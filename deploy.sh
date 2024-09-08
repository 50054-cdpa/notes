mkdocs build
git stash
git checkout gh-pages
git pull
cp -rf ./site ./
rm -rf ./site
git commit -m "built and deployed docs manually"
git push
git checkout main
git stash pop
