# TARVOKA — Base Naval V10 · alineación real de defensas y bolardos

## Prioridad artística
Conectar visualmente las defensas marítimas V9 a la geometría real de muelles y amarre. Los anclajes tienen soporte físico y no flotan frente a paredes; los bolardos y argollas originales siguen disponibles para embarcaciones. No se cambia el juego Android, la economía, la física o las colisiones.

## Referencias existentes
- **Muelle Este:** el paramento marítimo de hormigón V2 llega a **x=1.125**. Los cuerpos de caucho V9 están en x=1.04 y z=-4.10+1.35×índice. Las cuatro argollas V3 se ubican en **(1.70, 0.73, -3.75+2.43×estación)**.
- **Espigones:** el paramento interior está en z=±4.30. Los cuerpos V9 están en z=±4.19 y en x=-5.10+1.83×índice. Los bolardos reales V1 están en x=-5.05+1.86×índice, y=0.71, z=±4.85.
- En daño crítico desaparece el espigón positivo; V10 tampoco añade piezas a ese sector.

## Mejora añadida
- **Muelle Este:** placas de acero embutidas, ménsulas reforzadas y pernos, con un pequeño cable de retención que llega a un anclaje independiente sobre el borde del muelle. Las defensas de índice 0, 2, 4 y 6 están correlacionadas con las estaciones V3 0–3. La argolla de amarre del barco queda libre, sin cable de defensa atravesándola.
- **Espigones:** respaldos metálicos colocados en la cara interior real, pernos y doble tramo de cadena hasta retenedores de cubierta alineados con los bolardos originales. Se ocultan las cadenas simples V8 cuando se ve V10 para evitar duplicaciones.
- **Daños:** piezas completas solo en estados 0–1; estado 2 conserva soportes deteriorados y omite componentes faltantes; estado 3 muestra deformación sin restaurar el espigón cortado; estado 4 solo añade restos metálicos, nunca defensas operativas.
- **Zoom:** la cámara cercana muestra placas, tornillería y cables, mientras la distante utiliza marcas tácticas discretas. **Noche:** guías reflectantes de baja emisión, vinculadas al interruptor nocturno existente.

## TARVOKA Estudio 3D
El nuevo control **V10 · anclajes, bolardos y soportes (comparar V9)** preserva V1–V9 y las 8 facciones, 3 niveles, 5 daños, iluminación, zoom y rotación. La sexta cámara **Anclajes y bolardos** se suma a las cinco anteriores, sin sustituirlas.

## Validación Godot 4.3
`tests/test_naval_base_v10_gpu.gd` verifica la posición con respecto al verdadero muro Este, bolardos V1 y argollas V3, daños, pares, zoom y modo nocturno. `.github/workflows/naval-base-v10-gpu.yml` ejecuta Godot nativo/OpenGL y guarda 8 capturas para inspección. **No describir pruebas ni publicación como aprobadas hasta que GitHub Actions las confirme**.

## Siguiente etapa
Revisar visualmente escala y contacto entre acero, caucho y hormigón en capturas, y luego finalizar el conjunto de modelos de defensa portuaria para integración artística en el juego. No asumir FPS Android sin pruebas reales.
