# sync.ps1 — Clone missing repos and pull latest for existing ones
# Usage: .scripts/sync.ps1 [-Action pull|clone|status|push] [-CommitMsg "message"]
param(
    [ValidateSet("clone","pull","status","push")]
    [string]$Action = "pull",
    [string]$CommitMsg = "Auto-commit local changes"
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path $PSScriptRoot -Parent
$Manifest = Join-Path $RootDir ".repos"

if (-not (Test-Path $Manifest)) {
    Write-Error ".repos manifest not found at $Manifest"
    exit 1
}

Get-Content $Manifest | ForEach-Object {
    $line = $_.Trim()
    if ($line -match "^#" -or [string]::IsNullOrWhiteSpace($line)) { return }

    $parts = $line -split '\s+'
    $dir = $parts[0]
    $repo = $parts[1]
    $localPath = Join-Path $RootDir $dir

    switch ($Action) {
        "clone" {
            if (-not (Test-Path $localPath)) {
                Write-Output "Cloning $repo -> $dir"
                git clone "git@github.com:$repo.git" $localPath
            } else {
                Write-Output "Skip $dir (already exists)"
            }
        }
        "pull" {
            if (Test-Path (Join-Path $localPath ".git")) {
                Write-Output "Pulling $dir..."
                git -C $localPath pull --ff-only 2>&1 | Write-Output
            } else {
                Write-Output "Cloning $repo -> $dir"
                git clone "git@github.com:$repo.git" $localPath
            }
        }
        "status" {
            if (Test-Path (Join-Path $localPath ".git")) {
                $changes = git -C $localPath status --porcelain
                $branch = git -C $localPath branch --show-current
                $ahead = git -C $localPath rev-list --count '@{upstream}..HEAD' 2>$null
                if ($changes -or $ahead -ne "0") {
                    Write-Output "[$dir] branch=$branch ahead=$ahead dirty=$($changes.Count)"
                } else {
                    Write-Output "[$dir] clean"
                }
            } else {
                Write-Output "[$dir] NOT CLONED"
            }
        }
        "push" {
            if (Test-Path (Join-Path $localPath ".git")) {
                $changes = git -C $localPath status --porcelain
                if ($changes) {
                    Write-Output "Committing & pushing $dir..."
                    git -C $localPath add -A
                    git -C $localPath commit -m $CommitMsg
                    git -C $localPath push
                } else {
                    Write-Output "[$dir] clean, skipping"
                }
            }
        }
    }
}
