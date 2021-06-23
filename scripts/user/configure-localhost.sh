#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

case "$SHELL" in
 "/bin/zsh") profile_path=~/.zshrc ;;
 *) profile_path=~/.zshrc ;;
esac

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
flex_alias=$(cat "${script_path}/configure-alias.sh")

update_profile() {
    profile_path="${1}"
    flex_alias="${2}"

    echo -e "${flex_alias}\n${profile_content}" > "${profile_path}"
    echo "Added ${flex_alias} to your ${profile_path}"

    # Start a new shell session so that the
    # user can use the alias immediately.
    $SHELL
}

if [[ -f "${profile_path}" ]]; then
    if ! grep -q "${flex_alias}" "${profile_path}" ; then
        profile_content=$(cat "${profile_path}") 
        update_profile "${profile_path}" "${flex_alias}"
    fi
else
    update_profile "${profile_path}" "${flex_alias}"
fi
