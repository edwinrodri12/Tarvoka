# TARVOKA — G13 V20: modelado de blindajes de torreta y unión a carrocería

Continuación exclusivamente artística de V19, sobre **la misma malla nativa de Godot 4.3** y dentro del Estudio 3D compartido.

## Cinco superficies 3D reales

1. **Protector inferior de recámara**, una malla cerrada con perfil de seis puntos (60 vértices triangularizados) debajo del cierre biselado de V18. Hijo de `G13_ElevacionCanones`: asciende junto a ambos cañones durante el apuntado a tierra y a aire, evitando mostrar la cara inferior de las recámaras sin añadir misiles ni tapar bocas de fuego.
2. **Dos blindajes de transición traseros de torreta**, mallas cerradas de tres perfiles octogonales (132 vértices cada una). Hijas de `G13_TorretaAzimut`, comienzan encajadas en los blindajes laterales existentes y terminan hacia atrás sin tapar las insignias de las ocho facciones ni los rieles de identificación.
3. **Dos apoyos de pedestal sobre la carrocería**, también mallas cerradas de tres perfiles octogonales; hijas de `G13_Casco4x4`, funden visualmente el cuello fijo V15 con la cubierta trasera, por debajo del giro de torreta. No siguen el giro ni la elevación.

**Se preserva lo aprobado:** G13 4x4, radar independiente, exactamente dos cañones automáticos, cero lanzamisiles, bores huecos, retroceso/disparo aire y tierra, ocho facciones y todos los demás modelos. Solo LOD13 recibe estas cinco mallas; LOD8 Android sigue igual.

## Prueba y validación artística

- `tests/test_g13_turret_armor_v20.gd` valida las cinco nuevas mallas, perfil cerrado, coordenadas y holguras, pivotes correctos, idempotencia, animaciones y ocho facciones.
- `tests/test_g13_v20_visual_capture.gd` genera **50 capturas Godot**: todas las vistas previas, zoom bajo la recámara en reposo/elevación, blindaje posterior, apoyos fijos de carrocería y un par de imágenes del antes/después desde la misma cámara ocultando solo las cinco piezas V20.
- `.github/workflows/g13-v8-final-art-audit.yml` ejecuta esas pruebas y publica el ZIP de las vistas; `.github/workflows/tarvoka-3d-pages.yml` incluye el nuevo script en las actualizaciones del visor.

El G13 sigue siendo una maqueta 3D del Estudio: **este cambio no lo registra automáticamente como unidad jugable**. El cierre artístico definitivo queda sujeto a revisión y aprobación del usuario.
