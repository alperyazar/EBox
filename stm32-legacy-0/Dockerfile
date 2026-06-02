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
# STM32-legacy-0
# ------------------------------------------------------------------------------

# =============================================================================
# STM32 development environment — frozen at the existing host's exact versions
#
#   Detected on host (Ubuntu 20.04):
#     Eclipse Platform:     2019-06 R, build 20190614-1200 (4.12.0)
#     Eclipse CDT:          9.8.0.2019060717
#     GNU MCU Eclipse:      4.1.1-201707111115 (managed-build feature 2.5.2)
#                           — installed features: ARM Cross Compiler,
#                             J-Link Debugging, OpenOCD Debugging
#                           — STM32 templates NOT installed (legacy projects)
#     Toolchain:            gcc-arm-none-eabi-6-2017-q2-update (GCC 6.3.1)
#
#   The plug-ins are from July 2017 even though Eclipse is from June 2019;
#   plug-in version is locked to match what's running in production.
#
# =============================================================================

FROM ubuntu:20.04

# ---- Pinned versions (override with --build-arg only if you know why) -------

# SHA-256 integrity checking of the three downloaded files. Each download is
# verified against its ARG *_SHA256 below. Set SKIP_CHECKSUM_CHECK=1 to skip
# all three checks (e.g. when intentionally pulling a different version).
ARG SKIP_CHECKSUM_CHECK=0

ARG ECLIPSE_PKG=eclipse-cpp-2019-06-R-linux-gtk-x86_64.tar.gz
ARG ECLIPSE_URL=https://archive.eclipse.org/technology/epp/downloads/release/2019-06/R/${ECLIPSE_PKG}
# Uncomment if you run "python3 -m http.server 8123" on your host to speed up things
#ARG ECLIPSE_URL=http://172.17.0.1:8123/${ECLIPSE_PKG}
ARG ECLIPSE_SHA256=2b96d223e5a34434cca87748c7ce77821fc78ef591b8695f77fa517046a3ea99

# Plug-ins archive — July 2017 release. GitHub Releases is the only durable host
# (Bintray is gone, Netlify .com is gone, SourceForge mirror is dead).
ARG GNUMCU_VERSION=4.1.1-201707111115
ARG GNUMCU_ZIP=ilg.gnumcueclipse.repository-${GNUMCU_VERSION}.zip
ARG GNUMCU_URL=https://github.com/eclipse-embed-cdt/eclipse-plugins/releases/download/v${GNUMCU_VERSION}/${GNUMCU_ZIP}
ARG GNUMCU_SHA256=df4fe65687e9a264a3ac180a6171e1b1cb22f9dc78d7990760877e4ac79cb10f

# CDT 9.8 archive — only needed if a feature is missing from the EPP package.
# The 2019-06 C/C++ EPP already includes cdt.launch.remote and the GDB Hardware
# Debugging feature, so this is a defensive fallback you can drop if you prove
# it isn't needed.
#ARG CDT_ZIP=cdt-9.8.0.zip
#ARG CDT_URL=https://archive.eclipse.org/tools/cdt/releases/9.8/${CDT_ZIP}

# Arm toolchain — same vintage as the plug-ins (both from mid-2017)
ARG GCC_ARM_TARBALL=gcc-arm-none-eabi-6-2017-q2-update-linux.tar.bz2
ARG GCC_ARM_URL=https://firmware.ardupilot.org/Tools/STM32-tools/${GCC_ARM_TARBALL}
ARG GCC_ARM_SHA256=e68e4b2fe348ecb567c27985355dff75b65319a0f6595d44a18a8c5e05887cc3

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Etc/UTC

