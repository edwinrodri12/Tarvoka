# TARVOKA — Base Naval V11: contacto caucho–hormigón, herrajes y cadenas con eslabones

## Objetivo de la etapa
Perfeccionar el acabado de la Base Naval 3D, sin alterar V1–V10 ni las reglas de combate, navegación, edificios, captura o economía. El modelo V11 es una **capa adicional** sobre los anclajes V10: todas las versiones anteriores continúan siendo seleccionables en el Estudio 3D.

## Mejoras reales en Godot 4.3
- **Juntas de contacto en el muelle Este:** caucho elastomérico entre la defensa tubular V9 y el paramento real V2 en x=1.125. La junta penetra 0.017 m en el hormigón para impedir separación visible entre elementos. Pequeños cantos, ménsulas, remaches y marcas de facción; desgaste según el estado.
- **Espigones:** juntas ajustadas a z=±4.30, orejas laterales y pernos de cabeza visible. Las piezas se colocan en ambos lados desde coordenadas reales de muros y bolardos V1; los espigones ausentes por daño no reaparecen.
- **Retención:** se ocultan los cilindros rígidos V10 cuando V11 está activa y se muestran eslabones ovalados de acero construidos en `ArrayMesh`. Para no multiplicar los nodos/draw calls, cada cadena utiliza `MultiMeshInstance3D` con 3–9 instancias alternadas, aplicadas sobre la trayectoria exacta que ya unía la defensa con su retenedor. **Las argollas de amarre de buques quedan libres.**
- **Acabado de daño:** estados 0–1 con juntas, pernos y bandas completas; estado 2 pierde defensas/soportes predefinidos y muestra corrosión; 3 conserva únicamente juntas rotas donde existe el espigón, con cadenas operativas eliminadas; 4 presenta fragmentos sin recrear defensas ni pavimentos.
- **Zoom:** piezas cercanas y perfiles tácticos simplificados a distancia; vista nocturna aprovecha la iluminación V6 y señalización V10, sin luces extra.

## Integración obligatoria en TARVOKA Estudio 3D
`Edificios 3D → Base Naval V11`. Interruptor **V11 · sellos, herrajes y eslabones (comparar V10)**. Se conservan las seis cámaras anteriores, los tres niveles, ocho facciones y cinco daños. Se añade una séptima cámara **Unión caucho y hormigón** para revisar el contacto a escala cercana desde el agua.

## Pruebas
- `scripts/ui/NavalContactFinishV11.gd`
- `scripts/ui/CombinedArtStudioWeb.gd`
- `tests/test_naval_base_v11_gpu.gd`
- `.github/workflows/naval-base-v11-gpu.yml`

Godot 4.3/OpenGL debe probar 40 variantes, tres niveles, geometrías de junta y eslabones, comparador V10/V11, siete vistas y ocho capturas reales. No se considera verificado ni publicado hasta recibir resultados positivos de CI.

## Alcance fuera de esta fase
Integración APK Android, comportamiento real de atraque, colisiones, efectos hidrodinámicos y benchmark FPS aún no probados. No añadir nuevos modelos ajenos al proyecto.
