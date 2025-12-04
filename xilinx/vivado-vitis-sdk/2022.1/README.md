# Vivado 2022.1

## Creating `install_config.txt`

```shell
sudo docker build --file Dockerfile-setup --tag vivado:2022.1-setup .
```

then

first

```shell
sudo docker run --rm -it vivado:2022.1-setup
```

inside the container, run

```shell
/tmp/installer/xsetup -b ConfigGen
```

to create install config.

Then `cat /root/.Xilinx/install_config.txt` and save the content (and modify if
you need) as `install_config.txt`

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
  vivado:2022.1-setup
```

then inside the container

```shell
/tmp/installer/xsetup
```