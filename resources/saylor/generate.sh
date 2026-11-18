#!/bin/bash
#
# Regenerates every Saylor-branded image in the app from the SVGs in this folder.
# Needs Google Chrome (used headless as the SVG renderer) and python3. macOS only.
#
#   ./resources/saylor/generate.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

NAVY="#173140"

# render <out.png> <width> <height> <background css> <svg file> <svg width in px>
render() {
    local out="$1" w="$2" h="$3" bg="$4" svg="$5" sw="$6"
    local page="$TMP/page.html"
    cat > "$page" <<HTML
<!doctype html><html><head><style>
html,body{margin:0;width:${w}px;height:${h}px;background:${bg};overflow:hidden}
body{display:flex;align-items:center;justify-content:center}
img{width:${sw}px;height:auto;display:block}
</style></head><body><img src="file://${HERE}/${svg}"></body></html>
HTML
    "$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
        --allow-file-access-from-files --default-background-color=00000000 \
        --window-size="${w},${h}" --screenshot="$out" "file://$page" >/dev/null 2>&1
    echo "  $(basename "$out") ${w}x${h}"
}

echo "App icon"
render "$ROOT/resources/icon.png" 1024 1024 "$NAVY" mark-reversed.svg 640
cp "$ROOT/resources/icon.png" "$ROOT/src/assets/icon/icon.png"
cp "$ROOT/resources/icon.png" "$ROOT/src/assets/icon/favicon.png"

echo "Android adaptive icon foreground (background colour lives in resources/values/colors.xml)"
render "$ROOT/resources/android/icon-foreground.png" 1024 1024 transparent mark-reversed.svg 470

echo "Android launcher icons per density (referenced from config.xml)"
for spec in ldpi:36:81 mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
    IFS=: read -r density legacy adaptive <<< "$spec"
    render "$ROOT/resources/android/icon/${density}-icon.png" "$legacy" "$legacy" "$NAVY" mark-reversed.svg "$((legacy * 640 / 1024))"
    render "$ROOT/resources/android/icon/${density}-foreground.png" "$adaptive" "$adaptive" transparent mark-reversed.svg "$((adaptive * 470 / 1024))"
done

echo "Splash screens"
render "$ROOT/resources/splash.png" 2732 2732 "$NAVY" logo-reversed.svg 1000
render "$ROOT/resources/android/android-splash.png" 1152 1152 transparent mark-reversed.svg 520
mkdir -p "$ROOT/resources/ios/splash"
cp "$ROOT/resources/splash.png" "$ROOT/resources/ios/splash/Default@2x~universal~anyany.png"

echo "Android notification icons"
for spec in ldpi:18 mdpi:24 hdpi:36 xhdpi:48; do
    size="${spec#*:}"
    render "$ROOT/resources/android/icon/drawable-${spec%%:*}-smallicon.png" "$size" "$size" transparent mark-white.svg "$size"
done

echo "In-app logos"
render "$ROOT/src/assets/img/login_logo.png" 600 147 transparent logo-color.svg 600
render "$ROOT/src/assets/img/login_logo_dark.png" 600 147 transparent logo-reversed.svg 600
render "$ROOT/src/assets/img/top_logo.png" 600 147 transparent logo-reversed.svg 600

echo "Dropping the alpha channel from opaque images (the App Store rejects icons that have one)"
python3 "$HERE/strip_alpha.py" "$ROOT/resources/icon.png" "$ROOT/src/assets/icon/icon.png" \
    "$ROOT/src/assets/icon/favicon.png" "$ROOT/resources/splash.png" \
    "$ROOT/resources/ios/splash/Default@2x~universal~anyany.png" "$ROOT"/resources/android/icon/*-icon.png
