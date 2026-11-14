# TARVOKA — Cuartel General V21: muro trasero, deterioro físico y animaciones de impacto

## Alcance / compatibilidad

Versión posterior a V20, sobre las ramas apiladas V19/V18/V17. Sin alterar el motor de combate, facciones, estadísticas de daño, estados del guardado, el tanque G09 ni el terreno. El visor utiliza modelos nativos Godot 4.3, no una fotografía generada.

### 1. Pared posterior totalmente cerrada

`Headquarters3D._building()` incluye un grupo `CerramientoTraseroEstructuralV21`:
- Muro central completamente opaco de 5.82 m de anchura y altura adaptada a los tres niveles (2.87, 3.78 y 4.69 m), exterior z=2.865; frente al volumen original que llega hasta z≈2.81.
- Dos muros posteriores de ala (2.30 × 2.24 × 0.26 m cada uno), retorno al bloque central, zócalo y dintel posterior.
- Refuerzos en extremos, cornisas y respiraderos con fondo sólido; no hay agujeros por omisión ni planos de un solo lado. El edificio destruido mantiene únicamente fragmentos y escombros, no un cerramiento intacto.
- Geometría independiente de cámara, visible al rotar el edificio y construida para las 8 facciones y los 3 niveles.

### 2. Cinco etapas de daño 3D, progresivas

`scripts/ui/HeadquartersDamageV21.gd` gestiona:

0. **Intacto:** pared, cristales, alas y escudo sin alteraciones.
1. **Impactos leves:** tres zonas con hundimientos tridimensionales, bordes de metal y pequeñas grietas segmentadas.
2. **Moderado:** elimina realmente la geometría de un vidrio de la entrada y partes del cristal de puerta; añade fragmentos inclinados y marcos doblados, fisuras y placas posteriores caídas. Se acumulan los daños de la primera fase.
3. **Crítico:** elimina realmente el panel posterior izquierdo de ala, el pretil curvo y parte del vidrio; aparecen piezas fracturadas, vigas de acero expuestas, cornisa caída, humo y fisuras severas. Se conservan las etapas anteriores.
4. **Destruido:** usa el modelo original de auténticos escombros y añade restos del muro trasero/varillas, sin edificio sano superpuesto.

La selección de nivel de daño es explícita y reversible reconstruyendo el modelo. Los ocho emblemas oficiales mantienen sus texturas y paletas; los daños no cambian HP en la lógica de combate. La categoría existente *Operativo, Capturado, Dañado, Destruido* se conserva para compatibilidad, con *Dañado* inicializando la etapa 2.

### 3. Dos animaciones diferenciadas para ataques

`scripts/ui/HeadquartersImpactV21.gd` incorpora un nodo 3D residente en el modelo detallado que permanece inactivo hasta pulsar un control:
- **Impacto de balas** (0.62 s): un lote MultiMesh de 12 fragmentos/chispas pequeñas con trayectorias balísticas rápidas; desaparecen al terminar, sin efectos explosivos.
- **Ataque explosivo** (1.75 s): destello volumétrico breve, onda de choque toroidal, un lote MultiMesh de 18 fragmentos grandes con gravedad y rotación, y 3 volutas de humo que se elevan y disipan.
- No se crean OmniLight3D adicionales ni cientos de objetos por proyectil. No se toca física, habilidades, movimiento, combate ni guardados; aquí son previsualizaciones del efecto, no un sistema nuevo de HP.
- Se detienen y ocultan al pasar a LOD distante; no existen sobre Sprite3D Android V15 ni perfil táctico económico V13.

### 4. Studio 3D

Dos controles en **Edificios 3D → Cuartel General**:
- **Niveles de daño estructural · V21**: selector de las 5 etapas, integrado al selector de estado anterior.
- **Impacto de balas / Ataque explosivo**: dos botones activos en modelo 3D detallado.

El visor conserva las 8 facciones, lluvia, nieve, iluminación, zoom, rotación y los escenarios de 49/100/144 cuarteles de las versiones anteriores.

### 5. QA y pendientes comerciales

`tests/test_hq_v21_rear_damage_impacts.gd`: inspección espacial de muros, reversibilidad de cinco etapas, destrucción realmente abierta, reconocimiento de emblemas, reproducción de dos animaciones con duraciones diferentes, controles del visor y capturas desde cámara trasera. `.github/workflows/hq-v21-rear-damage-impact-gpu.yml` ejecuta Godot 4.3 nativo y archiva seis PNG GPU.

**Falta** validación visual humana de capturas para detalles de recorte, exportación WebGL release, publicación GitHub Pages y validación física Android de FPS. El nuevo arte V21 es de inspector detallado; no se afirma que 144 edificios carguen la geometría V21. El juego táctico mantiene versiones compactas hasta completar mediciones y horneado de sprites.
