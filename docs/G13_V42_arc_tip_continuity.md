# TARVOKA G13 — V42: cierre radial de puntas de guardabarros

**Estado:** corrección geométrica real en el código nativo de Godot, integrada al Estudio 3D y a los dos LOD. Inspección visual renderizada real y publicación web **no verificadas**. La G13 sigue en fase de acabado.

## Problema detectado en el diseño

Los guardabarros exteriores V40/V41 se detenían en theta=0,25 rad hasta theta=PI-0,25 rad, a unos 14,3° de cada extremo de la semicircunferencia. Aunque su geometría era estanca, el borde de cada arco terminaba abruptamente antes de llegar a la línea de eje y podía quedar con un corte visible en vistas laterales y tres cuartos.

## Solución V42

La V42 edita únicamente el `ArrayMesh` de `G13_V40_CurvedOuterFenders` (presente en V41). No crea ni borra objetos de escena.

1. **Cuatro arcos completos:** 16 segmentos por lado, desde theta=0 hasta PI, compartidos en un único recurso e instanciados en Z=-0,85 y +0,85 para los cuatro neumáticos; malla cerrada de **264 triángulos** por recurso compartido.
2. **Puntas empotradas en el arco V33:** en theta=0/PI cada sección ocupa |X|=0,786..0,804 y radios 0,358..0,419 m, enteramente dentro de V33 (|X|=0,699..0,811; radios 0,354..0,419 m). Así cada punta desaparece bajo el guardabarros original en lugar de quedar como una lengüeta.
3. **Transición gradual:** el extremo estrecho se abre con `smoothstep` hacia la coronación |X|=1,005 y radios 0,348..0,427 m. Holgura radial mínima respecto al neumático de referencia: 0,348−0,324=**0,024 m**.
4. **Comparación reversible:** se guardan los recursos reales V41/V42 y `show_finish(root, enabled)` los intercambia sin modificar el número de instancias, sus materiales, el esquema de colores ni la animación del vehículo. Si V40 está oculto por un control histórico, se restaura antes de comparar.

## Integración y compatibilidad

- `scripts/ui/G13ArcTerminationV42.gd` — clase `TarvokaG13ArcTerminationV42`, con validación de jerarquía y cotas antes de modificar la malla.
- `scripts/ui/UnitModels3D.gd` — aplica la corrección después de V41 en el modelo detallado LOD13 y el táctico LOD8.
- `scripts/ui/BastionStudioAdapter.gd` — cambia los títulos a V42 y añade **Puntas curvas integradas** / **Comparar con V41** sobre el mismo modelo 3D. Mantiene los controles de ocho vistas 360° introducidos en V41.
- Cero nodos nuevos de dibujo, cero luces nuevas, ninguna nueva arma.
- Se conservan el radar abatible, las ruedas existentes, los disparos de dos cañones automáticos, todas las animaciones y las ocho facciones.
- El rol `aa_mobile` sigue siendo de presentación artística; no se registra como unidad de combate jugable.

## Evidencia y límites

La geometría y sus cotas se inspeccionaron en los archivos, y la clase se guardó en el repositorio. No hay sesión gráfica de Godot ni capturas renderizadas verificadas desde este entorno. La corrección aborda **un defecto geométrico demostrable** (los arcos anteriores estaban limitados a 0,25..PI−0,25), pero el aspecto final solo podrá considerarse aprobado tras visualizarla realmente.

## Próxima prioridad

Completar la inspección visual de G13 V42 desde los ocho ángulos, especialmente el empalme de las puntas con V33, las uniones de V36/V39 y el espacio libre respecto a los neumáticos. Corregir solo problemas observados. Si el resultado se ve bien, decidir si se cierra el modelado artístico y se pasa a la integración jugable; evitar nuevas iteraciones cosméticas sin defectos concretos.
