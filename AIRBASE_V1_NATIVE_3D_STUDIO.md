# TARVOKA — Base Aérea V1 (Godot 4.3, modelo 3D real)

## Qué se completó
Primera versión editable y 100 % nativa 3D de la instalación tipo **airbase**, integrada en la opción **Edificios 3D > Base Aérea · V1** del visor web combinado.

- Explanada compacta de 13,4 × 12,8 unidades con señalización de rodaje, helipuerto y área de operaciones: **sin pista de aterrizaje gigante ocupando el mapa**.
- Hangar principal con cuatro paredes cerradas, vigas, cuatro portones en relieve, refuerzos, ventilación, cubierta curvada 3D triangulada con 14 secciones separadas, nervaduras reales, extracción superior y paneles en niveles avanzados.
- Torre de control independiente con cabina acristalada, cristales laterales, pasamanos, radomo y antena.
- Plataforma circular de helipuerto con H construida en mallas reales, borde, balizas; taller auxiliar y combustible con tanques.
- **8 facciones oficiales**: `VisualStyle.FACTIONS` para los colores y `HeadquartersEmblems3D.emblem_texture()` para las imágenes aprobadas. No se inventan emblemas, colores o facciones.
- **Niveles 1, 2 y 3**: evolución arquitectónica de torre, instalaciones y sistemas.
- **Cinco condiciones experimentales**: intacta, radar caído, roturas de portones/techo, cabina derrumbada/ala afectada y ruinas (sin el hangar intacto).
- **Lluvia y nieve**: acabado reversible universal y precipitación compartida del estudio; no modifica HP, suministros, turnos ni ingresos.
- Materiales estándar reutilizados, mallas primitivas cacheadas por dimensiones para reducir memoria, iluminación del estudio reutilizada y sin OmniLight adicional por pieza.

## Límites transparentes
**V1 es un modelo arquitectónico editable, todavía no un edificio funcional y atacable dentro del motor de combate.** No hay producción automática nueva, no hay acciones de aeronaves entrando al hangar, no hay animaciones de impacto físico ni estados de fuego/humo para Base Aérea: esas etapas son prioridades posteriores. Los cinco estados existentes son geometría 3D distinta, no un sistema real de puntos de vida.

No reemplazar el Cuartel General V23 ni las ramas de tanque, terreno o APC; este cambio agrega únicamente un nuevo tipo en `CombinedArtStudioWeb.gd` con controles separados.

## Verificación
`tests/test_airbase_v1_native_studio.gd` cubre 8 facciones × 3 niveles × 5 estados = 120 variantes, geometría trasera cerrada, escudo oficial, daños físicos reales, UI 3D, lluvia/nieve y regresión al Cuartel. Workflow `.github/workflows/airbase-v1-native-studio-gpu.yml` exporta capturas reales de Godot usando OpenGL a través de Xvfb. Las capturas no constituyen mediciones de FPS en un Android físico.

## Próximas prioridades
1. Revisar capturas 3D por ángulo y mejorar acabados PBR y portones, reparar cualquiera deformación visible.
2. Animar portones y torre, incorporar señales de aeronaves de forma no intrusiva.
3. Humo/fuego e impactos por categorías de armas, con LOD y presupuesto móvil.
4. Cuando exista un sistema de edificios atacables, ligar sus eventos reales al controlador sin suplantar HP de unidades.
