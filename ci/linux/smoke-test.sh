#!/usr/bin/env bash
set -euo pipefail

FORMAT="${1:?usage: smoke-test.sh deb|appimage}"
cd "$(dirname "$0")/../.."

case "$FORMAT" in
  deb)
    shopt -s nullglob
    files=(dist/*.deb)
    (( ${#files[@]} == 1 )) || { echo "Expected exactly one .deb" >&2; exit 1; }
    dpkg-deb --info "${files[0]}"
    dpkg-deb --contents "${files[0]}" | grep -F /opt/gimp-photo-dev/bin/gimp-3.3
    # Installing in the throwaway CI container also validates declared Depends.
    apt-get install -y "${PWD}/${files[0]}"
    gimp-photo-dev --version
    ;;
  appimage)
    shopt -s nullglob
    files=(dist/*.AppImage)
    (( ${#files[@]} == 1 )) || { echo "Expected exactly one AppImage" >&2; exit 1; }
    file "${files[0]}"
    chmod +x "${files[0]}"
    APPIMAGE_EXTRACT_AND_RUN=1 "${files[0]}" --version
    ;;
  *)
    echo "Unsupported format $FORMAT" >&2
    exit 2
    ;;
esac
(cd dist && sha256sum -c SHA256SUMS)
