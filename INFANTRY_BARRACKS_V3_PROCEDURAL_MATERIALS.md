# TARVOKA · Cuartel de Infantería V3 · materiales y proporciones

## Alcance aprobado de la siguiente prioridad
V3 **no genera imágenes**, sino que aplica directamente materiales físicos y remates 3D a los mismos meshes de Godot 4.3. Se conserva V1, V2, los tres escalones de arquitectura, la cámara del patio y la pista N3 corregida.

## Acabado material real
- Siete clases de superficies nativas diferenciadas: hormigón, cubierta metálica, acero galvanizado, pavimento, cristal, escombro y entrenamiento.
- Cada textura es **ImageTexture creada determinísticamente en Godot a partir de píxeles procedurales**, sin descargar fotografías ni usar arte conceptual. Cada mapa es pequeño (48×48), reutilizado en todas las mallas y facciones.
- Materiales StandardMaterial3D con rugosidad y metalicidad diferenciadas: hormigón mineral mate, techos en chapa, herrería menos rugosa, cristal de brillo contenido, polvo y ruina.
- **Pintura de facción intocable:** banderas, placas y marcas conservarán su color original sin capa gris.
- Cubiertas con nervaduras/sellos finos **solo sobre paneles realmente existentes**. No se cierran agujeros de daño, no se añade tejado donde V1/V2 lo habían retirado.
- Zócalos posteriores de contacto, goterón y rejillas de ventilación en niveles 2/3. Los zócalos son estrechos para no invadir las otras alas.
- Daños progresivos: polvo/oxidación sutil en etapas intermedias, ningún elemento operativo añadido al estado destruido.

## Niveles: mantener progresión de silueta
1. N1: una sola barraca con cubierta baja y equipamiento básico. Sin torre y sin ventilación mecánica posterior compleja.
2. N2: edificio en L de dos plantas con una torre arriostrada, cubiertas y rejillas.
3. N3: complejo en U con mando de tres plantas, alas dobles, dos torres y **pista lateral de entrenamiento físicamente despejada** después de la corrección de V2.

## Estudio 3D
Cuarto edificio, **Cuartel de Infantería V3**. Dos checkboxes:
- V2 · accesos, cristales y torres: activar/desactivar detalles nativos V2 contra V1.
- V3 · materiales y proporciones: activar/desactivar pasada V3 sobre V2 para comparar verdaderos modelos dentro del mismo estudio; se deshabilita si V2 está apagado.

La selección de nivel, daño, facción, rotación y cámara permanece operativa; el modo Cuartel General, Base Aérea y Base Naval no se toca.

## Verificación
- `scripts/ui/InfantryBarracksMaterialsV3.gd`: acabados PBR y geometría de superficie.
- `tests/test_infantry_barracks_v3_gpu.gd`: 120 variantes (8 × 5 × 3), acumulación V1+V2+V3, geometría sin nuevos techos en ruinas, pintura intacta, sombreado diferenciado, tres modelos previos, catorce capturas OpenGL, comparación V2/V3.
- `.github/workflows/infantry-barracks-v3-native-gpu.yml`: Godot 4.3 nativo, Xvfb y capturas.

**Estado:** no declarar QA aprobada sin consultar el resultado de Actions. Despliegue público y APK de Android son procesos separados. V3 no cambia la economía, reparaciones, fabricación ni cifras de balance.

## Próxima pasada cuando se apruebe QA
Inspeccionar las 14 capturas desde varios ángulos, confirmar lectura de techos y materiales a zoom de juego, examinar manchas, sombras, puerta y pista N3. Ajustar cualquier defecto observado antes de dar el diseño por definitivo.
