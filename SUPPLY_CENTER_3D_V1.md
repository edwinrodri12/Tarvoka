# TARVOKA — Centro de Suministros V1 · nueva arquitectura 3D

## Decisión de diseño
El **Taller Militar** fue descartado por redundancia con reparaciones móviles. Su PR #435 se cerró sin fusionar y GitHub Pages regresó a la Base Naval V13 aprobada. El siguiente edificio es el **Centro de Suministros**, vinculado al sistema de logística y abastecimiento de vehículos con combustible/municiones, no a reparar blindados.

Se trata de un **prototipo visual** de Godot 4.3, no de un nuevo productor de ingresos, un edificio adicional con una nueva casilla de batalla ni una forma de duplicar abastecimiento ya existente.

## Aspecto arquitectónico V1
- Cimentación completa con dos carriles de camiones y señalización.
- Almacén central con paredes cerradas reales y dos portones enrollables de carga, plataformas y protecciones.
- Dos depósitos de combustible verticales separados del almacén y conectados a conducciones y barreras de seguridad.
- Búnker de municiones separado, con paredes de hormigón reforzado, acceso blindado y cubierta robusta.
- Nivel 1: almacenamiento de combustible y municiones, andenes.
- Nivel 2: sala de control logístico, consola y zona de supervisión.
- Nivel 3: puente grúa de reparto, dos extractores y pasarela de servicio de depósitos.
- Ocho facciones oficiales, con identidad visual aplicada a pocos componentes reconocibles, no al cemento entero.
- Cinco estados: operativo, leve, medio, crítico y destruido. En ruinas no reaparecen portones intactos, tanques completos ni cubiertas.
- Materiales metálicos y hormigón reutilizables entre instancias; sin texturas externas ni luces costosas añadidas.

## Inspección en TARVOKA Estudio 3D
Se añade **Edificios 3D → Centro de Suministros V1**, junto a los tres edificios ya aprobados, con cuatro cámaras:
1. Complejo logístico completo
2. Andenes para camiones
3. Tanques y búnker de municiones
4. Cubiertas y distribución

El inspector tiene selectores de nivel 1–3 y daño 0–4 y permite cambiar entre las ocho facciones. Las cámaras acompañan el giro del modelo.

## Relación con las reglas existentes
El motor actual `scripts/core/Logistics.gd` ya define combustible, municiones y vehículos `logistics` con inventarios y transferencia. El catálogo `scripts/core/UrbanEconomy.gd` tiene seis clases de instalaciones productoras; **esta primera etapa NO modifica ninguna**. El ciclo propuesto anteriormente de depósito → camión → unidad se mantiene como intención para pruebas posteriores; no se declara implementado por existir este modelo.

Antes de integrarlo al campo de batalla habrá que confirmar qué casilla existente representa esta instalación, su compatibilidad con niebla de guerra, captura, turnos, límites de stock, reabastecimiento y desempeño Android. No crear un recurso infinito ni nueva economía tácita.

## Validación
- `scripts/ui/SupplyCenter3DV1.gd`: modelo 3D original en Godot 4.3
- `tests/test_supply_center_v1_gpu.gd`: 40 facciones/estados (8×5), tres niveles, cuatro cámaras, once capturas reales y regresión de edificios anteriores
- `.github/workflows/supply-center-v1-native-gpu.yml`: Godot 4.3 con render nativo OpenGL

No afirmar pruebas aprobadas, APK terminada ni publicación web hasta revisar el resultado correspondiente. **Siguiente prioridad visual:** inspeccionar las capturas y corregir proporciones, muros, tapas de tanques y portones antes de añadir detalles decorativos.
