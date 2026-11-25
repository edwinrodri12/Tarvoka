extends SceneTree

# Playable G05 engineer -> approved infantry_engineer V12.2 in ACTUAL 3D
# battle. Visual-only mapping: combat/state/fog/capture rules stay unchanged.
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const Engineer = preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const ContourV14 = preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const GearV15 = preload("res://scripts/ui/InfantryEngineerGearV15.gd")
const SilhouetteV16 = preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const OuterV17 = preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
var failures: int = 0

func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("ENGINEER V12.2 LIVE BATTLE: " + label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var profile: Dictionary=Arsenal.profile("engineer")
    check(str(profile.get("code",""))=="G05" and
        int(profile.get("hp",-1))==7 and
        int(profile.get("move_points",-1))==2 and
        int(profile.get("attack",-1))==2,
        "engineer retains the real existing G05 gameplay profile")
    # The G11 real battle map guarantees this cell is flat, avoiding a
    # foreground mountain blocking our actual physical V12.2 silhouette.
    var selected: Dictionary=Roles.make_unit(
        "G05-H",0,Vector2i(4,4),"engineer")
    check(str(selected.get("role",""))=="engineer",
        "existing save role never renamed infantry_engineer")
    var state: Dictionary=Context.make_state(0,Biomes.TEMPERATE)
    check(not state.is_empty(),"real game map loads")
    if state.is_empty():
        quit(1)
        return
    state[Identity.STATE_FIELD]={"0":"dominio_turquesa","1":"orden_onix"}
    state["units"]=[selected]
    var before: Dictionary=state.duplicate(true)
    var scene: Node3D=Terrain.build(state,"G05-H",0)
    check(scene!=null,"actual playable 3D terrain builds")
    if scene==null:
        quit(1)
        return
    var view:=SubViewport.new()
    view.size=Vector2i(960,720)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    view.add_child(scene)
    await process_frame
    var soldier: Node3D=scene.find_child(
        "Unidad3D_G05-H",true,false) as Node3D
    var unit_stats: Dictionary=(
        scene.get_meta("render_stats",{}) as Dictionary).get("units",{})
    check(soldier!=null,"playable G05 appears as a real 3D scene model")
    check(int(unit_stats.get("detailed",0))==1,
        "G05 consumes one of eight Android detailed-unit slots")
    if soldier!=null:
        check(Engineer.has_model(soldier) and Engineer.is_visible(soldier)
            and Engineer.has_seals(soldier) and ContourV14.has_model(soldier)
            and GearV15.has_model(soldier)
            and SilhouetteV16.has_model(soldier)
            and OuterV17.has_model(soldier),
            "playable G05 LOD8 uses sealed complete V17 exterior on V16 body")
        var shoulder: MeshInstance3D=soldier.find_child(
            ContourV14.SHOULDER+"_1",true,false) as MeshInstance3D
        check(shoulder!=null and shoulder.mesh is ArrayMesh and
            shoulder.get_parent().name=="BrazoRig_1",
            "LOD8 battle engineer uses actual tapered anatomical shoulder")
        var weapon: MeshInstance3D=soldier.find_child(
            "V8_CarcasaFusilIngeniero",true,false) as MeshInstance3D
        check(weapon!=null and weapon.mesh is ArrayMesh and
            weapon.has_meta(GearV15.ORIGINAL) and
            weapon.has_meta(GearV15.SCULPT),
            "G05 uses physically rounded V15 weapon on real battlefield")
        var torso_core: MeshInstance3D=soldier.find_child(
            SilhouetteV16.CORE,true,false) as MeshInstance3D
        var anatomy_thigh: MeshInstance3D=soldier.find_child(
            SilhouetteV16.THIGH+"_1",true,false) as MeshInstance3D
        check(torso_core!=null and torso_core.mesh is ArrayMesh and
            torso_core.has_meta(SilhouetteV16.OLD) and
            anatomy_thigh!=null and anatomy_thigh.mesh is ArrayMesh and
            anatomy_thigh.get_parent().name=="PiernaRig_1",
            "battle G05 actually renders V16 closed torso and tapered legs")
        var exterior: MeshInstance3D=soldier.find_child(
            OuterV17.FRONT,true,false) as MeshInstance3D
        var knee: MeshInstance3D=soldier.find_child(
            OuterV17.KNEE+"_1",true,false) as MeshInstance3D
        check(exterior!=null and exterior.mesh is ArrayMesh and
            exterior.has_meta(OuterV17.OLD) and
            knee!=null and knee.mesh is ArrayMesh and
            knee.get_parent().name=="PiernaRig_1",
            "playable G05 has truly contoured chest and knee LOD8 meshes")
        check(int(soldier.get_meta("tarvoka_infantry_lod",0))==8,
            "LOD8 lightweight native soldier, not LOD13 hero or fallback disc")
        check(str(soldier.get_meta("tarvoka_engineer_game_role",""))=="engineer"
            and int(soldier.get_meta("tarvoka_engineer_visual_faction",-1))==6
            and int(soldier.get_meta("faction",-1))==0,
            "visual turquoise faction respects the original engine side")
        check(soldier.find_child(Engineer.FRAME,true,false) is MeshInstance3D
            and soldier.find_child(Engineer.MAIN,true,false) is MeshInstance3D
            and soldier.find_child(Engineer.WING_SKIN+"_1",true,false)
            is MeshInstance3D,
            "visible V12.2 octagonal backplate and wing finish exist in battle")
    check(state==before,"3D rendering does not mutate authoritative game state")

    # Two visible sides get their chosen visual faction, even when engine
    # sides remain 0/1. Fog cannot reveal an unseen enemy to the 3D layer.
    var a: Dictionary=Roles.make_unit(
        "G05-B",0,Vector2i(1,1),"engineer")
    var b: Dictionary=Roles.make_unit(
        "G05-R",1,Vector2i(2,2),"engineer")
    var tiles: Dictionary={
        Vector2i(1,1):{"kind":"plain","seen":true,"visible":true},
        Vector2i(2,2):{"kind":"plain","seen":true,"visible":true}
    }
    var two_sides: Dictionary={"units":[a,b]}
    two_sides[Identity.STATE_FIELD]=state[Identity.STATE_FIELD]
    var both: Node3D=Node3D.new()
    var stats: Dictionary=Terrain._make_units(
        both,two_sides,tiles,"G05-B",0)
    check(int(stats.get("visible",0))==2 and
        int(stats.get("detailed",0))==2,
        "both playable engineers visible with approved Android LOD")
    var red: Node3D=both.find_child("Unidad3D_G05-R",false,false) as Node3D
    check(red!=null and Engineer.has_model(red) and
        Engineer.has_seals(red) and ContourV14.has_model(red) and
        GearV15.has_model(red) and SilhouetteV16.has_model(red) and
        OuterV17.has_model(red) and
        int(red.get_meta("tarvoka_engineer_visual_faction",-1))==7 and
        int(red.get_meta("faction",-1))==1,
        "enemy G05 uses onyx visual faction with engine team unchanged")
    both.free()
    var fog: Dictionary=tiles.duplicate(true)
    var fog_tile: Dictionary=fog[Vector2i(2,2)]
    fog_tile["visible"]=false
    fog[Vector2i(2,2)]=fog_tile
    var hidden: Node3D=Node3D.new()
    var fog_stats: Dictionary=Terrain._make_units(
        hidden,two_sides,fog,"G05-B",0)
    check(int(fog_stats.get("hidden_enemies",0))==1 and
        hidden.find_child("Unidad3D_G05-R",false,false)==null,
        "enemy engineer is still hidden by original fog of war")
    hidden.free()

    # Crowd safety: never instantiate more than eight costly soldier LOD8
    # trees. The ninth keeps the preexisting lightweight fallback behavior.
    var crowded: Array=[]
    var crowded_cells: Dictionary={}
    for i in range(9):
        var place:=Vector2i(i,1)
        crowded.append(Roles.make_unit(
            "G05-C%d"%i,0,place,"engineer"))
        crowded_cells[place]={"kind":"plain","seen":true,"visible":true}
    var group:=Node3D.new()
    var limit: Dictionary=Terrain._make_units(group,{"units":crowded},
        crowded_cells,"G05-C0",0)
    check(int(limit.get("detailed",0))==Terrain.MAX_DETAILED_UNITS and
        int(limit.get("visible",0))==9,
        "the original Android budget caps detailed LOD8 troops at eight")
    var ninth: Node3D=group.find_child("Unidad3D_G05-C8",false,false) as Node3D
    check(ninth!=null and not Engineer.has_model(ninth),
        "over-budget soldier uses the old fallback rather than heavy art")
    group.free()

    # Real renderer screenshot, not a simulated illustration.
    if soldier!=null:
        var light:=DirectionalLight3D.new()
        light.rotation_degrees=Vector3(-45,-35,0)
        light.light_energy=2.3
        view.add_child(light)
        var camera:=Camera3D.new()
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=5.0
        var focus: Vector3=soldier.position+Vector3(0,1.1,0)
        view.add_child(camera)
        camera.position=focus+Vector3(3.2,3.2,5.3)
        camera.look_at(focus,Vector3.UP)
        camera.current=true
        await process_frame
        await process_frame
        var picture: Image=view.get_texture().get_image()
        check(picture!=null and not picture.is_empty(),
            "capture actual G05 combat art in native Godot scene")
        if picture!=null and not picture.is_empty():
            DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
                "res://build/qa/engineer-live-battle"))
            check(picture.save_png(
                "res://build/qa/engineer-live-battle/engineer_g05_v12_2_lod8.png")==OK,
                "write actual V12.2 Android-budget gameplay photograph")
    view.queue_free()
    await process_frame
    if failures>0:
        push_error("FAIL ENGINEER V12.2 LIVE BATTLE: %d regressions"%failures)
        quit(1)
    else:
        print("PASS ENGINEER V12.2 LIVE BATTLE: playable G05 mapped to approved model, 8-faction palette, fog-safe, Android capped")
        quit(0)
