extends SceneTree

# Main-game G13 integration: native V69 meshes, playable ID and visual-only actions.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const G13 = preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V69 = preload("res://scripts/ui/G13MuzzleMountFinishV69.gd")
const Actions = preload("res://scripts/ui/G13BattleActionsV70.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
var failures: int = 0

func check(ok: bool,label: String) -> void:
    if not ok:
        failures += 1
        push_error("G13 V70 main battle: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(Models.supports("mobile_aa"),"playable G13 has native renderer")
    var profile: Dictionary = Arsenal.profile("mobile_aa")
    check(str(profile.get("code",""))=="G13" and
        int(profile.get("cost",-1))==500 and
        profile.get("target_domains",[])==["air"],
        "G13 costs and anti-air targeting unchanged")
    for art_faction in range(8):
        var candidate: Node3D = Models.build("mobile_aa",art_faction,true,8)
        check(candidate!=null,"G13 model faction %d" % art_faction)
        if candidate!=null:
            check(G13.has_model(candidate) and bool(candidate.get_meta(V69.FLAG,false)),
                "native approved V69 VFX/mesh is used")
            candidate.free()
    var state: Dictionary = Context.make_state(0,Biomes.TEMPERATE)
    check(not state.is_empty(),"native test battle loads")
    if state.is_empty():
        quit(1)
        return
    state[Identity.STATE_FIELD]={"0":"dominio_turquesa","1":"orden_onix"}
    var unit: Dictionary = Roles.make_unit(
        "G13-H",0,Vector2i(4,6),"mobile_aa")
    state["units"].append(unit)
    check(str(unit.get("role",""))=="mobile_aa","save format unchanged")
    var original: Dictionary = state.duplicate(true)
    var scene: Node3D = Terrain.build(state,"G13-H",0)
    check(scene!=null,"native battle terrain constructed")
    if scene==null:
        quit(1)
        return
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,680)
    viewport.own_world_3d=true
    root.add_child(viewport)
    viewport.add_child(scene)
    await process_frame
    var model:=scene.find_child("Unidad3D_G13-H",false,false) as Node3D
    var actions:=scene.find_child("G13V70_AccionesBatalla",false,false) as Actions
    check(model!=null and actions!=null,"G13 is visible in actual 3D battle")
    var units: Dictionary=(scene.get_meta("render_stats",{}) as Dictionary).get("units",{})
    check(int(units.get("g13_lod8",0))==1 and
        int(units.get("g13_visible",0))==1,"Android LOD8 active")
    if model!=null:
        check(G13.has_model(model) and bool(model.get_meta(V69.FLAG,false)),
            "game uses true V69 ported twin muzzle sculpt")
        check(int(model.get_meta("tarvoka_g13_visual_faction",-1))==6,
            "actual selected turquoise faction used")
        check(int(model.get_meta("faction",-1))==0,
            "art identity never replaces engine team")
    if model!=null and actions!=null:
        var destination: Vector3=model.position
        check(not actions.play("missing","attack",destination),"cannot animate invisible unit")
        check(not actions.play("G13-H","invalid",destination),"invalid action rejected")
        check(actions.play("G13-H","move",
            destination+Vector3(0,0,-Terrain.CELL),Vector2i(0,1)),
            "approved G13 model moves")
        actions.set_process(false)
        actions.advance(Actions.MOVE_TIME*0.48)
        check(model.position.distance_to(destination)>0.1,
            "G13 interpolates between current visible cells")
        actions.advance(Actions.MOVE_TIME*0.52)
        check(not actions.active() and model.position.is_equal_approx(destination),
            "G13 returns to authoritative location")
        check(actions.play("G13-H","attack",destination,Vector2i(1,0)),
            "G13 twin cannon air attack animation runs")
        actions.set_process(false)
        actions.advance(Actions.ATTACK_TIME*0.30)
        check(str(model.get_meta("tarvoka_g13_v1_pose",""))=="attack_air",
            "G13 plays original air-attack visual pose")
        actions.advance(Actions.ATTACK_TIME*0.71)
        check(not actions.active() and
            str(model.get_meta("tarvoka_g13_v1_pose",""))=="idle",
            "G13 resets pose after firing")
    check(state==original,"no change to rules, ammo, turns or game state")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G13 V70: %d regressions" % failures)
        quit(1)
        return
    print("PASS G13 V70: approved V69 native 3D integrated into main game")
    quit(0)
