# TARVOKA — atlas de sprites Android 32 × 4

Fecha: 2026-11-12. PR experimental apilada sobre la primera pasada artística (#142), que depende del tablero isométrico (#139).

## Objetivo y resultado

Pasamos de dibujar un símbolo complejo cada fotograma a disponer de un **atlas PNG real de 128 fotogramas**, indexados por 32 roles y cuatro poses:

| Pose | Clave | Uso en batalla |
| --- | --- | --- |
| Reposo | `idle` | La unidad espera o acaba de ser seleccionada |
| Desplazamiento | `move` | Interpolación visual durante 0,32 s |
| Ataque | `attack` | Parte inicial del efecto de disparo |
| Dañado | `damaged` | Estado de advertencia con HP críticos |

El archivo es **768 × 1536 px, RGBA**, con casillas de 96 × 96 y fondo transparente. Se reutiliza para ocho facciones aplicando `VisualStyle.faction_color()` al dibujar. No replica sprites y no altera la identidad, comandantes ni emblemas ya aprobados.

**Importante:** estas son siluetas originales **de producción técnica**, aún sujetas a una revisión visual en teléfono. No son 32 modelos 3D definitivos ni el arte final aprobado por el usuario. Las identidades y balance v0.1 permanecen intactos.

## Única fuente de verdad

- `scripts/ui/UnitSpriteAtlas.gd`: 32 diseños SVG escritos en GDScript, rasterización interna de Godot, regiones y textura compartida.
- `scripts/ui/IsoRenderer.gd`: pinta el fotograma correcto según movimiento, disparo y daño; HP, iconos, alcance y niebla siguen en el motor táctico.
- `scripts/ui/UnitArtIcon.gd` y `UnitArtGallery.gd`: la galería presenta los **mismos sprites** que la batalla; permite cambiar entre cuatro poses y ocho colores de facción.
- `scripts/ui/UnitArt.gd`: siluetas vectoriales procedimentales previas retenidas como respaldo, no borradas.
- `tools/export_unit_atlas.gd`: exporta PNG y manifiesto JSON sin GPU, sin Internet, sin Python y sin herramientas de pago.
- `tests/test_sprite_atlas.gd`: valida dimensiones, 128 regiones sin superposiciones, alfa real y arte no vacío, además de que el tablero conserva su estado.

## Cómo generar e inspeccionar

Ejecutar desde la carpeta de la app en una computadora con Godot 4.3:

```bash
godot --headless --path . --script res://tools/export_unit_atlas.gd
```

Producción:
- `assets/generated/tarvoka_units_32x4.png`
- `assets/generated/tarvoka_units_32x4.json`

La compilación Android de GitHub Actions **genera el PNG antes de importarlo a Godot**, lo incluye dentro de la APK y publica un artefacto descargable llamado `TARVOKA-Sprites-32-units-4-states`. Las pruebas de reglas regeneran y validan las mismas imágenes.

`UnitSpriteAtlas` también puede crear el atlas dentro de Android en memoria si el PNG no está incluido (entornos de desarrollo manuales). Esto impide que una imagen aún no generada vuelva imposible abrir el juego.

## Restricciones para no romper jugabilidad

- Animaciones, hitboxes de pantalla y colisiones no alteran coordenadas de batalla `Vector2i`, efectos, economía, IA, munición ni guardados.
- La niebla oculta enemigos y sus movimientos; un sprite nuevo **no puede filtrar información** que la capa `Visibility` oculta.
- La animación de ataque para clases sin armas no simula un disparo: solo muestra un estado de alerta en la galería.
- No hay financiación, anuncios, microtransacciones ni publicación comercial introducidos en esta PR.

## Próximos pasos

1. Revisar legibilidad y diferencias de clase a 18–30 px y 50–80 px en Android real.
2. Pasar de poses de cuatro cuadros a animaciones de desplazamiento direccional, salvas, giro de torretas y destrucción según tipo, después de aprobar las siluetas.
3. Añadir minis de edificios/terreno al pipeline y optimizaciones de mapa ampliado/minimapa.
4. Validar en hardware menor uso de draw calls y tiempo de primera activación; documentar una prueba de rendimiento reproducible.

No fusionar esta PR hasta que #139 y #142 estén integradas, sin sustituir los cambios tácticos de la automatización.
