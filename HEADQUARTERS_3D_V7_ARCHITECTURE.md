# TARVOKA · Cuartel General V7 — Escultura arquitectónica de detalle

## Propósito

Retomar el **modelado 3D inacabado** del Cuartel General, priorizando arquitectura y materiales en lugar de añadir funcionalidades al mapa o optimizar por inercia. La base es la silueta V4, los ocho escudos aprobados del V6 y los acabados PBR generados por Godot.

## Trabajo escultórico incorporado (geometría real)

- **Portal y acceso:** marquesina frontal curva con 16 tramos 3D, espesor, cara inferior, cornisa continua, nervios metálicos y borde con color de facción. Portón profundo con hojas de cristal blindado, marco, umbral, tiradores, paneles de control, celosías, puntales y banda antideslizante.
- **Centro elevado de mando:** envolvente de ventanas panorámicas con parteluces y viseras; dintel escultural, señalización lateral, espinazos de techo y galería coherente con la insignia tridimensional original.
- **Cubiertas de las alas:** dos faldones delanteros convexos en malla 3D, con profundidad, nervios continuos, cornisa protectora y guías iluminadas. Cambian físicamente la silueta que antes era una caja plana.
- **Azoteas técnicas:** dos conjuntos HVAC con carcasas biseladas, cuatro rejillas cada uno, extractor circular doble, ductos protegidos y franjas de seguridad. Los niveles 2 y 3 añaden equipamiento y riostras exclusivos.
- **Antena radar:** conjunto mecánico de horquilla, rodamiento de azimut, amortiguadores y caja de accionamiento; conserva plato cóncavo reflectante V4.
- **Helipuerto:** bordes horizontales y balizas de aproximación, señalización y armario contraincendios; ninguna barandilla alta que invada el área de rotores.
- **Daños físicos:** cristales astillados, marquesina golpeada, riostra doblada y módulo de ventilación desprendido. El estado destruido sustituye el edificio por restos específicos del portal y HVAC en lugar de dejar partes intactas flotando.
- **Detalles adaptativos:** tornillos de cornisa y otros microdetalles visibles solo al acercar la cámara, sin alterar la silueta principal a distancia.

## Comparación editable en el laboratorio

En Estudio 3D → Edificios → Cuartel General, el acabado V7 está **activado por defecto**. El nuevo botón **«Acabado escultórico V7 (comparar con V4)»** cambia los dos modelos con el mismo encuadre. El selector de V1–V3 permanece estable; V4 sigue siendo referencia base.

## Validación

`tests/test_headquarters_v7.gd` verifica niveles 1–3, ocho insignias, piezas y geometría curvada (vértices de un ArrayMesh), daños en fase destruida, microdetalles activables, retorno al tanque y diferencia de imagen desde la misma cámara.

El workflow del Estudio 3D genera:

- `artifacts/tarvoka_hq_v4_vs_v7_sculpted_front.png`
- `artifacts/tarvoka_hq_v7_level3.png`
- `artifacts/tarvoka_hq_v7_damaged.png`
- `artifacts/tarvoka_hq_v7_entrance_closeup.png` (cámara de Godot realmente acercada)

## Exportación real y editable en Blender

La integración V7 introduce dos exportaciones GLB independientes del mismo nivel 3:
- `TARVOKA_CuartelGeneral_V4_Nivel3_Editable.glb`: conserva el V4 **sin** la escultura V7 para referencia histórica.
- `TARVOKA_CuartelGeneral_V7_Nivel3_Editable.glb`: incluye la geometría escultórica V7, escudos originales aprobados y microdetalles cercanos, organizado por categoría (arquitectura, facción, radar, logística y daños).

La salida V7 se crea con `tests/export_headquarters_sculpt_v7_glb.gd` y se adjunta al artefacto del workflow de Estudio 3D; el exportador antiguo permanece reproducible.

## Límites reales

La V7 no debe declararse **modelo final comercial** antes de revisar material PBR de cerca, reflejos, proporciones y lectura a escala Android. Se trata de un nuevo volumen de modelado y un salto verificable de acabado; la comparación V4/V7 permite iterar.

Esta rama visual se construye sobre PR #220 (V6), que depende de #217 y #194. **No modifica** economía, física, balance, comandos, salvados ni escenas de tanque.
