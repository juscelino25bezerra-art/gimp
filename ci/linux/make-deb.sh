#!/usr/bin/env bash
# Experimental .deb for Debian 13 (trixie) x86_64.
# Install the fork under /opt rather than overwriting distro GIMP.
set -euo pipefail

cd "$(dirname "$0")/../.."
PREFIX=/opt/gimp-photo-dev
STAGE="$PWD/_deb-stage"
test -x "$PREFIX/bin/gimp-3.3" || { echo "GIMP binary missing from $PREFIX" >&2; exit 1; }

VERSION="$(awk -F "'" '/  version:/{print $2; exit}' meson.build)"
REVISION="${GITHUB_SHA:-local}"
REVISION="${REVISION:0:7}"
DEB_VERSION="${VERSION}+git.${REVISION}"
ARCH="$(dpkg --print-architecture)"
PKG="gimp-photo-dev_${DEB_VERSION}_${ARCH}.deb"

rm -rf "$STAGE"
mkdir -p "$STAGE/opt" "$STAGE/usr/bin" "$STAGE/usr/share/applications" "$STAGE/DEBIAN"
cp -a "$PREFIX" "$STAGE/opt/"

# Developer files are unnecessary for installing the experimental editor.
rm -rf "$STAGE$PREFIX/include" "$STAGE$PREFIX/share/doc"
find "$STAGE$PREFIX" -type d -name pkgconfig -prune -exec rm -rf '{}' +
find "$STAGE$PREFIX" -type f -name '*.a' -delete

cat > "$STAGE/usr/bin/gimp-photo-dev" <<'WRAPPER'
#!/bin/sh
ROOT=/opt/gimp-photo-dev
MULTIARCH=x86_64-linux-gnu
export PATH="$ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$ROOT/lib/$MULTIARCH:$ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GI_TYPELIB_PATH="$ROOT/lib/$MULTIARCH/girepository-1.0:$ROOT/lib/girepository-1.0${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
export XDG_DATA_DIRS="$ROOT/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export BABL_PATH="$ROOT/lib/$MULTIARCH/babl-0.1:$ROOT/lib/babl-0.1${BABL_PATH:+:$BABL_PATH}"
export GEGL_PATH="$ROOT/lib/$MULTIARCH/gegl-0.4:$ROOT/lib/gegl-0.4${GEGL_PATH:+:$GEGL_PATH}"
exec "$ROOT/bin/gimp-3.3" "$@"
WRAPPER
chmod 755 "$STAGE/usr/bin/gimp-photo-dev"

cat > "$STAGE/usr/share/applications/gimp-photo-dev.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=GIMP Photo Dev (Experimental)
Comment=Experimental GIMP fork for photographic editing
Exec=gimp-photo-dev %U
Terminal=false
Categories=Graphics;2DGraphics;RasterGraphics;Photography;
MimeType=image/png;image/jpeg;image/tiff;image/x-xcf;
DESKTOP

cat > "$STAGE/DEBIAN/control" <<CONTROL
Package: gimp-photo-dev
Version: $DEB_VERSION
Section: graphics
Priority: optional
Architecture: $ARCH
Maintainer: GIMP Photo Dev Contributors <noreply@github.com>
Depends: libc6, libgtk-3-0t64, libglib2.0-0t64, libgexiv2-2, python3, python3-gi, python3-gi-cairo, gjs, glib-networking, gvfs, mypaint-brushes
Description: Experimental photography interface based on the GIMP 3 development tree
 This is an unofficial test build of the GIMP fork.
 It installs under /opt/gimp-photo-dev and uses the
 gimp-photo-dev launcher to avoid replacing distro GIMP.
 Built for Debian 13 (trixie) x86_64, not for all .deb distributions.
CONTROL

mkdir -p dist
dpkg-deb --build --root-owner-group "$STAGE" "dist/$PKG"
dpkg-deb --info "dist/$PKG"
