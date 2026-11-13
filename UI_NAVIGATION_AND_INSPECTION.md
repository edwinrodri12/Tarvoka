# TARVOKA — Arquitectura de pantallas y fichas de batalla (v0.1)

Este documento es la guía de interfaz de batalla para Godot 4.3/Android. **No sustituye** los modelos 3D ni modifica la campaña de 50 capítulos, que avanzan por separado. Las ocho facciones conservan sus nombres, insignias, comandantes y colores aprobados. El tablero actual sigue siendo **cuadrado**; los escudos/emblemas no implican cambiar a casillas hexagonales.

## Implementado en esta rama

- **Terreno jugable:** los ejércitos terrestres con 1 o 2 puntos de movimiento pueden entrar directamente en una montaña adyacente y gastan todo el movimiento. Con 3 o más puntos rige el coste ordinario de 3. La navegación conserva el bloqueo y la aviación el coste 1. El coste efectivo para combustible es el del desplazamiento legal.
- **Ventajas de combate reales ya integradas en el motor:** bosque +1 cobertura, montaña +2 cobertura, ciudad +1 cobertura para tropas terrestres; desnivel +1/-1 al atacar tierra contra tierra, flanqueo +1 cuando se cumplen sus condiciones; la defensa y altura también intervienen en el contraataque. No se alteran perfiles de unidades ni la iniciativa.
- **Ficha contextual en panel ampliado y HUD móvil:** al tocar unidad propia, enemigo visible, edificio conocido o terreno explorado se muestra el contexto desde datos reales del estado. Contiene HP, ATQ, DEF, MOV, rango de arma, cobertura, combustible/munición propia, propietario y funcionalidad de instalación, o restricciones del terreno.
- **Niebla segura:** el enemigo solo se consulta usando inteligencia observada; no se revela combustible, munición ni acciones privadas. Un edificio fuera de la visión actual puede identificarse si su casilla fue explorada, pero no se debe revelar su dueño actualizado. Una casilla sin explorar aparece como desconocida.
- **Conservación de controles:** zoom de dos dedos, cámara isométrica, confirmación de órdenes, botón cancelar y fin de turno, guardados existentes.

## Próximas pantallas (diseño — aún no todas programadas)

| Pantalla | Elementos | Comportamiento esperado |
|---|---|---|
| Inicio | Continuar, Campaña, Escaramuza, Online, Arsenal, Ajustes | Solo habilitar modos implementados; distinguir partidas locales y en red |
| Escaramuza | Mapa/semilla, tamaño, facciones, dificultad IA, niebla, economía y objetivos | Presets claros; opciones avanzadas plegables; preparación antes de iniciar |
| Campaña | Mapa de capítulos, avance, misión, objetivos y diálogo | Conectar al motor narrativo C01–C50 sin introducir desbloqueos desde UI |
| Batalla | Mapa protagonista, turno, presupuesto, objetivo, alerta y acciones | Tablero interactivo; instrucciones breves; sin menús superpuestos permanentes |
| Ficha de unidad | Nombre/modelo 3D cuando exista, propietario, HP, nivel, ATQ, DEF, MOV, arma, alcance, munición/combustible, efectos de terreno | Nivel solo cuando exista dato real; seleccionar no debe ejecutar movimiento |
| Ficha del enemigo | Estadísticas conocidas, alcance teórico, cubierta y peligros | Sin leer datos privados bajo niebla; separada de previsualizar ataque |
| Ficha de instalación | Tipo, dueño, ingreso/captura, producción, disponibilidad por turno | Producción solo si es aliada y hay crédito, terreno y espacio |
| Ficha de casilla | Bioma, coste por dominio, cobertura, altura, información táctica | Al explorar; no debe ofrecer ventajas falsas a unidades aéreas/navales |
| Arsenal/códice | Catálogo depurado, modelos y función táctica, niveles desbloqueados | Sin unidades duplicadas por apariencia ni promesas de artes ya finalizadas |
| Opciones | Audio, gráficos/3D-2D, batería, accesibilidad, guardar/cargar, ayuda | Ajustes secundarios sin tapar el mapa durante batalla |
| Resultados | Victoria/derrota, resumen, objetivos y progreso | Nunca adjudicar desbloqueos sin el resultado real del motor |

## Reglas de interacción

1. Toque de unidad aliada: ficha y áreas legales. El área azul representa movimiento; el área naranja representa **alcance potencial del arma después de mover**; el rojo representa objetivos atacables **ahora**. El ataque es una orden separada que necesita posición legal y confirmación.
2. Toque de unidad enemiga visible: ficha e inteligencia limitada. El cálculo de daño previo al ataque muestra daño esperado y posible contraataque sin revelar munición/reacciones privadas.
3. Toque de ciudad, fábrica o casilla: información de lectura; producir/conquistar sigue las acciones reales de juego. Tocar edificio de un enemigo nunca abre un botón de producción utilizable.
4. Mover cámara: arrastrar/pellizcar no produce selección o ataque involuntario; área del tablero sigue accesible bajo fichas de solo lectura.
5. Compacto móvil: tarjeta contextual encima de acciones, sobre fondo discreto con opacidad; un panel detallado permanece accesible en Opciones. El mapa siempre tiene prioridad visual.
6. Una ficha jamás modifica el estado persistente, salva ninguna estadística nueva ni revela objetivos tras niebla. Probar tanto 10×8 como 24×18 y 40×30.

## Fases para organizar el trabajo

- **v0.1 presente:** movilidad de montaña, fichas contextuales y regresión de niebla.
- **v0.2:** separar Opciones en navegación por secciones «Partida / Unidades / Producción / Ajustes»; conectar selección de fábricas con un catálogo de producción por edificio.
- **v0.3:** retratos de comandantes, insignias de facción, animación ligera de fichas, emblemas y modelos 3D definitivos cuando estén aprobados en su rama.
- **v0.4:** pantalla principal, preparación completa de escaramuza y selector de campaña; conectar online solo cuando esté disponible.
- **v1.0:** accesibilidad (tamaño de letra, color/texto, pantalla pequeña), navegación Android de regreso, pruebas táctiles y QA físico.

## Pendientes de validación

- Ejecutar Godot headless y export Android en CI de GitHub, luego revisar un APK en teléfono real.
- Comprobar que la nueva ficha no quite superficie táctil ni tape órdenes en pantallas pequeñas.
- Comprobar que el coste excepcional de escalar mantiene un balance razonable entre infantería y blindados; por ahora se aplica a todo dominio terrestre según la decisión de permitir ascender a todas las unidades.
