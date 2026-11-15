# TARVOKA — Base Naval V5: escala, señalización, sombras e iluminación

## Alcance
Quinta revisión artística nativa Godot 4.3 de la instalación naval. Se construye **sobre V1 → V2 → V3 → V4**, sin cambiar las reglas del juego, captura, abastecimiento, navegación, producción de barcos ni el render del mapa Android.

## Mejoras implementadas
- **Escala y estructuras del astillero**: pies y arriostramiento metálico proporcionados a la bancada de V3, cantoneras en el color real de la facción, postes de seguridad de escala reducida y nuevos refuerzos del puente grúa solo en nivel 3 y con daño 0/1. Las piezas 3D proyectan sombras reales desde la iluminación direccional del Estudio; no se falsifican sombras con manchas pintadas.
- **Numeración de atraques**: placas **01 / 02** con auténticos trazos tridimensionales extruidos (siete segmentos por número), sin dependencias de fuentes o imágenes. Están en las posiciones de los espigones existentes, y no aparecen sobre el muelle seccionado en daños críticos ni en las ruinas finales.
- **Balizas de navegación**: cabezales rojo/verde de emisión suave, bases resistentes y deterioro visible en daños medios; en destrucción no hay aparatos restaurados artificialmente.
- **Luz de trabajo**: hasta dos reflectores direccionales SpotLight3D de poco alcance, con postes, brazos, carcasas y difusores en geometría real; energía moderada, sin costosos mapas de sombras adicionales. Con daño leve/medio se mantiene solo un reflector; en crítico/destruido ninguno.
- **Evolución del daño**: las señales, los refuerzos, la iluminación y el puente de servicio siguen los cinco estados existentes. Se preserva el escudo oficial de cada una de las ocho facciones. Los huecos de tejado y espigones rotos de V2-V4 permanecen huecos.
- **Comparación en el Estudio**: la casilla `V5 · escala, números de muelle y luces (comparar V4)` activa el paso completo y al desactivarla permite ver V4. Los toggles anteriores siguen mostrando V1, V2, V3 y V4.

## Validación
`scripts/ui/NavalYardSignalsV5.gd` + `tests/test_naval_base_v5_gpu.gd` + `.github/workflows/naval-base-v5-gpu.yml`.
El test comprueba las 40 combinaciones (8 facciones x 5 daños), niveles 1-3, las placas y numerales de los muelles, orientación y presencia de luces según daño, refuerzos del astillero, ausencia de muelles reconstruidos y selectores históricos, y guarda ocho capturas nativas. El CI debe finalizar en verde **antes de afirmar que la V5 está verificada**.

## Límites y próximo avance
No se han medido FPS en Android ni se ha conectado aún este arte 3D con unidades navales del mapa jugable. Siguiente paso visual propuesto: revisión de lectura nocturna y escala en zoom táctico, pequeñas mejoras de relieve de cubiertas y conexiones de escaleras, sin añadir iluminación excesiva.
