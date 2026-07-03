# Vivado, Vitis 2026.1

**❗ WIP (Work In Progress) ❗**

## Generating `install_config.txt`

The provided `Dockerfile-setup` is used to build a temporary container image for
generating `install_config.txt`.

To build this temporary image, run the following command:

```bash
sudo docker build --file Dockerfile-setup --tag vivado:2026.1-setup .
```

One option is to use the Vivado installer in batch (text) mode. To do this, you
simply need to run the container and execute `xsetup` with the appropriate
option:

```bash
sudo docker run --rm -it vivado:2026.1-setup
```

Once inside the container, run:

This will launch the batch mode installer and generate the `install_config.txt`
file. You should see a prompt similar to the following:

```bash
/tmp/installer/xsetup -b ConfigGen
```

Example output:

```text
root@7d6aa5397666:/# /tmp/installer/xsetup -b ConfigGen
This is a fresh install.
Running in batch mode...
+---------------------------------------------------------------------------+
|                  AMD Installer for FPGAs & Adaptive SoCs                  |
|---------------------------------------------------------------------------|
|                    Build Date:  2026-05-27 11:41:04 UTC                   |
|                    Branch:      2026.1                                    |
|                    Version:     f57d91f                                   |
|                                                                           |
| Copyright (c) 1986-2022 Xilinx, Inc. All rights reserved.                 |
| Copyright (c) 2022-2025 Advanced Micro Devices, Inc. All rights reserved. |
+---------------------------------------------------------------------------+

WARN  - WARNING: You are running this installer as the root user.
WARN  - It is recommended to run the installer as a regular user to avoid potential security risks.

Select a Product from the list:
1. Vitis
2. Vivado
3. Vitis Embedded Development
4. BootGen
5. Lab Edition
6. Hardware Server
7. Power Design Manager (PDM)
8. On-Premises Install for Cloud Deployments
9. Documentation Navigator (Standalone)

Please choose: 1
INFO  - Config file available at /root/.Xilinx/install_config.txt. Please use -c <filename> to point to this install configuration.
```

First, allow Docker to access your X server:

```bash
xhost +local:docker
```

Then, run the container with access to the X server:

```bash
sudo docker run --rm -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=${DISPLAY} \
  vivado:2026.1-setup
```

Inside the container, run the installer:

```bash
/tmp/installer/xsetup
```

## Building the image

The Vivado installer tar lives in `./installer/` and is supplied as a *named
build context* (`vivado_installer`) rather than the main build context. It is
bind-mounted read-only during the install step, so it is never copied into an
image layer and never re-transferred as part of the main context.

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20260703-0

# Build the Docker image with tagging and log output
sudo docker build \
  --build-context vivado_installer=./installer \
  -t vivado:2026.1-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

Or, using Podman:

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20260703-0

# Build the image with Podman
podman build \
  --build-context vivado_installer=./installer \
  -t vivado:2026.1-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

`--build-context` requires `docker buildx` (BuildKit, default in recent Docker)
or `podman`/`buildah` >= 4.x.

### Skipping the MD5 check

By default the build verifies the installer tar against a known MD5 before
extracting it, which reads all ~100 GB and adds noticeable time. If you have
already verified the download yourself (or simply don't need the check during
local development), skip it with `--build-arg SKIP_MD5=1`:

```bash
podman build \
  --build-context vivado_installer=./installer \
  --build-arg SKIP_MD5=1 \
  -t vivado:2026.1-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

The same `--build-arg SKIP_MD5=1` works with `docker build`. Leave the check
enabled for release builds; the expected MD5 is the `MD5` build arg in the
`Dockerfile`.
