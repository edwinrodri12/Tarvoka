extends SceneTree

# 3D QA: physically smoothed source meshes, no mesh/node duplication,
# eight paint factions in LOD8/13 and authentic Godot V14/V15 comparison.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const V14=preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const V15=preload("res://scripts/ui/InfantryEngineerGearV15.gd")
const V17=preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const OUT: String="res://build/qa/engineer-v15"
var issues: int=0
var photos: int=0

func check(ok: bool, label: String) -> void:
    if not ok:
        issues+=1
        push_error("ENGINEER V15: "+label)

func mesh_count(n: Node) -> int:
    var c: int=1 if n is MeshInstance3D else 0
    for child in n.get_children():
        c+=mesh_count(child)
    return c

func _image(view: SubViewport, label: String) -> Image:
    await process_frame
    await process_frame
    var im: Image=view.get_texture().get_image()
    check(im!=null and not im.is_empty(),"real 3D capture "+label)
    if im!=null and not im.is_empty():
        check(im.save_png(OUT+"/"+label+".png")==OK,"saved "+label)
        photos+=1
    return im

func _changes(a: Image,b: Image) -> int:
    if a==null or b==null or a.is_empty() or b.is_empty() or (
            a.get_size()!=b.get_size()):
        return 0
    var result: int=0
    for y in range(85,a.get_height()-85,3):
        for x in range(90,a.get_width()-90,3):
            var p: Color=a.get_pixel(x,y)
            var q: Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.16:
                result+=1
    return result

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"QA folder")
    for faction in range(8):
        for lod in [8,13]:
            var soldier: Node3D=Models.build("infantry_engineer",
                faction,true,lod)
            check(soldier!=null and V15.has_model(soldier) and
                V14.has_model(soldier) and V12.has_seals(soldier),
                "the same fully closed engineer is built at F%d L%d"%[faction,lod])
            if soldier==null or not V15.has_model(soldier):
                if soldier!=null:
                    soldier.free()
                continue
            check(V17.show_finish(soldier,false),"isolate historical V15 before comparison")
            var count: int=mesh_count(soldier)
            for name in ["V8_CarcasaFusilIngeniero",
                    "V8_GuardamanosPerforado",
                    "V8_RielOpticoSuperior",
                    "V5_ArnesDiagonalIngeniero",
                    "V6_BancadaFijaBisagra"]:
                var part: MeshInstance3D=soldier.find_child(
                    name,true,false) as MeshInstance3D
                check(part!=null and part.mesh is ArrayMesh and
                    part.has_meta(V15.ORIGINAL) and
                    part.has_meta(V15.SCULPT) and
                    part.material_override is StandardMaterial3D and
                    (part.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "physical opaque closed-source gear "+name)
            for side in [-1,1]:
                for name in ["V6_CantoGoma_%d"%side,
                        "V2_CinchaPortaequipo_%d"%side]:
                    var part: MeshInstance3D=soldier.find_child(
                        name,true,false) as MeshInstance3D
                    check(part!=null and part.mesh is ArrayMesh and
                        part.has_meta(V15.ORIGINAL),
                        "physical rounded moving rig strap "+name)
            var rifle: MeshInstance3D=soldier.find_child(
                "V8_CarcasaFusilIngeniero",true,false) as MeshInstance3D
            var refined: Mesh=rifle.mesh
            check(V15.show_finish(soldier,false) and
                rifle.mesh!=refined,
                "restore real V14 weapon sculpt on the same 3D rig")
            check(V15.show_finish(soldier,true) and
                rifle.mesh==refined and mesh_count(soldier)==count,
                "restore V15 without adding Android draw calls")
            check(V6.pose(soldier,"inspect",1.0) and
                V6.reset(soldier),"shield articulation unaffected")
            soldier.free()
    for other in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var unrelated: Node3D=Models.build(other,0,true,13)
        check(unrelated!=null and not V15.has_model(unrelated),
            "other soldier archetype left unchanged: "+other)
        if unrelated!=null:
            unrelated.free()

    var view:=SubViewport.new()
    view.size=Vector2i(860,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#192934")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#e1eff6")
    environment.ambient_light_energy=0.82
    world.environment=environment
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-34,0)
    sun.light_energy=2.5
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.15
    camera.current=true
    view.add_child(camera)
    var hero: Node3D=Models.build("infantry_engineer",6,true,13)
    check(hero!=null and V15.has_model(hero),"hero model in Godot")
    if hero!=null:
        view.add_child(hero)
        check(V17.show_finish(hero,false),"historical V15 render excludes V17")
        var views: Dictionary={
            "front":Vector3(0,2.2,-4.7),
            "left":Vector3(-4.1,2.25,-2.6),
            "right":Vector3(4.1,2.25,-2.6),
            "rear":Vector3(0,2.25,4.8),
            "top":Vector3(2.6,4.9,-3.3)}
        var changed: int=0
        for label in ["front","left","right","rear","top"]:
            camera.position=views[label]
            camera.look_at(Vector3(0,1.40,0),Vector3.UP)
            V15.show_finish(hero,false)
            var old: Image=await _image(view,"v14_"+label)
            V15.show_finish(hero,true)
            var updated: Image=await _image(view,"v15_"+label)
            changed+=_changes(old,updated)
        print("V15 changed native render pixels: ",changed)
        check(changed>20,"real PBR edges improve from identical 3D cameras")
        hero.queue_free()
        await process_frame
    check(photos==10,"ten camera-aligned native before/after views")
    if issues>0:
        push_error("FAIL ENGINEER V15: %d issues"%issues)
        quit(1)
    else:
        print("PASS ENGINEER V15: 8 factions x 2 LOD, rounded weapon and harness, unchanged rigs, 10 Godot images")
        quit(0)
