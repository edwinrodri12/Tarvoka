# TARVOKA Cuartel General V16 — la V15 Android dentro de TARVOKA Estudio 3D

## Corrección solicitada

La V15 había integrado nueve sprites horneados desde el modelo 3D V13 en la batalla Android, pero el **visor TARVOKA Estudio 3D** seguía leyendo el código de la rama V13 sin mostrar esos recursos reales. La V16 corrige esa desconexión. No se dibujan imágenes inventadas: los sprites que ve el usuario son **los mismos PNG publicados en la rama principal del juego**.

## Tres modos en el visualizador

Dentro de **EDIFICIOS 3D → Cuartel General** se añadió el selector **V15 · ARTE REAL UTILIZADO EN ANDROID** con:

- **3D real + sprite V15 (comparar)**: el escenario principal mantiene el modelo físicamente 3D V12 o el perfil táctico V13 y en el panel se muestra el PNG Android original de la facción actualmente seleccionada.
- **Solo 3D real (ocultar sprite)**: inspecta las geometrías anteriores sin una miniatura que ocupe espacio.
- **Mostrar sprite V15 en escenario 3D**: dibuja un `Sprite3D` plano con material transparente, orientado hacia la cámara. Este modo demuestra la diferencia entre una captura horneada y la geometría verdaderamente editable. No se hace pasar el billboard por una nueva malla física.
  
El visualizador conserva la rotación y zoom de la cámara, la galería de las **ocho facciones oficiales**, los niveles y estados previos, el comparador V12/V13 y el tanque en el visor correspondiente.

Se incluye **Sprite neutral (niebla sin insignia)** sin alterar la facción del modelo 3D. El control de zoom del panel simula la legibilidad del PNG a **220, 148 y 85 píxeles**; el zoom mínimo explica que Android usa el vector V14 como alternativa si la cámara se aleja. El sprite V15 mostrado corresponde al modelo V13 de nivel 2 operativo, no a una representación inventada de los estados dañado/destruido o todos los niveles.

## Fuente de datos y publicación

El flujo `.github/workflows/web-art-studio.yml` descarga temporalmente desde `main` los nueve PNG `assets/buildings/hq_v15/`. Los copia al entorno del estudio de edificios **antes de importar Godot**, comprueba que son exactamente nueve y elimina el checkout del juego para no duplicar scripts/class_names.

`tarvoka-3d-pages.yml` debe apuntar a la nueva rama V16 y realizar **la misma copia de los nueve PNG antes de exportar WebGL**. Los subvisualizadores independientes `/batalla/` y `/tanque/` se conservan. La publicación nunca se considera completa sin compilación WebGL y despliegue Pages correctos.

`tests/test_hq_v16_sprite_studio.gd` comprueba texturas importadas 384×384, nueve variantes, selección de ocho facciones, neutral, tres zooms, Sprite3D real de prueba, comparador V12/V13, vuelta a tanque y captura de la **pantalla completa del Estudio 3D** con sus controles visibles. Esta prueba corre en Godot GPU, no mediante una ilustración externa.

## Siguiente prioridad comercial

El siguiente cuello de botella artístico es mejorar el sprite táctico a distancias pequeñas sin ocultar la información del juego, evaluar el comportamiento con lluvia/nieve y generar estados físicos adicionales únicamente si son relevantes para las reglas de la partida. En el 3D, continuar refinando transiciones de materiales y escala de las cubiertas. Falta perfilado en teléfono Android real.
