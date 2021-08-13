#!/bin/sh

PUBLISH_REPO=git@git.bracken.jp:chris.bracken.jp.git

# Returns whether the git repo at path $1 has any uncommitted diffs.
has_diffs() {
  git -C $1 status > /dev/null
  git -C $1 diff-index --quiet HEAD -- && return 1 || return 0
}

# Prompts the user with $1. Returns whether user replied y/Y.
prompt_yn() {
  read -p "$1" -r REPLY
  echo
  test `echo $REPLY | tr a-z A-Z | head -c 1` = Y
}

# Check for hugo command.
command -v hugo >/dev/null 2>&1 || { echo >&2 "hugo not found. Aborting."; exit 1; }

# If blog repo has uncommitted diffs, abort.
if has_diffs .; then
  echo >&2 "Not all diffs have been committed. Commit and re-run. Aborting."
  exit 1
fi

# If public dir exists, abort.
if [ -d public ]; then
  echo >&2 "public directory exists. Remove and re-run. Aborting."
  exit 1
fi

# Clone the repo and build.
git clone $PUBLISH_REPO public
hugo || { echo >&2 "hugo build failed. Aborting."; exit 1; }

# Check diffs and publish.
echo "Build succeeded. Checking diffs..."
if ! has_diffs public; then
  echo >&2 "No changes to published site."
else
  git -C public diff
  if prompt_yn "Commit and publish? "; then
    git -C public add .
    git -C public commit -S -m "Publish site"
    git -C public push origin master
  fi
fi

echo "Cleaning up..."
rm -rf public
