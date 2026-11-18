# TARVOKA — G16 V1: Camión logístico 6×6, modelo 3D nativo

**Fecha:** 18 de noviembre de 2026. **Estado:** primera iteración artística en rama y PR; la publicación en el Estudio 3D y aprobación final dependen de CI. No autorizar un merge sin verificar. No se cambian mecánicas del juego.

## Identidad, función y compatibilidad

La familia `logistics` **ya existe** en `scripts/core/ModernArsenal.gd` con el ID `G16`, coste interno 300, movimiento 4, ataque 0 y categoría terrestre. El inventario y la transferencia móvil no se inventan en este PR: `scripts/core/Logistics.gd` implementa 16 puntos máximos de munición y 90 de combustible como carga persistente del camión, consumidos bajo reglas existentes, además de depósitos y presupuesto. La reparación de otras unidades sigue pendiente; una grúa en el modelo NO implica reparación jugable.

Las estadísticas y reglas de logística permanecen intactas. Esta primera entrega añade **el arte 3D** de la unidad, no un segundo tipo de camión ni producción adicional.

## Geometría original en Godot 4.3

Archivo: `scripts/ui/G16Logistics3DV1.gd`. Modelo a base de mallas reales y pivotes, no captura 2D.

- **Cabina de tipo cab-over** compacta y blindada: carcasa octagonal cerrada con biseles de verdad en 3D, parabrisas inclinado, puerta, lunas, peldaños, faros, parrilla, paragolpes y tiradores.
- **Chasis de seis ruedas (6×6):** seis pivotes de dirección/rodaje con neumáticos físicos. Material de caucho no metálico (`metallic=0`, `roughness=0.94`), llantas de aleación (`metallic=0.80`, `roughness=0.29`), bujes y tuercas. Banda de tacos de caucho en LOD de estudio, no cromada.
- **Plataforma de suministros** descubierta con piso nervado, bordes abatibles, bisagras y portón posterior. Claramente distinta de la caja de equipos sellada de la G15 y de la torreta armada G13.
- **Carga real:** dos depósitos cilíndricos con tapas y válvulas, dos cajas apilables con flejes, soportes metálicos y líneas protegidas de combustible. Las formas son elementos visuales; **no representan cantidades de stock**.
- **Brazo hidráulico** con base giratoria, boom articulado, extensión, cilindro y gancho, más manguera sobre carrete lateral para animación de servicio.
- **Facciones:** mismo sistema de ocho colores aprobados; esmalte con clearcoat solamente en puertas y laterales, preservando caucho real y acero.
- **LOD8 Android:** conserva seis ruedas, depósitos, caja de carga y grúa; omite detalles diminutos para reducir nodos sin cambiar silueta.

## Poses visuales

| Pose | Descripción |
|---|---|
| `idle` | Cabina, grúa, manguera, carga y ruedas restauradas |
| `move` | Rotación real de ruedas, dirección frontal y vibración moderada |
| `crane` | Giro de pedestal y elevación del brazo hidráulico |
| `supply` | Despliegue de manguera, plataforma de cajas y grúa; **sin transferir inventario** |
| `hit` | Reacción breve del chasis a impacto |
| `destroy` | Inclinación y deformación mecánica escénica **V1 provisional**; requiere destrucción por piezas antes de aprobar arte final |

Todas las poses admiten `restore_model_pose()` exacto; el visor puede detener la animación y el estado de destrucción visual no afecta ninguna partida.

## Estudio 3D y validación

- `UnitModels3D.gd` registra el mismo identificador `logistics` del catálogo jugable, material real, LOD y poses.
- `BastionStudioAdapter.gd` añade G16 al **selector existente** con ocho colores, acciones visuales y botón de restauración. No se crea un visor separado.
- `tarvoka-3d-pages.yml` copia el nuevo script al ensamblado del mismo Estudio WebGL; **la disponibilidad pública depende de fusionar el PR y de build + deploy exitosos**.
- `tests/test_g16_native_art_v1.gd` comprueba seis pivotes, cabina octagonal, llantas y caucho PBR, materiales de las ocho facciones, matrices de animación, reversibilidad, compatibilidad LOD8, que la ficha G16 permanece sin armas y **16 PNG de cámara real en Godot**.
- `.github/workflows/g16-native-art-qa.yml` ejecuta Godot 4.3 en CI y publica las capturas para examen visual.

## Siguiente etapa artística tras V1

Revisión minuciosa de todos los ángulos y fondos reales: biseles, ruedas naturales, guardabarros integrados, texturizado de carga, grúa funcional más compleja, manguera deformable, daños progresivos y destrucción física por piezas; todo separado de cambios de balance o suministro. **No declarar G16 finalizada antes de revisar imágenes reales y probar en Android.**
