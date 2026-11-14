# TARVOKA V17 · Acabado comercial del Cuartel General bajo clima y terreno

## Integración real en TARVOKA Estudio 3D

El Cuartel General ya incorpora un **estudio de condiciones climatológicas** con dos selectores junto a la comparación del PNG V15:
- **Clima:** Despejado, Lluvia y Nieve. Coincide con los nombres públicos de `scripts/core/Weather.gd` (del juego Android), pero este componente es exclusivamente visual.
- **Terreno:** Asfalto, Pradera, Desierto y Roca.

El archivo `scripts/ui/HeadquartersClimateV17.gd` añade geometría Godot **real**, y no una ilustración estática:
- Lluvia con ~78 estelas translúcidas agrupadas en **una sola malla**, sin un nodo por gota, y cuatro charcos transparentes con acabado húmedo.
- Nieve con ~56 copos agrupados en **otra sola malla** y tres depósitos 3D sobre alas/torre del edificio. No se acumula nieve en un Cuartel destruido ni sobre un Sprite3D plano V15.
- Un suelo 3D local de 29×29 metros y un MultiMesh de 44 irregularidades de terreno para diferenciar las superficies sin 44 draw calls.
- Paleta del suelo modificada por clima usando los mismos pesos que `Weather.terrain_tint` (`#27495E` al 28% para lluvia, `#D9E4EA` al 52% para nieve); luz ambiental más gris y fría bajo lluvia/nieve.
- Ligero movimiento determinista de las partículas mediante desplazamiento del lote, sin recrear mallas por fotograma.

### Calidad y separación de lógica

El Cuartel HQ V12 detallado y la variante V13 de 2 mallas/10 superficies siguen intactos. El componente V17 no se guarda en partidas ni modifica captura, ingresos, IA, niebla de guerra, combustible o penalizaciones por clima.

El **sprite V15 Android es una imagen horneada bajo condiciones despejadas**. En el visor aparece comparado contra el entorno con lluvia o nieve, y el modo de Sprite3D plano sigue siendo explícito. La climatología de la partida real ya se aplica mediante el sistema separado `WeatherPainter.gd`; **no afirmar que estas texturas V15 incluyen nieve o goteras horneadas**.

El estudio conserva día/atardecer/noche, ocho facciones, cuatro estados visuales, tres niveles, modo 3D/PNG y los visualizadores de terreno y tanque independientes.

## Pruebas y publicación

`tests/test_hq_v17_weather_terrain.gd` valida:
- Las 12 combinaciones de 3 climas × 4 terrenos mediante captura GPU real desde cámara fija.
- Transiciones sin reconstruir el modelo 3D; malla de precipitación de 1 lote visible y 44 elementos agrupados en MultiMesh.
- Charcos solo bajo lluvia; nieve de cubiertas solo si el edificio sigue en pie; estado destruido sin falsas cubiertas; modo sprite plano sin nieve geométrica flotando.
- Preservación del modelo V12, modo táctico V13, PNG V15 exacto, regreso a unidad/tanque, y controles de UI interactivos.
- Capturas `tarvoka_hq_v17_four_terrains_three_weathers_godot.png`, comparativas de lluvia/nieve y GUI completa en Godot.

Los nueve PNG V15 originales se copian de la rama principal del juego ANTES de importar Godot mediante CI; el visor público no contiene una aproximación inventada. El publicador Pages usa la rama V17 únicamente tras superar Godot GPU y WebGL, preservando otros subvisores.

## Próximos bloqueos comerciales

Poner a prueba el coste real de estos efectos en una tableta Android de gama baja, corregir interferencias de lluvia con la insignia táctica y el selector, ampliar el renderizado de sprites a estados/niveles cuando sea pertinente y decidir si deben aplicarse más efectos climáticos independientes a los mapas grandes. Las 12 capturas de estudio no equivalen a un benchmark físico Android.
