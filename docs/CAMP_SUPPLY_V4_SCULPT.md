# Suministros V4 — revisión artística real

La captura anterior mostraba una maqueta de cajas planas, cubierta con barras
gruesas y una fachada posterior pobre. La V4 sustituye piezas importantes por
mallas nativas cerradas con bisel 3D, depósitos de extremos curvos, manguera
continua, jambas y ventilación trasera, cubierta con juntas delgadas, paneles
de identidad y cubierta/gable articulados. Conserva el tamaño de casilla,
carácter temporal, daño D0–D3 y ambos LOD; no modifica reglas de batalla.

El selector Suministros V4 / V3 vive dentro del Estudio 3D original, con
el mismo ángulo, zoom, facción y estado. La V3 permanece disponible para
comparar directamente. No se consideran aprobados los otros tres campamentos
por este cambio: deberán recibir revisiones equivalentes individualmente.

QA: 72 combinaciones (incluido neutral), auditoría de aristas de las nuevas
mallas, 16 PNG nativos de Godot y comprobación del comparador en la escena
web real. Publicar únicamente después de revisar los resultados.

## V4.1 — revisión de 16 capturas reales

El primer CI generó 16 PNG y el export web pasó, pero la auditoría marcó ocho falsos negativos de pintura neutral (-1). Se conserva el umbral y se contrasta con el color neutral real de la factoría. La inspección detectó además dos tensores que atravesaban el techo, solape de faldones en cumbrera, paredes planas y barreras macizas que ocultaban depósitos y cajas. V4.1 ajusta las hojas al eje central, monta una cumbrera articulada, elimina tensores obsoletos, esculpe refuerzos laterales y sustituye barreras por bastidores abiertos. Añade pasarela modular a ras de plataforma. No altera la huella ni la lógica táctica. Requiere nueva QA y comparación de renders antes de publicación.

## V4.2 — materiales, herrajes y daño físico

El CI V4.1 pasó todas las auditorías y la exportación del estudio compartido. Al revisar las seis vistas principales de sus 16 PNG se confirmó la falta de diferenciación de superficies y daño D2 demasiado simple. Esta revisión introduce tres mapas procedurales opacos y deterministas compartidos de 64×64 (metal, tejido/panel, caucho), con triplanar nativo, mipmaps y valores PBR; conserva el color base oficial de las ocho facciones y neutral. Incorpora bridas de inspección, collarines, pernos y bisagras anclados, estación con instrumental visible y placa de acceso. D1 muestra abrasiones, D2 sustituye realmente la geometría de la cubierta sobreviviente por un volumen cerrado deformado y añade restos, sin reconstruir D3. Se amplían las auditorías de materiales, rig y daño, conservando las 72 variantes, 16 capturas, comparación V3/V4.2 y un único visor. No hay cambios de gameplay. Pendiente validar renders y CI nuevos antes de fusión.

## V4.3 — interior, iluminación y animación de servicio

V4.2 pasó el CI nativo. V4.3 reemplaza mobiliario V3 por bancada, cajones, consola y estantería; un difusor sólido emisivo y una luz Omni sin sombras iluminan el interior en LOD13 D0/D1. Los controles VER INTERIOR/CERRAR TECHO y ANIMAR SERVICIO operan bisagras, palanca y aguja reales en el mismo estudio. El servicio es exclusivamente visual y reversible; D2/D3 no operan. D3 tiene chapas cerradas deformadas y bastidores derrumbados. QA mantiene 72 variantes y 16 PNG, incluida inspección interior, más controles del estudio unificado. Pendiente revisar CI y renders antes de integrar.
