# TARVOKA — Referencia visual aprobada y paridad de interfaz

## Conceptos revisados: Biblioteca / Advanced wars

- **Interfaz táctica de Tarvoka en español.png**: barra superior, ficha de unidad, acciones doradas, vistas del mapa.
- **Mapa Estratégico de Tarvoka.png**: marcos, mapa protagonista, paneles y mandos grandes.
- **Panel de producción del cuartel.png**: catálogo, unidad seleccionada y pestañas.
- **Interfaz de Abastecimiento y Reparación Estratégica.png**: tarjetas, barras de vida, combustible y munición.
- **TARVOKA: Cambiar turno en batalla.png**: HUD, barra de acciones y fin de turno.
- **Estado de Unidades: Operación Río Azul(1).png**: subtítulos, tablas y fichas.
- **Panel Logístico de Operación Río Azul.png**: tarjetas de estado y módulos.
- **Control territorial y líneas de frente.png**: leyenda azul/rojo, sin revelar niebla.
- **Interfaz de Construcción Militar TARVOKA.png**: selección resaltada y prioridades.
- **TARVOKA: Ciudades y desarrollo económico.png**: paneles y contadores.

Estos conceptos muestran edificios con niveles, mejoras, múltiples recursos, colas, poderes y otras mecánicas que no están implementadas en el motor actual. No presentar esas ilustraciones como acciones funcionales. Las imágenes tienen texto y fondos pintados: no son sprites editables de botones. Las ilustraciones originales están en la Biblioteca, NO como assets importados al repositorio GitHub.

## Integración visual funcional v1

Se extiende el sistema compartido ya fusionado: scripts/ui/GameUiTheme.gd, con bordes más luminosos.

- Paneles azul marino casi negros, borde cian eléctrico, leve halo y profundidad.
- Botones decisivos dorados (Fin turno, Confirmar, Iniciar batalla); secundarios azules.
- Estados hover, pressed, focus y disabled con contraste.
- Pestaña seleccionada dorada, encabezados claros y tarjetas separadas.
- Estilos nativos ligeros para Android, sin shaders caros.
- Barra superior del campo con datos reales (lado activo, economía, relés si existen).
- Barra inferior jugable cuando el HUD ampliado está visible: Mando, Objetivos, Cancelar, Confirmar y Fin turno.
- Menús Inicio, Centro de mando y Escaramuza ya estilizados en PR #175; esta integración refina Radar y Resultados.
- Tarjetas reales del estado, minimapa, unidad y acciones ya agrupadas en PR #175; se mantienen sin sobrescribirlas.
- Solo información pública/permitida: el concepto de tres recursos queda fuera hasta que los datos reales existan.

## Sin cambiar las reglas

No se alteran mecánicas de combate, precios, IA, facciones, economía, visibilidad, confirmaciones, campaña ni los modelos 3D. Los botones nuevos reutilizan acciones existentes de Main.gd. Un PNG conceptual no reemplaza funcionalidad.

## Pendientes visuales obligatorios

1. Capturas reales Android landscape/portrait cotejadas lado a lado con conceptos; pasar pruebas de CI o exportar un APK no equivale a paridad visual.
2. Revisar que botones no bloqueen pinch-zoom ni toques de casillas en mapas pequeños.
3. Revisar legibilidad en teléfono pequeño, pantalla larga y tablet, y accesibilidad del texto.
4. Importar en el repositorio el logo oficial, iconos, fondos, retratos y marcos de nueve parches como assets reutilizables cuando los archivos editables estén disponibles. El logo de texto es provisional.
5. Integración posterior de estos estilos en las ramas 3D y laboratorio sin reescribir Main.gd ni el HUD.
6. No etiquetar como arte final hasta pruebas visuales en dispositivo físico.

Estado: primera implementación real del acabado de conceptos. No implica equivalencia pixel-perfect.
