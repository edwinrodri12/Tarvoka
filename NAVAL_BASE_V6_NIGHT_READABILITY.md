# TARVOKA — Base Naval V6: inspección nocturna y legibilidad táctica

## Objetivo
En el modelo 3D real del puerto, mantener la complejidad cercana de V5 y que los componentes importantes sigan siendo legibles al alejar la cámara. Introducir inspección nocturna con iluminación real, controlada y sin exageración. No modificar producción, unidades navales, economía ni reglas tácticas.

## Implementado en GDScript (Godot 4.3)
- `scripts/ui/NavalNightReadabilityV6.gd` se añade **después** de V1–V5 y solo si están presentes las capas anteriores.
- Con zoom cercano aparecen bandas antideslizantes por tramo, diagonales y pequeñas juntas reales del astillero; con zoom lejano aparecen siluetas simples, contrastadas y coherentes con la facción sobre los espigones sobrevivientes, el borde del puerto y la bancada de reparación. Se usa `set_detail(model,near_view)` y se respeta el umbral de zoom ortográfico `_zoom>=0.85` del Estudio.
- `set_night(model,enabled)` habilita/oculta las luces de trabajo V5 sin añadir mapas de sombras, y controla pequeños marcadores de muelle y guía de torre; una luz Omni de alcance 2.55 y energía 0.22 solo existe si la cabina se mantiene.
- La textura de oxidación V4 y la señalización V5 no se pierden. Los paneles faltantes de techo, la grúa colapsada y el espigón positivo desaparecido siguen ausentes en sus estados correspondientes.
- El Estudio tiene interruptores independientes **V6 · señalización distante y acabados (comparar V5)** y **Vista nocturna · reflectores y balizas reales**; conserva cámara, zoom, nivel, facción y daño. La vista nocturna aplica la iluminación ambiental nocturna existente; al desactivarla restaura el preset anterior.

## Validación nativa
`tests/test_naval_base_v6_gpu.gd` + `.github/workflows/naval-base-v6-gpu.yml`: 8 facciones × 5 daños (=40), 3 niveles, encendido/apagado nocturno, cambio de detalle automático por zoom, comparación V5, ocho capturas reales de Godot. No se afirma aprobado hasta que termine la ejecución correspondiente.

## Siguiente prioridad artística
Revisar calidad estética de noche y primer plano en Android real, y corregir proporciones/puntos de atraque según las capturas; evaluación de rendimiento posterior, no a costa de abandonar el modelado. El proyecto Android jugable permanece fuera de este avance.
