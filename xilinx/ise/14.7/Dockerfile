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
# ISE 14.7
# ------------------------------------------------------------------------------

# Stage 1: Installer
FROM ubuntu:22.04 AS installer

# Do the COPY and untar at the very top to maximize build cache
# Copy the Vivado installer tar file into the container
ARG VIVADO_INSTALLATION_FILE="Xilinx_ISE_DS_Lin_14.7_1015_1.tar"
COPY $VIVADO_INSTALLATION_FILE /tmp/$VIVADO_INSTALLATION_FILE

# Check if we should skip the MD5 comparison
ARG MD5="e8065b2ffb411bb74ae32efa475f9817"
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

# Install required packages to suppress warnings and possible problems during
# install
ENV DEBIAN_FRONTEND=noninteractive

ARG COMMON_PACKAGES="\
    locales \
    libncurses5 \
    xvfb \
    libglib2.0-0 \
    libxi6 \
    libxrender1 \
    libxrandr2 \
    libfontconfig1"

RUN apt update && apt install -y $COMMON_PACKAGES && \
    echo $COMMON_PACKAGES > /opt/EBox/common_packages.txt

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ARG VIVADO_BATCH_INSTALL_CONFIG_FILE="install_config.txt"
COPY $VIVADO_BATCH_INSTALL_CONFIG_FILE /opt/EBox/install_config.txt

# Install ISE
ENV TERM=xterm-256color
RUN yes | /tmp/installer/bin/lin64/batchxsetup --batch /opt/EBox/install_config.txt

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

# libgtk2.0-0: for SDK
# libcanberra-gtk-module: for SDK
# libxtst6: for SDK
# lib32z1: for SDK See https://adaptivesupport.amd.com/s/article/63561?language=en_US
# libncurses6: for SDK See https://adaptivesupport.amd.com/s/article/63561?language=en_US
# lib32stdc++6: for SDK See https://adaptivesupport.amd.com/s/article/63561?language=en_US

RUN apt update && apt install -y $(grep -vE '^\s*#|^\s*$' /opt/EBox/common_packages.txt | tr -d '\\') && apt install -y \
    sudo \
    libgtk2.0-0 \
    libcanberra-gtk-module \
    libxtst6 \
    lib32z1 \
    libncurses6 \
    lib32stdc++6

# https://stackoverflow.com/a/28406007/1766391
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user eboox with root (sudo) privileges
RUN groupadd -g 888 ebox && \
    adduser --uid 888 --gid 888 --shell /bin/bash ebox && \
    adduser ebox sudo && \
    echo 'ebox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo "ebox:ebox" | chpasswd && \
    echo "source /opt/Xilinx/14.7/ISE_DS/settings64.sh" >> "/home/ebox/.bashrc" && \
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

COPY sources-final.list /opt/EBox/sources-final.list
RUN /opt/EBox/bin/replace_sources.sh /opt/EBox/sources-final.list

ARG EBOX_OCI_TITLE="EBox - ISE 14.7"
ARG EBOX_OCI_DESCRIPTION="ISE 14.7 in a container, the EBox project"
ARG EBOX_OCI_VERSION="19700101-0"
ARG EBOX_OCI_REVISION="20250723-0"
ARG EBOX_OCI_LICENSE="MIT"
ARG EBOX_OCI_AUTHORS="The EBox Authors"

LABEL org.opencontainers.image.title="${EBOX_OCI_TITLE}" \
      org.opencontainers.image.description="${EBOX_OCI_DESCRIPTION}" \
      org.opencontainers.image.version="${EBOX_OCI_VERSION}" \
      org.opencontainers.image.revision="${EBOX_OCI_REVISION}" \
      org.opencontainers.image.license="${EBOX_OCI_LICENSE}" \
      org.opencontainers.image.authors="${EBOX_OCI_AUTHORS}" \
      org.opencontainers.image.ref.name="ebox-xilinx-ise-14-7"

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
