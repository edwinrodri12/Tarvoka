# TARVOKA — Cuartel General · Arquitectura 3D V2 (2026-11-13)

## Propósito y alcance
Segundo pase de **arte real en Godot**, no una ilustración alternativa. Parte de la referencia aprobada «Infografía del Cuartel General de Tarvoka» (12-11-2026). Se conserva la silueta de mando con alas, helipuerto, radar, entrada y ocho facciones. No toca estadísticas, balance, IA, ciudades, economía ni guardados.

## Cambios implementados

- **Volumetría y silueta:** cuerpo principal y cubiertas con prismas octogonales achaflanados (ArrayMesh con normales, sin pegar un PNG sobre un bloque); marquesina, contrafuertes y tensores en la fachada.
- **Materiales:** materiales StandardMaterial3D diferenciados para hormigón, metal, cubierta y vidrio con texturas procedurales 128×128, relieve de juntas dibujado y variación sutil; cacheados para disminuir duplicación WebGL. No dependen de servicios externos ni de texturas ajenas.
- **Fachada:** ventanas con receso, paños de vidrio, viseras, alféizares, marcos y portal reforzado.
- **Radar:** antena parabólica **cóncava**, hecha de triángulos de malla, aro perimetral, riostras y sensor central. No es un disco/cilindro plano.
- **Helipuerto:** plataforma biselada, barandillas bajas, escalera de servicio y marcas de seguridad; mantiene la H y señalización de la versión aprobada.
- **Nivel 1/2/3:** conserva tres escalas reconocibles, cubierta de comunicaciones, paneles y módulo del radomo con ocho nervios en nivel 3.
- **Detalle de uso:** climatización, bajantes, juntas de cubierta, generadores, sensores de perímetro y señalización vial.
- **Estados:** impactos sobre fachada y elementos técnicos en «dañado», con ruinas tridimensionales adicionales, vigas y fragmentos al destruir.
- **Facciones:** se conservan los ocho colores oficiales únicamente en paneles y señalización reemplazables; los materiales de construcción siguen neutros.

## Cómo verificar de verdad
En [el visor web de TARVOKA](https://edwinrodri12.github.io/Tarvoka/) seleccionar **Edificios 3D → Cuartel General → Comparar con diseño anterior (V1)**. El botón alterna entre mallas V1 y V2. La cámara, nivel, facción y estado se mantienen para comparar correctamente. No confundir la versión del visor con un APK integrado en batalla.

Una prueba de Godot con render OpenGL real genera `artifacts/tarvoka_headquarters_v1_v2_comparison.png` (antes/después con exactamente el mismo encuadre), comprueba el incremento de mallas 3D, la antena cóncava, los materiales texturizados y las variantes de nivel/daños. No se declara acabado comercial hasta pasar esa prueba, verificar legibilidad a distancia, FPS en Android y revisar el resultado con el usuario.

## Limitaciones y siguientes pasos
Este pase sigue siendo **arte procedural de transición**, no un activo definitivo de un artista con malla retopologizada, atlas UV manual, normales de alta calidad, colisiones/control en mapas, LOD validado ni animaciones completas. Prioridad después de revisar la V2: luz nocturna/atmosférica, huellas de uso y roturas personalizadas, perfil técnico detallado, mejoras de LOD, integración en escena táctica y QA real en Samsung.

## Archivos
- `scripts/ui/HeadquartersFinish3D.gd`: construcción visual de la mejora V2 aislada.
- `scripts/ui/Headquarters3D.gd`: firma `build(level,faction,condition,finish_enabled=true)` compatible hacia atrás.
- `scripts/ui/CombinedArtStudioWeb.gd`: comparación V1/V2.
- `tests/test_headquarters_premium_v2.gd` y `.github/workflows/web-art-studio.yml`: QA gráfico y archivo de comparación.
