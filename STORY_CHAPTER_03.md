# TARVOKA — Capítulo 03: NUDO SIETE

**Acto I**, misión C03 · **Control:** Sindicato Violeta · **Desbloquea:** G05 Ingeniero de combate (nivel I) · **Estado:** guion y escenario propuestos, todavía no programados.  
Continúa [C02 «Dos minutos de silencio»](STORY_CHAPTER_02.md); en [C04 «Convoy perdido»](CAMPAIGN_STORY_50.md) veremos una interpretación militar distinta de la catástrofe.

## Premisa y enfoque dramático

Los equipos del Nudo Siete reciben señales contradictorias y un sistema defensivo identifica erróneamente una aeronave como amenaza. La neutralización del objeto y la posterior **explosión de combustible** desencadenan un incendio y un apagón regional. La misión no adjudica todavía la responsabilidad a un país, un comandante ni a un saboteador. El jugador controla **trabajadores armados y especialistas de infraestructura** que intentan mantener con vida a su población mientras dos gobiernos empiezan a culparse.

**Tema de capítulo:** salvar lo que mantiene unida a una sociedad puede importar más que ganar el terreno.  
**Lección táctica:** ingeniería G05 vs Guardia G01, infraestructura, bloqueo de rutas, prioridad de recursos, objetivos alternativos claros. La primera intervención de ayuda no se cuenta como batalla para exterminar a un oponente.

## Escena A — sala de operaciones, mañana

*Desde las ventanas del Nudo Siete se distinguen los depósitos de combustible y un hospital comarcal. Las pantallas de sincronía registran comunicaciones tardías, pero no muestran una causa comprobada.*

- **COMANDANCIA VIOLETA:** «¿Podemos separar la red civil de la militar?».
- **INGENIERÍA:** «Sí. Si aislamos el nudo auxiliar, evitaremos que el fallo se propague».
- **CONTROL:** «Interferencia. Perdimos confirmación del corredor aéreo».
- **COMANDANCIA VIOLETA:** «No autoricen ninguna respuesta hasta recuperar contacto».
- **CONTROL:** «La estación remota ya actuó».
- **[Se escucha un golpe lejano. Las luces parpadean; una columna de humo aparece junto a los depósitos.]**
- **INGENIERÍA:** «El hospital acaba de pasar a reserva. Su generador sólo aguantará unas horas».
- **COMANDANCIA VIOLETA:** «Los archivos pueden esperar. Nadie en ese hospital puede hacerlo».

No mostrar aún al responsable del disparo ni una transmisión falsificada «perfecta». En capítulos posteriores se reconstruirá un **accidente compuesto de fallos y ocultamientos**, no un supervillano secreto.

## Escenario táctico inicial

**Mapa base propuesto:** 10×8, x=0…9, y=0…7; entorno industrial y de acceso hospitalario. Sin agua ni aeronaves controlables. Rutas de carretera hacia zona este; terreno industrial incendiado indicado antes de ejecutar una acción.

- **Inicio Violeta:** G05 Ingeniero en (1,3); otro G05 en (2,5); Guardia G01 en (1,5) y (2,2).
- **Subestación principal:** (4,3). **Conexión hospitalaria:** (6,5). **Punto de evacuación:** (8,5). **Archivo secundario:** (6,1).
- **Terreno bloqueado anunciado:** (5,3) y (5,4) por daños; conservar rutas alternativas de norte y sur. Usar únicamente terreno legal según motor real; un bloque visual debe ser bloque físico.
- **Oponentes:** ninguno durante el rescate inicial. El desafío es recorrer/ocupar/recuperar posiciones bajo ventana temporal, **no inventar una facción enemiga**. La presión posterior puede venir de patrullas militares en C04.
- **Límite propuesto:** 12 turnos para mantener el hospital operativo y permitir evacuación. Debe avisarse desde el briefing; calibrar después de simular con MOV real.

**Objetivo principal:** con G05, asegurar/reparar subestación y enlace hospitalario en ese orden o con caminos alternativos; después mantener libre el corredor hasta el punto de evacuación durante la verificación final. **Condición de derrota:** hospital pierde suministro por tiempo agotado, o todos los ingenieros quedan incapacitados. Las bajas del relato son consecuencias trágicas, pero no se muestran escenas gráficas ni se premia atacarlas.

**Objetivos secundarios opcionales:** rescatar registros del archivo (C02 ya detectó discrepancias) y conservar dos o más escuadras de trabajo. El jugador bien organizado puede alcanzar ambos; si no, elegir salvar el hospital sigue siendo una victoria completa. La prueba recuperada sirve de indicio temprano de `transparency`, no garantiza un final bueno ni desbloquea unidades mejores.

