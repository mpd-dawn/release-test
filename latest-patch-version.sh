#!/bin/bash

# Get current commit
current_commit=$(git rev-parse HEAD)

# Get the latest tag of the current commit if it exists
latest_tag=$(git describe --tags --exact-match $current_commit 2>/dev/null)

# If no tag is found for the current commit, find the latest tag.
# This should only happen when it is a QA build.
if [ -z "$latest_tag" ]; then
  latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
fi

# Extract the patch version from the tag (format is vX.Y.Z-envPostfix)
patch_version=$(echo $latest_tag | awk -F'[.-]' '{print $3}')

# Export the patch version as an environment variable
export latest_patch_version=$patch_version