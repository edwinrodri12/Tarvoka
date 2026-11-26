# M01 Patrullero — arte nativo V1.0

Rol `patrol` y código M01 existentes en ModernArsenal.gd y campaña C07. No se cambian reglas, estadísticas, compras ni IDs. Seleccionado por prioridad de introducción naval, no por aprobación explícita de orden artístico. Casco cerrado, pintura por vértice, cabina facetada, detalles LOD13, radar, estela, daño D0–D4 y hundimiento visual. Integración en fábrica y selector original; QA prevista 18 variantes y 8 PNG reales, más regresión de escena compartida. Sin aprobación de arte, publicación ni prueba física Android aún.

## V1.1
Módulo visual de proa articulado, destello temporal, detalles de popa y propulsión decorativa, agua compartida del visor, controles de disparo y parada. 13 PNG previstos, incluidos cuatro fotogramas de hundimiento con cámara fija y comparación contra mar vacío. Captura del mismo visor y regresión de salida a tanque/base naval. Pendiente QA nativa y web; sin reglas nuevas.

## V1.2 — revisión de renders V1.1

Run 45903512754 aprobado (18 variantes, 90 estados, 13 PNG; artefacto 15157745973). Se inspeccionaron las 13 imágenes: cabina simple, superficies demasiado oscuras, daño D1–D3 poco distinguible, popa inferior sin detalle visible. V1.2 añade puerta posterior, visera, ventilaciones, iluminación de navegación, relieves de cubierta, rotores visuales articulados, deformación de registro y efectos ampliados. Materiales opacos propios M01 y luz ambiental de QA corregida. 16 PNG previstos con tres encuadres adicionales. No se alteran reglas ni el destructor. Pendiente prueba nativa/web V1.2.

Seguimiento V1.2: animación continua y reversible del humo y fuego, inspección inferior con ocultación temporal de suelo y agua, regreso automático a superficie para hundimiento y regresiones de cámara, estado y efectos. Publicación destructor V1.12 confirmada por push run 45902848167, PASS PUBLIC STUDIO SOURCE AND PACKAGE 101073b64b2b66b0a76c2aa8c507aa1094ad9585. Main avanzó en paralelo; reconciliar antes de fusionar M01.

## V1.3 — reconciliación y silueta

Main 01a6024eb212bb3d53c2df7a57f25927600323ec (cuatro commits paralelos A02) incorporado mediante merge de árbol. Se mantienen sus cinco capturas A02 requeridas y los archivos BastionStudioAdapter y test A02 exactos de main. Pages: ranuras de concurrencia exclusivas M01 PR/push para no desplazar otras publicaciones. Proa más fina y extendida, cubierta con alturas y ancho derivados de estaciones del casco para mantener contacto, marco de ventanas delanteras, remates de cubierta y material mate de defensas. La pose cosmética D3 no deshabilita movilidad del motor; solo D4 rechaza movimiento. Se añaden dos encuadres de proa, 18 PNG previstos. V1.2 APK y reglas aprobados, QA específica y visor pendientes al editar. Sin modificación de estadísticas.

## V1.4 — revisión visual de V1.2

16 capturas reales inspeccionadas, artefacto 15157664353. Los efectos redondos, mástil rectangular y hélices poco integradas requerían revisión. Se añade mástil facetado con base y radar, ejes de propulsión en contacto, detalles de servicio y pasos de cubierta; humo agrupado y llamas cónicas estilizadas, impacto temporal independiente de daño persistente. Materiales opacos y comprobaciones de geometría, estados y limpieza; 20 PNG previstos. No se modifica el destructor ni reglas de combate. QA V1.3 seguía pendiente al editar; V1.4 no validada.

## V1.5 — contraste, identidad y coste geométrico

V1.3 y V1.4 aprobadas en QA nativa (45907147272 y 45907458558; 18 y 20 PNG inspeccionados; artefactos 15159395048 y 15158303395). V1.5 añade relieves laterales, paneles de facción de cabina y contraste de ventanas sin transparencia. Se mide el número real de mallas y triángulos por LOD en todas las facciones y se exige menor geometría en LOD8. No se afirma FPS sin medición en dispositivo. Reconciliados ocho commits de main 8045d3e64ad4fd33c7f62fac32a0bd9c1fedf3fc: conservados A02 V17 y sus pruebas, sin cambios fuera del conjunto M01. Pendiente QA exacta V1.5 y visor; sin cambios tácticos.

## V1.6 — integración visual en mapa táctico

Se detectó que el límite genérico de 8 modelos detallados convierte las unidades restantes en discos. M01 conserva su silueta en todas las unidades visibles: hasta ocho LOD8 y siguientes LOD6, con teselación reducida de esferas, tamaño 0.64 y ajuste de altura a la superficie. La facción artística procede de la selección real; daño D0–D3 deriva de HP actual exclusivamente para representación, D4 nunca aplicado a unidades vivas. Se conserva niebla, coordenadas, ID, reglas, estadísticas y estado de partida. QA de renderer con doce patrulleros visibles y enemigo oculto, dos LOD, recuento de triángulos y estado sin mutación. Pendiente CI; no se afirma rendimiento físico ni publicación. V1.5 aún en cola al comenzar.
