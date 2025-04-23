#!/usr/bin/env zsh
# commitSubmodules.sh - Commits and pushes changes in all git submodules
# Compatible with both macOS and Linux

# Default commit message
COMMIT_MESSAGE="Auto-Commit local changes in submodules"

# Parse command line arguments
if [[ $# -gt 0 ]]; then
  COMMIT_MESSAGE="$1"
fi

echo "Script started. Looking for submodules..."

# Function to get and sort submodule paths
get_sorted_submodules() {
  # Get all submodule paths using git submodule foreach
  local submodule_output
  submodule_output=$(git submodule foreach --recursive 'echo $path' 2>/dev/null)
  
  if [[ -z "$submodule_output" ]]; then
    echo "No submodules found"
    return 1
  fi
  
  # Sort submodules by path depth (descending)
  echo "$submodule_output" | sort -r -t'/' -k1,1
}

# Store the original directory
ORIGINAL_DIR=$(pwd)

# Get sorted submodule paths
SUBMODULE_PATHS=$(get_sorted_submodules)

if [[ $? -ne 0 ]]; then
  echo "No submodules found"
  exit 0
fi

echo "Submodule paths detected:"
echo "$SUBMODULE_PATHS" | while read -r path; do
  echo "- $path"
done

# Process each submodule
echo "$SUBMODULE_PATHS" | while read -r path; do
  if [[ -z "$path" ]]; then
    continue
  fi
  
  echo "Processing submodule: $path"
  
  # Try to change to the submodule directory
  if ! cd "$path" 2>/dev/null; then
    echo "Error: Could not navigate to submodule directory $path"
    cd "$ORIGINAL_DIR"
    continue
  fi
  
  # Check for uncommitted changes
  changes=$(git status --porcelain)
  
  if [[ -n "$changes" ]]; then
    echo "Found changes in $path. Staging all changes..."
    
    # Try to checkout main branch
    if ! git checkout main 2>/dev/null; then
      # If main branch doesn't exist, try master
      if ! git checkout master 2>/dev/null; then
        echo "Error: Could not checkout main or master branch in $path"
        cd "$ORIGINAL_DIR"
        continue
      fi
    fi
    
    # Stage all changes
    git add -A
    
    echo "Committing changes with message: $COMMIT_MESSAGE"
    if ! git commit -m "$COMMIT_MESSAGE"; then
      echo "Error: Failed to commit changes in $path"
      cd "$ORIGINAL_DIR"
      continue
    fi
    
    echo "Pushing changes to remote"
    if ! git push; then
      echo "Error: Failed to push changes in $path"
      cd "$ORIGINAL_DIR"
      continue
    fi
  else
    echo "No changes detected in $path"
  fi
  
  # Return to original directory
  cd "$ORIGINAL_DIR"
done

echo "Submodule commit and push completed"

# Make script executable
# chmod +x commitSubmodules.sh

