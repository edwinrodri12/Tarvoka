# TARVOKA — Helicóptero de ataque A01 · tren y monturas V5

**Estado:** diseño nativo Godot 4.3, disponible en rama de revisión PR #444. NO está aún fusionado ni publicado en el Estudio 3D público.

## Revisión de la V4 real
Las once capturas Godot de V4, tomadas antes de este cambio, muestran un tren de aterrizaje compuesto por barras rectas, patines sin curvas y motores cuyo perfil se lee casi separado de la cubierta central. Por eso V5 no añade cosméticos sobre las cajas antiguas: reemplaza físicamente los patines y sus cuatro pilares V1.

## Escultura nativa V5
- **Dos patines tubulares curvos:** mallas `ArrayMesh` cerradas y continuas de doce caras en cada sección, con puntas delanteras y traseras elevadas.
- **Tren simétrico:** cuatro soportes inclinados que unen casco y patines, anclajes y codos tridimensionales, cuatro refuerzos secundarios y dos travesaños bajo el fuselaje. Nuevos perfiles reducen los rectángulos de la V4.
- **Monturas de motor:** dos zócalos sellados con sección ovalada decreciente que conectan el casco V2 con cada nacela V4, juntas metálicas/goma y cuatro brazos mecánicos.
- **Identidad de ocho ejércitos:** sólo una pequeña marca cromática en los patines, sin repintar el chasis completo.
- **Comparación no destructiva V1–V5:** `set_enabled(false)` oculta V5 y muestra los patines V1; `set_enabled(true)` oculta los antiguos. Materiales y animaciones V1 a V4 siguen intactos.
- **Impacto de gameplay:** ninguno; el puente llama V5 sólo con `Models.build("attack_heli", faction, true, art_level >= 13)`. El helicóptero económico `art_level <=10` continúa igual en Android.

## Verificación y capturas
- `tests/test_attack_helicopter_v5.gd`: inspección de 8 facciones, geometría cerrada, patines curvos, motor sellado, cuatro pilares, cambio reversible, animaciones y LOD móvil anterior.
- `tests/test_attack_helicopter_v5_capture.gd`: ocho vistas orbitales, patín delantero, zócalo del motor y travesaños. El suelo de la prueba usa un plano situado junto al contacto real del patín, corrigiendo el falso vuelo de las capturas previas.
- `.github/workflows/a01-helicopter-qa.yml` guarda `tarvoka-a01-v5-360-review` con once PNG reales generados en Godot 4.3.
- El código para incluir la nueva escultura en la web del Estudio está preparado, pero sólo se publicará cuando la rama se fusione a main tras validación.

**Siguiente prioridad:** examinar los once ángulos V5 y corregir visualmente las transiciones del tren, separación del suelo y montaje del motor antes de considerar acabada la unidad.
