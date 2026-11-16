# TARVOKA — v1.1: costo de oportunidad de Rompedor e Ingeniero

**16 noviembre 2026 UTC · PR #394 (DRAFT) · Ningún precio, nivel o habilidad modificado en juego oficial**

## Motivo y fuentes

El análisis de roles de combate detectó un contrajuego antiblindaje insuficiente y la ausencia de reparaciones de campo en el catálogo vigente. El experimento RoleSpecializationV08.gd dispone ahora de ataques especializados sobre copia del estado y de una reparación optativa que consume créditos y acción.

**Verificación técnica previa:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43787490191 aprobó tres baterías: 8 suites de reglas por los dos bandos; matriz 32 roles × cuatro coberturas; 6 casos tácticos de rescate o remate. Esto **no** demuestra balance competitivo, únicamente funcionamiento del experimento.

## Comparación nueva: reemplazar o salvar al tanque

El archivo `tests/test_specialization_opportunity_cost_v11.gd` introduce una comparación controlada entre decisiones con el **mismo estado inicial y el mismo atacante enemigo**:

- El tanque aliado existente tiene 5 HP. Un tanque enemigo adyacente puede infligirle 6 HP en la siguiente fase en llanura.
- **Fabricar otro tanque cuesta 750 créditos** y lo coloca en la planta blindada amiga. La producción se realiza correctamente, pero **no salva** automáticamente al tanque antiguo situado en el frente; el nuevo tanque termina su fase de compra sin acciones.
- **Reparar con un Ingeniero ya desplegado** en la casilla adyacente cuesta 60 créditos y restaura 2 HP. En el ejemplo, el tanque antiguo pasa de 5→7 HP y sobrevive al siguiente ataque con 1 HP.
- En otro ensayo, se fabrica una Guardia por 200 créditos en la fábrica de infantería y el Ingeniero desplegado repara por 60 en la misma fase, consumiendo **260 créditos de distintas acciones**. Fabricar otra unidad en esa misma fábrica **durante la misma fase** está prohibido.
- Comprar un Ingeniero nuevo por 250 créditos en la fábrica no le permite reparar **inmediatamente** a un tanque que está lejos; tiene que acercarse primero y sigue sujeto a disponibilidad, capacidad de acción y supervivencia.

No se concluye que reparar siempre gane a comprar: la nueva unidad **persiste** tras el combate y podría ser mejor para otras batallas, mientras que el tanque salvado conserva una condición crítica, consumo de munición y riesgo futuro. Los costes de la inversión original en el tanque e Ingeniero también importan.

## Comparación de costo de reparación por vida

El módulo `scripts/experiments/SpecializationEconomicsV11.gd` calcula cotizaciones de 9 vehículos terrestres compatibles × 2 estados de daño × 2 paquetes × Ingeniero ya desplegado o no: **72 escenarios analíticos**.

| Caso concreto | Precio | Vida máxima | Valor observado |
|---|---:|---:|---|
| Tanque nuevo | 750 | 14 | 53,57 créditos por punto de HP inicial |
| APC nuevo | 300 | 11 | 27,27 créditos por HP inicial |
| Reparación ligera | 60 | Hasta 2 HP | 30 créditos por HP si aprovecha ambos |
| Reparación de campo | 100 | Hasta 3 HP | 33,33 créditos por HP si aprovecha los tres |
| Ingeniero nuevo | 250 | 7 | Compra previa necesaria si no hay uno en el frente |

*El coste/HP es una métrica de referencia, no un precio por equivalente táctico.* Si un tanque tiene solo 1 HP perdido, pagar 100 por el paquete de campo recupera **solo 1 HP** (100 créditos/HP efectivo). Si un APC requiere un Ingeniero nuevo, la primera reparación ligera cuesta 250+60=310 créditos de inversión inicial, **más que un APC nuevo de 300**; la conveniencia real depende de dónde están las unidades, cuántas veces se repara y la restricción de producción.

## Contrajuego antiblindaje vs comprar otro Rompedor

Rompedor base = 300 créditos, 8 HP, ATQ 4, DEF 0, 4 municiones. Tanque = 750 créditos, 14 HP, ATQ 8, DEF 2.

| Contra tanque intacto en llano | Sin bono | +2 ATQ específico | +3 ATQ específico |
|---|---:|---:|---:|
| Daño por ataque inicial | 2 | 4 | 5 |
| Golpes teóricos para destruir 14 HP | 7 | 4 | 3 |

**Advertencia crucial:** son golpes teóricos con daño constante. El Rompedor tiene solo **4 municiones** por recarga y un tanque puede responder; nadie ha probado que un solo Rompedor sin apoyo sobreviva siete, cuatro o tres impactos. Las bonificaciones no se aplican a infantería, aeronaves ni buques y no se mantienen como aumento permanente de ATQ.

