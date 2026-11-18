# TARVOKA G13 — V47: materiales PBR de cabina y torreta, sobre modelo 3D real

**Versión:** V47. **Medio:** GDScript/Godot 4.3 (no imagen generada). **Estado:** la implementación se encuentra en el repositorio, pendiente de verificación del render y despliegue de esta revisión. La G13 **todavía no se declara terminada**.

## Prioridad artística

La captura del Estudio 3D mostraba la G13 con superficies relativamente uniformes frente al nivel de las unidades aprobadas. Después de V44–V46, que completaron nuevos volúmenes de blindaje, portezuelas y ruedas mecanizadas, V47 **no suma más accesorios**: da una respuesta superficial más diferenciada a los materiales ya creados.

## Materiales y superficies realmente modificados

`scripts/ui/G13MaterialFinishV47.gd` revisa 21 superficies nativas de la versión hero LOD13 y 18 del modelo táctico LOD8:

- **Cabina visible:** acero frío de tono menos plano, metalicidad `0.49` y rugosidad `0.56`; en LOD13 modifica `G13_V10_ChamferedCabShell`, en LOD8 `G13_SealedCab`.
- **Carcasa giratoria de torreta:** tonalidad de acero algo más oscura, metalicidad `0.54` y rugosidad `0.51`; sobre las mallas correspondientes al LOD.
- **Techo blindado:** metalicidad `0.43`, rugosidad `0.60` y ligeras diferencias tonales respecto a los laterales.
- **Blindaje lateral V44 y puertas V45:** metalicidad `0.51`, rugosidad `0.57`, acabado acero ligeramente más claro en los planos expuestos.
- **Anillo de giro, soportes y juntas:** acabado de metal oscuro menos brillante, de rugosidad `0.66`, para separar visualmente carcasa, mecanismo de giro y chasis.
- **Cristales y ópticas:** rugosidad `0.18`, color óptico azul oscuro con variación moderada y metalicidad `0.11`; no se sustituyen los paneles de vidrio ni sus formas.
- **Detalles mecánicos y respiraderos:** rugosidad `0.67`, metalicidad `0.37`, apariencia grafito.
- **Centros de ruedas V46:** metalicidad `0.69` y rugosidad `0.43`, diferenciándose del caucho.
- **Paneles del color de facción:** se mantiene la **paleta real de las ocho facciones**, con un aclarado adicional moderado de `2.8 %`; metalicidad `0.36` y rugosidad `0.49`. Ninguna facción se fuerza a un color azul fijo.

Las propiedades se modifican **en duplicados individuales de los materiales existentes**; se preservan el resto de las propiedades originales, las luces, el shader y los nodos. Esto evita cambios compartidos sobre materiales de otros vehículos.

## Integración y reversibilidad

- `scripts/ui/G13MaterialFinishV47.gd` exige V46, valida todos los `GeometryInstance3D` reales y prepara las versiones de materiales **antes de modificar la escena**. No agrega nodos de dibujo (delta = 0).
- `scripts/ui/UnitModels3D.gd` aplica `G13SurfaceV47.apply(model)` después de V46 tanto en LOD13 como en LOD8.
- `scripts/ui/BastionStudioAdapter.gd` agrega **Materiales PBR refinados** y **Comparar con V46**; los controles intercambian materiales originales/pulidos **en el mismo modelo** sin alterar mallas, ángulo de cámara, facción ni animación.
- `tests/test_g13_studio_web_v1.gd` verifica la aplicación en ambos LOD, que el material real de cabina se diferencie en `roughness`, que la comparación restaure y reactive los materiales, y que la geometría de cabina conserve su identidad. El flujo también protege el tanque G11 aprobado.

## Restricciones y verificación

La ejecución del visor **#1508** de V46 terminó con éxito en compilación/exportación y publicación de GitHub Pages. **Esto no valida V47**, que debe producir una ejecución propia. No hay cambio en los dos cañones automáticos, radar abatible, ruedas/rodaje, colisiones ni reglas del juego.

La siguiente prioridad será **revisar la V47 renderizada** contra los modelos G09, P06 y G11 aprobados, con las mismas condiciones de luz y cámara. Si las superficies continúan demasiado uniformes, corregir la composición de las formas grandes (cabina y torreta), no multiplicar piezas minúsculas.
