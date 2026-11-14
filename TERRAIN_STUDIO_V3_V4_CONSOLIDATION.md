# TARVOKA — consolidación del terreno V3.1 + PBR + V4

## Objetivo
Conservar la buena parte de tres líneas de trabajo que se ejecutaban separadas:
- **V3.1**: carreteras continuas que siguen pendientes, costas de altura real, muestreo del suelo en los cuatro triángulos y vegetación/grava/juncos en tres grupos de instanciación.
- **PBR**: seis tipos de superficies con normales, mipmaps, texturas reutilizadas y degradados de color por vértice.
- **V4**: estratos geológicos, copas asimétricas, ondulaciones naturales del agua y fisuras en calzadas.

## Integración de las mejoras
No se reemplazan los modelos de tanque/cuartel ni los sistemas tácticos. El modo Entorno y mapa 3D ahora separa cuatro comparadores:
1. Geometría continua V2 frente a casillas V1.
2. Pendientes, carreteras, costas y vegetación V3.1 frente a V2.
3. PBR frente a colores planos.
4. Acabados V4 frente a la geometría base.

Se añadieron tangentes a mallas procedurales para que el PBR normal mapping funcione en montañas y carreteras de V3.1. Los elementos nuevos de carretera V3 reciben igualmente la textura de asfalto. V4 adapta sus grietas mediante el mismo muestreador de altura que V3, para evitar que floten. El inspector conserva las condiciones de iluminación, cámara y ejemplos de unidad/edificio.

## Comprobaciones
- Prueba de compilación rápida de V3, V4 y el visor.
- Prueba con render real de la captura `tarvoka_terrain_v2_v3_same_camera.png`, `tarvoka_terrain_pbr_comparison.png`, `tarvoka_terrain_v4_premium_comparison.png`.
- Prueba con render real del muestreo, continuidad de las casillas, alturas de la vegetación y trazado de carreteras/riberas en los tres biomas.
- Capturas completas de valle, cañón y delta.
- Exportación real a WebGL/GitHub Actions.

## Pendientes antes de calidad comercial
- LOD, división en chunks y reducción de draw calls en mapas grandes.
- Litoral no cuadriculado en escala topológica fina y agua animada de calidad.
- Primer plano de tierra/roca/carretera con mayor resolución, desgaste no repetitivo y variantes por bioma.
- Comprobar escala y contraste de unidades en escenarios de batalla y medir FPS real en Galaxy S23/Samsung Android.
- Revisar tres biomas en móvil, con cámara cercana, antes de declarar arte final.

**Separación esencial:** esta consolidación todavía pertenece al visor artístico 3D, no a las reglas ni a la escena de combate Android.
