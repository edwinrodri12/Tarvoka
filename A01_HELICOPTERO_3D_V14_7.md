# HAT-29 A01 — V14.7: acabado 3D y legibilidad de amortiguadores

## Prioridad de modelado
La revisión V14.6 fue publicada y probada. Sus cuerpos hidráulicos quedan parcialmente ocultos tras el perfil aerodinámico en determinadas cámaras. La V14.7 mejora **el modelo real**, no solamente la posición de la cámara.

## Nuevo acabado 3D nativo
Archivo: `scripts/ui/AttackHelicopterDamperFinishV147.gd`, instalado después de V14.6 para HAT-29 hero (art_level ≥13).

1. Mueve el grupo ORIGINAL de cada uno de los cuatro amortiguadores hacia el exterior **0.075 unidades**, levemente arriba (0.025). No duplica ninguna geometría ni mueve el eje del rotor; los pivotes existentes siguen siendo sus padres.
2. Conecta cada amortiguador expuesto a su pala mediante **dos horquillas tubulares** con anclajes reales, para evitar piezas aparentemente suspendidas.
3. Añade **dos collares metálicos mecanizados** y **dos tuercas** de sujeción a cada cilindro.
4. Modela **tres nervaduras de goma mate** en cada fuelle de polvo; da relieve 3D visible sin falsas líneas pintadas ni texturas superpuestas.
5. Aclara discretamente SOLO el acabado metálico del cilindro (acero gris desaturado) y conserva el material original para poder inspeccionarlo. No altera ni un tono de las ocho facciones.

La transmisión V3/V10/V14.5, la rotación de cuatro palas, las animaciones V13 de daños y destrucción, y el modo nocturno V14.4 mantienen el mismo rig y parámetros.

## Estudio 3D
En **Unidades → HAT-29 → Detalles**, dos nuevas vistas: **V14.7: cilindros hidráulicos** y **V14.7: fuelles y anclajes**. Se enfocan en piezas verdaderas del helicóptero existente. No hay un visor separado.

## Pruebas y publicación
- `tests/test_attack_helicopter_v14.gd`: ocho pinturas, cuatro horquillas y amortiguadores, doce nervaduras de goma, PBR metal/goma, instalación idempotente y exclusión del LOD10 Android.
- `tests/test_attack_helicopter_v9_studio.gd`: los dos botones muestran el modelo correcto sin cambiar de unidad ni dejar activa la cámara especial de mástil.
- `tests/test_attack_helicopter_v14_capture.gd`: **43 imágenes reales Godot** = 39 existentes + 4 nuevas macros (cilindro, fuelle, horquilla y rotor girando).
- `.github/workflows/tarvoka-3d-pages.yml` incluye el nuevo módulo en la exportación pública WebGL.

La revisión NO implica la aprobación definitiva del diseño 3D; busca hacer visible y coherente el siguiente nivel de detalle.
