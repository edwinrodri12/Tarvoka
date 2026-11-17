# TARVOKA — A01 V13: daño visual, impactos y destrucción

## Alcance implementado
Se incorpora `scripts/ui/AttackHelicopterDamageV13.gd` como capa 3D nativa Godot 4.3 independiente sobre la escultura de ataque A01 V12.1; no cambia alcance, vida, estadísticas, reglas, impactos del juego ni el LOD de batalla móvil.

La capa tiene cinco estados (0 intacto, 1 daño leve, 2 moderado, 3 crítico y 4 destruido). La malla permanece completa; se añaden, de forma reversible:

- cicatrices y rayaduras en fuselaje, con destello, chispas y anillo de onda expansiva real en los impactos;
- paneles ennegrecidos y columna de humo sobre un motor en daños moderados, con partículas de malla que ascienden durante la inactividad;
- fuego visible en estado crítico, cuyas llamas fluctúan con reloj propio incluso sin nueva animación de combate;
- aspas originales ocultas solo en destrucción (no eliminadas), con nuevas mallas cerradas de fragmentos de rotor principal y rotor de cola, bordes irregulares y despegue desde sus bujes originales;
- animación de caída e inclinación del modelo y trayectorias escalonadas de fragmentos (salida del buje, giro en el aire, aterrizaje en el terreno) durante la destrucción;
- botón de reparación que restablece los rotores y oculta todos los efectos.

## Visor 3D unificado
Bajo A01 se ofrecen: **Impactos de bala**, **Impacto explosivo**, **Siguiente nivel de daño**, **Reparar helicóptero**, **Animar destrucción** y acercamiento al humo. Se respeta el selector de facciones y la cámara. El texto técnico refleja el nivel de daño vigente.

## Pruebas
- `tests/test_attack_helicopter_v13.gd`: ocho facciones, 0–4, animaciones, humo y fuego con movimiento independiente, visibilidad y rotación del rotor, fragmentos independientes, reparación, idempotencia y ausencia de arte V13 en LOD10.
- `tests/test_attack_helicopter_v13_capture.gd`: trece capturas originales de Godot en 960×720: intacto, impacto, macro de onda expansiva, humo, humo animado, explosión, crítico, fuego animado, destruido, caída parcial, caída final, macro de fragmentos de rotor y reparado.
- `tests/test_attack_helicopter_v9_studio.gd`: entradas interactivas del visor unificado y controles V13.
- `.github/workflows/a01-v13-damage-qa.yml`: pruebas y pruebas de render Godot 4.3, con evidencias PNG adjuntas a Actions.

## Publicación
Rama provisional [PR #476](https://github.com/edwinrodri12/Tarvoka/pull/476). El visor [GitHub Pages](https://edwinrodri12.github.io/Tarvoka/) es el sitio público del proyecto, **no evidencia de que V13 esté publicada**. Las capturas y tests se revisan antes de fusionar.

## Estado de validación
El módulo y las pruebas V13 están implementados en la rama. **No dar V13 por aprobada ni publicada sin ejecución nueva de CI Godot 4.3** y revisión de los once fotogramas; las comprobaciones V12 anteriores no equivalen a haber probado V13. Se añade disparador de push a la rama de arte como respaldo a la PR draft.

## Revisión de la siguiente prioridad
Se reforzó el flujo V12 probado para ejecutar también pruebas V13 y exportar sus 13 imágenes originales de Godot. Las verificaciones ahora incluyen mallas cerradas de rotores principal/cola, puntos de salida junto a los bujes, fases inicial y final de la trayectoria, anillo expansivo y persistencia del daño al cambiar de facción en el Estudio 3D. **No se ha verificado visualmente V13 mediante capturas nuevas hasta recibir un artefacto de CI; la rama permanece draft.**
