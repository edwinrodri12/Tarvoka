# TARVOKA — Cuartel General V24 · puente REAL al mapa 3D

## Estado
Implementación de prueba en rama `feat/hq-v24-live-battle-3d-20261121` (PR #663). No declarar finalizada ni fusionada hasta pasar la validación Godot 4.3 y revisar render 3D en Android.

## ¿Qué cambió?
En el renderizador `BattleTerrain3D`, las dos **ciudades iniciales** de mando (identificadas por `CommandCityArtV14.is_visual_command_city`) reciben ahora geometría **nativa 3D**, no sprites 2D ni una silueta genérica de ciudad.

- La fuente de formas es el proxy de mapa ligero `HeadquartersMapLOD3D.gd` trasladado desde la rama histórica de arte HQ V23.
- El cuerpo usa seis superficies de material agrupadas; una segunda malla nativa de tres superficies reproduce las cubiertas **curvas y cerradas** originales V13 (puente central y dos alas), sin construir ni ocultar los miles de nodos HERO. Una tercera malla de cuatro superficies añade franjas superiores de facción, cristales, accesos, marcos y equipos de cubierta (13 superficies en tres mallas arquitectónicas). El conjunto se escala a 0.152 para permanecer dentro de una casilla de 2.40 m.
- Ocho colores de facción, escudo extraído del atlas original (solo cuando la identidad es pública) y variante neutral gris.
- N1–N3 y D0–D4 son **variantes solo visuales**. No existe HP estructural ni mejora de producción de HQ en las reglas actuales.
- D3 elimina un ala y conserva escombros; D4 usa una ruina completa. El aspecto definitivo aún requiere comparación visual con las ramas HERO V13/V23, que **no** se han integrado en el APK.
- Los emplazamientos conservan `kind=city` y todo el ingreso/captura asociado. No se crea HQ productor, bases ni gasto adicional.

## Privacidad y niebla de guerra
La ciudad no descubierta no se representa. Al explorarla pero perder contacto visual, se muestra la arquitectura N1/D0 neutral, sin insignia, sin datos de mejoras o daños actuales. La transformación del color tras una captura se realiza usando el dueño actualmente conocido, no la facción inicial.

## Pruebas y limitaciones
`tests/test_hq_v24_live_battle_3d.gd` comprueba 135 combinaciones (3 niveles × 5 daños × [8 facciones + neutral]), escala de la malla, dos instalaciones reales sin duplicar economía, colores oficiales, capturas y niebla.

CI: `.github/workflows/hq-v24-live-3d-qa.yml`, preparado para ejecutar Godot 4.3 y Mesa/Xvfb. `tests/test_hq_v24_visual_gallery.gd` prepara 5 capturas PNG **nativas**: combate real cerca/lejos; ocho facciones + neutral; D0–D4 y N1–N3. Se publicarán en el artefacto `tarvoka-hq-v24-native-3d-qa`, siempre que la ejecución llegue a la fase de GPU. Todavía faltan revisión humana de esas capturas y comparación directa con V13 HERO. Rendimiento físico Android y presencia en el estudio web requieren pruebas separadas.

## Próxima prioridad antes de aprobar
1. CI verde y corrección de parse/logic, si procede.
2. Inspeccionar las cinco capturas visuales del mapa real y del catálogo, en lugar de suponer que el código renderiza bien.
3. Comparación visual con HQ HERO aprobado; no sustituirlo por un proxy inferior en el visor.
4. Test en dispositivo Android de gama media o baja, zoom, memoria y legibilidad.


## Correcciones de inspección humana V24

- Se compararon cinco capturas generadas en GPU Godot 4.3 con la pieza HERO original; el modelo de mapa conserva deliberadamente menor densidad por Android.
- La cámara original mostraba la fachada trasera y hacía parecer que no existían puertas o ventanas. `test_hq_v24_visual_gallery.gd` pasó a capturar desde la zona frontal y añadirá el sexto primer plano del escudo y los materiales. No sustituye la prueba de nitidez en dispositivo Android.
- La primera inspección en el visor original encontró dos piezas físicas mal ancladas: una placa de facción flotante cerca de la torre y un módulo elevado de N3 cuya base no tocaba la cubierta. Ambos se reubicaron sobre la estructura y el módulo superior se colapsa en D3.
- Se solucionó la falta de escudos en la rama histórica del visor reutilizando exclusivamente los atlas oficiales, sin fabricar nuevos emblemas. La misma rama ofrece un conmutador V23 HERO ↔ V24 táctico.
- Estado de la integración Web original: PR #664 separada para no sobreescribir arte antiguo ni afirmar una publicación que no ocurrió. No hay promesa de despliegue público hasta validación y fusión.

## Comprobaciones finales

Las pruebas del renderizador V24 anteriores a la corrección de anclajes resultaron verdes en GitHub Actions. Los cambios más recientes de cámara y anclaje requieren CI propio y revisión de las capturas resultantes. Mantener PR como borrador hasta cumplir esos puntos.
