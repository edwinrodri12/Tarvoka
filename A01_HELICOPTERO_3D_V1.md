# TARVOKA — Helicóptero de ataque A01 · V1 (Godot 4.3)

**Estado:** primera escultura 3D implementada en la rama `art/attack-helicopter-v1-20261115`, pendiente de CI y de inspección artística humana 360°. **No es un modelo comercial finalizado.**

## Alcance visual real
- Fuselaje octogonal cerrado generado mediante malla nativa 3D, nariz sellada y cabina en tándem con material acristalado.
- Dos tomas de motor, escapes, paneles de blindaje de color de facción, pequeñas alas portaarmas y ocho tubos de lanzacohetes (cuatro por costado).
- Tren de aterrizaje tipo patín con soportes, viga de cola cerrada, estabilizador y aleta vertical.
- Rotor principal de cuatro palas y rotor de cola de cuatro palas, cada uno con su pivote animable. Cañón frontal sobre soporte independiente y destello de corta duración.
- Ocho variantes de facción, materiales Godot StandardMaterial3D y componentes 3D editables; sin texturas ilustrativas ni reemplazos 2D.

## Integración y preservación
- `UnitModels3D.build("attack_heli", faction, true, 14)` crea la escultura de estudio V1.
- `UnitModels3D.build("attack_heli", faction, true, 10)` conserva exactamente el modelo ligero previo del campo de batalla. No se cambian reglas, costes, combate, colisiones ni estadísticas.
- `UnitModels3D.pose_model` y `restore_model_pose`: vuelo, disparo, impactos y restauración de pose.
- En `BastionStudioAdapter.gd` se incluye la unidad en el selector del Estudio 3D, con vistas frontal/laterales/superior/posterior, animaciones y selección de facción. El Estudio público se despliega tras integrar a `main` y superar la exportación.
- CI: `tests/test_attack_helicopter_v1.gd` y `.github/workflows/a01-helicopter-qa.yml`.

## Siguientes prioridades artísticas
1. Inspeccionar **capturas Godot reales** desde 8 ángulos. Corregir cualquier intersección entre fuselaje, cabina, rotor, pylons y tren de aterrizaje.
2. Refinar biseles, tomas de aire, profundidad de cockpit, rotores y su sombra; evitar piezas flotantes o interpenetraciones.
3. Desarrollar cinco estados de daño físicos y efectos de impacto adecuados al helicóptero; en V1 aún no están implementados.
4. Luego: clima, LOD de producción, capturas de partida y pruebas Android físicas. No declarar FPS ni certificación móvil sin mediciones.

**Visor tras despliegue:** https://edwinrodri12.github.io/Tarvoka/ — seleccionar *Helicóptero de ataque A01*. Si todavía aparece el modelo antiguo, revisar el despliegue y versión de GitHub Pages antes de evaluar V1.
