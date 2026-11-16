# TARVOKA — Helicóptero de ataque A01 / etapa V4

**Estado:** geometría nativa escrita en rama de diseño; pendiente revisión de capturas y aprobación para integrarse en `main`. No afirmar arte terminado ni publicado.

## Diagnóstico del render auténtico V3
Las imágenes de la prueba Godot 4.3 V3 (11 capturas orbitales y primeros planos) muestran motores exageradamente ortogonales, paneles azules demasiado grandes, cajas de mantenimiento y rejillas sueltas. Los rotores de V3, la cabina V2 y sus animaciones proporcionan una buena base que se conserva.

## Cambios de escultura V4
- `scripts/ui/AttackHelicopterEnginesV4.gd`: dos nacelas auténticas cerradas de 16 lados y seis secciones longitudinales; geometría independiente por lado con volumen afinado hacia las entradas y escapes.
- Tomas delanteras con anillos metálicos y garganta interior real (malla superficial), tres deflectores, cinco rejillas superiores escalonadas y tobera trasera de varios radios.
- Casco lateral: dos placas 3D cerradas con perfil facetado, juntas, remaches, cerradura de mantenimiento, pequeños respiraderos y sólo una insignia estrecha del color de la facción.
- Cubierta de transmisión entre motores reemplazada por un carenado 3D cerrado con ranuras, no otra caja cúbica encima.
- Los bloques V1 y algunas tapas V2 se **ocultan**; no hay dos cubiertas visibles una sobre otra. `set_enabled(false)` restaura los elementos anteriores para compararlos; la nueva geometría no toca las hélices y armas V1 ni los perfiles aerodinámicos V3.
- Ocho facciones; estudio con nuevos primeros planos de entrada de motor, escape, placas y transmisión.
- Modelo de batalla con `art_level <=10` permanece intacto. Sin modificaciones a reglas, estadística, economía, IA o motor táctico.

## Pruebas reales
- `tests/test_attack_helicopter_v4.gd`: ocho variantes, paneles y carenados de malla cerrada, uso fiel de la versión anterior, animaciones, presupuesto de mallas sin duplicaciones y modo Android previo.
- `tests/test_attack_helicopter_v4_capture.gd`: ocho cámaras 360° y tres macros de aire, blindaje y tobera del motor exportadas directamente en Godot.
- Workflow `.github/workflows/a01-helicopter-qa.yml` ejecuta V1/V2/V3/V4 y guarda las capturas en `tarvoka-a01-v4-360-review`.
- No confundir un APK de pruebas generales en CI con una entrega del modelo V4: hasta integrar la rama no se encuentra en la publicación del Estudio.

**Próxima prioridad:** evaluar en capturas V4 el acoplamiento de las nacelas al fuselaje y la simetría de tomas de aire y silueta lateral. Después, mejorar detalles del tren de aterrizaje, si siguen siendo demasiado rectangulares.
