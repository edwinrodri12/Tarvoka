# TARVOKA Base Aérea V12 — bordes quemados, vigas dobladas y esquirlas de explosión

## Desarrollo de geometría 3D real
La V12 extiende V11 en Godot 4.3; no es una ilustración de concepto ni una APK nueva.

- **Quemaduras de cubierta:** cinco segmentos de acero ennegrecido en cada una de las dos fronteras reales de los huecos de daño medio y crítico. El daño leve sólo añade tres pequeñas marcas, sin simular roturas mayores.
- **Acero retorcido:** vigas en dos tramos sólidos unidos, dobladas hacia el interior de cada agujero. Se evita cualquier barra que una dos bordes de un hueco inexistente.
- **Destrucción final:** seis perfiles metálicos derrumbados a ras de las ruinas originales, sin reconstruir hangar ni techo.
- **Fragmentos animados:** seis pequeñas esquirlas tridimensionales sólidas, con mallas irregulares reutilizadas. Sólo se activan pulsando **«Explosión»** en el visor. Se desplazan y giran durante 0,57 segundos, después permanecen entre los escombros hasta el siguiente impacto o reconstrucción de la vista. Un impacto de bala mantiene el efecto breve anterior, sin estos fragmentos adicionales.
- **Presupuesto móvil:** en daños medio/crítico, dos mallas estáticas de acabado y seis esquirlas que normalmente están ocultas. No se agregan sombras dinámicas, luces, física de cuerpos rígidos ni nuevos sistemas de partículas. En vista de 8/32/64 bases, sólo los cuatro edificios cercanos reciben V12.

## Inspección en TARVOKA Studio 3D
En `Edificios 3D → Base Aérea V12`, activa/desactiva **«V12 · bordes quemados, vigas torcidas y fragmentos (comparar V11)»**. Para ver la geometría, elige **daño medio o crítico**, cámara **Cubierta superior** y el control V11 **«Inspeccionar cerchas: ocultar chapas del techo»**. Luego cambia entre V11/V12 para comparar el mismo encuadre.

Pulsa **«Explosión»** para ver los seis fragmentos desprenderse sin afectar la salud del edificio. Se mantienen los cinco niveles de daño, ocho facciones, portones animados, clima, cristales, fachada y controles del estudio.

## Validación
`tests/test_airbase_v12_fracture_gpu.gd` comprueba en Godot 4.3:
- 40 variantes de facción × daño, tres niveles arquitectónicos.
- Dos bordes realmente rotos en los daños medio/crítico; ningún perfil sobre huecos inexistentes.
- Uniones en dos segmentos de acero doblado y número de fragmentos creados.
- Explosión repetible con seis fragmentos reutilizados y animados, sin nuevas instancias al repetir.
- Mecanismo original de 20 piezas de portón, lluvia/nieve reversible y cuatro bases cercanas con LOD.
- 11 capturas Godot antes/después, daño medio/crítico, explosión, ruinas y nieve.

Pipeline: `.github/workflows/airbase-v12-fracture-gpu.yml`. El juego Android, su HP, combate, economía y FPS físicos **no** se han modificado ni medido.
