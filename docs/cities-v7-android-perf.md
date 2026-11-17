# TARVOKA · Ciudades 3D V7: prueba de rendimiento Android

## Qué ha cambiado
- Las ciudades siguen utilizando la geometría aprobada V1–V4 y el selector V6.
- La batalla 3D inicializa la cámara con el encuadre del mapa ANTES de dibujar, evitando un salto inesperado al máximo detalle.
- En tiempo real, el selector de detalle reparte las reconstrucciones: como máximo una ciudad por paso de 50 ms cuando hay cambios pendientes. Las pruebas puras siguen usando `update_now()` para inspeccionar todos los niveles.
- En el HUD de **batalla 3D** hay un botón opcional **FPS**. Muestra lecturas locales: FPS del motor en ese dispositivo, número de ciudades por LOD, mallas y el mayor tiempo de reconstrucción observado. No se recopilan conversaciones, ubicaciones ni datos externos. No se modifica la partida.

## Prueba manual en un teléfono real
1. Instalar la APK debug arm64 generada para la PR V7. **Importante:** las APK de prueba se firman con claves temporales y pueden no actualizarse encima de otra compilación. Respaldar partidas antes de cualquier desinstalación.
2. Iniciar una escaramuza con economía/ciudades y entrar en la batalla 3D.
3. Pulsar **FPS** en la esquina superior derecha. Esperar diez segundos sin mover la cámara y anotar el valor aproximado de FPS, el número de ciudades y las mallas.
4. Hacer zoom de lejos a cerca, detenerse diez segundos y registrar lo mismo. Alejar de nuevo. Repetir tres veces, con el ahorro de batería tanto desactivado como activado si se desea comparar.
5. Repetir en mapas 10×8, 24×18 y 40×30, si están disponibles. Registrar modelo de teléfono, modo de energía y si hay calor o interrupciones visibles. Una captura de pantalla de cada situación permite comparar cifras sin exportar datos privados.
6. Comprobar que no cambian ciudades de propietario, recursos, unidades ni reglas al activar FPS o hacer zoom.

| Tamaño | Vista | FPS medio en dispositivo | FPS mínimo observado | Mallas | Pico paso LOD (ms) |
| --- | --- | --- | --- | --- | --- |
| 10×8 | Lejos | Por medir | Por medir | Por medir | Por medir |
| 10×8 | Cerca | Por medir | Por medir | Por medir | Por medir |
| 24×18 | Lejos | Por medir | Por medir | Por medir | Por medir |
| 24×18 | Cerca | Por medir | Por medir | Por medir | Por medir |
| 40×30 | Lejos | Por medir | Por medir | Por medir | Por medir |
| 40×30 | Cerca | Por medir | Por medir | Por medir | Por medir |

## Baseline automatizado
`tests/benchmark_city_v7_zoom.gd` genera `artifacts/tarvoka_city_v7_zoom_mesa.json` y dos capturas PNG al ejecutar Godot 4.3 con OpenGL de software en Linux. Es una prueba reproducible de número de mallas, latencia y alternancia LOD; **no** es una medición de FPS de un teléfono Android.

La prueba 24×18 con diez ciudades es un escenario de estrés sintético y no modifica la densidad normal del juego. La documentación y las capturas del workflow están disponibles como artefactos del PR.
