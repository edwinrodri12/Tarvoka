#!/usr/bin/env bash
# TARVOKA: non-destructive Android evidence capture. No install, data clearing or permissions.
set -euo pipefail
PACKAGE="com.edwinrodri12.tarvoka"
OUT="${1:-android-smoke-evidence}"
if ! command -v adb >/dev/null 2>&1; then echo 'NO EJECUTADO EN DISPOSITIVO: adb no disponible' >&2; exit 2; fi
mapfile -t DEVICES < <(adb devices | awk 'NR>1 && $2=="device" {print $1}')
if (( ${#DEVICES[@]} != 1 )); then echo "NO EJECUTADO EN DISPOSITIVO: se requiere exactamente 1 dispositivo autorizado (encontrados ${#DEVICES[@]})" >&2; exit 2; fi
SERIAL="${DEVICES[0]}"
ADB=(adb -s "$SERIAL")
if ! "${ADB[@]}" shell pm path "$PACKAGE" | grep -q '^package:'; then echo "NO EJECUTADO EN DISPOSITIVO: $PACKAGE no instalado" >&2; exit 2; fi
mkdir -p "$OUT"
printf 'package=%s\nserial=%s\n' "$PACKAGE" "$SERIAL" > "$OUT/manifest.txt"
"${ADB[@]}" shell getprop ro.build.version.release >> "$OUT/manifest.txt"
"${ADB[@]}" shell wm size > "$OUT/display.txt"
"${ADB[@]}" shell wm density >> "$OUT/display.txt"
"${ADB[@]}" shell dumpsys input | grep -m 1 -E 'SurfaceOrientation|orientation=' >> "$OUT/display.txt" || true
"${ADB[@]}" shell dumpsys package "$PACKAGE" > "$OUT/package.txt"
"${ADB[@]}" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 > "$OUT/launch.txt"
sleep 3
"${ADB[@]}" exec-out screencap -p > "$OUT/launch.png"
"${ADB[@]}" shell dumpsys activity activities > "$OUT/activity.txt"
"${ADB[@]}" logcat -d -t 400 -v time > "$OUT/logcat-last400.txt"
if [[ ! -s "$OUT/launch.png" ]]; then echo 'FALLÓ: captura vacía' >&2; exit 1; fi
echo "PASÓ: evidencia recopilada en $OUT. NO implica validación de jugabilidad, FPS, guardados ni orientación visual."
