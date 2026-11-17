# TARVOKA · Ciudades V15 — identidad de los tres niveles urbanos

**Estado:** avance de escultura tridimensional, pendiente de aprobación artística. No se han realizado pruebas de jugabilidad, rendimiento ni APK.

## Objetivo

Que los tres niveles de ciudad civil se identifiquen de inmediato incluso desde la vista táctica de Godot, con ocho posibles colores de facción y en cualquiera de las cinco etapas de daño.

### Villa — nivel 1

Arquitectura baja con cubierta de teja **terracota**, aleros y arriostramientos de madera, zócalos de piedra y remates a dos aguas. En D2 pierde el caballete continuo y conserva fragmentos cerámicos. En D3/D4 se distingue por piezas de teja y madera carbonizada de baja altura.

### Ciudad — nivel 2

Volumen intermedio de **ladrillo y piedra**, bandas de mampostería, cornisas horizontales, pilastras y servicios en la azotea existentes en V8. En D2 presenta cornisas quebradas y sillares. En D3/D4 mantiene pilastras truncadas y restos de ladrillo.

### Metrópoli — nivel 3

Bloques altos con **vidrio, aluminio y acero**, coronas escalonadas, nervaduras de fachada, bandas de vidrio y color de facción. D2 exhibe perfiles torcidos y cristales impactados. D3/D4 muestra columnas de concreto abierto, barras y restos de vidrio con material PBR del tipo glass en el suelo.

### Ayuntamiento

Tiene un remate distintivo según el nivel urbano. Cuando se destruye, también cambia el tipo de fragmentos: sillar en villa, mampostería en ciudad y metal/cristal en metrópoli, sin recrear torres intactas sobre ruinas.

## Integración

- Nueva capa: `scripts/ui/CivilianCityIdentityV15.gd`
- Cadena acumulativa en `CivilianCityTacticalLOD4.gd`: V1–V4, V8–V15
- Nueva escena: `scenes/CivilianCityDesignStudioV15.tscn`
- El visor V15 permite cambiar nivel urbano sin resetear facción ni daño. Botones para silueta lejana, primer plano y comparación D4
- La edición sigue aislada en `art/cities-v8-rear-facades-rooftops-20261117`; `main` solo tiene integración del publicador web

**Próxima prioridad:** refinar las uniones visuales que aún puedan parecer planas entre madera/teja, piedra/cornisa y metal/vidrio, manteniendo la legibilidad de las siluetas desde las cámaras superiores. No marcar el diseño como aprobado ni iniciar QA de jugabilidad o compilación APK.
