#!/bin/bash

# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

# Update cocoapods master repo
# pod_update

# shellcheck disable=SC2154
examples_dir="${base_dir}/Examples" 
for script in "${examples_dir}"/*/build.sh
do	
	example="$(basename "$(dirname "${script}")")"
	example_dir="${examples_dir}/${example}"

	echo "Building ${example}"
	{
		pod_install  "${example_dir}" &&
		cd "${example_dir}" &&
		. "${script}" &&
		cd - > /dev/null &&
		pod_deintegrate "${example_dir}" 
		pod_cleanup  "${example_dir}"
	} || exit "${PIPESTATUS[*]}"
done
