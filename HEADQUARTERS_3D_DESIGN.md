# TARVOKA — Cuartel General en 3D: fase 1

**Referencia visual**: lámina de la Biblioteca *Advanced wars* **«Infografía del Cuartel General de Tarvoka.png»** (12 de noviembre de 2026). Conservar la identidad de la forma y la combinación de instalación administrativa, radar, antenas, cercado, patio logístico y helipuerto. **La lámina no es todavía un recurso binario incorporado a GitHub.**

## Entregado
- **Geometría 3D genuina y editable** en Godot 4.3: `scripts/ui/Headquarters3D.gd`.
- **Visor autónomo**, con cámara ortográfica isométrica, rotación por arrastre/botón, zoom, selección de tres niveles, ocho colores de facciones oficiales y cuatro estados: `scenes/HeadquartersShowroom.tscn`.
- Nivel 1: cuerpo de mando, alas, ventanas, pórtico y escalinata, radar parabólico y mástil, helipuerto elevado marcado con H, cerca, portería, accesos y elementos logísticos.
- Nivel 2: se eleva el edificio, se construye torre de comunicaciones con cabina panorámica, se amplía el despliegue técnico y aparecen paneles solares.
- Nivel 3: radomo, antenas de mayor longitud, ala técnica adicional y acceso elevado al helipuerto.
- Estado dañado: cristales rotos, revestimiento chamuscado, escombros y humo transparente, sin afectar mallas de la versión sana.
- Estado destruido: ruinas volumétricas distintas del edificio operativo; no oscurecer un modelo intacto para simular pérdida.
- Capturado: cambia la facción **propietaria** e incluye marca de cambio de control. Los colores son piezas arquitectónicas sustituibles, no un tinte aplicado a todo el hormigón.

## Al diseñar el arte final
1. Reemplazar el bloque constructivo por superficies propias con biseles, uniones y soldaduras, puertas articuladas, tensores, bajantes y cableado.
2. Añadir atlas PBR original (hormigón pintado, ventanas, acero, marcas de desgaste y tierra) con UV, normales y oclusión; no utilizar texturas de otra franquicia.
3. Conservar el helipuerto reconocible, el radar y la silueta escalonada de la lámina original, pero con proporciones legibles al tamaño de casilla en Android.
4. Separar las zonas pintables por nombres/metadatos; el color de facción nunca modifica ventanas, suelo ni plataformas de combate.
5. Mantener las versiones de 3 niveles y los estados de daño visibles tanto en el inspector como en partida.
6. Exportar LOD de vista cercana/lejana, hornear iluminación si se necesita y medir rendimiento real en teléfono; las primitivas de fase 1 todavía no son producción artística final.
7. No asignar valores definitivos de ingresos, visión, defensa, desbloqueos, HP ni tamaños de cuadrícula a partir de las infografías de arte: esas son cuestiones de jugabilidad independientes.

## Cómo abrirlo, sin compilar APK
Abre el proyecto de Godot y la escena `scenes/HeadquartersShowroom.tscn`; pulsa **F6** (ejecutar escena actual). Puedes seleccionar las ocho facciones oficiales, comparar niveles 1–3, ver operativo/capturado/dañado/destruido, girar el edificio, hacer zoom y restablecer la cámara.

**Nota de integración**: no cambia `Main.gd`, `TouchBoard.gd`, `WorldArt.gd`, `UrbanEconomy.gd` ni los archivos del visor 3D de unidades. La incorporación al menú visual del juego se hará cuando la cadena de PRs del laboratorio 3D de unidades quede consolidada, para evitar conflictos con el trabajo del tanque.

## QA
- `tests/test_headquarters_3d.gd`: valida niveles, 8 facciones, piezas pintables y estados; verifica que la escena del inspector crea nodos 3D auténticos sin tocar estados de batalla.
- Acción CI dedicada `.github/workflows/headquarters-3d-validation.yml` con Godot oficial 4.3.
- **No confundir** tests headless con aprobación visual de Android, glTF final ni prueba FPS en Galaxy.

## Próximos edificios
Conservar el catálogo aprobado del 12/11/2026. Siguiente: Cuartel de Infantería y Fábrica de Vehículos. No reinventar ni incorporar por error los edificios de estilo medieval.
