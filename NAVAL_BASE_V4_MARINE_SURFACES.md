# TARVOKA · Base Naval V4 — Corrosión marítima, hormigón y transición costera

## Objetivo
Perfeccionar los materiales reales del modelo 3D de la Base Naval V3 sin cambiar su construcción, las 8 facciones, sus escudos oficiales, las 3 etapas de arquitectura ni los 5 estados de daño. **No** se modifican reglas de combate, economía, capturas, construcción o navegación.

## Geometría y materiales
1. Nuevo **shader espacial original Godot 4.3** (sin recursos descargados): ruido determinista en coordenadas mundiales, rugosidad diferenciada, metalicidad y pátina controlada con banda de marea. `assets/shaders/naval_marine_weathering_v4.gdshader`. Superficies de piedra/hormigón con sal/humedad; acero expuesto con oxidación localizada. No se colorean los escudos y líneas oficiales de facción.
2. Tratamiento de las **mallas originales de la V1–V3**, no simples imágenes superpuestas: bordes de coronación, espigones existentes, grúa, astillero, rampa de botadura, torre y componentes de embarque. `scripts/ui/NavalMarineFinishV4.gd`.
3. **Marea y sal:** manchas tridimensionales escalonadas en el paramento vertical interior del muelle, pequeños goteos de óxido desde juntas y contactos de espuma muy suaves; las marcas del espigón destruido desaparecen con él.
4. **Costa:** piedras irregulares mediante geometría de baja densidad, y costuras de grava en el límite exterior del patio portuario. Se sitúan junto a la costa (x>2.6, |z|>6.0); no invaden el canal central de navegación.
5. **Astillero:** marcas discontinuas de rodadura y suciedad industrial en el suelo, adaptadas a daños críticos y niveles de equipamiento. Se conservan exactamente los agujeros de cubierta del modelo V2 y las piezas ausentes de V3.

## Estudio 3D
Nueva casilla `V4 · corrosión, mareas y costa (comparar V3)`. El orden de capas es V1 → V2 → V3 → V4; V4 exige V2 y V3 activos. Al desactivarla se crea de nuevo la V3 con sus materiales previos; no se alteran los modelos históricos. Se conservan el selector de facción, el daño, la cámara panorámica, la vista marítima, posterior y cenital.

## Alcance de calidad y rendimiento
Prueba nativa declarada: `tests/test_naval_base_v4_gpu.gd`, workflow `.github/workflows/naval-base-v4-gpu.yml`. Comprobaciones de 40 variantes (8 × 5), 3 niveles, acero/hormigón con material shader, rocas fuera del canal, espigones rotos, escudos oficiales y comparación V1/V2/V3/V4, más 8 capturas de Godot. **No afirmar resultados aprobados antes del cierre del workflow**. La eficiencia y FPS Android, integración del agua con el mapa táctico, UV artísticos y biomas dinámicos quedan para fases posteriores.

## Siguiente prioridad visual propuesta
Corrección final de escala, sombreado y siluetas del astillero desde todas las cámaras; luego elementos de señalización naval de alta legibilidad (balizas, numeración, iluminación no deslumbrante). No se sustituye el desarrollo del juego por imágenes conceptuales.
