extends RefCounted
class_name TarvokaCombatPreviewData

const Hints = preload("res://scripts/core/TacticalHints.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Domains = preload("res://scripts/core/Domains.gd")

# Public, pure, confirmation-time forecast. All numbers come from
# TacticalHints.for_unit: the same legal forecast used to confirm attacks.
# Enemy ammunition and 'reacted' status are intentionally never read.
static func estimate(state: Dictionary, pending: Dictionary) -> Dictionary:
    var none: Dictionary = {"valid":false,"reason":"Sin ataque preparado"}
    if str(pending.get("kind","")) != "attack":
        return none
    var attacker_id: String = str(pending.get("unit_id",""))
    var defender_id: String = str(pending.get("target_id",""))
    var cell = pending.get("cell",null)
    if attacker_id.is_empty() or defender_id.is_empty() or not (cell is Vector2i):
        return none
    var faction: int = int(state.get("faction",-1))
    if faction not in [0,1] or not state.get("units") is Array:
        return none
    var hints: Dictionary = Hints.for_unit(state,attacker_id)
    var entry: Dictionary = hints.get("attacks",{}).get(cell,{})
    if entry.is_empty() or str(entry.get("id","")) != defender_id:
        return {"valid":false,"reason":"Objetivo fuera de alcance. Cancela la orden."}
    var own: Dictionary = {}
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == attacker_id and int(unit.get("faction",-1)) == faction:
            own = unit
            break
    var observed: Dictionary = Visibility.observed_state(state,faction)
    var opponent: Dictionary = {}
    for enemy in observed.get("units",[]):
        if enemy is Dictionary and str(enemy.get("id","")) == defender_id and int(enemy.get("faction",-1)) != faction and enemy.get("pos",null) == cell:
            opponent = enemy
            break
    if own.is_empty() or opponent.is_empty():
        return {"valid":false,"reason":"El objetivo no está visible."}
    var dealt: int = maxi(0,int(entry.get("damage",0)))
    var possible_counter: int = maxi(0,int(entry.get("counter_damage",0)))
    var own_hp: int = maxi(0,int(own.get("hp",0)))
    var enemy_hp: int = maxi(0,int(opponent.get("hp",0)))
    var own_role: String = str(own.get("role",""))
    var enemy_role: String = str(opponent.get("role",""))
    var attack_bonus: int = int(entry.get("terrain_attack_bonus",0))
    var defender_cover: int = int(entry.get("terrain_defense_cover",0))
    var flank: bool = bool(entry.get("flanked",false))
    var notes: Array[String] = []
    if Domains.domain(own) == Domains.GROUND and Domains.domain(opponent) == Domains.GROUND:
        var own_ground: String = Terrain.tile_at(state["terrain"],own["pos"])
        var enemy_ground: String = Terrain.tile_at(state["terrain"],opponent["pos"])
        var height_advantage: int = Terrain.height_of(own_ground) - Terrain.height_of(enemy_ground)
        if height_advantage > 0:
            notes.append("Ataque desde altura: +1")
        elif height_advantage < 0:
            notes.append("Ataque cuesta arriba: -1")
    if attack_bonus != 0:
        notes.append("Posición: ataque %+d" % attack_bonus)
    if defender_cover > 0:
        notes.append("Cobertura enemiga: +%d" % defender_cover)
    if flank:
        notes.append("Flanqueo activo")
    if notes.is_empty():
        notes.append("Sin modificadores de terreno")
    if own_role in BattleActions.ONE_WAY_ROLES:
        notes.append("Munición de un solo uso: el atacante se consume al impactar")
    return {
        "valid":true,
        "attacker":Roles.label(own_role),"defender":Roles.label(enemy_role),
        "attacker_id":attacker_id,"defender_id":defender_id,
        "attacker_hp":own_hp,"defender_hp":enemy_hp,
        "enemy_loss":mini(enemy_hp,dealt),
        "counter_max":mini(own_hp,possible_counter),
        "attacker_after_min":maxi(0,own_hp-possible_counter),
        "defender_after":maxi(0,enemy_hp-dealt),
        "lethal":bool(entry.get("defeated",false)),
        "explanation":"  ·  ".join(notes),
        "counter_note":"Respuesta enemiga MAXIMA estimada. La municion y reaccion rival no son visibles."
    }
