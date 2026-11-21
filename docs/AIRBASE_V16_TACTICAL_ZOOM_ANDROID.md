# TARVOKA — Base Aérea V16: detalle táctico adaptable en batalla

La Base Aérea ya tenía el modelo artístico HERO V16 finalizado en el Estudio 3D. El mapa del juego utilizaba únicamente el proxy V4 de cuatro superficies y geometría muy sencilla. Esta etapa **no reinicia el modelado** y no sustituye el diseño artístico V16.

Se añade un perfil táctico cercano que recupera rasgos reconocibles del acabado V16 (portones, fachada, trusses, cristales panorámicos semitransparentes de la torre, señalizaciones de pista, marcos y mayor presencia de los colores de facción) **horneados en una sola malla con cuatro/cinco superficies**. No es el modelo HERO completo: es un LOD de mayor fidelidad inspirado en el arte ya aprobado, destinado a evitar cientos de nodos 3D por edificio en Android.

**Automatización visual:** el edificio alejado conserva V4 de 4 superficies. Si el modelo proyecta >=115 px pasa a cercano; al bajar a <=85 px regresa a distante. Histéresis en la banda evita parpadeos; como máximo una reconstrucción por paso de 50 ms hasta terminar cambios, luego revisión cada 250 ms.

**Reglas intactas:** las dos bases aéreas `airbase` de la economía existente siguen produciendo desde UrbanEconomy. La cámara solo sustituye el `MeshInstance3D`; la casilla, selección, propietario, niebla, munición, combustible y partida guardada nunca cambian. Los estados N1–N3 y D0–D4 siguen siendo puramente visuales; no inventar puntos de vida para edificios.

**Diagnóstico:** botón FPS muestra número de bases, detalle cercano/lejos y pico de CPU para reconstrucciones reales de ese dispositivo. QA `tests/test_airbase_v16_tactical_zoom.gd` verifica las 120 combinaciones artísticas, ciudad y unidades reales, zoom, histéresis, posición estable, estado inmutable y genera 2 PNGs de Godot + JSON. Test en Linux Mesa no es FPS Android físico.

**Pendiente antes de cerrar como juego completo:** revisión visual del LOD en el visor, medidas físicas de FPS y arte V16 HERO íntegro si alguna pantalla exige ultra detalle. El modelo V16 artístico como tal ya estaba finalizado.
