# TARVOKA G16 · V2 — acabados mecánicos y materiales premium

**Estado:** implementado en rama de revisión; pendiente de compilar y comprobar capturas V2 en Godot 4.3 y publicación del mismo visor unificado. Las reglas tácticas originales G16 no cambian.

## Qué cambia respecto a V1

El modelo base **sigue siendo la V1 6×6**, con su rol artístico `logistics_mobile`, sus dos depósitos de combustible, dos cofres de munición, dos estabilizadores, toldo y portón trasero. La V2 es una **capa de geometría real adicional**, no una fotografía, GLB prefabricado ni un visor alterno.

### Cabina 100% opaca y acabados PBR

- Frontal de cabina con ceja blindada, capó elevado, faldón sellado, rejilla de cinco lamas, paragolpes macizo y placa superior de techo solapada sobre la cabina cerrada de V1.
- **Cuatro cristales sólidos:** dos parabrisas y dos ventanas laterales con `BoxMesh`, marcos y juntas metálicas. Todos usan material con `TRANSPARENCY_DISABLED`, `clearcoat_enabled`, rugosidad 0.12 y brillo PBR; no se transparenta al girar la cámara.
- Puertas de acceso, pilares, bisagras, manijas, espejos en metal reflectante y dos balizas de seguridad.
- Franjas reconocibles de cada una de las **ocho facciones**, ocupando solo paneles de identidad y no el casco completo.

### Seis ruedas con mecánica visible

- Arandelas de borde `TorusMesh`, hombros de caucho tridimensional y buje central en cada uno de los seis pivotes giratorios ya existentes.
- **Guardabarros semicirculares físicos** con ocho segmentos sobre cada rueda en LOD13 y cinco en LOD8. Permiten distinguir suspensión y rueda, con silueta real, no únicamente textura.
- **6 pernos por rueda en LOD13**; 3 pernos simplificados por rueda en LOD8.
- Los neumáticos y tacos existentes de V1 siguen girando. Los nuevos anillos y pernos son *hijos de los mismos seis pivotes*, por lo que no se quedan suspendidos al avanzar.

### Módulos de carga y grúa

- Separación visual de combustible (tapones, abrazaderas, tambor del enrollador, válvula y etiquetas azules) y munición (cierres y protectores de cajas).
- Paragolpes trasero, advertencias laterales y pilotos rojos.
- **Actuador hidráulico telescópico de la grúa:** cilindro exterior, vástago cromado, pasador y rieles de extensión. El eje se calcula cada fotograma desde la transformación real del brazo; sigue altura y extensión.
- Animaciones `idle/move/deploy/unload/resupply/camp/pack/hit` se conservan. Los elementos V2 se sincronizan con todas las poses.
- `show_finish(root,true/false)` permite comparar la V2 real contra la V1 en el **mismo modelo cargado**, sin reemplazarlo por una imagen.

## Integración técnica real

- `scripts/ui/G16LogisticsExteriorV2.gd`: mallas, materiales, seis arcos de guardabarros, seis llantas, dos cilindros, geometría frontal y cristales.
- `scripts/ui/UnitModels3D.gd`: `V1.build()` → `V2.apply()`, con `V2.sync()` tras la animación y restauración.
- `scripts/ui/BastionStudioAdapter.gd`: selector G16 V2 y botones «V2 mostrar» / «V1 comparar» en el visor unificado.
- `.github/workflows/tarvoka-3d-pages.yml`: copia todos `G16*.gd`, verifica la existencia de V2 y preserva su `preload` durante el montaje.
- `tests/test_g16_v2_native_finish.gd`: construcción real ocho facciones × LOD8/13, cuatro cristales reflectantes opacos, seis anillos y guardabarros 3D, extensión/retracción real del pistón, marcha, restauración, comparación, materiales y seis conjuntos de neumáticos.
- `.github/workflows/g16-v1-native-logistics-qa.yml`: ejecuta V1 y V2, exige **24 capturas Godot reales** (16 antes/después + 8 ángulos 360°).

## Sin cambios en jugabilidad

El arsenal original `logistics` (G16) continúa con **HP8, movimiento4, daño0, coste300, fábrica**. El campamento y el abastecimiento de combustible/munición presentados en 3D son *vistas artísticas*, no nuevas habilidades ni un nuevo edificio fijo.

## Pendientes

Confirmar ambas CI y validar que las capturas nuevas realmente muestran las cuatro caras del camión, la grúa, los cristales y los neumáticos. No fusionar con main ni calificar V2 de final hasta que el publicador pase sus pruebas.
