#!/bin/bash

#
# This script determines the latest patch version based on the branch name and the latest tag.
# The script is intended to be used in a CI/CD pipeline to determine the next patch version for a release.
# The script assumes that the branch name follows the format 'release/x.y' where x is the major version and y is the minor version.
# The script also assumes that the tags follow the format 'vX.Y.Z-env' where X is the major version, Y is the minor version, and Z is the patch version. the -env is only for non production releases. 
#

# Last part of the branch name. If the branch is 'release/1.4' this should be '1.4' (Build.SourceBranchName in Azure DevOps).
branch_name=$1

# Environment suffix of the tag. If environment is 'qa' this should be '-qa'.
env_suffix=$2

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
echo "Latest tag: $latest_tag"
if [ -z "$latest_tag" ]; then
  latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
fi

# Extract the major, minor, and patch versions from the latest tag
IFS='.-' read -r tag_major tag_minor patch env <<< "${latest_tag#v}"

if [ "-$env" != "$env_suffix" ]; then
  patch_version=$patch
fi

# Extract the major and minor versions from the branch name
major=$(echo $branch_name | awk -F'.' '{print $1}' | sed 's/v//')
minor=$(echo $branch_name | awk -F'.' '{print $2}')

# Check if the major or minor version from the branch name has changed compared to the latest tag
if [ "$major" != "$tag_major" ] || [ "$minor" != "$tag_minor" ]; then
  patch_version=0
elif [ "-$env" == "$env_suffix" ]; then
  patch_version=$((patch + 1))
fi

# Check if the tag with the current patch version already exists and increment the patch version if it does.
# This is to support deploying 1.5.2 to QA and then to Training and then afterwards deploying to QA again from the same branch.
while git rev-parse "v$major.$minor.$patch_version$env_suffix" >/dev/null 2>&1; do
  patch_version=$((patch + 1))
done

echo $patch_version