# TARVOKA Base Aérea V5 — medición Android mixta

## Estado de esta entrega

Esta rama conserva **Base Aérea V4** (hangar, pista corregida, ocho facciones, daño, humo/fuego suave y LOD auténtico), y agrega una escena nueva e **independiente**: `scenes/AirbaseAndroidBenchV5.tscn`. **No altera el juego comercial, los turnos, el HP, la economía ni las reglas de producción aérea.**

La V4 comprobó complejidad y render en escritorio con 8/32/64 bases, pero no su rendimiento en teléfonos. La V5 sirve para conseguir medidas **reales del teléfono**, usando recursos 3D ya disponibles.

## Cómo se carga la prueba

La acción `.github/workflows/airbase-v5-android-bench.yml`:
1. Compila y prueba la escena en Godot 4.3/OpenGL, sin presentar los FPS de escritorio como Android.
2. Exporta un **APK de laboratorio** para **ARM64**, con package independiente `com.edwinrodri12.tarvoka.airbasebench`; así no sobrescribe TARVOKA.
3. Publica un artefacto `TARVOKA-Airbase-V5-Android-Mixed-Load-arm64` en GitHub Actions, disponible al completar correctamente el workflow. La firma debug es temporal: nuevas compilaciones podrían requerir desinstalar esta app de pruebas.

En el APK, selecciona cada nivel de carga, alterna clima y cámara, y toca **MEDIR 15 SEGUNDOS**. Es aconsejable medir cada combinación tres veces, sin otras aplicaciones en primer plano, y registrar modelo de teléfono y nivel térmico.

| Nivel | Bases aéreas | Bases detalladas | Bases LOD | Unidades 3D cercanas | Unidades LOD |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bajo | 8 | 4 | 4 | 12 | 4 |
| Medio | 32 | 4 | 28 | 12 | 52 |
| Alto | 64 | 4 | 60 | 12 | 116 |

Las unidades cercanas proceden del catálogo nativo `TarvokaUnitModels3D` (tanque, APC, caza, helicóptero, infantería y MLRS). Las lejanas usan una geometría simplificada deliberadamente. Las ocho facciones están representadas. El clima alterna despejado, lluvia y nieve mediante partículas de una sola fuente global; el daño visible de algunas bases habilita humo/fuego V4 con calidad móvil.

El panel muestra **FPS, media de tiempo de fotograma y p95**; el botón **Copiar última medición** copia la fila CSV y se guarda también en `user://airbase_v5_results.csv`. Una línea `TARVOKA_AIRBASE_V5_DEVICE_SAMPLE` se imprime por medición para recuperación de registros.

## Qué todavía NO demuestra

- No es una partida ni ejecuta la IA, órdenes, economía, niebla o turnos de ocho jugadores.
- El nivel alto con 64 bases **no equivale a 64 edificios completos**: 60 están renderizados en LOD. Tampoco equivale a cientos de unidades de máxima calidad.
- La escena permite recoger métricas físicas cuando la instales y la ejecutes en Android. La aprobación del workflow, el build de APK y los FPS de CI **no prueban por sí mismos** rendimiento en teléfono.
- Los FPS son intervalos de fotograma observados por el motor; **no** son tiempo de GPU aislado. El resultado depende de hardware, temperatura, controlador, resolución y pantalla.

## Criterio siguiente

Comparar en un teléfono real los escenarios alto/medio/bajo con clima despejado, lluvia y nieve. Luego, con esos datos, integrar el modelo de Base Aérea en las **partidas reales** (HP y economía solo después de diseñar las reglas autoritativas). Para objetivo multijugador de hasta ocho participantes se requiere una prueba final separada con IA/turnos/unidades/edificios y consumo de memoria, además de FPS.
