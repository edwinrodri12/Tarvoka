# TARVOKA v3.8.0 — Límite de objetivos del fuego coordinado sin sesgo de ID

**18 de noviembre de 2026 — Candidato experimental sin fusión.**

## Incidente verificable

La [CI de iniciativa v3.7.9](https://github.com/edwinrodri12/Tarvoka/actions/runs/44257429683) ejecutó con éxito 15/16 grupos, pero falló el escenario de mapa **24×18, semilla 317, sin niebla**. En el fotograma **137 (fase 10, orden 6)** se detectó una primera divergencia: ante el mismo defensor, una ejecución decidió disparar con la unidad inicial **C** y la otra con una unidad comprada **N1**. Todos los fotogramas anteriores, incluidas unidades, munición, economía y objetivos, eran semánticamente equivalentes.

La coincidencia temporal con el crecimiento del ejército revela un posible sesgo en `CoordinatedFireV34.propose`: se permitían **8 objetivos visibles**, pero la preselección se ordenaba por ID literal `A..F / U..Z / N1...`. Un reflejo intercambia los IDs de la formación inicial y preserva los de unidades fabricadas, por lo que dos bandos con exactamente las mismas amenazas podían analizar **distintos subconjuntos** a partir de 9 enemigos. La selección de objetivos podía afectar qué disparo ejecutar primero.

## Cambio propuesto

En **solo esta rama de revisión**, cambiar el orden previo al límite a `posición X local del atacante → Y → tipo de unidad → ID final`, con el tamaño real del tablero. Las etiquetas arbitrarias ya no desplazan del cupo una amenaza equivalente al cambiar el color. Se mantienen **exactamente iguales**:

- `MAX_VISIBLE_TARGETS=8`, `MAX_ATTACKERS_PER_TARGET=6`, profundidad de cálculo y puntuación de disparos.
- Daño, defensa, contraataques, orden del turno, compra, dinero, experiencia, HP y suministros.
- Visibilidad: la IA sigue utilizando solo el estado observable y sin información secreta.
- Arquitectura de dos bandos, ocho identidades visuales, guardados, producción y contenido 3D.

Este cambio puede alterar **a cuál enemigo visible se dirige primero la IA cuando existen más de ocho objetivos**. Es un cambio de selección táctica sujeto a los tests y revisión, no una modificación de estadísticas.

## Pruebas específicas

- `tests/test_symmetric_fire_target_cap_v380.gd`: tablero de 24×18 con **11 hostiles**. Asegura el mismo conjunto de ocho candidatos en ambos espejos y compara un disparo coordinado con dos atacantes, sin bonificaciones extra.
- `tests/test_ai_initiative_counterfactual_v379.gd`: reaplicar los dos iniciadores y sus reflejos al caso fallido sin niebla, al mismo terreno con niebla, y a un mapa 10×8.
- [Workflow v3.8.0](https://github.com/edwinrodri12/Tarvoka/blob/experiment/ai-v380-symmetric-fire-target-cap-20261118/.github/workflows/ai-target-cap-v380.yml): **4 trabajos**, sin despliegues.
- Después de pasar el caso focalizado, ejecutar toda la matriz original v3.7.9 y comparar métricas con el experimento anterior; hasta entonces, **no concluir nada sobre ventajas del primer/segundo jugador**.

**Estatus: hipótesis de causa, aún no comprobada por CI en este commit. PR draft, no auto-merge, sin cambios en `main` ni APK.**
