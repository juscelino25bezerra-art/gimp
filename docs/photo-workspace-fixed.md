# Fixed photographic workspace

## Design goal

Provide a photo-focused editing experience inspired by the workflow of modern
desktop photo editors, while preserving GIMP's editing engine and the ability to
return to the native GIMP interface.

**Non-negotiable layout rule:** photographic panels are fixed containers, not
`GimpDock` or `GimpDockBook` objects. They cannot be detached, dragged,
reordered, or resized with dock handles.

## Layout contract

| Region | Behavior |
| --- | --- |
| Top | Permanent navigation and export area (future milestones) |
| Left | Fixed compact tool rail (future milestone) |
| Center | Existing `GimpDisplayShell` canvas; zoom and pan remain operational |
| Right | Fixed-width sidebar (initially 312 px), vertical scrolling only |
| Bottom | Optional, fixed-position photo strip (later milestone) |

Sidebar section order is fixed:

1. Light
2. Color
3. Effects
4. Detail
5. Optics

Sections can be expanded/collapsed but not reordered. The entire sidebar can
only be changed by explicitly switching back to standard GIMP mode.

For narrow windows, keep the center canvas visible; use vertical scrolling
inside the sidebar rather than allowing widgets to detach or float.

## Implementation notes

- `app/display/gimpimagewindow.c` owns the optional photo-mode toggle and
  static `GtkScrolledWindow` container.
- The original left/right `GimpDockColumns` stay alive behind the scenes,
  preserving traditional GIMP sessions and user customization.
- While photo mode is active, the standard dock columns remain hidden even if
  GIMP emits `notify::hide-docks` or related window-layout changes.
- New controls must bind to existing GIMP/GEGL filter configurations with
  live previews. Do not add misleading sliders that merely animate without
  changing the image.
- Avoid putting tool-option dialogs into separately floating windows. Their
  editing controls belong inside the right-hand sidebar as the feature matures.
- Preserve the underlying GIMP GPL license and avoid copying Adobe visual assets.

## Current status of this patch

This is an **initial, opt-in structural prototype only**, not a complete
Lightroom-style interface. It adds the working layout toggle and the permanent
right-hand sidebar with expandable sections. The placeholder text explicitly
notes that editing controls are not yet wired.

### Acceptance checklist

- [x] No draggable `GimpDock` widgets in photographic sidebar
- [x] No right-panel resize handle in photographic mode
- [x] Expander order fixed
- [x] Original GIMP docks can be restored by toggling back
- [ ] Tested on the actual built GTK3 application
- [x] Live exposure/contrast/shadows/highlights controls (pending CI and manual QA)
- [ ] Unified tool rail and photo thumbnail navigation
- [ ] Persistent photo-workspace preference
- [ ] Color/typography refinements and narrow-screen behavior tested

## Live Light controls — current experimental behavior

In the optional **Photo workspace** mode, the fixed right sidebar's **Light**
section offers Exposure (EV), Contrast, Highlights and Shadows.

- Select **one editable, unlocked, non-indexed layer** in an open image.
- Moving a slider attaches a GEGL filter to that layer and updates the canvas
  immediately. Contrast maps a -80..100 user-facing slider to the GEGL
  `brightness-contrast` scale factor 0.2..2.0. Exposure uses photographic
  stops (-5..5); highlights/shadows use GEGL's -100..100 scale.
- **Apply** confirms non-destructive layer filters, then resets the sliders.
  The changes remain in the image's filter stack and are included in the GIMP
  undo history.
- **Cancel** aborts the live filter preview and resets sliders.
- Switching images or leaving photo mode cancels an unconfirmed preview.
- If the selected layer changes before Apply, the old preview is cancelled
  instead of editing an unintended layer.

This initial interaction is **Apply/Cancel**, not Lightroom's persistent
per-photo slider settings; already-applied filters are edited from the GIMP
filter stack for now. This avoids pretending to support a parameter-persistent
photo develop engine before it exists.

### Manual acceptance tests (still required)

1. Open a JPEG/PNG with a single unlocked RGB layer.
2. Enable **Photo workspace**.
3. Move Exposure and verify preview changes without any floating dialog.
4. Move Contrast and Shadows/Highlights; verify the canvas reflects all effects.
5. Select Cancel; verify the image returns to its previous appearance.
6. Repeat, click Apply, then use Undo/Redo and verify filter removal/restore.
7. Switch tabs with a preview active; check the abandoned preview is cleared.
8. Ensure GIMP's conventional docks are restored on exiting Photo workspace.

Build success is not proof of these UI/runtime assertions.

## Photo-first layout (second UI milestone)

The fork now opens **Photo workspace by default**. Set
`GIMP_START_STANDARD=1` in the environment before launching the editor
to use the conventional interface at startup; users can switch at any
time with **Standard GIMP** / **Photo workspace**.

The photographic window now contains:
- A dark, dedicated top bar with native Open, Edit and Export actions.
- A fixed 82 px left tool rail with Open, Light, Fit and Save actions.
- The existing image canvas in the center.
- The fixed 312 px right panel and non-destructive Light sliders.

The traditional menubar is hidden **only** while Photo workspace is
active, and restored when switching back. Existing dock panes are
preserved in memory; nothing can be detached from the photo layout.

All toolbar/rail buttons call existing GIMP actions; they are not
decorative mockups. Light focuses the Exposure slider.

### Additional manual checks

- Launch the fork and verify Photo mode is initially active.
- Verify **Standard GIMP** restores the original menubar and both dock
  columns; re-enter Photo workspace and verify it hides docks again.
- Verify **Open**, **Export**, **Save**, **Fit**, and **Light** controls.
- Confirm that resizing the window does not detach either fixed panel.
- Test `GIMP_START_STANDARD=1` for developers.
- Test Gtk3 CSS in light and dark desktop themes and on HiDPI screens.
