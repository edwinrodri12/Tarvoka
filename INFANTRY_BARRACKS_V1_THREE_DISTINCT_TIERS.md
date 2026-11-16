# TARVOKA · Cuartel de Infantería V1 · tres niveles realmente distintos

## Decisión de diseño
El Cuartel de Infantería será un **edificio productor fijo del mapa, capturable y limitado por escenario**, no uno de los campamentos construibles por unidades especializadas. En el catálogo de economía actual la infantería se fabrica en instalaciones `factory`; este prototipo de arte **no cambia** esa economía ni crea un nuevo tipo de productor antes de una migración validada.

## Tres arquitecturas visibles y progresivas (mismo lote de 16,2 × 13 m)
- **Nivel 1 — puesto de reclutas:** UN edificio de barracas de UN piso, patio de formación con marcas, pista pequeña con dos obstáculos, armario de equipamiento. Altura arquitectónica 2,94 m. Su perfil es compacto y asimétrico.
- **Nivel 2 — cuartel operativo:** NUEVA silueta **en L**: bloque principal de DOS plantas, ala lateral de instrucción, una torre de supervisión sobre cuatro soportes, pasarela de conexión y pista ampliada con barras. No se limita a repintar/agrandar V1.
- **Nivel 3 — complejo de guarnición:** NUEVA silueta **en U** con edificio central de TRES plantas, DOS alas laterales de dos pisos, DOS torres de vigilancia, patio central despejado y marcado para despliegues, pasarelas elevadas, más obstáculos y muros de práctica. Claramente distinto de la L del nivel anterior.

Al elegir un nivel en el visor se **reconstruye la arquitectura correspondiente**; no hay piezas de los otros niveles ocultas dentro de la escena. La tierra y el patio exterior mantienen la misma referencia espacial para poder comparar tamaños y lectura en juego.

## Identidad de TARVOKA
- Ocho facciones con acentos selectivos en entrada, franja del patio, remates, torres y bandera, sin repintar todo el hormigón.
- Cinco daños VISUALES por nivel, con auténticos huecos de techo por paneles eliminados, muros fracturados, pérdida de cristales y estado final de SOLO cimentación y escombros.
- Modelado totalmente nativo en Godot 4.3: mallas, materiales y geometría espacial, no imágenes ni sprites de ejemplo.
- Un nivel NO equivale a una mejora de las estadísticas ni a producir más unidades de forma automática; eso se define y prueba después en el balance.

## Estudio 3D
- `Edificios 3D → Cuartel de Infantería V1`
- Selector niveles 1, 2 y 3 con explicación de su geometría
- Selector 5 daños
- Cuatro cámaras: conjunto, patio, pista de entrenamiento y cubiertas
- Selector compartido de ocho facciones; rotación, zoom y controles de iluminación existentes
- Mantiene Cuartel General, Base Aérea V16 y Base Naval V13; no reincorpora el Taller Militar descartado

## Archivos y verificación
- `scripts/ui/InfantryBarracks3DV1.gd`
- `scripts/ui/CombinedArtStudioWeb.gd`
- `tests/test_infantry_barracks_v1_gpu.gd`
- `.github/workflows/infantry-barracks-v1-native-gpu.yml`
- 120 variantes estructurales (8 facciones × 5 daños × 3 niveles) y 11 capturas reales, incluidos los tres niveles bajo EXACTAMENTE el mismo encuadre.

**Estado:** primera fase de modelado; la aprobación visual requiere revisar renders auténticos de Godot. No afirmar publicación web, FPS Android o incorporación a partidas hasta comprobarlo.

## Próxima prioridad visual
Revisar desde todas las cámaras las uniones de las alas en U, accesos, alturas de forjados, torres, cristales y pérdida de paneles de techo. Mejorar específicamente lo que esté mal en el modelo, no añadir detalles arbitrarios.
