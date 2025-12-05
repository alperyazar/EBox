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

## Building the image

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20250424-1

# Build the Docker image with tagging and log output
sudo docker build \
  -t vivado:2022.1-$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

## Runing the image

To test:

```shell
sudo docker run --rm -it --user ebox vivado:2022.1-$TAG
```

with X11

```shell
sudo docker run --rm -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=${DISPLAY} \
  -u ebox \
  vivado:2022.1-$TAG
```

## Notlar

```text
Abnormal program termination (11)
Please check '/home/ebox/hs_err_pid52.log' for details
segfault in /opt/Xilinx/Vivado/2022.1/bin/unwrapped/lnx64.o/vivado -exec vivado, exiting...
ebox@40b5aad2f578:~$ cat /home/ebox/hs_err_pid52.log
#
# An unexpected error has occurred (11)
#
Stack:
/opt/Xilinx/Vivado/2022.1/tps/lnx64/jre11.0.11_9/lib//server/libjvm.so(+0xbefecb) [0x7fb27b28fecb]
/opt/Xilinx/Vivado/2022.1/tps/lnx64/jre11.0.11_9/lib//server/libjvm.so(JVM_handle_linux_signal+0xd1) [0x7fb27b296c81]
/opt/Xilinx/Vivado/2022.1/tps/lnx64/jre11.0.11_9/lib//server/libjvm.so(+0xbead23) [0x7fb27b28ad23]
/opt/Xilinx/Vivado/2022.1/tps/lnx64/javafx-sdk-11.0.2/lib/libjfxwebkit.so(+0x205ae18) [0x7fb23066ce18]
/lib/x86_64-linux-gnu/libc.so.6(+0x43090) [0x7fb2d1e98090]
/lib/x86_64-linux-gnu/libc.so.6(malloc_usable_size+0x48) [0x7fb2d1ef11f8]
/lib/x86_64-linux-gnu/libudev.so.1(+0x10319) [0x7fb2566a8319]
/lib/x86_64-linux-gnu/libudev.so.1(+0x167c4) [0x7fb2566ae7c4]
/lib/x86_64-linux-gnu/libudev.so.1(+0x1b255) [0x7fb2566b3255]
/lib/x86_64-linux-gnu/libudev.so.1(+0x1b4bb) [0x7fb2566b34bb]
/lib/x86_64-linux-gnu/libudev.so.1(udev_enumerate_scan_devices+0x277) [0x7fb2566b5d67]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(+0x129015) [0x7fb2ca768015]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(xilinxd_52bd866351b78202+0x9) [0x7fb2ca768499]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(+0xd6317) [0x7fb2ca715317]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(xilinxd_52bd862318b59a70+0x86) [0x7fb2ca7150d6]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(+0xc364f) [0x7fb2ca70264f]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(xilinxd_52bd9e9e1c8e52fb+0x1b) [0x7fb2ca70c3eb]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libXil_lmgr11.so(xilinxd_52bd700d1bd3c616+0x30) [0x7fb2ca70c480]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commonxillic.so(XilReg::Utils::GetHostInfo[abi:cxx11](XilReg::Utils::HostInfoType, bool) const+0x1a0) [0x7fb2ce667cd0]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commonxillic.so(XilReg::Utils::GetHostInfoFormatted[abi:cxx11](XilReg::Utils::HostInfoType, bool) const+0x59) [0x7fb2ce66abc9]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commonxillic.so(XilReg::Utils::GetHostInfo[abi:cxx11]() const+0x103) [0x7fb2ce66ae83]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commonxillic.so(XilReg::Utils::GetRegInfo(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&, bool, bool)+0x96) [0x7fb2ce671f96]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commonxillic.so(XilReg::Utils::GetRegInfoWebTalk(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)+0x60) [0x7fb2ce6721c0]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_project.so(HAPRWebtalkHelper::getRegistrationId[abi:cxx11]() const+0x3d) [0x7fb2904d1bdd]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_project.so(HAPRWebtalkHelper::HAPRWebtalkHelper(HAPRProject*, HAPRDesign*, HWEWebtalkMgr*, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)+0x178) [0x7fb2904d42d8]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_tcltasks.so(+0x1d68475) [0x7fb2c55f4475]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_tcltasks.so(+0x1d71474) [0x7fb2c55fd474]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_common.so(+0xb44ccf) [0x7fb2d2faaccf]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(+0x3356f) [0x7fb2cdebc56f]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(+0x76945) [0x7fb2cdeff945]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(+0x7e0f9) [0x7fb2cdf070f9]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(TclEvalObjEx+0x76) [0x7fb2cdebe216]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_common.so(+0xb435b3) [0x7fb2d2fa95b3]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(Tcl_ServiceEvent+0x7f) [0x7fb2cdf30bef]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(Tcl_DoOneEvent+0x154) [0x7fb2cdf30f24]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commontasks.so(+0x2b39f7) [0x7fb2c7b129f7]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commontasks.so(+0x2bc22f) [0x7fb2c7b1b22f]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commontasks.so(+0x2bcb3f) [0x7fb2c7b1bb3f]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_common.so(+0xb44ccf) [0x7fb2d2faaccf]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(+0x3356f) [0x7fb2cdebc56f]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(+0x76945) [0x7fb2cdeff945]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(+0x7e0f9) [0x7fb2cdf070f9]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(TclEvalObjEx+0x76) [0x7fb2cdebe216]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_commonmain.so(+0xc538) [0x7fb2d2458538]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/libtcl8.5.so(Tcl_Main+0x1d0) [0x7fb2cdf292f0]
/opt/Xilinx/Vivado/2022.1/lib/lnx64.o/librdi_common.so(+0xb721fb) [0x7fb2d2fd81fb]
/lib/x86_64-linux-gnu/libpthread.so.0(+0x8609) [0x7fb2d1e3a609]
/lib/x86_64-linux-gnu/libc.so.6(clone+0x43) [0x7fb2d1f74353]
ebox@40b5aad2f578:~$ LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1 vivado
```

ÜSTTEKİNİN çözümü `LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1 vivado`


----

```text
(java:106690): dbind-WARNING **: 05:26:09.844: Couldn't connect to accessibility bus: Failed to connect to socket /run/user/1000/at-spi/bus_0: No such file or directory
SWT SessionManagerDBus: Failed to connect to org.gnome.SessionManager: Failed to execute child process “dbus-launch” (No such file or directory)
SWT SessionManagerDBus: Failed to connect to org.xfce.SessionManager: Failed to execute child process “dbus-launch” (No such file or directory)

(Vitis IDE:106690): dconf-WARNING **: 05:26:18.306: failed to commit changes to dconf: Failed to execute child process “dbus-launch” (No such file or directory)
```

ÜSTEKİNİN çözümü `ENV NO_AT_BRIDGE=1`

---

```text
xsct
/opt/Xilinx/Vitis/2022.1/bin/xsct: line 241: 115721 Segmentation fault      (core dumped) "$RDI_BINROOT"/unwrapped/"$RDI_PLATFORM$RDI_OPT_EXT"/rlwrap -rc -b "(){}[],+= & ^%$#@"";|\\" -f "$HDI_APPROOT"/scripts/xsct/xsdb/cmdlist -H "$LOG_FILE" "$RDI_BINROOT"/loader -exec rdi_xsct "${RDI_ARGS[@]}"
```

Çözüm: `rlwrap` olan

---

Create hardware platform GUI açılmıyor,

Çözüm: `apt install gnome-icon-theme`