**Dependencias técnicas:** G05 debe disponer de acción de reparación/recuperación con coste de movimiento/acción y objetivos multi-paso. La primera versión de prueba puede representar `repair_site` como operación de escenario ligada a ocupación de casilla, **pero jamás afirmar que la habilidad general de ingenieros ya está programada**. Los marcadores de incendio y el contador no deben provocar daño invisible ni muerte súbita no anunciada.

## Eventos de batalla

### B — Primera reparación

**Condición:** primer nodo restaurado; evento una vez.

- **INGENIERÍA:** «Tenemos potencia auxiliar, pero los canales de registro siguen desfasados».
- **COMANDANCIA VIOLETA:** «Prioridad absoluta al hospital».
- **INGENIERÍA:** «Si desviamos las cuadrillas al archivo perderemos minutos».
- **COMANDANCIA VIOLETA:** «Entonces la decisión es visible: salvamos personas primero. Si queda tiempo, también salvaremos pruebas».

### C — A cinco turnos del límite

**Condición:** el contador de misión muestra cinco turnos restantes, si hay progreso activo.

- **CONTROL:** «Cinco turnos antes del cierre de emergencia. La ruta sur sigue disponible».
- **COMANDANCIA VIOLETA:** «No busquen culpables por radio. Abran esa carretera».

No se introducen refuerzos inesperados ni se oculta el objetivo real. Si se pierde una ruta, el jugador debe haber visto por qué.

### D — Archivo secundario recuperado (opcional)

- **INGENIERÍA:** «Los archivos locales hablan de una interferencia anterior a la explosión».
- **COMANDANCIA VIOLETA:** «Guárdenlos en dos copias. Una para nosotros, otra para quien todavía quiera escuchar».
- **CONTROL:** «Ya hay fuerzas movilizándose hacia el corredor».
- **COMANDANCIA VIOLETA:** «¿Para ayudarnos?».
- **CONTROL:** «No lo han aclarado».

**Información honesta:** un registro anterior a la explosión no demuestra por sí mismo un ataque intencional ni la inocencia de una facción.

## Epílogo: primera fractura

*La luz vuelve al hospital. Un convoy civil atraviesa el corredor reconstruido. Detrás, en el horizonte, se encienden luces de vehículos militares.*

- **INGENIERÍA:** «La red vuelve a funcionar en este sector».
- **COMANDANCIA VIOLETA:** «Entonces ¿por qué nadie puede ponerse de acuerdo en qué ocurrió?».
- **CONTROL:** «Dos capitales han emitido comunicados. Cada una afirma que la otra disparó primero».
- **COMANDANCIA VIOLETA:** «Diles que nuestros equipos todavía están dentro. Que no hagan de este lugar una frontera».

**Flags propuestos:** `c03_hospital_operativo`, `c03_archivo_salvado` (opcional), `c03_ruta_evacuacion_abierta`. El resultado de rescate afecta recuerdos/diálogos y variables de integridad/transparencia; jamás cambia el balance permanente de facción ni las reglas de online.

**Enlace C04:** la perspectiva pasa al **Pacto Escarlata**, que ha perdido una patrulla y debe recuperar un convoy del mismo corredor. Se introducirá G04 Rompedor como contramedida antiblindaje y se demostrará cómo una noticia parcial puede parecer prueba concluyente para quien está aislado.

## QA y aceptación narrativa

1. G05 Ingeniero se desbloquea en C03 y tiene un rol diferente de Guardia: reparar/recuperar instalaciones bajo coste de acciones.
2. El capítulo nunca obliga a disparar contra civiles ni presenta una facción secreta; los protagonistas preservan sus retratos/emblemas oficiales.
3. Todos los objetivos tienen estado y plazo visible; el camino a hospital y archivo es legal antes de elegir ruta.
4. Reparación y captura de instalaciones deben distinguirse: sólo la infantería puede capturar; el ingeniero usa una habilidad especial limitada que cuesta turno/recursos.
5. Salvar archivo es opcional, no barrera para avanzar historia; guardar/cargar conserva estado de reparación y las flags sin repeticiones.
6. Sin desvelar culpables; todos los detalles deben ser compatibles con el incidente complejo descrito en la biblia.
7. Cuando el motor soporte los objetivos, probar ruta rápida al hospital, ruta por archivo y fallos por plazo; que ninguna requiera conocer información invisible.
