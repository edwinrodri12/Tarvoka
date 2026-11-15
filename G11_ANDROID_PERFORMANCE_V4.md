# TARVOKA — G11 Android / ocho jugadores: rendimiento y LOD V4

**Fecha:** 15 de noviembre de 2026. **Estado:** LOD tácticos 8/10 implementados y validados; prueba cuantitativa de referencia terminada en Mesa GL/Linux; laboratorio Android creado para medir dispositivos físicos. No se deben presentar cifras Mesa como FPS del móvil.

## Arquitectura sin alterar reglas

- `scripts/ui/G11MobileLOD.gd` implementa dos modelos nativos 3D de bajo coste. LOD 10 (cerca): doce tubos, doce ruedas y doce aros agrupados mediante tres `MultiMeshInstance3D`, además de la carrocería. LOD 8 (lejos o mucha densidad): doce tubos agrupados, sin pequeñas piezas de rueda o aros individuales. Se mantienen las ocho facciones y la silueta del lanzador.
- `scripts/ui/UnitModels3D.gd` construye estos LOD para batallas (`art_level < 13`) y mantiene el G11 V3 completo exclusivamente en Estudio 3D (`art_level >= 13`). El rol y las estadísticas no cambian.
- `G11MobileLOD.recommended_level(distance,visible_units,high_quality)` permite seleccionar el LOD a partir de densidad y distancia. **Esta función no se ha conectado aún a un cambio automático del nivel durante la partida**; los creadores del mapa deben pasar el LOD adecuado a `Models.build(...)`.
- El render de los doce tubos se mantiene en un lote por vehículo, en lugar de doce mallas separadas. El giro y la elevación se mantienen como pose decorativa reversible.

## Mediciones de referencia Godot 4.3

Fuente verificada: [GitHub Actions G11 benchmark](https://github.com/edwinrodri12/Tarvoka/actions/runs/43692291257), `tests/benchmark_g11_mobile_stress.gd` y artifact `tarvoka-g11-mobile-gl-stress`.

| Unidades G11 | LOD | FPS promedio aproximado | Milisegundos por fotograma | Llamadas de dibujo |
|---:|---:|---:|---:|---:|
| 8 | 13 (hero) | 15.7 | 63.56 | 1421.6 |
| 8 | 10 | 91 | 10.99 | 144 |
| 8 | 8 | 169.4 | 5.90 | 128 |
| 32 | 10 | 29 | 34.53 | 576 |
| 32 | 8 | 71.7 | 13.95 | 512 |
| 64 | 10 | 17.4 | 57.61 | 1152 |
| 64 | 8 | 39.9 | 25.08 | 1024 |

Método: renderizado **por software Mesa en Ubuntu con Xvfb**, vista 720×405 y 18 fotogramas medidos en cada escenario tras calentamiento. Estos números **no representan FPS de Android ni FPS estables de una partida completa**. Al reducir 64 G11 de LOD 10 a LOD 8, el tiempo medio bajó ~56.5 %. La prueba no incluye otros vehículos, terreno, IA, iluminación compleja ni sincronización online. Todas las pruebas de geometría/animación pasaron.

## Laboratorio táctil para Android

Escena: `scenes/G11AndroidStressLab.tscn`; controlador: `scripts/ui/G11AndroidPerfLab.gd`. La interfaz muestra modelos reales en paisaje y botones para alternar **8 / 32 / 64 unidades** y **LOD cercano / lejano**. Después de 45 fotogramas de calentamiento registra 180 fotogramas, FPS promedio, milisegundos promedio, draw calls y memoria estática. Los resultados se guardan automáticamente en `user://g11_android_performance.json` y el botón **Copiar** los coloca en el portapapeles para pegarlos en ChatGPT.

La tarea `.github/workflows/g11-android-stress-apk.yml` produce un APK ARM64 con paquete separado `com.edwinrodri12.tarvoka.g11lab`. **No reemplaza TARVOKA normal**. Se distribuye en Artifacts del workflow [TARVOKA G11 Android stress lab APK](https://github.com/edwinrodri12/Tarvoka/actions/workflows/g11-android-stress-apk.yml). Es una APK de diagnóstico y no un producto de publicación. Una firma debug efímera puede exigir desinstalar la versión anterior del laboratorio antes de instalar otra, pero no afecta al juego normal.

## Criterios pendientes para ocho jugadores

1. Ejecutar el laboratorio en varios dispositivos Android y registrar FPS de 8/32/64 unidades con LOD 8 y 10, especialmente caída térmica después de varios minutos. El CI no puede simular una GPU Adreno/Mali real.
2. Crear un escenario de batalla mixta con hasta ocho facciones (unidades terrestres, aéreas, navales, edificios, biomas, lluvia/nieve, efectos y UI) y registrar p95 de tiempos de fotograma y RAM real.
3. Integrar LOD automático con histéresis para evitar alternancia constante, sin modificar estadísticas, rangos o visibilidad del enemigo.
4. Validar la instalación APK de laboratorio y la recepción de datos del botón Copiar en un teléfono real; los tests de escena en Godot no sustituyen esa validación.
