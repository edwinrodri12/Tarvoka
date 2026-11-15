# TARVOKA — Revisión integral de infantería y apoyos, sin duplicar reparaciones
Fecha: 15-11-2026 · **Auditoría de diseño y pruebas, no integración del juego**.

## Corrección respecto de la fase 05 inicial

La propuesta anterior de **Ingeniero +2 HP y coste 85 % proporcional (mínimo 20)** repite una funcionalidad **ya desarrollada** en la rama draft [PR #320](https://github.com/edwinrodri12/Tarvoka/pull/320). La propuesta duplicada **se retiró del código** en `scripts/experiments/BalanceProposalV05.gd` y de sus pruebas. **No fusionar ni incorporar esa segunda implementación**, ni asignar un segundo precio incompatible.

- **PR #320**: Ingeniero a pie repara chasis terrestres aliados adyacentes hasta **3 HP**, por **35 créditos/HP**; validación de turno, distancia, créditos, límites, niebla y UI Android en su rama; **no está fusionada en main**.
- **PR #323**, basada en #320: planificador IA para llevar Ingenieros hacia blindados dañados antes de repararlos. Incluye pruebas focalizadas, también draft.
- **EV-21, Vehículo de Ingeniería**: diseño de una unidad distinta previamente propuesto para reparación, fortificación, despeje de obstáculos y puentes. **No es una clase implementada ni comprable** de las 32 actuales: no agregarlo como segundo reparador por el momento.
- **VL-22 / Vehículo Logístico existente** (rol `logistics`): **sí funciona** con inventarios finitos para **municiones y combustible**, no repara HP en `main`; precio **300**, sin ataque. Su descripción de «reparación pendiente» no implica que la reparación ya exista.
- **Centro de Reparación y Mantenimiento**: definido antes como instalación especializada en recuperar vehículos estacionados; no es una acción de reparación HP implementada en los productores de `UrbanEconomy` actual.

**Criterio de no duplicación:** conservar **un solo propietario de la reparación de HP de campo**. Aprovechar y medir PR #320/#323 antes de decidir si el Ingeniero a pie debe permanecer como reparador o si el diseño EV-21 debe reemplazarlo. El vehículo logístico conserva exclusivamente munición/combustible. Si un taller fijo llega a existir, tendría la ventaja posicional de curar plataformas en base, con costo de tiempo y fondos, no competir con una reparación instantánea móvil. Fortificación, minas y puentes deben ser mecánicas distintas y costeadas; no regalarlas simultáneamente al Ingeniero y al EV-21.

## Las siete clases de soldados actuales, juntas

Verificado con `UnitRoles`, `ModernArsenal`, `UrbanEconomy`, `Logistics` y `CombatDoctrine` de `main`. **Los números son base actual, NO cambios propuestos**.

| Soldado | Costo | HP | Ataque | Defensa | Movimiento | Visión | Alcance | Captura en main | Función a proteger |
|---|---:|---:|---:|---:|---:|---:|---|---|---|
| Guardia (`line`) | 200 | 10 | 5 | 0 | 3 | 3 | 1 | Sí | Infantería estándar barata y resistente; captura |
| Rastreador (`scout`) | 150 | 6 | 2 | 0 | 4 | **5** | 1 | Sí | Exploración/niebla, captura rápida, contrarresta Lanzador (+3 ATQ) |
| Asaltante (`assault`) | 250 | 9 | 5 | 0 | 3 | 3 | 1 | Sí | Toma ciudades, pero **sin ventaja urbana implementada en main**: está numéricamente eclipsado por Guardia |
| Rompedor (`piercer`) | 300 | 8 | 4 | 0 | 3 | 3 | 1 | **No** | Antiblindaje (+4 contra Baluarte en main); bono +2 contra tanque existe **solo** en draft #328 |
| Baluarte (`bulwark`) | 350 | 12 | 3 | **2** | 2 | 3 | 1 | No | Infantería defensiva, aguanta línea, contrajuego con Rompedor |
| Lanzador (`artillery`) | 400 | 7 | **6** | 0 | 2 | 3 | **2 solamente** | No | Fuego indirecto de apoyo, sin disparo a adyacentes ni contraataque |
| Ingeniero (`engineer`) | 250 | 7 | 2 | 0 | 2 | 3 | 1 | Sí | Captura y posible soporte; reparaciones +3 HP/35 cr por HP **en #320**, no en main |

Todos los siete soldados tienen munición y no gastan combustible. El Vehículo Logístico tiene combustible, cargamento de municiones y combustible, y no puede capturar.

### Tres inconsistencias de diseño que sí debemos resolver

1. **Asaltante vs Guardia:** pagar 250 por Asaltante frente a 200 por Guardia y contar con un HP menos es difícil de justificar si comparten ataque, movimiento, captura y alcance. **Conservar** la propuesta de Asaltante que ignora solo **+1 cobertura urbana** al atacar una unidad terrestre en ciudad. PR #384 mantiene ese experimento aislado: en 30 situaciones urbanas, 24 mejoraron +1 daño, 6 no cambiaron; otros soldados y ataques fuera de ciudad no reciben la habilidad. Falta comprobar jugabilidad con decisiones de asedio.
2. **Infantería y captura:** `main` permite captura a Guardia, Rastreador, Asaltante e Ingeniero, **no a Rompedor**. Draft [PR #156](https://github.com/edwinrodri12/Tarvoka/pull/156) ya propone corregir Rompedor como capturador. Se debe decidir por doctrina si **todos los soldados que ocupan a pie** capturan (Baluarte y Lanzador también) o si solo infantería apta para ocupar. La regla «solo infantería captura» **no resuelve por sí sola** quién de esos siete captura. Recomendar revisión por rol en vez de habilitar arbitrariamente todos.
3. **Rompedor y protección pesada:** en `main` el bono contra Baluarte sí funciona, pero la utilidad contra tanque G09 es menor. Draft [PR #328](https://github.com/edwinrodri12/Tarvoka/pull/328) ya añade **+2 ATQ solo contra tanque**, sin alterar fuerza contra infantería, y draft [PR #333](https://github.com/edwinrodri12/Tarvoka/pull/333) ajusta la compra IA al contrajuego blindado. No crear otro bono paralelo en #384 ni declarar estos cambios fusionados. La función de escudos y línea defensiva del Baluarte debe conservar un contrajuego visible, no convertirse en un tanque económico sin restricciones.

## P1 / P3 todavía válidas de la fase 05

- **P1 Asaltante urbano:** solo ataque contra unidad terrestre en ciudad ignora su cobertura urbana +1; no da bonus permanente ni afecta montaña/bosque, air/naval, daño defensivo o soldados de otros roles.
- **P3 Reclutamiento IA por función realmente operativa:** priorizar amenazas observadas y objetivos; con 500 créditos en base aérea, **ahorrar** frente a comprar un helicóptero de transporte cuyo embarque aún no funciona. **No reclutar Ingeniero como reparador en la rama experimental basada en main**: la acción real está solo en PR #320. Una vez se integre esa mecánica deberá compararse con el planificador existente #323, no reinventarlo.
- **Resultado comprobado de P1/P3 tras retiro de P2:** [Godot Actions #43735933669 — SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43735933669): **40** situaciones de Asaltante (30 ciudades, 10 fuera), **60** elecciones IA A/B, **7** soldados auditados (HP/costo/ataque/movilidad/visión/munición/captura), logística distinguida, y **2** pruebas de niebla. Fueron **30** decisiones diferentes de compra; 10 retenciones de fondos en los escenarios examinados.

## Próximas pruebas antes de decidir el catálogo final

- Tomar como base la rama **PR #320 + #323** de reparación de Ingeniero y estudiar si el reparador realmente se compra, se posiciona bien y aporta valor en partidas largas. No cambiar su HP por acción ni costo mientras se superponen las pruebas.
- Medir captura e ingreso de las **cuatro clases que hoy capturan** y el caso de Rompedor de PR #156: evitar que el Rastreador barato/rápido monopolice la economía y desplace otros soldados. Medir roles por **costo total + utilidad táctica**, no DPS aislado.
- Asegurar identidad útil para **Baluarte** (posición y cobertura) y **Lanzador** (ataque indirecto, vulnerable a flancos) con terreno/contraataque/suministros, sin habilidades mágicas acumulativas.
- Evaluar las ramas apiladas de transporte: [PR #335 APC, 2 pasajeros](https://github.com/edwinrodri12/Tarvoka/pull/335) y [PR #339 IFV, 1 pasajero](https://github.com/edwinrodri12/Tarvoka/pull/339), **todavía drafts**. Cambian mucho el valor de infantería y la captura rápida de ciudades, por lo que deben entrar en el análisis antes de ajustar precios definitivos.
- Mantener separado el sistema de **suministros vs HP**, diseño comercial de EV-21/taller y multijugador de ocho (pendiente). Ninguna habilidad conceptual se presentará como ejecutable hasta tener código y pruebas en una rama integrable.

## Estado de ramas

Este documento y `scripts/experiments/BalanceProposalV05.gd` son la **revisión corregida de PR #384**: el código experimental de reparación **fue retirado** y la nueva P1/P3 sigue en estado de prueba. No merge automático, no cambio en `main`, sin APK interactivo con estas habilidades.
