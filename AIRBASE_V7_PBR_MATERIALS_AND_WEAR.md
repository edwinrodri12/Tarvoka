# TARVOKA — Base Aérea V7: materiales PBR, texturas y desgaste físico

## Resultado visual (Godot 4.3, no ilustraciones)
La V7 amplía el edificio V6 con **materiales StandardMaterial3D** reales y texturas procedurales originales, generadas de manera determinista como `ImageTexture` (64×64, una vez por familia). No introduce imágenes conceptuales, no sobreescribe recursos originales, no utiliza texturas de terceros ni cambia estadísticas de juego.

| Familia PBR | Acabado visual |
|---|---|
| Hormigón | Variaciones de tono y microporos, juntas y pequeñas manchas |
| Acero | Chapa menos uniforme, rugosidad industrial, microrelieve y desgaste |
| Cubierta | Paneles con patina, rugosidad metalizada, variación entre nervaduras |
| Asfalto | Grano de pavimento y cambios en reflectancia |
| Cristal | Acabado más liso, ligero tinte y material compatible con lluvia |

Las texturas incluyen albedo de grano, mapa de rugosidad y microrelieve normal en superficies no acristaladas, como auténticos recursos GPU reutilizables (no un cambio global de colores sólidos).

**Desgaste añadido en geometría 3D agrupada**: huellas de rodaje fuera de la línea central V3, manchas de servicio y pequeños depósitos de óxido/hollín que crecen con los niveles de daño. Estas marcas no rellenan las partes de cubierta arrancadas ni interfieren con el recorrido de los 20 componentes de los portones.

## Controles TARVOKA Studio 3D
Abrir `Edificios 3D → Base Aérea V7`:
- `V6 · fachadas, cubierta, torre y pavimento` activa/desactiva la arquitectura V6;
- **`V7 · texturas PBR y desgaste (comparar V6)`** activa/desactiva los materiales y el desgaste de V7.

Para comparar V6 y V7, conservar la opción V6 activa y alternar la V7. Los controles de ocho facciones, niveles, daños, apertura del hangar, vista interior, lluvia/nieve, explosiones y pruebas LOD continúan.

## Compatibilidad y rendimiento
- **Pinturas protegidas:** no se reemplazan texturas de emblemas originales, marcas de identidad, señalizaciones o la pintura de las ocho facciones.
- **Clima reversible:** V7 se aplica antes de `WeatherCoating3D`; lluvia cambia la rugosidad sin destruir las nuevas texturas; nieve añade la geometría reversible existente.
- **LOD:** sólo los cuatro edificios cercanos del escenario de carga usan V7; el resto conserva los proxies V4. Dos mallas en lote de manchas, máximo por edificio, sin luces extra ni partículas nuevas.
- **Sin cambio de lógica:** ninguna modificación de HP, economía, ataques, munición, fabricación de aeronaves o turnos.

## Calidad y límites
`tests/test_airbase_v7_pbr_finish_gpu.gd` valida 40 variantes (8 facciones × 5 daños), tres niveles, selección de materiales, emblemas, puertas y clima reversible, e incorpora ocho capturas reales de Godot: V6/V7, hangar, daño, ruinas, lluvia y nieve.

`airbase-v7-pbr-weathering-gpu.yml` ejecuta la validación OpenGL y publica las capturas como artefacto. Los resultados de este CI son **visuales en escritorio**, no FPS Android. La publicación web de la V7 debe hacerse después de confirmar estas pruebas.
