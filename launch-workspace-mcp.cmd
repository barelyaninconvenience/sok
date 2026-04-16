@echo off
REM Launch workspace-mcp with DPAPI-retrieved Google OAuth credentials
REM Used by Claude Code CLI MCP subsystem — do not modify without testing stdio passthrough
REM Sentinel-reviewed 2026-04-16: removed OAUTHLIB_INSECURE_TRANSPORT, added post-exit cleanup

for /f "usebackq delims=" %%i in (`pwsh -NoProfile -Command "Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force; Get-SOKSecret -Name 'GoogleOAuthClientId'"`) do set GOOGLE_OAUTH_CLIENT_ID=%%i
for /f "usebackq delims=" %%i in (`pwsh -NoProfile -Command "Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force; Get-SOKSecret -Name 'GoogleOAuthClientSecret'"`) do set GOOGLE_OAUTH_CLIENT_SECRET=%%i

REM Required: workspace-mcp uses http://localhost:8000/oauth2callback (HTTP not HTTPS)
REM Without this, oauthlib raises InsecureTransportError on the localhost callback
set OAUTHLIB_INSECURE_TRANSPORT=1

uvx workspace-mcp

REM Post-exit credential cleanup (clear env vars from shell memory)
set GOOGLE_OAUTH_CLIENT_ID=
set GOOGLE_OAUTH_CLIENT_SECRET=
