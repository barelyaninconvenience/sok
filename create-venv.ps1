# Quick virtual environment creation script
# Usage: .\create-venv.ps1 <project-name>

param([string]$projectName = "venv")

Write-Host "Creating virtual environment: $projectName" -ForegroundColor Cyan
python -m venv $projectName

Write-Host "Activating environment..." -ForegroundColor Yellow
& ".\$projectName\Scripts\Activate.ps1"

Write-Host "[?] Virtual environment '' created and activated!" -ForegroundColor Green
Write-Host "To deactivate: deactivate"
