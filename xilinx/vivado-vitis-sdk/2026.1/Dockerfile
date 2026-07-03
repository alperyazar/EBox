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

# Stage 1: Installer
FROM ubuntu:24.04 AS installer

# Do the COPY and untar at the very top to maximize build cache
# Copy the Vivado installer tar file into the container
ARG VIVADO_INSTALLATION_FILE="FPGAs_AdaptiveSoCs_Unified_SDI_2026.1_0616_1700.tar"
COPY $VIVADO_INSTALLATION_FILE /tmp/$VIVADO_INSTALLATION_FILE

# Check if we should skip the MD5 comparison
ARG MD5="b577835d4304f07e40292c51a4018482"
ARG SKIP_MD5="0"
RUN if [ "$SKIP_MD5" != "1" ]; then \
        echo "Calculating MD5..." && \
        file_md5=$(md5sum /tmp/$VIVADO_INSTALLATION_FILE | awk '{ print $1 }') && \
        if [ "$file_md5" != "$MD5" ]; then \
            echo "MD5 mismatch! Expected $MD5, got $file_md5. Build failed." && exit 1; \
        else \
            echo "MD5 matched: $file_md5"; \
        fi; \
    else \
        echo "Skipping MD5 comparison."; \
    fi

# Extract Vivado
RUN mkdir -p /tmp/installer && \
    tar -xvf /tmp/$VIVADO_INSTALLATION_FILE -C /tmp/installer --strip-components=1

RUN mkdir -p /opt/EBox

COPY sources-stage-1.list /opt/EBox/sources-stage-1.list
COPY replace_sources.sh /opt/EBox/bin/replace_sources.sh
RUN chmod +x /opt/EBox/bin/replace_sources.sh && \
    /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-stage-1.list

ENV DEBIAN_FRONTEND=noninteractive

# Most packages are from installLibs.sh from Vivado 2026.1 installation
# libtinfo5 and libncurses5 not avail in Ubuntu 24.04, try 6, replace libncurses5-dev with libncurses-dev
# libasound2 -> libasound2t64 ref: https://github.com/cypress-io/cypress-documentation/issues/5816#issue-2268545713
ARG COMMON_PACKAGES="\
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
    apt-get install -y $COMMON_PACKAGES && \
    rm -rf /var/lib/apt/lists/* && \
    echo $COMMON_PACKAGES > /opt/EBox/common_packages.txt

# Create symlink for libtinfo5. Ubuntu 24.04 doesn't have libtinfo5 but 6
# Ref: https://www.youtube.com/watch?v=mH7bfsOPVLk
RUN ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    TZ=Etc/UTC

ARG VIVADO_BATCH_INSTALL_CONFIG_FILE="install_config.txt"
COPY $VIVADO_BATCH_INSTALL_CONFIG_FILE /opt/EBox/install_config.txt

# Install Vivado
RUN /tmp/installer/xsetup \
    --agree XilinxEULA,3rdPartyEULA \
    --batch Install \
    --config /opt/EBox/install_config.txt

# Save environment variables used during the build
RUN printenv > /opt/EBox/env-stage-1

# ------------------------------------------------------------------------------
################# Beginning of the final image ##################
# ------------------------------------------------------------------------------

# Stage 2: Final
FROM ubuntu:24.04

COPY --from=installer /opt/Xilinx /opt/Xilinx
COPY --from=installer /opt/EBox /opt/EBox

COPY sources-stage-2.list /opt/EBox/sources-stage-2.list
RUN /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-stage-2.list

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y $(grep -vE '^\s*#|^\s*$' /opt/EBox/common_packages.txt | tr -d '\\') && apt-get install -y \
    x11-utils \
    sudo && \
    rm -rf /var/lib/apt/lists/*

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    TZ=Etc/UTC

# Create a non-root user eboox with root (sudo) privileges
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

RUN printenv > /opt/EBox/env-stage-2 && \
    cat /opt/EBox/env-stage-1 /opt/EBox/env-stage-2 > /opt/EBox/env

USER root
WORKDIR /root
CMD [ "/bin/bash" ]
ENTRYPOINT ["/opt/EBox/entrypoint.sh"]

