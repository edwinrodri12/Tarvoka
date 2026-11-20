# TARVOKA — Taller de Blindados V2: estrés Android dentro de partida 3D

## Alcance y diferencia esencial
El juego moderno existente tiene **dos** instalaciones reales `armor_plant` por partida, que utilizan Taller V2 y producen unidades sin alterar reglas. El script `tests/benchmark_armored_workshop_battle_android_v1.gd` abre `BattleSession.start(..., economy=true, modern=true)` y construye `BattleTerrain3D.build` con mapa y unidades reales. En escenarios sintéticos agrega exclusivamente nodos 3D decorativos (no entradas `economy.sites`) para probar densidades extremas de 8, 24 y 48 talleres. Ningún modelo adicional puede producir, capturar, reparar ni reabastecer.

## Corrección del motor
`ArmoredWorkshopBattleLOD.gd` reduce el ritmo de reconstrucción: **como máximo un taller 3D por paso**, a intervalos de 50 ms cuando hay transiciones pendientes; cuando termina, vuelve a revisar cada 250 ms. Se conserva la histéresis 112–152 px y el perfil Android TÁCTICO/DISTANTE. El método `refresh()` queda disponible para QA exhaustivo; la rutina normal `_process()` utiliza `update_budgeted()`.

## Pruebas y evidencias
Cuatro casos: `10x8_real_2`, `24x18_visual_8`, `24x18_visual_24` y `24x18_visual_48`. Cada caso hace zoom LEJOS → CERCA → LEJOS, comprueba posiciones, IDs de nodo, perfil gráfico, cantidad máxima de transiciones por paso y estado inmutable de economía y unidades. Se guarda una captura PNG real por caso y `manifest.json` con draw calls, tiempos CPU/GPU Mesa y tiempos de pasos de reconstrucción.

**No equivale a medir rendimiento en un dispositivo Android.** El entorno CI es Ubuntu 22.04, Godot 4.3 GL Compatibility y GPU Mesa por software a 960×540. Los tiempos Mesa no deben presentarse como FPS de un teléfono. Los valores de GPU en cero significan medición no disponible.

## Criterio pendiente en teléfono
Instalar APK de prueba en un Android real. Comparar zoom cercano/lejos con edificios propios y rivales descubiertos, alternar cinco veces, registrar FPS p50/p95, tirones máximos, temperatura y batería y comprobar que las fachadas, el color y las posiciones no desaparezcan. Mantener N1–N3 y D0–D4 como presentación visual; los edificios no tienen defensa armada ni función de suministro adicional.

**Estado:** modificaciones y QA de regresión en rama de desarrollo hasta que su ejecución termine satisfactoriamente; no afirmar validación física sin instalar en Android.
