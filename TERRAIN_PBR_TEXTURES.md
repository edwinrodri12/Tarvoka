# TARVOKA — materiales y texturas del entorno (pasada PBR 0.1)

Esta entrega complementa el modelado del entorno V2 en **TARVOKA Estudio 3D**, todavía sin cambiar el tablero de batalla Android.

## Acabado implementado
- Texturas procedurales originales y repetibles de **tierra, roca, asfalto, arena, grava y agua**, cada una con albedo neutro y mapa de normales para microrelieve.
- Diseño ligero para WebGL: imágenes de 96×96 píxeles, con mipmaps, reutilizadas mediante caché; sin paquetes externos, licencias comerciales dudosas ni descargas en ejecución.
- La superficie continua conserva los **colores por vértice** que separan biomas; las nuevas texturas los modulan en vez de sustituir la paleta. Piedras, cordilleras y carreteras obtienen materiales individuales coherentes.
- El visor añade **Texturas PBR (comparar con colores planos)** y genera `artifacts/tarvoka_terrain_pbr_comparison.png` (mismas cámara, luz y mapa).
- Las unidades y edificios de referencia conservan íntegramente sus materiales. El efecto queda contenido en los nodos de terreno y elementos ambientales.

## Cómo revisarlo
En el navegador, abre Tarvoka Estudio 3D → **ENTORNO Y MAPA 3D** → activa o desactiva **Texturas PBR**. Comprueba con zoom medio/cercano la textura del camino, las rocas, la tierra, las orillas y el agua en los tres biomas. Alterna mediodía, atardecer y nublado, con y sin sombras.

## Alcance y límites
Esta es **una primera pasada de materiales**, no fotografías escaneadas, una biblioteca comercial de alta resolución ni texturas definitivas. El agua tiene microrrelieve estático, no ondas animadas. El terreno utiliza un atlas neutral compartido, aún sin máscaras especiales pintadas para cada bioma; roca y carretera tienen identidad material propia. Quedan por hacer UV/texel density definitiva, mejor calidad en primeros planos, suciedad acumulada y desgaste localizado, coste GPU real en Android, composiciones LOD y arte final aprobada con el usuario.

Las pruebas comprueban la existencia de texturas normales y albedo, reutilización, dimensiones, y captura comparativa pixel a pixel. No modifica costes de movimiento, pasos por montaña, niebla, ríos jugables, IA ni guardados.
