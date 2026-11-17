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

## Inspección ventral V12.2 — prueba en Godot 4.3
- La primera prueba cuantitativa de cajas 3D detectó una separación insuficiente entre el travesaño fijo y el carenado móvil al disparar (8 fallos, uno por facción). Por eso se reubicaron **el travesaño y los dos anclajes superiores de -1.240 a -1.085 en Z local**, detrás de la envolvente del arma. No se ocultó ni desactivó la geometría.
- La prueba `tests/test_attack_helicopter_v12.gd` mide los volúmenes completos, transformados al sistema local del modelo, de los patines V5, la montura V12, el travesaño y la cuna. Comprueba reposo, disparo y siete fases adicionales por facción, manteniendo los ocho colores aprobados y el LOD10 intacto.
- **Resultado: aprobado** en [Godot V12 — inspección de patines y cañón](https://github.com/edwinrodri12/Tarvoka/actions/runs/44021658674).
- La nueva captura nativa genera **20 PNG**: ocho giros a 320×180; cuatro referencias V11 idénticas; cuatro macros del morro; cuatro ángulos desde debajo (ambos patines y cañón en disparo, sin ocultación del fuselaje por el plano del suelo).
- El trabajo sigue en la rama de PR #476; el visor publicado en Pages todavía no está confirmado con V12, porque la escena de Estudio depende de otra rama pendiente de integrar.
