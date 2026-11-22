#!/usr/bin/env bash
set -euo pipefail

PKG="com.edwinrodri12.tarvoka"
APK="build/TARVOKA-hq-v24-emulator-qa.apk"
OUT="artifacts/hq_v24_android_emulator"
mkdir -p "$OUT"
echo "Android device/AVD: $(adb shell getprop ro.product.model | tr -d '\r')"
echo "Android version: $(adb shell getprop ro.build.version.release | tr -d '\r')"
adb shell getprop ro.product.cpu.abilist | tee "$OUT/device_abis.txt"
test -s "$APK"
"$ANDROID_HOME/build-tools/34.0.0/apksigner" verify "$APK"
unzip -Z1 "$APK" | grep -Eq '^lib/x86_64/[^/]+\.so$'
adb install -r "$APK"
adb shell pm path "$PKG" | grep -F 'package:'
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 | tee "$OUT/launch.txt"

PASSED=0
for i in $(seq 1 150); do
  adb logcat -d -v brief > "$OUT/android-logcat.txt" 2>/dev/null || true
  if grep -Fq 'TARVOKA_ANDROID_HQ_EMULATOR_FAIL' "$OUT/android-logcat.txt"; then
    echo "Actual Android/Godot acceptance check failed:" >&2
    grep -F 'TARVOKA_ANDROID_HQ_EMULATOR_FAIL' "$OUT/android-logcat.txt" >&2
    exit 1
  fi
  if grep -Fq 'TARVOKA_ANDROID_HQ_EMULATOR_PASS' "$OUT/android-logcat.txt"; then
    PASSED=1
    break
  fi
  if (( i % 10 == 0 )); then
    echo "Waiting for actual Android render checks: $i/150"
    grep -F 'TARVOKA_ANDROID_HQ_EMULATOR_HEARTBEAT' "$OUT/android-logcat.txt" | tail -3 || true
  fi
  sleep 3
done
if [[ "$PASSED" != 1 ]]; then
  echo "Android APK did not finish the real HQ V24 3D acceptance scene." >&2
  grep -Ei 'godot|FATAL EXCEPTION|force finishing|crash|fatal' "$OUT/android-logcat.txt" | tail -90 >&2 || true
  exit 1
fi

# Godot user:// maps to the debuggable Android application's private files.
# Run-as reads ONLY the CI test process's data; no real user data is involved.
for name in \
  hq_v24_android_emulator_report.json \
  hq_v24_android_01_home.png \
  hq_v24_android_02_near.png \
  hq_v24_android_03_far.png \
  hq_v24_android_04_fps_hud.png
do
  adb exec-out run-as "$PKG" cat "files/$name" > "$OUT/$name"
  test -s "$OUT/$name"
done

python3 - <<'PY'
import json, pathlib, struct
out = pathlib.Path("artifacts/hq_v24_android_emulator")
r = json.loads((out / "hq_v24_android_emulator_report.json").read_text())
assert r["status"] == "PASS", r
assert r["runtime_os"] == "Android", r
assert r["real_android_phone_tested"] is False
assert r["real_command_HQ"] == 2 and r["hq_meshes"] == 6
assert r["hq_surfaces"] == 26
assert r["economy_and_game_state_unchanged"] is True
assert r["frame_samples"] >= 40
for filename in r["screenshots"]:
    raw = (out / filename).read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n', filename
    w, h = struct.unpack(">II", raw[16:24])
    assert w >= 320 and h >= 180, (filename,w,h)
    assert len(raw) > 5000, (filename,len(raw))
    print(f"Valid actual Android screenshot: {filename} {w}x{h} ({len(raw)} bytes)")
print("PASS ANDROID EMULATOR HQ V24 QA", json.dumps(r,ensure_ascii=False))
PY

grep -F 'TARVOKA_ANDROID_HQ_EMULATOR_PASS' "$OUT/android-logcat.txt"
echo "PASS HQ V24 real Android emulator: installed, booted, opened 3D, enabled FPS, near/far, screenshots, state unchanged"
