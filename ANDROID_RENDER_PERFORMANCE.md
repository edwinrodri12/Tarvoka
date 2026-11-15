# TARVOKA — optimización de mapas grandes en Android

Fecha: 12 noviembre de 2026. Rama `feat/mobile-large-map-performance-20261112` sobre la integración visual/táctica PR #148.

## Cambios aplicados

**Renderizado isométrico de 40×30**
- `VisualBudget.visible_grid_bounds` calcula un rectángulo conservador de casillas que pueden ocupar la pantalla, con márgenes generosos para edificios, unidades y efectos. El motor mantiene la profundidad de pintado sin recorrer todo el tablero cuando la cámara está ampliada o desplazada.
- Se calcula el origen de proyección solo una vez por cuadro; los centros y rombos de cada casilla se derivan directamente, eliminando cálculos repetidos.
- Las casillas bajo niebla *no exploradas* se pintan opacas **sin dibujar primero vegetación, agua o relieve oculto**, preservando privacidad y reduciendo trabajo gráfico.
- Los edificios, unidades, rutas y zonas de ataque fuera de pantalla se omiten. La lógica y la visibilidad real del juego no cambian.
- El nivel de detalle se adapta automáticamente al tamaño en píxeles de las casillas. Con poco zoom, las unidades se representan mediante marcadores contrastados y legibles; al acercar, vuelven las 128 figuras del atlas. A gran escala, los modelos de terreno decorativo se simplifican antes que las acciones o posiciones.
- `IsoRenderer.last_frame_stats` informa cantidad de casillas candidatas/pintadas, detalles decorativos y tropas en pantalla, para diagnosticar costo de dibujo sin alterar el estado táctico.

**Minimapa**
- El terreno conocido se convierte en una imagen miniatura transparente/coloreada de 10×8, 24×18 o 40×30. La textura se crea **solo cuando cambia el estado**, no cada vez que se arrastra la cámara.
- En cada desplazamiento solo se vuelve a dibujar la textura existente, las unidades e instalaciones visibles y el contorno de la cámara.
- La textura usa filtro de píxel más cercano para conservar las separaciones de casilla cuando se amplía.
- `BattleMinimap.cache_rebuild_count` y `cache_reuse_count` permiten comprobar las actualizaciones. La firma de estado se calcula a partir del dato real, no de un contador de acciones; así un estado restaurado o modificado externamente invalida el caché.
- La textura **jamás** representa posiciones de enemigos invisibles, propietarios no revelados o geografía no explorada. Los marcadores quedan filtrados por `Visibility`.

**Animaciones y batería**
- En mapas pequeños, animaciones ambientales cada 0.12 s; mapas medianos cada 0.20 s; mapas de ≥800 casillas cada 0.30 s.
- Botón **Ahorro de batería**, opcional y reversible, extiende la animación ambiental a 0.50 s y reduce la decoración. El combate y los desplazamientos mantienen su interpolación independiente de 0.32/0.55 s.
- El modo de ahorro y la posición de cámara no se incorporan a los guardados ni cambian ninguna regla.

## Verificación

`tests/test_mobile_visual_performance.gd` comprueba:
1. Que el recorte de pantalla jamás descarte un centro de casilla visible para varios tamaños, escalas y desplazamientos.
2. Que 40×30 simplifica decoración y reduce el número de casillas candidatas al ampliar/desplazar.
3. Que los enemigos desconocidos siguen ocultos y el renderizador no altera el estado.
4. Que el minimapa **reutiliza** su textura durante los movimientos de cámara, pero la reconstruye al cambiar los HP.
5. Que el modo ahorro reduce actualizaciones ambientales sin cambiar reglas ni guardados.
6. Que los controles Android activan/desactivan el modo sin modificar la partida.
7. Una observación de tiempo de dibujo en Godot headless registrada en el log CI; **no es una medición de FPS de móvil**.

## Restricciones

La optimización es independiente de la PR #148 y se mantiene experimental. La compilación Android y la suite de Godot deben estar verdes, pero el rendimiento real **todavía requiere pruebas en un teléfono** a 10×8/24×18/40×30, con y sin niebla, con número realista de unidades y tras 15–30 min de juego. No se declara FPS fijo, consumo de batería ni temperatura hasta hacer esas mediciones.

No se modifica balance, 32 roles, doctrinas de contraataque, alcance, IA, economía, visibilidad, formato de guardado ni identidad de las ocho facciones.


## Protocolo experimental: ocho facciones y APC P06 V3 (14 noviembre 2026)

La rama del PR #330 añade un **segundo instalador independiente** llamado
`TARVOKA-Estudio3D-Android-FPS-benchmark-arm64` a los artefactos del flujo
`.github/workflows/android-debug-apk.yml`. Usa una aplicación Android
distinta (`com.edwinrodri12.tarvoka.studio`) y abre el Estudio 3D Godot
directamente; no sustituye los datos ni la APK jugable TARVOKA.

**Uso en un teléfono Android ARM64**:

