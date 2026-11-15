# TARVOKA — Base Aérea V3 · Rodaje alineado y efectos de combate

## Corrección geométrica real de la pista (prioridad del usuario)
La pista de rodaje estaba **2,75 unidades desplazada a la derecha** de la boca del hangar: `CarrilRodaje` se colocaba en `x=+0.80`, mientras que `HangarPrincipalV1` está centrado en `x=-1.95`.

`Airbase3DV1.gd` ahora declara `HANGAR_CENTER_X=-1.95` y `TAXIWAY_CENTER_X=HANGAR_CENTER_X`. Reubica la superficie de rodaje a `x=-1.95`, la ensancha a **6,40**, la alarga hacia el umbral, gira la señalización longitudinal al eje `-Z` y coloca el umbral centrado a `z=-4.235`; dos límites de seguridad se colocan a `x=-1.95±3.04`. No extiende una pista artificial fuera de la casilla compacta.

## Efectos visuales de daños en Godot
- `AirbaseImpactV3.gd`: reutiliza la clase 3D probada para **chispas/balas** a la entrada del hangar y **onda de choque, fogonazo, escombros y humo** por impactos explosivos en el techo. Los efectos son distintos y temporales.
- `AirbaseDamageFXV3.gd`: estado **medio** con 2 fuentes de humo suave (6 pseudo-volúmenes en un MultiMesh); **crítico** con 4 fuentes de humo (12 pseudo-volúmenes) más 9 llamas en otro MultiMesh, concentradas en el daño de cubierta y cabina. Utiliza el shader de humo HQ V23, evitando iluminación adicional.
- Perfil Android visual: baja a dos capas por fuente y puede suspender totalmente la animación en LOD lejano. No son valores medidos en un móvil físico.
- Intacto/leve sin incendio permanente, destruido muestra ruinas sin recrear edificios ni puertas intactas.

## Integración
En `Edificios 3D → Base Aérea V3 · pista y efectos`, controles separados **Impacto de bala**, **Impacto explosivo** y **Humo reducido · perfil Android**, junto a todos los controles previos de abrir/cerrar, cámara interior, ocho facciones, 3 niveles, 5 estados, lluvia y nieve.

**Límite:** Solo efectos visuales de estudio. El combate del juego aún no tiene HP autorizados para edificios atacables y por tanto estas animaciones NO se presentan como impactos reales confirmados. No modifica la economía, balance, acciones del turno ni el Cuartel General.

## Pruebas
`tests/test_airbase_v3_aligned_runway_vfx_gpu.gd` verifica eje X de pista vs. hangar en 120 variantes, orientación de marcas, umbral, estados, explosiones, humo/incendio en GPU real, LOD reducido, nieve, facción turquesa y retorno al HQ V23. Capturas PNG emitidas por Godot 4.3 en CI `.github/workflows/airbase-v3-runway-vfx-gpu.yml`.

**Después de V3**: revisión visual de materiales y renderizado en Android físico, calibración de FPS bajo varios edificios, y solo entonces conexión de efectos con HP reales una vez existan reglas de edificios atacables.
