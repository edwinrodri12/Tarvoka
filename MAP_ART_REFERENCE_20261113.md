# TARVOKA — Guía de implementación del entorno a partir de artes del proyecto
Fecha de revisión: 13 de noviembre de 2026.
Rama visual: `feat/connected-environment-map-20261113`.

## Artes revisadas en la Biblioteca / Advanced wars

Referencias de máxima prioridad, **archivos existentes en Biblioteca**, no se pretende que sus PNG estén ya importados al repositorio:

1. `Batalla Isométrica: Operación Río Azul.png`: vista de juego; relieve orgánico, río con cascada, dos puentes, carretera continua, pinos agrupados, ciudades, instalaciones, costa y combatientes.
2. `TARVOKA: Operación Río Azul.png`: variante con cámara y HUD inferior, grilla táctica translúcida y transición natural desde altiplano hacia costas.
3. `Mapa Estratégico de Tarvoka.png`: juego en escala territorial, montañas y ríos que estructuran rutas; bordes azul/rojo solo para modo territorial.
4. `TARVOKA: Frente del Río Norte.png`: valles atravesados por puentes, orografía, vías terrestres y frente disputado.
5. `Guía de Terrenos del Mapa Tarvoka.png`: biblioteca conceptual, NO fuente automática de reglas (los números en la imagen no reflejan siempre el balance vigente).
6. `Infografía de terrenos tácticos del mapa.png`: otras variantes de terreno/ambientación.
7. `Infografía de Terrenos y Tácticas de Tarvoka.png`: biomas templado, desértico, ártico, tropical, urbano y costero.
8. `Tablero Visual de TARVOKA: Tácticas Avanzadas.png`: lineamientos de silueta, suelo, edificaciones e interfaz.
9. `Interfaz táctica de Tarvoka en español.png`: vistas Normal / Territorial / Logística / Táctica, sin cambiar acciones actuales.
10. `Infografía TARVOKA: Edificios y Estrategia.png` y `TARVOKA: Ciudades y desarrollo económico.png`: volúmenes e identidad de edificios/ciudades, no promesa de funciones ya implementadas.

## Lenguaje visual bloqueado

- Perspectiva isométrica 2.5D con sensación de volumen; mundo **continuo**, aunque el tablero funcional conserve celdas.
- Naturaleza limpia, luminosa y vibrante; verde y tierra para suelo, piedra estratificada, pinos en grupos, ríos azules con orillas, espuma y puentes.
- Edificios estilizados modernos con masa legible; color de facción en áreas de identificación, no recolorear toda la geografía.
- Redes de carretera que se continúan a través de las casillas, puentes conectados con las vías y orillas costeras legibles.
- Grilla discreta en vista normal; colores de movimiento azul, ataque rojo; capas territorial, logística y táctica solo si están ligadas a datos reales.
- Zoom táctil, minimapa, niebla y selección siguen siendo fuente de verdad. Las siluetas decorativas nunca conceden cobertura, ingresos ni movimiento.

## Primer incremento en esta rama

- `TerrainTopology.gd` calcula conectividad cardinal de carreteras y orillas observadas. No guarda ningún metadato nuevo en las partidas.
- `WorldArt.gd` dibuja segmentos de asfalto unidos y transición entre agua y tierra dentro de las casillas visibles. Esto sustituye la carretera diagonal artificial e independiente de cada casilla.
- `IsoRenderer.gd` inyecta solo conexiones visibles para que el mapa no revele secretos detrás de niebla.
- Nueva regresión en `test_connected_terrain_art.gd` y paso en `godot-rules.yml`; debe pasar el CI antes de fusionar.

## Segundo incremento (13 de noviembre, rama actual)

- `LandscapeDetailPainter.gd`: nueva capa visual original en Godot de grupos de pinos con profundidad, sombras y variación determinista, y macizos con facetas de roca, mesetas y nieve. La densidad se adapta al nivel de detalle para teléfonos.
- `TerrainTopology.bridge_axis()`: identifica **solo a partir de carreteras y agua visibles** los cruces de río que deben verse como puentes; no crea terrenos ni reglas nuevos. Los apoyos y barandillas del puente siguen siendo puramente gráficos.
- `WorldArt.gd` delega la pintura de montaña/bosque y aplica puente cuando corresponde.
- `IsoRenderer.gd` usa la conectividad de la topología para dibujar masas conectadas y ajusta el nivel de detalle al zoom y al ahorro de batería.
- `test_connected_terrain_art.gd` amplía comprobaciones para ambos ejes de los puentes, ocultación por niebla y conexión de los macizos/bosques.

**Estado honesto:** esta entrega es arte procedural 2.5D integrado en la partida, no mallas tridimensionales/texturizado PBR ni calidad final equivalente a las láminas. Las referencias siguen siendo el objetivo para la siguiente iteración.

## Tercer incremento — transiciones y relieve continuo (13 de noviembre)