# -----------------------------------------------------------------------------
# 1) System packages
#    - i386 multiarch: the 6-2017-q2 toolchain ships 32-bit ELFs
#    - GTK/X11/font packages so Eclipse renders correctly over X11 forwarding
#    - make + a host gcc for any small native utilities Eclipse may invoke
#    - openjdk-8: matches the plug-ins' documented minimum (JavaSE-1.8-111).
#      Eclipse 2019-06 works fine on 8 or 11; we pick 8 to match the era and
#      sidestep any deprecation warnings the 2017-era plug-ins might emit on 11.
# -----------------------------------------------------------------------------
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget unzip bzip2 xz-utils \
        git make build-essential pkg-config \
        openjdk-8-jdk \
        libc6:i386 libncurses5:i386 libstdc++6:i386 \
        libgtk-3-0 libxtst6 libxrender1 libxi6 \
        libgl1 libglu1-mesa libcanberra-gtk3-module libdbus-glib-1-2 \
        libsecret-1-0 \
        fonts-dejavu fonts-liberation \
        dbus-x11 xauth \
        locales tzdata sudo && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# Optionally inject custom SSL certificate(s) AFTER the ca-certificates package.
#
# Drop any number of PEM-format *.crt files into the local ./certs/ directory
# and they will be merged into the system trust store. Leave ./certs/ empty
# (only the .gitkeep placeholder) and the stock built-in Ubuntu certificates
# are used unchanged.
#
# Copying a *directory* (rather than a named file) is what makes this optional:
# the build does not fail when no custom cert is present, whereas a
# `COPY ca-certificates.crt ...` would error if that file were missing.
COPY certs/ /usr/local/share/ca-certificates/
RUN update-ca-certificates
# SSL_CERT_FILE needed for wget; update-ca-certificates regenerates this bundle.
ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

# -----------------------------------------------------------------------------
# 2) Eclipse 2019-06 R (C/C++ Developers package — bundles CDT 9.8.0)
# -----------------------------------------------------------------------------
RUN cd /tmp && \
    wget --progress=dot:giga -O "${ECLIPSE_PKG}" "${ECLIPSE_URL}" && \
    if [ "${SKIP_CHECKSUM_CHECK}" = "1" ]; then \
        echo "SKIP_CHECKSUM_CHECK=1 — skipping sha256 check for ${ECLIPSE_PKG}"; \
    else \
        echo "${ECLIPSE_SHA256}  ${ECLIPSE_PKG}" | sha256sum -c -; \
    fi && \
    tar -xzf "${ECLIPSE_PKG}" -C /opt && \
    rm "${ECLIPSE_PKG}" && \
    ln -s /opt/eclipse/eclipse /usr/local/bin/eclipse

# -----------------------------------------------------------------------------
# 3) GNU MCU Eclipse plug-ins 4.1.1 — installed offline from the local
#    repository archive via the p2 director.
#
#    Installing ONLY the features that the host has installed:
#      - managedbuild.cross.arm  (the actual cross-build support)
#      - debug.gdbjtag.jlink     (J-Link Debugging)
#      - debug.gdbjtag.openocd   (OpenOCD Debugging)
#      - packs                   (CMSIS Packs view, harmless and useful)
#      - doc.user                (offline docs)
#
#    Deliberately NOT installing:
#      - templates.stm           (host doesn't have it; legacy projects don't
#                                 need it; user uses CubeMX separately)
#      - templates.cortexm,
#        templates.freescale,
#        templates.ad            (not present on the host)
#      - debug.gdbjtag.qemu      (no QEMU on host; build-only image)
#
#    The 4.1.1 plug-ins require CDT's "C/C++ GDB Hardware Debugging" feature,
#    which IS included in the 2019-06 C/C++ EPP package by default. So we
#    install the plug-ins directly against the running Eclipse install.
# -----------------------------------------------------------------------------
RUN mkdir -p /opt/eclipse-archives && \
    cd /opt/eclipse-archives && \
    wget --progress=dot:giga -O "${GNUMCU_ZIP}" "${GNUMCU_URL}" && \
    if [ "${SKIP_CHECKSUM_CHECK}" = "1" ]; then \
        echo "SKIP_CHECKSUM_CHECK=1 — skipping sha256 check for ${GNUMCU_ZIP}"; \
    else \
        echo "${GNUMCU_SHA256}  ${GNUMCU_ZIP}" | sha256sum -c -; \
    fi

