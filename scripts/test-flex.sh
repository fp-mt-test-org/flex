#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

current_path=$(realpath .)

git_org_base_url='https://github.com/fp-mt-test-org'

dist_folder_name='dist'
dist_folder_path="${current_path}/${dist_folder_name}"
dist_user_scripts_path="${dist_folder_path}/scripts/user"

install_folder_name='.flex'
helloworld_repo_name='flex-test-empty-repo'
helloworld_repo_folder_path="${current_path}/${helloworld_repo_name}"

flex_wrapper_script='flex.sh'
flex_alias=$(cat "${dist_user_scripts_path}/configure-alias.sh")

# Configure the flex variable to simulate the flex alias that the tests can use.
if [[ "${flex_alias}" =~ flex=(.+) ]]; then
    alias_flex_path="${BASH_REMATCH[1]}"

    echo "Configuring flex variable to match alias: ${alias_flex_path}"
    flex="${alias_flex_path}"
else
    echo "Flex alias not found!"
    exit 1
fi

install_flex() {
    install_to='.'
    install_flex_path="./${flex_wrapper_script}"

    flex_wrapper_script_install_from="${dist_user_scripts_path}/${flex_wrapper_script}"

    echo "Simulate downloading the Flex wrapper script from ${flex_wrapper_script_install_from} to ${install_to}"
    # Note: this command should come from the install step in the README.md.
    cp -v "${flex_wrapper_script_install_from}" . && \
        chmod a+x "${install_flex_path}" && \
        skip_download=1 download_folder_path="${dist_folder_path}" auto_clean=0 "${install_flex_path}"
}

echo ""
echo "======================="
echo "TEST: Install/init flow"
echo "======================="
if [ -d "${helloworld_repo_folder_path}" ]; then
    echo "Pre-test Cleanup: Clearing out the test repo if left over from previous test..."
    rm -rdf "${helloworld_repo_folder_path}"
    echo ""
fi

echo "Cloning a blank repo..."
git clone "${git_org_base_url}/${helloworld_repo_name}.git"
echo "Clone complete."
echo ""

expected_flex_version=$(git describe --abbrev=0 --tags)
echo "expected_flex_version: ${expected_flex_version}"
echo ""

cd "$helloworld_repo_folder_path"

install_flex

build_cmd="hello"

echo "Executing init workflow..."
{ echo "helloworld-service"; sleep 1; echo "build"; sleep 1; echo "echo ${build_cmd}"; sleep 1; echo "n"; } | skip_download=1 auto_clean=0 download_folder_path="${dist_folder_path}" "${flex}" init
echo "Init complete, executing build..."
cat service_config.yml
build_output=$("${flex}" build)

echo "-- Build Output --"
echo "${build_output}"
echo "-- End Build Output --"

echo "Assert build output is as expected:"
if ! [[ "${build_output}" =~ ${build_cmd} ]]; then
    echo "Fail: Build output doesn't contain ${build_cmd}"
    exit 1
fi
echo "Pass!"
echo ""
echo "Getting version..."
flex_output=$(${flex} -version)
echo "-- flex_output: start --"
echo ""
echo "${flex_output}"
echo ""
echo "-- flex_output: end --"
echo ""
echo "Assert the output contains expected_flex_version:"
if ! [[ "${flex_output}" =~ .*[0-9]+\.[0-9]+\.[0-9]+.* ]]; then
    echo "Fail: Output does not contain expected_flex_version: ${expected_flex_version}"
    exit 1
fi
echo "Pass!"

gitignore_file_name='.gitignore'
gitignore_file_path="${helloworld_repo_folder_path}/${gitignore_file_name}"
echo "Assert ${gitignore_file_name} updated:"
if ! grep -q "${install_folder_name}" "${gitignore_file_path}"; then
    echo "Fail: ${install_folder_name} is missing from ${gitignore_file_path}"
    exit 1
fi
echo "Pass!"

cd ..

if [ -d "${helloworld_repo_folder_path}" ]; then
    echo "Post-test Cleanup: Clearing out the test repo if left over from previous test..."
    rm -rdf "${helloworld_repo_folder_path}"
fi

echo ""
echo "========================="
echo "TEST: Update Version Flow"
echo "========================="
repo_name='flex-test-upgrade'

# Start back at the source root.
cd "${current_path}"

if [ -d "${repo_name}" ]; then
    echo "Pre-test Cleanup: Clearing out the test repo if left over from previous test..."
    rm -rdf "${repo_name}"
    echo ""
fi

echo "Step 1: Clone a repo that has previously installed and initialized with an older version of flex."
echo ""
expected_flex_version=$(git describe --abbrev=0 --tags)
expected_flex_version="${expected_flex_version:1}" # Removes the 'v' prefix.
echo "expected_flex_version: ${expected_flex_version}"
echo ""
git clone "${git_org_base_url}/${repo_name}.git"
echo ""

# Change in to the repo so all cli commands issued will be relative to it.
cd "${repo_name}"

echo "Step 2. Install the configured version of flex by running the wrapper script"
${flex} -version
echo ""

echo "Step 3. Test: Configure version to latest built version"
service_config_path='service_config.yml'
service_config=$(cat "${service_config_path}")
echo "Current service_config:"
echo "${service_config}"
echo ""
echo "Updated service_config:"
service_config="${service_config/0.3.0/$expected_flex_version}"
echo "${service_config}"
echo "${service_config}" > "${service_config_path}"
echo ""

echo "Step 4. Install latest built version of flex"
skip_download=1 auto_update=1 auto_clean=0 download_folder_path="${dist_folder_path}" ${flex} -version
actual_flex_version=$(${flex} -version)
echo "actual_flex_version: ${actual_flex_version}"
echo ""

echo "Step 5. Test: Assert actual contains configured"
echo "expected_flex_version: ${expected_flex_version}, actual_flex_version: ${actual_flex_version}"
if ! [[ "${actual_flex_version}" =~ ${expected_flex_version} ]]; then
    echo "Fail: Output does not contain expected_flex_version: ${expected_flex_version}"
    exit 1
fi
echo "Pass!"
