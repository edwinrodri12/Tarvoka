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
