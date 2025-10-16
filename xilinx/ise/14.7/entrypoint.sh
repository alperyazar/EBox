#!/bin/bash

# ------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2025 The EBox Authors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ------------------------------------------------------------------------------

set -e

# --------------------------------------------------------------------
# Entry point for Vivado/Vitis container (Docker & Podman compatible)
# --------------------------------------------------------------------

WS_PATH="${WORKSPACE_PATH:-/workspace}"

# If no arguments are passed, default to bash
if [ $# -eq 0 ]; then
    echo "No command provided. Defaulting to bash."
    set -- /bin/bash
fi

# If no UID/GID provided, assume interactive root or Podman
if [ -z "$USER_ID" ] || [ -z "$GROUP_ID" ]; then
    echo "No USER_ID or GROUP_ID provided. Running as $(whoami)..."
    cd "$HOME" || cd /root  # make sure we land somewhere safe

    if [ "$(id -u)" -eq 0 ]; then
        echo "WARNING: You are running as ROOT."
        echo "If using Docker and mounted volumes, consider running:"
        echo "  gosu ebox /bin/bash"
        echo "You can return to root with 'sudo -i' or 'exit'."
    fi

    if [[ "$EBOX_MODIFY_PATH" != "false" ]]; then
        # Avoid duplicate bashrc entries
        grep -qxF 'source /opt/Xilinx/14.7/ISE_DS/settings64.sh' "$HOME/.bashrc" || echo 'source /opt/Xilinx/14.7/ISE_DS/settings64.sh' >> "$HOME/.bashrc"
    else
        echo "Skipping PATH modification"
    fi

    exec "$@"
    exit 0
fi

USERNAME="u$USER_ID"
GROUPNAME="g$GROUP_ID"

# Create group if not exists
if ! getent group "$GROUP_ID" > /dev/null; then
    if ! groupadd -g "$GROUP_ID" "$GROUPNAME"; then
        echo "ERROR: Failed to create group with GID $GROUP_ID" >&2
        exit 1
    fi
fi

# Create user if not exists
if ! id -u "$USER_ID" > /dev/null 2>&1; then
    if ! useradd -u "$USER_ID" -g "$GROUP_ID" -m "$USERNAME" -s /bin/bash; then
        echo "ERROR: Failed to create user with UID $USER_ID" >&2
        exit 1
    fi
fi

HOME_DIR=$(getent passwd "$USER_ID" | cut -d: -f6)

# Avoid duplicate bashrc entries
grep -qxF 'source /opt/Xilinx/14.7/ISE_DS/settings64.sh' "$HOME_DIR/.bashrc" || echo 'source /opt/Xilinx/14.7/ISE_DS/settings64.sh' >> "$HOME_DIR/.bashrc"

# Setup workspace
if [ ! -d "$WS_PATH" ]; then
    mkdir -p "$WS_PATH"
    echo "WARNING: '$WS_PATH' was missing and has been created. Mount it using -v to persist work."
else
    echo "Workspace directory '$WS_PATH' already exists."
fi

if [[ "$EBOX_DO_CHOWN_WS" == "true" ]]; then
  echo "Running: chown -R $USER_ID:$GROUP_ID $WS_PATH"
  chown -R "$USER_ID:$GROUP_ID" "$WS_PATH"
fi

cd "$WS_PATH"

# Ensure HOME is set for the new user
export HOME="$HOME_DIR"

exec gosu "$USERNAME" "$@"
