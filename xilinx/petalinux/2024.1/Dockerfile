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

# ------------------------------------------------------------------------------
# EBox https://github.com/alperyazar/EBox
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# PetaLinux 2024.1
# ------------------------------------------------------------------------------

# Stage 1: Base
FROM ubuntu:22.04 AS base

RUN mkdir -p /opt/EBox

COPY sources-build.list /opt/EBox/sources-build.list
COPY replace_sources.sh /opt/EBox/bin/replace_sources.sh
RUN chmod +x /opt/EBox/bin/replace_sources.sh && \
    /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-build.list

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

# Package list is taken from plnx-env-setup.sh, version 2025-03-26
RUN dpkg --add-architecture i386 && apt update && apt install -y \
    sudo \
    locales \
    gosu

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Package list is taken from plnx-env-setup.sh, version 2025-03-26
# + packages learned from installation and runtime errors, internet etc.
# ----------------------------------------------------------------------
# [ERROR] nslookup is required but not found in the path
# https://ayazar.dev/xilinx/ubuntu-2004-petalinux-20222-kurulumu.html
ARG COMMON_PACKAGES="\
  iproute2 \
  gawk \
  python3 \
  build-essential  \
  gcc \
  git \
  make \
  net-tools \
  libncurses5-dev \
  tftpd \
  zlib1g-dev \
  libssl-dev \
  flex \
  bison \
  libselinux1 \
  gnupg \
  wget \
  git-core \
  diffstat \
  chrpath \
  socat \
  xterm \
  autoconf \
  libtool \
  tar \
  unzip \
  texinfo \
  zlib1g-dev \
  gcc-multilib  \
  automake \
  zlib1g:i386  \
  screen  \
  pax  \
  gzip \
  cpio \
  python3-pip \
  python3-pexpect \
  xz-utils \
  debianutils \
  iputils-ping \
  python3-git \
  python3-jinja2 \
  libegl1-mesa \
  libsdl1.2-dev \
  pylint \
  rsync \
  bc \
  lsb-release \
  libtinfo5 \
  dnsutils"

RUN apt install -y $COMMON_PACKAGES && \
    echo $COMMON_PACKAGES > /opt/EBox/common_packages.txt

# Create necessary users for install and run-time
RUN groupadd -g 888 ebox && \
    adduser --uid 888 --gid 888 --shell /bin/bash ebox && \
    adduser ebox sudo && \
    echo 'ebox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo "ebox:ebox" | chpasswd && \
    chown -R ebox:ebox /home/ebox && \
    groupadd -g 887 eboxinstall && \
    adduser --uid 887 --gid 887 --shell /bin/bash eboxinstall && \
    echo "eboxinstall:eboxinstall" | chpasswd && \
    chown -R eboxinstall:eboxinstall /home/eboxinstall

# Save environment variables used during the build
RUN printenv > /opt/EBox/env-stage-1

# ------------------------------------------------------------------------------
################# Beginning of the installation image ##################
# ------------------------------------------------------------------------------

# Stage 2: Installer
FROM base AS installer

# Do the COPY and untar at the very top to maximize build cache
# Copy the Vivado installer tar file into the container
ARG INSTALLATION_FILE="petalinux-v2024.1-05202009-installer.run"
COPY $INSTALLATION_FILE /tmp/$INSTALLATION_FILE

# Check if we should skip the MD5 comparison
ARG MD5="548e3c81036021f74e67f33cc1ac2db4"
ARG SKIP_MD5="0"
RUN if [ "$SKIP_MD5" != "1" ]; then \
        echo "Calculating MD5..." && \
        file_md5=$(md5sum /tmp/$INSTALLATION_FILE | awk '{ print $1 }') && \
        if [ "$file_md5" != "$MD5" ]; then \
            echo "MD5 mismatch! Expected $MD5, got $file_md5. Build failed." && exit 1; \
        else \
            echo "MD5 matched: $file_md5"; \
        fi; \
    else \
        echo "Skipping MD5 comparison."; \
    fi

# Install
RUN chown eboxinstall:eboxinstall /tmp/$INSTALLATION_FILE && \
    chmod u+x /tmp/$INSTALLATION_FILE && \
    mkdir -p /opt/Xilinx/PetaLinux && \
    chown eboxinstall:eboxinstall /opt/Xilinx/PetaLinux

USER eboxinstall
WORKDIR /home/eboxinstall

# Automatically accept the license
RUN sed -i '/^echo "Use PgUp\/PgDn to navigate the license viewer, and press '\''q'\'' to close"/a answer="y"' /tmp/$INSTALLATION_FILE

RUN /tmp/$INSTALLATION_FILE \
    -d /opt/Xilinx/PetaLinux/2024.1

USER root
WORKDIR /root

# Save environment variables used during the build
RUN printenv > /opt/EBox/env-stage-2

# ------------------------------------------------------------------------------
################# Beginning of the final image ##################
# ------------------------------------------------------------------------------

# Stage 3: Final
FROM base AS final

COPY --from=installer /opt/Xilinx /opt/Xilinx
COPY --from=installer /opt/EBox /opt/EBox

# make bash default
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash && \
    echo "source /opt/Xilinx/PetaLinux/2024.1/settings.sh" >> /home/ebox/.bashrc

# In-file extra packages
ARG EXTRA_PACKAGES=""
RUN apt update && apt install -y $EXTRA_PACKAGES

# Allow user to append extra packages via --build-arg
ARG CMD_EXTRA_PACKAGES=""
RUN apt update && apt install -y $CMD_EXTRA_PACKAGES

COPY sources-final.list /opt/EBox/sources-final.list
RUN /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-final.list

ARG EBOX_OCI_TITLE="EBox - PetaLinux 2024.1"
ARG EBOX_OCI_DESCRIPTION="PetaLinux 2024.1 in a container, the EBox project"
ARG EBOX_OCI_VERSION="19700101-0"
ARG EBOX_OCI_REVISION="20251121-0"
ARG EBOX_OCI_LICENSE="MIT"
ARG EBOX_OCI_AUTHORS="The EBox Authors"

LABEL org.opencontainers.image.title="${EBOX_OCI_TITLE}" \
      org.opencontainers.image.description="${EBOX_OCI_DESCRIPTION}" \
      org.opencontainers.image.version="${EBOX_OCI_VERSION}" \
      org.opencontainers.image.revision="${EBOX_OCI_REVISION}" \
      org.opencontainers.image.license="${EBOX_OCI_LICENSE}" \
      org.opencontainers.image.authors="${EBOX_OCI_AUTHORS}" \
      org.opencontainers.image.ref.name="ebox-xilinx-petalinux-2024-1"

ENV EBOX_OCI_TITLE=${EBOX_OCI_TITLE}
ENV EBOX_OCI_DESCRIPTION=${EBOX_OCI_DESCRIPTION}
ENV EBOX_OCI_VERSION=${EBOX_OCI_VERSION}
ENV EBOX_OCI_REVISION=${EBOX_OCI_REVISION}
ENV EBOX_OCI_LICENSE=${EBOX_OCI_LICENSE}
ENV EBOX_OCI_AUTHORS=${EBOX_OCI_AUTHORS}

RUN printenv > /opt/EBox/env-stage-3 && cat /opt/EBox/env-stage-1 /opt/EBox/env-stage-2 /opt/EBox/env-stage-3 > /opt/EBox/env

USER root
WORKDIR /root
CMD [ "/bin/bash" ]
