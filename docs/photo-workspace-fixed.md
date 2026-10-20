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
- [ ] Live exposure and contrast controls
- [ ] Unified tool rail and photo thumbnail navigation
- [ ] Persistent photo-workspace preference
- [ ] Color/typography refinements and narrow-screen behavior tested
