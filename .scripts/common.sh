#!/bin/bash

set +x

# shellcheck disable=SC2034
base_dir="$(git rev-parse --show-toplevel)"

pod_update() {
	pod repo update --silent || return "${PIPESTATUS[*]}"
}

pod_install() {
	dir=$1
	{ 
		cd "${dir}" &&
		pod install --silent  &&
		cd - > /dev/null 
	} || return "${PIPESTATUS[*]}"
}

pod_deintegrate() {
	dir=$1
	{ 
		cd "${dir}" && 
		pod deintegrate --silent &&
		cd - > /dev/null 
	} || return "${PIPESTATUS[*]}"
}

pod_cleanup() {
	dir=$1
	{
		rm -rf "${dir}/Pods"  &&
		rm -rf "${dir}/Podfile.lock"  &&
		rm -rf "${dir}/*.xcworkspace"
	} || return "${PIPESTATUS[*]}"
}
