#!/bin/bash

PUBLISH_REPO=git@github.com:cbracken/cbracken.github.io.git

if ! git diff-index --quiet HEAD --; then
  echo >&2 "Not all diffs have been committed. Aborting."
  exit 1
fi

# Check for hugo command.
command -v hugo >/dev/null 2>&1 || { echo >&2 "hugo not found. Aborting."; exit 1; }

# If public dir exists, abort.
if [[ -d public ]]; then
  echo >&2 "public directory already exists. Aborting."
  exit 1
fi

# Clone the repo and build.
git clone $PUBLISH_REPO public
hugo || { echo >&2 "hugo build failed. Aborting."; exit 1; }

# Check diffs and publish.
echo "Build succeeded. Checking diffs..."
git -C public status
if git -C public diff-index --quiet HEAD --; then
  echo >&2 "No changes to published site."
else
  git -C public diff
  read -p "Commit and publish? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git -C public add .
    git -C public commit -m "Publish site"
    git -C public push origin master
  fi
fi

echo "Cleaning up..."
rm -rf public
