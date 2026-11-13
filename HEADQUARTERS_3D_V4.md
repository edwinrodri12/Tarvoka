# TARVOKA — Cuartel General V4: reconstrucción de la silueta (2026-11-13)

## Referencia y decisión
La ilustración oficial «Infografía del Cuartel General de Tarvoka» (12 de noviembre de 2026) es más alta, más colorida y tiene un centro de mando, plato radar grande, torre de comunicaciones, banderín y helipuerto frontal. La comparación renderizada V2/V3 permitió detectar que la geometría previa se percibía como un edificio bajo y gris, con helipuerto alejado del frente. V4 corrige **composición arquitectónica**, no solo ornamentos.

## Implementado
- **Torre central de mando** elevada sobre las cubiertas, revestimiento de facción, molduras doradas y prominente **placa de escudo 3D**.
- **Emblema compatible con futuras artes:** el escudo de V4 es un soporte genérico sin logotipo oficial inventado. Los ocho escudos finales aprobados se deberán montar sobre este soporte cuando los recursos de arte estén disponibles en el repositorio.
- **Alas laterales:** recubrimiento naval con ventanas empotradas, ductos y bandas pintables; los ocho colores vienen de `VisualStyle.faction_color()`.
- **Radar:** nuevo tamaño y posición alta en techo, con pedestales y arriostramientos; se aprovecha la antena cóncava auténtica de V2.
- **Comunicaciones:** torre con estructura triangulada, cabina de sensores y bandera de tela 3D volumétrica con pliegues.
- **Helipuerto:** se traslada físicamente del fondo elevado al frente izquierdo a baja cota, con plataforma, camino, marcas, malla y balizas heredadas.
- **LOD visual:** 44+ remaches repetidos agrupados en un solo `MultiMeshInstance3D`; el nodo `DetalleCercanoV4` sólo es visible al acercar. La silueta fuerte permanece visible siempre.
- **Estados:** conserva operativo, capturado, dañado, destruido, con nuevos fragmentos y marcas de impacto.
- **Tres niveles:** mantienen edificios y mástiles distintos por mejora.
- **Visor más claro:** un selector único **Acabado visual: V4 / V3 / V2 / V1** en lugar de tres botones de comparación; zoom ligeramente más cercano; gestos táctiles intactos; unidades disponibles sin regresiones.

## Validación
`tests/test_headquarters_v4.gd` comprueba en Godot 4.3 OpenGL:
- 8 facciones, 3 niveles y 4 estados.
- Mallas efectivas (ArrayMesh), bandera, radar, helipuerto frontal, escudo pintable y LOD con MultiMesh.
- Comparación V3/V4 desde **la misma cámara** y captura `artifacts/tarvoka_hq_v3_vs_v4_real_render.png`.
- Vista nivel 3 `artifacts/tarvoka_hq_v4_level3_render.png`.
- Regreso del visor a las unidades sin cambios en el G09.

El workflow `.github/workflows/web-art-studio.yml` ejecuta estos casos, exporta el estudio WebGL y archiva imágenes de QA antes de publicar.

## Estado del producto
**Prototipo avanzado, no aprobado comercialmente**. Aunque la silueta se acerca más a la referencia, faltan pruebas de aceptación visual a escala de mapa Android, optimizaciones y perfilado de llamadas de dibujo, un atlas artístico profesional, UV y mapas normales propios, y la incorporación del escudo oficial en lugar del soporte genérico. Ningún cambio de esta rama modifica el balance, combate, economía ni guardados.

## Archivos
- `scripts/ui/HeadquartersHero4.gd`: geometría V4 independiente.
- `scripts/ui/Headquarters3D.gd`: añade parámetro opcional `hero_enabled=true` y control LOD.
- `scripts/ui/CombinedArtStudioWeb.gd`: selector único y encuadre.
- `tests/test_headquarters_premium_v2.gd`, `tests/test_headquarters_v3.gd`: versiones previas inmovilizadas para comparación real.
- `tests/test_headquarters_v4.gd` y workflow web: QA.
