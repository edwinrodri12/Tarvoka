# TARVOKA — primera prueba de estrés visual en Android

Fecha: 14 de noviembre de 2026 · Implementación QA de primera fase.

## Qué mide en una APK real

Abrir **PRUEBA DE RENDIMIENTO (QA)** en el menú lateral del juego. La pantalla crea un tablero **independiente**, sin sobrescribir la partida ni su guardado. Se ejecutan automáticamente cinco cargas, cada una con calentamiento inicial y muestreo de fotogramas. El botón **REPETIR PRUEBA** permite comparar teléfono frío/caliente. El botón **COPIAR INFORME** facilita compartir resultados. El JSON también se guarda en \`user://tarvoka_stress_report.json\` (almacenamiento privado de la aplicación).

Escenarios:

| Caso | Mapa | Carga | Clima | Efectos | Modo ahorro |
|---|---|---|---|---|---|
| HQ detallado | 24×18 | 24 tanques idénticos + CQ real en tablero | Despejado | 2 ataques visuales | No |
| Mapa completo | 40×30 | 60 tanques | Despejado | 0 | No |
| Lluvia y combate | 40×30 | 100 tanques | Lluvia | 8 | No |
| Nieve extrema | 40×30 | 150 tanques | Nieve | 16 | No |
| Nieve con ahorro | 40×30 | 150 tanques | Nieve | 16 | Sí |

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
