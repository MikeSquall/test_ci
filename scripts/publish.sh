#!/bin/bash
set -e

echo "//registry.npmjs.org/:_authToken=\${NPM_TOKEN}" > .npmrc

VERSION=$(npm version | grep @ | sed -re "s/\{ '.*': '(.*)',?/\1/g")

if [[ "$TRAVIS_BRANCH" =~ ^feature\/.*$ ]]; then
    BRANCH_NAME=$(echo $TRAVIS_BRANCH | sed "s/[_/]/-/g")
    TIMESTAMP=$(date +"%s")
    echo $VERSION-$BRANCH_NAME-$TIMESTAMP
    echo "--------------------------------------------"
    echo "|    Deploying snapshot on npm registry    |"
    echo "--------------------------------------------"
    npm version $VERSION-$BRANCH_NAME-$TIMESTAMP
    npm publish --tag snapshot
elif [[ "$TRAVIS_BRANCH" == "develop" ]] && [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    echo $VERSION
    echo "--------------------------------------------"
    echo "|     Deploying latest on npm registry     |"
    echo "--------------------------------------------"
    git remote set-url origin https://${GH_TOKEN}@github.com/capsulajs/capsulahub.git
    git checkout develop
    npm version patch
    npm publish --access public
    npm publish --access public
else
    echo "*************************************************"
    echo "*   Not a pull request, npm publish skipped !   *"
    echo "*************************************************"
fi
