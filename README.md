# rootero-arduino-libs

The precompiled ESP-IDF libraries of the Arduino core for ESP32, rebuilt with a few
changed settings for Rootero firmware. Everything here comes from Espressif's public
sources and their [esp32-arduino-lib-builder](https://github.com/espressif/esp32-arduino-lib-builder).

- `pins.env`: the source versions, the same as the stock libraries of the Arduino core named there.
- `rootero.defconfig`: the settings that differ from stock.
- `Dockerfile`, `build-in-container.sh`: the build.

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

Status: recipe under test, no package released yet.

The libraries keep their original licenses (see the Espressif repositories).
