# TARVOKA — G16 V1 · Camión logístico blindado 6×6

**Estado:** primera escultura 3D nativa implementada, para revisión de arte y QA. No está fusionada con la rama principal y no se ha comprobado aún en el visor web publicado.

## Identidad de la nueva unidad

**Código táctico existente:** `G16`; **rol jugable:** `logistics`. La unidad ya figura en el arsenal como soporte terrestre de **coste 300, 8 HP, movimiento 4, ataque 0, visión 3, producida en fábrica**. No se modifican esos valores, la IA, la economía, los depósitos de munición/combustible ni los datos guardados.

**Nuevo rol exclusivo de revisión artística:** `logistics_mobile`. Se mantiene separado de `logistics` hasta que se apruebe la geometría y se prepare una integración segura del modelo en batalla.

## Primera propuesta de modelado 3D

- **Carrocería propia 6×6**, con motor y cabina adelantados, volumen trasero de carga abierto. No reutiliza las siluetas SAM G14 ni guerra electrónica G15.
- **Cabina completamente maciza**, vidrio frontal/lateral volumétrico `BoxMesh` en tono azul petróleo, acabado PBR y transparencia desactivada. Nada de paredes transparentes.
- **Seis neumáticos físicos**, seis bujes mecanizados, seis perfiles de dibujo real implementados con `MultiMesh` (20 bloques por rueda en Android LOD8; 36 en Studio LOD13).
- **Dos depósitos metálicos de combustible**, soportes de fijación y **dos cajas selladas de municiones**, diferenciados visualmente.
- Bandas de identificación aplicadas a paneles concretos de cada una de las **ocho facciones**: no pintar toda la carrocería del color del ejército.
- **Grúa telescópica** trasera con brazo principal, extensión cromada, cable de gancho y una caja suspendida que se hace visible al descargar.
- **Rampa metálica abatible**, módulo de toldo lateral macizo y dos estabilizadores para representar un punto temporal de suministro.
- Indicadores lumínicos de descarga con materiales emisivos discretos; estos efectos visuales no generan recursos.

## Animaciones en el MISMO visor 3D

`idle`: carrocería y carga recogidas.

`move`: giran las seis ruedas.

`deploy`: toldo, estabilizadores y rampa se abren.

`unload`: grúa articula y levanta una caja.

`resupply`: muestra descarga e indicadores de abastecimiento *sin ejecutar reglas de juego*.

`camp`: puesto temporal desplegado. **No equivale a campamento ya implementado en combate**.

`pack`: recoge todo el equipo.

`hit`: reacción de suspensión/carrocería a impacto, sin aplicar daño.

## Archivos entregados

- `scripts/ui/G16ArmoredLogisticsV1.gd` — carrocería y animación Godot.
- `scripts/ui/UnitModels3D.gd` — registro `logistics_mobile`, colores de facción y API de pose.
- `scripts/ui/BastionStudioAdapter.gd` — selector y botones de animación del visor existente.
- `.github/workflows/tarvoka-3d-pages.yml` — copia el archivo nativo G16 al exportar el visor unificado, no un visor paralelo.
- `tests/test_g16_v1_native_3d.gd` — QA de geometría y escena Godot.
- `.github/workflows/g16-v1-native-logistics-qa.yml` — prueba Godot 4.3/GL y artefacto con **16 PNG** (8 facciones × transporte y campamento).

## Criterios de aprobación antes de V2

1. Revisar capturas desde todos los ángulos: cabina, techo, cristales, cargas y parte trasera.
2. Confirmar que se ve la V1 en el visor web publicado y que responde a controles en Android horizontal.
3. Comprobar que las ocho facciones se distinguen y el neutro no se confunde con amarillo.
4. Validar normal/LOD8 y los dibujos de neumáticos sin un consumo excesivo de GPU.
5. Tras la aprobación visual, V2 refinará los biseles, carrocería, grúa y suspensión al nivel de las unidades aprobadas.

**Nota de diseño:** no añadir un edificio permanente de reabastecimiento. La unidad G16 podrá representar gráficamente el apoyo temporal; las reglas reales de campamentos deberán implementarse o verificarse en un cambio de jugabilidad separado.
