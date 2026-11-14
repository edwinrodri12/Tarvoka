# TARVOKA — primera prueba de estrés visual en Android

Fecha: 14 de noviembre de 2026 · Implementación QA de primera fase.

## Qué mide en una APK real

En las compilaciones de pull request, el APK se identifica como **TARVOKA QA** y usa un identificador Android separado (`com.edwinrodri12.tarvoka.qa`), de modo que no obliga a desinstalar el juego habitual. Esta sustitución se hace solo en el runner de CI; el nombre/paquete oficial de `main` permanece intacto.

Abrir **PRUEBA DE RENDIMIENTO (QA)** en el menú lateral del juego. La pantalla crea un tablero **independiente**, sin sobrescribir la partida ni su guardado. Se ejecutan automáticamente cinco cargas, cada una con calentamiento inicial y muestreo de fotogramas. El botón **REPETIR PRUEBA** permite comparar teléfono frío/caliente. El botón **COPIAR INFORME** facilita compartir resultados. El JSON también se guarda en \`user://tarvoka_stress_report.json\` (almacenamiento privado de la aplicación).

Escenarios:

| Caso | Mapa | Carga | Clima | Efectos | Modo ahorro |
|---|---|---|---|---|---|
| HQ detallado | 24×18 | 24 tanques idénticos + CQ real en tablero | Despejado | 2 ataques visuales | No |
| Mapa completo | 40×30 | 60 tanques | Despejado | 0 | No |
| Lluvia y combate | 40×30 | 100 tanques | Lluvia | 8 | No |
| Nieve extrema | 40×30 | 150 tanques | Nieve | 16 | No |
| Nieve con ahorro | 40×30 | 150 tanques | Nieve | 16 | Sí |

## Extensión: requisito comercial de 8 jugadores (14-XI-2026)

La prueba incorpora cinco situaciones de estrés gráfico **con ocho colores oficiales simultáneos**. Este es un **prototipo aislado de presentación**, NO una batalla de ocho participantes:

| Carga adicional | Mapa | Participantes VISUALES | Tanques técnicos | Edificios representados | Ataques simulados | Clima |
|---|---|---:|---:|---:|---:|---|
| Avanzada | 40×30 | 8 | 160 (20/equipo) | 64 (8 HQ V15) | 8 | despejado |
| Grande | 40×30 | 8 | 320 (40/equipo) | 128 (8 HQ V15) | 16 | despejado |
| Masiva | 40×30 | 8 | 512 (64/equipo) | 192 (8 HQ V15) | 24 | lluvia |
| Extremo | 40×30 | 8 | 768 (96/equipo) | 256 (8 HQ V15) | 32 | nieve |
| Ahorro | 40×30 | 8 | 768 (96/equipo) | 256 (8 HQ V15) | 32 | nieve |

Los edificios incluyen las siluetas de los siete tipos ya disponibles en el renderer y ocho imágenes de HQ obtenidas del modelo 3D. Las unidades siguen usando el tanque **técnico** existente. Los edificios y tropas se distribuyen en posiciones distintas; las tropas pueden ocupar casillas de instalaciones porque esta es carga gráfica. La pantalla usa el motor de dibujo real, pero no controla economía ni turnos en ocho equipos. No modifica mapas guardados.

Se ha mejorado el culling previo a ordenar las unidades por profundidad: solo se ordenan los candidatos visibles y permitidos por la niebla. El informe contiene total de unidades en el mundo, unidades ordenadas, unidades dibujadas, edificios dibujados, percentil 95 y memoria reportada. Debemos observar esta métrica en zoom cercano para cuantificar el beneficio al crecer el mapa.

### Hitos todavía necesarios para ocho jugadores reales

1. **Modelo de partida:** separar identificador de jugador (0..7), alianza/equipo, facción visual y dueño táctico. El juego actual usa 0/1 y el balance no debe recibir ocho bandos mediante una modificación superficial.
2. **Motor de turnos:** orden de hasta ocho jugadores, desconexiones, rendición, victoria por equipo, IA para asientos desocupados, validación de órdenes del jugador activo, reconexión y guardados versionados sin romper v1.
3. **Visibilidad y privacidad:** niebla de guerra y memoria de exploración por asiento/equipo; el servidor jamás debe enviar información de enemigos ocultos al cliente, incluidos minimapa y repetición.
4. **Red autoritativa:** servidor/host que valide cada comando y mantenga estado y registro determinista; detección de desincronización, reintentos, reconexión, integridad de partidas y anti-trampas básicas. El escenario gráfico QA **no prueba la red**.
5. **Mapas mayores:** hoy solo se admiten 10×8, 24×18 y 40×30 (máximo 1200 casillas). Escalar a 64×48 u 80×60 exige probar generación, memoria, IA, rutas, zoom y guardados, con terreno por chunks y caché; NO ampliar simplemente \`MAX_AREA\` sin validar.
6. **Rendimiento Android:** sprites horneados del tanque y demás edificios finales, carga diferida y atlas, efectos limitados, recorte/caché de edificios, actualización de simulación por turno (no cada cuadro). Probar un dispositivo potente, medio y uno modesto con 30 minutos de carga repetida.

### Qué podemos y qué NO podemos concluir

- Concluir: que Godot puede **ejecutar los diez escenarios gráficos sintéticos sin errores** cuando CI está verde y que Android ofrece mediciones comparables cuando la APK se ejecuta en un móvil.
- No concluir: que ocho jugadores ya pueden conectarse o mover unidades; que el servidor soporta ocho conexiones; que 30/60 FPS Android están garantizados; que los modelos de arte 3D aún no incorporados tienen el mismo costo que los sprites técnicos.
- Meta propuesta: por lo menos **30 FPS estables** en teléfonos de gama media durante situaciones habituales, 60 FPS preferidos en gama alta; comparar p95 de cuadros y caídas con la escena extrema y opciones de calidad. No prometer límite fijo de tropas antes de los datos del teléfono.

Todo usa el **renderizador isométrico del juego**, el atlas de la unidad tanque actualmente en el proyecto, el terreno generado real y los PNG del HQ V15 horneados desde su modelo 3D. **El tanque final de TARVOKA Estudio 3D no está integrado en el APK en esta fase**; por tanto, esta prueba NO valida todavía el coste ni la animación definitiva del modelo 3D del tanque.

El benchmark fuerza un repintado de tablero **cada cuadro**, más exigente que la cadencia ambiental normal. Los combates y desplazamientos se agregan **solo como efectos visuales**, no como órdenes reales; no prueba IA ni rendimiento de rutas.

## Métricas y límites

Cada caso registra:
- FPS medio estimado a partir del tiempo entre cuadros completos;
- percentil 95 del tiempo entre cuadros (p95 ms), más útil que un máximo puntual;
- porcentaje de cuadros con más de 33.3 ms;
- máximo de memoria estática medido por Godot;
- unidades/casillas efectivamente dibujadas y si se mostró el HQ V15.

No es una captura de GPU time, memoria total del SO ni uso térmico. Para interpretar datos en un teléfono hay que comparar el FPS p95 con la temperatura percibida, brillo, batería, resolución y uso tras 15–30 minutos. Registrar al menos dos corridas con el mismo dispositivo y condiciones. Los FPS de GitHub Actions Linux NO son predicciones de FPS en Android.

## Objetivos de aceptación (a confirmar con dispositivos reales)

- Gama alta: objetivo preferido 60 FPS y p95 cerca de 16.7 ms en cargas habituales. Carga extrema admite una degradación controlada.
- Gama media: objetivo de 30 FPS estables, con p95 cerca de 33.3 ms en situaciones habituales.
- El modo ahorro debería mejorar estabilidad/consumo, pero el resultado debe verificarse con mediciones.
- Cero crasheos, arte invisible, filtraciones de niebla de guerra o corrupción de guardados.

## Validación automatizada

\`tests/test_android_visual_stress.gd\` ejecuta las cinco cargas con una duración breve para verificar imports, HQ, atlas, clima, VFX, métricas, salida JSON y aislamiento de la partida. \`.github/workflows/android-visual-stress.yml\` ejecuta smoke headless y escritorio virtual en Godot 4.3.

**No declarar rendimiento apto para lanzamiento sin resultados de Android real.** Después de incorporar el tanque definitivo y más edificios, repetir con sus sprites horneados reales y un escenario de duración prolongada; la repetición del tanque técnico sirve como primera línea base, no como certificado final.
