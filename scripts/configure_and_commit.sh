#!/bin/bash

TRAVIS_EVENT_TYPE="$1"
TRAVIS_REPO_SLUG="$2"

git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"

base_branch="$TRAVIS_PULL_REQUEST_BRANCH"
branch_name="$TRAVIS_BRANCH"
#hjdvblk
evaluate_and_set_version() {
  if [[ $TRAVIS_EVENT_TYPE == 'pull_request' && $TRAVIS_PULL_REQUEST_MERGED == 'true' ]]; then
    case "$base_branch-$branch_name" in
      'qa-dev') evaluate_dev_version ;;
      'master-qa') npm version minor ;;
      *'fix'*) npm version patch ;;
      *) echo "Error: Invalid event or branch combination." >&2; exit 1 ;;
    esac
  fi
}

evaluate_dev_version() {
    dev_version=$(git show origin/dev:package.json | jq -r .version)
    dev_minor=$(echo "$dev_version" | cut -d. -f2)
    echo "Versión minor dev: $dev_minor"
    
    qa_version=$(git show refs/heads/qa:package.json | jq -r .version)
    qa_minor=$(echo "$qa_version" | cut -d. -f2)
    echo "Versión minor qa: $qa_minor"

    if [[ $dev_minor == $qa_minor ]]; then
      npm --no-git-tag-version version preminor --preid=beta
    else
      npm --no-git-tag-version version prerelease --preid=beta
    fi
}

set_outputs() {
  echo "::set-output name=base_branch::$base_branch"
  echo "::set-output name=branch_name::$branch_name"
  version=$(npm version)
  echo "::set-output name=version::$version"
}

commit_and_push_version_update() {
  echo "Base branch: $base_branch"
  echo "Branch name: $branch_name"
  git fetch origin "$base_branch":"$base_branch" || true
  git checkout "$base_branch" || true
  git add .
  git commit -am "Update version" || true
  git checkout "$base_branch"
  git push origin "$base_branch" --follow-tags || true
}

# Main script
evaluate_and_set_version
set_outputs
commit_and_push_version_update
