# TARVOKA — Revisión visual en Android (13-11-2026)

Esta revisión parte de la captura real enviada por el usuario desde una batalla Android. Se mantiene separada de la rama de modelos de unidades, de la historia y del HUD.

## Estado observado

- Los colores de los dos bandos y la silueta de las unidades ya ayudan a leer rápidamente la posición estratégica.
- **Rombos y superficies:** el terreno todavía muestra juntas de casillas y variación abrupta. La capa isométrica debe ocultar bordes internos entre terrenos homogéneos, conservando contornos y celdas tácticas en la selección.
- **Carreteras:** segmentos e intersecciones demasiado rectos. En esta rama se sustituyeron por trazos de pavimento/arcén continuos y pequeñas curvas basadas en extremos compartidos. No cambia el costo de movimiento.
- **Montañas:** muchos picos con siluetas verticales parecidas. Próximo trabajo: cordilleras irregulares y transición con las llanuras, respetando la lectura defensiva en HUD.
- **Bosques:** clumps de pinos mejor que árboles aislados pero repetidos, con límites de color geométricos. Próximo trabajo: sotobosque compartido y variación en los bordes sin filtrar niebla.
- **Interfaz / cámara (otro subproyecto):** unidades de la parte inferior parcialmente ocultas por el panel, información de terreno demasiado pequeña en teléfono, posible superposición de etiquetas con piezas y edificios. Requiere aplicar un encuadre que respete el área visible entre HUD superior e inferior y una prioridad de etiquetas; NO se corrige mediante reglas tácticas ni modificando la escala/alcance de las unidades.
- **Unidades / edificios (otros subproyectos):** proporciones, acabados 3D y animaciones aún están en progreso. No mezclar aquí modificaciones al catálogo ni a los modelos.

## Incremento implementado en el renderizador 2.5D

- `WorldArt.gd`: carreteras con pequeñas curvas procedurales a partir de `LandscapeContinuity.river_curve`, con pavimento, arcén y marcas de desgaste y carretera central. Los extremos de los bordes son compartidos y respetan los enlaces dados por `TerrainTopology.road_mask`.
- `IsoRenderer.gd`: bordes norte/sur de la cuadrícula se dibujan con contraste muy bajo **solo** en límites de terreno diferente o sin conexión visible. Dentro de un bioma conectado se ocultan las líneas superficiales. La niebla de guerra sigue siendo autoridad para cualquier máscara de vecinos.
- `.github/workflows/map-art-previews.yml`: recompila las capturas originales de materiales cuando cambia `IsoRenderer.gd`, `WorldArt.gd` o estilo.
- `.github/workflows/native-terrain3d-preview.yml`: captura la misma batalla 3D y el fallback 2.5D con esos cambios de terreno para comparar efectos de integración sin instalar una APK.

**Invariantes:** `Rules`, `BattleSession`, `SaveCodec`, `TacticalHints` y la entrada de Android se mantienen sin cambios; solo se modifica representación visual. Seguir haciendo QA en los tres tamaños 10x8, 24x18 y 40x30 y con niebla activada.

## Criterios para terminar el arte ambiental

1. Materiales de suelo y vegetación deben enlazarse entre casillas visibles sin patrón de rombos repetido.
2. Montañas deben formar macizos, no picos independientes con nieve idéntica.
3. Carreteras y ríos deben conectarse sin costuras, con cruces y puentes legibles.
4. Las unidades del borde del mapa, etiquetas y comandos deben ser visibles en Android sin cubrirse mutuamente.
5. Capturas de calidad completa/media, rendimiento móvil real y regresión Godot/APK sin errores.
6. Igualar el lenguaje visual de las artes de referencia originales, con propiedad intelectual propia y sin sustituir imágenes de juego por ilustraciones conceptuales.

**Estado:** incremento visual 2.5D en PR #183, aún borrador. No fusionar con `main` hasta revisión de cambios concurrentes y pruebas del arte/cámara.
