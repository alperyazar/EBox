# ISE 14.7

> Work In Progress

## Creating `install_config.txt`

```shell
sudo docker build --file Dockerfile-setup --tag ise:14.7-setup .
```

then

first

```shell
sudo docker run --rm -it ise:14.7-setup
```

inside the container, run

```shell
/tmp/installer/bin/lin64/batchxsetup --samplebatchscript /tmp/install_config.txt
```

to create install config.

Then `cat /tmp/install_config.txt` and save the content (and modify if you
need) as `install_config.txt`

---

OR

interactive installer but can't save the config file, so pretty useless for
our case.

First enable X11 access

```shell
xhost +local:docker
```

then run as

```shell
sudo docker run --rm -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=${DISPLAY} \
  ise:14.7-setup
```

then inside the container

```shell
/tmp/installer/xsetup
```

## Building the image

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20250424-1

# Build the Docker image with tagging and log output
sudo docker build \
  -t ise:14.7-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

## Runing the image

To test:

```shell
sudo docker run --rm -it --user ebox ise:14.7-$TAG
```

with X11

```shell
sudo docker run --rm -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=${DISPLAY} \
  -u ebox \
  ise:14.7-$TAG
```
