# TARVOKA · G13 V12 — sellado exterior y cañones mecánicos 3D

**Estado:** implementación nativa Godot 4.3 integrada únicamente a la variante de estudio `aa_mobile` / `art_level=13`; pendiente de auditoría visual en las 22 capturas reales de la nueva versión. Este trabajo es **solo arte**, no habilita al G13 en una partida ni modifica combate.

## Cambios físicos (sobre el G13 V11)

1. **Cabina y paneles:** perfiles metálicos de volumen real en zócalos de puerta y juntas posteriores, dos pilares externos del parabrisas y junta vertical frontal. Los detalles quedan por encima de los pasos de rueda; conservan la pintura de las ocho facciones.
2. **Techo:** ocho cabezas de perno volumétricas en un único `MultiMeshInstance3D`, por lo que no añaden ocho llamadas de dibujo.
3. **Articulación de armas:** dos montajes fijos de muñón sobre la torreta de azimut, dos núcleos móviles y dos tirantes sobre el eje de elevación de cañones. No se añadieron nuevos scripts de animación: los componentes giran por parentesco con los pivotes originales V1/V4.
4. **Vainas de retroceso:** dos cubiertas sobre el inicio de los cañones, **hijas de `G13_Autocannon_±1`**, que retroceden con el cañón durante la animación V4 de 2,5 cm.
5. **Bocas huecas reales:** se sustituyó la malla de cilindro macizo dentro de los nodos originales `G13_RealMuzzle_±1` por un **`ArrayMesh` anular de 20 segmentos**, con anillo frontal, posterior, cara exterior e interior. No hay tapas sólidas nuevas ni bocas duplicadas; V4 sigue reposicionando el nodo original.

## Contratos intactos

- Cuatro ruedas y bajos G13 V6/V7.
- Cabina V11, torreta V10/V11, radar V1, superficies PBR V8.
- Las 8 facciones, selector único del Estudio 3D, cámara y animaciones de disparo terrestre y aéreo.
- `art_level=8` queda completamente fuera de la capa V12. **No se modifica consumo de combustible, munición, daño, alcance, IA, HUD táctico ni balance.**

## Aceptación automatizada

- `tests/test_g13_mechanical_finish_v12.gd` prueba 8 facciones, jerarquías, geometría de las bocas abiertas, juntas, GPU batch, apuntado a dos elevaciones, retroceso, restauración e aislamiento de LOD8.
- `tests/test_g13_v12_mechanical_capture.gd` renderiza **22 PNG**: 8 facciones, 7 vistas completas, disparos a tierra y aire, macro de rueda y 4 macros específicas de ventanillas, soportes de arma, bocas huecas y disparo en elevación.
- Pipeline: `.github/workflows/g13-v8-final-art-audit.yml`, también ejecuta regresiones V1–V11.
- El visor público se construye desde una rama de edificios y sobrepone las fuentes G13/UnitModels3D de `main`; el archivo `BastionStudioAdapter.gd` ahora indica **G13 V12**.

**Próxima etapa artística:** inspeccionar los 22 PNG, corregir posibles intersecciones en el zócalo de la cabina y los soportes al rotar la torreta, y posteriormente perfeccionar iluminación, desgaste metálico y materiales sin inflar el LOD Android.
