# TARVOKA — Una identidad visual final, múltiples presupuestos de renderizado

Estado: 2026-11-14 · propuesta de arquitectura de rendimiento Android, primera fase G09 V28 implementada.

## Decisión de producto

**Nunca sustituir una unidad, edificio ni terreno por un diseño antiguo según distancia o calidad.** Un LOD puede quitar geometría imperceptible o aproximar el material del modelo final, pero debe preservar:
- silueta, proporciones, paleta de facción y volumen visible;
- poses esenciales, identificación del tipo de unidad, torreta/cañón y aspecto de daños;
- interpretación de altura, cobertura y caminos del terreno.
- mismos IDs, estados de niebla, selección y órdenes; el arte no tiene autoridad táctica.

## Auditoría del motor actual

- Android tiene un campo táctico 2D isométrico, un visor 3D opcional y renderizadores 3D a textura en `UnitRender3D.gd`. La captura estática actual crea por defecto `Models.build(role,faction)`, es decir `art_level=10` para el tanque. No basta con corregir el visor 3D para mejorar TODO el campo 2D.
- El atlas `UnitSpriteAtlas.gd` actual proviene de 32 siluetas SVG originales, 4 poses, 96 px, y es fallback de presentación, **no** una captura del G09 V25.
- `BattleTerrain3D.gd` ya junta suelo por chunks de 8x8, y la vegetación repetida utiliza `MultiMesh`. Conservar esas optimizaciones.
- V27 cambiaba entre modelos distintos V25/V10/V6 al variar el zoom. V28 lo prohíbe y modifica microgeometría, sombras y shader de **la misma instancia V25** sin reconstruirla. Prueba automatizada protege la identidad de la malla.

## Ruta de producción recomendada (en orden)

### Fase 1 — Uniformidad inmediata (V28)
Tanques bajo presupuesto de ocho modelos: árbol G09 V25 con 14 zonas originales y 17 acabados V23/V24; acercamiento = mallas y material completos; distancia = mismos componentes mayores y el mismo albedo de facción, con microdetalles y sombras no perceptibles apagados. La versión ECO no cambia de diseño. Cambios de zoom **en el mismo Node3D**, sin recargar materiales cada vez.

**Pendiente explícito:** el límite vigente de ocho modelos 3D mantiene una representación genérica para unidades adicionales; V28 aún no sustituye ese fallback por imágenes del V25.

### Fase 2 — LOD de malla de VERDAD (fuente V25)
Exportar el modelo final a GLB con mallas editables. Generar e importar versiones decimadas desde el GLB **derivadas del mismo V25** mediante el importador LOD Godot 4.3, con preservación de silueta en blindaje/chasis/torreta y preservación de partes móviles. El renderizador móvil decidirá por tamaño proyectado en píxeles, no solo por distancia de cámara. El proceso no debe decimar identificadores de color ni crear variaciones manuales desvinculadas del modelo maestro.

### Fase 3 — Impostores artísticos horneados desde los modelos FINALES
Crear en CI (nunca en cada arranque del teléfono) un atlas por familia de modelos con vistas direccionales del modelo final, albedo, sombras y normales de apariencia coherente; ángulos suficientes para cámara giratoria. Usarlo para tanques fuera del presupuesto de mallas y para el tablero isométrico; las animaciones cercanas pueden seguir usando una o dos capturas 3D en vivo. Necesita capturar ocho paletas oficiales y estados/poses cuando proceda, o permitir recolor fiel. Verificar que **no** se vuelvan a ver siluetas SVG como sustituto del G09 final, excepto en modo compatibilidad explícito.

### Fase 4 — Edificios y vegetación
Aplicar el mismo pipeline de fuente final al cuartel general y demás edificios. Conservar la arquitectura, cubiertas, volúmenes y colores oficiales; agrupar materiales repetidos y hornear detalles pequeños en normales/oclusiones. Mantener sombras dinámicas solo donde contribuyan al aspecto. Reutilizar `MultiMesh` por sector para arbustos, hierba, piedras, árboles y elementos repetidos, con grupos delimitados para culling efectivo. Evitar cientos de MeshInstance3D por edificio a distancia.

### Fase 5 — Entorno y clima
Agrupar suelo por chunks independientes y omitir chunks fuera de cámara/niebla; atlas de materiales para carretera/costa, lomas y nieve; luces solares limitadas, sombras por prioridad, efectos lluvia/nieve con partículas escaladas según carga, sin tocar las penalizaciones tácticas de clima. Mantener las transiciones de material de terreno y topografía acordadas.

### Fase 6 — Calidad adaptativa y QA físico
- Modos visuales **Alto/Equilibrado/Ahorro**: todos comparten la MISMA identidad artística; varían resolución interna del SubViewport, densidad de partículas, rango de sombras y nivel de detalle.
- Evitar cambios repetidos cerca de umbrales: histéresis y/o suavizado de microdetalles; la elección basada en tamaño proyectado evita diferencias entre móviles.
- Instrumentación: FPS bajo carga, p95 frame time, draw calls, tiempos de preparación, memoria VRAM/RAM, cambio de facción, temperatura y batería tras 15 minutos.
- Escenarios verificables: mapas 10x8, 24x18, 40x30; 8/16/32 unidades, 5/15/30 edificios; bosques densos, agua, atardecer/noche, lluvia y nieve; zoom/orbita rápida, daño y todos los colores.
- Meta de diseño orientativa a validar en dispositivo físico: **30 FPS sostenidos** en gama media Android con modo Equilibrado y **60 FPS** en dispositivos capaces con modo Alto, no una afirmación de rendimiento actual. Sin saltos evidentes de silueta en la distancia táctica.
- Mantener posibilidad de restaurar perfiles de calidad inferiores sin alterar partidas guardadas ni introducir errores de niebla.

## Condición de aprobación

No fusionar una optimización que mejore FPS a costa de que el tanque, cuartel o terreno se convierta en un diseño visualmente distinto. Una reducción real de geometría/efectos debe medirse y contrastarse con capturas mismo ángulo, misma facción, mismo clima y mismo zoom. Cuando la diferencia sea visible, volver al perfil superior o rehacer el LOD desde el modelo maestro.
