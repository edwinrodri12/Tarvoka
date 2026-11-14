# TARVOKA · Cuartel General V8 — materiales y uniones estructurales

**Base aprobada:** geometría V7, ocho escudos de facción originales, acabados V2–V4, sin cambios de reglas ni unidades.

## Materiales nuevos

`scripts/ui/HeadquartersFinishV8.gd` incorpora cuatro acabados PBR originales y uno de oxidación local:
- metal cepillado estructural, con rugosidad direccional y rayaduras finas
- azotea industrial, con juntas y desgaste discreto
- cristal de seguridad laminado con rugosidad de reflejo reducida
- hormigón arenado con microjuntas
- metal chamuscado / oxidación de calor para piezas rotas

Cada familia utiliza mapas de albedo, normales y rugosidad creados por código en Godot a 128×128 y **cacheados**. No se introduce arte de terceros. Los materiales de facción mantienen el color oficial; los ocho escudos aprobados se conservan sin intervención.

## Modelado adicional

- Uniones de expansión oscuras + cubrejuntas y placas de anclaje metálicas conectan alas y cuerpo central.
- Riostras de cubierta, drenajes técnicos y canaleta de puerta ayudan a distinguir elementos constructivos de bloques superpuestos.
- Tornillería fina instanciada y desgaste bajo aleros solo aparecen al acercar la cámara.
- Cuando está dañado, un cristal completo se oculta y es sustituido por triangulación irregular con un vacío real. También se añaden tapas de radar desprendidas, metal oxidado y canalones doblados.
- Cuando está destruido, solo se generan fragmentos metálicos chamuscados y piezas caídas, sin recrear el edificio intacto.

## Estudio 3D y comparador

En Edificios → Cuartel General, se carga **V8 por defecto** y se puede desactivar «Materiales PBR y daños V8 (comparar con V7)» para comprobar la misma cámara con el mismo nivel, facción y estado. La elección V1–V3 y el comparador V4/V7 se conservan; el modo mapa de 49 edificios permanece separado.

Prueba: `tests/test_headquarters_v8.gd` valida niveles 1–3, ocho facciones oficiales, materiales PBR reales, juntas, daños con huecos geométricos, detalle adaptativo, imágenes comparativas y regreso al tanque.

Capturas nativas: `tarvoka_hq_v7_vs_v8_pbr.png`, `tarvoka_hq_v8_pbr_closeup.png` y `tarvoka_hq_v8_fractured_glass.png`.

Exportadores GLB independientes:
- `TARVOKA_CuartelGeneral_V4_Nivel3_Editable.glb` — V4 sin capas posteriores
- `TARVOKA_CuartelGeneral_V7_Nivel3_Editable.glb` — V7 sin acabado V8
- `TARVOKA_CuartelGeneral_V8_Nivel3_Editable.glb` — V8 con materiales nuevos

## Publicación

La rama del Estudio 3D público estaba fijada a `feat/browser-3d-model-lab-20261113`, anterior a las versiones V4–V8. La publicación debe apuntar explícitamente a esta revisión después de superar el pipeline. No debe declararse publicado antes de verificar una ejecución **exitosa de deploy-pages** desde el workflow de publicación.

El ensamblaje sigue siendo un **prototipo de arte visual**: no cambia ocupación de casillas, capturas, defensa, selección de unidades, partidas, ni IA. Los FPS del visor no sustituyen mediciones Android.