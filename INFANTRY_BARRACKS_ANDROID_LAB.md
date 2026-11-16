# TARVOKA — Cuartel de Infantería V5 · laboratorio Android

## Estado
Experimento de rendimiento y apariencia, **no una APK del juego comercial**.
Rama: `feat/infantry-barracks-android-device-lab-20261116`.
Escena de inicio aislada: `scenes/InfantryBarracksAndroidLab.tscn`.
Paquete Android aislado: `com.edwinrodri12.tarvoka.infantrylab`.

## Modelos que se inspeccionan
Mallas 3D reales del edificio V1, acabados V2, materiales V3, fachada posterior V4 y accesos/patio V5.
Tres arquitecturas N1/N2/N3, ocho facciones, cinco daños y 1/4/9 instancias separadas en una cuadrícula.
No se crean nuevos edificios jugables ni se modifican producción, capturas, balances, partidas o guardados.

## Procedimiento en Android
1. Descargar el artefacto `TARVOKA-Infantry-V5-Android-ARM64-Lab` de la ejecución exitosa del workflow `infantry-barracks-android-lab.yml` (no antes).
2. Instalar la APK del laboratorio, **sin desinstalar la aplicación TARVOKA**.
3. Abrir Nivel 3, 9 edificios, sin daño y facción 0.
4. Pulsar `Comparar A/B`. El laboratorio cambia automáticamente entre LOD cercano y lejano, con los mismos edificios, posición de cámara, facción y daño. Cada escenario calienta 45 fotogramas y mide 180.
5. Pulsar `Copiar datos` para obtener el historial JSON y `paired_ab_comparisons`, con diferencia porcentual de FPS y mallas ocultas. Repetir con 4 edificios y con Nivel 1.
6. Comparar `fps_mean`, `frame_p95_ms`, `draw_calls_mean`, `memory_static_bytes`, `mesh_stats.hidden_meshes` y `paired_ab_comparisons`, manteniendo condiciones del teléfono similares (temperatura, brillo, aplicaciones abiertas).

## Interpretación
`android_hardware_tested=true` solo cuando el proceso se ejecutó en Android real.
Las capturas y resultados de Godot en Linux verifican geometría y compilación, **no FPS reales de Android**.
Ocultar mallas reduce la geometría visible, pero la mejora de FPS solo se demuestra con datos del dispositivo.
La optimización de caché evita recorrer el árbol 3D repetidamente al recibir el mismo nivel de LOD.

## Criterios para integración posterior
- Godot 4.3 importa los scripts sin fallos;
- las capturas de comparación muestran N1/N2/N3 y daño 4 sin geometría reconstruida;
- el conteo de mallas visibles disminuye con LOD lejano y revierte al LOD cercano;
- se genera una APK arm64 firmada, verificable e instalable del laboratorio;
- se realizan pruebas de rendimiento en Android real, sin reclamar mejoras anticipadas;
- solo después se evalúa conectar el activo al mapa táctico o a la APK principal.
