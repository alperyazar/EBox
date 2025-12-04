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

# Use first argument as source file, or default to /tmp/sources.list
SOURCE_FILE="${1:-/tmp/sources.list}"
TARGET_FILE="/etc/apt/sources.list"

# Check if file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "No sources.list provided at $SOURCE_FILE. Skipping replacement."
    exit 0
fi

# Read first line
FIRST_LINE=$(head -n 1 "$SOURCE_FILE")

# Check if it starts with #ignore
if echo "$FIRST_LINE" | grep -q "^#ignore"; then
    echo "Found '#ignore' marker. Keeping default sources.list."
else
    echo "Replacing default sources.list with $SOURCE_FILE."
    cp "$SOURCE_FILE" "$TARGET_FILE"
fi

exit 0
