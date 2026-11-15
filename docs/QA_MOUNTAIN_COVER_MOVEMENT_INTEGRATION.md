# QA — montaña: movimiento y combate posicional (2026-11-14)

## Alcance
Regresión independiente para `Rules.reachable`, `TerrainTactics.modifiers` y `Combat.resolve` en Godot 4.3. Comprueba ascenso adyacente con movilidad 1, agotamiento de presupuesto, cobertura de montaña +2, modificador de altura -1/+1, daño determinista y ausencia de mutación de unidades y mapa. No modifica balance ni implementa nuevas reglas.

## Ejecución
```sh
godot --headless --path . --script res://tests/test_mountain_cover_movement_integration.gd
```
Se espera `PASS: mountain movement and positional combat integration` y código de salida 0. Ejecutar además suite general Godot, IA, guardado, victoria y exportación Android antes de considerar integración.

## Estado
- Fuente subida a rama independiente: PASÓ.
- Godot 4.3/CI: NO EJECUTADO en esta entrega.
- Android físico: NO EJECUTADO EN DISPOSITIVO.
- Revisión de arte/terreno #203: PENDIENTE DE REVISIÓN VISUAL; no depende de ella.
- No sustituye pruebas de partida real, contrafuego, clima ni niebla.

## Extensión de regresión — 2026-11-14
- Positivo: ciudad sobre montaña acumula cobertura terrestre +2 de montaña y +1 de ciudad, sin alterar HP ni terreno.
- Adversarial: defensor aéreo sobre montaña no recibe cobertura terrestre ni bonificación de altura de combate terrestre.
- Adversarial: coordenada fuera de tablero no produce cobertura ni bonificaciones de ataque.
- Commit de código: `7ae824bb83214ef81149bd6f89ac7f2f2d087c41`.
- Estado de esta extensión: **NO EJECUTADO en Godot/CI**; **NO EJECUTADO EN DISPOSITIVO**. No se ha fusionado en main.
