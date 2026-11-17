# TARVOKA — Diseño acordado de campamentos, infantería y recuperación

**17 de noviembre de 2026 — Especificación funcional para implementación FUTURA.**
No es una afirmación de que las mecánicas ya estén programadas. Debe preservarse el juego y sus guardados existentes; la rama experimental v2.2 se dedica al balance de desbloqueo de blindados.

## Niveles del Cuartel de Infantería (diseño)

- **Nivel I**: Guardia (infantería normal) + Rompedor (bazuca). No construyen campamentos.
- **Nivel II**: Francotirador/observador avanzado + Ingeniero. Desbloquean puesto de reconocimiento y fortificación defensiva.
- **Nivel III**: Especialista logístico + Médico de campaña. Desbloquean puesto de suministros y puesto médico.
- **Comando de operaciones especiales**: opción adicional de especialización del mismo cuartel en nivel III, sin edificio de entrenamiento exclusivo; requisitos, sabotaje y límite siguen pendientes de confirmar y medir.
- El nivel del edificio **NO equivale** al nivel personal de experiencia/veteranía.
- **Riesgo de migración**: el catálogo presente todavía tiene `scout`/Rastreador como clase inicial; no eliminarla ni alterar guardados antes de fijar conversión/homologación.

## Campamentos — cuatro tipos, un constructor específico por tipo

| Tipo | Constructor | Efecto | Activación |
|---|---|---|---|
| Reconocimiento | Francotirador | Visibilidad fija de territorio alrededor; sin arma ni daño | No es necesario que haya unidad sobre él; visibilidad solo mientras esté activo/controlado |
| Defensivo | Ingeniero | Bonificación a la unidad que ocupa la casilla; **+2 defensa infantería, +1 vehículos terrestres** como valores candidatos | Solamente para la unidad encima, nunca unidades cercanas |
| Suministros | Especialista logístico | Recarga munición/combustible con coste; máximo una unidad atendida por casilla y periodo | **La unidad debe ponerse ENCIMA** del campamento y finalizar allí el turno |
| Médico | Médico de campaña | Recupera vida de **infantería**, nunca vehículos, con coste; candidato **+2 HP / 40 créditos** por turno | **La unidad debe ponerse ENCIMA** del campamento y finalizar allí el turno |

Reglas compartidas: campamentos **son las únicas estructuras construibles durante batalla**; no fabrican unidades, no generan ingresos, no se instalan sobre ciudades/bases fijas ni se apilan. El constructor sobrevive y puede abandonar su campamento, el cual sigue existiendo. Construir consume acción y créditos. Una casilla campamento no bloquea el movimiento; comparte su posición con exactamente una unidad terrestre a la vez, conforme a la regla ya aprobada de no terminar dos unidades en una misma casilla. Pueden ser destruidos; hay que resolver su HP/destrucción y control al programarlos. No curar o abastecer automáticamente a las unidades alrededor.

**Límite provisional por ejército** en mapas 10×8 / 24×18 / 40×30: 2 / 4 / 6 campamentos TOTAL, no de cada tipo (sujeto a juego y pruebas).

## Funciones propias del especialista fuera del campamento

- Francotirador: daño especializado contra soldados, alcance candidato 2–3, sin contraataque adyacente y sin daño contra blindados, aviones o barcos. Para evitar daño mínimo obligado, implementar **inmunidad por dominio/categoría de objetivo**, no reducir a ataque 1 si el motor sigue forzando 1 de daño. El campamento permanente da visión; el soldado móvil hace disparos.
- Ingeniero: reparar un vehículo aliado adyacente **pagando créditos** y consumiendo acción; precio/HP candidato +2 HP / 60 créditos, ya examinado previamente en el laboratorio `RoleSpecializationV08`. No reparar ni curar gratis.
- Logístico: reabastecimiento limitado de **una unidad adyacente por acción** durante una ofensiva, con coste. El campamento permite abastecer al ocupante con mayor eficiencia, no reabastece un radio.
- Médico: sanar una infantería aliada adyacente en movimiento, candidato +1 HP por acción; el campamento sana al ocupante más rápido, con coste, no un radio.
- Fortificación no dispara automáticamente ni genera una torreta. El bono defensivo solo funciona sobre ella, no se apila indiscriminadamente con terreno. Propuesta provisional techo de protección combinado 3, pendiente de medir y decidir.
- Los logísticos/médicos/ingenieros/Francotiradores no desaparecen tras construir.

## Valores actuales de la base y nuevas cifras: NO confundir

`SpecialistCampsV17.gd` prototipo: `recon` cuesta 100 y constructor `scout`, `defense` cuesta 130 e Ingeniero, `supply` cuesta 150 y constructor `quartermaster` todavía no implementado, `medical` cuesta 140 y constructor `field_medic` todavía no implementado. Las propiedades de curación/protección/reabastecimiento están **etiquetadas como futuras**; en V19 aún no ejecutan esos efectos completos.

Las decisiones de esta ficha **SUSTITUYEN** el concepto anterior de campamentos médicos/logísticos con beneficio de área y la especialización del Rastreador ordinario como constructor. Los precios, alcance, defensa y costes de recuperación son **candidatos de balance**, no ajustes finales. La incorporación debe migrar o reemplazar el prototipo V17 cuidadosamente con pruebas específicas de legalidad, créditos, ocupación, niebla, captura, destruccción y guardados.

## No hacer todavía
No cambiar el catálogo oficial, el APK, `BattleSession`, `ModernArsenal`, `SaveCodec` o los niveles de edificios durante la auditoría de acceso a tanques. Primero terminar resultados v2.2. La mecánica individual de campamentos se implementará en experimento separado y se probará antes de integrar.
