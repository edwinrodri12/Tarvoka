# TARVOKA — G13 V14 · radar cóncavo y sensores de seguimiento 3D

**Alcance:** nueva capa de modelado 3D **real en Godot 4.3** sobre `G13 V13`, restringida a `aa_mobile` con nivel 13. No añade ninguna unidad al sistema de combate, tampoco efectos reales de rastreo, adquisición de blancos, balance, daño o munición.

## Geometría

1. **Radar trasero:** sustituye **solo la malla** del componente original `G13_TiltedRadarDish` de cilindro plano por una parábola poliédrica, cerrada por detrás. El radio original de 0.294 m se conserva; la inclinación original de 68° y su nodo siguen intactos.
2. **Borde y alimentación:** anillo de aluminio hecho de una sola malla, receptor central, cara óptica y cuatro varillas físicas sobre el radar. Todas son hijas del disco original y por tanto giran al barrer de -70° a +70° usando la animación existente.
3. **Mástil:** collar reforzado de metal y canalización visible. Ambos cuelgan de `G13_RadarAzimut`, no de la torreta principal.
4. **Director electroóptico:** cubierta superior protectora y dos sensores con lentes de vidrio azul y biseles metálicos. Son hijos de `G13_TorretaAzimut`: acompañan los giros de disparo sin forzar el radar a seguir el mismo rumbo.

## Contratos conservados

- Animaciones `scan`, `move`, `aim_air`, `attack_air`, `aim_ground` y `attack_ground`, con el mismo radar de V1 y los cañones V4/V12.
- Las ocho facciones, sus esmaltes y los materiales V13.
- La variante Android `art_level=8` continúa con el disco original de bajo coste.
- Mismo `UnitModels3D`, mismo `BastionStudioAdapter` y Estudio 3D publicado.
- Módulo con flag idempotente `tarvoka_g13_sensor_sculpt_v14`, sin generar mallas durante una animación.

## Comprobaciones

- `tests/test_g13_sensor_sculpt_v14.gd`: topología de radar, posición/inclinación original, material, alimentación, sensores gemelos, independencia radar/torreta, barrido angular 140°, apuntado aéreo y terrestre, ocho facciones, idempotencia y variante LOD8.
- `tests/test_g13_v14_sensor_capture.gd`: **27 fotogramas PNG** desde Godot: 8 facciones, 7 ángulos del vehículo, rueda, disparos, detalles V12/V13 y tres macros V14: reflector, lentes y posición de barrido.
- Pipeline `.github/workflows/g13-v8-final-art-audit.yml` conserva la suite V1–V13 y la amplía a V14; además activa la publicación web al cambiar su propio archivo nativo.

**Próxima etapa sugerida:** verificar visualmente los 27 fotogramas y corregir colisiones perceptibles cerca de la caja óptica y los soportes. No añadir funcionalidades reales de radar sin decisión explícita de diseño de juego.
