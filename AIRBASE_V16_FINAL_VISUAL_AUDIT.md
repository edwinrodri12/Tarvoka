# TARVOKA · Base Aérea V16 — revisión final del diseño 3D

## Alcance aprobado: conservar el diseño V15
Esta etapa es una **auditoría de aceptación visual**, no otra ampliación de geometría. La estructura, hangares, fachadas, torre de control, portones, colores de las ocho facciones, estados de daño y efectos de ataque V6–V15 se conservan.

Se detectó un único detalle reproducible: el punto de impacto sobre el concreto de la torre estaba centrado en un nervio vertical metálico frontal. Por eso el relieve podía verse como una placa apoyada sobre el nervio, no como un desconchón en el concreto.

### Corrección mínima de la V16
- El punto de impacto del concreto pasa a `(3.92, 1.91, -2.864)` en el sistema local del modelo, entre los nervios de la torre V1 y sobre la cara de su fuste.
- Las tres huellas del mismo paño se distribuyen ligeramente en altura y x sin trasladarlas a otros objetos.
- La profundidad aparente del relieve en el concreto se reduce a 64 %; portones y cubierta mantienen **exactamente** la escala aprobada.
- No se modifican siluetas, texturas generales, modelo de armas, iluminación, superficies del edificio, LOD, reglas del juego ni estadísticas.

### Aceptación gráfica y criterios
`tests/test_airbase_v16_final_360_gpu.gd` inspecciona:
1. Ocho cámaras de Godot (frontal, izquierda, posterior, derecha, superior, torre, interior del hangar y baja).
2. 40 combinaciones de ocho facciones por cinco estados de daño y tres niveles arquitectónicos.
3. Portones operativos de 20 componentes, lluvia/nieve reversible, paredes posteriores existentes en todos los daños que conservan hangar, ausencia de hangar en destrucción total.
4. Contacto correcto del relieve V14/V15 sobre el concreto, comportamiento del impacto y limpieza de huellas.
5. 16 imágenes auténticas de Godot: ocho vistas, tres estados de destrucción, dos condiciones de clima y tres imágenes de la torre antes/impactada/reparada.

**Criterio de cierre:** si la auditoría visual y el empaquetado web completo pasan, el edificio queda *candidato a diseño artístico terminado*. El hecho de que sea candidato no certifica rendimiento Android ni integración de gameplay; estas son fases separadas, como acordado.

Código de prueba: `tests/test_airbase_v16_final_360_gpu.gd`. Workflow: `.github/workflows/airbase-v16-final-360-gpu.yml`.
