# TARVOKA · HAT-29 A01 · V14.2 · escultura ventral y revisión orbital

## Continuación exacta sobre V14.1
Después de revisar las 14 capturas reales de Godot generadas en la ejecución 44167519718, se observó que el frente y la cabina son reconocibles, pero que los bajos y la transición motor-cola necesitan más relieve. Esta versión NO retoca los colores moderados aprobados en V14.1.

## Geometría añadida
- **Bajos**: escotilla octogonal cerrada con triangulación propia de tapa, fondo y ocho costados; dos raíles de servicio y seis remaches. El centro se sitúa debajo del casco original, no en el patín.
- **Motores**: seis lamas físicas repartidas en ambos registros de mantenimiento incorporados en V14.1. No se sustituyen las tomas, escapes ni cajas de transmisión de V4–V11.
- **Cola**: dos registros de acceso (uno por costado), dos rebajes y cuatro fijaciones metálicas junto a las abrazaderas ya existentes. Todo acompaña a la viga principal sin interferir con el rotor de cola.
- Las piezas nuevas están bajo `A01V14_1_AccesosYJuntasTacticas` y sólo se generan en el modelo 3D de inspección detallado (`art_level >= 13`).

## Visor y evaluación visual
El modelo se crea mediante `UnitModels3D.build("attack_heli",...,true,14)`; el Estudio compartido utiliza el mismo constructor, de modo que los detalles se muestran dentro de la categoría **Unidades > A01** sin visor paralelo ni recursos GLB falsos.

El archivo `tests/test_attack_helicopter_v14_capture.gd` conserva las 8 capturas de facción y 6 estados de combate y añade **11 imágenes 3D originales**: 8 ángulos orbitales de 45° más vistas superior, inferior y macro ventral. El flujo `a01-v14-hat29-visual-qa.yml` genera y publica un artefacto de 25 PNG para la revisión.

## Restricciones
- Se conserva el acabado táctico V14.1 (intensidad de facción, materiales, metalicidad y bicromía).
- No se cambian las animaciones de vuelo, hover, ataque frontal, misiles, impactos de bala, explosión, daños 0–4, destrucción, caída y reparación.
- No se altera la variante táctica `art_level<=10` ni estadísticas, economía, IA, munición o movimiento.
- Las capturas son evidencia de revisión artística; no sustituyen una prueba de rendimiento en un dispositivo Android físico.

## Revisión V14.2.1 — Corrección tras ver los renders reales

En las 24 capturas iniciales se detectó que `hat29_v14_2_bajos.png` enseñaba más el costado y los patines que la escotilla inferior. Se corrigió a una cámara **verdaderamente bajo el fuselaje**, con el suelo oculto solo en esa toma y un foco auxiliar de inspección que no afecta ninguna otra vista. Se añadió un macro extra `hat29_v14_2_escotilla_macro.png`, por lo que ahora la salida solicitada al flujo es de **25 PNG** nativos.

También se afinaron los elementos físicos de la escotilla: ocho pequeñas juntas cilíndricas recorren el perímetro octogonal y los seis remaches ventrales ahora tienen el eje alineado con la normal de la cara inferior, en vez de quedar orientados horizontalmente como los remaches de puertas laterales. Se desplazaron ligeramente los carriles inferiores para evitar superponerlos al perímetro.

Las pruebas de Godot ahora exigen los ocho segmentos, los seis remaches correctamente orientados, sus alturas relativas y la conservación de las ocho facciones, las animaciones V13/V14 y el LOD táctico Android. Esta mejora está contenida en la PR #555 y no modifica estadísticas ni pintura.

## Validación antes de integrar
La suite `tests/test_attack_helicopter_v14.gd` valida ocho facciones, presencia de malla cerrada y nuevas piezas y preservación de LOD10. Confirmar CI Godot, render de 24 capturas y funcionamiento del Studio antes de publicar.
