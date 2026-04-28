# ==============================================================================
# Script: Move-OldUnreadToArchive.ps1
# Description: Moves all unread emails received before Dec 31, 2025, to Archive.
# ==============================================================================

# --- Configuration ---
$userEmail = "CHANGEME@example.com" # REPLACE with your user principal name (UPN) / email before running
$dateLimit = "2026-01-01T00:00:00Z"  # UTC format required by Graph API

# --- Connect to Microsoft Graph ---
# Requires Mail.ReadWrite scope to read and move messages
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Mail.ReadWrite"

try {
    # --- 1. Find the Archive Folder ---
    Write-Host "Locating the Archive folder..."
    # Query all folders and filter by DisplayName. 
    # (Note: Standard English folders use "Archive", adjust if your localized folder name differs).
    $archiveFolder = Get-MgUserMailFolder -UserId $userEmail -All | Where-Object { $_.DisplayName -eq "Archive" }

    if (-not $archiveFolder) {
        Write-Warning "Could not find a folder named 'Archive'. Exiting."
        exit
    }
    
    Write-Host "Archive folder found. ID: $($archiveFolder.Id)" -ForegroundColor Green

    # --- 2. Query the Emails ---
    Write-Host "Querying unread emails received before $dateLimit..."
    # OData filter for unread (isRead eq false) and older than date (receivedDateTime lt date)
    $filterString = "isRead eq false and receivedDateTime lt $dateLimit"
    
    # -All fetches all pages of results. We only pull necessary properties to speed up the query.
    $emailsToMove = Get-MgUserMessage -UserId $userEmail -Filter $filterString -All -Property "id,subject,receivedDateTime"

    $totalEmails = @($emailsToMove).Count
    if ($totalEmails -eq 0) {
        Write-Host "No emails matched the criteria." -ForegroundColor Yellow
        exit
    }

    Write-Host "Found $totalEmails email(s) to move." -ForegroundColor Cyan

    # --- 3. Move the Emails ---
    $counter = 0
    foreach ($email in $emailsToMove) {
        $counter++
        Write-Host "Moving [$counter/$totalEmails]: $($email.Subject)"

        # Move action requires the User ID, the Message ID, and the Destination Folder ID
        Move-MgUserMessage -UserId $userEmail -MessageId $email.Id -DestinationId $archiveFolder.Id | Out-Null
        
        # Optional: Uncomment the line below to add a slight delay to prevent Graph API rate-limiting 
        # if you are moving tens of thousands of emails.
        Start-Sleep -Milliseconds 66 
    }

    Write-Host "Successfully moved $totalEmails emails to Archive!" -ForegroundColor Green

}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # --- Disconnect ---
    Write-Host "Disconnecting from Microsoft Graph..."
    Disconnect-MgGraph
}