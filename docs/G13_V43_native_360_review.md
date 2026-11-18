# TARVOKA G13 — V43: captura real de inspección artística 360°

**Estado:** implementada la captura de vistas del modelo real mediante Godot 4.3 y GitHub Actions. **No se afirma que las capturas ya se hayan ejecutado, que el render haya sido aprobado ni que la publicación de Pages haya terminado.** En esta fase no se crean mallas nuevas.

## Objetivo y criterio de trabajo

En vez de sumar tornillos o chapas, verificar el diseño G13 V42 desde todos los ángulos, conservando los dos autocañones, el radar plegable, la distribución de las ocho facciones y las animaciones. Las capturas deben proceder de la escena real del Estudio TARVOKA; no son imágenes conceptuales.

## Implementación

- **Script:** `tests/test_g13_v43_visual_capture.gd`. Instancia `res://scenes/UnitArtStudioWeb.tscn`, selecciona el rol visual `aa_mobile`, comprueba que `tarvoka_g13_v42_fender_tip_continuity` está activo y captura imágenes reales a 1280 × 720 con `RenderingServer.frame_post_draw` / `Window.get_texture().get_image().save_png()`.
- **Ocho vistas LOD13:** frente (0°), delantero 3/4 (38°), costado izquierdo (90°), trasero 3/4 (145°), trasera (180°), costado derecho (270°), techo (42° yaw, −55° tilt), bajos (132° yaw, +58° tilt).
- **Comparación:** una imagen adicional de la versión V41 a 90°, usando el conmutador V42→V41 sobre la misma escena antes de restaurar la V42.
- **Dos vistas LOD8:** costado izquierdo y delantero 3/4. El modelo se reconstruye mediante el selector LOD táctico ya presente en el Estudio.
- **Archivos generados solo cuando el script se ejecuta:** `build/qa/g13-v43/g13-v43-*.png` y `g13-v43-manifest.json`. El manifiesto registra LOD, ángulos, dimensiones y posibles errores.

## Integración de publicación

El workflow `.github/workflows/tarvoka-3d-pages.yml` intenta las capturas en el trabajo existente de Godot/Xvfb **después de las comprobaciones básicas de navegación y antes de las barreras de inventario de animaciones**. Esta es una revisión artística: un fallo de captura se informa como advertencia y no sustituye ni relaja los bloqueos de publicación existentes. Un paso `if: always()` sube los archivos a un artefacto independiente llamado:

**`tarvoka-g13-v43-native-360-design`** (retención de 14 días).

Cuando el trabajo produzca el artefacto, se podrán revisar las imágenes en GitHub Actions y decidir correcciones. Hasta abrirlas no se debe afirmar que el diseño se ve bien o está listo.

## Visor compartido

`scripts/ui/BastionStudioAdapter.gd` muestra la G13 como fase V43 de revisión 360°, cambia los ocho botones de orientación a V43 y amplía las inclinaciones de techo/bajos para exponer mejor ambas superficies. **Las mallas que se muestran siguen siendo las de V42; V43 es una fase de inspección, no un sustituto de geometría.** El acceso al radar, cañones, clips de impacto y controles históricos permanece intacto.

## Próxima prioridad

Revisar el artefacto de imágenes cuando exista, detectar materialmente cualquier intersección, cara invertida o pieza flotante y corregir únicamente lo observado. Si las imágenes y el visor confirman el aspecto, solicitar aprobación artística del modelo completo antes de la integración jugable en TARVOKA. No confundir revisión artística con mediciones de FPS Android ni con la condición de unidad jugable.
