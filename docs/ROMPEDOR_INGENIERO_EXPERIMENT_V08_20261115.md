# TARVOKA — Especialización experimental: Rompedor e Ingeniero

**15 de noviembre de 2026 · PR #394 en borrador · Solo prototipo y pruebas · Sin modificación de estadísticas oficiales**

## Motivo

La auditoría anterior (Godot 4.3, https://github.com/edwinrodri12/Tarvoka/actions/runs/43778731623) encontró 432 ataques legales estáticos entre las 32 clases, 116 bajas al primer golpe, y demostró que +1 ATQ o +1 DEF altera el daño en cientos de pares. Dos clases muestran funciones incompletas en el catálogo vigente:

- Rompedor (8 HP, ATQ 4, DEF 0, 3 mov., 300 créditos) obtiene **+4 ATQ contra Baluarte**, pero no tiene bonificación definida contra vehículos modernos como el tanque.
- Ingeniero (7 HP, ATQ 2, DEF 0, 2 mov., 250 créditos) tiene una función de reparación descrita como pendiente, por lo que su especialización es inferior a la del Asaltante si se juzga solamente por combate y captura.

Se investigan sus capacidades, **no se declara que el balance definitivo haya sido aprobado**.

## Rompedor: contrajuego específico contra vehículos

Archivo: `scripts/experiments/RoleSpecializationV08.gd`.

Se mantiene intacta la bonificación oficial contra Baluarte. Se comparan **bonificaciones adicionales 0, +2 y +3 ATQ** solo cuando el Rompedor ataca vehículos terrestres modernos de una lista explícita: APC, IFV, tanque, SPG, MLRS, antiaéreo móvil, SAM, guerra electrónica y logística.

El prototipo usa la acción real `BattleSession.attack`, cambiando transitoriamente el ataque en una copia del estado **exclusivamente durante el ataque legal** y restaurándolo antes de devolver el estado. No se crea un estado mejorado persistente, no hay buff contra infantería ni contra naves/aeronaves, y el disparo consume la munición y la acción habituales. El rival sigue pudiendo contraatacar según las reglas normales.

| Objetivo en terreno llano | Vida | Defensa | Daño actual del Rompedor | Candidato +2 | Candidato +3 |
|---|---:|---:|---:|---:|---:|
| Tanque principal | 14 | 2 | 2 | 4 | 5 |
| Baluarte (no nuevo bono) | 12 | 2 | 6 (incluye el +4 oficial) | 6 | 6 |

Estas cifras se deducen de la fórmula vigente, y el caso de tanque se verifica además en las pruebas de acción. Un Rompedor sigue vulnerable a un ataque iniciado por un tanque (8 puntos de daño en llano sobre 8 HP): la especialización necesita oportunidad táctica y terreno, no asegura vencer un duelo frontal.

### Riesgos

Un +3 contra blindaje ligero sin defensa puede ser demasiado fuerte para un soldado de 300 créditos. La matriz secundaria compara todos los vehículos compatibles bajo llanura/bosque/montaña/ciudad y registra ataques necesarios para vencer sin modelar explícitamente movimientos de varias fases. **No elegir +2/+3 solo por su efecto contra tanque**.

## Ingeniero: reparación de campo de vehículos

La acción `field_repair(state, engineer_id, patient_id, pack)` es una implementación **optativa** y no aparece en el juego principal. Condiciones:
- Solamente Ingeniero vivo y disponible, durante el turno de su facción.
- Solo vehículos terrestres compatibles aliados vivos, **adyacentes** en cardinales (una casilla); no se repara a enemigos, infantería, aeronaves, buques ni unidades destruidas.
- El jugador paga los créditos. Reparación ligera = **+2 HP por 60 créditos**; campo = **+3 HP por 100 créditos**. Nunca sobrepasa los HP máximos del perfil.
- El Ingeniero gasta su acción ofensiva (no puede atacar/reparar de nuevo ese turno). Como la regla actual permite mover y después atacar, también puede moverse y luego reparar. Esto se medirá como opción táctica, no valor gratuito.
- El estado es una copia, la tesorería del rival no cambia, no hay campos nuevos en la partida ni efectos en el guardado v1. Las pruebas verifican ida/vuelta por SaveCodec.
- Reparación de **edificios** se tratará separadamente cuando existan HP de estructuras y reglas de construcción en el estado autoritativo. No crear atributos ficticios para simular que ya funciona.

### Relación inicial con economía

| Concepto | Costo unitario | Vida de referencia | Costo nominal por HP |
|---|---:|---:|---:|
| Tanque nuevo | 750 | 14 | 53,57 |
| APC nuevo | 300 | 11 | 27,27 |
| Reparación ligera | 60 | Hasta 2 | 30,00 si cura 2 |
| Reparación de campo | 100 | Hasta 3 | 33,33 si cura 3 |

**Atención:** la reparación exige haber comprado un Ingeniero (250 créditos), mantenerlo vivo y sacrificar su turno. Tampoco recupera munición ni combustible y no puede revivir unidades destruidas. Reparar un APC puede ser menos eficiente por HP que comprar uno nuevo, mientras que reparar un tanque caro podría ser interesante. La prueba completa deberá contabilizar vidas salvadas, posiciones, coste fijo del Ingeniero, suministros y tiempo.

## Evidencia verificable

Workflow de Godot 4.3: `.github/workflows/role-specialization-v08.yml`.

- `tests/test_role_specialization_v08.gd` verifica ataques autoritativos, consumo de munición, retorno del atributo de ataque original, ambos bandos, coste y acción de reparación, casos rechazados y guardado.
- `tests/test_specialization_sensitivity_v09.gd` prueba el daño entre el Rompedor y las 32 clases en cuatro coberturas y registra los contrajuegos de los nueve vehículos, además del costo de reparación por HP.

El criterio de éxito técnico es que ambas pruebas muestren PASS sin excepciones. **Solo después** evaluaremos estadísticas de victorias y escenarios de uso. Ninguna de las pruebas confirma todavía equilibrio en partidas con edificios evolucionados, poderes de facciones o ocho jugadores.

## Recomendación y siguiente etapa

No modificar el precio del Rompedor ni del Ingeniero y no añadir la habilidad al juego principal hasta validar el costo-beneficio y evitar dominios no deseados. Tras la verificación técnica, comparar +2 vs +3 en escenarios con tanque, IFV, MLRS y artillería, y evaluar varias reparaciones a un tanque y un APC frente a producir una unidad nueva. Después conectar estas habilidades con compras de tecnología de nivel II–III por edificio, evitando bonificaciones acumuladas arbitrarias.
