#!/bin/bash

TRAVIS_EVENT_TYPE="$1"
TRAVIS_REPO_SLUG="$2"
GH_TOKEN="$3"

create_branch_and_pr() {
  if [[ $TRAVIS_EVENT_TYPE == 'pull_request' && $TRAVIS_PULL_REQUEST_SLUG == "$TRAVIS_REPO_SLUG" && $TRAVIS_PULL_REQUEST_MERGED == 'true' && $TRAVIS_PULL_REQUEST_BRANCH == 'master' ]]; then
    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"

    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "Travis CI"

    git fetch origin master
    git checkout -b "$reintegrate_branch" master
    git push origin "$reintegrate_branch"

    PR_TITLE="Reintegrate $version to dev"
    curl -X POST \
      -H "Authorization: Bearer $GH_TOKEN" \
      -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
      "https://api.github.com/repos/$TRAVIS_REPO_SLUG/pulls"
  else
    echo "Branch is not master or not a pull request"
  fi
}

# Main script
create_branch_and_pr