RUN /opt/eclipse/eclipse \
        -application org.eclipse.equinox.p2.director \
        -noSplash \
        -repository "jar:file:/opt/eclipse-archives/${GNUMCU_ZIP}!/" \
        -installIU ilg.gnumcueclipse.managedbuild.cross.arm.feature.feature.group \
        -installIU ilg.gnumcueclipse.debug.gdbjtag.jlink.feature.feature.group \
        -installIU ilg.gnumcueclipse.debug.gdbjtag.openocd.feature.feature.group \
        -installIU ilg.gnumcueclipse.packs.feature.feature.group \
        -installIU ilg.gnumcueclipse.doc.user.feature.feature.group

# Verify the install worked — fail the build if a feature didn't take.
RUN /opt/eclipse/eclipse \
        -application org.eclipse.equinox.p2.director \
        -noSplash \
        -listInstalledRoots | tee /tmp/installed.txt && \
    grep -q "ilg.gnumcueclipse.managedbuild.cross.arm"        /tmp/installed.txt && \
    grep -q "ilg.gnumcueclipse.debug.gdbjtag.jlink"            /tmp/installed.txt && \
    grep -q "ilg.gnumcueclipse.debug.gdbjtag.openocd"          /tmp/installed.txt && \
    rm /tmp/installed.txt

# -----------------------------------------------------------------------------
# 4) gcc-arm-none-eabi 6-2017-q2-update (GCC 6.3.1)
# -----------------------------------------------------------------------------
RUN cd /tmp && \
    wget --progress=dot:giga -O "${GCC_ARM_TARBALL}" "${GCC_ARM_URL}" && \
    if [ "${SKIP_CHECKSUM_CHECK}" = "1" ]; then \
        echo "SKIP_CHECKSUM_CHECK=1 — skipping sha256 check for ${GCC_ARM_TARBALL}"; \
    else \
        echo "${GCC_ARM_SHA256}  ${GCC_ARM_TARBALL}" | sha256sum -c -; \
    fi && \
    mkdir -p /opt/gcc-arm-none-eabi && \
    tar -xjf "${GCC_ARM_TARBALL}" -C /opt/gcc-arm-none-eabi --strip-components=1 && \
    rm "${GCC_ARM_TARBALL}"

ENV PATH="/opt/gcc-arm-none-eabi/bin:${PATH}"

# Sanity check — fails the build if 32-bit libs are wrong or the toolchain
# is broken. Expected output line one: "arm-none-eabi-gcc (GNU Tools for Arm
# Embedded Processors 6-2017-q2-update) 6.3.1 20170620 (release) ..."
RUN arm-none-eabi-gcc --version && \
    arm-none-eabi-gcc --version | head -1 | grep -q "6-2017-q2-update" && \
    arm-none-eabi-gcc -print-multi-lib | head -1

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

ARG EBOX_OCI_TITLE="EBox - STM32-legacy-0"
ARG EBOX_OCI_DESCRIPTION="Frozen legacy STM32 toolchain, July-2017 plug-ins on June-2019 Eclipse (Eclipse 2019-06 + GNU MCU 4.1.1), the EBox project"
ARG EBOX_OCI_VERSION="19700101-0"
ARG EBOX_OCI_REVISION="20260602-0-BETA"
ARG EBOX_OCI_LICENSE="MIT"
ARG EBOX_OCI_AUTHORS="The EBox Authors"

LABEL org.opencontainers.image.title="${EBOX_OCI_TITLE}" \
      org.opencontainers.image.description="${EBOX_OCI_DESCRIPTION}" \
      org.opencontainers.image.version="${EBOX_OCI_VERSION}" \
      org.opencontainers.image.revision="${EBOX_OCI_REVISION}" \
      org.opencontainers.image.licenses="${EBOX_OCI_LICENSE}" \
      org.opencontainers.image.authors="${EBOX_OCI_AUTHORS}" \
      org.opencontainers.image.ref.name="ebox-stm32-legacy-0"

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
