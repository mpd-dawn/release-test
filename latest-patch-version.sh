#!/bin/bash

# Get current commit
current_commit=$(git rev-parse HEAD)

# Get the latest tag of the current commit if it exists
latest_tag=$(git describe --tags --exact-match $current_commit 2>/dev/null)

# If no tag is found for the current commit, find the latest tag.
if [ -z "$latest_tag" ]; then
  latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
  # Extract the patch version from the tag (format is vX.Y.Z-envPostfix)
  patch_version=$(echo $latest_tag | awk -F'[.-]' '{print $3}')
  # Increment the patch version
  patch_version=$((patch_version + 1))
else
  # Extract the patch version from the tag (format is vX.Y.Z-envPostfix)
  patch_version=$(echo $latest_tag | awk -F'[.-]' '{print $3}')
fi

# Export the patch version as an environment variable
echo $patch_version