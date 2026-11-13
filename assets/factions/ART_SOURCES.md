# TARVOKA · Primeros cuatro escudos y retratos originales

Recursos **recortados de dos láminas aprobadas previamente por el usuario**, sin sustituir su identidad visual:

1. **Escudos:** lámina «Emblemas de facciones futuristas luminosas.png» (1536 × 1024 px, 4 columnas × 2 filas). Los cuatro escudos iniciales proceden de la primera fila, recorte rectangular `x = 384 × índice`, `y = 86`, `w = 384`, `h = 384`.
2. **Retratos:** lámina original **«241959.png»** (1536 × 864 px, ocho columnas y personajes). Los cuatro comandantes iniciales proceden de `x = 192 × índice + 8`, `y = 329`, `w = 176`, `h = 124`.

Índices del atlas, de izquierda a derecha:

| ID | Facción | Escudo | Retrato |
| --- | --- | --- | --- |
| 0 | Alianza Norte | Águila blanca, laureles | Comandante mujer de boina azul |
| 1 | Pacto Escarlata | León coronado | Comandante hombre de barba y uniforme rojo |
| 2 | Unión Verde | Árbol en engranaje | Comandante mujer con gafas sobre la cabeza |
| 3 | Confederación Solar | Sol radiante | Comandante rubio con auriculares |

## Recurso incorporado

`official_first_four_atlas.webp`: atlas WEBP de **640 × 273 px, calidad 80**, optimizado para la selección móvil. La franja superior contiene cuatro escudos, cada uno de 160 × 160 px; la franja inferior contiene cuatro retratos, cada uno de 160 × 113 px. La imagen se separa con `AtlasTexture.region` por índice, sin alterar las artes ni introducir retratos alternativos.

Usar `VisualStyle.emblem_texture(index)` y `VisualStyle.commander_texture(index)` para mostrar el arte. Si algún día se añaden imágenes maestras individuales `assets/factions/<key>.png` y `assets/commanders/<key>.png`, éstas tienen prioridad sobre el atlas; el contrato de `emblem_path`/`commander_path` permanece compatible.

Las facciones 4–7 conservan sus referencias del catálogo y los indicadores claros de **arte pendiente**, hasta que sus recursos aprobados se incorporen; no dibujar ni generar nuevos personajes para reemplazarlos.

### Alcance y calidad

La versión atlas está optimizada para los retratos de selección del juego Android, no para impresión ni portadas de tienda. Los originales se conservan en la Biblioteca de proyecto «Advanced wars»; no confundir esta versión optimizada con los archivos maestros.

No se modifican bonificaciones de facción, reglas de combate, balance, guardados ni nombres aprobados.
