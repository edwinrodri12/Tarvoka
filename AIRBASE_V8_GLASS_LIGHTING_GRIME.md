# TARVOKA — Base Aérea V8: Cristales, iluminación de hangar y suciedad localizada

## Objetivo: un salto visual, no otro benchmark

La V8 parte de **V7 probada** y mantiene las ocho facciones y sus insignias oficiales, la pista V3 alineada, las 20 piezas móviles del portón V2, la geometría V6, los materiales PBR V7, el humo/fuego V4 y los controles de clima. Todo es 3D de Godot 4.3, editable por código, no ilustraciones ni fotografías falsas.

### Tres mejoras

1. **Cristalería de la torre de control:** material StandardMaterial3D con transparencia moderada, rugosidad menor, especular y clearcoat para vidrios de la cabina. Se mantienen tintes y texturas PBR V7; dos brillos 3D de contorno suave en la fachada (sin reflejos de pantalla ni ray tracing).
2. **Interior del hangar:** hasta cuatro luminarias repartidas en **un único lote de superficies 3D**, más un lote de halos suaves en el suelo. El daño medio reduce a dos luminarias y el daño crítico/destrucción las apaga. No se crean nuevas luces dinámicas ni pases de sombra.
3. **Desgaste localizado:** un lote geométrico de suciedad cerca de la zona técnica y de algunas uniones de la cubierta curva. Se respetan las roturas de la techumbre y nunca se tapa el mecanismo de los portones ni la línea central de rodaje.

### Comparador en el visor

En **Edificios 3D → Base Aérea V8**, el interruptor `V8 · cristales, luces y suciedad (comparar V7)` permite activar/desactivar la V8 de manera independiente de las opciones V6 y V7.

Para comprobar el efecto es recomendable usar **vista interior del hangar**, cámara cercana de la torre, nivel arquitectónico 2 o 3, día/noche, abrir/cerrar puertas, distintos estados de daño, lluvia y nieve.

### Presupuestos y compatibilidad

- Máximo **2 lotes de iluminación** y **1 lote de suciedad** por base cercana.
- Cristales adaptados a la geometría V1; protegen escudos y señalización.
- LOD de 8, 32 y 64 bases: sólo cuatro modelos detallados reciben la V8. Los proxies lejanos siguen siendo los de V4.
- El clima del proyecto se aplica después de la V8; se verifica restauración de materiales y protección de insignias.
- Este cambio no altera HP, economía, movimiento, combate, fabricación aérea ni APK Android.

### QA

`tests/test_airbase_v8_glass_lighting_gpu.gd` recorre 40 combinaciones de facción y daño, los tres niveles, portones operativos, clima reversible, protección de escudos, cantidad de lotes gráficos y comparación V7/V8. Exporta nueve capturas nativas de Godot: exterior, V7, hangar, daño medio/crítico, destrucción, lluvia y nieve.

`.github/workflows/airbase-v8-glass-lighting-gpu.yml` ejecuta la aceptación en Godot 4.3 con OpenGL. **No se atribuyen FPS Android a un renderizado de escritorio.**
