#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-Secrets.psm1 — DPAPI-encrypted credential helper for SOK scripts.
.DESCRIPTION
    v1.0.0 (2026-04-14). Provides Get-SOKSecret / Set-SOKSecret /
    Remove-SOKSecret for storing sensitive values (API keys, OAuth secrets,
    PATs, tokens) in DPAPI-encrypted files under ~/.sok-secrets/.

    Windows Data Protection API (DPAPI) encrypts to the current user profile
    on the current machine. Secrets cannot be decrypted by any other user or
    on any other machine, even with the raw file contents — the master key is
    derived from the user's Windows login credentials.

    This is the "least volatile" credential store on Windows that still allows
    per-process retrieval: survives reboots, survives profile updates, harder
    to lose accidentally than a `.env` file, harder to exfiltrate than a plain
    env var.

    For GitHub PATs specifically, prefer `gh auth login` / `gh auth token` —
    gh uses Windows Credential Manager natively and is already integrated.
    Use this module for non-gh credentials (Google OAuth, Brave API key,
    Anthropic API key, etc.).

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-14
    Domain:  Universal — called by every SOK script that handles credentials
#>

$script:SecretsDir = Join-Path $env:USERPROFILE '.sok-secrets'

function Initialize-SOKSecretsDir {
    [CmdletBinding()]
    param()
    if (-not (Test-Path $script:SecretsDir)) {
        New-Item -Path $script:SecretsDir -ItemType Directory -Force | Out-Null
    }
    # Restrict ACL to current user only
    $acl = Get-Acl $script:SecretsDir
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl -Path $script:SecretsDir -AclObject $acl
}

function Set-SOKSecret {
    <#
    .SYNOPSIS
        Store a credential under a given name, DPAPI-encrypted.
    .EXAMPLE
        Set-SOKSecret -Name 'GoogleOAuthClientSecret' -Value (Read-Host -AsSecureString)
    .EXAMPLE
        Set-SOKSecret -Name 'BraveAPIKey' -Plain 'abc123...'
    #>
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(ParameterSetName='Secure',  Mandatory)][SecureString]$Value,
        [Parameter(ParameterSetName='Plain',   Mandatory)][string]$Plain
    )
    Initialize-SOKSecretsDir

    if ($PSCmdlet.ParameterSetName -eq 'Plain') {
        $Value = ConvertTo-SecureString -String $Plain -AsPlainText -Force
    }

    # DPAPI encryption via ConvertFrom-SecureString (encrypts to the user profile)
    $encrypted = ConvertFrom-SecureString -SecureString $Value

    $path = Join-Path $script:SecretsDir "$Name.sec"
    Set-Content -Path $path -Value $encrypted -Encoding utf8 -Force

    # Restrict file ACL to current user
    $acl = Get-Acl $path
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, 'FullControl', 'None', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl -Path $path -AclObject $acl

    Write-Verbose "Stored secret '$Name' at $path"
}

function Get-SOKSecret {
    <#
    .SYNOPSIS
        Retrieve a previously stored secret as a plain string.
    .DESCRIPTION
        DPAPI-decrypts the named secret. Returns a plain string suitable for
        passing to an MCP env var or an API call. Callers should minimize the
        time the plain value stays in memory.
    .PARAMETER AsSecureString
        Return a SecureString instead of plain text. Preferred where possible.
    .EXAMPLE
        $apiKey = Get-SOKSecret -Name 'BraveAPIKey'
    .EXAMPLE
        $env:GOOGLE_OAUTH_CLIENT_SECRET = Get-SOKSecret -Name 'GoogleOAuthClientSecret'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$AsSecureString
    )
    $path = Join-Path $script:SecretsDir "$Name.sec"
    if (-not (Test-Path $path)) {
        Write-Error "Secret '$Name' not found at $path. Store with Set-SOKSecret first."
        return $null
    }

    $encrypted = Get-Content $path -Raw
    $secure = ConvertTo-SecureString -String $encrypted

    if ($AsSecureString) {
        return $secure
    }

    # Convert to plain string
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Remove-SOKSecret {
    <#
    .SYNOPSIS
        Move a secret to Deprecated/ (never hard-delete per SOK axiom).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    $path = Join-Path $script:SecretsDir "$Name.sec"
    if (-not (Test-Path $path)) { return }

    $deprecated = Join-Path $script:SecretsDir 'Deprecated'
    if (-not (Test-Path $deprecated)) {
        New-Item -Path $deprecated -ItemType Directory -Force | Out-Null
    }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $dest = Join-Path $deprecated "${Name}_${stamp}.sec"
    Move-Item -Path $path -Destination $dest -Force
    Write-Verbose "Deprecated secret '$Name' -> $dest"
}

function Get-SOKSecretList {
    <#
    .SYNOPSIS
        List all currently stored secret names (does NOT reveal values).
    #>
    [CmdletBinding()]
    param()
    if (-not (Test-Path $script:SecretsDir)) { return @() }
    Get-ChildItem -Path $script:SecretsDir -Filter '*.sec' -File |
        ForEach-Object { $_.BaseName }
}

Export-ModuleMember -Function @(
    'Set-SOKSecret',
    'Get-SOKSecret',
    'Remove-SOKSecret',
    'Get-SOKSecretList'
)