Para medir inversiones futuras de edificios, el ensayo compara **hipótesis** de precio de tecnología global de **300 y 600 créditos** frente a gastar esa cantidad en unidades base de 300 créditos: a 600 créditos se podrían adquirir **dos Rompedores** si hay dinero, instalaciones libres y suficientes turnos de producción. Una mejora global, por el contrario, podría beneficiar a varios Rompedores ya desplegados; eso puede cambiar el resultado al avanzar una instalación de nivel II o III. **No se han aprobado precios de tecnologías** ni instalado desbloqueos en el juego comercial.

La prueba analítica examina 9 objetivos blindados × 3 bonos × 3 tamaños de destacamento (1, 2, 4) × 2 precios hipotéticos = **162 escenarios**, y calcula diferencias de daño inicial y umbrales teóricos de golpes necesarios.

## Pruebas reproducibles y límites

El archivo `tests/test_specialization_opportunity_cost_v11.gd` ejecuta ocho suites por grupos: dos bandos con tres situaciones de compra/reparación cada uno, y dos cuadrículas de 72 y 162 escenarios. La ejecución deberá comprobar costes de producción reales, límites por fábrica y turno, compra+reparación simultáneas, escasez de dinero, ahorro de un tanque herido y que el estado original no se altera. También valida guardados y rechazos.

**Godot 4.3 SUCCESS y PASS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43787651014. Se ejecutaron las cuatro etapas del workflow `.github/workflows/role-specialization-v08.yml`, incluida la prueba nueva de ocho suites de costo de oportunidad, con la versión de script registrada en ese commit. La refactorización posterior del `preload` del arsenal no alteró fórmulas ni decisiones de los ensayos.

Resultados del laboratorio: **72 cotizaciones de reparación**, de las cuales **8 requieren una inversión inicial superior al costo de reemplazar el vehículo** si aún no se posee Ingeniero; **162 hipótesis de antiblindaje**, ambas facciones con casos de compra, reparación, restricciones presupuestarias y competencia por un turno de fábrica. Los ataques y reparaciones son ejecutados sobre el estado real por `BattleSession` o por la envoltura optativa; el análisis de tecnología global es hipotético, no un mecanismo activo de compra.

**Sin cambios en:** BattleSession, Combat, UrbanEconomy, BasicAI, producción del APK, SaveCodec, facciones ni niveles de edificios. Las nuevas clases son herramientas de análisis en scripts/experiments.

## Próxima decisión de diseño

Si las baterías pasan, el siguiente trabajo debería medir un enfrentamiento de varias fases en el que la IA tenga que elegir entre fabricar, reparar, reabastecer y capturar bajo presupuesto fijo. Después se pueden estudiar mejoras globales comprables desde la planta blindada y los niveles de edificios I–III, sin sustituir el coste de producción por habilidades gratuitas o aplicar el buff a unidades ajenas a la tecnología.


## Hallazgos decisivos de sensibilidad y política candidata

La ejecución contrastada de las 32 clases × 4 coberturas (128 configuraciones de objetivo, 64 con ataque válido del Rompedor) registró **36 escenarios antivehículo**. La bonificación **+2** reduce el número teórico de ataques necesarios para eliminar la unidad en **30** de esos escenarios. **+3** reduce el número en **33**, pero además convierte **2** ataques antes no letales en bajas directas de un solo golpe. Son observaciones de *posiciones/HP constantes*; no incluyen cambios de reacción o IA multiturmo.

**Elección de investigación, no aprobación de balance:** estudiar +2 como primera candidata de contrajuego antiblindaje y mantener +3 como límite de potencia a someter a más pruebas. No activar aún ninguna: un Rompedor de 300 créditos con +3 podría destruir de un solo golpe plataformas con 0 defensa y poca vida en ciertas coberturas. El cambio tampoco arregla que un Rompedor pueda morir de un golpe de un tanque completo en campo abierto.

En reparación, el paquete ligero **60/2 = 30 créditos por HP** es más eficiente por HP que el de campo **100/3 ≈ 33,33**, siempre que aprovechen toda su curación. Pero el de campo puede superar un umbral de supervivencia puntual. No considerar la diferencia de precio como única variable: importa el Ingeniero ya desplegado, el turno que no dispara, la casilla, las municiones y la existencia de la fábrica.

**Decisión:** mantener el experimento en PR borrador y comparar en la siguiente fase IA de varias rondas y compras de tecnologías de edificio nivel II/III antes de definir precio definitivo o integrarlo.
