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

## Extensión — contraataque con inversión de posiciones (2026-11-14)
- Tras el ataque cuesta arriba (daño 2, defensor en montaña sobrevive con 8 HP), simular su contraataque desde la altura contra el atacante situado en llanura.
- Recalcular `TerrainTactics.modifiers` invirtiendo atacante y defensor; esperar altura +1, cobertura 0 para el nuevo defensor y daño 6 con ataque base 6/defensa 1.
- Comprobar que el contraataque no hereda cobertura montañosa del primer disparo, no declara derrota errónea y no muta diccionarios de unidades.
- Código: commit `513b0e1c6052c6441b2287000ef6da8c4094e55b`. Godot 4.3/CI: **NO EJECUTADO**; Android físico: **NO EJECUTADO EN DISPOSITIVO**.
- Alcance limitado: prueba de funciones puras; no acredita que el controlador de turnos dispare automáticamente el contraataque ni que el HUD lo presente correctamente.

## Extensión — flanqueo y montaña (2026-11-14)
- Positivo: aliado terrestre vivo en (1,3), detrás del defensor montañoso en (1,2), añade +1 al ataque de (1,1); el -1 por atacar cuesta arriba se compensa y el daño esperado pasa de 2 a 3.
- Adversarial: el mismo aliado con HP 0 o dominio `air` NO habilita flanqueo ni cambia la penalización por altura.
- La cobertura de montaña del defensor permanece +2; unidades y terreno no se mutan.
- CI anterior para `3ac5778`: Godot general 43666142242, suite de montaña 43666142263 y exportación Android 43666142265, todos SUCCESS. **Esos resultados no validan este nuevo commit.**
- Godot/CI del commit de esta extensión: NO EJECUTADO / pendiente de resultado. Android físico: NO EJECUTADO EN DISPOSITIVO. No integra el controlador de turnos ni verifica visualización de flanqueo.
