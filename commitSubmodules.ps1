param(
  [string]$commitMessage = "Auto-Commit local changes in submodules"
)


# Get all subdmoule paths (including nested ones) using git subdmoule for each functions
#
########################################################################################

$submodule_paths = git submodule foreach --recursive 2>&1 | ForEach-Objects{
  if($_ -match "Entering '(.+)'"){$matches[1]} 
}

if(-not $submodulePaths){
  Write-Output "No submodules found"
  exit
}

foreach($path in $submodulePaths){
  Write-Output "Processing submodule: $path"
  Push-Location $path
  # Check for uncommited changes using 'git status --porcelain'
  $changes = git status --porcelain
  if($changes){
    Write-Output "Found Changes in $path. Staging all changes..."
    git add -A
    Write-Output "Commiting changes with message: $commmitMessage"
    gitr commit -m $commitMessgae

    Write-Ouput "pushing changes to remote"
    git push
  }else {
    Write-Output "No changes detected in $path"
  }
  Pop-Location
}

Write-Output "Subdmoule commit and push completed"

