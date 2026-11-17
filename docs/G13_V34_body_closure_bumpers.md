# TARVOKA — G13 V34: cerramientos de blindaje y defensas

Estado: **geometría 3D creada e integrada en Godot y Studio; inspección visual, compilación y publicación pública no confirmadas**. Todavía no es una unidad definida como finalizada.

## Escultura V34

- **Juntas perimetrales de la cabina:** dos montantes y un travesaño de sellado por lateral, colocados fuera de las lunas de V11 y de las placas de facción V32.
- **Cierre posterior:** en LOD13, marco de cuatro barras en el contorno de la puerta de mantenimiento real; en LOD8, marco de cuatro barras sobre la tapa de motor trasera. En ambos casos las piezas conservan la base del radar V28–V30.
- **Cierres de mantenimiento:** dos tiradores bajos compuestos por cuatro elementos (asa y soporte) en ambas versiones.
- **Frente:** reborde de protección metálico y dos extremos robustecidos, situados por debajo de los faros V23 y de la rejilla V24. Se conserva el parachoques original, sin reemplazar su geometría.
- **Trasera:** barra transversal reforzada, protecciones de extremos y dos guías verticales antirroce por debajo de las insignias de facción.
- **Materiales:** goma de juntas oscura, acero mate para tiradores, acero protector para parachoques y acabado de grafito en los protectores. La pintura de las ocho facciones y las placas V32 se conservan.

### Coste geométrico y compatibilidad

- Nuevo archivo: `scripts/ui/G13BodyClosureV34.gd`.
- Se añaden **4 instancias MultiMesh** (un nodo de dibujo por tipo de acabado), con 10 segmentos de junta, 4 componentes de cerraduras, 6 componentes de parachoques y 2 protecciones posteriores.
- El archivo valida la jerarquía de la carrocería existente y depende de la marca V33 antes de instalar piezas.
- No modifica `BattleSession`, estadísticas, armamento, rotaciones, radar, ruedas ni animaciones de tierra/aire.
- LOD13 y LOD8 aplican exactamente la misma lógica visual con posiciones adaptadas al modelo real disponible.
- `show_finish(root, enabled)` activa/desactiva V34 dentro del modelo activo. Permite comparación auténtica con V33 sin crear clones.

## Integración del visor

- `scripts/ui/UnitModels3D.gd`: `G13ClosureV34.apply(model)` inmediatamente después de V33 en ambas ramas del rol `aa_mobile`.
- `scripts/ui/BastionStudioAdapter.gd`: categoría G13 con botones **Mostrar acabados del chasis** y **Comparar con V33**. Se conservan las opciones de V31/V32/V33 y todos los efectos visuales anteriores.

## Próxima prioridad de arte — V35

Completar la zaga técnica, incluidas compuertas de acceso, escapes protegidos y detalles de uniones del tren trasero. Mantener todo como escultura 3D nativa, no añadir armas ni someter la unidad a aprobación definitiva antes de inspeccionar las piezas.
