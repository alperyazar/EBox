# PetaLinux 2024.1

> ⚠️ Work in Progress

Similar to [Vivado/Vitis 2024.1](../../vivado-vitis-sdk/2024.1/README.md)

## Building the image

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20250424-1

# Build the Docker image with tagging and log output
sudo docker build \
  -t petalinux:2024.1-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

## Runing the image

To test:

```shell
sudo docker run --rm -it --user ebox petalinux:2024.1-$TAG
```

----

```text
root@e28d3bf120c1:~/xilinx-zc702-2024.1# petalinux-build 
[INFO] Building project
[INFO] Extracting yocto SDK to components/yocto. This may take time!
[ERROR] 
PetaLinux Extensible SDK installer version 2024.1
=================================================
ERROR: The extensible sdk cannot be installed as root.
```


