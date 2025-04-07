param(
  [string]$commitMessage = "Auto-Commit local changes in submodules"
)

Write-Output "Script started. Looking for submodules..."



# Get all submodule paths (including nested ones) using git submodule foreach
# 
$submodulePaths = git submodule foreach --recursive 2>&1 | ForEach-Object {
  if($_ -match "Entering '(.+)'"){
    $matches[1]
  }
}

# Sort the submodules by path depth
$submodulePaths = $submodulePaths | Sort-Object {($_ -split '/').Length} -Descending # Shortest path first

Write-Output "Submodule paths detected:"
$submodulePaths | ForEach-Object { Write-Output "- $_" }

if(-not $submodulePaths){
  Write-Output "No submodules found"
  exit
}

foreach($path in $submodulePaths){
  Write-Output "Processing submodule: $path"
  try {
    Push-Location $path -ErrorAction Stop
    # Check for uncommited changes using 'git status --porcelain'
    $changes = git status --porcelain
    if($changes){
      Write-Output "Found Changes in $path. Staging all changes..."
      git checkout main
      git add -A
      Write-Output "Commiting changes with message: $commitMessage"
      git commit -m $commitMessage

      Write-Output "Pushing changes to remote"
      git push
    }else {
      Write-Output "No changes detected in $path"
    }
  }
  catch {
    Write-Output "Error processing submodule $path`: $($_.Exception.Message)"
  }
  finally {
    Pop-Location # Return to parent directory first after processing each submodule
  }
}

Write-Output "Submodule commit and push completed"

