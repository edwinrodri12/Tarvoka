# TARVOKA — combate direccional, efectos visuales y minimapa Android

Actualizado: 12 de noviembre de 2026. Trabajo experimental apilado sobre la PR #144, que depende de #142 y #139. **No modifica el motor de reglas.**

## Lo que se integra

**Movimiento y orientación**
- Ocho direcciones visuales de orientación para las 32 clases existentes, a partir de la diferencia entre coordenadas del mapa y la proyección isométrica.
- Las unidades mantienen su última orientación conocida visualmente después de desplazarse; el siguiente ataque las orienta hacia el objetivo. Esta preferencia es transitoria, no se guarda.
- El atlas compartido de 32 × 4 fotogramas sigue siendo el origen de imagen: Godot rota sus sprites sobre el centro, sin tocar selección/hitboxes.
- La galería de 32 clases ahora permite elegir **nueve opciones de orientación** (sin giro + ocho direcciones) además de las cuatro poses y colores de facción.
- La interpolación de desplazamiento de 0,32 segundos sigue siendo visual y no cambia movimientos, acción de turno ni combustible.

**Disparos, daños y destrucción**
- `scripts/ui/BattleVFX.gd`: trayectoria temporal de proyectil, estelas visibles, ondas de impacto y fragmentos transitorios.
- Efectos distintos según familia terrestre, aérea o naval (salpicadura de agua, fragmentos aéreos o chispas en tierra).
- La destrucción se determina a partir del resultado real: **una unidad eliminada del array también cuenta como destruida**, sin asignar recompensas ni HP por el renderizador.
- Ningún proyectil revela el origen oculto de un atacante. Un impacto visible puede representarse sin trazar su procedencia.
- Estos efectos son **ilustraciones de combate**, no nuevas reglas de disparo, intercepción, daño en área, ruido o partículas físicas.

**Minimapa táctil**
- `scripts/ui/BattleMinimap.gd` calcula dimensiones desde la matriz real de terreno (el motor actual sigue siendo de 10 × 8).
- La proyección geométrica ahora acepta dimensiones explícitas y se prueba con tableros visuales de **24 × 18 y 40 × 30**. Esto prepara coordenadas y cámaras, no habilita todavía batallas de tamaño ampliado.
- Muestra terreno conocido, tropas visibles, propias tropas, emplazamientos descubiertos y un contorno del área visual de la cámara, con colores de facción.
- El desconocido se representa con casillas oscuras: nunca se muestra terreno no explorado, unidades enemigas invisibles ni propietario actual de instalaciones fuera de visión.
- Tocar o arrastrar sobre el minimapa **solo cambia el desplazamiento visual de cámara** y no selecciona unidad, produce, mueve, ataca ni termina turno.
- El minimapa aparece solamente con «Vista isométrica» en el panel de Android, sin afectar a la vista clásica.
- Refresco con invalidación de estado/cámara para evitar dibujar constantemente un mapa invariable.

## Límites y siguiente nivel

- Se trata de un **minimapa real del tablero actual**, no de un escenario ampliado ya integrado: para mapas grandes aún faltan reglas dimensionales, movimientos, generación, guardado, IA y evaluación de rendimiento. La interfaz del minimapa ya toma tamaños dinámicamente, preparada para una futura expansión.
- No se declara orientación artística específica de 32 modelos 3D terminados; se reutilizan las 128 poses de sprites originales ya creadas.
- La siguiente iteración podrá añadir secuencias de 6–12 cuadros para explosiones, giro independiente de torretas, trayectorias curvas de cohetes y escuadrones, una vez aprobados los efectos en Android físico.
- Las ocho facciones, sus retratos, colores aprobados y balance v0.1 no se modifican.
- El flujo de campaña de 50 capítulos y el guardado siguen intactos.

## Pruebas

`tests/test_minimap_vfx.gd` valida octantes, orientación, diferenciación de familias, detección de unidades eliminadas, renderizado real, niebla, navegación del minimapa y aparición del control en Android; la prueba entra en el mismo conjunto de CI de Godot que verifica todas las reglas, junto con la exportación de la APK ARM64.

Revisar en teléfono físico antes de fusionar cambios experimentales.
