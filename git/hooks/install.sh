#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

echo "Installing git hooks..."

cp -v ./git/hooks/pre-commit .git/hooks

echo "Git hook installation completed."
