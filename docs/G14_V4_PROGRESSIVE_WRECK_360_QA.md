# TARVOKA · G14 V4 — daños físicos y revisión de 360 grados

**Estado:** desarrollo artístico de G14 V4 integrado en la rama de revisión. La validación Godot/Android y la publicación en el visor web todavía dependen de la CI. No fusionado a `main`, unidad no final.

## Modelo 3D nativo

Las cuatro etapas **acumulativas y reversibles** de daño son:

| Nivel | Daño geométrico en Godot | Riesgo visual mitigado |
|---|---|---|
| 0 | Chasis 8×8, cabina cerrada, vidrio sólido, 4 SAM y radar intactos | Preserva blindaje y materiales V2/V3 |
| 1 | Abolladuras, rayones, rebordes desgastados y golpe en defensa | Mallas superpuestas; jamás paredes perforadas/invisibles |
| 2 | Blindaje lateral combado, impactos sellados y líneas de fractura sobre vidrio opaco | Vidrios V2 continúan sólidos, sin recortes transparentes |
| 3 | Carbonización en 4 contenedores, rieles doblados y antena radar fracturada | Todo daño del lanzador/radar es hijo de pivotes móviles |
| 4 | Casco ennegrecido, bordes mecánicos expuestos, lanzador inclinado, columnas opacas de humo y brasas | El casco sellado permanece; no elimina geometría estructural |

El **flash de impacto** es un grupo temporal de piezas 3D emisivas y es independiente de los niveles permanentes. Los materiales no introducen `ALPHA` ni modos transparentes para paredes, puertas o blindaje.

Los niveles no modifican salud, ataque, munición, captura, humo táctico, rutas, colisiones, economía ni IA. El rol `sam_mobile` sigue siendo artístico; `sam` (código G14) conserva coste 900, ataque 8, alcance 2–5 y el catálogo de unidades existente.

## Animación y recuperación

- `G14MobileSAMDamageV4.set_damage(root,0..4)` muestra solo las capas correspondientes al nivel.
- `sync(root,"hit",p)` aplica flash de impacto en un intervalo breve y vuelve a sincronizar inclinación del lanzador y deformación del radar sin acumular los ángulos en cada fotograma.
- `reset_damage(root)` restaura todos los elementos visuales intactos.
- `show_finish(root,false)` oculta toda la escultura V4 y permite comparación real de la V3.
- `restore_model_pose` restaura movimiento, ruedas y pistones, sin borrar el nivel de daño persistente del visor.

## Visor y prueba 360°

El **único** visor `BastionStudioAdapter.gd` incluye 5 botones de nivel de daño y un recorrido orbital completo en 6 segundos; las vistas V1/V2/V3 continúan disponibles. No se crea una galería aparte para la V4.

`tests/test_g14_v4_native_damage_360.gd` verifica:
- Presencia de V1/V2/V3/V4 en ocho facciones × dos LOD (8 y 13).
- Aparición acumulativa de cuatro grupos de geometría real y correcta desaparición tras restauración.
- Alineación de daños de radar y lanzador con sus pivotes, hit flash temporal y ausencia de cambio de reglas.
- Producción de **28 capturas reales de Godot** en `build/qa/g14-v4/`: 8 ángulos intactos, 8 ángulos destruidos, 4 niveles y 8 facciones. Comprueba cambios reales de píxeles entre intacto/destruido.
- Que el exportador web copie `G14MobileSAMDamageV4.gd` y mantenga el registro en `UnitModels3D.gd`.

## Pendientes antes de aprobación

Inspeccionar los 28 PNG de Godot (frontal, trasera, ambos flancos, diagonal y altura) y contrastar sus esquinas/solapes con V2. Luego validar rendimiento Android 8-faction LOD8 y publicación real del Studio. Si la CI indica error, corregir antes de liberar.
