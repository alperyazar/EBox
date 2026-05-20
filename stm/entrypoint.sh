#!/bin/bash

# ------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2026 The EBox Authors
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

# --------------------------------------------------------------------
# Entry point for STM32CubeIDE container (Docker & Podman compatible)
#
# Behavior:
#   - If USER_ID / GROUP_ID are unset: run the command as the current
#     user (typical Podman rootless case, where UIDs already map
#     correctly via userns).
#   - If USER_ID / GROUP_ID are set: create a matching user+group on
#     the fly, grant passwordless sudo, and drop privileges via gosu.
#
# Environment variables:
#   USER_ID            Numeric UID for the runtime user
#   GROUP_ID           Numeric GID for the runtime user
#   WORKSPACE_PATH     Workspace mount point (default: /workspace)
#   EBOX_DO_CHOWN_WS   If "true", chown -R the workspace to USER_ID
#   EBOX_EXTRA_GROUPS  Optional comma-separated supplementary groups
#                      (e.g. "dialout,plugdev") for USB / serial access
# --------------------------------------------------------------------
set -euo pipefail

WS_PATH="${WORKSPACE_PATH:-/workspace}"
EBOX_DO_CHOWN_WS="${EBOX_DO_CHOWN_WS:-false}"
EBOX_EXTRA_GROUPS="${EBOX_EXTRA_GROUPS:-}"

log()  { printf '[entrypoint] %s\n' "$*"; }
warn() { printf '[entrypoint] WARNING: %s\n' "$*" >&2; }
err()  { printf '[entrypoint] ERROR: %s\n' "$*" >&2; }

# Default command -> interactive bash
if [ "$#" -eq 0 ]; then
    log "No command provided. Defaulting to /bin/bash."
    set -- /bin/bash
fi

