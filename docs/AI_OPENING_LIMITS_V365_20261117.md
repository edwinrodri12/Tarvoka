# TARVOKA — estudio v3.6.5: número de órdenes iniciales e iniciativa

**18 de noviembre de 2026. Solo investigación y control de calidad. No integra código en `main` ni modifica el juego oficial.**

## Evidencia verificable

La [auditoría de 64 combates con dos relés simétricos](https://github.com/edwinrodri12/Tarvoka/actions/runs/44210609218) se completó con diez trabajos de CI correctos:

| Distribución | Azul | Rojo | Empieza | Responde |
|---|---:|---:|---:|---:|
| Norte (4,2) + (5,2) | 14 | 18 | 2 | 30 |
| Sur (4,5) + (5,5) | 16 | 16 | 8 | 24 |

**Conclusión limitada:** el diseño sur eliminó la asimetría *de color* en esta muestra, pero aún favorece excesivamente al jugador que responde. La distribución norte produce una desventaja de iniciativa mayor. No se debe aprobar ninguno de los dos diseños como definitivo.

## Hipótesis: límite de tres órdenes en la primera fase

`OpeningBalance.gd` define actualmente `MAX_FIRST_ORDERS=3` y admite estados válidos con límites entre 1 y 3. Aunque la regla ayuda a combatir el dominio del primer turno observado anteriormente, cuando la puntuación de relés ya se hace por ronda completa es posible que reduzca demasiado la libertad de quien empieza.

Este estudio mide las **tres configuraciones que el motor realmente admite**, sin modificarlo:

- **Límite 2:** se crea apertura equilibrada mediante `BattleSession.start(...,balanced_opening=true)` y se establece `opening.limit=2`, un estado válido para `OpeningBalance.valid`.
- **Límite 3:** comportamiento actual, íntegramente autoritativo, que sirve de referencia.
- **Sin límite:** modo clásico del motor `BattleSession.start(...,balanced_opening=false)`, sin campo `opening`.

No se prueban «4» ni «5» porque el motor no los admite hoy. No se inventan reglas de movimiento ni estados inválidos solo para mejorar una tasa de victorias.

## Batería de 96 partidas

Cada variante obtiene **32 partidas reales**: 2 mapas (Campo abierto y Puentes), niebla sí/no, 2 dificultades (10 y 12), alternancia del primer bando, dos políticas idénticas en ambos lados (v3.5 vs sí misma y v3.6.3 vs sí misma). En todas se mantiene:

- Dos relés simétricos **al sur**, (4,5) y (5,5).
- Puntuación de relés **solo al finalizar la ronda completa**.
- La misma economía, mismos 5 soldados por facción, misma IA, terreno, recursos, daños, capturas, reglas de suministros y victoria.
- Facciones y primer bando alternados sin bonos extra.

Los registros `OPEN365_MATCH` guardan el límite elegido, número de acciones efectivamente realizadas en apertura, causa de victoria, bandos, capturas y retiradas. El agregador exige **exactamente 96** combinaciones únicas; verifica que ninguna partida de límite 2/3 exceda las órdenes y que las 32 partidas con límite 3 reproduzcan exactamente las **8 victorias de apertura** y el empate 16–16 de colores del ensayo anterior.

`tests/test_ai_opening_limits_contract_v365.gd` prueba seis configuraciones legales (dos posibles bandos iniciales por tres límites), movimientos reales de `Session.move`, denegación al exceder límite, guardado/carga y final de turno.

## Criterio de decisión

Primero evitar partidas inconclusas o errores técnicos. Después comparar **por separado** el equilibrio de iniciativa, por color, por mapa y por política, **no solo la media global**. Un resultado favorable en estos dos mapas no asegura equilibrio en otros mapas o frente a seres humanos.

Si eliminar el límite favorece demasiado al primero y 3 órdenes favorece al segundo, habrá indicios de que se necesita explorar formalmente una variante intermedia, con cambios propuestos y pruebas de compatibilidad **solo en otra rama**, antes de considerar modificar la regla del juego. Si la diferencia persiste aun sin límite, la siguiente hipótesis debe centrarse en capturas de relés, orden de acción y objetivos tácticos.

**Estado inicial:** resultados de v3.6.5 pendientes; la documentación no reemplaza las pruebas. PR en borrador, sin autorización automática de merge ni APK.
