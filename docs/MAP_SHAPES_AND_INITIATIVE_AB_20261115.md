# TARVOKA — Estudio A/B: formas de mapa y ventaja de iniciativa (15-11-2026)

## Hipótesis
La variedad **estructural** de los mapas —rutas alternativas, cuellos de botella, montañas, cobertura, agua y accesos a objetivos— podría alterar la ventaja de quien juega primero sin modificar estadísticas. Sin embargo, **diversidad no equivale a justicia**: un sesgo del reloj de turnos o un ataque inicial dominante puede repetirse en todos los mapas. Un promedio equilibrado también puede esconder un mapa injusto.

## Estado del producto
- Cuatro mapas predeterminados: campo abierto, bosque de dos rutas, puentes y costa.
- Escaramuza aleatoria reproducible con semillas, tamaños 10×8 / 24×18 / 40×30; los cambios actuales son mayormente de celdas forestales, caminos y montañas, con topología acuática y posiciones estratégicas heredadas.
- Los mapas modernos usan ciudades y relés en coordenadas establecidas; la IA y guardados dependen de su validez. Cambiar los resultados de `seeded_terrain` para una semilla ya usada **rompería la integridad de partidas guardadas**. No se hace aquí.

## Experimento inicial (solo prueba, no mapas seleccionables)

`tests/test_map_shape_first_turn_study.gd` ejecuta **56 partidas de IA real**:
- Siete geometrías: cuatro actuales y tres prototipos nuevos **solo en la prueba**: `alturas_corredores`, `lagunas_centrales`, `bosques_cruzados`.
- Cada geometría se ejecuta con niebla activada y desactivada, alternando el bando iniciador. Cada condición se compara **con/sin restricción de tres órdenes en el primer turno**.
- La dificultad, IA, facciones, unidades, precios y condiciones de victoria son idénticas entre condiciones; los mapas se reflejan horizontalmente.
- Se validan geometría 10×8, accesos espejo a ciudades y relés, instalaciones transitables, economía y guardado/carga.
- Registra por escenario y condición: victorias del primero, victorias del segundo, partidas sin ganador después de 56 fases (no etiquetar como empate definitivo), turnos, acciones, créditos y marcador.
- **No** se impone que gane el 50 %: un resultado sería diagnóstico, no una razón para manipular los valores hasta lograr un indicador.

## Condiciones de publicación de nuevas formas
1. No bloquear a una facción fuera de ciudades, relés o centros de producción; proteger instalaciones aéreas/navales y movilidad conforme al dominio.
2. Igualar distancias estratégicas desde ambas bases en mapas competitivos simétricos; si hay asimetría deliberada, usar spawn invertido y test A/B independiente.
3. Registrar caminos alternativos, cuellos de botella, exposición al bombardeo, defensa por altura y tiempos para capturar objetivos; no basta con una paleta de biomas diferente.
4. **Separar** el costo de los cambios topológicos de la limitación de tres órdenes, la niebla y la elección de facción. Evitar que un mapa favorable compense silenciosamente otro injusto.
5. Medir mapas **grandes** y ejércitos más amplios antes de redefinir la apertura: tres órdenes es un valor de prototipo.
6. Mantener semillas históricas intactas. Los mapas nuevos deben elegir un **formato/versionado de generación** propio o aparecer como mapas adicionales con IDs nuevos, con migración explícita del selector y los guardados.
7. Probar realmente en Android y con personas; partidos entre IA idénticas no demuestran entretenimiento ni justicia PvP.

## Decisión posterior a los resultados
Si los escenarios nuevos bajan el sesgo por iniciador en varias categorías, ampliar el generador con topologías versionadas, no sustituir las semillas actuales. Si no lo bajan, investigar causas estructurales (primer ataque/compra, renta urbana, unidades iniciales, puntuación y turno) sin abandonar la diversidad como objetivo de diseño. Cada forma debería ofrecer rutas o estrategias alternativas reales.

## Resultado medido en CI de Godot 4.3

Ejecución: https://github.com/edwinrodri12/Tarvoka/actions/runs/43691083929 — **SUCCESS**, test PASÓ, 56/56 partidas terminadas antes del límite de 56 fases. Mismo motor/IA, 7 mapas × 2 nieblas × 2 iniciadores × 2 reglas de apertura; **n=4 encuentros por mapa en cada regla**.

| Forma | Quien inicia gana, apertura SIN límite | Quien inicia gana, apertura con 3 órdenes |
|---|---:|---:|
| Campo abierto | 2/4 | 2/4 |
| Bosque de dos rutas | 4/4 | 2/4 |
| Puentes | 4/4 | 0/4 |
| Costa | 2/4 | 0/4 |
| Alturas y corredores (prototipo) | 4/4 | 0/4 |
| Lagunas centrales (prototipo) | 4/4 | 2/4 |
| Bosques cruzados (prototipo) | 0/4 | 2/4 |
| **TOTAL** | **20/28 (71,4%)** | **8/28 (28,6%)** |

**Lectura:** El mapa influye claramente en quién gana según el modelo de IA probado; **la diversidad no neutralizó globalmente** la ventaja del inicio sin límite (20/28). La regla experimental de solo 3 órdenes aparentemente **sobrecompensa** en esta cohorte, favoreciendo al segundo (20/28). Los resultados por geometría van desde 0/4 a 4/4: **no hay una única configuración justa para todos los mapas** con la evidencia disponible.

**Límites:** n=4 por combinación de forma/regla es muy pequeño; agentes de IA deterministas con una formación inicial y reglas de relés; no se han medido jugadores humanos, 8 facciones con poderes activos, tamaño de mapa 24×18/40×30 ni más composiciones. No extrapolar porcentajes a PvP. Las siete geometrías son simétricas y los prototipos no aparecen en el selector jugable.

**Decisión:** no modificar todavía la apertura global ni elegir automáticamente un límite por mapa. Siguiente ensayo: mapas más grandes, bases/ciudades y objetivos distribuidos de formas diferentes, varias aperturas/ejércitos y pruebas con participantes humanos; preservar semillas antiguas.
