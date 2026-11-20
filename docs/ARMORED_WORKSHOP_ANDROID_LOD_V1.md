# TARVOKA — Taller de Blindados V2 / Android LOD

## Objetivo de esta pasada
Mantener sin cambios el modelo de calidad HERO (V2 / V2.1) para inspección artística y crear dos REPRESENTACIONES 3D MÓVILES reales:
- \`PROFILE_TACTICAL=1\`: conjunto ligero de bahías, marcos, cubierta, ventanales PBR opacos, grúa y fosas de servicio, puertas y colores de facción.
- \`PROFILE_DISTANT=2\`: silueta de nave, bahías, daños, fachada e identidad visual sin maquinaria y sin adornos que no se verán a distancia.

No se generan imágenes sustitutas ni mallas vacías: ambos perfiles usan **\`MultiMeshInstance3D\` de Godot 4.3 con instancias de BoxMesh y transformaciones 3D reales**. El modelo móvil se construye directamente; NO se materializan cientos de mallas HERO para luego eliminarlas. En cada modelo móvil se agrupan materiales y detalles similares en un máximo de 11 familias de render (objetivo de lotes GPU; el número real deberá verificarse con QA).

## Contrato de selección
- \`scripts/ui/ArmoredWorkshop3DV2.gd\` conserva el aspecto HERO aprobado solo como punto de comparación; **el taller todavía no tiene aprobación artística**.
- \`scripts/ui/ArmoredWorkshopMobileLOD3D.gd\` recibe \`build(level, faction, damage, profile)\`; con \`profile=0\` devuelve HERO, con \`profile=1\` móvil táctico y con \`profile=2\` móvil distante.
- \`ArmoredWorkshopStudioAdapterV1.gd\` y \`ArmoredWorkshopDesignStudioV1.gd\` ofrecen cuatro opciones de comparación: V1 / V2 HERO / Android táctico / Android distante.
- \`main\` solo actualiza el ensamblador del visor Web para copiar el nuevo script desde la rama artística. **No se conectan aún estos perfiles al renderizador de batalla ni a la APK**.
- Las ocho facciones oficiales conservan el mismo color mediante \`VisualStyle.faction_color\`; el neutral sigue gris pizarra diferenciado de amarillo. Todos los materiales móviles son opacos.

## Daños y recursos
D0–D2 conservan estructura, cubierta, bahías, paredes sólidas y franjas de facción (D2 añade escombros). D3 pierde cubierta, puerta y ventanales enteros; queda una estructura baja y escombros. D4 elimina estructura intacta y deja los restos sobre suelo. Sin depósitos de suministro, estaciones fijas de recarga ni astillero separado.

## QA habilitado
- \`tests/test_armored_workshop_v2_native.gd\`: 135 combinaciones HERO, ya existían y se preservan.
- \`tests/test_armored_workshop_mobile_lod.gd\`: 270 variantes móviles (3 escalas × 9 paletas × 5 daños × 2 perfiles), material opaco, color real, integridad de transformaciones, presupuesto de lotes (hasta 11) y de cubos (hasta 115), ruinas sin techo y reducción frente a la cantidad de MeshInstances HERO.
- \`tests/capture_armored_workshop_v2_cameras.gd\`: 36 imágenes desde seis cámaras de Godot OpenGL: 24 HERO y 12 Android (táctico / distante) sobre N3 facción 3, con manifiesto.
- \`.github/workflows/armored-workshop-v2-art-qa.yml\`: pruebas y artefactos descargables en GitHub Actions, sin reemplazar el modelo de producción.

La ejecución exitosa de una revisión anterior **no aprueba** automáticamente estas nuevas variantes. Rendimiento real en hardware Android (ms de render, memoria, temperatura, Android WebGL y compatibilidad) **no está medido**. Mantener PR en borrador hasta una corrida SUCCESS de los dos módulos y comparación humana de las 36 imágenes; no integrar con juego/Android APK antes.

## Auditoría de vistas, derrumbe y selección LOD (siguiente prioridad)

1. Se encontró que la V2 heredaba de V1 una cubierta central todavía elevada en daño D3 y una viga frontal desprendida flotando. Ahora V2 retira esas dos geometrías del modelo ensamblado **sin cambiar V1**. Los trozos de fachada caídos del nuevo acabado V2 permanecen.
2. `tests/test_armored_workshop_v2_native.gd` comprueba la ausencia de cerchas altas, extractores, techo de V1 y viga frontal sin soporte en D3; comprueba además que V1 conserva su propia pieza original como referencia reversible.
3. `scripts/ui/ArmoredWorkshopLODPolicy.gd` elige TÁCTICO si el ancho en pantalla alcanza **152 px** y DISTANTE cuando baja a **112 px**. Dentro de la franja de 40 px conserva el perfil anterior para evitar parpadeo al pellizcar el zoom.
4. `tests/test_armored_workshop_lod_policy.gd` cubre **840 selecciones** de escala/nivel/perfil, umbrales y estabilidad al variar zoom, sin activar nunca el perfil HERO automáticamente en Android.
5. Las 36 capturas de Godot ahora incluyen verificación de primer plano no vacío, encuadre y límites de la geometría visible. Cada imagen registra `foreground_sample_count` y `foreground_bounds_sampled` en el manifiesto para auditar cuadros negros o exportaciones aparentemente satisfactorias pero vacías.

**Estado:** scripts y pruebas guardados en la rama de arte. Esto **no confirma** que las últimas capturas hayan corrido ni que el Android alcance un FPS objetivo; se precisa un resultado real de CI y revisión de las capturas para aprobar.

## Prioridad posterior: integridad de visibilidad GPU y encuadre

**Defecto preventivo corregido:** cada `MultiMesh` Android ahora calcula su `custom_aabb` a partir de las coordenadas y semiextensiones transformadas de todas las cajas, incluida la rotación y el escalado. Es indispensable porque Godot agrupa por lote para visibilidad; un límite demasiado pequeño puede hacer desaparecer una fachada completa durante zoom o giro.

Las **270 combinaciones** verifican además que cada uno de los ocho vértices reales de cada caja queda dentro de su AABB GPU. Es una prueba estructural y no sustituye la revisión de imágenes.

**Modelo HERO:** se añadieron cuatro remates de muro para unir físicamente los tres paneles laterales con los extremos frontal/posterior en los tres tamaños, cerrando unas aberturas de 3.7 % de la longitud por lado. Los tests de los 135 casos comprueban que cada tapa llega a la esquina.

**Capturas:** la prueba ahora escanea el fotograma completo de 960×720 px, rechaza escenas vacías y exige al menos 24 px de margen visible respecto a cada borde. El resultado de cada una de las 36 imágenes conserva límites aproximados en el manifiesto.

**Ejecuciones:** la rama incluye concurrencia de CI que cancela revisiones anteriores al publicar un cambio más reciente, sin tocar el flujo de despliegue general ni otros proyectos. La ejecución correcta y las capturas aún deben verificarse. El PR sigue siendo borrador.
