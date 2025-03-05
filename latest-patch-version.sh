#!/bin/bash

branch_name=$1

# Get the latest tag of the current commit if it exists
current_commit=$(git rev-parse HEAD)
latest_tag=$(git describe --tags --exact-match $current_commit 2>/dev/null)

major=$(echo $branch_name | awk -F'.' '{print $1}' | sed 's/v//')
minor=$(echo $branch_name | awk -F'.' '{print $2}')

if [ -z "$latest_tag" ]; then
  latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
  patch_version=$(echo $latest_tag | awk -F'[.-]' '{print $3}')
  
  # Extract the major, minor, and patch versions from the latest tag
  IFS='.-' read -r tag_major tag_minor patch env <<< "${latest_tag#v}"
  
  # Check if the major or minor version has changed
  if [ "$major" != "$tag_major" ] || [ "$minor" != "$tag_minor" ]; then
    patch_version=0
  else
    patch_version=$((patch + 1))
  fi
else
  patch_version=0
fi

# Export the patch version as an environment variable
echo $patch_version