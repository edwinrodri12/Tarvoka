# TARVOKA — Capítulo 02: DOS MINUTOS DE SILENCIO

**Acto I**, misión C02 · **Control:** Orden Ónix · **Desbloquea:** G03 Rastreador (nivel I) · **Estado:** guion y escenario propuestos; no jugable todavía.  
Continúa directamente [STORY_CHAPTER_01.md](STORY_CHAPTER_01.md). Preparación del incidente del [capítulo 03](STORY_CHAPTER_03.md).

## Logline y pregunta dramática

Tras el ejercicio conjunto del corredor de Arven, el sistema de registros de Meridian muestra un vacío de **dos minutos**. Un equipo de Orden Ónix debe verificar los repetidores antes de que el centro de control archive el dato como una falla rutinaria. **¿Qué se puede afirmar cuando la información es incompleta?** No hay villano escondido ni ataque intencional revelado.

**Lección táctica:** G03 Rastreador, visión limitada, niebla de guerra honesta, localización y extracción. La misión no premia destruir soldados que sólo custodian instalaciones: el juego muestra que el objetivo es información, no eliminación.

## Escena de apertura

Narración breve: *Un informe rutinario llega a una división de inteligencia. La transmisión contiene algo extraño: el mismo convoy aparece entrando al corredor una vez, saliendo dos veces y desapareciendo de las grabaciones durante dos minutos.*

- **COMANDANTE ÓNIX:** «¿Dónde están los registros originales?».
- **ANALISTA:** «El nodo auxiliar asegura que no dejó de transmitir».
- **COMANDANTE ÓNIX:** «Eso no responde a la pregunta».
- **ANALISTA:** «Nos piden cerrar el incidente como un error de reloj».
- **COMANDANTE ÓNIX:** «Nadie se moviliza por un reloj. Pero una guerra sí puede empezar por un informe firmado demasiado pronto».

**Instrucción inicial:** «Explora la zona con Rastreador. Tu visión termina donde termina la línea de detección. No supongas que lo que no ves está vacío».

## Tablero de diseño y misión

**Mapa de prototipo:** 10×8, x=0…9, y=0…7, corredor de estaciones periféricas. G03 en (1,3) y (1,5), Guardia G01 de escolta en (2,4). Dos repetidores objetivos en (5,1) y (7,5); extracción en (1,4). Rutas por bosque (más ocultas, más lentas si el motor lo establece) y carretera expuesta. Sin dominio marítimo, aéreo ni unidad nueva aparte de G03.

**Reglas de escenario:**
- Niebla activa, exploración persistente sólo de casillas visitadas y últimas posiciones detectadas, sin enemigo oculto revelado por UI.
- Las unidades visibles de seguridad del corredor se tratan como **contactos no hostiles** durante esta misión, no como enemigo obligatorio para una condición de exterminio. Evitar enfrentamientos por confusión de colores; usar un marcador visible y sin captura de la red como facción propia.
- **Objetivo principal:** confirmar físicamente los dos repetidores con al menos un Rastreador a una casilla o menos, y regresar al punto de extracción con uno vivo.
- **Presión:** ventana de diez turnos sugeridos; cualquier limitación por reloj debe mostrarse desde el briefing, nunca como sorpresa. Si se pierden ambos Rastreadores, derrota; si se agota el plazo, el equipo se retira con informe incompleto (desbloqueo de reintento, no bloqueo narrativo permanente).
- **Secundario:** conservar escolta G01 para evacuar a los exploradores; completar sin iniciar ataques.
- **Balance:** sin fuego enemigo letal en la primera introducción de niebla. El reto está en ruta/visibilidad/tiempo. No castigar al jugador por una información inaccesible.

**Dependencia:** requiere objetivo de reconocimiento y extracción con niebla y contactos neutrales. No debe construirse como sustituto improvisado sobre la victoria por eliminación del prototipo.

## Eventos y diálogo de batalla

**EVENTO A — primera casilla descubierta de la zona central (única vez):**
- **ANALISTA:** «Contactos en el oeste. No tenemos confirmación de hostilidad».
- **COMANDANTE ÓNIX:** «Entonces no son objetivos. Son personas de las que todavía no sabemos nada».

**EVENTO B — segundo repetidor confirmado:**
- **ANALISTA:** «Los relojes difieren. Hay dos minutos sin registro central, pero los equipos locales siguieron funcionando».
- **COMANDANTE ÓNIX:** «Conserva ambas copias. Quiero el origen, no una explicación cómoda».
- **ANALISTA:** «¿Informamos al consejo?».
- **COMANDANTE ÓNIX:** «Primero, comprobemos que no estamos equivocados».

**EVENTO C — extracción completada:**
- **ANALISTA:** «Mensaje prioritario: el Nudo Siete solicita técnicos. Hay inestabilidad en alimentación secundaria».
- **COMANDANTE ÓNIX:** «¿Es una emergencia?».
- **ANALISTA:** «Todavía no lo saben».

## Desenlace y continuidad

**Victoria:** `c02_registros_originales=true`, G03 nivel I desbloqueado para capítulos compatibles; expediente opcional muestra dos relojes con tiempos incongruentes. Orden Ónix decide **preservar la evidencia**, no usarla para atacar a otro estado.

**Retirada:** `c02_registros_incompletos=true` (sólo si el diseño admite avanzar con fallo), escena posterior informa de que faltan fragmentos. Los capítulos principales avanzan con recap; no esconder la verdad final detrás de una misión de tutorial perdida.

**Enlace C03:** la última comunicación anuncia que la situación del Nudo Siete ha pasado de anomalía informativa a fallo de infraestructura.

## Criterios de QA

1. Rostro y emblema de Orden Ónix oficiales; no cambiar colores de facción.
2. Al iniciar: G03 es el único nuevo desbloqueo; G01 se permite como clase previamente aprendida sin enseñarlo de nuevo.
3. Niebla/historial no revelan mapas, rutas ni unidades ocultas a IA o jugador.
4. La visión descubre información, nunca altera estadísticas de enemigos ocultos o crea ataque ilegal.
5. Dos objetivos y extracción requieren éxito; contactos neutrales no se presentan como enemigos para destruir.
6. Eventos únicos y persistentes en autosave; sin duplicación al cargar.
7. El incidente de C02 no determina culpables; pistas compatibles con la revelación posterior de Nudo Siete.
