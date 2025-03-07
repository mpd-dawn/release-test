#!/bin/bash

#
# The script:
# - determines the latest patch version based on the branch name and the latest tag.
# - is intended to be used in a CI/CD pipeline to determine the next patch version for a release.
# - assumes that the branch name follows the format 'release/x.y' where x is the major version and y is the minor version.
# - also assumes that the tags follow the format 'vX.Y.Z-env' where X is the major version, Y is the minor version, and Z is the patch version. the -env is only for non production releases. 
# - does not support deploying out of order, e.g. deploying to production before deploying to QA. This is because the script does not know anything about order of environments.
# This will result in the patch version being incremented for the production release but when QA is being deployed it uses the same patch as production since it think it .
#

# Last part of the branch name. If the branch is 'release/1.4' this should be '1.4' (Build.SourceBranchName in Azure DevOps).
branch_name=$1

# Environment suffix of the tag. If environment is 'qa' this should be '-qa'.
env_suffix=$2

# Extract the major and minor versions from the branch name
major=$(echo $branch_name | awk -F'.' '{print $1}' | sed 's/v//')
minor=$(echo $branch_name | awk -F'.' '{print $2}')

# Find the latest tag based on version number
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

# Extract the major, minor, and patch versions from the latest tag
IFS='.-' read -r tag_major tag_minor patch env buildnumber <<< "${latest_tag#v}"

# If the environment part of the latest tag is different from the environment we are deploying to, we do not increment the patch version
if [ "-$env" != "$env_suffix" ]; then
  patch_version=$patch
fi

# Check if the major or minor version from the branch name has changed compared to the latest tag
if [ "$major" != "$tag_major" ] || [ "$minor" != "$tag_minor" ]; then
  patch_version=0
elif [ "-$env" == "$env_suffix" ]; then
  patch_version=$((patch + 1))
fi

# Check if the tag with the current patch version already exists and increment the patch version if it does.
# This is to support deploying 1.5 to QA (resulting in 1.5.1-qa) and then to Training (resulting in 1.5.1-training) and then afterwards deploying to QA again from the same branch (resulting in 1.5.2-qa).
while git tag | grep -q "^v$major.$minor.$patch_version$env_suffix"; do
  patch_version=$((patch + 1))
done

echo $patch_version