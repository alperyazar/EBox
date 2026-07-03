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
# Vivado/Vitis 2026.1
# ------------------------------------------------------------------------------
#
# Single-stage build.
#
# The ~100 GB Vivado installer tar is NOT part of the main build context and is
# never COPYied into a layer. Instead it is supplied as a *named build context*
# and bind-mounted read-only for the single RUN that extracts + installs it, so:
#   * no 100 GB COPY layer is created,
#   * the extracted installer tree never persists in a layer (removed in the
#     same RUN), and
#   * the main build context stays tiny, so it isn't re-transferred/re-tarred
#     on every build.
#
# Build with (note the named context pointing at the dir that holds the tar):
#
#   docker build \
#     --build-context vivado_installer=./installer \
#     -t vivado:2026.1 .
#
# (Both `docker buildx` and `podman`/`buildah` >= 4.x support --build-context.)

FROM ubuntu:24.04

# ------------------------------------------------------------------------------
# apt sources used *during the build*.
# Override sources-build.list to point apt at a local mirror if needed; a file
# whose first line starts with "#ignore" is treated as a no-op (keep defaults).
# ------------------------------------------------------------------------------
RUN mkdir -p /opt/EBox
COPY sources-build.list /opt/EBox/sources-build.list
COPY replace_sources.sh /opt/EBox/bin/replace_sources.sh
RUN chmod +x /opt/EBox/bin/replace_sources.sh && \
    /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-build.list

ENV DEBIAN_FRONTEND=noninteractive

# Packages required to install Vivado/Vitis (mostly from installLibs.sh of the
# Vivado 2026.1 installation). These are Vivado's own dependencies, so they are
# also needed at runtime and remain in the final image. Keep this list to what
# the installer/Vivado actually needs -- purely runtime conveniences belong in
# RUNTIME_PACKAGES below so they don't invalidate the expensive install layer.
# libtinfo5 and libncurses5 not avail in Ubuntu 24.04, try 6, replace libncurses5-dev with libncurses-dev
# libasound2 -> libasound2t64 ref: https://github.com/cypress-io/cypress-documentation/issues/5816#issue-2268545713
ARG INSTALL_PACKAGES="\
    python3 \
    locales \
    lsb-release \
    xz-utils \
    libc6-dev-i386 net-tools \
    graphviz \
    make \
    unzip \
    zip \
    g++ \
    libtinfo6 \
    xvfb \
    git \
    libtool \
    libyaml-dev \
    libncurses6 \
    libncurses-dev \
    libc6-dev-i386 \
    libnss3-dev \
    libgdk-pixbuf2.0-dev \
    libgtk-3-dev \
    libxss-dev \
    libasound2t64 \
    openssl  \
    fdisk \
    libsecret-1-dev"

RUN apt-get update && \
    apt-get install -y $INSTALL_PACKAGES && \
    rm -rf /var/lib/apt/lists/* && \
    echo $INSTALL_PACKAGES > /opt/EBox/install_packages.txt

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    TZ=Etc/UTC

ARG VIVADO_BATCH_INSTALL_CONFIG_FILE="install_config.txt"
COPY $VIVADO_BATCH_INSTALL_CONFIG_FILE /opt/EBox/install_config.txt

# ------------------------------------------------------------------------------
# Install Vivado/Vitis.
#
# The installer tar is bind-mounted read-only from the `vivado_installer` named
# build context (mounted as a directory so no build args appear in the --mount
# line, which keeps it portable across docker/buildkit and buildah). MD5 is
# verified on the mounted file, then it is extracted, installed, and the
# extracted tree is removed -- all in one layer, so nothing huge is persisted.
# ------------------------------------------------------------------------------
ARG VIVADO_INSTALLATION_FILE="FPGAs_AdaptiveSoCs_Unified_SDI_2026.1_0616_1700.tar"
ARG MD5="b577835d4304f07e40292c51a4018482"
ARG SKIP_MD5="0"
RUN --mount=type=bind,from=vivado_installer,target=/mnt/installer_ctx \
    installer_tar="/mnt/installer_ctx/$VIVADO_INSTALLATION_FILE" && \
    if [ "$SKIP_MD5" != "1" ]; then \
        echo "Calculating MD5..." && \
        file_md5=$(md5sum "$installer_tar" | awk '{ print $1 }') && \
        if [ "$file_md5" != "$MD5" ]; then \
            echo "MD5 mismatch! Expected $MD5, got $file_md5. Build failed." && exit 1; \
        else \
            echo "MD5 matched: $file_md5"; \
        fi; \
    else \
        echo "Skipping MD5 comparison."; \
    fi && \
    mkdir -p /tmp/installer && \
    tar --no-same-owner -xf "$installer_tar" -C /tmp/installer --strip-components=1 && \
    /tmp/installer/xsetup \
        --agree XilinxEULA,3rdPartyEULA \
        --batch Install \
        --config /opt/EBox/install_config.txt && \
    rm -rf /tmp/installer

# ------------------------------------------------------------------------------
# Everything below is runtime setup for the delivered image. It is placed after
# the (expensive, rarely-changing) Vivado install so editing it doesn't
# invalidate the install layer's cache.
# ------------------------------------------------------------------------------

# Create symlink for libtinfo5. Ubuntu 24.04 doesn't have libtinfo5 but 6.
# Needed by Vivado at runtime (not by the installer).
# Ref: https://www.youtube.com/watch?v=mH7bfsOPVLk
RUN ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# Packages needed only at container runtime, not during the Vivado install.
# Kept separate from INSTALL_PACKAGES and installed *after* the install step so
# that adding a runtime package does not invalidate the expensive install layer.
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
    echo "source /opt/Xilinx/Vivado/2026.1/settings64.sh" >> "/home/ebox/.bashrc" && \
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
RUN printenv > /opt/EBox/env

USER root
WORKDIR /root
CMD [ "/bin/bash" ]
ENTRYPOINT ["/opt/EBox/entrypoint.sh"]
