extends SceneTree

# Real Godot native QA for V13: a rounded face must be physically curved,
# watertight, outward-facing and visibly different from its V12.3 version.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const Smooth=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const OUT: String="res://build/qa/engineer-v13"
var failures: int=0
var pictures: int=0

func check(ok: bool, why: String) -> void:
    if not ok:
        failures+=1
        push_error("ENGINEER V13: "+why)

func _key(p: Vector3) -> String:
    return "%d:%d:%d"%[
        roundi(p.x*100000.0),roundi(p.y*100000.0),roundi(p.z*100000.0)]

func _outward_watertight(shape: Mesh) -> bool:
    if not shape is ArrayMesh or shape.get_surface_count()<1:
        return false
    for i in range(shape.get_surface_count()):
        var arrays: Array=shape.surface_get_arrays(i)
        var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
        var raw: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            raw if raw is PackedInt32Array else PackedInt32Array())
        var n: int=indices.size() if indices.size()>0 else vertices.size()
        if n<30 or n%3!=0 or normals.size()!=vertices.size():
            return false
        var volume: float=0.0
        var edges: Dictionary={}
        for j in range(0,n,3):
            var ia: int=indices[j] if indices.size()>0 else j
            var ib: int=indices[j+1] if indices.size()>0 else j+1
            var ic: int=indices[j+2] if indices.size()>0 else j+2
            var a: Vector3=vertices[ia]
            var b: Vector3=vertices[ib]
            var c: Vector3=vertices[ic]
            volume+=a.dot(b.cross(c))/6.0
            var v: Array[String]=[_key(a),_key(b),_key(c)]
            if v[0]==v[1] or v[1]==v[2] or v[2]==v[0]:
                return false
            for k in range(3):
                var edge: Array[String]=[v[k],v[(k+1)%3]]
                edge.sort()
                var id: String=edge[0]+"|"+edge[1]
                edges[id]=int(edges.get(id,0))+1
        if volume<=0.00000001:
            return false
        for count in edges.values():
            if int(count)!=2:
                return false
    return true

func _capture(view: SubViewport, name: String) -> Image:
    await process_frame
    await process_frame
    var img: Image=view.get_texture().get_image()
    check(img!=null and not img.is_empty(),
        "native photo "+name)
    if img!=null and not img.is_empty():
        check(img.save_png(OUT+"/"+name+".png")==OK,
            "saved PNG "+name)
        pictures+=1
    return img