1. Descargar el artefacto del último workflow Android **aprobado**, extraer
   `TARVOKA-Estudio3D-benchmark.apk` e instalarlo como aplicación aparte.
   Una APK del PR usa una firma de depuración temporal: si una actualización
   no se instala encima, desinstalar solo la aplicación Estudio 3D anterior.
2. Elegir el APC P06 V3 y activar `32 vehículos`. Tomar una muestra estable
   de 60 segundos en detalle completo; pulsar
   `GUARDAR / COPIAR INFORME FPS`. Guardar el JSON copiado.
3. Cambiar a `LOD TÁCTICO`; repetir 60 segundos y conservar otro informe.
   Repetir con 64 APC; luego activar `BATALLA MIXTA` para incluir
   ocho tanques G09 y ocho Cuarteles Generales y repetir ambos detalles.
4. Repetir cada escenario tres veces. Anotar modelo de teléfono, versión
   Android, frecuencia de pantalla, estado de batería, temperatura
   ambiental y cualquier degradación visible tras 15–30 minutos.
5. Comparar preferentemente **p10 FPS, media FPS, fracción de muestras de
   al menos 30 FPS, draw calls y memoria estática del motor**. La
   `Performance.MEMORY_STATIC` no mide toda la memoria del teléfono ni su
   temperatura. No confundir los FPS de WebGL o Mesa/llvmpipe con los nativos.
   El archivo JSON también queda bajo `user://` de la aplicación.

**Criterios provisionales de aceptación para perfilar, no promesas:**
p10 FPS ≥30 durante una sesión estable de 60 s en un teléfono Android
de referencia identificado, sin cierres ni progresión anormal de memoria;
probar un equipo Android menos potente antes de fijar los requisitos
comerciales. Si un escenario no alcanza esa meta, conservar el informe
y priorizar LOD adicional, menos efectos o reducción de capturas.

**Optimización de memoria incorporada**: el renderizador del tablero
`UnitRender3D` ahora prepara las 22 capturas estáticas (ocho G09,
ocho P06 y seis clases restantes) en grupos de un máximo de cuatro
`SubViewport` temporales. Tras cada captura libera el modelo y
preserva solamente `ImageTexture`; la batalla utiliza las imágenes
precapturadas y no mantiene 22 cámaras actualizándose.

Las pruebas de laboratorio con 48 y 80 modelos reales de Godot son
**visuales**: no verifican red, latencia de ocho clientes, IA por turno,
mapas completos ni consumo térmico del teléfono. La aprobación de QA/CI
no equivale a aprobación física.


## Autotest V2: comparación Android sin cambiar ajustes manualmente

En el **Estudio 3D para Android** seleccionar el botón
`ANDROID · AUTOTEST 6 FASES (≈7 MIN)`. El visor cambia automáticamente
entre seis escenarios idénticos en colocación y daño, con **6 segundos
de calentamiento** y **60 segundos de medición** para cada fase:

| Fase | Escenario | Calidad |
|---|---|---|
| 1 | 32 APC P06, ocho facciones | Completa |
| 2 | 32 APC P06, ocho facciones | LOD táctico |
| 3 | 64 APC P06, ocho facciones | Completa |
| 4 | 64 APC P06, ocho facciones | LOD táctico |
| 5 | 64 APC, 8 tanques G09 y 8 HQ V3 | Completa |
| 6 | 64 APC, 8 tanques G09 y 8 HQ V3 | LOD táctico |

Al terminar, queda un archivo local
`user://tarvoka_android_suite_v2_*.json` con las seis mediciones
independientes. Pulsar **GUARDAR / COPIAR INFORME FPS** para copiar el
JSON completo y compartirlo en el chat. Si se pulsa **DETENER AUTOTEST**,
se guarda un resultado parcial marcado `cancelled=true`; no debe
interpretarse como una prueba terminada. El botón también se puede
usar en el navegador, pero sus datos no se deben etiquetar como Android.

En cada fase se muestrean FPS, percentil inferior p10, porcentaje de
muestras que superaron 30 FPS, llamadas de dibujo y memoria estática
del motor. El protocolo no conoce el estado térmico real de Android ni
recolecta identificadores personales del teléfono. Su resultado es
evidencia de capacidad gráfica del laboratorio, no un ensayo completo
de IA, red, multijugador u optimización de mapas.

**Control de calidad:** `tests/test_android_benchmark_suite_v2.gd`
revisa las seis fases, el calentamiento, el informe y la cancelación.
`tests/test_apc_p06_studio_stress.gd` comprueba además que el botón
inicia la escena correcta, cambia automáticamente el LOD, guarda un
informe parcial y libera la escena al detenerse.

La meta provisional para los primeros teléfonos de referencia es
`p10 >= 30 FPS` en cada escenario de un minuto. Se necesitan varias
repeticiones y pruebas de mayor duración antes de fijar un requisito
mínimo comercial. No atribuir FPS de hardware a CI Mesa/llvmpipe.
