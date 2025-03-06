#!/bin/bash

# Last part of the branch name. If the branch is 'release/1.4' this should be '1.4' (Build.SourceBranchName in Azure DevOps).
branch_name=$1

env_suffix=$2

# Get the latest tag of the current commit if it exists
current_commit=$(git rev-parse HEAD)

# Find the latest tag based on version number and environment suffix
# This is to support a tag having the same commit id as the previous tag
tags=$(git tag)
latest_tag=""
for tag in $tags; do
  if [[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    if [ -z "$latest_tag" ] || [ "$(printf '%s\n' "$tag" "$latest_tag" | sort -V | tail -n1)" == "$tag" ]; then
      latest_tag=$tag
    fi
  fi
done

if [ -z "$latest_tag" ]; then
  latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
fi


# # Checks if latest_tag is empty
# if [ -z "$latest_tag" ]; then
#   latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
#   patch_version=$(echo $latest_tag | awk -F'[.-]' '{print $3}')  
# else
#   patch_version=0
# fi
# echo $latest_tag

# Extract the major, minor, and patch versions from the latest tag
IFS='.-' read -r tag_major tag_minor patch env <<< "${latest_tag#v}"

if [ "$env" != "$env_suffix" ]; then
  patch_version=$patch
fi


# Extract the major and minor versions from the branch name
major=$(echo $branch_name | awk -F'.' '{print $1}' | sed 's/v//')
minor=$(echo $branch_name | awk -F'.' '{print $2}')

# Check if the major or minor version from the branch name has changed compared to the latest tag
if [ "$major" != "$tag_major" ] || [ "$minor" != "$tag_minor" ]; then
  patch_version=0
elif [ "$env" == "$env_suffix" ]; then
  patch_version=$((patch + 1))
fi

echo $patch_version