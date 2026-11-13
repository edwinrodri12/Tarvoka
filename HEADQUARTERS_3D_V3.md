# TARVOKA — Cuartel General V3 · Pase de arquitectura comercial (13 noviembre 2026)

## Alcance entregado
A partir de la referencia aprobada «Infografía del Cuartel General de Tarvoka» del 12 de noviembre, V3 modela una **fachada militar distintiva y legible** mediante geometría 3D nativa Godot 4.3; no se ha sustituido el estilo por una ilustración.

- **Acceso reforzado:** pórtico biselado, puertas dobles acorazadas y placas de identificación intercambiables.
- **Silueta de mando:** dos torrecillas esquineras, riostras y coronamiento frontal con franja de facción.
- **Cubierta técnica:** pabellón de mando elevado, ventanas panorámicas, elementos de señalización luminosos; mástiles nuevos en nivel 2 y estructura triangular elevada en nivel 3.
- **Helipuerto:** patas de refuerzo, balizas y guías de borde; se conserva la H aprobada.
- **Zona operativa:** barreras de acceso, farolas, señalización logística y equipo de servicio.
- **Daños:** roturas alrededor del pórtico y, en ruinas, piezas colapsadas diferenciadas.
- **Materiales:** reaprovecha la biblioteca de superficies V2 para hormigón, acero, cubierta y cristal; añade solo materiales emisivos cacheados para luces. Sin recursos comerciales de terceros.
- **Facciones:** ocho tonos oficiales de `VisualStyle`, exclusivamente sobre elementos pintables independientes.

## Comparación real
En [el visor web público](https://edwinrodri12.github.io/Tarvoka/) se puede entrar a **Edificios 3D → Cuartel General → Comparar arquitectura V2 / V3**. Se mantiene el mismo nivel, facción, estado y cámara. El botón V1 heredado sigue disponible.

`tests/test_headquarters_v3.gd` comprueba:
1. Tres niveles y piezas únicas por nivel.
2. Ocho colores de facción.
3. Materiales emisivos de señalización.
4. Captura, daños y ruinas.
5. Geometría nueva frente a la V2 y cambio visible de píxeles en render real.
6. Salida y regreso a Unidades sin alterar el tanque G09.

El workflow genera `artifacts/tarvoka_headquarters_v2_v3_comparison.png` desde Godot OpenGL (antes/después, misma cámara), lo adjunta a su paquete de inspección y exporta WebGL 2.0. No se requiere instalar APK.

## Pendiente de «comercial»
Esta mejora NO equivale a un modelo final: faltan modelado artístico manual/retopología, mapas normales y UV diseñados, atlas optimizado, perfiles de render para Android, variantes LOD y una integración formal en el mapa táctico. La representación visual no establece estadísticas, economía o colisiones. No modificar motor de combate ni los modelos de las unidades en este pase.

## Archivos
- `scripts/ui/HeadquartersDetail3D.gd`: nuevo pase V3 desacoplado.
- `scripts/ui/Headquarters3D.gd`: `build(level,faction,condition,finish_enabled=true,detail_enabled=true)`; compatible con invocaciones anteriores de 3 o 4 argumentos.
- `scripts/ui/CombinedArtStudioWeb.gd`: control V2↔V3 y cámara orientada hacia fachada frontal.
- `tests/test_headquarters_v3.gd`: test de render y modelos.
- `.github/workflows/web-art-studio.yml`: captura y validación de producción.
