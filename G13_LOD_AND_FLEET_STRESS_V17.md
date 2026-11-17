# TARVOKA G13 V17 — prueba multivehículo, política de detalle y FPS nativos

## Alcance aprobado

Continuación de V16 sin alterar una sola malla, pintura, animación, textura, pivote, valor de daño o regla de TARVOKA. **G13 sigue siendo un modelo de inspección del Estudio 3D, NO una unidad jugable incorporada a la sesión de batalla.**

### LOD operativo (selector reusable, no alta en combate)

`scripts/ui/G13LODPolicyV17.gd` es una función pura que recomienda `8` o `13` para construir G13 existentes:
- Android: **LOD8 sin excepciones**, incluidos acercamientos y el modo inspección, para no asignar los 13.584 triángulos y 107 objetos visibles del LOD13 en plena batalla.
- Escritorio, inspección de arte: mantiene el LOD13 del modelo aprobado en el mismo Estudio 3D.
- Escritorio, escena múltiple: permite LOD13 solamente para **1 o 2 G13** cerca de cámara; con **3 o más**, usa LOD8.
- Distancia escritorio: entra en LOD13 a 6.5 unidades de Godot o menos, lo conserva hasta 8.0 para impedir parpadeo por cambios rápidos de cámara (histéresis).
- La política **no crea G13 jugables ni cambia automáticamente instancias ya dibujadas**. Queda accesible desde `UnitModels3D.recommend_g13_art_level(...)` para conectarla a futuros administradores de escenas y controles del estudio.

### Estrés en Godot 4.3 y trazas reales

`tests/test_g13_v17_stress_scene.gd` crea y dibuja formaciones originales de G13 (variantes de 8 facciones) desde la misma escena nativa: **1,4,8,16 unidades en LOD13**, y **1,8,16,32 unidades en LOD8**. Para cada configuración mide:
- Tiempo en milisegundos para **construir la formación** y tiempo CPU para las animaciones por cuadro.
- 16 cuadros realmente dibujados por la instancia de Godot bajo **Linux/Xvfb, OpenGL compatible por software**, con media y percentil 95 de tiempo de cuadro de reloj real.
- Conteo de nodos MeshInstance3D/MultiMeshInstance3D **visibles**, memoria estática registrada por Godot y contador del renderizador, cuando esté disponible.
- Una captura **PNG real Godot** por escenario; 8 capturas en total y `g13-v17-stress.json` de trazabilidad.
- Estos datos **no son FPS, temperatura, consumo eléctrico, GPU ni RAM total de un teléfono Android**. El rendimiento de CI virtualizada varía.

### Toma de FPS de un Android físico, bajo demanda

`scripts/ui/G13AndroidPerfV17.gd` registra 180 fotogramas de `_process(delta)` con 45 de calentamiento, percentiles de tiempo, FPS aproximados calculados, memoria estática y llamadas de dibujo reportadas, **solo al pulsar el nuevo botón** “V17 · Medir FPS en Android” mientras se inspecciona el G13 en el Estudio 3D ejecutado como **app nativa Android**. El resultado queda únicamente en `user://g13-v17-device-profile.json`, sin permisos nuevos, telemetría remota ni llamadas externas; el menú presenta un resumen. En GitHub Pages (plataforma web) se informa que el benchmark requiere la compilación nativa y no se fingen datos.

El botón “V17 · Ver política LOD” explica qué nivel se recomienda. Este perfilador mide el rendimiento general de la escena que se está mostrando, **no exclusivamente el G13**.

### Verificación y cierre

Prueba de LOD `tests/test_g13_v17_lod_policy.gd`; prueba de contrato JSON `tests/test_g13_v17_android_telemetry.gd`; 8 escenarios renderizados en `tests/test_g13_v17_stress_scene.gd`. CI en `.github/workflows/g13-v8-final-art-audit.yml` publica un ZIP con ocho PNG y el informe.

Próxima etapa, tras revisar los números: confirmar el LOD8 visual de 32 vehículos y cerrar cualquier regresión; ejecutar el botón **en un dispositivo Android real** antes de certificar FPS o integrarlo en una APK comercial.
