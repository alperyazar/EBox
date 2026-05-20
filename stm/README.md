# STM - STMicroelectronics

Cube IDE etc. in container.

Example for Cube IDE 1.5.1. Download deb edition from st.com.
`st-stm32cubeide_1.5.1_9029_20201210_1234_amd64.deb_bundle.sh.zip`

## Building the image

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20250424-1

# Build the Docker image with tagging and log output
sudo docker build \
  -t stm32cubeide:1.5.1-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

## Runing the image

To test:

```shell
sudo docker run --rm -it --user ebox stm32cubeide:1.5.1-$TAG
```

with X11

```shell
sudo docker run --rm -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=${DISPLAY} \
  -u ebox \
  stm32cubeide:1.5.1-$TAG
```
