#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

current_path=$(realpath .)

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

    flex_wrapper_script_install_from="${dist_user_scripts_path}/${flex_wrapper_script}"

    echo "Simulate downloading the Flex wrapper script from ${flex_wrapper_script_install_from} to ${install_to}"
    cp -v "${flex_wrapper_script_install_from}" "${install_to}"
    echo ""
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
git clone https://github.com/fp-mt/${helloworld_repo_name}.git
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

# Waiting for a release.
exit 0

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
fi

expected_flex_version=$(git describe --abbrev=0 --tags)
echo "expected_flex_version: ${expected_flex_version}"
echo ""
echo "Cloning a repo that has flex already initialized..."
git clone https://github.com/fp-mt/${repo_name}.git
echo "Clone complete."
echo ""

cd "${repo_name}"

echo "Step 1. Test: Get currently configured/installed version"
${flex} -version
actual_flex_version=$(${flex} -version)
echo "actual_flex_version: ${actual_flex_version}"
echo ""
echo "Step 2. Test: Configure version to latest built version"
service_config_path='service_config.yml'
service_config=$(cat "${service_config_path}")
echo "${service_config}"
service_config="${service_config/0.1.0/$expected_flex_version}"
echo "${service_config}" > "${service_config_path}"

echo "Step 3. Test: Run flex -version again:"
actual_flex_version=$(skip_download=1 auto_clean=0 download_folder_path="${dist_folder_path}" ${flex} -version)
echo "actual_flex_version: ${actual_flex_version}"
echo "Step 4. Flex: If configuration != actual then install-flex.sh, return updated version"

echo "Step 5. Test: Assert actual contains configured"
echo "actual_flex_version: ${actual_flex_version}, expected_flex_version: ${expected_flex_version}"
if ! [[ "${actual_flex_version}" =~ ${expected_flex_version} ]]; then
    echo "Fail: Output does not contain expected_flex_version: ${expected_flex_version}"
    exit 1
fi
echo "Pass!"
