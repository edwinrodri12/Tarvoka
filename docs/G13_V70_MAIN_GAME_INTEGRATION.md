# TARVOKA — G13 final en el juego principal (V70)

**Aprobación del arte:** 19 de noviembre de 2026, versión visual G13 V69.
**Rol jugable existente:** mobile_aa (código G13).
**Alias histórico del visor 3D:** aa_mobile.

## Integración técnica

- La G13 ya existe en ModernArsenal como unidad antiaérea jugable: coste 500, alcance 1–3 y objetivos aéreos. No se modifica el balance, el identificador ni el formato de guardado.
- El nuevo modelo de la batalla táctica 3D utiliza el mismo G13 V69 aprobado en el estudio 3D, con su artillería doble, materiales, ruedas, vidrios y ocho identidades visuales de facción.
- La batalla representa el color de la facción elegida, sin convertir las dos facciones lógicas del motor en ocho equipos tácticos.
- Hasta ocho G13 simultáneas usan la versión Android LOD8 con acabados V69; las adicionales mantienen el chasis G13 LOD6, no una ficha genérica.
- El controlador G13BattleActionsV70 reproduce movimiento y ataque antiaéreo únicamente tras la confirmación válida de la orden de batalla; no altera turnos, combustible, munición, daño ni datos de partida.
- El icono 2D de mobile_aa permanece intacto para compatibilidad del tablero principal.

## Validación

Workflow: .github/workflows/g13-main-battle-v70.yml.
Script: tests/test_g13_main_battle_v70.gd.
Cobertura: ocho facciones, escena táctica real, G13 V69, Android LOD8, movimiento, ataque, restauración de pose y preservación del estado.

**Alcance:** integración jugable de G13 en el modo 3D. La certificación de rendimiento real en teléfonos Android y la instalación de APK requieren pruebas de dispositivo separadas.
