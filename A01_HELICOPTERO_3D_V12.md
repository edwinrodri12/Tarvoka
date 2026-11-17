# TARVOKA — A01 Helicóptero de ataque · modelado 3D V12

## Objetivo
Pasar de V11 (transmisión y lanzadores) a un morro blindado y una montura de cañón más creíbles sin comprometer las animaciones, las ocho facciones o el rendimiento táctico.

## Geometría creada
- Nuevo módulo `scripts/ui/AttackHelicopterNoseV12.gd`, geometría editable nativa Godot 4.3.
- Dos blindajes laterales integrados al casco V2 con cuatro secciones longitudinales, chaflán interior y extremos triangulados/cerrados; no son planos 2D ni fotografías.
- Juntas superficiales finas y dos acentos de color de facción.
- Dos soportes rígidos para el cardán del arma unidos al casco V1.
- Un carenado de cañón troncocónico de dieciséis lados, dos muñones giratorios, collar anterior, nuevo bisel óptico y aro de bocacha.
- El grupo `A01V12_CunaCanonMovil` es hijo del pivote original `A01_ArmaMorro`. La inclinación y el destello de disparo V1 siguen intactos.

## Controles del Estudio 3D unificado
- Categoría A01 ahora se presenta como `Helicóptero A01 · V12`.
- En **Detalles**: acercamientos al blindaje frontal y cardán, botón de comparación **V11 ↔ V12**.
- `set_enabled` activa/desactiva solo los dos grupos V12, sin destruir el árbol ni reconstruir otras unidades.
- Los cambios se limitan a `finish_enabled && art_level >= 13`; las unidades de combate en Android utilizan exactamente el mismo LOD ≤10 anterior.

## Validaciones automatizadas
- `tests/test_attack_helicopter_v12.gd`: ocho facciones, armadura cerrada real, cardán hijo del pivote animado, idempotencia, comparación reversible, movimiento/ataque y LOD10 limpio.
- `tests/test_attack_helicopter_v12_capture.gd`: 16 imágenes Godot reales, ocho giros en 320×180, cuatro bases V11 con cámara idéntica, cuatro acercamientos en 960×720 (morro, lateral, cardán y bocacha).
- `.github/workflows/a01-v12-nose-qa.yml`: ejecuta ambos tests nativos con Godot 4.3 y archiva capturas para revisión.
- La revisión V11 se captura aislando la geometría V12, preservando la comparación histórica.

## Estado
Geometría y pruebas guardadas en la rama de desarrollo de [PR #476](https://github.com/edwinrodri12/Tarvoka/pull/476). La integración en `main` y el visor publicado requieren compatibilidad con la rama que contiene `CombinedArtStudioWeb.gd`. No indicar que está desplegada hasta verificar integración y publicación.
