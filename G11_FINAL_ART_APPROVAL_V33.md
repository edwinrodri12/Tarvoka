# TARVOKA — G11 Lanzador, aprobación final del diseño artístico 3D

**Estado:** DISEÑO 3D APROBADO — V33.  
**Aprobación:** 16 de noviembre de 2026, después de revisar la corrección trasera V30, efectos V31 y tren de rodaje V32.  
**Alcance:** aprobación artística y funcional del modelo visual; **no es certificación comercial de rendimiento Android**.

## Versión definitiva protegida

La representación del G11 queda estabilizada en los archivos de Godot 4.3, manteniendo:

- **Escultura hero:** doce bocas en disposición 4×3, casco octogonal cerrado, ocho facciones, doce ruedas y dos orugas de 46 zapatas móviles cada una (92 zapatas en total).
- **Corrección de geometría:** se retiraron físicamente las dos placas cuadradas redundantes `G11_ProteccionInferior` y `G11_RampaPosteriorCerrada`, sin comprometer el casco octogonal ni duplicar paneles.
- **Animaciones:** movimiento, giro diferencial de orugas, suspensión en desniveles, orientación y elevación de lanzador, salva de 12 cohetes esculpidos, humo progresivo, retroceso reversible y estados de daño/reparación.
- **Batalla Android:** LOD8 sin ruedas ocultas y LOD10 con 12 ruedas agrupadas; doce tubos agrupados, identidad de facción y efectos temporales agrupados.
- **Integridad táctica:** todos los efectos son estrictamente visuales. El motor existente conserva la autoridad exclusiva de vida, daños, combustible, munición, rango, visión, economía, IA y guardados.

## Política de cierre

No ampliar geometría, efectos de partículas ni texturas por preferencias cosméticas. Solo reabrir el G11 ante un defecto **reproducible y documentado**, una regresión de accesibilidad o un problema significativo de rendimiento medido. Corregir la pieza o el sistema afectado sin modificar diseños aprobados.

**Validación disponible:** suites de G11 V29–V33, estudio web nativo Godot 4.3 y laboratorio Android de 8/32/64 modelos LOD8/LOD10. El laboratorio V33 corrigió un defecto anterior en el que se medía accidentalmente la escultura hero en lugar del modelo táctico.

**Pendiente explícito sin bloquear la aprobación artística:** pruebas de instalación y rendimiento con teléfono Android físico (FPS medio/p95, memoria, temperatura y sesiones prolongadas), idealmente en batalla mixta y no solo con lanzadores. No declarar FPS ni comportamiento térmico de dispositivo sin esos datos.

## Siguiente unidad de diseño

**G13 — Antiaéreo móvil.** Elegido entre las familias funcionales distintas de `UNIT_ROSTER_AUDIT_V02.md`: defensa antiaérea con prototipo de cañones de corto alcance en Nivel I y opción tecnológica SAM posterior en esta **misma familia** (el G14 histórico se absorbe en G13). No implica que el combate antiaéreo ni las mejoras estén implementados.

El desarrollo visual inicial del G13 se lleva en archivos separados del G11 y no cambia las cinco unidades tácticas actualmente implementadas ni sus estadísticas.

Referencia histórica del modelado G11: `G11_LANZADOR_3D_V1.md`.
