# TARVOKA — Puente del arte oficial al motor (fase visual 1)

Fecha: 2026-11-12. Alcance: **infraestructura visual en ejecución**, no se afirma que los renders conceptuales se hayan convertido en modelos 3D ni que estén importados al APK.

## Referencias vinculantes

- Estilo aprobado: híbrido 2D + 3D estilizado, lectura isométrica en la versión final, identidad propia; no copiar el lenguaje gráfico de Advance Wars.
- Orden fijo de emblemas del mosaico aprobado del 12-11-2026, leído de izquierda a derecha, arriba y abajo:
  1. Alianza Norte — azul, águila blanca con laureles.
  2. Pacto Escarlata — rojo, león blanco coronado.
  3. Unión Verde — verde, árbol y engranaje.
  4. Confederación Solar — amarillo, sol.
  5. Sindicato Violeta — violeta, tres hexágonos.
  6. Legión Ámbar — naranja, dragón.
  7. Dominio Turquesa — turquesa, tridente sobre olas.
  8. Orden Ónix — gris oscuro/plata, insignia alada.
- Personajes y líderes aprobados se conservan como referencia separada; **no se redibujan ni sustituyen** en este cambio.
- Balance de las ocho facciones v0.1 bloqueado hasta pruebas; esta capa NO concede atributos tácticos.

## Qué está integrado

- `scripts/ui/VisualStyle.gd`: registro único de identidades, colores, motivos y rutas futuras de PNG; colores de casillas; indicador azul de movimiento y rojo de ataque.
- `scripts/ui/TouchBoard.gd`: toma de VisualStyle los colores de terreno, bandos e indicadores, con iluminación simple de borde para dar profundidad sin alterar hitboxes ni niebla.
- `scripts/ui/Main.gd`: leyenda de movimiento actualizada; botón «Ver las ocho facciones» en el HUD.
- `scripts/ui/FactionGallery.gd`: galería desplazable con las ocho identidades, que muestra cada emblema si su PNG existe y un recuadro de color claramente provisional si falta.
- `tests/test_visual_style.gd`: congelación de identidades y regresión visual sin cambios de estado; CI la ejecuta junto a pruebas tácticas.

## Rutas preparadas para el arte final

Depositar las ocho imágenes originales, separadas y ajustadas sin rediseño, en:

```
assets/factions/alianza_norte.png
assets/factions/pacto_escarlata.png
assets/factions/union_verde.png
assets/factions/confederacion_solar.png
assets/factions/sindicato_violeta.png
assets/factions/legion_ambar.png
assets/factions/dominio_turquesa.png
assets/factions/orden_onix.png
```

Cada PNG: fondo transparente, mismo encuadre y tamaño (recomendado 256×256 o 512×512); no recortar laureles, olas, coronas ni alas; no generar reemplazos improvisados. Los emblemas se pueden consultar mediante `emblem_texture(index)`; se devuelven `null` cuando aún faltan, sin bloquear la partida.

## Secuencia restante

1. Importar **los PNG exactos aprobados** y retratos del arte original a dichas rutas, con trazabilidad de fuente y licencia propia.
2. Construir un atlas modular 2D/3D para 32 clases finales, 12 edificios, terreno y efectos. Las 40 propuestas anteriores son concepts; la campaña utiliza las 32 clases depuradas.
3. Prototipo de cámara isométrica / mapeo pantalla-celda con pan, zoom, selección y capas aéreas; migración controlada con pruebas de toque Android. **No cambiar malla de interacción hasta completar pruebas**.
4. Render de instalaciones capturables por clase/estado y variantes de propietario; después incorporar HUD definitivo y minimapa.

Ninguna de estas acciones altera reglas de munición, combustible, ciudades, relés, autosave o IA. No se publica versión comercial ni se declara APK compilada por este cambio.
