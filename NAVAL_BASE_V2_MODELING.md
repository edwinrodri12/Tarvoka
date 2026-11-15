# TARVOKA — Base Naval V2 | Muelles, astillero, grúa y agua

## Objetivo
Continuación visual del modelo Godot 4.3 Base Naval V1. Se conserva su silueta en U, el espacio del puerto, la torre de control y los tres niveles. No se altera la economía, la producción de navíos, los turnos ni el gameplay Android.

## Cambios realizados
- Muelles con coronaciones y zócalos de hormigón, defensas de goma, planchas metálicas, juntas de pavimento, bolardos de amarre y señalización antideslizante.
- El muelle roto en daño crítico permanece interrumpido, sin construir geometría completa sobre el agujero.
- Astillero: pilastras, zócalos, ventilación lateral, drenaje, nervaduras sobre los paneles de cubierta realmente existentes y refuerzos de puertas.
- Grúa: pluma espacial con vigas superior/inferior y diagonales, polea y guía del gancho. En daños medio/crítico se muestran solo refuerzos caídos; no una pluma milagrosamente intacta.
- Material de agua original de Godot con ondas sutiles animadas, transiciones de color hacia el muelle y luz suavizada; se evitaron reflejos planos costosos.
- Facciones: se mantienen los ocho colores y los escudos oficiales de V1.

## Inspección V1 / V2
Seleccionar Edificios 3D → Base Naval V2 en TARVOKA Studio. El interruptor 'V2 · muelles, techo, grúa y olas (comparar V1)' permite retirar o restaurar los acabados nuevos sin cambiar el proyecto táctico. Se conservan tres niveles, cinco estados de daño y cuatro cámaras.

## Control de calidad
Test: tests/test_naval_base_v2_gpu.gd. Workflow: .github/workflows/naval-base-v2-gpu.yml.
Valida 40 combinaciones de facción × daño, 3 niveles, geometría de pier/dique roto, modelo de celosía de la grúa y caída por daño, paneles de cubierta omitidos por daño, agua con shader, selector del Estudio y 12 capturas nativas de Godot.

Esta V2 es un avance artístico inicial. No declara terminada la Base Naval ni establece FPS Android o integración del agua al mapa de batalla.