# Linux test packages (unofficial fork)

This branch adds a GitHub Actions proof-of-concept that compiles the **fork's
source code**, BABL, and GEGL, then generates Linux x86_64 test artifacts.

## Trigger a build

1. Open **Actions > Linux test packages** in this repository.
2. Choose **Run workflow** and select `ci/linux-test-packages` (until merged).
3. On success, open the workflow run, scroll to **Artifacts**, and download
   `gimp-photo-deb-x86_64` or `gimp-photo-appimage-x86_64`.
4. Artifacts expire after 14 days. SHA256SUMS is included.

Pushes to the specified source paths on `master` and `ci/**` and pull
requests touching those paths also build both test packages.

**Status:** Experimental pipeline. Until GitHub Actions reports success,
no package is guaranteed to exist or work.

## Supported platform

- Compiled inside a **Debian 13 (trixie) x86_64** container hosted by GitHub.
- The `.deb` is targeted at **Debian 13**, not all Debian/Ubuntu versions.
- The AppImage is meant to be more portable, but still requires validation
  on real Linux desktops.
- This is an **unofficial GIMP 3 development snapshot**, *not* a stable release
  and *not* yet the planned Lightroom-inspired interface.

## Running the outputs

AppImage:

```sh
chmod +x ./GIMP-*.AppImage
./GIMP-*.AppImage
```

Debian 13:

```sh
sudo apt install ./gimp-photo-dev_*.deb
gimp-photo-dev
```

The `.deb` installs the fork to `/opt/gimp-photo-dev`, with a separate launcher
`/usr/bin/gimp-photo-dev`, so it does not replace Debian's standard GIMP package.
The Meson option `-Dgimpdir=GIMPPhotoDev` is used to isolate its user
configuration. For now uninstall with `sudo apt remove gimp-photo-dev`.

## Technical approach

- `.github/workflows/linux-packages.yml`: independent `deb` and `appimage`
  jobs with artifact retention and basic smoke tests.
- `ci/linux/build-package.sh`: builds BABL, GEGL, and **this checkout**
  using Meson/Ninja.
- `ci/linux/make-deb.sh`: creates an experimental package with `dpkg-deb`.
- `ci/linux/smoke-test.sh`: tests package structure, checksums, installation,
  and `--version` when possible.
- AppImage creation reuses `build/linux/appimage/3_dist-gimp-goappimage.sh`
  from GIMP's source tree.

Compiling GIMP and both graphics engines from source is resource-intensive
and could expose upstream build-tool compatibility errors. Review the logs for
each job before distributing outputs. The first releases should be considered
developer previews only.

## Interface development: planned separate branch

The next branch should implement an **optional photographic workspace**
within `app/display/gimpimagewindow.c`, alongside GTK3 widgets inside
`app/widgets/`. First milestone: dark layout, center canvas, editing panel,
and working brightness/contrast controls backed by GIMP/GEGL. This CI
pipeline can then package that implementation for testing.

## Licensing

Retain GIMP's GPL licensing and license notices. Do not reuse proprietary
Adobe icons, logos, or distributable assets in the interface.
