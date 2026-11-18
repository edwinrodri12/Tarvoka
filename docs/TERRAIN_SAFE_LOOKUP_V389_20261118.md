# TARVOKA v3.8.9 — Defensa de límites en vista previa del terreno

**18 noviembre de 2026. Corrección acotada de robustez de motor. No cambia balance ni el mapa del juego.**

## Hallazgo

La [CI general de Godot v3.8.7](https://github.com/edwinrodri12/Tarvoka/actions/runs/44368832649) imprimía varias veces `SCRIPT ERROR: Out of bounds get index '2' (on base: 'Array')` desde `TerrainTactics.tile_at:21` durante `test_large_map_terrain_combat` y `test_counterfire_doctrine`, aun cuando cada test mostraba su marca de PASS. **Ese ruido es una excepción real del motor**, no una prueba aprobada de la función. Después, el flujo se detuvo por otra regresión obsoleta de test logístico que fue corregida y aprobada en la v3.8.8.

**Causa precisa de los límites:** `TerrainTactics.tile_at` usaba `Rules.inside(cell, terrain)` antes de indexar `terrain[cell.y]`. `Rules.inside` interpreta a propósito un **terreno vacío** como tablero implícito de 10×8 para mantener compatibilidad con verificaciones antiguas de movimiento. Por eso `Rules.inside(Vector2i(2,2), [])` devuelve `true`, aunque `terrain[2]` no existe. El acceso a la fila arroja error de script.

## Corrección candidata

Dentro de `scripts/core/TerrainTactics.gd`, `tile_at` ahora:

1. Rechaza coordenadas negativas, Y más allá del número de filas real o terreno sin filas antes de cualquier índice.
2. Rechaza la fila cuando no es Array.
3. Rechaza X más allá del tamaño real de la fila.
4. Para una casilla válida, **devuelve exactamente el mismo tipo de terreno que antes**.

Las demás funciones de combate, altura, flanqueo, cobertura, unidades y cálculo de daño quedan **intactas**. `Rules.inside` y su comportamiento deliberado de compatibilidad para movimiento **no cambian**.

## Contrato automático

`tests/test_terrain_safe_lookup_v389.gd` prueba:

- Array de terreno vacío (incluido el caso real `(2,2)` antes problemático).
- Coordenadas negativas y fuera del tablero.
- Terrenos irregulares con filas cortas, vacías y filas que no son Arrays.
- Protección contra mutación de los datos de entrada.
- **1.712 casillas reales** entre mapas válidos de 10×8, 24×18 y 40×30, verificando cada tipo original y los bordes.

`.github/workflows/terrain-safe-lookup-v389.yml` instala Godot 4.3 y exige cero `SCRIPT ERROR`, `Assertion failed`, `Parse Error` o `ERROR:` de cuatro pruebas:
`test_terrain_safe_lookup_v389`, `test_large_map_terrain_combat`, `test_counterfire_doctrine`, `test_supply_strategy`.

Si algún test falla, **no** se considera aprobado. Ejecutar también la CI general de Godot de la rama; no asumir éxito global solo por la prueba focalizada.

## Relación con balance

Este trabajo fue aislado en una rama basada en [PR #597 v3.8.8](https://github.com/edwinrodri12/Tarvoka/pull/597) para no modificar su estudio de semillas nuevas. La v3.8.8 compara apertura oficial vs primera respuesta de cinco órdenes sobre semillas 634–641 con 32 situaciones originales. **Sus resultados aún deben tratarse por separado y sin inventar ganadores para los casos censurados**.

**No cambia OpeningBalance, RelayControl, IA de producción, ingresos, reglas de turno, suministro, combate, APK ni main. El único archivo de producción modificado es TerrainTactics.gd. PR draft sin auto-merge.**
