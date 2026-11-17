# TARVOKA — HAT-29 A01 — V14.4 (reflejos locales nocturnos)

## Objetivo
Seguir la prioridad aprobada tras V14.3: hacer perceptibles los registros metálicos, lamas de motor y placas de servicio de cola con iluminación nocturna **sin re-colorear la facción, emitir luz desde las superficies ni alumbrar todo el fuselaje**.

## Implementación real en Godot 4.3
Se añadió `scripts/ui/AttackHelicopterNightStudioV144.gd`: sistema de exactamente tres `OmniLight3D` fríos, de energía limitada (0.25/0.25/0.14), rango corto (1.9/1.9/1.3) y **sin sombras WebGL**. Están anclados al mismo `model_root` del helicóptero, no a la cámara; acompañan la rotación, las maniobras y la inclinación del modelo en el visor.

- Dos lámparas laterales subrayan los herrajes existentes de motores y escudos térmicos de V14.3.
- La tercera resalta los cierres/contorno del registro de cola.
- Las tres nacen **apagadas**; solo se encienden cuando el usuario activa `Noche táctica` desde **Unidades → HAT-29 → Detalles**.
- El interruptor previo V14.3 conserva su comportamiento y además controla estas tres luces. No agregamos más botones a una interfaz ya extensa.
- Al volver al día o seleccionar otras unidades, se desactivan; al reemplazar el modelo por otra facción, se recrean únicamente sobre el helicóptero. No forman parte del factory de Android ni del nivel táctico LOD10.

El acabado de facción, sus factores de mezcla `PAINTED`, las texturas/materiales de la aeronave y las animaciones permanecen **idénticos** a V14.3.

## Evidencia y criterios de aceptación
1. `tests/test_attack_helicopter_v14.gd`: no admite nuevas lámparas en LOD10; comprueba la instalación idempotente y el encendido/apagado en las 8 facciones; cada lámpara carece de sombras; verifica que el color del casco no se modifica.
2. `tests/test_attack_helicopter_v9_studio.gd`: abre el Estudio real, comprueba las 3 luces locales apagadas de inicio, activación en noche y apagado al volver al día.
3. `tests/test_attack_helicopter_v14_capture.gd`: **31 capturas nativas Godot** = 25 históricas + 3 noche base V14.3 + 3 noche rasante V14.4, en los mismos ángulos, para comparación visual directa.
4. `a01-v14-hat29-visual-qa.yml`: exige 31 imágenes y pruebas reales de las 8 facciones.
5. `tarvoka-3d-pages.yml`: incluye explícitamente el nuevo script en el export web del Estudio compartido, evitando imports ausentes.

**No se considera aprobado definitivamente el diseño de la aeronave**: esta revisión es una iteración incremental e inspeccionable.
