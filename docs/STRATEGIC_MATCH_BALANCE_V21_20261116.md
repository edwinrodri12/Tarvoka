# TARVOKA — Auditoría de partidas estratégicas v2.1

**16 noviembre 2026 · [PR #458](https://github.com/edwinrodri12/Tarvoka/pull/458) (DRAFT) · Experimental y aislado de gameplay/APK.**

**CI Godot 4.3 SUCCESS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43903340050 — cuatro jobs verdes: smoke de tres mapas y 12 partidas espejo en cada escenario de mapa pequeño abierto, mediano abierto y mediano boscoso.

## Qué hicimos realmente

- `scripts/experiments/StrategicMatchBalanceV21.gd` ejecuta órdenes reales de `FixedSiteOrdersV19`/`CapturableProductionV18`/`BattleSession`. Los ejércitos se mueven hacia ciudades, bases y enemigos; disparan, contraatacan, compran unidades, capturan sitios tras dos fases propias y reciben ingresos reales. No se inventaron bajas ni victorias.
- Tres políticas deterministas: **expansión** prioriza captura e infantería/APC; **presión** compra asaltantes/rompedores y busca combates; **blindados** invierte preferentemente en tanques y unidades pesadas. Capturar bases puede abrir nuevas líneas de compra.
- Ejércitos iniciales idénticos y espejados: Guardia, Rastreador, Rompedor e Ingeniero por bando. Cada ejército inicia con **2.500 créditos**. IA limitada a **ocho decisiones tácticas más máximo una compra por media fase**, máximo 12 unidades vivas por bando: esas son **restricciones de la IA del ensayo**, NO nuevas reglas aprobadas del juego.
- Se comparan las tres parejas de estrategia por escenario: A/B y B/A, con iniciador de ambos colores: **12 partidas por escenario**, **36 partidas** en total. Cada estrategia aparece **ocho veces por escenario** y **24 veces en total**.
- Escenarios: 10×8 llanura con una ciudad propia/bando, dos neutrales y **250 créditos por ciudad**; 24×18 llanura y bosque, con dos ciudades propias/bando, ocho neutrales y **83 créditos por ciudad (166 iniciales por bando y turno)**. Límites de **42/52 medias fases**. Solo **dos bandos**, visión sin niebla y sin ventajas de comandante.
- El motor declara ganador cuando el estado `winner` real indica un bando. Cualquier partida sin ganador al límite se marca **censurada**, NO empate, victoria técnica ni victoria territorial.
- Cada ejecución valida **créditos finales = 2.500 + ingresos de ciudad − gastos de compra** por bando, capturas reales en sitios fijos, turnos, titulares y límites sin dinero artificial.

## Resultados comprobados

### Partidas decididas y duración

| Escenario | Partidas | Con vencedor real | Censuradas | Iniciador ganó entre decididas |
|---|---:|---:|---:|---:|
| 10×8 llanura (≤42 medias fases) | 12 | 12 | 0 | 6 |
| 24×18 llanura (≤52 medias fases) | 12 | 3 | 9 | 1 |
| 24×18 bosque (≤52 medias fases) | 12 | 3 | 9 | 1 |
| **Total** | **36** | **18** | **18** | **8** |

Los mapas medianos no demostraron un empate irreversible: **la mitad de las partidas de toda la muestra siguen sin decisión** al cortar el ensayo, concentradas en mapas medianos. El modelo de victoria es por eliminación militar, no por controlar un HQ o ganar puntos territoriales.

### Victorias por política y mapa

Cada cifra se refiere a **ocho apariciones** de esa política por escenario; las victorias de un mismo mapa suman las partidas decididas.

| Política | 10×8 ganadas | 24×18 abierto ganadas | 24×18 bosque ganadas | Ganadas total | Derrotas total | Censuradas entre sus 24 apariciones |
|---|---:|---:|---:|---:|---:|---:|
| Expansión | 4 | 0 | 0 | **4** | 8 | 12 |
| Presión | 1 | 2 | 2 | **5** | 8 | 11 |
| Blindados | 7 | 1 | 1 | **9** | 2 | 13 |

**Dato preciso del mapa pequeño:** expansión venció a presión en 3/4 partidas; blindados vencieron a expansión en 3/4; blindados vencieron a presión en **4/4**. No hay señal de ventaja del iniciador en las 12 partidas pequeñas (6/12).

**Cautela:** en mapas medianos hay demasiadas partidas censuradas para inferir un ranking competitivo. Tampoco tenemos múltiples semillas independientes o jugadores humanos.

### Efectos de estrategia sobre comportamiento y economía (agregado de 24 apariciones por política)

| Métrica | Expansión | Presión | Blindados |
|---|---:|---:|---:|
| Ataques ejecutados | 702 | 899 | 797 |
| Daño infligido | 1.895 | 3.628 | 3.531 |
| Unidades enemigas eliminadas | 209 | 393 | 431 |
| Desplazamientos legales | 1.658 | 1.989 | 2.264 |
| Unidades compradas | 441 | 401 | 438 |
| Créditos gastados en compras | 111.750 | 152.400 | 203.150 |
| Ingresos recibidos | 174.841 | 158.677 | 193.379 |
| Capturas de ciudades (incluye reconquistas) | 74 | 66 | 91 |
| Capturas de bases (incluye reconquistas) | 41 | 48 | 83 |
| Suma de unidades vivas al final de partidas | 53 | 138 | 187 |
| Suma de créditos finales | 123.091 | 66.277 | 50.229 |
| Medias fases jugadas por la política | 496 | 474 | 498 |

**Estas métricas suman exposiciones de longitud diferente y varios rivales; no interpretar números brutos como rendimientos causales.** Para comparación de intensidad se pueden dividir por medias fases activas: daño ~3,82/turno propio expansión, ~7,65 presión y ~7,09 blindados; eliminaciones ~0,42/turno expansión, ~0,83 presión, ~0,87 blindados. Esos promedios son descriptivos, no equivalencias de valor táctico o probabilidad de victoria.

### Por qué los blindados parecen dominar tanto

- El catálogo actual compra **tanque (14 HP / ataque 8 / defensa 2 / coste 750)** desde su planta sin imponer primero la evolución propuesta de nivel I→II. En este experimento, un tanque puede entrar desde los primeros turnos si el bando controla una planta blindada y dispone de fondos. **El coste de 650 créditos y un turno de fábrica para acceder a nivel II no interviene.**
- La misma política usa fábricas conquistadas para producir artillería, drones y helicópteros; no son 438 tanques. Entre sus 438 compras hay **112 tanques**, 88 asaltantes, 74 FPV, 62 artillerías y otras clases.
- Los Rompedores actuales carecen del +2 antiblindaje tecnológico en este ensayo; su enfrentamiento contra un tanque es favorable al tanque si no se coordina. El laboratorio v1.7 mostró que el efecto +2 varía mucho por cobertura.
- Los ingresos iniciales del mapa pequeño y el capital base pueden facilitar despliegues rápidos sin desbloqueos; una supuesta supremacía de ataque del tanque podría ser en realidad **supremacía de disponibilidad temprana**.

**Recomendación:** antes de modificar HP/ataque/defensa/coste del tanque, implementar una **variante experimental A/B con acceso de tanque exclusivamente después de invertir en nivel II**, manteniendo ambos jugadores en el mismo régimen en cada pareja y anotando el coste y la fase de desbloqueo. Como contraste añadir doctrina antiblindaje pagada en nivel III y unidad Ingeniero funcional. El objetivo es distinguir problemas de estadísticas, progresión, economía y comportamiento de IA.

### Qué no demuestra esta auditoría

- No simula los cuatro rangos individuales de XP ni las tecnologías pagadas **dentro de las partidas v2.1**. Esos sistemas están auditados en `IntegratedBalanceBattleV16` y `BuildingProgressionV12` por separado. No fusionar sus resultados como si fueran la misma partida.
- Los poderes de ocho facciones, precisión/ocultación, duraciones, redondeo porcentual y beneficios navales quedan en la auditoría aislada [v1.7](https://github.com/edwinrodri12/Tarvoka/pull/456) y no actuaron aquí.
- No implementa efectos funcionales de campamentos sobre combate; no hay clima dinámico, niebla, acuerdos entre ocho jugadores, ni batallas de 40×30 en esta ejecución.
- Se utilizó un escenario geométrico por familia con reglas deterministas y IA propia de laboratorio; no se probaron 36 semillas aleatorias independientes. No usar estas tasas de victoria para prometer balance comercial.
- Tampoco deben introducirse "partidas completas" como sinónimo de "todas con vencedor": **18 terminan por victoria y 18 quedan censuradas**.

## Siguiente trabajo numérico prioritario

1. **Comparación espejo de acceso inmediato versus desbloqueo de nivel II para tanque** (precio + retraso + unidades renunciadas) con 10×8 y 24×18; reproducir mismas condiciones, cap de unidades y acciones.
2. Repetir con **tecnología antiblindaje +2** en el bando que la paga y medir sobrevivencia verdadera de varios Rompedores coordinados, no golpes hipotéticos sin contraataque.
3. Incorporar experiencias de las 29 clases elegibles sin dejar que FPV/munición merodeadora/USV acumulen veteranía, y medir si la experiencia de las unidades sobrevivientes incrementa la brecha económica.
4. Medir en un nuevo A/B **victoria por conquista de HQ/objetivos** frente a eliminación total, sin cambiar la regla oficial hasta comprobar que las partidas medianas terminan con decisiones claras.
5. Extender a **40×30**, más semillas y niebla, y después evaluar 8 bandos cuando el motor real los soporte.

**Conclusión:** los blindados dominan el entorno pequeño observado, pero **es demasiado pronto para nerfear el tanque**; la hipótesis mejor soportada es una interacción entre disponibilidad inicial de unidades avanzadas, volumen de producción y calidad del avance ofensivo. En mapas medianos el problema principal detectado es **duración/censura de las partidas**.
