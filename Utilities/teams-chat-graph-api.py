"""
Teams Chat Extractor — Microsoft Graph API approach
====================================================

The robust alternative to DOM scraping. Uses Microsoft Graph API with device
code flow authentication — no Azure app registration required, no client
secret to manage.

INSTALLATION
------------
    pip install msal requests

FIRST-RUN AUTHENTICATION
------------------------
1. Run the script:     python teams-chat-graph-api.py
2. It prints a URL and a device code. Visit the URL in any browser.
3. Sign in with your UC account, enter the code, grant consent to:
       - Chat.Read (view your 1:1 and group chats)
       - ChatMessage.Read (view message content)
4. Token is cached to ~/.teams-chat-token.json for subsequent runs.

USAGE
-----
List all chats (to find the one you want):
    python teams-chat-graph-api.py list

Fetch a specific chat's messages:
    python teams-chat-graph-api.py fetch <chat-id> [--out chat.json] [--md chat.md]

Fetch ALL chats (bulk dump):
    python teams-chat-graph-api.py dump-all [--out-dir teams-chats/]

CONDITIONAL ACCESS CAVEAT
-------------------------
Some Microsoft 365 tenants (including many universities) have Conditional
Access policies that block device code flow. If you get an error like
"AADSTS50158: External security challenge not satisfied" or similar, your
tenant admin has disabled device code auth. Fallback options:
  1. Use the DOM-based extractor (teams-chat-extract.js)
  2. Ask IT to grant you an Azure app registration for personal use
  3. Use Microsoft Graph Explorer (graph.microsoft.com/graphexplorer) for
     one-off queries with your signed-in account
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

try:
    import msal
    import requests
except ImportError:
    print("Missing dependencies. Install with: pip install msal requests", file=sys.stderr)
    sys.exit(1)

# Microsoft's own "Microsoft Graph Command Line Tools" public client (used by
# PowerShell SDK and MS-sanctioned tooling). No Azure app registration needed.
CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
AUTHORITY = "https://login.microsoftonline.com/common"
SCOPES = ["Chat.Read", "ChatMessage.Read"]
GRAPH_BASE = "https://graph.microsoft.com/v1.0"
TOKEN_CACHE_PATH = Path.home() / ".teams-chat-token.json"


def get_token() -> str:
    """Acquire a Graph API access token via device code flow (cached)."""
    cache = msal.SerializableTokenCache()
    if TOKEN_CACHE_PATH.exists():
        try:
            cache.deserialize(TOKEN_CACHE_PATH.read_text())
        except Exception:
            pass

    app = msal.PublicClientApplication(CLIENT_ID, authority=AUTHORITY, token_cache=cache)

    accounts = app.get_accounts()
    result = None
    if accounts:
        result = app.acquire_token_silent(SCOPES, account=accounts[0])

    if not result:
        flow = app.initiate_device_flow(scopes=SCOPES)
        if "user_code" not in flow:
            raise RuntimeError(f"Device flow init failed: {flow.get('error_description', flow)}")
        print(flow["message"], flush=True)
        result = app.acquire_token_by_device_flow(flow)

    if cache.has_state_changed:
        TOKEN_CACHE_PATH.write_text(cache.serialize())
        TOKEN_CACHE_PATH.chmod(0o600)

    if "access_token" not in result:
        raise RuntimeError(f"Token acquisition failed: {result.get('error_description', result)}")

    return result["access_token"]


def graph_get(path: str, token: str, params: dict | None = None) -> dict:
    """GET a Graph API endpoint with pagination collapsed into a single dict."""
    url = f"{GRAPH_BASE}{path}" if path.startswith("/") else path
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}

    collected = []
    while url:
        resp = requests.get(url, headers=headers, params=params if collected == [] else None, timeout=30)
        if resp.status_code == 401:
            raise RuntimeError("Token expired or invalid — delete ~/.teams-chat-token.json and rerun")
        if resp.status_code >= 400:
            raise RuntimeError(f"Graph API error {resp.status_code}: {resp.text[:500]}")
        data = resp.json()
        if "value" in data:
            collected.extend(data["value"])
            url = data.get("@odata.nextLink")
        else:
            return data

    return {"value": collected}


def list_chats(token: str) -> list[dict]:
    """List all chats visible to the signed-in user, most-recent first."""
    data = graph_get(
        "/me/chats",
        token,
        params={"$orderby": "lastMessagePreview/createdDateTime desc", "$expand": "members"},
    )
    return data.get("value", [])


def fetch_messages(chat_id: str, token: str) -> list[dict]:
    """Fetch all messages in a chat, oldest first."""
    data = graph_get(f"/me/chats/{chat_id}/messages", token, params={"$top": 50})
    messages = data.get("value", [])
    messages.reverse()  # Graph returns newest-first; reverse for chronological reading.
    return messages


def format_chat_label(chat: dict) -> str:
    """Produce a human-readable one-line label for a chat."""
    topic = chat.get("topic") or ""
    members = chat.get("members", [])
    member_names = ", ".join(m.get("displayName", "?") for m in members if m.get("displayName"))
    chat_type = chat.get("chatType", "")
    last_dt = ""
    preview = chat.get("lastMessagePreview", {}) or {}
    if preview.get("createdDateTime"):
        last_dt = preview["createdDateTime"][:16].replace("T", " ")
    bits = [b for b in [chat_type, topic or member_names, last_dt] if b]
    return " | ".join(bits)


def messages_to_markdown(messages: list[dict], chat_label: str = "") -> str:
    """Render the Graph API message list as chronological markdown."""
    lines: list[str] = []
    lines.append(f"# Teams chat capture{f': {chat_label}' if chat_label else ''}")
    lines.append("")
    lines.append(f"Captured: {datetime.now().isoformat(timespec='seconds')}")
    lines.append(f"Message count: {len(messages)}")
    lines.append("")
    lines.append("---")
    lines.append("")

    for m in messages:
        sender = m.get("from", {}) or {}
        user = sender.get("user", {}) or {}
        sender_name = user.get("displayName") or sender.get("application", {}).get("displayName") or "(system)"

        created = m.get("createdDateTime", "")
        try:
            ts = created.replace("T", " ").replace("Z", "")[:19]
        except Exception:
            ts = created

        body = m.get("body", {}) or {}
        content = body.get("content", "") or ""
        content_type = body.get("contentType", "text")

        lines.append(f"### {sender_name} — {ts}")
        lines.append("")
        if content_type == "html":
            # Best-effort HTML-to-text: strip tags but preserve line breaks.
            import re
            text = re.sub(r"<br\s*/?>", "\n", content, flags=re.IGNORECASE)
            text = re.sub(r"</p>", "\n\n", text, flags=re.IGNORECASE)
            text = re.sub(r"<[^>]+>", "", text)
            text = text.replace("&nbsp;", " ").replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
            lines.append(text.strip())
        else:
            lines.append(content.strip())

        attachments = m.get("attachments", []) or []
        if attachments:
            lines.append("")
            lines.append("**Attachments:**")
            for a in attachments:
                name = a.get("name", "") or a.get("contentUrl", "") or "(unnamed)"
                url = a.get("contentUrl", "")
                lines.append(f"- {name} — {url}")

        lines.append("")

    return "\n".join(lines)


def cmd_list(args):
    token = get_token()
    chats = list_chats(token)
    print(f"Found {len(chats)} chats:\n")
    for c in chats:
        print(f"  {c['id']}")
        print(f"    {format_chat_label(c)}")
        print()


def cmd_fetch(args):
    token = get_token()
    messages = fetch_messages(args.chat_id, token)
    print(f"Fetched {len(messages)} messages from chat {args.chat_id}", file=sys.stderr)

    if args.out:
        Path(args.out).write_text(json.dumps(messages, indent=2), encoding="utf-8")
        print(f"JSON written: {args.out}", file=sys.stderr)

    if args.md:
        md = messages_to_markdown(messages)
        Path(args.md).write_text(md, encoding="utf-8")
        print(f"Markdown written: {args.md}", file=sys.stderr)

    if not args.out and not args.md:
        print(json.dumps(messages, indent=2))


def cmd_dump_all(args):
    token = get_token()
    chats = list_chats(token)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    for chat in chats:
        chat_id = chat["id"]
        label = format_chat_label(chat)
        slug = label.replace(" | ", "_").replace(" ", "_").replace("/", "-").replace(":", "-")[:80]
        filename = f"{chat_id[:16]}_{slug}"

        try:
            messages = fetch_messages(chat_id, token)
        except Exception as e:
            print(f"FAIL {chat_id}: {e}", file=sys.stderr)
            continue

        json_path = out_dir / f"{filename}.json"
        md_path = out_dir / f"{filename}.md"

        json_path.write_text(json.dumps(messages, indent=2), encoding="utf-8")
        md_path.write_text(messages_to_markdown(messages, label), encoding="utf-8")

        print(f"{len(messages):>5} msgs  →  {filename}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Teams chat extractor via Microsoft Graph API")
    sub = parser.add_subparsers(dest="command", required=True)

    list_cmd = sub.add_parser("list", help="List all chats with IDs")
    list_cmd.set_defaults(func=cmd_list)

    f = sub.add_parser("fetch", help="Fetch a specific chat's messages")
    f.add_argument("chat_id", help="Chat ID from the list command")
    f.add_argument("--out", help="Write raw JSON to this path")
    f.add_argument("--md", help="Write markdown-rendered chat to this path")
    f.set_defaults(func=cmd_fetch)

    d = sub.add_parser("dump-all", help="Dump every chat to files in a directory")
    d.add_argument("--out-dir", default="teams-chats", help="Output directory (default: teams-chats)")
    d.set_defaults(func=cmd_dump_all)

    args = parser.parse_args()
    try:
        args.func(args)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