func _change_pixels(before: Image, after: Image) -> int:
    if before==null or after==null or before.is_empty() or (
            after.is_empty() or before.get_size()!=after.get_size()):
        return 0
    var count: int=0
    for y in range(90,before.get_height()-90,3):
        for x in range(110,before.get_width()-110,3):
            var a: Color=before.get_pixel(x,y)
            var b: Color=after.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.14:
                count+=1
    return count

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "QA directory available")
    for faction in range(8):
        for lod in [8,13]:
            var soldier: Node3D=Models.build(
                "infantry_engineer",faction,true,lod)
            check(soldier!=null,"F%d L%d engineer exists"%[faction,lod])
            if soldier==null:
                continue
            check(Smooth.has_model(soldier) and V12.has_seals(soldier)
                and V12.is_visible(soldier),
                "V13 built ON V12.3 with no missing anatomy F%d L%d"%[faction,lod])
            var main: MeshInstance3D=soldier.find_child(
                V12.MAIN,true,false) as MeshInstance3D
            var helm: MeshInstance3D=soldier.find_child(
                "V9_CascoContinuoBiselado",true,false) as MeshInstance3D
            var pouch: MeshInstance3D=soldier.find_child(
                V12.CASE+"_1",true,false) as MeshInstance3D
            for part in [main,helm,pouch]:
                check(part!=null and _outward_watertight(part.mesh),
                    "smooth sealed outward topology F%d L%d"%[faction,lod])
                if part!=null:
                    var normals: PackedVector3Array=(
                        part.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL])
                    check(normals.size()>0 and
                        part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>200,
                        "nontrivial rounded surface, not 8-sided cover")
                    var material: StandardMaterial3D=(
                        part.material_override as StandardMaterial3D)
                    check(material!=null and
                        material.transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "approved opaque material reused unchanged")
            if lod==13:
                var shield_parent: Node3D=soldier.find_child(
                    V6.RIG,true,false) as Node3D
                for suffix in ["Superior","Ranura_-1","Ranura_1",
                        "UnionCentral"]:
                    var trim: MeshInstance3D=soldier.find_child(
                        Smooth.TRIM_PREFIX+suffix,true,false) as MeshInstance3D
                    check(trim!=null and trim.visible and
                        trim.get_parent()==shield_parent and
                        _outward_watertight(trim.mesh),
                        "V13 physical closed dark relief on hero shield")
            if main!=null:
                var round_mesh: Mesh=main.mesh
                check(Smooth.show_smoothing(soldier,false),
                    "V12.3 actual previous polygon mesh restored")
                check(main.mesh!=round_mesh,
                    "same physical shield mesh changes, not a UI label")
                if lod==13:
                    var old_trim: MeshInstance3D=soldier.find_child(
                        Smooth.TRIM_PREFIX+"Superior",true,false) as MeshInstance3D
                    check(old_trim!=null and not old_trim.visible,
                        "V12.3 comparison hides V13 hero-only detailed bezels")
                check(Smooth.show_smoothing(soldier,true) and
                    main.mesh==round_mesh and
                    bool(soldier.get_meta(
                        "tarvoka_engineer_v13_smoothed_visible",false)),
                    "same rig renders refined V13 mesh without rebuild")
                if lod==13:
                    var current_trim: MeshInstance3D=soldier.find_child(
                        Smooth.TRIM_PREFIX+"Superior",true,false) as MeshInstance3D
                    check(current_trim!=null and current_trim.visible,
                        "V13 comparison restores shield-depth metal bezels")
            var shield: Node3D=soldier.find_child(
                V6.RIG,true,false) as Node3D
            check(V6.pose(soldier,"inspect",1.0) and
                shield!=null and
                is_equal_approx(shield.rotation_degrees.x,-54.0),
                "rounded shield preserves actual full opening mechanism")
            check(V6.reset(soldier),"shield reset after 3D orbit")
            soldier.free()
    for role in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var unrelated: Node3D=Models.build(role,0,true,13)
        check(unrelated!=null and not Smooth.has_model(unrelated),
            "V13 never modifies "+role)
        if unrelated!=null:
            unrelated.free()

    var view:=SubViewport.new()
    view.size=Vector2i(860,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172633")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e8eef4")
    env.ambient_light_energy=0.85
    world.environment=env
    view.add_child(world)
    var lamp:=DirectionalLight3D.new()
    lamp.rotation_degrees=Vector3(-48,-31,0)
    lamp.light_energy=2.5
    view.add_child(lamp)
    var rim:=DirectionalLight3D.new()
    rim.rotation_degrees=Vector3(-23,155,0)
    rim.light_energy=1.2
    view.add_child(rim)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.25
    camera.current=true
    view.add_child(camera)
    var hero: Node3D=Models.build("infantry_engineer",6,true,13)
    check(hero!=null and Smooth.has_model(hero),
        "real Godot V13 hero load")
    if hero!=null:
        view.add_child(hero)
        var poses: Dictionary={
            "front":Vector3(0.0,2.3,-4.8),
            "left":Vector3(-4.2,2.2,-2.8),
            "right":Vector3(4.2,2.2,-2.8),
            "rear":Vector3(0,2.3,4.8),
            "top":Vector3(2.7,4.5,-3.2)}
        var changed: int=0
        for name in ["front","left","right","rear","top"]:
            camera.position=poses[name]
            camera.look_at(Vector3(0,1.37,0),Vector3.UP)
            Smooth.show_smoothing(hero,false)
            var previous: Image=await _capture(view,"v123_"+name)
            Smooth.show_smoothing(hero,true)
            var modern: Image=await _capture(view,"v13_"+name)
            changed+=_change_pixels(previous,modern)
        print("V13 same-camera perceptible changed samples: ",changed)
        check(changed>65,
            "smooth topology actually alters real silhouette and lighting")
        hero.queue_free()
        await process_frame
    check(pictures==10,"ten before/after authentic Godot 3D screenshots")
    if failures>0:
        push_error("FAIL ENGINEER V13: %d errors"%failures)
        quit(1)
    else:
        print("PASS ENGINEER V13: 8 factions x 2 LOD, rounded watertight panels, spline helmet/limbs and ten real Godot camera captures")
        quit(0)
