# Android landscape configuration regression (2026-11-21)

Scope: independent Godot 4.3 headless contract for existing `project.godot` settings. No gameplay, art, Android export or user-facing layout changes.

Run after importing the project:

```sh
godot --headless --path . --audio-driver Dummy --script res://tests/test_android_landscape_contract.gd
```

Expected: exit code 0 and `PASS ANDROID LANDSCAPE CONTRACT`. The test validates six project settings (fixed landscape orientation, landscape logical viewport, expand aspect, canvas_items stretch, mobile GL compatibility and ETC2/ASTC compression). Six additional pure controls ensure that portrait/sensor orientation, portrait/square/zero-sized viewports are rejected and a different landscape resolution is accepted. No ProjectSettings values are modified by the controls.

## Evidence and limitations

- Previous head `ac29cbbf14f76e588fe6315f9f08517344198d7c`: landscape workflow **PASÓ** on [GitHub Actions run 44864143520](https://github.com/edwinrodri12/Tarvoka/actions/runs/44864143520); generic Godot rules and Android debug export also reported success for that commit.
- New negative controls in commit `adce0c6b79f827906d9e07b507896cfb132888b8`: **NO EJECUTADO** until its own CI result is inspected. The prior run does not validate this commit.
- Android physical: **NO EJECUTADO EN DISPOSITIVO**.
- HUD clipping, touch targets, safe areas and legibility: **PENDIENTE DE REVISIÓN VISUAL**.
- This does not measure FPS, battery, touch ergonomics, or prove an APK installs or upgrades safely.

CI: `.github/workflows/android-landscape-contract.yml` imports Godot 4.3, executes the regression, requires the PASS marker and publishes a diagnostic log. Review its next run and fix reproducible failures before merging. No APK distributed.

## 2026-11-21 — aspect ratio geometry regression

Added 13 pure checks in `tests/test_android_landscape_contract.gd`: for 16:9, 20:9, 4:3 and 21:9 physical landscape dimensions, compute the expected expanded logical canvas and assert that neither base logical dimension shrinks and that the resulting aspect matches the screen. A zero-width physical screen must return an invalid zero canvas. This tests the **mathematical contract only**, not actual Godot Control anchors, cutouts, safe areas, UI clipping or Android touch behavior.

Commit `9a04080dabb272117b83f7bd8ff0328f45ab9f0b`: **NO EJECUTADO** in Godot/CI at authoring time. Android physical: **NO EJECUTADO EN DISPOSITIVO**; visual HUD: **PENDIENTE DE REVISIÓN VISUAL**. Inspect the CI run for the new head SHA before declaring success. No gameplay rules changed.

## 2026-11-21 — GDScript parsing hotfix

Inspection of PR #649 head `7f9d43cd` found 16 literal `\\n` escape sequences embedded in source code outside strings, rather than physical line breaks, in the 13-check aspect simulation block and `_expanded_canvas` helper. This makes the test script syntactically invalid before the geometry assertions can run. Commit `02f63537befe90f7a43d5f9acf88028563d0e481` replaces those sequences with real newlines, preserving all test conditions and the project configuration. **Static source repair: PASÓ** (16 replacements); **Godot 4.3 execution: NO CONFIRMADO** until CI reports on the corrected head. **Android físico: NO EJECUTADO EN DISPOSITIVO**; **HUD visual: PENDIENTE DE REVISIÓN VISUAL**.

## 2026-11-21 — safe-area geometry regression

Commit `07c58f4c` adds six pure safe-area/HUD rectangle controls to `tests/test_android_landscape_contract.gd`: valid physical safe-area containment, an accepted HUD rectangle, left-cutout rejection, bottom-inset rejection, negative HUD dimensions and degenerate safe-area rejection. Coordinates are illustrative physical pixels, not measured from a device. No scene nodes, gameplay, export preset or rendering settings changed.

**Godot 4.3 CI: NO CONFIRMADO** for this head until its workflow run completes. **Android: NO EJECUTADO EN DISPOSITIVO**. **Real HUD anchors/cutouts: PENDIENTE DE REVISIÓN VISUAL**. Next independent increment: instantiate the actual HUD scene in a headless viewport and compare each interactive Control's global bounds against its viewport/safe-area, after identifying the authoritative HUD scene and avoiding parallel UI branches.

## 2026-11-21 — Godot 4.3 parse regression fixed

CI run [44883096497](https://github.com/edwinrodri12/Tarvoka/actions/runs/44883096497) on head `9dde39e2` **FALLÓ**: Godot 4.3 reports `Cannot find constant "ZERO" on base "Rect2"` at line 46. Replaced `Rect2.ZERO` with `Rect2()` in the degenerate-safe-area negative control. Commit `f417a3955da29886bba5266c06e76853e1aa26a2`; this is a source-level correction, **CI del nuevo commit NO CONFIRMADO** until run completes. Separate generic rules workflow run [44883096509](https://github.com/edwinrodri12/Tarvoka/actions/runs/44883096509) also failed in a V13 HQ sprite verification; that failure is not evidence about this landscape test and requires independent investigation. Android physical **NO EJECUTADO EN DISPOSITIVO**; HUD visual **PENDIENTE DE REVISIÓN VISUAL**.

## 2026-11-21 — projection from physical safe area to logical HUD canvas

Commit `9b5247ec` adds `_physical_safe_to_canvas()` to the existing regression script. Six pure checks validate projection of physical left/right insets, containment in the expanded logical viewport, and rejection of invalid physical rectangles, screens, or logical base sizes. The conversion uses the same uniform scale factor as the `expand` geometry test; it does **not** alter actual HUD layout, Android settings, or game rules.

Run: `godot --headless --path . --audio-driver Dummy --script res://tests/test_android_landscape_contract.gd`. Expected: `PASS ANDROID LANDSCAPE CONTRACT` and exit 0. **Godot/CI on this commit: NO CONFIRMADO** until a workflow result is inspected. **Android: NO EJECUTADO EN DISPOSITIVO**; **HUD real: PENDIENTE DE REVISIÓN VISUAL**. Next: inspect the actual HUD Control nodes and add a scene-instantiation regression without modifying parallel UI branches.


## 2026-11-21 — asymmetric inset regression

Added 15 pure geometry assertions across 1920×1080, 2400×1080 and 1600×1200 physical landscapes, with different left/right/top/bottom safe-area margins. Checks projected containment, both edges and physical-to-logical round trip. No real Control nodes or device insets are measured. Run `godot --headless --path . --script res://tests/test_android_landscape_contract.gd`; GitHub Actions outcome must be checked against the new head commit before marking PASS. Android: NO EJECUTADO EN DISPOSITIVO; HUD visual: PENDIENTE DE REVISIÓN VISUAL.

## 2026-11-21 — production HUD instance regression

New `tests/test_production_hud_bounds.gd` instantiates the actual `scenes/Main.tscn` and checks visible named HUD controls at logical 1280×720 and 1600×900. Missing controls, nonpositive rectangles and bounds outside the logical Main viewport fail. The landscape workflow runs this script independently and archives its log. This is a real scene/layout test, unlike earlier pure coordinate examples, but does not simulate physical cutouts, font legibility, taps or device scaling. Main may load an existing autosave in its normal `_ready`; CI should run in an isolated environment.

Source/CI wiring committed as `2a2f5ea0` and `f2018c81`. **Godot 4.3 CI: NO CONFIRMADO** for these commits until a completed run is inspected. **Android: NO EJECUTADO EN DISPOSITIVO**; **visual review: PENDIENTE**. If this test fails, inspect its named-control diagnostics before changing layout or weakening assertions. No APK delivered.

## 2026-11-21 — production HUD ultrawide and 4:3 regression

Commit `940a587f70bbba589e107c565197de81cbfef0a5` expands the existing instantiated production HUD bounds test from two 16:9 resolutions to four logical landscape sizes: 1280×720, 1600×900, 2400×1080 (20:9), and 1600×1200 (4:3). Each visible named Control must have a positive rectangle contained within Main's logical bounds. This deliberately changes tests only, not game UI or gameplay. The preceding head `877122ad2a6a8517c489e651a6e0f430d5f79256` passed four GitHub workflows including the landscape contract ([run 44907235767](https://github.com/edwinrodri12/Tarvoka/actions/runs/44907235767)); this does NOT validate the newly added aspect cases. **New head Godot CI: NO CONFIRMADO**. **Android: NO EJECUTADO EN DISPOSITIVO**. **Visual HUD: PENDIENTE DE REVISIÓN VISUAL**. Follow up on the new workflow; if the extreme ratios fail, inspect node-specific diagnostics and fix the underlying layout on a separately reviewed change. This test does not reproduce device cutouts or prove touch target sizing.

## 2026-11-21 — minimum visible action-button geometry

The production HUD instance test now checks that each visible `BaseButton` in its named action-control set has at least 24×24 logical pixels, alongside positive bounds and viewport containment. It also prints the count of visible named controls inspected per resolution; a zero count is diagnostic rather than a pass claim about hidden menus. This is a deliberately modest regression threshold, **not** an approved Android touch-target size or accessibility certification. Commit `caac12e9aaa1d037f1c5e864537fc10ca4459cf8`. **Godot 4.3 CI: NO CONFIRMADO** for this commit; **Android: NO EJECUTADO EN DISPOSITIVO**; **legibility/touch: PENDIENTE DE REVISIÓN VISUAL**. If a visible button fails, fix its layout only after checking its role and design constraints; do not loosen the test to conceal the issue.

## 2026-11-21 — non-vacuous HUD coverage and additional ratios

Commit `9bb4309c` extends the instantiated production HUD test to 2520×1080 (21:9) and 1440×960 (3:2). It now **fails** if a resolution inspects zero visible named controls or zero visible `BaseButton` controls; formerly an entirely hidden/missing-visible HUD could produce a misleading PASS. Logs include both counts. Existing bounds and 24×24 logical-button checks remain unchanged. This is a regression-only change; it does not force hidden menus visible or alter game layout. Run via `godot --headless --path . --script res://tests/test_production_hud_bounds.gd`. **CI for this commit: NOT YET CONFIRMED** at authoring. Prior head `da2c317f` passed landscape, rules, G11 and Android debug workflows (runs 44917219783, 44917219858, 44917219802, 44917219781), which do not validate the new cases. **Android physical: NO EJECUTADO EN DISPOSITIVO**; **visual: PENDIENTE DE REVISIÓN VISUAL**. Hidden HUD modes remain a separate test target.
