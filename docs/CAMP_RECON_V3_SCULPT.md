# Campamento de reconocimiento V3 — escultura inicial

Suministros V4.5 ya integrado y publicado. Recon V3 rediseña la torre con perfiles cerrados biselados, zapatas y articulaciones, cabezal con lentes opacas, cojinetes, alas y carcasa posterior; consola de observación con paneles traseros y ventilación. El mástil telescópico usa traslación de piezas rígidas, no escalado del sensor. D2 desactiva el cabezal y D3 conserva restos, no torre funcional. Se mantiene V2 como comparación en el mismo estudio. 72 variantes (ocho facciones + neutral, dos LOD, cuatro daños), 25 PNG y pruebas del mismo visor. Primera revisión artística, pendiente comprobar CI, renders, animaciones, microacabado y aprobación. No modifica lógica táctica.

## V3.1 — cableado, óptica y materiales

La V3 pasó la exportación del estudio; la QA nativa y reglas fallaron por una función de cuantización de vértices omitida en el test. Se restituye el helper exacto sin reducir comprobaciones. Captura real del estudio mostró una torre robusta pero ópticas básicas y cableado ausente. V3.1 agrega conducto continuo cerrado entre centro de control y torre, cableado de actuador/cabezal, motor, conexiones, bisagras, disipadores y viseras; ajusta el eje deslizante para no atravesar el cabezal. Materiales opacos con mapas procedurales compartidos de 64px y pintura de facción exacta. Pendiente CI y revisión 360; no altera gameplay.

## V3.2 — estación de control y operación visual

V3.1 superó QA nativa (72 modelos/25 PNG), reglas, APK y exportación web. Capturas 360 confirmaron necesidad de dar identidad al terminal y la cubierta. V3.2 añade marco físico de pantalla opaca, trazas y barrido animados, dos módulos de comunicación con diales e indicadores, teclas diferenciadas y superficie para el operador. Cubierta elevada con soportes, costillas, pintura de facción y luminaria física (Omni sin sombras solo LOD13). D2 apaga electrónica y pierde la cubierta; D3 no opera. El botón ANIMAR RECONOCIMIENTO sincroniza consola y giro óptico en el mismo visor y cancela al cambiar modelo o plegar. 72 variantes y 27 PNG, incluidas dos vistas cercanas. Animación exclusivamente visual, sin detección ni reglas nuevas. Pendiente CI y revisión visual.

## V3.3 — plataforma y equipos auxiliares

V3.2 pasó todas las verificaciones, incluyendo 72 variantes, 27 PNG y exportación web. La revisión visual mostró una plataforma uniforme y sensores terrestres elementales. V3.3 agrega pavimento modular con paso central despejado, perfiles de acceso, anclajes, cajas de comunicaciones y batería portátil (solo arte, no producción), y sensores terrestres de carcasa opaca, lentes, base, columnas deslizantes y cables. Se integran al plegado y barrido de reconocimiento existentes. D2 inclina sensores y apaga indicador; D3 no recrea equipos. QA 72 variantes/29 renders, dos nuevas vistas cercanas, y comprobación de la animación en el mismo visor. Pendiente CI e inspección real, sin cambios de gameplay.
