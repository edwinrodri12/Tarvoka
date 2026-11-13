# TARVOKA — Identidad visual aprobada (2026-11-13)

## Decisión de dirección creativa

La identidad oficial aprobada conserva **el águila metálica plateada sobre la gran T**, su emblema alado, la estrella dorada inferior, el anillo de mando y el **planeta ficticio** como fondo.

Esta referencia **sustituye las versiones anteriores con el planeta Tierra**. El planeta debe mostrar continentes y océanos inventados: nada reconocible como África, América, Asia, Europa, Oceanía o la Antártida.

- **Estilo:** 70 % militar moderno y 30 % tecnología táctica. No ciencia ficción extrema.
- **Paleta de interfaz existente (GameUiTheme.gd):** azul noche `#08131F`, superficies `#102332`, cian eléctrico `#36C3FF`, dorado `#FFD44A`, texto acero claro `#F1F5F2`.
- **Símbolo:** águila de acero, gran T y alas simétricas; aro de mando, estrella dorada y planeta inventado.
- **Aplicación:** icono **sin texto**. El título TARVOKA y la composición cinematográfica pertenecen a la portada/menús, no al icono pequeño.
- **Facciones:** conservar sus 8 paletas diferenciadas y NO recolorear toda la UI según facción.
- **Consistencia:** el símbolo no se sustituye por las propuestas anteriores de monograma «TV», águila con el título superpuesto, laureles gigantes o globo terrestre.
- **Escalado:** producir variantes de 48, 96, 192, 512 y 1024 px desde el arte maestro; revisar contornos en pantalla real antes de exportar a tiendas.
- **Derechos:** esta aprobación visual no constituye autorización legal de uso comercial ni garantía de exclusividad de marca. Queda pendiente una búsqueda de anterioridades por un especialista antes de publicar.

## Recursos en esta rama

`assets/branding/tarvoka_icon_fictional_planet_64.png`: **previsualización de 64 px reducida del icono aprobado con planeta ficticio**; sirve para identificar la referencia sin sustituir el arte maestro. No usar como raster de publicación ni escalarlo a icono 512/1024.

`assets/branding/tarvoka_emblem_fictional_planet_512.webp`: **versión optimizada de 512 × 512 px (WebP ~67 KB) del emblema de 1254 × 1254 px aprobado en esta conversación**, con el planeta ficticio. Ya se usa en la portada mediante `HomeMenu.gd`, conservando la miniatura de 64 px como alternativa. No se ha redibujado ni sustituido el símbolo.

El **PNG maestro original de 1254 × 1254 px** permanece disponible entre los materiales de la conversación y todavía debe almacenarse como original sin pérdidas antes del lanzamiento comercial. También queda pendiente ajustar con ese maestro los iconos adaptativos de Android, los presets y el recurso de tienda; la versión WebP es para visualización dentro del juego, **no** una entrega de identidad comercial final.

## Siguiente fase de interfaz

Diseñar e implementar el menú principal, Campaña, Escaramuza, Multijugador, Arsenal, Ajustes y sus submenús a partir de los colores aprobados. Reutilizar `GameUiTheme.gd`. Las pantallas deben estar conectadas a acciones reales y ser navegables, no solamente mockups.
