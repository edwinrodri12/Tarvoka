# TARVOKA · Cuartel General V19 — fachadas, insignia y densidad

## Continuidad verificada

Fase sucesora de V18, heredando V17 (lluvia, nieve, biomas), V16 (sprites Android V15), V13 (2 mallas tácticas), V12 (fachada estructural) y ocho escudos oficiales.

## Trabajo implementado

1. **Alineación de luminarias V18**: las cuatro luces de las ventanas de alas están situadas en los cristales V12 reales (x=±3.46 / ±4.60; y=2.56; z≈−3.15). Las dos del muro frontal siguen el vidrio real V1–V3 (x=±1.32; y=1.26). Las dos de la torre aumentan su altura 0.91 por nivel, sin reconstrucción de mallas.
2. **Marcos de ventana V19**: 16 elementos de aluminio con sección transversal de ocho lados y bisel físico (no rectángulos dibujados ni lámina 2D). Un único MultiMesh comparte el mismo modelo para los cuatro miradores de las alas V12. El ala izquierda dañada oculta sus ocho segmentos; el edificio destruido no conserva marcos flotantes.
3. **Marco de escudo V19**: 4 perfiles metálicos alrededor, no sobre, el escudo oficial. Sigue los tres niveles (incremento 0.91 por nivel); color metálico ligeramente relacionado con la paleta oficial. Jamás modifica ni sustituye el atlas aprobado de ocho escudos.
4. **Presupuesto**: 20 segmentos físicos agrupados en 2 lotes MultiMesh, mesh compartida, sin sombras propias ni fuentes de luz adicionales. Sólo existe sobre arquitectura cercana V12. Se desactiva al alejar, mostrar Sprite3D V15, calidad V13 o estado destruido. Sin coste añadido por cada edificio del distrito.
5. **Estrés en TARVOKA Studio 3D**: selector 49 (7×7), 100 (10×10) o 144 (12×12) edificios. El modelo de distrito utiliza exclusivamente la función existente `HeadquartersCityBatch3D.build_grid()`, agrupada por variante de facción, estado y nivel con mallas compartidas. Preserva ocho facciones y funciona en la misma galería sin APK.

## Visor y controles

`scripts/ui/CombinedArtStudioWeb.gd` mantiene las vistas de ocho facciones y añade el interruptor reversible `V19 · Marcos biselados y contraste del escudo oficial`. El panel de estrés sólo se muestra al activar el distrito de edificios, con escenarios 49/100/144. Mover o girar el cuartel mantiene unidos los remates porque son hijos del modelo.

## Pruebas

- `tests/test_hq_v19_facade_stress.gd`: malla biselada compartida, 20 instancias/2 lotes, 8 texturas oficiales, estados sano/capturado/dañado/destruido, 3 alturas, lluvia, LOD distante, Sprite3D, modelo táctico V13 y carga 49/100/144 MultiMesh.
- `.github/workflows/hq-v19-facade-stress-gpu.yml` usa Godot 4.3 real en GPU Mesa/Xvfb. Guarda 6 capturas de calidad, lluvia, noche y densidad.

**Importante**: el número de lotes del distrito no equivale necesariamente al número de *draw calls de GPU*, dado que cada malla por material puede requerir superficies distintas. El benchmark de estrés es una validación de coherencia y de FPS del visualizador, no una garantía de 60 FPS en teléfonos Android de gama baja ni de 144 HQ por partida de ocho jugadores. Para Android se conserva el perfil V13 sin la decoración hero.

## Distribución protegida

V19 se desarrolla en rama independiente. El publicador `tarvoka-3d-pages.yml` debe cambiar la fuente del visor principal solamente cuando el CI de Godot nativo, regresiones V17/V18 y exportación WebGL sean satisfactorios, preservando `/batalla/`, `/tanque/` y `/batalla-g09/`. El APK permanece sin cambios.

## Pendientes reales

- Revisión visual humana de capturas para confirmar encaje óptico con cristales y proporciones.
- Medir FPS y VRAM en hardware Android físico antes de fijar presupuestos definitivos.
- Decidir si los materiales V19 se hornean en nuevos sprites Android, previo control de niebla y visibilidad.
