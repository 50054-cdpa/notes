#!/bin/bash

set -e

current_branch=$(git branch --show-current)

mkdocs build
git stash
git switch -C gh-pages
find . -maxdepth 1 ! -name ".git" ! -name "." ! -name "site" -exec rm -rf {} \;
cp -rf ./site/* ./
rm -rf ./site
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "built and deployed docs manually"
  git push
fi
git checkout "$current_branch"
git stash pop
