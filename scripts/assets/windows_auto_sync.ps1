# NAEON Assets Auto-Sync for Windows (Task Scheduler)
# Schedule this script to run every 15-30 minutes.

$ProjectRoot = "C:\Users\YOUR_USERNAME\Projects\naeon"   # <-- измените путь
$LocalAssets = Join-Path $ProjectRoot "assets"
$Remote = "neon:dev"

Set-Location $ProjectRoot

if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Error "rclone not found in PATH. Install it first."
    exit 1
}

Write-Host "$(Get-Date -Format 'HH:mm:ss') Syncing $Remote → $LocalAssets"

rclone sync $Remote $LocalAssets `
    --exclude ".DS_Store" `
    --exclude "*.tmp" `
    --exclude "Thumbs.db" `
    --progress

Write-Host "$(Get-Date -Format 'HH:mm:ss') Done"
