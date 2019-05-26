#!/bin/bash
set -e

echo "//registry.npmjs.org/:_authToken=\${NPM_TOKEN}" > .npmrc

VERSION=$(npm version | grep @ | sed -re "s/\{ '.*': '(.*)',?/\1/g")

setup_git() {
  # Set the user name and email to match the API token holder
  # This will make sure the git commits will have the correct photo
  # and the user gets the credit for a checkin
  git config --global user.email "arbib.michael@gmail.com"
  git config --global user.name "MikeSquall"
  git config --global push.default matching
  
  # Get the credentials from a file
  git config credential.helper "store --file=.git/credentials"
  
  # This associates the API Key with the account
  echo "https://${GH_TOKEN}:@github.com" > .git/credentials
}


make_version() {
  # Make sure that the workspace is clean
  # It could be "dirty" if
  # 1. package-lock.json is not aligned with package.json
  # 2. npm install is run
  git checkout -- .

  # Echo the status to the log so that we can see it is OK
  git status

  # Run the deploy build and increment the package versions
  # %s is the placeholder for the created tag
  npm version patch -m "chore: publish version %s [skip ci]"
}

upload_files() {
  # This make sure the current work area is pushed to the tip of the current branch
  git push origin HEAD:$TRAVIS_BRANCH

  # This pushes the new tag
  git push --tags
}

if [[ "$TRAVIS_BRANCH" =~ ^feature\/.*$ ]]; then
    BRANCH_NAME=$(echo $TRAVIS_BRANCH | sed "s/[_/]/-/g")
    TIMESTAMP=$(date +"%s")
    echo $VERSION-$BRANCH_NAME-$TIMESTAMP
    echo "--------------------------------------------"
    echo "|    Deploying snapshot on npm registry    |"
    echo "--------------------------------------------"
    npm version $VERSION-$BRANCH_NAME-$TIMESTAMP
    npm publish --tag snapshot
elif [[ "$TRAVIS_BRANCH" == "master" ]] && [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    echo $VERSION
    echo "--------------------------------------------"
    echo "|     Deploying latest on npm registry     |"
    echo "--------------------------------------------"
    setup_git
    make_version
    upload_files
    npm publish --access public
else
    echo "*************************************************"
    echo "*   Not a pull request, npm publish skipped !   *"
    echo "*************************************************"
fi
