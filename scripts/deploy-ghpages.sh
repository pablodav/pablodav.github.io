#!/bin/sh
# ideas used from https://gist.github.com/motemen/8595451
# https://github.com/DevProgress/onboarding/wiki/Using-Circle-CI-with-Github-Pages-for-Continuous-Delivery

# abort the script if there is a non-zero error
set -e

# show where we are on the machine
pwd


siteSource="$1"

if [ ! -d "$siteSource" ]
then
    echo "Usage: $0 <site source dir>"
    exit 1
fi

# read the remote config from submodule
cd $siteSource
remote=$(git config remote.origin.url)
cd ..

# make a directory to put the gh-pages branch
#mkdir gh-pages-branch
#cd gh-pages-branch
# now lets setup a new repo so we can update the gh-pages branch

# if GH_EMAIL is set, use it:
if [ ! -z "${GH_EMAIL}" ]; then
    git config --global user.email "$GH_EMAIL" > /dev/null 2>&1
fi

# if GH_NAME is set, use it:
if [ ! -z "$GH_NAME" ]; then
    git config --global user.name "$GH_NAME" > /dev/null 2>&1
fi

# Thes are original steps not necesary when you are not using gh-pages branch
#git init
#git remote add --fetch origin "$remote"
# switch into the the gh-pages branch
#if git rev-parse --verify origin/gh-pages > /dev/null 2>&1
#then
#    git checkout gh-pages
    # delete any old site as we are going to replace it
    # Note: this explodes if there aren't any, so moving it here for now
#    git rm -rf .
#else
#    git checkout --orphan gh-pages
#fi

# Update your submodules with public dir and also themes
rm -rf $siteSource
git submodule update --init --recursive
cd $siteSource
git checkout master
git pull origin master
cd ..

# copy over or recompile the new site
# cp -a "../${siteSource}/." .

hugo --buildDrafts

sleep 4

# move to pulic directory
cd public

# stage any changes and new files
git add -A
# now commit, ignoring branch gh-pages doesn't seem to work, so trying skip
git commit --allow-empty -m "Deploy to GitHub pages [ci skip]"
# and push, but send any output to /dev/null to hide anything sensitive
git push --force --quiet origin master > /dev/null 2>&1

# go back to where we started and remove the gh-pages git repo we made and used
# for deployment
#cd ..
#rm -rf gh-pages-branch

echo "Finished Deployment!"
