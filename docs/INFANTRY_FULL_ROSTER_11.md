# TARVOKA — Catálogo completo de infantería en el Estudio 3D (V4)

Este cambio completa las **once configuraciones visuales** definidas en las conversaciones del 12 al 20 de noviembre de 2026. Todas usan geometría nativa Godot 4.3; el único visualizador es `scenes/UnitArtStudioWeb.tscn`.

| Rol del Estudio | Apariencia |
| --- | --- |
| `line` Guardia G01 | Soldado estándar con fusil |
| `infantry_urban` Guardia urbana / Asaltante | Escudo y armadura urbana |
| `infantry_defense` Guardia defensiva | Blindaje corporal reforzado |
| `scout` Rastreador G03 | Ópticas de reconocimiento |
| `infantry_antitank` Rompedor G04 | Arma antiblindaje |
| `infantry_engineer` Ingeniero G05 | Equipo técnico |
| `infantry_sniper` Francotirador | Fusil largo, visor y bípode |
| `infantry_aa` Antiaéreo a pie | Lanzador SAM portátil, no G13 |
| `infantry_logistic` Logístico a pie | Mochila, herramientas de suministros, no G16 |
| `infantry_medic` Médico de combate | Botiquín verde, distintivo sanitario blanco |
| `infantry_commando` Comando FS-24 | Óptica nocturna, arma especial y radio |

Los cinco últimos tienen geometría propia adicional en `scripts/ui/InfantryVariantsV4.gd`, más sus perfiles de referencia V1. La evolución de detalle ya disponible permite alternar LOD13 y LOD8, comparar V1/V2, girar 360° y repintar las ocho facciones **en el mismo SubViewport**.

**No se activan nuevas clases tácticas:** ninguna clave `infantry_*` nueva entra en ModernArsenal ni en producción, costes, captura, medicina, avistamiento, reglas de campamentos o guardados. En diseños previos, la Guardia urbana cubre al Asaltante; el Baluarte blindado y el Lanzador mecanizado son vehículos y no se duplican aquí como infantería. Más adelante, el juego puede conectar el arte a las mecánicas aceptadas, como la reparación pagada del Ingeniero, la precisión antiinfantería del Francotirador y la ocupación de campamentos por Médico/Logístico, tras verificar su integración independiente.

La aceptación requiere pruebas nativas: **176 combinaciones**, 18 capturas V1 y 41 V2/V4, prueba del visor real con once roles, materiales opacos, animaciones y ausencia de errores Godot. No declarar publicación hasta validar CI y despliegue.
