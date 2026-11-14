# TARVOKA · Cuartel General V22 — daños coherentes, humo y fuego dinámicos

V22 apila sobre V21. Cambios exclusivamente visuales del modelo hero; no modifica HP, combates, economía, guardados, modo historia, ni sprites V15 y proxy Android V13.

## Estados revisados

| Estado | Geometría 3D real | Animación ambiental |
|---|---|---|
| 0 Intacto | Todo completo | Ninguna |
| 1 Leve | Retira el mástil principal y, niveles 2/3, mástil de comunicaciones, sustituye por antenas caídas de metal, crucetas y bases rotas; conserva cuerpos, ventanas y escudo | Ninguna |
| 2 Medio | Acumula el leve; cristales físicamente rotos de V21, secciones verdaderamente retiradas del techo derecho y de servidores, losas anguladas, refuerzos expuestos y fragmentos tirados en el patio | 3 volutas de humo animadas, sin fuego |
| 3 Crítico | Acumula daños medios y V21; ala izquierda colapsa de verdad, desaparece la galería original, la cornisa y cubiertas, deja suelo interior, muros rotos, columnas y ferralla; centro de mando y escudo todavía en pie | 5 volutas de humo + **10 llamas 3D** en un solo lote MultiMesh; fuego en ala colapsada y techo derecho |
| 4 Destruido | Ruina real V21 y sin edificio intacto | Sin fuego persistentemente activo en modelo borrado |

El fuego se mueve (cambia altura, inclinación y radio) y el humo asciende y se desvanece: no son imágenes 2D, ni simples esferas inmóviles. Los diez conos de llama comparten **una sola malla instanciada**. Sin nuevos OmniLight3D, CPU emitters o sistemas de partículas. El sistema de clima global de V20 sigue siendo reversible.

## Animaciones de ataque ya existentes y conservadas

`HeadquartersImpactV21.gd`: **bullet 0,62 s** (12 chispas/fracciones 1 MultiMesh) y **explosive 1,75 s** (destello, onda, 18 fragmentos 1 MultiMesh y humo). Ambas se pueden activar incluso cuando el edificio está en llamas V22 desde los dos botones del Studio 3D. **No** están todavía enlazadas a un evento verdadero de daño de batalla. Si esto se integra al juego, los estados deben derivarse de HP real del motor de combate, nunca de eventos simulados.

## LOD / rendimiento

Solo el hero de exhibición tiene `HeadquartersDamageV22.gd` y `HeadquartersFireV22.gd`. `HeadquartersMapLOD3D` a distancia deja de ejecutar `_process` de humo/fuego y detiene impacto temporal. V15 PNG y V13 táctico preservados; no prometer FPS de partidas 8 jugadores. Las mediciones físicas Android todavía pendientes.

## QA

`tests/test_hq_v22_progressive_damage_fire.gd` verifica 3 niveles × 5 estados, antenas de origen realmente ocultas, conservación de pared posterior central, techo arrancado, galería izquierda realmente suprimida, humo medio en movimiento, 10 llamas realmente animadas, cambio de LOD, dos impactos V21 compatibles, reversión a intacto y diferencias de píxel entre etapas. `.github/workflows/hq-v22-progressive-damage-fire-gpu.yml` archiva capturas GPU originales de los estados 0/1/2/3/4 e impacto sobre fuego.

**Entrega web:** el workflow principal de Pages en main debe comprobar todos los scripts V22 y test V22 al cambiar únicamente su fuente HQ. Conservar visores independientes del mapa y tanque, actualmente sujetos a cambios en ramas paralelas; no reemplazarlos por versiones antiguas al publicar.
