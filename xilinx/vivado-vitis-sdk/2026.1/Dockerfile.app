# syntax=docker/dockerfile:1
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

# ------------------------------------------------------------------------------
# EBox https://github.com/alperyazar/EBox
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Vivado/Vitis 2026.1 -- APP image (light, build-often)
# ------------------------------------------------------------------------------
#
# The cheap half: runtime packages, the ebox user, entrypoint, labels, etc.,
# layered on top of the build-once base (Dockerfile.base). This rebuilds in
# seconds because it never touches the ~150 GB install -- that lives in the base
# image, pulled in by `FROM`, which is reused deterministically.
#
# No installer / named build context is needed here.
#
# Build (after the base exists), rebuild freely on entrypoint/package edits:
#
#   TAG=YYYYMMDD-<Count>
#   podman build -f Dockerfile.app \
#     --build-arg EBOX_OCI_VERSION="$TAG" \
#     -t vivado:2026.1-$TAG .
#
# Point BASE_IMAGE at whatever tag you built the base as. On docker the local
# base is just `vivado-base:2026.1` (drop the localhost/ prefix).

ARG BASE_IMAGE=pass-as-command-line-argument
FROM ${BASE_IMAGE}

# DEBIAN_FRONTEND/LANG/TZ are inherited from the base image; re-declared here for
# clarity since this stage runs apt.
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Everything below is runtime setup for the delivered image.
# ------------------------------------------------------------------------------

# Packages needed only at container runtime, not during the Vivado install.
ARG RUNTIME_PACKAGES="\
    x11-utils \
    sudo"
RUN apt-get update && \
    apt-get install -y $RUNTIME_PACKAGES && \
    rm -rf /var/lib/apt/lists/* && \
    echo $RUNTIME_PACKAGES > /opt/EBox/runtime_packages.txt

# Create a non-root user ebox with root (sudo) privileges
RUN groupadd -g 888 ebox && \
    adduser --uid 888 --gid 888 --shell /bin/bash ebox && \
    adduser ebox sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ebox_nopasswd_sudo && \
    echo "ebox:ebox" | chpasswd && \
    echo "source /opt/Xilinx/2026.1/Vivado/settings64.sh" >> "/home/ebox/.bashrc" && \
    echo "source /opt/EBox/ebox.sh /opt/EBox/bin" >> "/home/ebox/.bashrc" && \
    chown ebox:ebox /home/ebox/.bashrc

ARG EXTRA_PACKAGES="python3-dev python3-pip wget curl vim nano micro"
RUN apt-get update && \
    apt-get install -y $EXTRA_PACKAGES && \
    rm -rf /var/lib/apt/lists/*

# Allow user to append extra packages via --build-arg
ARG CMD_EXTRA_PACKAGES=""
RUN apt-get update && \
    apt-get install -y $CMD_EXTRA_PACKAGES && \
    rm -rf /var/lib/apt/lists/*

# Set the default command to launch when starting the container
COPY entrypoint.sh /opt/EBox/entrypoint.sh
RUN apt-get update && \
    apt-get install -y gosu && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /opt/EBox/entrypoint.sh

# https://adaptivesupport.amd.com/s/article/000034450?language=en_US
COPY ebox-vivado /opt/EBox/bin/vivado
COPY ebox.sh /opt/EBox/ebox.sh
RUN chmod +x /opt/EBox/bin/vivado && chmod +x /opt/EBox/ebox.sh

# Create symlink for libtinfo5. Ubuntu 24.04 doesn't have libtinfo5 but 6.
# Needed by Vivado at runtime (not by the installer).
# Ref: https://www.youtube.com/watch?v=mH7bfsOPVLk

# Edit: It looks like no need for Vivado 2026.1 on Ubuntu 24.04 but keep in mind
# leave as commented
#RUN ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# ------------------------------------------------------------------------------
# Finalize apt sources for the delivered image (what the end user's apt will
# use). This is the last apt-affecting step, so no packages are installed after
# it. Override sources-final.list the same way as sources-build.list.
# ------------------------------------------------------------------------------
COPY sources-final.list /opt/EBox/sources-final.list
RUN /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-final.list

ARG EBOX_OCI_TITLE="EBox - Vivado Vitis 2026.1"
ARG EBOX_OCI_DESCRIPTION="Vivado Vitis 2026.1 in a container, the EBox project"
ARG EBOX_OCI_VERSION="19700101-0"
ARG EBOX_OCI_REVISION="20260703-0"
ARG EBOX_OCI_LICENSE="MIT"
ARG EBOX_OCI_AUTHORS="The EBox Authors"

LABEL org.opencontainers.image.title="${EBOX_OCI_TITLE}" \
      org.opencontainers.image.description="${EBOX_OCI_DESCRIPTION}" \
      org.opencontainers.image.version="${EBOX_OCI_VERSION}" \
      org.opencontainers.image.revision="${EBOX_OCI_REVISION}" \
      org.opencontainers.image.licenses="${EBOX_OCI_LICENSE}" \
      org.opencontainers.image.authors="${EBOX_OCI_AUTHORS}" \
      org.opencontainers.image.ref.name="ebox-xilinx-vivado-2026-1"

ENV EBOX_OCI_TITLE=${EBOX_OCI_TITLE}
ENV EBOX_OCI_DESCRIPTION=${EBOX_OCI_DESCRIPTION}
ENV EBOX_OCI_VERSION=${EBOX_OCI_VERSION}
ENV EBOX_OCI_REVISION=${EBOX_OCI_REVISION}
ENV EBOX_OCI_LICENSE=${EBOX_OCI_LICENSE}
ENV EBOX_OCI_AUTHORS=${EBOX_OCI_AUTHORS}

# Save environment variables used during the build
RUN printenv > /opt/EBox/env-app

USER root
WORKDIR /root
CMD [ "/bin/bash" ]
ENTRYPOINT ["/opt/EBox/entrypoint.sh"]
