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

## Desglose de fases restantes

A. Continuidad de suelo: carreteras en cuatro direcciones, riberas de aguas, cruces con puente y pruebas de niebla — **primera iteración en esta rama**.
B. Elementos elevados: macizos y pinos volumétricos 2.5D ya integrados. **Pendientes:** mallas/atlas con texturizado de alta calidad, acantilados interconectados, cascadas, río más orgánico y transiciones variadas de biomas. 
C. Arte modular de edificios y ciudades a escala 2.5D/3D; tamaños y niveles por reglas disponibles; sin usar escudos de facción como parte inseparable de la geometría.
D. Variantes de bioma: templado, desértico, ártico, tropical, urbano y costero; solo introducir nuevos tipos tácticos tras diseño y pruebas de balance, mientras pueden ser variantes exclusivamente estéticas.
E. Optimización Android (40x30, niveles de detalle, fragmentación de atlas y cámara), QA visual en teléfono/tableta, sin promesas de FPS sin medición real.

## Nota de diseño: distinguir concepto de mecánica

Las láminas muestran cifras variadas y hasta contradictorias para coste de desplazamiento y defensa. **No copiarlas al código.** El motor es la autoridad en cobertura, altura y costes de carreteras/montañas. Asimismo, la imagen de ciudad mejorable y las cuatro capas de mapa son objetivos de experiencia, no prueba de que todas sus funciones estén programadas.

El arte conceptual tampoco es ya un atlas 3D importado: se utiliza como referencia para piezas originales escalables en Godot, y deberá compararse mediante capturas reales antes de declarar paridad de calidad.
