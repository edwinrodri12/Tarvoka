# TARVOKA · Cuartel General V9 — silueta táctica y ocho vistas por facción

## Trabajo 3D

Retomando el HQ V8 se añade `HeadquartersReadabilityV9.gd`, una capa de **volúmenes reales** visibles desde un encuadre de batalla: contrafuertes diagonales en la fachada, pilastras altas con color de facción, alerones exteriores, parapetos técnicos sobre ambas alas, dos aletas reforzadas en el puente de mando y terminaciones del patio. Las facciones mantienen sus **ocho escudos oficiales** y colores exactos; ninguna forma sustituye ni tapa el escudo central.

Niveles 1–3 compatibles; condiciones operativo, capturado, dañado (una aleta superior se desprende y aparece un refuerzo roto) y destruido (solo fragmentos reconocibles sin reconstrucción de volumen sano). Microdetalle exclusivo de zoom cercano desactivado por defecto.

## Vistas por facción reintegradas

En el Estudio 3D original existía únicamente un desplegable de facción compartido entre tanque y edificios. Se restaura la **visión directa de los ocho escudos** en una cuadrícula 2×4:

- Escudos recortados de los dos atlas WEBP **aprobados** (`HeadquartersEmblems3D.emblem_texture`), no iconos nuevos.
- Cada tarjeta selecciona la facción correcta tanto en UNIDADES 3D (aplica paleta) como en EDIFICIOS 3D (regenera el mismo HQ con escudo/color).
- La selección está sincronizada con el desplegable anterior; el nombre completo se muestra en el rótulo y el texto de ayuda de cada tarjeta.
- Al cambiar de unidad a edificio, y viceversa, **la facción seleccionada se conserva**.
- El visor sigue permitiendo giro 360°, zoom, tres niveles, cuatro estados y comparar V1–V9.

## Arte, pruebas y límites

`tests/test_headquarters_v9_faction_gallery.gd` comprueba el selector en ambas categorías, las ocho imágenes/texturas oficiales, las ocho escenas 3D del HQ, la silueta V9, los tres niveles, estado dañado/destruido, microdetalle y comparación V8/V9 desde la **misma cámara real de Godot**.

Artefactos en GitHub Actions:
- `tarvoka_hq_v9_eight_faction_views.png` — montaje 4×2 con el orden oficial de los ocho escudos
- `tarvoka_hq_v8_vs_v9_distance_architecture.png`
- `tarvoka_hq_v9_tactical_scale.png`
- `TARVOKA_CuartelGeneral_V9_Nivel3_Editable.glb` — modelo completo editable; conserva V4/V7/V8 como comparadores históricos separados

No hay cambios a las reglas del mapa, unidades, puntos de movimiento, ataque, facciones o IA. La versión se debe publicar **después** de pasar las pruebas Godot/Android y confirmar que GitHub Pages desplegó el SHA de la rama V9, no la V8 antigua.
