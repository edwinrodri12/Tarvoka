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

## Desglose de fases restantes

A. Continuidad de suelo: carreteras en 4 direcciones, riberas de aguas, pruebas de zoom/niebla y miniatura del mapa — **comenzado aquí**.
B. Elementos elevados: montañas con paredes y mesetas verosímiles; transiciones entre roca, pradera, bosque; cascadas, puentes y cambios de nivel visuales, manteniendo hitboxes. 
C. Arte modular de edificios y ciudades a escala 2.5D/3D; tamaños y niveles por reglas disponibles; sin usar escudos de facción como parte inseparable de la geometría.
D. Variantes de bioma: templado, desértico, árctico, tropical, urbano y costero; solo introducir nuevos tipos tácticos tras diseño y pruebas de balance, mientras pueden ser variantes exclusivamente estéticas.
E. Optimización Android (40x30, niveles de detalle, fragmentación de atlas y cámara), QA visual en teléfono/tableta, sin promesas de FPS sin medición real.

## Nota de diseño: distinguir concepto de mecánica

Las láminas muestran cifras variadas y hasta contradictorias para coste de desplazamiento y defensa. **No copiarlas al código.** El motor es la autoridad en cobertura, altura y costes de carreteras/montañas. Asimismo, la imagen de ciudad mejorable y las cuatro capas de mapa son objetivos de experiencia, no prueba de que todas sus funciones estén programadas.

El arte conceptual tampoco es ya un atlas 3D importado: se utiliza como referencia para piezas originales escalables en Godot, y deberá compararse mediante capturas reales antes de declarar paridad de calidad.
