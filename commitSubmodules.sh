#!/usr/bin/env zsh
# commitSubmodules.sh - Commits and pushes changes in all git submodules
# Compatible with both macOS and Linux

# Default commit message
COMMIT_MESSAGE="Auto-Commit local changes in submodules"

# Get the full path to git
GIT_CMD=$(which git)

# Parse command line arguments
if [[ $# -gt 0 ]]; then
  COMMIT_MESSAGE="$1"
fi

echo "Script started. Looking for submodules..."

# Function to get and sort submodule paths
get_sorted_submodules() {
  # Get all submodule paths including nested ones using git submodule foreach --recursive
  local submodule_output
  submodule_output=$($GIT_CMD submodule foreach --recursive --quiet '
    if [[ "$toplevel" = "'$(pwd)'" ]]; then
      echo "$path"
    else
      # Get the relative path from the root repository
      relative_path="${PWD#'$(pwd)'/}"
      echo "$relative_path"
    fi
  ')
  
  if [[ -z "$submodule_output" ]]; then
    echo "No submodules found"
    return 1
  fi
  
  # Sort submodules by path depth (descending) to handle nested modules first
  # More nested paths have more slashes, so sort by number of slashes in reverse order
  printf "%s\n" "$submodule_output" | grep -v '^\s*$' | 
    awk '{print gsub("/", "/", $0) " " $0}' | sort -nr | cut -d' ' -f2- | uniq
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
  changes=$($GIT_CMD status --porcelain)
  
  if [[ -n "$changes" ]]; then
    echo "Found changes in $path. Staging all changes..."
    
    # Try to checkout main branch
    if ! $GIT_CMD checkout main 2>/dev/null; then
      # If main branch doesn't exist, try master
      if ! $GIT_CMD checkout master 2>/dev/null; then
        echo "Error: Could not checkout main or master branch in $path"
        cd "$ORIGINAL_DIR"
        continue
      fi
    fi
    
    # Stage all changes
    $GIT_CMD add -A
    
    echo "Committing changes with message: $COMMIT_MESSAGE"
    if ! $GIT_CMD commit -m "$COMMIT_MESSAGE"; then
      echo "Error: Failed to commit changes in $path"
      cd "$ORIGINAL_DIR"
      continue
    fi
    
    echo "Pushing changes to remote"
    if ! $GIT_CMD push; then
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

