# TARVOKA — primer prototipo isométrico jugable

Actualizado: 2026-11-12. Estado: rama experimental superpuesta sobre `feat/visual-foundation-eight-factions-20261112`.

## Implementado

- `scripts/ui/IsoProjection.gd`: proyección geométrica diamante 2:1 de la misma cuadrícula táctica 10×8 y la inversión exacta de coordenadas de toques a celdas.
- `scripts/ui/IsoRenderer.gd`: dibujado original sin assets copiados: terreno, relieves decorativos, niebla, objetivos, instalaciones, unidades terrestres/aéreas/navales, alertas M/F, HP, coste de movimiento, vista previa de daños y destellos de combate.
- `TouchBoard`: modo de dibujo conmutable que **no** cambia movimientos, alcance, IA, economía, guardados ni municiones; arrastrar desplaza cámara sin mover unidades; zoom permite acercar/alejar y restablecer la vista.
- `Main`: controles «Vista isométrica», «Vista clásica», +/- y «Centrar mapa» en la barra lateral Android.
- Vista clásica predeterminada para que ninguna partida anterior cambie inesperadamente de controles.
- `tests/test_isometric_board.gd`: comprueba geometría y aciertos de celdas, turnos y toques reales, cambio de visualización, zoom, gesto sin acciones accidentales y estado intacto.
- CI ejecuta la prueba nueva junto a la batería anterior.

## Reglas de seguridad

1. Las coordenadas de tablero siguen siendo enteros `Vector2i`; la vista es 100% presentación. No agregar coordenadas de pantalla ni preferencias de cámara a `SaveCodec`.
2. Niebla: no pintar unidades enemigas fuera de visión, no revelar lugares o propietarios aún desconocidos, no descubrir atacantes ocultos por efectos de combate.
3. Los indicadores de movimiento y ataque proceden exclusivamente de `TacticalHints`, no de predicción visual.
4. Zoom y desplazamiento no producen compras, fin de turno, recargas ni órdenes; un gesto invalidado nunca se considera tap.
5. Mantener la alternativa clásica mientras no se compruebe usabilidad de Android físico y rendimiento en mapas mayores.

## Pendiente antes del acabado artístico definitivo

- Incorporar físicamente las ocho artes aprobadas, con trazabilidad de la imagen original.
- Sustituir símbolos provisionales por atlas originales de las 32 clases jugables, edificios y biome tiles.
- Cerrar problemas de legibilidad en teléfonos pequeños; validar minimapa, profundidad de sprites, animaciones, gestos multitáctiles y accesibilidad cromática.
- Probar pantallas 19.5:9, portrait y landscape en hardware Android, especialmente selección de unidades aérea/suelo apiladas.
- Escalar de la cuadrícula 10×8 a mapas grandes sin degradación; usar culling/tiles instanciadas y separar UI de cámara.

**No declarar arte 3D completo, modelos finales ni APK comercial** por esta fase.
