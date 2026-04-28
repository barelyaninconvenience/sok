# Configuration: Set your target folder path
$TargetFolder = "C:\Path\To\Your\HtmlFiles"

# Check if Chrome is in the System Path (common), otherwise define full path
$ChromePath = "chrome.exe" 
# If chrome.exe isn't found, uncomment the line below:
# $ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Get all HTML files and open them
Get-ChildItem -Path $TargetFolder -Filter "*.html" | ForEach-Object {
    Write-Host "Opening: $($_.Name)"
    Start-Process -FilePath $ChromePath -ArgumentList $_.FullName
}

Start-Process "chrome.exe" "C:\Path\To\Report.html"

Start-Process "chrome.exe" "C:\Users\shelc\Downloads\personal_takeaway.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\personal_takeaway_v2.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\prompt_exoskeleton_v1.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\prompt_framework.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\sep_patent_draft.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\sep_patent_draft_v2.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\sir_articles.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\substrate_thesis_v2.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\whitepaper.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\klem_os_architecture.html"
Start-Process "chrome.exe" "C:\Users\shelc\Downloads\klem_os_v2_expansion.html"