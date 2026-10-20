#!/usr/bin/env bash
# Build current GIMP sources, not a distribution-provided GIMP executable.
set -euo pipefail

FORMAT="${1:?usage: build-package.sh deb|appimage}"
case "$FORMAT" in deb|appimage) ;; *) echo "Unsupported format: $FORMAT" >&2; exit 2;; esac

cd "$(dirname "$0")/../.."
ROOT="$PWD"
mkdir -p "$ROOT/dist"

# Use the installation layout expected by GIMP's Meson and AppImage tools.
if [[ "$FORMAT" == "deb" ]]; then
  export GIMP_PREFIX=/opt/gimp-photo-dev
else
  export GIMP_PREFIX="$ROOT/_install"
fi
export LIB_DIR=lib
export LIB_SUBDIR="$(gcc -print-multiarch)/"
export PKG_CONFIG_PATH="$GIMP_PREFIX/lib/${LIB_SUBDIR}pkgconfig:$GIMP_PREFIX/lib/pkgconfig:$GIMP_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="$GIMP_PREFIX/lib/${LIB_SUBDIR%/}:$GIMP_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GI_TYPELIB_PATH="$GIMP_PREFIX/lib/${LIB_SUBDIR}girepository-1.0:$GIMP_PREFIX/lib/girepository-1.0${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
export XDG_DATA_DIRS="$GIMP_PREFIX/share:/usr/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export PATH="$GIMP_PREFIX/bin:$PATH"
export APPIMAGE_EXTRACT_AND_RUN=1
export GIT_TERMINAL_PROMPT=0

# The fork currently tracks GIMP 3.3.x, which requires newer BABL/GEGL
# than the copies shipped with many Linux distributions.
git clone --depth 1 https://gitlab.gnome.org/GNOME/babl.git babl
meson setup babl/_build babl \
  --prefix="$GIMP_PREFIX" \
  -Drelocatable-bundle=yes -Dpkgconfig.relocatable=true
meson compile -C babl/_build --jobs 2
meson install -C babl/_build

git clone --depth 1 https://gitlab.gnome.org/GNOME/gegl.git gegl
meson setup gegl/_build gegl \
  --prefix="$GIMP_PREFIX" \
  -Drelocatable-bundle=yes -Dpkgconfig.relocatable=true
meson compile -C gegl/_build --jobs 2
meson install -C gegl/_build

# Keep test builds separate from the user's ordinary GIMP configuration.
meson setup _build-package \
  --prefix="$GIMP_PREFIX" \
  -Drelocatable-bundle=yes \
  -Dpkgconfig.relocatable=true \
  -Dgi-docgen=disabled \
  -Dcheck-update=no \
  -Dgimpdir=GIMPPhotoDev \
  -Dbuild-id=org.gimp.PhotoDev.CI
meson compile -C _build-package --jobs 2
meson install -C _build-package

if [[ "$FORMAT" == "appimage" ]]; then
  # Reuse the bundler maintained in this GIMP source tree.
  # It installs and packs the runtime plus plug-ins into AppDir.
  export GITLAB_CI=1
  sh build/linux/appimage/3_dist-gimp-goappimage.sh
  find build/linux/appimage/_Output -maxdepth 1 -name '*.AppImage' \
    -exec cp -v '{}' dist/ \;
  test -n "$(find dist -maxdepth 1 -name '*.AppImage' -print -quit)"
else
  bash ci/linux/make-deb.sh
fi

(cd dist && sha256sum -- * > SHA256SUMS)
ls -lh dist/
