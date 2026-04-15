#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-Canvas.psm1 — Canvas LMS REST API PowerShell module.

.DESCRIPTION
    Wraps the Canvas LMS REST API for UC's instance (uc.instructure.com).
    Supports: course listing, assignment listing, submission status checking,
    file upload + submission, and grade retrieval.

    Token is read from environment variable CANVAS_API_TOKEN (User scope).
    Never displays the token in output.

.NOTES
    Author: S. Clay Caddell / Claude Code
    Version: 1.0.0
    Date: 2026-04-05
    Canvas API docs: https://canvas.instructure.com/doc/api/
    UC Canvas instance: https://uc.instructure.com
#>

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

$script:CanvasBaseUrl = 'https://uc.instructure.com/api/v1'
$script:TokenEnvVar = 'CANVAS_API_TOKEN'

function Get-CanvasToken {
    <#
    .SYNOPSIS Returns the Canvas API token from environment, or throws if not set.
    #>
    $token = [Environment]::GetEnvironmentVariable($script:TokenEnvVar, 'User')
    if (-not $token) {
        $token = $env:CANVAS_API_TOKEN
    }
    if (-not $token) {
        throw @"
Canvas API token not found. Set it with:
  [Environment]::SetEnvironmentVariable('CANVAS_API_TOKEN', 'your-token-here', 'User')

To generate a token:
  1. Log into https://uc.instructure.com
  2. Go to Account > Settings
  3. Scroll to "Approved Integrations" > "+ New Access Token"
  4. Give it a purpose name (e.g., "SOK-Canvas") and generate
  5. Copy the token immediately (it won't be shown again)
"@
    }
    return $token
}

function Invoke-CanvasApi {
    <#
    .SYNOPSIS Generic Canvas API caller with pagination support.
    .PARAMETER Endpoint API endpoint path (e.g., '/courses')
    .PARAMETER Method HTTP method. Default: GET
    .PARAMETER Body Request body for POST/PUT
    .PARAMETER AllPages Follow Link pagination headers to get all results
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,
        [string]$Method = 'GET',
        [hashtable]$Body,
        [switch]$AllPages,
        [string]$ContentType = 'application/json'
    )

    $token = Get-CanvasToken
    $headers = @{ Authorization = "Bearer $token" }
    $url = if ($Endpoint.StartsWith('http')) { $Endpoint } else { "$($script:CanvasBaseUrl)$Endpoint" }

    $allResults = @()

    do {
        $params = @{
            Uri     = $url
            Method  = $Method
            Headers = $headers
        }

        if ($Body -and $Method -in @('POST', 'PUT', 'PATCH')) {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
            $params['ContentType'] = $ContentType
        }

        try {
            $response = Invoke-WebRequest @params -UseBasicParsing
            $data = $response.Content | ConvertFrom-Json

            if ($AllPages) {
                $allResults += $data
                # Check for Link header pagination
                $linkHeader = $response.Headers['Link']
                $url = $null
                if ($linkHeader) {
                    $links = $linkHeader -split ','
                    foreach ($link in $links) {
                        if ($link -match '<([^>]+)>;\s*rel="next"') {
                            $url = $Matches[1]
                        }
                    }
                }
            } else {
                return $data
            }
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorBody = ''
            try { $errorBody = $_.ErrorDetails.Message } catch {}
            Write-Error "Canvas API error ($statusCode) on $Method $Endpoint`: $errorBody"
            return $null
        }
    } while ($url -and $AllPages)

    return $allResults
}

# ═══════════════════════════════════════════════════════════════
# COURSE OPERATIONS
# ═══════════════════════════════════════════════════════════════

