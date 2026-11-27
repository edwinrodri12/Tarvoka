# Comparación artística nativa A02 / Bastion

Este ensayo opcional no modifica modelos ni reglas y no activa una compilación automática. Utiliza Godot 4.3 y las dos unidades que entrega la fábrica nativa del juego, con LOD13, cuatro vistas y tres facciones representativas (Norte, Solar, Ónix). Produce 24 PNG de 960×680 con la misma iluminación, fondo y orientación de cámara. El encuadre ortográfico se ajusta a los límites visibles de cada unidad; las imágenes comparan acabado y no tamaño físico. El informe guarda la escala de cámara, límites, identidad de cada captura y SHA-256.

Ejecutar desde la raíz del repositorio, con los recursos importados:

```sh
xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 godot --rendering-method gl_compatibility --audio-driver Dummy --path . --script res://tests/test_a02_bastion_matched_art.gd
```

Salida: `build/qa/a02-bastion-matched/`. Revisar por separado la jerarquía tonal, continuidad visual de superficies, riqueza gráfica, bordes, lectura de facción y consistencia de detalle. No convertir diferencias de píxeles en una nota artística. No es una prueba de FPS ni de memoria Android. El ensayo permanece sin ejecutar; los PNG de esta comparación aún no existen. La rama se mantiene aislada mientras las pruebas V23 están en cola.
