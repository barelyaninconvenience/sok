/*
 * Teams Chat Extractor — DOM-based approach
 * ------------------------------------------
 *
 * USAGE (3 options):
 *
 * Option A — Chrome DevTools console (fastest):
 *   1. Open Teams in Chrome, navigate to the chat you want to extract
 *   2. Scroll to the TOP of the chat so message history begins loading
 *   3. Press F12 → Console tab
 *   4. Paste this entire file, press Enter
 *   5. Wait for the "Loaded N messages" message
 *   6. Run: copy(JSON.stringify(window.__teamsChatExtract, null, 2))
 *   7. Paste into a file — you now have a structured JSON chat dump
 *
 * Option B — claude-in-chrome MCP javascript_tool:
 *   Have Claude run this via the browser automation MCP, then save the
 *   returned JSON to disk.
 *
 * Option C — invoke a specific function directly (for testing):
 *   await window.__teamsChat.loadAll()      // auto-scroll to load history
 *   window.__teamsChat.extract()            // extract what's currently in DOM
 *
 * KNOWN LIMITATIONS:
 *   - Teams uses virtual scrolling — only visible messages + buffer are in DOM
 *   - The loadAll() function scrolls up repeatedly to trigger lazy-load until
 *     message count stops growing, but is bounded at 100 scroll iterations
 *   - Selectors target multiple Teams DOM generations; Microsoft ships DOM
 *     changes frequently and this may need tuning — if you get 0 messages,
 *     inspect one message element in DevTools and add its selector below
 *   - Message bodies strip formatting (bold, italic, links); the full HTML
 *     is preserved in the `bodyHtml` field if you need it
 *   - Attachments, reactions, and thread replies are captured as best-effort;
 *     they may require role-specific extraction
 *
 * FALLBACK: if this doesn't work, use teams-chat-graph-api.py instead.
 */