- `LandscapeTransitions.gd`: costas dibujadas del lado terrestre mediante franjas de tierra/piedra y pequeños guijarros; pedreras y sedimentos en el pie de las montañas; corrientes alineadas con la forma observable de cada tramo de agua.
- `LandscapeDetailPainter.gd`: las cumbres pertenecientes al mismo macizo comparten espolones rocosos hasta sus bordes; los acantilados se pintan exclusivamente si el vecino de terreno distinto es visible, evitando sugerir información bajo niebla.
- `IsoRenderer.gd` calcula separadamente conexiones de agua, bordes marítimos, piedemontes y acantilados con filtros de visibilidad; deja el estado de combate y las partidas guardadas intocados. La cuadrícula de fondo es más discreta para que el terreno no parezca un tablero de losetas.
- `VisualStyle.gd` usa variación cromática de baja frecuencia en lugar del damero de colores claros/oscuros y una gama natural templada más próxima a la dirección original.
- `test_landscape_materials.gd` rasteriza en Godot las 16 combinaciones cardinales de orillas y acantilados, en detalle medio y alto; el nuevo paso de CI falla ante errores de geometría. Los tests existentes siguen comprobando niebla, batalla inmutable y mapas grandes.

**Pendientes para lograr paridad con el concepto aprobado:** modelos 3D/mallas de relieve, textura de roca/suelo/vegetación y materiales, curvas orgánicas de ríos en vez de canales siempre celulares, cascadas con altitud explícita, y capturas reales en Android de distintas escalas. Evitar dibujar cascadas sin datos de elevación, porque implicaría un relieve inventado que no existe en las reglas.

## Cuarto incremento — texturas procedurales y visor de comparación sin APK

- `TerrainSurfaceMaterials.gd`: microdetalle original en hierba, bosque, roca, agua y asfalto; distribución determinista, comprimida dentro de cada diamante. Dos perfiles de detalle en el render; ahorro de batería/mínimo omite microtexturas.
- `TerrainTextureAtlas.gd`: genera texturas reales de Godot `ImageTexture` a partir de ruido multiescala, con estratos rocosos y reflejos de agua; se almacenan en caché por material y nivel de calidad (96 px medio, 160 px completo). Se pintan recortadas dentro del diamante; no se descargan librerías, imágenes ni assets de terceros.
- Las laderas de `LandscapeDetailPainter.gd` reciben material sobre sus facetas. La variedad de alturas y número de picos reduce la repetición visible en la primera captura de prueba.
- `export_environment_preview.gd` utiliza tanto el material como el atlas de texturas de la batalla, para que el laboratorio no muestre una versión distinta.
- `IsoRenderer.gd`: incluye esas marcas **solamente en celdas actualmente visibles**, bajo el mismo control de niebla, zoom y mapa táctico. Ninguna de ellas modifica terreno, reglas o guardados.
- `test_landscape_materials.gd`: verifica estabilidad del sembrado y que las marcas no sobrepasen los límites geométricos; se dibujan tanto a calidad media como completa.
- `tools/export_environment_preview.gd`: crea dos capturas reales del mismo pintor gráfico Godot 4.3 usado en la partida, sobre un escenario de exhibición fijo con montañas, bosques, río y carretera con puente; no simula una partida ni reemplaza las pruebas de reglas.
- `.github/workflows/map-art-previews.yml`: automatiza con Xvfb/Mesa la exportación de ambas capturas a un artefacto `tarvoka-environment-preview`. No hay que instalar Android para verlas.
- `tools/environment-preview-gallery.html`: galería local y responsiva; abre `index.html` del ZIP del artefacto de GitHub Actions. Permite alternar perfiles y cargar localmente una lámina aprobada como referencia al lado derecho. No envía la imagen a ningún servicio.

### Procedimiento de revisión sin APK

1. Abrir el pull request del entorno en GitHub, entrar a la ejecución más reciente de `TARVOKA map art preview (no APK)`.
2. Descargar el artefacto `tarvoka-environment-preview`, descomprimirlo y abrir `index.html` con cualquier navegador.
3. Alternar `Detalle completo` y `Detalle medio / móvil`. Seleccionar una de las imágenes originales de `Advanced wars` desde el campo `Elegir referencia PNG/JPG`.
4. Comparar **elementos equivalentes**, no exigir que el mapa de demostración reproduzca la composición exacta de la lámina. Registrar capturas de discrepancias de costa, bosque, altiplano, contraste y legibilidad.
5. Después de validar por capturas, revisar en una APK real la cámara, la niebla de guerra y el rendimiento en móvil; las imágenes no sustituyen la prueba táctil.

**Límite:** se trata de materiales procedurales pintados por CanvasItem en 2.5D. Todavía no son materiales 3D PBR, modelos de suelo texturizados ni fotogrametría. El producto comercial debe evaluarse con capturas reales y evitar prometer paridad total hasta mejorar geometría, iluminación y detalle.

## Quinto incremento — relieve orgánico y riberas curvas (13 de noviembre)

