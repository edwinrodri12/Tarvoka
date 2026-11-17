# Cuartel de Infantería — Arte 3D V11 FINAL / APROBADO

**Fecha de aprobación artística:** 16 de noviembre de 2026  
**Estado:** DISEÑO DEFINITIVO. No añadir más adornos, remodelaciones ni nuevas versiones artísticas sin una nueva indicación expresa del usuario.

## Identidad definitiva

El modelo original aprobado es el mismo que se construyó y revisó en TARVOKA Estudio 3D. Las 11 capas Godot se conservan como código editable en `scripts/ui/InfantryBarracks3DV1.gd` … `InfantryBarracksWindowShadeV11.gd`.

- **Nivel 1:** barraca compacta de una planta.
- **Nivel 2:** complejo en L de dos plantas con torre de vigilancia.
- **Nivel 3:** complejo en U de tres plantas con dos torres, patio y pista de entrenamiento exterior occidental despejada.
- **Colores:** ocho facciones oficiales, mediante `VisualStyle` y `FactionIdentity`.
- **Daños:** cinco apariencias visuales (intacto, leve, moderado, grave, destruido) sin restaurar paredes o ventanales desaparecidos.
- **Detalles finales:** puertas, escalones, ventanas laterales y frontales con marcos 3D, materiales PBR, ventilación, viseras, azoteas, torres y acabado militar.

## Integración en la partida real

`InfantryBarracksBattle3D.gd` compone el modelo **V11 exacto** en el renderizador de la vista 3D de batalla `BattleTerrain3D.gd`; no utiliza capturas de pantalla como textura ni una escena 3D falsa. Se escala al espacio de la casilla sin cambios de selección o colisión. `SiteOverlayPainter.gd` dibuja una versión tácticamente legible de la misma silueta en los modos 2D clásico e isométrico.

**Correspondencia actual:** los sitios preexistentes de tipo `factory` (producción básica) usan la apariencia del Cuartel de Infantería aprobado en partida. Esto es **un cambio visual**, no crea un nuevo edificio funcional ni cambia la producción. El futuro diseño de instalaciones militares especializadas puede independizar los cuarteles del tipo `factory`, pero esa decisión requiere una modificación de economía y jugabilidad distinta.

Los mapas pueden indicar `visual_level` = 1, 2 o 3 para representar una instalación preexistente. Predeterminado: nivel 1. `visual_damage_stage` (0–4) es también exclusivamente gráfico. No confundir ninguno de ambos campos con mejoras de producción, salud ni permisos para construir instalaciones. **Los únicos edificios construibles por la infantería especializada siguen siendo los campamentos**, según las reglas ya definidas.

La niebla de guerra impide dibujar instalaciones no descubiertas y sustituye la facción desconocida por un aspecto neutral. Capturas, turnos, créditos, compra de unidades, balance, guardados y demás edificios se mantienen sin cambios.

## Verificación y enlaces

- Visor de modelos 3D compartido: https://edwinrodri12.github.io/Tarvoka/
- Integración al juego principal: PR #489.
- Prueba nativa automatizada: `tests/test_infantry_barracks_battle_v11.gd`.
- APK Android: debe compilarse en Godot 4.3 y superar CI antes de considerarse versión final publicada.

**Directriz creativa:** NO continuar con una V12 de este edificio por iniciativa propia. El siguiente trabajo artístico debe pasar a otra unidad o edificio pendiente.
