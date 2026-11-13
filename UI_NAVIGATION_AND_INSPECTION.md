# TARVOKA — Arquitectura de pantallas y fichas de batalla (v0.1)

Este documento es la guía de interfaz de batalla para Godot 4.3/Android. **No sustituye** los modelos 3D ni modifica la campaña de 50 capítulos, que avanzan por separado. Las ocho facciones conservan sus nombres, insignias, comandantes y colores aprobados. El tablero actual sigue siendo **cuadrado**; los escudos/emblemas no implican cambiar a casillas hexagonales.

## Implementado hasta v0.5

- **Carretera motorizada (v0.2):** dos casillas de carretera por punto de movimiento para vehículos terrestres motorizados; infantería terrestre a 1 casilla por punto; aire y naval sin bonificación. El cálculo usa medias unidades internamente y redondea el coste final de movimiento/combustible hacia arriba. El mismo cálculo se utiliza en movimientos legales, IA, exploración, suministro y alcance mostrado, sin regalar puntos por entrar y salir de carretera.
- **Terreno jugable:** los ejércitos terrestres con 1 o 2 puntos de movimiento pueden entrar directamente en una montaña adyacente y gastan todo el movimiento. Con 3 o más puntos rige el coste ordinario de 3. La navegación conserva el bloqueo y la aviación el coste 1. El coste efectivo para combustible es el del desplazamiento legal.
- **Ventajas de combate reales ya integradas en el motor:** bosque +1 cobertura, montaña +2 cobertura, ciudad +1 cobertura para tropas terrestres; desnivel +1/-1 al atacar tierra contra tierra, flanqueo +1 cuando se cumplen sus condiciones; la defensa y altura también intervienen en el contraataque. No se alteran perfiles de unidades ni la iniciativa.
- **Señales económicas en tablero (v0.5):** ciudades y talleres muestran marca discreta de propiedad (azul/rojo/neutral/desconocida). Una ciudad lleva $ y solo muestra su ingreso potencial por turno (+100 o +250) al inspeccionarla; «!» avisa de captura aliada *pendiente de finalizar el turno*, sin falso progreso. Bases propias: «+» únicamente si puede comprarse alguna unidad **ahora**, «-» si ya produjo, «$» si faltan fondos, «x» si no cabe unidad y punto si espera turno. Los estados de producción enemiga no se revelan. Una casilla nunca explorada no muestra instalación, y las exploradas sin visión actual ocultan dueño actualizado. Comparten snapshot de vista clásica e isométrica y solo resaltan una casilla seleccionada; iconos y textos se reducen con zoom y ahorro de batería. No cambia capturas, economía ni hitboxes.
- **Fichas gráficas v0.4:** portrait 2D provisional de la clase actual, barra HP, ATQ/DEF/MOV/VIS/RANGO/cobertura del terreno y suministros *solo propios*. Visible en panel lateral y HUD compacto sin eliminar ficha de terreno. Edificios enseñan titular conocido, ingreso por ciudad o disponibilidad de base; nunca revelan dueño de ciudad lejana solo explorada. Las fichas no alteran el guardado ni generan órdenes.
- **Comparador previo a producción v0.4:** en Centro de mando > Producción, cada unidad tiene acciones separadas **Ficha**, **Comparar** y **Comprar**. Ver diferencias en HP, daño, defensa, movilidad, visión, alcance y precio con miniaturas, papel táctico y disponibilidad real (créditos, turno, base usada u ocupación). Comparar es lectura pura y solo aparecen unidades construibles por ese tipo de instalación. La compra usa el motor existente.
- **Preparación de escaramuza (v0.3):** pantalla exclusiva antes del combate, tres presets («Clásica», «Moderna» y «Territorio»), mapa/semilla, 3 tamaños, ejército, niebla, ciudades/fábricas, objetivo, equilibrio e iniciativa; normaliza combinación inválida ejército clásico/economía. La partida actual no cambia hasta la confirmación existente. «Avanzado» mantiene los ajustes antiguos accesibles.
- **Pronóstico de combate (v0.3):** tarjeta visual con barras HP, pérdida prevista enemiga, posible daño máximo por contraataque, cobertura del defensor, bonificación neta de ataque y flanqueo. Fichas extraen cifras desde el motor legal y no consultan datos secretos del enemigo bajo niebla. No sustituye la confirmación de órdenes y desaparece al cancelar.
- **Pantalla de inicio v0.2:** Continuar, Modo historia C01, Escaramuza, Arsenal y Ajustes funcionan mediante las rutas reales del juego; el multijugador aparece deshabilitado porque todavía no está disponible. La portada se abre al iniciar en Android y no destruye el autoguardado al regresar al mapa.
- **Centro de mando v0.2:** cuatro pestañas independientes (Batalla, Ejército, Producción y Ajustes), accesibles desde el HUD compacto y el panel completo sin ocultar permanentemente el mapa. Ejército permite localizar una tropa sin dar órdenes; Producción se limita a la fábrica propia seleccionada y verifica precio/turno/espacio; Opciones comparte controles reales de cámara, batería y guardado.
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
- **v0.2 presente:** centro de mando móvil por pestañas (Batalla, Ejército, Producción, Ajustes); producción contextual autorizada, velocidad de carretera específica para vehículos, HUD y pruebas Godot.
- **v0.3 presente:** configurador de escaramuza por presets y previsualización gráfica del intercambio de combate; retratos de comandantes, insignias de facción, animación ligera de fichas, emblemas y modelos 3D definitivos cuando estén aprobados en su rama.
- **v0.4 presente:** fichas gráficas, notas tácticas y comparación de dos clases antes de fabricar.
- **v0.5 presente:** iconos de ciudades y bases, propiedad conocida, ingreso al inspeccionar, captura pendiente y disponibilidad real de producción en mapa clásico e isométrico.
- **v0.6:** pulir portada, selector de campaña C01–C50 conforme se implementen realmente y retratos/modelos 3D definitivos; conectar online solo cuando esté disponible.
- **v1.0:** accesibilidad (tamaño de letra, color/texto, pantalla pequeña), navegación Android de regreso, pruebas táctiles y QA físico.

## Pendientes de validación

- Ejecutar Godot headless y export Android en CI de GitHub, luego revisar un APK en teléfono real.
- Comprobar que la nueva ficha no quite superficie táctil ni tape órdenes en pantallas pequeñas.
- Comprobar que el coste excepcional de escalar mantiene un balance razonable entre infantería y blindados; por ahora se aplica a todo dominio terrestre según la decisión de permitir ascender a todas las unidades.