(function installTeamsChatExtractor() {
    'use strict';

    // Selector candidates per Teams generation (try in order, stop at first match).
    const MESSAGE_SELECTORS = [
        '[data-tid="chat-pane-message"]',
        '[data-tid^="message-pane-item-"]',
        'div[role="listitem"][data-tid^="message-"]',
        '[data-tid="message-pane-list-viewport"] [role="listitem"]',
        '.ts-message',
        'div.message-body',
    ];

    const SCROLL_CONTAINER_SELECTORS = [
        '[data-tid="message-pane-list-viewport"]',
        '.message-list-container',
        '[role="list"]',
        '[data-tid="chat-pane"]',
    ];

    const SENDER_SELECTORS = [
        '[data-tid="messageSender"]',
        '[data-tid="author"]',
        '[data-tid="chat-pane-message-sender-name"]',
        '[itemprop="author"]',
        '.user-name',
        '.ts-message-header .sender',
    ];

    const TIMESTAMP_SELECTORS = [
        'time',
        '[data-tid="messageTimestamp"]',
        '[aria-label*="sent"]',
        '[title*=":"]',
    ];

    const BODY_SELECTORS = [
        '[data-tid="messageBody"]',
        '[data-tid="chat-pane-message-body"]',
        '[data-tid="message-body-content"]',
        '.message-body-content',
        '.message-body',
    ];

    function findMessageElements() {
        for (const sel of MESSAGE_SELECTORS) {
            const found = document.querySelectorAll(sel);
            if (found.length > 0) {
                console.log(`[teams-chat] ${found.length} messages via "${sel}"`);
                return Array.from(found);
            }
        }

        // Last-resort: walk up from <time> elements to find message containers.
        const times = document.querySelectorAll('time');
        if (times.length > 0) {
            console.warn(`[teams-chat] No message selector matched; using ${times.length} <time> elements as anchors`);
            return Array.from(times).map((t) => t.closest('[role="listitem"], article, li, div[class*="message"]'))
                .filter((x) => x !== null);
        }

        return [];
    }

    function findScrollContainer() {
        for (const sel of SCROLL_CONTAINER_SELECTORS) {
            const el = document.querySelector(sel);
            if (el) return el;
        }
        return null;
    }

    function extractText(parent, selectors) {
        for (const sel of selectors) {
            const el = parent.querySelector(sel);
            if (el) {
                return (el.getAttribute('datetime')
                     || el.getAttribute('aria-label')
                     || el.getAttribute('title')
                     || el.innerText
                     || '').trim();
            }
        }
        return null;
    }

    function extractMessage(el) {
        const sender = extractText(el, SENDER_SELECTORS);
        const timestamp = extractText(el, TIMESTAMP_SELECTORS);

        let body = null;
        let bodyHtml = null;
        for (const sel of BODY_SELECTORS) {
            const bodyEl = el.querySelector(sel);
            if (bodyEl) {
                body = bodyEl.innerText.trim();
                bodyHtml = bodyEl.innerHTML;
                break;
            }
        }
        if (body === null) {
            // Fallback: use the whole element text, minus sender/timestamp noise.
            body = el.innerText.trim();
        }

        // Attachments heuristic.
        const attachmentEls = el.querySelectorAll('[data-tid*="attachment"], [role="img"][aria-label], a[href*="sharepoint.com"], a[href*="onedrive.com"]');
        const attachments = Array.from(attachmentEls).map((a) => ({
            type: a.tagName === 'A' ? 'link' : 'attachment',
            text: a.innerText || a.getAttribute('aria-label') || a.getAttribute('alt') || '',
            href: a.getAttribute('href') || null,
        })).filter((a) => a.text || a.href);

        // Reactions heuristic.
        const reactionEls = el.querySelectorAll('[data-tid*="reaction"], [aria-label*="reaction"]');
        const reactions = Array.from(reactionEls).map((r) => (r.getAttribute('aria-label') || r.innerText || '').trim()).filter(Boolean);

        return { sender, timestamp, body, bodyHtml, attachments, reactions };
    }

    function extract() {
        const elements = findMessageElements();
        const messages = elements.map(extractMessage);
        window.__teamsChatExtract = messages;
        console.log(`[teams-chat] Extracted ${messages.length} messages → window.__teamsChatExtract`);
        console.log(`[teams-chat] To copy: copy(JSON.stringify(window.__teamsChatExtract, null, 2))`);
        return messages;
    }

    async function loadAll(maxScrolls = 100, waitMs = 1500, stableThreshold = 3) {
        const container = findScrollContainer();
        if (!container) {
            console.warn(`[teams-chat] No scroll container found — cannot auto-load history`);
            return extract();
        }

        console.log(`[teams-chat] Auto-scrolling to load chat history (max ${maxScrolls} iterations)`);

        let prevCount = findMessageElements().length;
        let stable = 0;

        for (let i = 0; i < maxScrolls; i++) {
            container.scrollTop = 0;
            await new Promise((r) => setTimeout(r, waitMs));
            const currentCount = findMessageElements().length;

            if (currentCount === prevCount) {
                stable += 1;
                if (stable >= stableThreshold) {
                    console.log(`[teams-chat] Stable at ${currentCount} messages after ${i + 1} scrolls`);
                    break;
                }
            } else {
                stable = 0;
                prevCount = currentCount;
                if ((i + 1) % 5 === 0) {
                    console.log(`[teams-chat] ${i + 1} scrolls, ${currentCount} messages loaded`);
                }
            }
        }

        return extract();
    }

    window.__teamsChat = { extract, loadAll, findMessageElements, findScrollContainer };
    console.log(`[teams-chat] Extractor installed. Run: await window.__teamsChat.loadAll()`);
})();

/*
 * OUTPUT FORMAT
 * -------------
 * Each extracted message is an object:
 * {
 *   sender: "Cohen, Abbey (cohen2al)",     // display name string or null
 *   timestamp: "2026-02-13T18:36:00",      // ISO datetime or aria-label fallback
 *   body: "plain text content",             // stripped of HTML
 *   bodyHtml: "<div>...</div>",             // raw HTML if you need formatting
 *   attachments: [                          // links/files referenced in message
 *     { type: "link", text: "Click here", href: "https://..." }
 *   ],
 *   reactions: ["thumbs up by 2"]           // reaction summary strings
 * }
 *
 * POST-PROCESSING
 * ---------------
 * Once you have the JSON, you can convert to markdown with the Python companion:
 *   python teams-chat-json-to-md.py path/to/chat.json
 *
 * Or paste directly into Claude and ask for a summary/analysis.
 */
