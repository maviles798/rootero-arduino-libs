#!/bin/bash
# Runs inside the container. Usage: build-in-container.sh <targets> [settings file]
#   targets        comma separated, e.g. esp32s3 or esp32s3,esp32c6,esp32
#   settings file  Kconfig lines added to every build (none = stock settings)
set -eo pipefail
TARGETS="$1"; SETTINGS="${2:-}"
source /recipe/pins.env
cd /work
if [ ! -d lib-builder ]; then
    git clone https://github.com/espressif/esp32-arduino-lib-builder.git lib-builder
fi
cd lib-builder
git checkout -q -f "$LIB_BUILDER_COMMIT"
if [ -n "$SETTINGS" ]; then
    echo "* Rootero settings:"; cat "/recipe/$SETTINGS"
    printf '\n' >> configs/defconfig.common
    cat "/recipe/$SETTINGS" >> configs/defconfig.common
fi
[ -d components/arduino_tinyusb/tinyusb ] || git clone https://github.com/hathach/tinyusb.git components/arduino_tinyusb/tinyusb
git -C components/arduino_tinyusb/tinyusb checkout -q "$TINYUSB_COMMIT"
[ -d components/arduino ] || git clone https://github.com/espressif/arduino-esp32.git components/arduino
git -C components/arduino checkout -q "$ARDUINO_COMMIT"
export IDF_COMMIT
source ./tools/install-esp-idf.sh
./build.sh -s -t "$TARGETS"
echo "* done: /work/lib-builder/out/tools/esp32-arduino-libs"
