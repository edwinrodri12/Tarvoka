# TARVOKA — G13 V15: unión giratoria, legibilidad táctica y luces de material

**Alcance:** modelo `aa_mobile` de Godot 4.3, vista de alta calidad `art_level=13`; **ningún cambio** de lógica de batalla, poder, munición, daño, radar funcional ni IA. Esta versión se suma a la V14 aprobada.

## Escultura 3D

- Un **pedestal troncocónico fijo** anclado al chasis, desde y=0,828 hasta y=1,420. Cubre el espacio vacío que separaba el chasis de la torre; invade ligeramente el casco y el aro existente para evitar una unión abierta.
- Una **junta anular hueca** de 24 segmentos, con paredes exterior/interior y tapas superior/inferior. La junta es hija de `G13_TorretaAzimut`: sigue los giros de disparo; el pedestal fijo no gira.
- Un segundo cuello negro fijo, ocho fijaciones en un `MultiMeshInstance3D` y dos protectores laterales de la parte baja de la torreta.
- Dos **raíles superiores de identificación**, cada uno pintado con una copia del esmalte oficial de su facción, sin tapar el emblema del techo. Las ocho facciones no se sustituyen por colores inventados.
- Cuatro materiales de lámpara ya existentes (dos delanteros, dos traseros) con **emisión suave** para inspeccionar el modelo bajo luz tenue. No se crean `Light3D`, focos físicos ni luces dinámicas por vehículo.

## Rendimiento: pruebas separadas

El LOD8 Android conserva las mallas, materiales, iluminación y el radar anteriores, sin ninguna geometría V15. La única nueva decoración se construye para `art_level=13`.

- `tests/test_g13_turret_finish_v15.gd` verifica ocho facciones, material de señales, hueco verdadero del anillo, jerarquía de pivotes, las cuatro lámparas, ausencia de `Light3D`, idempotencia, disparos terrestres y aéreos y aislamiento de LOD8.
- `tests/test_g13_v15_build_profile.gd` mide en Linux CPU el tiempo de construcción y 12 poses por modelo, conteo de nodos, objetos dibujables y triángulos para 8 facciones en LOD8 y LOD13, y exporta un JSON. **No mide GPU ni FPS reales en Android**; hace falta una prueba posterior en teléfono.
- `tests/test_g13_v15_tactical_capture.gd` toma **33 capturas reales** Godot: 27 heredadas de V14 + dos macros de junta/raíles + comparación a distancia LOD13/LOD8 + dos vistas nocturnas de focos.
- Flujo CI `.github/workflows/g13-v8-final-art-audit.yml` añade el test V15, publica capturas y JSON. El selector principal del Estudio 3D presenta `G13 · Antiaéreo V15`.

## Pendientes de aprobación final

Inspeccionar las 33 imágenes para comprobar la intersección visual en la unión rotatoria y si los colores de las ocho facciones se distinguen desde distancia de juego; después, verificar consumo de memoria y FPS con telemetría **de un Android real**.

No integrar un modelo de detalle 13 en la partida Android hasta superar esa prueba. Conservar el LOD8 como la versión de producción móvil.
