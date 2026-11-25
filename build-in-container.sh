#!/bin/bash
# Runs inside the container. Usage: build-in-container.sh <targets> [settings file]
#   targets        comma separated, e.g. esp32s3 or esp32s3,esp32c6,esp32
#   settings file  Kconfig lines added to every build (none = stock settings)
set -eo pipefail
TARGETS="$1"; SETTINGS="${2:-}"
source /recipe/pins.env

# One commit of a repository, without its history.
fetch_commit() {  # <dir> <url> <full commit id> <branch name> <id length>
    if [ ! -d "$1/.git" ]; then
        rm -rf "$1"; mkdir -p "$1"; git -C "$1" init -q; git -C "$1" remote add origin "$2"
    fi
    if [ "$(git -C "$1" rev-parse -q --verify HEAD 2>/dev/null)" != "$3" ]; then
        git -C "$1" fetch -q --depth 1 origin "$3"
        git -C "$1" checkout -q -f FETCH_HEAD
    fi
    git -C "$1" checkout -q -B "$4"   # the branch name the stock build had
    git -C "$1" config core.abbrev "$5"   # a commit without history prints a shorter id
}

cd /work
fetch_commit lib-builder https://github.com/espressif/esp32-arduino-lib-builder.git "$LIB_BUILDER_COMMIT" master 7
cd lib-builder
git checkout -q -f "$LIB_BUILDER_COMMIT" -- configs
if [ -n "$SETTINGS" ]; then
    echo "* Rootero settings:"; cat "/recipe/$SETTINGS"
    printf '\n' >> configs/defconfig.common
    cat "/recipe/$SETTINGS" >> configs/defconfig.common
fi
fetch_commit components/arduino_tinyusb/tinyusb https://github.com/hathach/tinyusb.git "$TINYUSB_COMMIT" master 9
fetch_commit components/arduino https://github.com/espressif/arduino-esp32.git "$ARDUINO_COMMIT" idf-release/v5.5 9
fetch_commit esp-idf https://github.com/espressif/esp-idf.git "$IDF_COMMIT" release/v5.5 10
git -C esp-idf submodule update -q --init --recursive --depth 1

export IDF_PATH="$PWD/esp-idf"
if [ ! -f /work/.idf-tools-installed ] || [ "$(cat /work/.idf-tools-installed)" != "$IDF_COMMIT" ]; then
    echo "* Installing the ESP-IDF tools"
    "$IDF_PATH/install.sh" > /dev/null
    echo "$IDF_COMMIT" > /work/.idf-tools-installed
fi
export IDF_TOOLS_PATH="${IDF_TOOLS_PATH:-/work/.espressif}"
source "$IDF_PATH/export.sh"
# One chip at a time, each with the component versions of the stock build (its lock file):
# without it the component manager takes today's newest versions.
for target in ${TARGETS//,/ }; do
    lock="/recipe/locks/$CORE_VERSION/$target.lock"
    [ -f "$lock" ] || { echo "no lock file for $target ($lock)"; exit 1; }
    rm -rf managed_components dependencies.lock build sdkconfig
    cp "$lock" dependencies.lock
    ./build.sh -s -t "$target"
    if ! diff <(grep -E "^  [a-z].*:$|^    version:" "$lock") \
              <(grep -E "^  [a-z].*:$|^    version:" dependencies.lock) > /dev/null; then
        echo "ERROR: $target was built with other component versions than the lock file"; exit 1
    fi
done
echo "* done: /work/lib-builder/out/tools/esp32-arduino-libs"
