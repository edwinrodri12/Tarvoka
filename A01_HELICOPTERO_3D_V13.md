# TARVOKA — A01 V13: daño visual, impactos y destrucción

## Alcance implementado
Se incorpora `scripts/ui/AttackHelicopterDamageV13.gd` como capa 3D nativa Godot 4.3 independiente sobre la escultura de ataque A01 V12.1; no cambia alcance, vida, estadísticas, reglas, impactos del juego ni el LOD de batalla móvil.

La capa tiene cinco estados (0 intacto, 1 daño leve, 2 moderado, 3 crítico y 4 destruido). La malla permanece completa; se añaden, de forma reversible:

- cicatrices y rayaduras en fuselaje, con destello y chispas en impactos;
- paneles ennegrecidos y columna de humo sobre un motor en daños moderados;
- fuego visible en estado crítico;
- aspas originales ocultas solo en destrucción (no eliminadas), con piezas físicas fracturadas en la capa V13;
- animación de caída e inclinación del modelo y desplazamiento de fragmentos durante la secuencia de destrucción;
- botón de reparación que restablece los rotores y oculta todos los efectos.

## Visor 3D unificado
Bajo A01 se ofrecen: **Impactos de bala**, **Impacto explosivo**, **Siguiente nivel de daño**, **Reparar helicóptero**, **Animar destrucción** y acercamiento al humo. Se respeta el selector de facciones y la cámara. El texto técnico refleja el nivel de daño vigente.

## Pruebas
- `tests/test_attack_helicopter_v13.gd`: ocho facciones, 0–4, animaciones, visibilidad rotación del rotor, fragmentos independientes, reparación, idempotencia y ausencia de arte V13 en LOD10.
- `tests/test_attack_helicopter_v13_capture.gd`: nueve capturas originales de Godot en 960×720: intacto, impacto, humo, explosión, crítico, destruido, caída parcial, caída final, reparado.
- `tests/test_attack_helicopter_v9_studio.gd`: entradas interactivas del visor unificado y controles V13.
- `.github/workflows/a01-v13-damage-qa.yml`: pruebas y pruebas de render Godot 4.3, con evidencias PNG adjuntas a Actions.

## Publicación
Rama provisional [PR #476](https://github.com/edwinrodri12/Tarvoka/pull/476). El visor [GitHub Pages](https://edwinrodri12.github.io/Tarvoka/) es el sitio público del proyecto, **no evidencia de que V13 esté publicada**. Las capturas y tests se revisan antes de fusionar.
