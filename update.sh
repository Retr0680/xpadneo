#!/bin/bash

cd "$(dirname "$0")"
source "lib/installer.sh"

set -e

LATEST=$(get_upstream_version_latest)
CURRENT_KERNEL=$(uname -r)

current_kernel_module_installed() {
    local status
    status=$("${DKMS_BIN}" status -m hid-xpadneo -v "${VERSION}" -k "${CURRENT_KERNEL}" 2>/dev/null || true)
    [[ "${status}" == *": installed"* ]] &&
        modinfo -k "${CURRENT_KERNEL}" hid_xpadneo >/dev/null 2>&1
}

reinstall() {
    if current_kernel_module_installed; then
        echo "You have already installed ${VERSION} for kernel ${CURRENT_KERNEL}."
    else
        echo "* repairing DKMS installation for kernel ${CURRENT_KERNEL}"
        echo "* uninstalling outdated modules"
        VERSION="${VERSION}" ./uninstall.sh

        echo "* installing repository version ${VERSION}"
        VERSION="${VERSION}" ./install.sh --force
    fi

    echo "* restarting driver module"
    modprobe -r hid_xpadneo 2>/dev/null || true
    modprobe hid_xpadneo
}

if [[ "${LATEST}" == "${VERSION}" ]]; then
    echo "Looks like the repo is up to date, checking DKMS installation."
    reinstall
elif __version_lte "${LATEST}" "${VERSION}" ; then
    echo "Looks like you are on a developer version, checking DKMS installation."
    reinstall
else
    echo "Latest stable version: ${LATEST}"
    echo "Installed versions: ${INSTALLED[*]}"
    echo "Repository version: ${VERSION}"

    if [[ "${GIT_ROOT}" != "" ]]; then
        echo "Please update this directory by running 'git reset --hard' and 'git pull', afterwards run this script again"
    else
        echo "Please update this directory by downloading the latest version from https://github.com/atar-axis/xpadneo/archive/${LATEST}.tar.gz"
    fi
    exit 1
fi