function Get-CanvasCourses {
    <#
    .SYNOPSIS List all active courses for the authenticated user.
    .PARAMETER IncludeCompleted Include completed/past courses.
    #>
    param([switch]$IncludeCompleted)

    $endpoint = '/courses?per_page=100&include[]=total_students&include[]=term'
    if (-not $IncludeCompleted) {
        $endpoint += '&enrollment_state=active'
    }

    $courses = Invoke-CanvasApi -Endpoint $endpoint -AllPages
    if ($courses) {
        $courses | ForEach-Object {
            [PSCustomObject]@{
                Id         = $_.id
                Name       = $_.name
                CourseCode = $_.course_code
                Term       = $_.term.name
                State      = $_.workflow_state
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# ASSIGNMENT OPERATIONS
# ═══════════════════════════════════════════════════════════════

function Get-CanvasAssignments {
    <#
    .SYNOPSIS List all assignments for a course.
    .PARAMETER CourseId Canvas course ID.
    .PARAMETER IncludeSubmission Include the user's submission status.
    #>
    param(
        [Parameter(Mandatory)]
        [int]$CourseId,
        [switch]$IncludeSubmission
    )

    $endpoint = "/courses/$CourseId/assignments?per_page=100&order_by=due_at"
    if ($IncludeSubmission) {
        $endpoint += '&include[]=submission'
    }

    $assignments = Invoke-CanvasApi -Endpoint $endpoint -AllPages
    if ($assignments) {
        $assignments | ForEach-Object {
            $sub = $_.submission
            [PSCustomObject]@{
                Id              = $_.id
                Name            = $_.name
                DueAt           = if ($_.due_at) { [datetime]$_.due_at } else { $null }
                PointsPossible  = $_.points_possible
                SubmissionTypes = ($_.submission_types -join ', ')
                Submitted       = if ($sub) { $sub.workflow_state -ne 'unsubmitted' } else { $null }
                Score           = if ($sub) { $sub.score } else { $null }
                Grade           = if ($sub) { $sub.grade } else { $null }
                Url             = $_.html_url
            }
        }
    }
}

function Get-CanvasSubmissionStatus {
    <#
    .SYNOPSIS Check submission status for a specific assignment.
    .PARAMETER CourseId Canvas course ID.
    .PARAMETER AssignmentId Canvas assignment ID.
    #>
    param(
        [Parameter(Mandatory)][int]$CourseId,
        [Parameter(Mandatory)][int]$AssignmentId
    )

    $endpoint = "/courses/$CourseId/assignments/$AssignmentId/submissions/self"
    $sub = Invoke-CanvasApi -Endpoint $endpoint
    if ($sub) {
        [PSCustomObject]@{
            AssignmentId   = $AssignmentId
            WorkflowState  = $sub.workflow_state
            SubmittedAt    = $sub.submitted_at
            Score          = $sub.score
            Grade          = $sub.grade
            Late           = $sub.late
            Missing        = $sub.missing
            Attempt        = $sub.attempt
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# FILE UPLOAD + SUBMISSION
# ═══════════════════════════════════════════════════════════════

function Submit-CanvasAssignment {
    <#
    .SYNOPSIS Upload a file and submit it to a Canvas assignment.
    .DESCRIPTION
        Three-step Canvas file upload process:
        1. Notify Canvas of the upload (POST to assignment's submissions endpoint)
        2. Upload the file to the URL Canvas provides
        3. Confirm the upload and create the submission

    .PARAMETER CourseId Canvas course ID.
    .PARAMETER AssignmentId Canvas assignment ID.
    .PARAMETER FilePath Local path to the file to submit.
    .PARAMETER Comment Optional submission comment.
    .PARAMETER DryRun Preview without actually submitting.
    #>
    param(
        [Parameter(Mandatory)][int]$CourseId,
        [Parameter(Mandatory)][int]$AssignmentId,
        [Parameter(Mandatory)][string]$FilePath,
        [string]$Comment,
        [switch]$DryRun
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }

    $file = Get-Item $FilePath
    $sizeKB = [math]::Round($file.Length / 1KB, 1)

    if ($DryRun) {
        Write-Host "[DRY RUN] Would submit: $($file.Name) ($sizeKB KB) to assignment $AssignmentId in course $CourseId" -ForegroundColor Yellow
        if ($Comment) { Write-Host "[DRY RUN] Comment: $Comment" -ForegroundColor Yellow }
        return [PSCustomObject]@{ Status = 'DryRun'; File = $file.Name; SizeKB = $sizeKB }
    }

    # Step 1: Request upload slot
    Write-Host "  [1/3] Requesting upload slot for $($file.Name) ($sizeKB KB)..." -ForegroundColor Cyan
    $token = Get-CanvasToken
    $headers = @{ Authorization = "Bearer $token" }

    $step1Body = @{
        name         = $file.Name
        size         = $file.Length
        content_type = switch ($file.Extension) {
            '.docx' { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
            '.pdf'  { 'application/pdf' }
            '.xlsx' { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
            '.pptx' { 'application/vnd.openxmlformats-officedocument.presentationml.presentation' }
            '.ipynb' { 'application/json' }
            '.md'   { 'text/markdown' }
            '.txt'  { 'text/plain' }
            '.py'   { 'text/x-python' }
            '.zip'  { 'application/zip' }
            default { 'application/octet-stream' }
        }
    }

    $uploadSlot = Invoke-CanvasApi -Endpoint "/courses/$CourseId/assignments/$AssignmentId/submissions/self/files" `
        -Method POST -Body $step1Body

    if (-not $uploadSlot -or -not $uploadSlot.upload_url) {
        Write-Error "Failed to get upload slot from Canvas"
        return $null
    }

    # Step 2: Upload the file
    Write-Host "  [2/3] Uploading file..." -ForegroundColor Cyan
    $uploadParams = @{}
    foreach ($prop in $uploadSlot.upload_params.PSObject.Properties) {
        $uploadParams[$prop.Name] = $prop.Value
    }

    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
    foreach ($key in $uploadParams.Keys) {
        $multipartContent.Add([System.Net.Http.StringContent]::new($uploadParams[$key]), $key)
    }
    $fileStream = [System.IO.File]::OpenRead($file.FullName)
    $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
    $multipartContent.Add($fileContent, 'file', $file.Name)

    try {
        $httpClient = [System.Net.Http.HttpClient]::new()
        $uploadResponse = $httpClient.PostAsync($uploadSlot.upload_url, $multipartContent).Result
        $uploadResult = $uploadResponse.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    }
    finally {
        $fileStream.Dispose()
        $multipartContent.Dispose()
        $httpClient.Dispose()
    }

    if (-not $uploadResult.id) {
        Write-Error "File upload failed"
        return $null
    }

    $fileId = $uploadResult.id
    Write-Host "  [2/3] Upload complete. File ID: $fileId" -ForegroundColor Green

    # Step 3: Create submission
    Write-Host "  [3/3] Creating submission..." -ForegroundColor Cyan
    $submissionBody = @{
        submission = @{
            submission_type = 'online_upload'
            file_ids        = @($fileId)
        }
    }
    if ($Comment) {
        $submissionBody.comment = @{ text_comment = $Comment }
    }

    $result = Invoke-CanvasApi -Endpoint "/courses/$CourseId/assignments/$AssignmentId/submissions" `
        -Method POST -Body $submissionBody

    if ($result) {
        Write-Host "  [3/3] Submitted! Submission ID: $($result.id)" -ForegroundColor Green
        return [PSCustomObject]@{
            Status       = 'Submitted'
            SubmissionId = $result.id
            File         = $file.Name
            SizeKB       = $sizeKB
            AssignmentId = $AssignmentId
            CourseId     = $CourseId
            SubmittedAt  = $result.submitted_at
        }
    } else {
        Write-Error "Submission creation failed"
        return $null
    }
}

# ═══════════════════════════════════════════════════════════════
# BATCH OPERATIONS
# ═══════════════════════════════════════════════════════════════

function Get-CanvasAcademicStatus {
    <#
    .SYNOPSIS Show submission status across all active courses.
    .DESCRIPTION
        Lists all assignments with due dates, submission status, and scores
        for all active courses. Highlights missing/late submissions.
    #>

    $courses = Get-CanvasCourses
    if (-not $courses) {
        Write-Error "No courses found or API token invalid"
        return
    }

    Write-Host "=== Canvas Academic Status ===" -ForegroundColor Cyan
    Write-Host "Courses found: $($courses.Count)"
    Write-Host ""

    foreach ($course in $courses) {
        Write-Host "--- $($course.Name) (ID: $($course.Id)) ---" -ForegroundColor Cyan
        $assignments = Get-CanvasAssignments -CourseId $course.Id -IncludeSubmission

        if (-not $assignments) {
            Write-Host "  No assignments found" -ForegroundColor DarkGray
            continue
        }

        foreach ($a in $assignments | Sort-Object DueAt) {
            $dueStr = if ($a.DueAt) { $a.DueAt.ToString('yyyy-MM-dd') } else { 'No due date' }
            $status = if ($a.Submitted) { 'SUBMITTED' }
                      elseif ($a.DueAt -and $a.DueAt -lt (Get-Date)) { 'MISSING' }
                      else { 'PENDING' }
            $color = switch ($status) {
                'SUBMITTED' { 'Green' }
                'MISSING'   { 'Red' }
                'PENDING'   { 'Yellow' }
            }
            $scoreStr = if ($null -ne $a.Score) { "$($a.Score)/$($a.PointsPossible)" } else { '--' }
            $line = "  [{0,-9}] {1,-50} {2}  {3}" -f $status, $a.Name, $dueStr, $scoreStr
            Write-Host $line -ForegroundColor $color
        }
        Write-Host ""
    }
}

# ═══════════════════════════════════════════════════════════════
# CONNECTION TEST
# ═══════════════════════════════════════════════════════════════

function Test-CanvasConnection {
    <#
    .SYNOPSIS Verify Canvas API token and connection.
    #>
    try {
        $user = Invoke-CanvasApi -Endpoint '/users/self'
        if ($user) {
            Write-Host "Connected to Canvas as: $($user.name) ($($user.login_id))" -ForegroundColor Green
            Write-Host "Instance: uc.instructure.com" -ForegroundColor DarkGray
            return $true
        }
    }
    catch {
        Write-Host "Canvas connection failed: $_" -ForegroundColor Red
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════
# MODULE EXPORTS
# ═══════════════════════════════════════════════════════════════

Export-ModuleMember -Function @(
    'Get-CanvasCourses',
    'Get-CanvasAssignments',
    'Get-CanvasSubmissionStatus',
    'Submit-CanvasAssignment',
    'Get-CanvasAcademicStatus',
    'Test-CanvasConnection',
    'Invoke-CanvasApi'
)
