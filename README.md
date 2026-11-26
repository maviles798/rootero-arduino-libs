# rootero-arduino-libs

The precompiled ESP-IDF libraries of the Arduino core for ESP32, rebuilt with a few
changed settings for Rootero firmware. Everything here comes from Espressif's public
sources and their [esp32-arduino-lib-builder](https://github.com/espressif/esp32-arduino-lib-builder).

- `pins.env`: the source versions, the same as the stock libraries of the Arduino core named there.
- `rootero.defconfig`: the settings that differ from stock.
- `Dockerfile`, `build-in-container.sh`: the build.
- `package.sh`, `check.sh`: pack a build, and check it against the stock libraries.
- `rootero.defconfig.expect`: the exact difference to the stock settings that the check allows.

## Build

```bash
docker build -t rootero-libs-build .
# stock settings (must reproduce the stock libraries):
docker run --rm -v rootero-libs-work:/work -v "$PWD":/recipe:ro rootero-libs-build \
    /recipe/build-in-container.sh esp32s3
# with the Rootero settings:
docker run --rm -v rootero-libs-work:/work -v "$PWD":/recipe:ro rootero-libs-build \
    /recipe/build-in-container.sh esp32s3,esp32c6,esp32 rootero.defconfig
```

The result is in the `rootero-libs-work` volume under `lib-builder/out/tools/esp32-arduino-libs`.

Releases: one file per version, `rootero-libs-<core>-r<n>.tar.xz`. A name is never reused.

## Release

On GitHub: Actions, "Build the libraries package", Run workflow, with the next release
number. It builds, packs and checks; the file is kept with the run. With "publish" on it
also becomes a pre-release. Mark it as a full release by hand after a bench test.

By hand: `./package.sh <n>` packs a build, `./check.sh <n>` checks it.

A change of settings: edit `rootero.defconfig` and `rootero.defconfig.expect` together.
A new Arduino core: new commits and stock URL in `pins.env`, new lock files in `locks/`.

The libraries keep their original licenses (see the Espressif repositories).