# --------------------------------------------------------------------
# Case 1: no USER_ID / GROUP_ID — run as whoever we already are
# --------------------------------------------------------------------
if [ -z "${USER_ID:-}" ] || [ -z "${GROUP_ID:-}" ]; then
    log "No USER_ID/GROUP_ID provided. Running as $(id -un) (uid=$(id -u))."

    # Land somewhere sensible
    if [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
        cd "$HOME"
    else
        cd /root 2>/dev/null || cd /
    fi

    if [ "$(id -u)" -eq 0 ]; then
        warn "You are running as ROOT."
        warn "For Docker with mounted volumes, prefer passing USER_ID and GROUP_ID,"
        warn "or drop to an unprivileged user with: gosu <user> /bin/bash"
    fi

    exec "$@"
fi

# --------------------------------------------------------------------
# Case 2: USER_ID / GROUP_ID provided — create user + group, grant sudo
# --------------------------------------------------------------------

# Sanity-check numeric inputs
if ! [[ "$USER_ID"  =~ ^[0-9]+$ ]]; then err "USER_ID must be numeric, got: $USER_ID"; exit 1; fi
if ! [[ "$GROUP_ID" =~ ^[0-9]+$ ]]; then err "GROUP_ID must be numeric, got: $GROUP_ID"; exit 1; fi

USERNAME="u${USER_ID}"
GROUPNAME="g${GROUP_ID}"

# --- Group ----------------------------------------------------------
if getent group "$GROUP_ID" >/dev/null; then
    GROUPNAME="$(getent group "$GROUP_ID" | cut -d: -f1)"
    log "Group with GID $GROUP_ID already exists as '$GROUPNAME'."
else
    if ! groupadd -g "$GROUP_ID" "$GROUPNAME"; then
        err "Failed to create group '$GROUPNAME' (GID $GROUP_ID)."
        exit 1
    fi
    log "Created group '$GROUPNAME' (GID $GROUP_ID)."
fi

# --- User -----------------------------------------------------------
if id -u "$USER_ID" >/dev/null 2>&1; then
    USERNAME="$(getent passwd "$USER_ID" | cut -d: -f1)"
    log "User with UID $USER_ID already exists as '$USERNAME'."
else
    if ! useradd -u "$USER_ID" -g "$GROUP_ID" -m -s /bin/bash "$USERNAME"; then
        err "Failed to create user '$USERNAME' (UID $USER_ID)."
        exit 1
    fi
    log "Created user '$USERNAME' (UID $USER_ID, GID $GROUP_ID)."
fi

HOME_DIR="$(getent passwd "$USER_ID" | cut -d: -f6)"
if [ -z "$HOME_DIR" ] || [ ! -d "$HOME_DIR" ]; then
    err "Home directory for UID $USER_ID is missing or invalid."
    exit 1
fi

# --- Supplementary groups (e.g. dialout for ST-Link / USB serial) ---
if [ -n "$EBOX_EXTRA_GROUPS" ]; then
    # Only add groups that actually exist in the image
    valid_groups=()
    IFS=',' read -ra requested <<< "$EBOX_EXTRA_GROUPS"
    for g in "${requested[@]}"; do
        g="${g// /}"  # trim spaces
        [ -z "$g" ] && continue
        if getent group "$g" >/dev/null; then
            valid_groups+=("$g")
        else
            warn "Supplementary group '$g' does not exist; skipping."
        fi
    done
    if [ "${#valid_groups[@]}" -gt 0 ]; then
        joined="$(IFS=','; echo "${valid_groups[*]}")"
        usermod -aG "$joined" "$USERNAME"
        log "Added '$USERNAME' to supplementary groups: $joined"
    fi
fi

# --- Passwordless sudo for the dynamic user -------------------------
# We write a dedicated drop-in under /etc/sudoers.d so we never touch
# the main sudoers file. The file is validated with visudo before
# being put in place to avoid locking out sudo on a typo.
if command -v sudo >/dev/null 2>&1; then
    if [ ! -d /etc/sudoers.d ]; then
        mkdir -p /etc/sudoers.d
        chmod 0750 /etc/sudoers.d
    fi
    sudoers_file="/etc/sudoers.d/90-${USERNAME}"
    tmp_sudoers="$(mktemp)"
    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USERNAME" > "$tmp_sudoers"
    if visudo -cf "$tmp_sudoers" >/dev/null; then
        install -m 0440 -o root -g root "$tmp_sudoers" "$sudoers_file"
        log "Granted passwordless sudo to '$USERNAME' via $sudoers_file."
    else
        warn "Generated sudoers snippet failed visudo check; sudo NOT granted."
    fi
    rm -f "$tmp_sudoers"
else
    warn "'sudo' is not installed in this image; cannot grant sudo to '$USERNAME'."
fi

# --- Workspace ------------------------------------------------------
if [ ! -d "$WS_PATH" ]; then
    mkdir -p "$WS_PATH"
    warn "'$WS_PATH' was missing and has been created. Mount it with -v to persist work."
else
    log "Workspace directory '$WS_PATH' already exists."
fi

if [ "$EBOX_DO_CHOWN_WS" = "true" ]; then
    log "Recursively chowning '$WS_PATH' to ${USER_ID}:${GROUP_ID} (this may take a while)..."
    chown -R "${USER_ID}:${GROUP_ID}" "$WS_PATH"
else
    # Make sure at least the top level is writable by the user, so the
    # IDE can create its .metadata/ etc. on first launch without forcing
    # a full recursive chown of large mounted source trees.
    if [ "$(stat -c '%u' "$WS_PATH")" != "$USER_ID" ]; then
        chown "${USER_ID}:${GROUP_ID}" "$WS_PATH" 2>/dev/null \
            || warn "Could not chown top-level of '$WS_PATH'."
    fi
fi

cd "$WS_PATH"

# Ensure HOME points at the new user's home for the exec'd process
export HOME="$HOME_DIR"
export USER="$USERNAME"
export LOGNAME="$USERNAME"

# --- Drop privileges ------------------------------------------------
if command -v gosu >/dev/null 2>&1; then
    exec gosu "$USERNAME" "$@"
elif command -v su-exec >/dev/null 2>&1; then
    exec su-exec "$USERNAME" "$@"
elif command -v runuser >/dev/null 2>&1; then
    exec runuser -u "$USERNAME" -- "$@"
else
    err "Neither gosu, su-exec, nor runuser is available; cannot drop privileges."
    exit 1
fi
