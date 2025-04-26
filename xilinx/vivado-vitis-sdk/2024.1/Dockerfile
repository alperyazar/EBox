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
# Vivado/Vitis 2024.1
# ------------------------------------------------------------------------------

# Stage 1: Installer
FROM ubuntu:22.04 AS installer

# Do the COPY and untar at the very top to maximize build cache
# Copy the Vivado installer tar file into the container
ARG VIVADO_INSTALLATION_FILE="FPGAs_AdaptiveSoCs_Unified_2024.1_0522_2023.tar.gz"
COPY $VIVADO_INSTALLATION_FILE /tmp/$VIVADO_INSTALLATION_FILE

# Check if we should skip the MD5 comparison
ARG MD5="372c0b184e32001137424e395823de3c"
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
    tar -xvzf /tmp/$VIVADO_INSTALLATION_FILE -C /tmp/installer --strip-components=1

# Get installation config
RUN mkdir -p /opt/EBox
ARG VIVADO_BATCH_INSTALL_CONFIG_FILE="install_config.txt"
COPY $VIVADO_BATCH_INSTALL_CONFIG_FILE /opt/EBox/install_config.txt
COPY sources-stage-1.list /opt/EBox/sources-stage-1.list
COPY replace_sources.sh /opt/EBox/bin/replace_sources.sh
RUN chmod +x /opt/EBox/bin/replace_sources.sh && \
    /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-stage-1.list

# Install required packages to suppress warnings and possible problems during
# install
ENV DEBIAN_FRONTEND=noninteractive
# Error: xz is required for installation of this SDK, please install it first
# The SDK needs a python installed /opt/Xilinx/Vivado/2024.1/bin/rdiArgs.sh:
# warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
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
    libtinfo5 \
    xvfb \
    git \
    libncursesw5 \
    libc6-dev-i386 \
    openssl  \
    ca-certificates \
    libnss3-dev \
    libgdk-pixbuf2.0-dev \
    libgtk-3-dev \
    libxss-dev"
RUN apt update && apt install -y $COMMON_PACKAGES && \
    echo $COMMON_PACKAGES > /opt/EBox/common_packages.txt

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Vivado
# https://adaptivesupport.amd.com/s/question/0D52E00007Dnt9PSAR/when-i-install-vivado-20221-i-get-an-error-that-says-warning-xilinx-software-was-installed-successfully-but-an-unexpected-status-was-returned-from-the-following-post-installation-tasks-the-syntax-of-the-command-is-incorrectplease-help
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
FROM ubuntu:22.04

COPY --from=installer /opt/Xilinx /opt/Xilinx
COPY --from=installer /opt/EBox /opt/EBox

COPY sources-stage-2.list /opt/EBox/sources-stage-2.list
RUN /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-stage-2.list

ENV DEBIAN_FRONTEND=noninteractive

# According to Xilinx (AMD) 000036522 article the following packages should
# be installed manually
#
# Package Name : Ubuntu Package Name
# compat-openssl10 : openssl (?) + ca-certificates (recommended)
# libnss3-dev : libnss3-dev
# libgdk-pixbuf2.0-dev : libgdk-pixbuf2.0-dev
# libgtk-3-dev : libgtk-3-dev
# libxss-dev : libxss-dev
RUN apt update && apt install -y $(grep -vE '^\s*#|^\s*$' /opt/EBox/common_packages.txt | tr -d '\\') && apt install -y \
    libyaml-0-2 \
    libsecret-1-0 \
    rlwrap \
    x11-utils \
    libasound2 \
    sudo

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# https://adaptivesupport.amd.com/s/article/000036522?language=en_US
# We did (all) install manually at previous steps. But just to make sure
# run the Xilinx's script again.
RUN bash /opt/Xilinx/Vitis/2024.1/scripts/installLibs.sh

# https://adaptivesupport.amd.com/s/question/0D54U00006lApRISA0/immediate-segfault-when-running-xsdb
RUN mv /opt/Xilinx/Vitis/2024.1/bin/unwrapped/lnx64.o/rlwrap /opt/Xilinx/Vitis/2024.1/bin/unwrapped/lnx64.o/rlwrap.bak && \
    ln -s `which rlwrap` /opt/Xilinx/Vitis/2024.1/bin/unwrapped/lnx64.o/rlwrap

# Create a non-root user eboox with root (sudo) privileges
RUN groupadd -g 888 ebox && \
    adduser --uid 888 --gid 888 --shell /bin/bash ebox && \
    adduser ebox sudo && \
    echo 'ebox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo "ebox:ebox" | chpasswd && \
    echo "source /opt/Xilinx/Vivado/2024.1/settings64.sh" >> "/home/ebox/.bashrc" && \
    echo "source /opt/EBox/ebox.sh /opt/EBox/bin" >> "/home/ebox/.bashrc" && \
    chown ebox:ebox /home/ebox/.bashrc

ARG EXTRA_PACKAGES="python3-dev python3-pip"
RUN apt update && apt install -y $EXTRA_PACKAGES

# Allow user to append extra packages via --build-arg
ARG CMD_EXTRA_PACKAGES=""
RUN apt update && apt install -y $CMD_EXTRA_PACKAGES

# Set the default command to launch when starting the container
RUN apt update && apt install -y gosu
COPY entrypoint.sh /opt/EBox/entrypoint.sh
RUN chmod +x /opt/EBox/entrypoint.sh

# https://adaptivesupport.amd.com/s/article/000034450?language=en_US
COPY ebox-vivado /opt/EBox/bin/vivado
COPY ebox.sh /opt/EBox/ebox.sh
RUN chmod +x /opt/EBox/bin/vivado && chmod +x /opt/EBox/ebox.sh

COPY sources-final.list /opt/EBox/sources-final.list
RUN /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-final.list

ARG EBOX_OCI_TITLE="EBox - Vivado Vitis 2024.1"
ARG EBOX_OCI_DESCRIPTION="Vivado Vitis 2024.1 in a container, the EBox project"
ARG EBOX_OCI_VERSION="19700101-0"
ARG EBOX_OCI_REVISION="20250426-0"
ARG EBOX_OCI_LICENSE="MIT"
ARG EBOX_OCI_AUTHORS="The EBox Authors"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="${OCI_DESCRIPTION}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.license="${OCI_LICENSE}" \
      org.opencontainers.image.authors="${OCI_AUTHORS}"

ENV EBOX_OCI_TITLE=${EBOX_OCI_TITLE}
ENV EBOX_OCI_DESCRIPTION=${EBOX_OCI_DESCRIPTION}
ENV EBOX_OCI_VERSION=${EBOX_OCI_VERSION}
ENV EBOX_OCI_REVISION=${EBOX_OCI_REVISION}
ENV EBOX_OCI_LICENSE=${EBOX_OCI_LICENSE}
ENV EBOX_OCI_AUTHORS=${EBOX_OCI_AUTHORS}

RUN printenv > /opt/EBox/env-stage-2 && cat /opt/EBox/env-stage-1 /opt/EBox/env-stage-2 > /opt/EBox/env

USER root
WORKDIR /root
CMD [ "/bin/bash" ]
ENTRYPOINT ["/opt/EBox/entrypoint.sh"]

