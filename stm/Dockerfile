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
# STM32CubeIDE
# ------------------------------------------------------------------------------

# Stage 1: Single Stage
# The installer script from STM also installs required packages from repositories.
# Therefore use single stage build with caution not to blow up disk usage.
FROM ubuntu:22.04

# ---- Installer ----
ARG INSTALLATION_FILE="st-stm32cubeide_1.5.1_9029_20201210_1234_amd64.deb_bundle.sh.zip"
ARG INSTALLER_CHECKSUM="b4fec91c0cff2c89f7d360b4c92f02f4b1dae824d2711fd6990a4de365bb1f80"
ARG SKIP_CHECKSUM_CONTROL="0"

# ---- Build-time environment ----
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /opt/EBox
COPY sources-stage-1.list /opt/EBox/sources-stage-1.list
COPY replace_sources.sh /opt/EBox/bin/replace_sources.sh
RUN chmod +x /opt/EBox/bin/replace_sources.sh && \
    /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-stage-1.list

# ---- Prereqs (cached unless base image changes) ----
RUN apt-get update \
 && apt-get install -y --no-install-recommends unzip \
 && rm -rf /var/lib/apt/lists/*

# Dependencies of STM32CubeIDE
# libswt-gtk-4-java: needed for GUI bring-up

# Bind-mount the installer so it never enters any layer.
# Everything (verify, unzip, install, cleanup) happens in one RUN.
RUN --mount=type=bind,source=${INSTALLATION_FILE},target=/tmp/installer.zip,readonly \
    set -eu; \
    if [ "$SKIP_CHECKSUM_CONTROL" != "1" ]; then \
      echo "Calculating checksum..."; \
      file_checksum=$(sha256sum /tmp/installer.zip | awk '{ print $1 }'); \
      if [ "$file_checksum" != "$INSTALLER_CHECKSUM" ]; then \
        echo "Checksum mismatch! Expected $INSTALLER_CHECKSUM, got $file_checksum."; \
        exit 1; \
      fi; \
      echo "Checksum matched: $file_checksum"; \
    else \
      echo "Skipping checksum comparison."; \
    fi; \
    mkdir -p /tmp/install; \
    unzip -q /tmp/installer.zip -d /tmp/install; \
    apt-get update; \
    yes Y | LICENSE_ALREADY_ACCEPTED=1 bash /tmp/install/*.sh; \
    apt-get install -y libswt-gtk-4-java; \
    rm -rf /tmp/install /var/lib/apt/lists/* /var/cache/apt/archives/*.deb

# EBox related installes
RUN apt-get update \
 && apt-get install -y --no-install-recommends gosu sudo\
 && rm -rf /var/lib/apt/lists/*

# Create a non-root user eboox with root (sudo) privileges
RUN groupadd -g 888 ebox && \
    adduser --uid 888 --gid 888 --shell /bin/bash ebox && \
    adduser ebox sudo && \
    echo 'ebox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo "ebox:ebox" | chpasswd

# Set the default command to launch when starting the container
COPY entrypoint.sh /opt/EBox/entrypoint.sh
RUN chmod +x /opt/EBox/entrypoint.sh


# make bash default
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

ARG EBOX_OCI_TITLE="EBox - STM32CubeIDE 1.5.1"
ARG EBOX_OCI_DESCRIPTION="STM32CubeIDE 1.5.1 in a container, the EBox project"
ARG EBOX_OCI_VERSION="19700101-0"
ARG EBOX_OCI_REVISION="20260520-0-BETA"
ARG EBOX_OCI_LICENSE="MIT"
ARG EBOX_OCI_AUTHORS="The EBox Authors"

LABEL org.opencontainers.image.title="${EBOX_OCI_TITLE}" \
      org.opencontainers.image.description="${EBOX_OCI_DESCRIPTION}" \
      org.opencontainers.image.version="${EBOX_OCI_VERSION}" \
      org.opencontainers.image.revision="${EBOX_OCI_REVISION}" \
      org.opencontainers.image.licenses="${EBOX_OCI_LICENSE}" \
      org.opencontainers.image.authors="${EBOX_OCI_AUTHORS}" \
      org.opencontainers.image.ref.name="ebox-stm32cubeide-1-5-1"

ENV EBOX_OCI_TITLE=${EBOX_OCI_TITLE} \
    EBOX_OCI_DESCRIPTION=${EBOX_OCI_DESCRIPTION} \
    EBOX_OCI_VERSION=${EBOX_OCI_VERSION} \
    EBOX_OCI_REVISION=${EBOX_OCI_REVISION} \
    EBOX_OCI_LICENSE=${EBOX_OCI_LICENSE} \
    EBOX_OCI_AUTHORS=${EBOX_OCI_AUTHORS}

USER root
WORKDIR /root
CMD [ "/bin/bash" ]
ENTRYPOINT ["/opt/EBox/entrypoint.sh"]
