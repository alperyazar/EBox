# STM32 Dev Environment - STM32-legacy-0

Frozen Legacy Snapshot

A reproducible container image of an existing STM32 development workstation.
Versions chosen to match what is **currently running in production**, not
what was newest in 2019-2020.

## What's inside (matches the existing host exactly)

| Component | Version | Released | Notes |
|---|---|---|---|
| Ubuntu | 20.04 LTS | — | host OS |
| OpenJDK | 8 | — | matches plug-in era; Eclipse 2019-06 also runs on 11 |
| Eclipse Platform | 2019-06 R (4.12.0), build `20190614-1200` | Jun 2019 | C/C++ Developers EPP |
| Eclipse CDT | 9.8.0 | Jun 2019 | bundled with the EPP |
| GNU MCU Eclipse plug-ins | **4.1.1-201707111115** | **Jul 2017** | the existing install is locked to this |
| gcc-arm-none-eabi | 6-2017-q2-update (GCC 6.3.1) | Jun 2017 | same vintage as the plug-ins |

## Installed plug-in features

These match the host's `Installed Software` exactly:

* GNU MCU C/C++ ARM Cross Compiler (`managedbuild.cross.arm`)
* GNU MCU C/C++ J-Link Debugging (`debug.gdbjtag.jlink`)
* GNU MCU C/C++ OpenOCD Debugging (`debug.gdbjtag.openocd`)
* GNU MCU C/C++ Packs (`packs`)
* GNU MCU C/C++ Documentation (`doc.user`)

**Deliberately NOT installed** (the host doesn't have them either):

* STM32Fxx templates — legacy projects are imported directly; CubeMX is run
  separately on the host machine and its generated C/H files are committed.
* Generic Cortex-M templates, Freescale templates, Arduino templates.
* QEMU debugging — build-only image.

## Build

```bash
# Define a version tag
TAG=YYYYMMDD-<Count>  # Change this to match the current date and build count like 20260602-0

# Build the Docker image with tagging and log output
sudo docker build \
  -t stm32-legacy-0:$TAG \
  --build-arg EBOX_OCI_VERSION="$TAG" \
  --progress=plain . \
  2>&1 | tee build.log
```

## Run

Test:

```bash
sudo docker run --rm -it --user ebox stm32-legacy-0:$TAG
```

with X11

```bash
sudo docker run --rm -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=${DISPLAY} \
  -u ebox \
  stm32-legacy-0:$TAG
```

## Headless build (no GUI needed)

The toolchain is on `PATH`:

```bash
docker run --rm -v $PWD:/src -w /src stm32-legacy-0:$TAG \
    arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb ...
```

For an existing project with Eclipse-generated makefiles in `Debug/` or
`Release/`:

```bash
docker run --rm -v $PWD:/src -w /src/Debug stm32-legacy-0:$TAG make all
```

## Why these exact versions?

The host machine was set up around 2019 by an engineer who, per their own
account, followed mcuoneclipse.com tutorials and explicitly chose the older
toolchain rather than tracking newer releases. Specifically:

* **Plug-ins from July 2017** were installed onto an Eclipse from June 2019.
  This means the install pre-dates the Eclipse Embedded CDT rebrand (2020)
  and the xPack migration (mid-2019). All `ilg.gnumcueclipse.*` plug-in IDs
  rather than `org.eclipse.embedcdt.*`.
* **gcc-arm-none-eabi 6-2017-q2-update** is the matching toolchain release
  from the same month as the plug-ins (June 2017). It's a 32-bit Linux ELF —
  hence the `i386` multiarch packages.
* **Eclipse 2019-06** was the latest stable release available when the
  install was performed. It uses CDT 9.8, which is comfortably past the
  CDT 9.2.1 minimum that plug-ins 4.1.1 require.

## Dead URLs you might see in old docs

If you find tutorials referencing any of these, ignore them — they no longer
resolve:

* `gnu-mcu-eclipse.netlify.com/v4-neon-updates` — `.com` domain retired
* `dl.bintray.com/gnu-mcu-eclipse/...` — Bintray sunset by JFrog in 2021
* `gnuarmeclipse.sourceforge.net/updates` — long-deprecated
* `download.eclipse.org/releases/2019-06/` — moved to `archive.eclipse.org`

The Dockerfile uses **GitHub Releases** for the plug-ins archive and
**archive.eclipse.org** for everything else. Both are stable long-term hosts.

## Future maintenance

If you ever need a different plug-in version:

* `4.5.1-201901011632` — last release before the xPack migration
* `4.6.1-201909231407` — first release supporting xPack tools
* `4.7.2-202001271244` — last release under the GNU MCU name
* `5.x` and later — rebranded as Eclipse Embedded CDT, requires Eclipse 2020-06+

Override `GNUMCU_VERSION` build-arg to pick a different one. Bumping to 5.x
also requires a newer Eclipse base (2020-06 or later), which means moving
to OpenJDK 11.
