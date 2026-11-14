# TARVOKA Cuartel General V18 — señalización arquitectónica 3D

## Sobre qué parte continúa

Basado en la rama artística `feat/hq-v17-commercial-weather-terrain-20261114`, que contiene lluvia/nieve, cuatro materiales de terreno, recubrimiento reversible, V12 arquitectura hero, V13 calidad táctica y comparadores Android V15.

Esta etapa **no sustituye V17**, ni las ocho facciones, ni el selector de clima o iluminación. Añade una capa visual opcional al modelo detallado para dar lectura operacional al Cuartel de noche o al atardecer.

## Arte añadido en Godot

`scripts/ui/HeadquartersWayfindingV18.gd` construye **14 elementos volumétricos reales**, con **3 MultiMeshInstance3D**:

- **8 ventanas y señales interiores** de tono cálido en fachada y acceso
- **4 guías visibles de facción** en el acceso y alas delanteras, coloreadas desde la paleta oficial (no se dibuja otro escudo)
- **2 balizas de seguridad** en la zona de cubierta, con material emisivo

La luz es emisión de material: **no se añaden OmniLight3D, sombras dinámicas ni nodos individuales por ventana**. Se conservan geometrías entre transiciones; la facción modifica solo la señalización de pintura. La temperatura y fuerza de emisión distingue atardecer de noche y responde a lluvia.

La capa es visual, sin colisión, sin cambios tácticos y sin requerir una textura diferente por facción. En horario diurno se oculta; también se oculta con estado destruido, modo LOD distante, modo V15 Sprite3D y V13 táctico. El edificio se puede rotar y la iluminación gira con él porque la geometría V18 es hija del HQ, no del suelo climático.

## Vista en TARVOKA Estudio 3D

En `EDIFICIOS 3D → Cuartel General`, activa `V18 · Accesos iluminados y balizas 3D agrupadas` y cambia `ILUMINACIÓN DE ESTUDIO` a atardecer o noche. Cambia luego facción, clima y LOD para comparar. El control es reversible sin reinstalar el juego ni regenerar el edificio.

El nuevo código se propone en PR apilada sobre V17, **no se publica automáticamente** ni se añade al APK hasta QA y una decisión de integración segura. El sitio actual sigue mostrando V17.

## QA y límites

`tests/test_hq_v18_wayfinding.gd` valida 3 lotes, 14 instancias, colores de facción, clima, ocaso/noche, estado destruido, interruptor, LOD distante, modo V15 y presupuesto V13. El workflow `hq-v18-wayfinding-gpu.yml` ejecuta Godot 4.3 nativo con capturas GPU:

- `tarvoka_hq_v18_night_wayfinding_3d.png`
- `tarvoka_hq_v18_rain_night_faction_glow.png`
- `tarvoka_hq_v18_dusk_3d.png`

**No equivale a un benchmark de FPS en hardware Android**. Quedan pendientes revisión visual de capturas reales, verificar que la luminaria sea legible con las ocho paletas y publicación en TARVOKA Studio 3D tras QA verde. El acceso, la insignia oficial y la fachada no se modifican.

## Seguridad de integración

La V18 opera exclusivamente en la rama de arte HQ. No cambia `Weather.gd`, reglas, IA, terreno táctico, partidas, niebla de guerra, multijugador, objetos de selección o export Android existente. Ninguna ampliación de estética debe sumar tres lotes por cada edificio distante: el modo táctico no instancia esta capa.
