# TARVOKA · G14 V3 — lanzadores SAM y cilindros hidráulicos nativos

**Estado:** ingeniería 3D V3 implementada en rama de revisión. No es una unidad final aprobada, no se ha fusionado con `main` y no equivale a un APK Android listo.

## Mejoras realizadas

- Cuatro contenedores SAM reales conservados del modelo V1: añaden armazones superiores de blindaje, refuerzos de pared, cierre de popa, dos posiciones de identificación por facción, **cuatro bocas metálicas anulares tridimensionales** y sellos internos oscuros.
- **Cuatro tapas articuladas individualmente** mediante pivote de bisagra propio en cada contenedor. Durante el disparo visual, solo se abre la tapa correspondiente al misil que avanza, y se cierra antes de la siguiente secuencia.
- **Dos actuadores hidráulicos telescópicos** con cilindro exterior, pistón cromado y extremos esféricos articulados. Los extremos se calculan a partir de la transformación efectiva del soporte de elevación V1, en cada fotograma, en vez de usar barras decorativas que no siguen el movimiento.
- Rodamiento de la plataforma, eje transversal mecanizado, collarines y refuerzos laterales. Separación de materiales para acero de blindaje, piezas cromadas, juntas de caucho y esmalte de facción.
- **LOD8 Android:** mallas simplificadas, sin pernos individuales. **LOD13 Studio:** biselado, pernos, metales mecanizados.
- Todos los nuevos elementos son **3D nativos del motor Godot**, no imágenes en una tarjeta y no sustituyen el vehículo aprobado previamente en otros lugares.
- El modelo continúa integrado en el **mismo visor 3D TARVOKA**. Nuevos botones: «V3 mostrar actuadores y cierres» y «V2 comparar lanzadores anteriores»; los botones de comparación V1/V2 se preservan.
- El perfil jugable `sam` permanece exactamente igual: coste 900, alcance 2–5, ataque 8 y producción en depósito de artillería. `sam_mobile` sigue siendo solo identificador artístico.

## Integración técnica

`scripts/ui/G14MobileSAMLauncherV3.gd` contiene la geometría y el rig.
`scripts/ui/UnitModels3D.gd` compone V1 → V2 → V3 y ejecuta `G14LauncherV3.sync()` después de la pose V1, restaurando posteriormente cilindros y compuertas.
`scripts/ui/BastionStudioAdapter.gd` añade las dos opciones en Animar dentro del inspector existente.
`.github/workflows/tarvoka-3d-pages.yml` ya recoge todos los archivos `G14*.gd` para el visor web y la ruta debe verificar su inclusión.

## QA antes de darlo por cerrado

La prueba `tests/test_g14_v3_launcher_hydraulics.gd` requiere 2 pistones móviles, 4 compuertas independientes, cada tubo presente en 8 facciones, animación de un solo cierre abierto en el segundo disparo, restauración tras interrumpir, 8 vistas de nivel ligero y 8 de detalle. Genera 16 capturas reales de Godot con los montajes V2/V3 para inspección.

**Pendiente:** confirmar que la CI funciona y que las capturas dejan ver realmente el nivel de detalle; corregir cualquier defecto antes de pasar a la V4. No se ha alterado la batalla ni las partidas guardadas.
