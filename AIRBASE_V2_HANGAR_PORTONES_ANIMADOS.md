# TARVOKA — Base Aérea V2: arquitectura de hangar y portones reales

## Nueva geometría Godot 4.3

`AirbaseHangarV2.gd` aplica una capa sobre la geometría V1 sin alterar el Cuartel V23, las ocho facciones, la torre ni el helipuerto:

- Interior con piso real, juntas, revestimiento lateral, pilares, áreas de mantenimiento y paneles de operaciones.
- Puente grúa con carro, rieles, vigas y luminarias emisivas sin agregar nuevas luces OmniLight.
- Refuerzos y cerchas de cubierta, ventilación lateral, guía superior/inferior de portones, motores laterales y señalización.
- Reutiliza las mallas, materiales PBR y colores oficiales V1. La variante de destrucción total sigue sin hangar intacto, y el daño crítico rompe parte de la estructura.
- El acabado reversible de lluvia/nieve se conserva desde V1.

## Animación de portones

`AirbaseDoorRigV2.gd` identifica y mueve **20 MeshInstance3D verdaderas** de las 4 hojas existentes (4 paneles, 4 franjas verticales, 12 rigidizadores). Las parejas se recogen hacia los laterales en 1,85 s con desaceleración suave y separación de profundidad para no producir parpadeo entre hojas apiladas. No son imágenes ni puertas duplicadas superpuestas.

En `Edificios 3D > Base Aérea V2` del Estudio Godot:

- **Abrir portones** y **Cerrar portones** activan la animación.
- La barra de apertura permite inspeccionar manualmente la geometría en 0–100%.
- Al cambiar nivel o facción se conserva el porcentaje de apertura y se actualiza la paleta original.
- El daño leve permite operar los portones; daño medio, crítico y destrucción quedan **bloqueados** y las puertas rotas permanecen estáticas.
- En LOD distante se detiene el procesamiento de la animación sin borrar el estado.

## Seguridad y alcance

La animación es únicamente visual. No introduce consumo de recursos, producción de aeronaves, inteligencia artificial, hitboxes físicas ni resistencia estructural en el sistema real de combate. Tampoco declara FPS Android comprobados. El motor de partida sigue usando las reglas de `BattleSession`; el cambio no altera ataques, defensa ni turnos.

## Verificación

`tests/test_airbase_v2_hangar_doors_gpu.gd`: 8 facciones × 3 niveles × 5 estados, presupuesto de mallas, 20 piezas animadas, interpolación y restauración, cierre/pausa LOD, bloqueo por daños, visor 3D, capturas GPU de puertas abiertas/cerradas y regresión al Cuartel General. CI `.github/workflows/airbase-v2-hangar-gates-gpu.yml`.

**Siguientes prioridades**: detalles finos de las bisagras y guías, mejor interior iluminado, capturas en cámara lateral/trasera, efectos de daño animados por impactos y mapa LOD móvil optimizado.
