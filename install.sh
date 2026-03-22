#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="${HOME}/.config/docker-tools"

# Detect if running via curl | bash (no BASH_SOURCE file on disk)
# or running from a local clone.
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && -f "${BASH_SOURCE[0]}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	USE_LOCAL=1
else
	USE_LOCAL=0
fi

# ─── GitHub config ────────────────────────────────────────────────────────────
GITHUB_USER="manhtai831"
GITHUB_REPO="tools"
GITHUB_BRANCH="main"
ZIP_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.zip"

# ─── Download repo zip if not local ──────────────────────────────────────────

if [[ "${USE_LOCAL}" -eq 0 ]]; then
	require_cmd() {
		command -v "$1" >/dev/null 2>&1 || { echo "Error: required command not found: $1" >&2; exit 1; }
	}
	require_cmd curl
	require_cmd unzip

	TMP_DIR="$(mktemp -d)"
	trap 'rm -rf "${TMP_DIR}"' EXIT

	echo "Downloading repo from GitHub ..."
	curl --fail --silent --show-error -L "${ZIP_URL}" -o "${TMP_DIR}/repo.zip"

	echo "Extracting ..."
	unzip -q "${TMP_DIR}/repo.zip" -d "${TMP_DIR}"

	# GitHub zip giải nén ra thư mục tên: <repo>-<branch>
	SCRIPT_DIR="${TMP_DIR}/${GITHUB_REPO}-${GITHUB_BRANCH}"
fi

# ─── Install binaries ─────────────────────────────────────────────────────────

echo "Installing binaries to ${INSTALL_DIR} ..."

for tool in docker_tool docker_push; do
	if [[ -f "${SCRIPT_DIR}/${tool}" ]]; then
		sudo cp "${SCRIPT_DIR}/${tool}" "${INSTALL_DIR}/${tool}"
		sudo chmod 755 "${INSTALL_DIR}/${tool}"
		echo "  Installed: ${INSTALL_DIR}/${tool}"
	else
		echo "  Warning: ${tool} not found in repo, skipping." >&2
	fi
done

# ─── Install completions ──────────────────────────────────────────────────────

echo "Installing completions to ${COMPLETION_DIR} ..."
mkdir -p "${COMPLETION_DIR}"

for comp in docker_push.bashrc docker_push.zshrc; do
	if [[ -f "${SCRIPT_DIR}/completions/${comp}" ]]; then
		cp "${SCRIPT_DIR}/completions/${comp}" "${COMPLETION_DIR}/${comp}"
		echo "  Installed: ${COMPLETION_DIR}/${comp}"
	fi
done

# ─── Hook into shell rc files ─────────────────────────────────────────────────

MARKER="# docker-tools completion"

install_completion() {
	local rc_file="$1"
	local completion_file="$2"

	[[ ! -f "${rc_file}" ]] && return 0

	if grep -qF "${MARKER}" "${rc_file}" 2>/dev/null; then
		echo "Completion already installed in ${rc_file}, skipping."
		return 0
	fi

	cat >> "${rc_file}" <<EOF

${MARKER}
if [[ -f "${completion_file}" ]]; then
  source "${completion_file}"
fi
EOF
	echo "Completion hook added to ${rc_file}"
}

install_completion "${HOME}/.bashrc" "${COMPLETION_DIR}/docker_push.bashrc"
install_completion "${HOME}/.zshrc"  "${COMPLETION_DIR}/docker_push.zshrc"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Done!"
echo "  Run: docker_tool --help"
echo "  Run: docker_push --help"
echo ""
echo "Reload your shell to activate completions:"
echo "  source ~/.zshrc   (zsh)"
echo "  source ~/.bashrc  (bash)"
