# TARVOKA — v3.7.5: diagnóstico de simetría en batallas completas

**18 de noviembre de 2026 (UTC).** Rama exclusiva de investigación. Este experimento **no modifica** `main`, la APK oficial, escenas, mallas 3D, valores de unidades, mapas ni el código de la IA.

## Antecedente verificado

[CI v3.7.4 #44234207399](https://github.com/edwinrodri12/Tarvoka/actions/runs/44234207399) aprobó 18/18 trabajos. En **192 aperturas auténticas de Godot 4.3**, las **576 decisiones de IA originales** coincidieron con sus equivalentes al reflejar horizontalmente el tablero, intercambiar facciones e IDs de unidades; también coincidieron al invertir el orden de la lista de unidades. **0 divergencias en apertura**, **0 diferencias de visión**, con 48 contratos de guardado y estado.

Ese resultado NO demuestra simetría del combate completo. En [v3.7.3 #44232803642](https://github.com/edwinrodri12/Tarvoka/actions/runs/44232803642), el mapa Puentes con cuatro relés laterales terminó 8-8 según iniciativa, **pero 16-0 según color**. Hay que identificar si el resultado nace durante capturas, unidades producidas, reglas de combate, decisiones tardías o transición de rondas, en lugar de conceder bonificaciones artificiales.

## Diseño v3.7.5 — 192 parejas de partidas completas

Cada pareja consta de **dos batallas auténticas e independientes** de Godot: una con la configuración original y otra con todos los elementos reflejados horizontalmente e intercambiadas facciones, propiedades, créditos, objetivos e IDs equivalentes. No se crea ninguna acción alternativa: las dos IA eligen y ejecutan de forma independiente las órdenes normales de `BasicAI.step` y `BattleSession`, hasta que una facción gane o se alcance el límite de 80 medias rondas o seis turnos consecutivos inactivos.

**384 batallas completas = 192 parejas =** cuatro mapas × niebla sí/no × nivel IA 10/12 × ambos primeros jugadores × políticas autocontroladas v3.5 o v3.6.3 × tres ubicaciones simétricas de cuatro relés: centro, accesos a puentes y flancos.

Todas las partidas conservan el límite oficial de **tres órdenes de primera fase**, ingresos iniciales simétricos **opt-in solamente dentro del experimento**, cuatro relés con objetivo 8, puntuación después de dos turnos y las mismas reglas de captura/compra/munición. **Cada fuente reproduce los controles completos de v3.7.3**: centros primero 28/64, segundo 36/64, azul 32/64, rojo 32/64; accesos primero 12/64, segundo 52/64; laterales primero 18/64, segundo 46/64.

### Qué se compara después de cada acción

1. Tipo de acción real, unidad, destino, oponente y producción. La acción del juego reflejado se expresa en coordenadas y facción de la partida original.
2. Estado completo de unidades (incluidas nuevas unidades `N1`, `N2`, etc.), propietario de ciudades/fábricas, crédito, munición, clima, objetivos persistentes de la IA, casillas exploradas y contactos de niebla, relés, puntuación, turno y ganador.
3. Se normaliza exclusivamente el **orden no semántico de la enumeración** de unidades, sitios, relés y exploración. Los valores y órdenes persistentes de objetivos de IA siguen comparándose; nunca se oculta una divergencia de decisiones.
4. Se registra la **primera transición exacta** que rompe la equivalencia: fase, orden, tipo/campo y un resumen de ambas realidades. Después se siguen jugando **ambos combates**, por separado, hasta terminar y comparar si el ganador del juego reflejado corresponde al ganador original con el color intercambiado.
5. Se desglosa por mapa, relés, niebla, política IA y bando inicial; incluye cantidad de compras, ataques, movimientos, capturas de ciudades y relés y eventos de puntuación.

En `tests/MirrorSemanticsV375.gd` se realiza la normalización sin modificar el estado; `tests/test_ai_mirrored_full_battles_v375.gd` ejecuta 384 batallas reales.

## Contrato del motor y control de calidad

`tests/test_ai_mirror_midgame_contract_v375.gd`: **48 estados reales después de cuatro medias rondas**, 4 mapas × niebla sí/no × iniciador azul/rojo × tres disposiciones. Se verifica la reversibilidad del reflejo, serialización y recuperación con `SaveCodec`, unidades nuevas, objetivos/visión y validación de `RelayControl` y `UrbanEconomy`.

`tests/aggregate_ai_full_mirror_v375.py` exige **192 registros distintos**, 384 partidas con acciones válidas y tres resultados históricos reproducidos. Un dato ausente, duplicado, incoherente o una regresión del control impide aceptar el informe.

Las salidas son `reports/ai_v375_full_battle_mirror.{json,md}` con diferencias de ganador, primera divergencia y desglose por mapa y color. La CI está en `.github/workflows/ai-mirrored-full-battles-v375.yml`.

**No es una corrección de balance automática.** Si se detecta una primera asimetría, deberá estudiarse su causa en la regla compartida concreta y repararse por separado con pruebas de regresión y mapas variados; no se aprueban ajustes de unidades, poderes ni ayudas de facción por un dato aislado. Mantener PR en borrador.
