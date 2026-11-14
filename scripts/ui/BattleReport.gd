extends RefCounted
class_name TarvokaBattleReport

const Visibility = preload("res://scripts/core/Visibility.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")

# Faction-aware facts for the landscape command dashboard. This is a
# display-only observer: the owning side can see its full army, while enemy
# numbers under fog count VISIBLE contacts only. Never calculate opponent
# total HP or covert unit readiness from the authoritative state.
static func operational_snapshot(state: Dictionary, viewer: int) -> Dictionary:
    var summary := {
        "allies":0, "move_ready":0, "attack_ready":0,
        "hp":0, "contacts":0, "fog":Visibility.enabled(state)
    }
    if viewer not in [0,1]:
        return summary
    var troops = state.get("units",[])
    if not troops is Array:
        return summary
    var fog: bool = bool(summary["fog"])
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if fog else {}
    for unit in troops:
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        var side: int = int(unit.get("faction",-1))
        if side == viewer:
            summary["allies"] += 1
            summary["hp"] += int(unit.get("hp",0))
            if not bool(unit.get("acted",true)):
                summary["attack_ready"] += 1
                if not bool(unit.get("moved",false)):
                    summary["move_ready"] += 1
        elif side == 1 - viewer:
            if not fog or visible.has(unit.get("pos",Vector2i(-1,-1))):
                summary["contacts"] += 1
    return summary

# Presentation-only statistics. This never changes battle state or save data.
# During fog, do not disclose unseen enemies or their total surviving HP.
static func field_summary(state: Dictionary) -> String:
    var allies := 0
    var can_move := 0
    var can_attack := 0
    var ally_hp := 0
    var enemies := 0
    var contacts := 0
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, 0) if fog else {}
    for unit in state.get("units", []):
        if not (unit is Dictionary) or int(unit.get("hp", 0)) <= 0:
            continue
        if int(unit.get("faction", -1)) == 0:
            allies += 1
            ally_hp += int(unit["hp"])
            # Relocation no longer spends the attack. Count these
            # capabilities separately instead of labeling moved units spent.
            if not bool(unit.get("acted", true)):
                can_attack += 1
                if not bool(unit.get("moved", false)):
                    can_move += 1
        elif int(unit.get("faction", -1)) == 1:
            enemies += 1
            if not fog or visible.has(unit.get("pos", Vector2i(-1, -1))):
                contacts += 1
    var friendly := "AZUL: unidades %d | mover %d | atacar %d | HP %d" % [allies, can_move, can_attack, ally_hp]
    if fog:
        return friendly + "\nContactos enemigos visibles: %d (otros pueden estar ocultos)" % contacts
    return friendly + "\nROJO: %d unidades activas" % enemies

static func terminal_summary(state: Dictionary) -> String:
    var alive := [0, 0]
    var losses := [0, 0]
    var hp := [0, 0]
    for unit in state.get("units", []):
        if not (unit is Dictionary):
            continue
        var faction := int(unit.get("faction", -1))
        if faction not in [0, 1]:
            continue
        if int(unit.get("hp", 0)) > 0:
            alive[faction] += 1
            hp[faction] += int(unit["hp"])
        else:
            losses[faction] += 1
    var report := "Aliadas: %d activas, %d bajas. Enemigas: %d activas, %d bajas." % [
        alive[0], losses[0], alive[1], losses[1]
    ]
    report += "\nHP restante: aliadas %d | enemigas %d." % [hp[0], hp[1]]
    if state.has("control"):
        var objective: Dictionary = state["control"]
        report += "\nSenal final: Azul %d | Rojo %d (meta %d)." % [
            int(objective["scores"][0]), int(objective["scores"][1]), int(objective["target"])
        ]
    return report

static func pending_preview(state: Dictionary, pending: Dictionary) -> String:
    if pending.is_empty():
        return ""
    var unit_id := str(pending.get("unit_id", ""))
    var cell = pending.get("cell", null)
    if unit_id.is_empty() or not (cell is Vector2i):
        return "Orden invalida. Cancela la seleccion."
    var hints: Dictionary = TacticalHints.for_unit(state, unit_id)
    if str(pending.get("kind", "")) == "attack":
        if not hints["attacks"].has(cell):
            return "El objetivo ya no esta disponible. Cancela la seleccion."
        var target: Dictionary = hints["attacks"][cell]
        if str(target.get("id", "")) != str(pending.get("target_id", "")):
            return "El objetivo cambio. Cancela la seleccion."
        var bonus: int = int(target.get("terrain_attack_bonus",0))
        var cover: int = int(target.get("terrain_defense_cover",0))
        var position_note := " | terreno ATQ %+d, cobertura +%d%s" % [bonus, cover, ", flanqueo" if bool(target.get("flanked",false)) else ""]
        return "ATAQUE PREPARADO: %s contra %s | dano previsto %d HP al enemigo | respuesta posible hasta -%d HP propios%s.\nConfirma o toca el objetivo otra vez." % [
            unit_id, str(target["id"]), int(target["damage"]), int(target.get("counter_damage",0)), position_note
        ]
    if str(pending.get("kind", "")) == "move" and hints["moves"].has(cell):
        return "MOVIMIENTO PREPARADO: %s a (%d,%d) | costo %d.\nConfirma o toca el destino otra vez." % [
            unit_id, cell.x + 1, cell.y + 1, int(hints["moves"][cell])
        ]
    return "El destino ya no esta disponible. Cancela la seleccion."
