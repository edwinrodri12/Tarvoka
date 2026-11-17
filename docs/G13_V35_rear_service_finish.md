# TARVOKA G13 V35 — acabado posterior y tren de servicio

**Estado:** modelado 3D nativo incorporado al repositorio para LOD8/LOD13 y menú del visor. **Pendiente**: confirmación de compilación Godot, inspección visual y despliegue web. Esta revisión NO supone aprobación final de la unidad.

## Diseño

- **Compuerta posterior:** un panel físico 3D de ocho esquinas con caras anterior y posterior y paredes cerradas. Se coloca sobre la puerta posterior real en LOD13 y sobre el monocasco en LOD8, a distinta altura según geometría disponible. Cuatro fijaciones comparten un `MultiMesh`.
- **Escape protegido:** dos tubos cortos metálicos sobre la zaga baja, con *boca abierta real* (superficie interna y labios anulares modelados, sin un disco que tape el orificio). A cada tubo le corresponden dos piezas de cubierta/blindaje.
- **Tren trasero:** cuatro pequeñas piezas de arriostramiento y protección bajo la zaga, dentro de la cara interior de las ruedas; no alteran la posición ni la animación de las ruedas o los ejes.
- **Color:** se mantiene íntegro el acabado de facción definido en V32; acero oscuro, metal mate y protector grafito en piezas puramente mecánicas.
- **Compatibilidad:** no se añaden lanzacohetes, misiles, armas, datos de ataque ni nodos de iluminación. Se conservan los dos cañones originales, la elevación, el radar plegable V29, las cuatro ruedas, y los parachoques y arcos V33/V34.

## Código integrado

- `scripts/ui/G13RearServiceFinishV35.gd`: geometría procedural real, verificación de V34 y comparador de visibilidad `show_finish()`. **Cinco nodos de dibujo nuevos:** panel, fijaciones, tubos, protectores y arriostramientos.
- `scripts/ui/UnitModels3D.gd`: carga V35 inmediatamente después de V34 en los modelos G13 LOD8 y LOD13.
- `scripts/ui/BastionStudioAdapter.gd`: categoría G13 V35, botones **Mostrar escapes y compuertas** y **Comparar con V34**. Se usa el mismo modelo/cámara/facción, sin reconstruir otra escena.

## Próxima prioridad propuesta

V36: revisar el acabado visual general del 4x4, especialmente coherencia de dimensiones de la zaga, posición de paneles y radios de los guardabarros, antes de declarar terminada la escultura. Continuar con mejoras de diseño y no asumir pruebas de rendimiento Android o compilación web realizadas.
