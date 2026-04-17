#Requires -Version 7.0
# Verify .mcp.json is valid JSON and report structure
try {
    $content = Get-Content 'C:/Users/shelc/.mcp.json' -Raw
    $parsed = $content | ConvertFrom-Json
    Write-Host "JSON VALID"
    $names = $parsed.mcpServers.PSObject.Properties.Name
    Write-Host "Entries: $($names.Count)"
    foreach ($name in $names) {
        $entry = $parsed.mcpServers.$name
        $argsStr = ($entry.args -join ' ')
        Write-Host ("  - {0,-14}  command={1}" -f $name, $entry.command)
        Write-Host ("                    args=$argsStr")
    }
} catch {
    Write-Host "JSON INVALID:"
    Write-Host $_.Exception.Message
    exit 1
}
