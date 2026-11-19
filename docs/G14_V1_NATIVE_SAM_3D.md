# TARVOKA — G14 batería SAM móvil · V1 (inicio del diseño)

Estado: **prototipo de arte 3D**, no aprobado ni integrado en batalla como visual definitivo.

## Identidad

- Silueta totalmente distinta del G13 (4×4 de cañones) y G15 (6×6 de guerra electrónica): G14 es un portador SAM blindado **8×8 de cuatro ejes**.
- Cuatro contenedores cerrados 2×2 con giro de plataforma, elevación conjunta, radar en mástil independiente y cuatro patas estabilizadoras plegables.
- Cabina blindada con cristales azul petróleo, acero satinado, rieles y detalles de facción moderados; ocho colores TARVOKA originales.
- Los ocho neumáticos y sus ocho bujes comparten **dos MultiMesh**, evitando fabricar una docena de objetos por cada rueda.
- Animaciones de rodaje, desplegar, barrido, apuntar, lanzamiento visual, replegar e impacto con reposición segura.
- Android (LOD8) y alta definición del visor (LOD13), con el mismo chasis y silueta.

## Arquitectura

- Modelo nativo: `scripts/ui/G14MobileSAMV1.gd`.
- Alias artístico: `sam_mobile` en `UnitModels3D.ROLES`.
- Visor unificado: `scripts/ui/BastionStudioAdapter.gd` recibe el selector G14 y su pestaña de animaciones (sin abrir un visor independiente).
- Unidad jugable: `sam` código G14 en `ModernArsenal.gd` **sin cambios**. El nuevo alias artístico no se registra en el motor de combate.
- Prueba reproducible: `tests/test_g14_v1_native_sam.gd`, ocho facciones y capturas Godot reales.
- CI: `.github/workflows/g14-v1-native-sam-qa.yml`.

## Siguientes mejoras antes de pedir aprobación final

Refinar curvaturas de neumáticos, paneles inclinados verdaderos, cierres de contenedores, reflejos de vidrios y rig de daños completo. Una vez aprobado el arte, conectar `sam` al juego principal reutilizando el rol ya jugable, como en G13.

**No declarar final ni APK listo hasta validar Godot, el visor publicado y pruebas Android.**
