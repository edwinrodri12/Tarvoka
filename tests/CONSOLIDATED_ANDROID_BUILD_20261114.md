# TARVOKA · Consolidated Android test snapshot — 2026-11-14

Base: main commit `e95260b10e6f1be29c1358ff7f250702886c4c45` (frozen snapshot).

Purpose: trigger the existing `.github/workflows/android-debug-apk.yml` pull-request validation to produce a downloadable Android ARM64 debug APK for user testing of ALL updates already merged in main at this snapshot, without changing gameplay or silently merging open draft PRs.

Scope: exactly the executable game from the base main commit. This document is the sole source-tree addition and has no runtime effect.

**Not bundled:** ongoing unmerged/draft PRs (tank G09 V22, HQ variants, terrain/3D battle art), which have independent review gates and overlapping branches. Do not claim that an Android APK includes unmerged changes merely because their separate CI succeeded.

Acceptance: Android workflow SUCCESS, APK ZIP uploaded, arm64-v8a library and apksigner verification passed. Device install/gameplay and update-in-place remain NOT EXECUTED until physically checked.

Signing: PR builds use ephemeral debug identity. If uninstalling an earlier APK becomes necessary, local user:// save data may be deleted. Back up game progress before installation.

This branch is a delivery/build marker, **not a request to merge documentation into main**.
