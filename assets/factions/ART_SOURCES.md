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

### Segunda tanda: las cuatro facciones restantes (integrada)

`official_last_four_atlas.webp`: atlas WEBP de **640 × 273 px, calidad 80**, ~33 KiB. Misma distribución y coordenadas locales del primero (fila superior: cuatro escudos de 160×160; fila inferior: cuatro retratos de 160×113), pero corresponde a los índices **4, 5, 6 y 7** del catálogo. Los recortes se realizaron **sin rediseñar** las artes aprobadas:

- Escudos: segunda fila de «Emblemas de facciones futuristas luminosas.png» (1536×1024), índice local `j = índice - 4`, rectángulo `x = 384×j, y = 535, w = 384, h = 384`.
- Retratos: misma lámina oficial de comandantes `241959.png` (1536×864), índice total `i`, recorte `x = 192×i + 8, y = 329, w = 176, h = 124`.
- El sistema carga automáticamente ambos archivos desde `VisualStyle.emblem_texture(i)` y `VisualStyle.commander_texture(i)`; `i` va de 0 a 7. El selector muestra el escudo en **cada opción** y, al seleccionarla, muestra el escudo grande y el retrato correspondiente.

| ID | Facción | Escudo | Retrato original |
| --- | --- | --- | --- |
| 4 | Sindicato Violeta | Tres hexágonos | Comandante mujer de cabello violeta y gafas |
| 5 | Legión Ámbar | Dragón blanco | Comandante veterano de barba gris y parche ocular |
| 6 | Dominio Turquesa | Tridente sobre olas | Comandante mujer con gorra naval |
| 7 | Orden Ónix | Insignia alada plateada | Comandante enmascarado de uniforme negro |

**Estado actual: 8 escudos y 8 retratos aprobados integrados.** No hay placeholders de arte en las ocho fichas, salvo que fallen los recursos. Estas texturas están optimizadas para la pantalla del juego y no sustituyen los originales maestros para marketing o impresión.

### Alcance y calidad

La versión atlas está optimizada para los retratos de selección del juego Android, no para impresión ni portadas de tienda. Los originales se conservan en la Biblioteca de proyecto «Advanced wars»; no confundir esta versión optimizada con los archivos maestros.

No se modifican bonificaciones de facción, reglas de combate, balance, guardados ni nombres aprobados.
