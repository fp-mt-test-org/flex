#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

git_status=$(git status)

if ! [[ "${git_status}" =~ "nothing to commit, working tree clean" ]]; then
    echo "ERROR: You have uncommitted changes."
    echo ""
    echo "Please commit, stash or revert any pending changes then try pushing again."
    echo ""
    echo "The reason for this is push will first test your local codebase and then push the changes. However, uncommitted changes would be tested and not pushed leading to unpredictable results downstream."
    exit 1
fi

git push
