# TARVOKA · Base Aérea V13 — impactos según superficie y tipo de ataque

## Estado del arte 3D real

Esta prioridad continúa el modelado de la Base Aérea V12 en **Godot 4.3**. El objetivo es dar respuestas visuales distintas a tres categorías de armamento, dependiendo del material impactado. No se crean reglas de daño ni se altera HP, economía, turnos, armas o balances del juego.

### Matriz de reacciones visuales

| Ataque | Portón metálico | Torre de concreto | Cubierta del hangar |
|---|---|---|---|
| **Bala** | Chispas doradas, pequeña abolladura temporal y rebote | Polvo claro, desconchones y marca localizada | Rasguño/ricochete superficial y chispas más frías |
| **Misil** | Estela de aproximación, un destello, onda de presión y esquirlas | Proyección de polvo de cemento y cascotes | Destello, expansión horizontal y fragmentos de chapa |
| **Bombardeo** | Tres detonaciones escalonadas cerca del portón | Tres impactos distribuidos por el eje de la torre | Tres explosiones sucesivas sobre secciones existentes de la cubierta |

Los puntos seleccionados pertenecen a geometría conservada incluso en **daño crítico** (la cubierta seleccionada queda en la sección 12, no en los huecos desaparecidos). Con **destrucción total** se bloquean las pruebas de impacto; no aparecen objetivos reconstruidos.

### Integración del visor

Selecciona **Edificios 3D → Base Aérea V13**. El interruptor *V13 · efectos específicos (comparar V12)* activa la nueva animación de impactos. Justo bajo los botones existentes hay un selector de objetivos de metal, concreto y cubierta. Usa **Impacto de bala**, **Misil** o **Bombardeo**. El botón **Impacto explosivo** mantiene el efecto anterior de V12 para comparación.

La animación V13 está separada de V12, por lo que no dispara dos veces partículas/escombros del mismo impacto. Todas las animaciones son reproducibles y se pueden volver a activar sin instanciar más geometría.

### Diseño técnico y control de recursos

- Dos lotes **MultiMeshInstance3D** para doce chispas y quince fragmentos.
- Tres destellos, tres ondas, tres volúmenes suaves de polvo/humo, tres estelas y tres marcas temporales de contacto, precargados por edificio.
- Sin luces dinámicas, física rígida ni sistemas adicionales de partículas.
- Bala: duración ~0,65 segundos. Misil: ~1,65. Bombardeo: ~2,40 con tres fases escalonadas.
- La vista de carga 8/32/64 continúa usando los LOD anteriores: no precarga la V13 en los edificios distantes, ni en las cuatro bases cercanas de la prueba de estrés sin interacción.
- Mantiene las ocho facciones, cinco estados visuales, portones de 20 piezas, lluvia/nieve, cámaras 360° y comparador de estructura desmontable.

### Control de calidad

`tests/test_airbase_v13_surface_impacts_gpu.gd` verifica en Godot:

- 40 combinaciones de facción × daño y tres niveles.
- Nueve combinaciones (3 ataques × 3 materiales), puntos reales, tiempos y presupuesto de objetos reutilizados.
- Rearme inmediato sin duplicar objetos, 20 piezas del portón y estados de lluvia/nieve.
- Integración de menú, selector y tres botones nuevos.
- **12 capturas nativas**: comparación V12, matriz completa de nueve impactos y bombardeo sobre daño crítico.

Workflow: `.github/workflows/airbase-v13-material-impacts-gpu.yml`. **Estas pruebas son de renderizado de escritorio, no FPS Android.** La publicación del visor y la integración del juego Android se controlan por separado.
