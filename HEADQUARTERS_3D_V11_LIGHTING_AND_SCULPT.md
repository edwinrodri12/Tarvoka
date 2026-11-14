# TARVOKA HQ V11 — Remates curvos e iluminación de validación

## Arte nuevo realmente esculpido

Sobre la V10, `scripts/ui/HeadquartersRefinementV11.gd` incorpora una curva extruida cerrada de **24 segmentos** con superficies frontales, traseras, inferiores y superiores, normales y UV para mapas PBR.

- Coronas redondeadas de hormigón fundido sobre ambas alas y finas bandas de facción acompañando su curvatura; conservan los escudos originales.
- Cornisa curva del puente de mando y junta inferior de caucho, sin tapar el emblema central.
- Marco de acceso redondeado, juntas elásticas y bisagras legibles.
- Cinco branquias de admisión HVAC por ala, perfiles de remate y tuberías de drenaje en codo y bajante.
- En **dañado**, se oculta la cornisa intacta y se reemplaza por dos fragmentos desiguales con acero y aislante expuesto. En **destruido** solo hay escombros curvos, no el edificio intacto.
- Remaches y abrazaderas cercanos apagados a distancia para WebGL/móvil.

## Estudio de iluminación

`CombinedArtStudioWeb.gd` permite probar **Día neutro / Atardecer cálido / Noche operativa**, sobre el mismo modelo y la misma cámara. Se ajustan la luz direccional, relleno, color ambiental y fondo; tres pequeñas luces de estudio sin sombras se habilitan solo en el modo nocturno del Cuartel General. Nunca se transmiten al juego ni a sus estadísticas, y al volver al tanque se recupera la iluminación neutra.

La V11 está activa por defecto y se puede desmarcar para comparar **V10/V11**. El usuario conserva el control de la cámara, los niveles 1–3, cuatro estados y las **ocho tarjetas de escudos oficiales por facción**.

## Comprobación obligatoria

`tests/test_headquarters_v11_lighting.gd` valida geometría curva real, los tres niveles y variantes de daño, mallas PBR, cámara y controles de luz bajo Godot, compatibilidad con ocho escudos oficiales, regreso a UNIDADES 3D y comparación V10/V11.

Capturas nativas:
- `tarvoka_hq_v10_vs_v11_curved_real_mesh.png`
- `tarvoka_hq_v11_day_godot.png`
- `tarvoka_hq_v11_sunset_godot.png`
- `tarvoka_hq_v11_night_godot.png`
- `tarvoka_hq_v11_curved_damage.png`

Blender: `TARVOKA_CuartelGeneral_V11_Nivel3_Editable.glb`. Los exportadores V4/V7/V8/V9/V10 quedan congelados en su versión correspondiente.

**Sin cambios** de mapas, balance, facciones, IA, controles de combate, guardados ni estadísticas. Publicar en la web solo después de Godot QA verde y `deploy-pages=success`.
