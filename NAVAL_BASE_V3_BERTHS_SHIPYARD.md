# TARVOKA — Base Naval V3 | Atraque, rampas y astillero

## Alcance y continuidad
Iteración aditiva sobre los modelos de la Base Naval V1 y los acabados V2. El edificio sigue teniendo la dársena en U, dos espigones, grúa marítima, hangar, torre y superficie de agua V2. La nueva malla funciona en Godot 4.3; no habilita reglas navales, colisiones operativas, producción, FPS Android ni movimientos de embarcaciones.

## Diseño 3D agregado
- **Estaciones de atraque:** cuatro pedestales estancos, argollas, escaleras de acceso al agua con peldaños, barandales por sectores en caras exteriores; conexiones de agua/combustible a partir de nivel 2.
- **Pasarela de embarque abatible:** tablero realmente inclinado desde el borde este, bisagra y pistones, superficie de seguridad, vigas laterales y pasamanos; en daño medio se pierde parte de la rejilla y de la protección, y en crítico/destruido queda solo el anclaje arrancado.
- **Rampa de varada en el espigón sur:** plano de botadura que desciende hacia la dársena, rieles paralelos, rodillos, drenajes y cabrestante en tierra. En crítico solo sobrevive una sección con un riel caído; en destruido queda escombro.
- **Zona de reparación naval:** bancada y cunas de casco, rieles de traslado, calzos y armario de equipo; carrete de servicios desde nivel 2; puente grúa de taller, cable y gancho a nivel 3 únicamente mientras la estructura resista.

## Integración al Estudio
Edificios 3D → Base Naval. Controles independientes V2 y V3 permiten comparar **V1 → V2 → V3** sin eliminar modelos anteriores. V3 solo se monta cuando V2 está activado. Se mantienen facciones oficiales, 3 niveles, 5 estados visuales y cámaras naval, posterior, superior y general.

## Integridad de daño
En daño 2 se conserva la cubierta parcialmente ausente V2; la pasarela pierde componentes y el sistema de varada sigue utilizable visualmente. En daño 3 se mantiene el espigón seccionado y desaparecen los barandales de ese sector. Daño 4 no reconstruye grúa ni hangar, y muestra restos de la rampa y bancada.

## QA reproducible
- `tests/test_naval_base_v3_gpu.gd` inspecciona las 40 combinaciones (8 facciones × 5 daños), 3 niveles y alternancia V1/V2/V3.
- `.github/workflows/naval-base-v3-gpu.yml` ejecuta importación nativa Godot 4.3 y prueba OpenGL con capturas reales de 8 vistas. **Hasta que el workflow finalice correctamente, no afirmar pruebas GPU aprobadas.**
- Nuevo código: `scripts/ui/NavalBaseBerthsV3.gd`; integración: `scripts/ui/CombinedArtStudioWeb.gd`.

## Próxima etapa visual
Estudiar acabado de superficies y conexión del dique al litoral (anclajes, desgaste y texturas coherentes con los distintos biomas), manteniendo el relieve y la legibilidad táctica. El rendimiento Android se medirá al final de la fase artística, no como sustituto del modelado.
