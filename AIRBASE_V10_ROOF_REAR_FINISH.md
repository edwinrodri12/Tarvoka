# TARVOKA · Base Aérea V10 — estructura de cubierta y fachada posterior

## Objetivo artístico

La V9 dejó aprobadas las perspectivas frontal, lateral, trasera, superior y del hangar. La siguiente prioridad es que la geometría **posterior e interior** tenga acabados coherentes y que ningún elemento de cubierta flote sobre los paneles curvos. Esta V10 es código **Godot 4.3 real** — no imagen conceptual, no APK Android, no alteración de las reglas tácticas.

## Nuevas superficies 3D

- **Cubierta del hangar:** una sola malla de perfiles curvos estructurales, con tres líneas de nervaduras por cada una de las 14 secciones existentes. Los perfiles se sitúan junto a la cara inferior **real de cada panel plano V1**, no sobre una curva ficticia. Otra malla contiene hasta cuatro cartelas de apoyo en los extremos.
- **Daño progresivo:** mantiene sólo los paneles y soportes existentes (14 intactos, 12 con daños medios, 8 en daño crítico, 0 destruidos); nunca reconstruye un vano roto.
- **Fachada posterior:** se conservan íntegros `MuroTraseroCerrado` de V1 y `ParedPosteriorInterior` de V2. En el exterior se añaden zócalo, cinco nervaduras, remate horizontal, puerta de servicio en relieve, lamas de ventilación y señalización de facción. La puerta de servicio **no es operable** y no representa una abertura nueva en la pared. Con daño crítico se sustituyen detalles funcionales por chapa y ducto desprendidos.
- **Equipo de cubierta:** se corrige la altura de extractores y paneles solares con interpolación entre los vértices reales de la cubierta segmentada; los equipos situados sobre huecos destruidos se ocultan. Las alturas ya no se basan en la coordenada constante de V1, que podía causar equipos suspendidos.

No se añaden focos dinámicos, partículas nuevas, colisiones, animaciones de combate ni propiedades de jugabilidad. Se mantienen los **20 componentes animados del portón V2**, las ocho facciones y las texturas anteriores.

## Comparación dentro de TARVOKA Studio 3D

Selecciona `Edificios 3D → Base Aérea · V10 · estructura y fachada posterior`, con el interruptor **«V10 · cerchas reales, fachada trasera y equipos alineados (comparar V9)»**. V9, V8, V7 y V6 permanecen seleccionables de forma independiente. Para evaluar usa la cámara **Posterior** y su zoom, la vista **Cubierta superior**, la cámara del **Interior hangar** y la comparación con V9. También sirven las vistas de daño medio/crítico, lluvia y nieve.

En carga de 8, 32 o 64 edificios, V10 sólo se instancia en los cuatro edificios cercanos; el resto conserva los LOD anteriores. No se ha afirmado rendimiento físico Android.

## Validación automática

`tests/test_airbase_v10_roof_rear_gpu.gd` exige:
- 40 combinaciones de facción × cinco daños; niveles 1, 2 y 3;
- el número correcto de secciones de techo soportadas y ausencia de soportes sobre huecos;
- materialización del muro trasero verdadero y detalles por estado;
- equipos de cubierta posicionados sobre los paneles existentes;
- clima reversible, 20 portones móviles, LOD cercano y retorno al Cuartel General;
- **12 capturas auténticas de Godot** (antes/después de fachada, acercamiento, tejado, interior, frente, lado, torre, daños y nieve).

`.github/workflows/airbase-v10-roof-rear-gpu.yml` produce el artefacto de capturas si el ensayo pasa. Publicar el estudio web público requiere ejecutar después la acción central de GitHub Pages; el PR no altera la aplicación Android comercial.
