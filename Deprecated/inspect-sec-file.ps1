#Requires -Version 7.0
$p = 'C:/Users/shelc/.sok-secrets/GoogleOAuthClientId.sec'
$raw = Get-Content $p -Raw
Write-Host "File length: $($raw.Length)"
Write-Host "First 60 chars: $($raw.Substring(0, [Math]::Min(60, $raw.Length)))"
Write-Host ""
Write-Host "Last 10 bytes as hex:"
$bytes = [System.IO.File]::ReadAllBytes($p)
$tail = $bytes[-10..-1]
($tail | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
Write-Host ""
Write-Host "Total file bytes on disk: $($bytes.Length)"

# Try trimmed retrieve
Write-Host ""
Write-Host "--- Attempt: trimmed ConvertTo-SecureString ---"
try {
    $trimmed = $raw.Trim()
    Write-Host "Trimmed length: $($trimmed.Length)"
    $secure = ConvertTo-SecureString -String $trimmed
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        Write-Host "Trimmed retrieve SUCCESS — length: $($plain.Length), starts-with: $($plain.Substring(0,10))..."
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
} catch {
    Write-Host "Trimmed retrieve FAILED: $($_.Exception.Message)"
}
