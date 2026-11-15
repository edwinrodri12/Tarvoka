# TARVOKA — Base Naval V1: primera arquitectura 3D original

## Decisión creativa
Después del Cuartel General y de la Base Aérea V16, el siguiente gran edificio militar que desarrollamos es la Base Naval. El objetivo es una instalación costera funcional, no un bloque genérico. Esta V1 es exclusivamente visual; no cambia economía, combate ni reglas de producción.

## Arquitectura Godot 4.3
- Dársena conectada al borde marítimo, con superficie de agua y dos espigones en U
- Muelles de hormigón con bolardos, defensas de goma y señalización
- Hangar naval con muros, cubierta a dos aguas y tres accesos
- Torre de control marítimo con cabina acristalada y radar
- Grúa portuaria con pluma, cable y gancho
- Tres niveles: muelle militar, abastecimiento y astillero avanzado
- Cinco estados visuales, con antena caída, grúa rota, cubierta perforada y ruinas
- Ocho colores de facción y escudos oficiales reutilizados

## Controles del Estudio 3D
Tercer elemento en el selector Edificios 3D, sin sustituir HQ ni Base Aérea. Nivel, daño y cuatro cámaras. Se conservan controles de zoom, rotación y galería de facciones.

Archivos: scripts/ui/NavalBase3DV1.gd, scripts/ui/CombinedArtStudioWeb.gd, tests/test_naval_base_v1_gpu.gd, .github/workflows/naval-base-v1-native-gpu.yml.

El modelo V1 es una base estructural para progresar hacia acabados comerciales. Todavía no forma parte del gameplay Android, no incluye barcos operables ni conecta su agua con el mapa real. Las pruebas de escritorio no certifican FPS Android.