extends "res://scripts/ui/HeadquartersImpactV21.gd"
class_name TarvokaAirbaseImpactV3

# Use the existing battle-tested short bullet and heavier explosive
# animation rigs, with Airbase-specific physical coordinates.
# Does not change health, economy, turn logic, fog or unit state.
const AIRBASE_NAME := "ImpactosBalasExplosivosBaseAereaV3"
const AIRBASE_BULLET := "bullet"
const AIRBASE_EXPLOSIVE := "explosive"
const GATE_IMPACT := Vector3(-2.42,1.63,-4.12)
const ROOF_IMPACT := Vector3(-3.09,3.15,-1.80)

func _ready() -> void:
    super._ready()
    name = AIRBASE_NAME
    set_meta("tarvoka_airbase_v3_visual_only",true)

func trigger_airbase(kind: String) -> bool:
    if kind == AIRBASE_BULLET:
        return trigger(kind,GATE_IMPACT)
    if kind == AIRBASE_EXPLOSIVE:
        return trigger(kind,ROOF_IMPACT)
    return false
