extends SceneTree

# Parse isolate: prevents the global UnitModels3D import chain from hiding
# the precise root cause when a new native infantry specialist fails to load.
const Specialist = preload("res://scripts/ui/InfantryVariantsV4.gd")
const Infantry = preload("res://scripts/ui/InfantryFamilyV1.gd")

func _initialize() -> void:
    for role in ["infantry_sniper","infantry_aa","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        if not Specialist.supports(role) or not Infantry.supports(role):
            push_error("V4 role missing: "+role)
            quit(1)
            return
    print("PASS INFANTRY V4 ISOLATED PRELOAD: all five roles compile")
    quit(0)
