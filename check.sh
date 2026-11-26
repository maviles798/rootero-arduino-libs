#!/bin/bash
# check.sh <release number> — the gate for a packed build (out/rootero-libs-<core>-r<n>).
# Fails unless the package differs from the stock libraries only where we chose:
#   - each chip's settings (sdkconfig) differ from stock by exactly rootero.defconfig.expect;
#   - each chip has the same files as stock;
#   - the marker file and the layout are what PlatformIO and the hub builder expect.
set -eo pipefail
cd "$(dirname "$0")"
source pins.env
N="$1"; [ -n "$N" ] || { echo "usage: check.sh <release number>"; exit 1; }
NAME="rootero-libs-$CORE_VERSION-r$N"
P="out/$NAME/esp32-arduino-libs"
S="out/stock/esp32-arduino-libs"
fail() { echo "CHECK FAILED: $*"; exit 1; }

[ -d "$P" ] || fail "no package at $P (run package.sh $N first)"
if [ ! -d "$S" ]; then
    echo "* Downloading the stock libraries"
    mkdir -p out/stock
    curl -fsSL --retry 3 -o out/stock/stock-libs.tar.xz "$STOCK_LIBS_URL"
    tar -C out/stock -xJf out/stock/stock-libs.tar.xz
fi

[ ! -e "$P/sdkconfig" ] || fail "a top-level sdkconfig would make PlatformIO reinstall the framework"
[ "$(head -n 1 "$P/ROOTERO.txt")" = "$NAME" ] || fail "the first line of ROOTERO.txt is not $NAME"
# versions.txt: the same four sources, and no component version that stock does not have
# (stock lists the components of every chip, the package only those of its chips).
cmp -s <(head -n 4 "$P/versions.txt") <(head -n 4 "$S/versions.txt") || fail "versions.txt: the sources differ from stock"
if grep -vxFf "$S/versions.txt" "$P/versions.txt"; then
    fail "versions.txt: the component versions above are not the stock ones"
fi
grep -q "\"version\": \"[^\"]*+rootero\.$CORE_VERSION\.r$N\"" "$P/package.json" || fail "package.json does not carry the version of $NAME"

for chip in ${CHIPS//,/ }; do
    [ -d "$P/$chip" ] || fail "$chip is missing"
    if ! diff <(diff "$S/$chip/sdkconfig" "$P/$chip/sdkconfig" | grep '^[<>]') rootero.defconfig.expect; then
        fail "$chip: the settings differ from stock in another way than rootero.defconfig.expect"
    fi
    # Stock keeps a copy of versions.txt in each chip folder; the build recipe does not.
    if ! diff <(cd "$S/$chip" && find . | grep -v '^\./versions\.txt$' | LC_ALL=C sort) \
              <(cd "$P/$chip" && find . | LC_ALL=C sort); then
        fail "$chip: the files are not the same as in stock"
    fi
    echo "ok  $chip"
done
for d in "$P"/*/; do
    case ",$CHIPS," in *",$(basename "$d"),"*) ;; *) fail "unexpected folder $(basename "$d")";; esac
done
if [ -f "out/$NAME.tar.xz" ]; then
    [ "$(tar -tJf "out/$NAME.tar.xz" | head -n 1)" = "esp32-arduino-libs/" ] || fail "the archive does not start with esp32-arduino-libs/"
fi
echo "CHECK PASSED: $NAME"
