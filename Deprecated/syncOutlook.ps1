Add-Type -assembly "
Microsoft.Office.Interop.Outlook
"
$Outlook = New-Object -comobject Outlook.Application
$Outlook.Session.SendAndReceive($true)