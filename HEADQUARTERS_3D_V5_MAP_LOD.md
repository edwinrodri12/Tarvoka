# TARVOKA — Cuartel General V5, vista táctica de baja carga

Se añade una versión geométrica simplificada para las distancias de mapa, sin perder el Cuartel General V4 de detalle alto. El modo distante conserva la silueta principal: torre, alas, radar, fachada con colores de facción, helipuerto frontal y perfil de ruinas.

## Implementación real
- scripts/ui/HeadquartersMapLOD3D.gd: concentra la vista distante en un ArrayMesh con seis superficies PBR y conserva el V4 completo en un grupo independiente.
- scripts/ui/CombinedArtStudioWeb.gd: una opción llamada Vista lejana optimizada (mapa) permite comparar V4 y la malla simplificada sin reinstalar APK.
- tests/test_headquarters_map_lod.gd: cubre 3 niveles, 4 condiciones, 3 facciones; verifica que se renderice una sola MeshInstance3D en el grupo distante y guarda una comparación gráfica con la misma cámara.

La selección de facción es real; no se inventa ningún escudo oficial. Los cambios son exclusivamente visuales: sin edición de economía, IA, daños, captura, ocupación de casillas ni partidas.

## Criterios pendientes para producto comercial
El cambio baja las mallas visibles, pero no demuestra FPS Android hasta medirlo en hardware y con varios edificios. Ambos LOD permanecen en memoria; optimizar memoria y elegir LOD dinámico en el mapa táctico son trabajos posteriores. Es un modo opt-in de estudio y no sustituye aún la arquitectura de edificios jugables.
