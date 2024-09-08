#!/bin/bash

current_branch=$(git branch --show-current)

mkdocs build
git stash
git switch -c gh-pages
cp -rf ./site ./
rm -rf ./site
git commit -m "built and deployed docs manually"
git push
git checkout "$current_branch"
git stash pop
