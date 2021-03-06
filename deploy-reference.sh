#!/bin/sh

# Push all png 

set -e

cd "${TRAVIS_BUILD_DIR}"

git config --global push.default simple
git config user.name "Travis CI"
git config user.email "travis@travis-ci.org"

git checkout "${TRAVIS_BRANCH}"
git add --all
git commit -m "Update reference png for commits: ${TRAVIS_COMMIT_RANGE}" -m "Travis build: ${TRAVIS_BUILD_NUMBER} [ci skip]"
git push "https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git" "${TRAVIS_BRANCH}"
