# TARVOKA · Base Naval V9 — defensas marítimas esculpidas con caucho PBR

## Objetivo
Refinar **el acabado real del modelo 3D**, no sustituirlo por ilustraciones. Cada defensa de la Base Naval V8 ahora tiene una alternativa con cuerpo acanalado construido en malla `ArrayMesh`, accesorios metálicos, abrasión de sal y suciedad húmeda, sin añadir reglas de juego ni activos externos.

## Qué cambia en Godot 4.3
- `NavalSculptedFendersV9.gd` crea una malla tubular **procedural** con 16 anillos longitudinales y 16 subdivisiones radiales (el perfil se ensancha, se estrecha en extremos y tiene nervaduras reales), acompañada de abrazaderas de acero, pernos y zonas de agarre.
- `naval_rubber_pbr_v9.gdshader` genera grano fino, manchas de sal, desgaste y humedad en coordenadas mundiales con **metallic=0** y rugosidad variable. No requiere archivos de textura externos; el metal queda en piezas separadas.
- Al mostrar V9, se ocultan las primitivas redundantes de defensas V1/V2/V8, **pero** se conservan espuma V8, drenajes, barandales, escaleras, agua y señalización. No se elimina ningún arte anterior, se reconstruye la V8 sin alteraciones al desactivar V9.
- **Daños:** 0/1 conservan refuerzos y el distintivo de la facción; 2 pierde abrazaderas y muestra soportes doblados y faltantes; 3 presenta trozos desgarrados y ausencia del espigón +1; 4 mantiene únicamente restos del modelo anterior, sin defensas intactas ficticias.
- **Zoom:** a distancia se muestran volúmenes simples, no micropernos y mallas corrugadas. Noche usa los reflectantes ya existentes de V6/V8, sin nuevos puntos de luz ni mapas de sombras.

## TARVOKA Estudio 3D
En **Edificios 3D → Base Naval V9** se añade el interruptor:
**V9 · defensas esculpidas y caucho PBR (comparar V8)**.

Las cinco cámaras, incluyendo **Detalle defensas y rampa**, permanecen operativas; también las ocho facciones, tres niveles, cinco estados de daño y modo nocturno.

## Validación real
`tests/test_naval_base_v9_gpu.gd` y `.github/workflows/naval-base-v9-gpu.yml` deben verificar 40 combinaciones, los tres niveles, materiales shader sobre geometría `ArrayMesh`, alternancia del zoom, reparación visual de estados de daño, conservación del agua y ocho capturas nativas.

**No afirmar pruebas aprobadas hasta finalizar el workflow.** Tampoco se han medido FPS Android o integrado la geometría en el juego táctico. Después de V9, revisar proporciones y conexiones de los soportes de amarre desde los cinco ángulos.
