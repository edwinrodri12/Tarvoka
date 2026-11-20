# TARVOKA — Taller de Blindados V2: evolución, impactos y destrucción

## Diseño aprobado, animaciones nuevas
Se preserva la arquitectura 3D del Taller de Blindados V2; el usuario consideró perfecto el modelo general y solicitó terminar su evolución y animación de combate. **No existe un ataque ofensivo propio** de este edificio: `RECIBIR ATAQUE` reproduce un proyectil enemigo impactando en la construcción, no crea un arma ni una nueva regla de batalla.

### Evolución N1–N3

| Nivel | Arquitectura | Evolución visible |
| --- | --- | --- |
| N1 | Taller blindado compacto, 1 bahía | Modelo completo compacto con un espacio de mantenimiento |
| N2 | Taller mecanizado, 2 bahías | Aumenta estructura, puertas, techo, equipos y capacidad visual del edificio |
| N3 | Complejo de blindados, 3 bahías | Nave grande con tres zonas de servicio, ventilación y detalles adicionales |

`ArmoredWorkshopEvolutionVFX3D.gd` reproduce una transición de **1,05 segundos** con cinco andamios físicos de color de facción y cuatro chispas de soldadura. Al finalizar, emite `stage_requested(N+1,D)` para que el visor sustituya el edificio por el modelo geométrico real del siguiente nivel (no escala artificialmente el N1 para hacerlo pasar por N3). Se bloquea una evolución más allá de N3 o cuando D4 indica destrucción total.

### Daños progresivos D0–D4

| Etapa | Manifestación permanente |
| --- | --- |
| D0 | Intacto, sin marcas de batalla |
| D1 | Dos quemaduras pequeñas sobre el techo, desgaste leve |
| D2 | Seis quemaduras más grandes, puertas dañadas y escombros |
| D3 | Daño crítico: se pierde la cubierta completa, estructura de soporte quebrada |
| D4 | Destrucción: estructura derrumbada, quedan cimientos, placas y escombros |

El *impacto visual entrante* dura **0,34 s** de trayectoria más **0,54 s** de explosión. Usa un proyectil visible, destellos radiales, onda de choque, ocho chispas metálicas y cuatro volúmenes de humo que desaparecen al acabar la animación. En estados D0–D2 el golpe alcanza la cubierta superior opaca para poder verse desde la cámara táctica; en ruinas D3 impacta sobre los muros bajos restantes. El cambio a D+1 sucede en el impacto para que la destrucción permanezca visible tras disiparse el humo.

La reparación **es solo una simulación visual en el visor**: cinco haces de luz durante 0,55 s y transición D→D−1 sin consumir recursos, introducir talleres de suministro, reparar unidades de juego ni modificar estados persistentes.

### Controles para revisar en el estudio 3D

En **EDIFICIOS > Taller de Blindados** y en el visor individual:
- `EVOLUCIONAR N+1`: de N1 a N2 a N3; nunca más allá de N3.
- `RECIBIR ATAQUE D+1`: un nuevo proyectil y daños acumulativos hasta D4.
- `REPARACIÓN VISUAL D-1`: retrocede una etapa de daño para comparar recuperaciones.
- Los selectores existentes permiten escoger manualmente cualquiera de N1–N3, Facción Neutral/F1–F8 y D0–D4, en geometría HERO o escala táctica Android.

En el modo de nueve casillas se reduce la escala de los efectos al tamaño real de la celda de **2,4 m**. `stage_requested` modifica únicamente los selectores del estudio y reconstruye el modelo visual del edificio; el código de juego no recibe órdenes de combate ni reparación.

### Archivos y pruebas

- `scripts/ui/ArmoredWorkshopEvolutionVFX3D.gd`: sistema de efectos y señales (sin recursos `Gameplay`).
- `scripts/ui/ArmoredWorkshop3DV2.gd` y `ArmoredWorkshopMobileLOD3D.gd`: cicatrices persistentes de techo D1/D2 con material opaco.
- `scripts/ui/ArmoredWorkshopDesignStudioV1.gd` y `ArmoredWorkshopStudioAdapterV1.gd`: controles conectados en ambos visores.
- `tests/test_armored_workshop_evolution_vfx.gd`: progresión y reparación N1→N3 y D0→D4, validación de señales y límites.
- `tests/test_armored_workshop_evolution_studio_ui.gd`: pulsadores reales en la escena Godot, sustitución real del modelo y vista de batalla.
- `tests/capture_armored_workshop_evolution_vfx.gd`: 17 fotogramas reales (N1/N2/N3, construcción, proyectil, explosión, estados D0–D4).
- Actualizaciones de `tests/test_armored_workshop_v2_native.gd` y `tests/test_armored_workshop_mobile_lod.gd` comprueban la cantidad de quemaduras y su opacidad en todos los perfiles.

**Límites:** esto es arte animado y previsualización, no integración jugable. No cambia `BattleTerrain3D.gd`, reglas, economía, combate, producción, consumibles ni datos guardados. El Taller no obtiene un arma ni capacidad ofensiva. El teléfono Android físico sigue pendiente de evaluación antes de entrega comercial.
