# TARVOKA — V14: puente visual del Cuartel General al tablero de batalla real

## Alcance y regla de honestidad

El Cuartel General V13 es una construcción 3D real en `TARVOKA Estudio 3D`, pero el combate en `main` usa un tablero isométrico CanvasItem 2D. Esta V14 introduce **una interpretación vectorial ligera de sus volúmenes** en las **dos ciudades iniciales** sin pretender que sean nuevos edificios con mecánicas propias.

**Sigue siendo una ciudad en el motor:** se conserva su ingreso, captura por infantería, reglas de movimiento, propietarios actuales, interacción táctil y sistema de guardados. La nueva silueta no es una nueva fábrica, cuartel producible, capital invulnerable ni condición de victoria. Su propósito es establecer una identidad visual de *centro de mando* en el campo de batalla. No hay escenas ni luces 3D en Android durante la partida.

## Implementación real

- `scripts/ui/CommandCityArtV14.gd`: vector isométrico de bajo coste siguiendo la arquitectura V13: **dos alas con cubiertas arqueadas, torre central, ventanas, radar, helipuerto y tres perfiles anchos del color de la facción**. Escudo **oficial exacto** extraído del atlas WebP ya integrado (sin ilustraciones inventadas).
- `scripts/ui/SiteOverlayData.gd`: marcador efímero `visual_command_city` para las dos posiciones de ciudad inicial desde las funciones originales `Scenarios.scale_x/y`. Nunca se escribe en `state` ni en los guardados. Mantiene el edificio visual tras captura, pintado según el propietario **actual**.
- `scripts/ui/IsoRenderer.gd`: el tablero isométrico real usa esa silueta solamente en esos marcadores; el resto de ciudades, fábricas y edificios conservan sus imágenes originales. Los comandos táctiles y las superposiciones se siguen dibujando después sin cambios.
- `scripts/ui/TouchBoard.gd`: símbolo arquitectónico muy compacto en el mapa clásico sobre la misma ciudad, sin botones falsos ni hitboxes.
- **Niebla de guerra:** la ciudad rival nunca aparece si no fue explorada; una ciudad explorada cuyo propietario es desconocido conserva silueta neutra **sin emblema** para no revelar identidad ni cambios fuera de visión.
- **Android:** alrededor de unas pocas decenas de polígonos y un recorte AtlasTexture por ciudad de mando. No hay construcción de mallas V13, escenas 3D, luces ni texturas duplicadas por frame. En distancias bajas se omite el microdetalle.

## Regresión comercial

Prueba `tests/test_headquarters_battle_bridge_v14.gd`:
- Coherencia de las dos ciudades iniciales en mapas 10×8, 24×18 y 40×30; dos ciudades disputadas y fábricas sin cambio.
- Ocho identidades visuales oficiales y ausencia de insignia al desconocer el propietario.
- Cambio de propietario sin alterar posición ni economía; ingresos regulares.
- Fog of war no filtra dueño de ciudades exploradas ni no vistas.
- Render efectivo `TouchBoard` en dos modos: isométrico y clásico; clic/tile sigue calculado por el motor original.
- Capturas Godot GPU con la **misma partida** antes/después de la V14 y montaje de ocho facciones.

Comprobación separada mediante `.github/workflows/hq-v14-battle-visual.yml`, además de incluir la prueba de reglas en el flujo habitual `godot-rules.yml`.

## Límites que aún quedan

Esto **no significa** que el edificio 3D detallado se esté instanciando en las batallas 2D. Hemos conectado una silueta coherente y el escudo oficial al tablero real, que es el puente necesario en el motor actual. Para tener el 3D visible en combate habría que introducir una capa 3D o un sistema de sprites horneados por render desde la V13, medir móvil, definir la conversión del sistema de alturas y validarlo sin sacrificar jugabilidad. Debe comprobarse también legibilidad bajo lluvia/nieve y fondos variados antes del arte comercial final.
