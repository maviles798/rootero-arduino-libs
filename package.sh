#!/bin/bash
# package.sh <release number> — pack the built chips (docker volume rootero-libs-work, /work/result)
# into out/rootero-libs-<core>-r<n>.tar.xz, with the same layout as the stock package.
set -eo pipefail
cd "$(dirname "$0")"
source pins.env
N="$1"; [ -n "$N" ] || { echo "usage: package.sh <release number>"; exit 1; }
NAME="rootero-libs-$CORE_VERSION-r$N"
rm -rf "out/$NAME" && mkdir -p "out/$NAME/esp32-arduino-libs"
# As the calling user: on Linux the copied files would belong to root otherwise.
docker run --rm --user "$(id -u):$(id -g)" -v rootero-libs-work:/work -v "$PWD/out/$NAME/esp32-arduino-libs":/o rootero-libs-build \
    sh -c 'cp -a /work/result/. /o/'
P="out/$NAME/esp32-arduino-libs"
[ ! -e "$P/sdkconfig" ] || { echo "a top-level sdkconfig would make PlatformIO reinstall the framework"; exit 1; }
python3 - "$P/package.json" "$CORE_VERSION" "$N" <<'PY'
import json, sys
p, core, n = sys.argv[1:]
d = json.load(open(p))
d["version"] = d["version"].split("+")[0] + f"+rootero.{core}.r{n}"
d["description"] += " — rebuilt with Rootero's settings (github.com/maviles798/rootero-arduino-libs)"
json.dump(d, open(p, "w"), indent=2)
PY
{ echo "$NAME"; echo "Arduino core $CORE_VERSION; sources: see pins.env"; echo "Settings that differ from stock:"; grep -v '^#' rootero.defconfig; } > "$P/ROOTERO.txt"
tar -C "out/$NAME" -cJf "out/$NAME.tar.xz" esp32-arduino-libs
shasum -a 256 "out/$NAME.tar.xz"
ls -la "out/$NAME.tar.xz" | awk '{print $5 " bytes"}'
