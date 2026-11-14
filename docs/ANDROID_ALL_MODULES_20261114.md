# TARVOKA — Integración Android de desarrollo (14-nov-2026)

Fuente principal de reglas, menús, IA, economía, suministros y guardados: `main` a commit `d718d333af6ff57971e27f695034a13ea0e1505c`.

Se copian a esta rama aislada **201 archivos** de los trabajos 3D desarrollados en cuatro líneas paralelas:
- Tanque G09 V23 y su cadena de materiales, geometría, armadura, estados de daño y visor de unidades (rama `feat/g09-v23-faction-armor-readability-20261114`).
- Cuartel General V13, perfil táctico optimizado / V12 de inspección, emblemas, niveles, estados (rama `feat/hq-v13-production-ready-runtime-lod-20261114`).
- Terreno V9, relieves, riberas, agua y mapa/batalla 3D interactiva V8 de pruebas (rama `feat/terrain-studio-v9-landscape-controls-20261114`).
- Módulos propios del entorno 3D continuo con bosques, costa, texturas y niebla por sectores (rama `feat/connected-environment-map-20261113`).

En Android se agrega desde **Inicio → Estudio 3D** el laboratorio con cuatro categorías (unidades, Cuartel General, entorno y batalla sandbox). La vista de batalla 3D del estudio es una simulación separada, **no sustituye automáticamente el renderer del juego real**; el modo de batalla jugable sigue usando el motor y las reglas actuales de `main`. Los módulos visuales aún experimentales no deben considerarse arte final ni QA completado en teléfono. El visor permite volver al juego.

**Conflictos resueltos conservadoramente**: ante archivos compartidos de IA, core, menús, estados, guardados, HUD táctico, `TouchBoard` y `IsoRenderer`, se retuvo la versión de `main` para no retroceder el desarrollo de jugabilidad. Se incorporaron los módulos 3D nuevos sin forzar reemplazos inseguros. Integración combinada `CombinedArtStudioWeb` prioriza las cuatro categorías de terreno V9, usa el visor de tanque V23 y permite alternar Cuartel General V12 héroe / V13 táctico.

**Estado:** compilación de prueba. Criterios previos a entrega: Godot CI completo, APK Android ARM64 export, verificación criptográfica de firma, pruebas de carga en estudio y Android físico pendiente. No fusionar esta rama en `main` hasta resolver QA real de sus interacciones.
