# TARVOKA · HAT-29 A01 · V14.14 — restos del buje central

## Motivo (revisión de capturas reales)
La V14.13 superó sus pruebas y se publicó en Godot Web ([85 capturas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44260671338/artifacts/14407368667), [publicación](https://github.com/edwinrodri12/Tarvoka/actions/runs/44260883383)). La revisión de capturas a vista 3/4 confirmó:
- La corona central V10 ya no queda hueca: V14.13 tiene una malla cerrada;
- las cuatro palas y mecanismos siguen anclados durante el giro y los impactos;
- **defecto restante**: al destruirse el helicóptero V13 ocultaba el rotor completo y producía fragmentos de palas, pero no dejaba restos del *buje central* que acabábamos de esculpir.

## Modelado nativo V14.14
- Se incorpora `scripts/ui/AttackHelicopterHubWreckV1414.gd` después de la V14.13, únicamente al modelo hero 3D (`art_level >= 13`). No altera el modelo de batalla Android ni sus colisiones, estadísticas o economía.
- Construye exactamente **dos piezas irregulares** obtenidas de triángulos de la **malla V14.13 real**, dividiendo la corona por sectores angulares. Sus bordes de corte son geometría de verdad, no calcomanías ni efectos de partículas. Quedan deliberadamente separados por una sección ausente para que no aparezca un duplicado intacto de la corona.
- Los fragmentos se agregan como `MeshInstance3D` hijos del `A01V13_RotorYEscombrosDesprendidos` existente y reciben las claves reales `a01_v13_launch`, `a01_v13_rest` y `a01_v13_rot`. Su trayectoria usa directamente `V13.pose(..., "destroy", t)`: salen del eje de rotor en (0, 2.068, 0.08), vuelan con la explosión y se asientan junto a los demás restos.
- **No modifica ni elimina** la corona V14.13 intacta o su material. El buje entero sigue bajo el rotor V1, el cual V13 oculta al destruirse; las dos piezas solo quedan visibles cuando el nodo de restos V13 se muestra.
- `set_enabled(false)` oculta los dos fragmentos y recupera la apariencia V13 anterior; `set_enabled(true)` los vuelve a mostrar sin crear objetos duplicados.

## Inspector unificado
En `Unidades → Helicóptero HAT-29 → Detalles` se añaden:
- `V14.14: desprendimiento del buje` reproduce la destrucción original V13, ralentizada.
- `Comparar restos V13 / V14.14` conmuta solo los fragmentos de corona, permitiendo examinar los restos anteriores desde la misma cámara y sin reconstruir el modelo.

## QA de geometría y animación
- `tests/test_attack_helicopter_v14_14_wreck.gd`: ocho facciones; origen auténtico de los triángulos, dos piezas truncadas, comparación reversible, ausencia en LOD Android, lanzamiento desde el rotor, trayectoria en vuelo, caída al suelo, ocultación del rotor intacto, reparación y ausencia de duplicaciones.
- `tests/test_attack_helicopter_v9_studio.gd`: comprueba botones del Inspector, estado de daños y reversibilidad dentro del mismo `model_root`.
- `tests/test_attack_helicopter_v14_capture.gd`: amplía de 85 a **89** capturas Godot 4.3, con comparación V13/V14.14 en cámara idéntica y vistas de fragmentos en vuelo y en suelo.
- `.github/workflows/a01-v14-hat29-visual-qa.yml` y `.github/workflows/tarvoka-3d-pages.yml` contienen tests y empaquetado de V14.14.

**Estado:** implementada en el código de GitHub. La aprobación V14.14 depende de la ejecución nativa del QA de 89 imágenes y del despliegue del visor web; los resultados verdes de V14.13 no equivalen automáticamente a esos resultados posteriores.


## Auditoría visual posterior y ajuste de asentamiento
La primera ejecución nativa de V14.14 completó las **89 imágenes** y la prueba de ocho ciclos de destrucción/reparación ([run 44263208771](https://github.com/edwinrodri12/Tarvoka/actions/runs/44263208771)). La comparación de capturas originales mostró que la geometría funcionaba, pero las piezas se asentaban demasiado cerca de los bajos del fuselaje y resultaban difíciles de distinguir.

La corrección de diseño mantiene la malla fragmentada, sus dos sectores reales y el movimiento V13, pero coloca los puntos finales en X=+1.36 y X=-1.43, cerca del suelo, **fuera del casco y los patines**. Las rotaciones finales se redujeron para apoyar la cara ancha de los trozos de metal en vez de mostrarlos casi de canto. El material expuesto también se aclaró moderadamente, con la misma rugosidad de acero accidentado.

Las cuatro capturas V14.14 se han reencuadrado con una cámara algo más alta y abierta (siempre idéntica entre antes y después). Se agregó una aserción automática específica para evitar que los dos fragmentos vuelvan a quedar bajo el casco.

**Validación importante:** los 89 PNG de la primera implementación verifican la función y detectaron este ajuste; la versión con posiciones corregidas requiere su propia ejecución posterior de QA y no se debe dar por publicada hasta que la exportación web termine en verde. La publicación puede quedar bloqueada por pruebas independientes del G13; eso no cambia el resultado del modelo del helicóptero.
