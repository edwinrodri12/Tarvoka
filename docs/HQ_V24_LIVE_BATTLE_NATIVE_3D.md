# TARVOKA — Cuartel General V24 · puente REAL al mapa 3D

## Estado
Implementación de prueba en rama `feat/hq-v24-live-battle-3d-20261121` (PR #663). No declarar finalizada ni fusionada hasta pasar la validación Godot 4.3 y revisar render 3D en Android.

## ¿Qué cambió?
En el renderizador `BattleTerrain3D`, las dos **ciudades iniciales** de mando (identificadas por `CommandCityArtV14.is_visual_command_city`) reciben ahora geometría **nativa 3D**, no sprites 2D ni una silueta genérica de ciudad.

- La fuente de formas es el proxy de mapa ligero `HeadquartersMapLOD3D.gd` trasladado desde la rama histórica de arte HQ V23.
- La malla usa seis superficies de material agrupadas, sin construir modelos HERO ocultos. Se escala a 0.152 de las medidas originales para permanecer dentro de una casilla de 2.40 m.
- Ocho colores de facción, escudo extraído del atlas original (solo cuando la identidad es pública) y variante neutral gris.
- N1–N3 y D0–D4 son **variantes solo visuales**. No existe HP estructural ni mejora de producción de HQ en las reglas actuales.
- D3 elimina un ala y conserva escombros; D4 usa una ruina completa. El aspecto definitivo aún requiere comparación visual con las ramas HERO V13/V23, que **no** se han integrado en el APK.
- Los emplazamientos conservan `kind=city` y todo el ingreso/captura asociado. No se crea HQ productor, bases ni gasto adicional.

## Privacidad y niebla de guerra
La ciudad no descubierta no se representa. Al explorarla pero perder contacto visual, se muestra la arquitectura N1/D0 neutral, sin insignia, sin datos de mejoras o daños actuales. La transformación del color tras una captura se realiza usando el dueño actualmente conocido, no la facción inicial.

## Pruebas y limitaciones
`tests/test_hq_v24_live_battle_3d.gd` comprueba 135 combinaciones (3 niveles × 5 daños × [8 facciones + neutral]), escala de la malla, dos instalaciones reales sin duplicar economía, colores oficiales, capturas y niebla.

CI: `.github/workflows/hq-v24-live-3d-qa.yml`, ejecutado con Godot 4.3 y Mesa Xvfb. El renderizador físico Android, FPS bajo carga, fidelidad fina de curvas/tejados y presencia en el estudio web deberán verificarse por separado.

## Próxima prioridad antes de aprobar
1. CI verde y corrección de parse/logic, si procede.
2. Capturas visuales cercanas/lejos en mapa real con las ocho facciones, neutral y los cinco daños.
3. Comparación visual con HQ HERO aprobado; no sustituirlo por un proxy inferior en el visor.
4. Test en dispositivo Android de gama media o baja, zoom, memoria y legibilidad.
