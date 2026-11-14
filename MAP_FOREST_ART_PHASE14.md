# TARVOKA — Fase 14: siluetas de bosque y presupuesto de geometría 3D

## Alcance

Este cambio ocurre en la **vista 3D experimental** y no modifica reglas de
movimiento/combate, alcance, cobertura de bosque, niebla de guerra, unidades,
edificios, escenarios ni partidas guardadas. La vista isométrica 2.5D sigue
siendo el modo predeterminado.

## Bosques: tres perfiles de árbol original

- `scripts/ui/Conifer3DMesh.gd` genera tres perfiles:
  `PROFILE_SPRUCE` (alto y estrecho), `PROFILE_FIR` (ancho)
  y `PROFILE_YOUNG` (juvenil). Se agrupan ramas con ligeras
  irregularidades, textura tonal por vértice y pequeños brotes laterales
  en calidad completa.
- La calidad completa usa un material de follaje ligero con una oscilación
  de viento **solo visual**; calidad móvil usa un material opaco sin
  animación de hojas y menos vértices.
- `tools/terrain3d_lab.gd` genera tres `MultiMeshInstance3D` para todos
  los árboles visibles del mapa (uno por perfil), más un grupo para
  troncos y otro para sotobosque: **cinco agrupaciones de vegetación**.
  La cantidad de árboles de cada perfil es reproducible por mapa y no
  depende de cambios en el reloj.
- Las mallas de coronas, hierbas y troncos se mantienen en caché para
  evitar construir el mismo recurso con cada actualización de la niebla.
  Los arbustos adicionales en el límite del bosque se generan solo en
  algunos segmentos **de vecino terrestre explícitamente visible**;
  nunca invaden ríos, carreteras ni zonas ocultas.

## Métricas y rendimiento

- `environment_metrics()` expone triángulos por superficie, triángulos
  de vegetación, cantidad de árboles y arbustos, número de agrupaciones,
  calidad y duración CPU de reconstrucción en milisegundos.
- `tools/benchmark_forest3d.gd` exporta
  `forest3d-budget.json` en la misma galería que las imágenes de
  Godot para mapas sintéticos **10×8, 24×18 y 40×30**, con calidad
  completa y móvil. Verifica que la calidad móvil utiliza menos
  del **50 %** de triángulos de la completa y unos límites máximos
  para el mapa grande de prueba.
- `Battle3DView.runtime_metrics()` / 
  `TouchBoard.get_3d_performance_snapshot()` exponen además los FPS
  reales del motor Godot cuando se ejecuta una batalla 3D. Son
  diagnósticos de lectura voluntaria, no telemetría enviada a
  servidores ni datos incorporados al guardado.
- Las cifras de `build_ms` del artefacto provienen del entorno
  x86_64/Mesa en GitHub Actions. **NO equivalen a tiempos ni FPS en
  un Galaxy/Android real**: aún hace falta QA en hardware físico.

### Medición verificada del artefacto de esta fase

Con el mapa **sintético** de 40×30 generado por
`tools/benchmark_forest3d.gd`, en
[CI 43554365032](https://github.com/edwinrodri12/Tarvoka/actions/runs/43554365032),
se registró:

| Presupuesto | Calidad completa | Calidad móvil |
|---|---:|---:|
| Triángulos totales aproximados | 309 567 | 104 044 |
| Árboles | 1 575 | 907 |
| Arbustos | 1 446 | 724 |
| Reconstrucción CPU en runner Mesa | 4,75 s | 1,22 s |

El modo móvil utiliza aproximadamente un **66 % menos de triángulos**.
La reconstrucción de un mapa grande sigue siendo un coste importante,
incluso en el runner, y debe perfilarse en teléfonos físicos. El
benchmark no representa un FPS medido ni garantiza un rendimiento
comercial en Android.
- La medición inicial detectó coste innecesario en setos de borde;
  se redujo su densidad para no penalizar mapas de gran tamaño.
- La escena sigue siendo prototipo: estas siluetas y sombras no
  sustituyen al modelado 3D final de los elementos del juego.

## QA

Se ejecutan `tests/test_native_terrain3d.gd` (perfiles distintos, LOD,
posiciones estables y originales dentro del bosque, niebla, materiales
sin fugas), `tests/test_battle_3d_view.gd` (FPS/geométricas en lectura,
estado táctico y retorno a 2.5D inalterados) y el nuevo benchmark de
triángulos con capturas auténticas de Godot. El workflow
`.github/workflows/native-terrain3d-preview.yml` adjunta imágenes PNG
full/mobile, comparador de batalla y JSON de datos.

**Pendiente antes de considerar acabado comercial:** variantes de
hojas/madera con materiales finales, un mejor sistema de sombras y
vegetación que responda al viento, evaluación de ángulo isométrico
con unidades de producción y medición de FPS/memoria/temperatura en
al menos un Android real. La PR #183 debe permanecer en borrador
hasta resolver conflictos con `main`.
