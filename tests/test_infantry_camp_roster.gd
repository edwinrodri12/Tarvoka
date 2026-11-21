extends SceneTree

# The precise user-approved military infantry roster, not every archived
# artist proof in UnitModels3D. All exclusive camp links are immutable here.
const Roster=preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/InfantryVariantsV4.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var failures:int=0

func check(ok: bool, description:String)->void:
    if not ok:
        failures+=1
        push_error("INFANTRY CORE SIX: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    const EXPECTED={
        "infantry_sniper":"reconocimiento",
        "infantry_engineer":"defensivo",
        "infantry_logistic":"suministros",
        "infantry_medic":"medico"
    }
    check(Roster.CORE_ROLES.size()==6,"exact six, never eleven")
    check(Roster.CAMP_FOR_ROLE.size()==4,"exact four camp associations")
    check(Roster.is_core("line") and Roster.is_core("infantry_commando"),
        "one basic Guardia plus one special Comando")
    for role in ["infantry_urban","infantry_defense","scout",
            "infantry_antitank"]:
        check(not Roster.is_core(role),"archived old draft is not an extra core role "+role)
    for role in EXPECTED:
        var camp:String=str(EXPECTED[role])
        check(Roster.is_core(role) and Roster.can_build(role,camp),
            "exclusive specialist builder: "+role+" => "+camp)
        for other in EXPECTED.values():
            if str(other)!=camp:
                check(not Roster.can_build(role,str(other)),
                    "cannot build another specialist's camp")
    for role in Roster.CORE_ROLES:
        var model:Node3D=Models.build(role,0,true,13)
        check(model!=null and bool(model.get_meta(
            "tarvoka_infantry_sculpt_finish_v2",false)),
            "real existing native sculpt "+role)
        if model!=null:
            if Finish.supports(role):
                check(Finish.has_model(model,role) and model.find_child(
                    str(Finish.MARKER[role]),true,false)!=null,
                    "unique physical equipment "+role)
            if role not in ["line"]:
                check(not Arsenal.valid(role),
                    "non-approved tactical role must not activate "+role)
            model.free()
    if failures>0:
        quit(1)
    else:
        print("PASS INFANTRY CORE SIX: Guardia, Comando and 4 exclusive camp specialists; legacy previews preserved")
        quit(0)