- `LandscapeTransitions.gd`: reemplaza las franjas de costa rectas por bandas de nueve a diez puntos con curvas deterministas de pequeña escala. Usa **dos triángulos convexos por segmento**, evitando fallos de triangulación. Todo permanece dentro de la casilla conocida; no cambia datos del mapa ni la niebla de guerra.
- `WorldArt.gd`: unifica la pintura de riberas terrestres y espuma de la orilla acuática con las curvas nuevas, en detalle medio y completo.
- `LandscapeDetailPainter.gd`: siluetas rocosas de nueve vértices, facetas irregulares, estratos texturizados y nieve selectiva; cada macizo ya no depende de los mismos dos triángulos. Las copas de los pinos tienen franjas escalonadas con bordes de ramas desiguales, distinta amplitud y sombreado.
- `tools/export_environment_preview.gd`: escenario de prueba con río serpenteante que desemboca en un estuario, cruzado por una carretera con puente, para comparar los mismos materiales con capturas originales de Godot.
- `tests/test_landscape_materials.gd`: prueba nuevos puntos de la ribera curva para cuatro bordes y cuatro semillas, comprueba que son reproducibles y que **ninguno sale del diamante**, además de rasterizar montañas y vegetación para detectar polígonos defectuosos.

**Criterio de aceptación:** CI Godot de reglas y material debe pasar sin `SCRIPT ERROR` o `ERROR`, la vista previa debe exportar PNG de detalle completo y medio, y la APK debe compilar. **Esto sigue siendo 2.5D isométrico**, no una malla de terreno 3D físicamente basada. El siguiente gran salto de fidelidad requerirá resolver la geometría tridimensional, escalar materiales/iluminación y validar el rendimiento móvil con vistas próximas y lejanas.

## Sexto incremento — conexiones geométricas entre casillas (13 de noviembre)

- `LandscapeContinuity.gd`: trayectorias de cauce y crestas enlazadas entre vecinos por **puntos de salida idénticos** en el borde común. La trayectoria interna puede variar sin romper la conexión; el río conserva continuidad visual y la piedra tiene una espina central más legible.
- `LandscapeDetailPainter.gd`: integra las crestas de montaña antes de dibujar sus siluetas de roca.
- `WorldArt.gd`: pinta el cauce conectado y pasa la coordenada de la casilla a la decoración. `IsoRenderer.gd` mantiene su filtro de niebla; únicamente entran máscaras de vecinos observados, sin revelar territorio oculto.
- `LandscapeTransitions.gd`: ruido costero compartido por cada borde tierra-agua; ambas casillas emplean la misma semilla canónica y el extremo inverso. La espuma curva de un lado coincide con la geometría del otro y no excede los límites tácticos del diamante. La parte del diamante acuático que está pegada a un terreno conocido se cubre con el color real de su vecino, ocultando la orilla rígida de la casilla y dejando una ribera orgánica interna.
- `IsoRenderer.gd` envía ese color **solo si la casilla de tierra está actualmente visible**; la pintura no debe descubrir tipos de terreno detrás de niebla. El laboratorio utiliza los mismos colores de vecinos desde `export_environment_preview.gd`.
- `test_continuous_world_seams.gd`: verifica salidas coincidentes N/S/E/O para cauces y cordilleras, bancos emparejados al invertir la dirección de borde y ausencia de secretos bajo niebla. La galería automática ejecuta este test antes de exportar PNG.
- `tools/export_environment_preview.gd`: usa las mismas coordenadas de mundo y fuentes de la batalla para mostrar esa continuidad en el laboratorio visual.

**Límite del sistema:** es un renderizador isométrico 2.5D que sigue usando casillas de agua y montaña como fuente de verdad. Se han corregido discontinuidades decorativas, **no** generado aún una única malla tridimensional de terreno. La futura conversión a relieve 3D no debe alterar la selección de celdas, las propiedades de las unidades, los costes ni los guardados.

## Desglose de fases restantes

A. Continuidad de suelo: carreteras en cuatro direcciones, riberas de aguas, cruces con puente y pruebas de niebla — **primera iteración en esta rama**.
B. Elementos elevados: macizos y pinos volumétricos 2.5D ya integrados. **Pendientes:** mallas/atlas con texturizado de alta calidad, acantilados interconectados, cascadas, río más orgánico y transiciones variadas de biomas. 
C. Arte modular de edificios y ciudades a escala 2.5D/3D; tamaños y niveles por reglas disponibles; sin usar escudos de facción como parte inseparable de la geometría.
D. Variantes de bioma: templado, desértico, ártico, tropical, urbano y costero; solo introducir nuevos tipos tácticos tras diseño y pruebas de balance, mientras pueden ser variantes exclusivamente estéticas.
E. Optimización Android (40x30, niveles de detalle, fragmentación de atlas y cámara), QA visual en teléfono/tableta, sin promesas de FPS sin medición real.

## Nota de diseño: distinguir concepto de mecánica

Las láminas muestran cifras variadas y hasta contradictorias para coste de desplazamiento y defensa. **No copiarlas al código.** El motor es la autoridad en cobertura, altura y costes de carreteras/montañas. Asimismo, la imagen de ciudad mejorable y las cuatro capas de mapa son objetivos de experiencia, no prueba de que todas sus funciones estén programadas.

El arte conceptual tampoco es ya un atlas 3D importado: se utiliza como referencia para piezas originales escalables en Godot, y deberá compararse mediante capturas reales antes de declarar paridad de calidad.
