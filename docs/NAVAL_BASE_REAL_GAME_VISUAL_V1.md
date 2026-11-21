# TARVOKA — Base Naval real en mapa jugable (integración visual 3D)

## Continuación de edificio ya aprobado
La Base Naval HERO está aprobada artísticamente hasta V13 en el Estudio 3D. En el juego principal la categoría `shipyard` ya tenía producción naval real, pero únicamente se dibujaba como cubo.

Esta integración conserva exactamente el **sitio `shipyard` existente**; no crea un astillero adicional. La Base Naval pasa a ocuparlo en partidas con agua navegable. Los mapas sin mar permanecen sin bases navales, igual que antes.

## Representación táctica
Reinterpretación ligera del diseño V13, no copia íntegra de su HERO: puertos en U, agua central real, dos muelles, hangar de maniobra, torre de control, grúa, defensas y señalización de la facción. Un único `ArrayMesh` por ubicación: 4 superficies a distancia, 5 cerca si el edificio conserva cristales, 4 cerca en daño crítico/ruinas.

8 pinturas oficiales + neutral, 3 niveles visuales N1–N3, 5 daños D0–D4 visuales, zoom con histéresis 116px/85px y máximo un edificio cambiado por paso. No se añaden HP de edificios ni disparos desde instalaciones. El modelo V13 completo permanece en la rama artística y puede inspeccionarse en el Estudio 3D original.

## Protección de lógica y niebla
El puente `NavalBaseBattle3D` construye únicamente los modelos visibles del `UrbanEconomy` autoritativo y respeta ocultación de propietario, mejoras y daño tras niebla de guerra. Propietarios, dinero, producir barcos, terreno, combate, combustible, capturas y partidas guardadas se mantienen intactos.

## Control nativo
`tests/test_naval_base_playable_v1.gd` valida 2 `shipyard` de agua real del escenario costa, 0 en mapa terrestre, las 120 variantes del modelo 3D, la inmutabilidad de la partida, zoom y la neutralidad bajo niebla; produce 2 PNGs y un JSON. Workflow Linux Mesa no mide el rendimiento de un teléfono real.

**Importante:** Esta rama es una integración inicial para juego; no se declara cerrada hasta pasar QA Godot y compilación Android y revisar las capturas.
