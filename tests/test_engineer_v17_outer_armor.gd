extends SceneTree

# V17 real Godot 3D QA: closed exterior mechanical-anatomic silhouette.
# Same rig/model/camera A/B, 8 faction materials x hero/tactical LOD.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const V16=preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const V17=preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const OUT: String="res://build/qa/engineer-v17"
var failed: int=0
var photos: int=0
var mobile_triangles: int=0

func check(ok: bool, message: String) -> void:
    if not ok:
        failed+=1
        push_error("ENGINEER V17: "+message)

func _key(p: Vector3) -> String:
    return "%d:%d:%d"%[
        roundi(p.x*100000.0),roundi(p.y*100000.0),roundi(p.z*100000.0)]

func closed_outward(mesh: Mesh) -> bool:
    if not mesh is ArrayMesh or mesh.get_surface_count()<1:
        return false
    var edges: Dictionary={}
    var volume: float=0.0
    for surface in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surface)
        var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
        # SurfaceTool emits unindexed triangles on Godot 4.3. For those
        # meshes ARRAY_INDEX is null, not a PackedInt32Array.
        var raw_index: Variant=arrays[Mesh.ARRAY_INDEX]
        var index: PackedInt32Array=(
            raw_index if raw_index is PackedInt32Array
            else PackedInt32Array())
        var size: int=index.size() if index.size()>0 else verts.size()
        if size<30 or size%3!=0 or verts.size()!=normals.size():
            return false
        for i in range(0,size,3):
            var a: Vector3=verts[index[i] if index.size()>0 else i]
            var b: Vector3=verts[index[i+1] if index.size()>0 else i+1]
            var c: Vector3=verts[index[i+2] if index.size()>0 else i+2]
            volume+=a.dot(b.cross(c))/6.0
            var t: Array[String]=[_key(a),_key(b),_key(c)]
            if t[0]==t[1] or t[1]==t[2] or t[2]==t[0]:
                return false
            for j in range(3):
                var edge: Array[String]=[t[j],t[(j+1)%3]]
                edge.sort()
                var key: String=edge[0]+"|"+edge[1]
                edges[key]=int(edges.get(key,0))+1
    if volume<=0.00000001:
        return false
    for count in edges.values():
        if int(count)!=2:
            return false
    return true



func face_count(mesh: Mesh) -> int:
    if mesh==null:
        return 0
    var triangles: int=0
    for surface in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surface)
        var raw_indices: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            raw_indices if raw_indices is PackedInt32Array
            else PackedInt32Array())
        if indices.size()>0:
            triangles+=indices.size()/3
        else:
            var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
            triangles+=vertices.size()/3
    return triangles

func mesh_count(n: Node) -> int:
    var result: int=1 if n is MeshInstance3D else 0
    for child in n.get_children():
        result+=mesh_count(child)
    return result

func snapshot(view: SubViewport, label: String) -> Image:
    await process_frame
    await process_frame
    var photo: Image=view.get_texture().get_image()
    check(photo!=null and not photo.is_empty(),
        "real Godot photo "+label)
    if photo!=null and not photo.is_empty():
        check(photo.save_png(OUT+"/"+label+".png")==OK,
            "PNG disk output "+label)
        photos+=1
    return photo

func image_diff(a: Image, b: Image) -> int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    if a.get_size()!=b.get_size():
        return 0
    var count: int=0
    for y in range(70,a.get_height()-70,3):
        for x in range(80,a.get_width()-80,3):
            var previous: Color=a.get_pixel(x,y)
            var current: Color=b.get_pixel(x,y)
            if (absf(previous.r-current.r)+
                absf(previous.g-current.g)+
                absf(previous.b-current.b))>0.16:
                count+=1
    return count

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "Godot V17 QA output folder")
    for faction in range(8):
        for lod in [8,13]:
            var model: Node3D=Models.build("infantry_engineer",
                faction,true,lod)
            check(model!=null and V17.has_model(model)
                and V16.has_model(model) and V12.has_seals(model),
                "complete V17 engineered infantry F%d L%d"%[faction,lod])
            if model==null:
                continue
            if not V17.has_model(model):
                model.free()
                continue
            var count_before: int=mesh_count(model)
            var torso: Node3D=model.find_child(
                "TorsoRig",true,false) as Node3D
            var chest: MeshInstance3D=model.find_child(
                V17.FRONT,true,false) as MeshInstance3D
            var symbol: MeshInstance3D=model.find_child(
                V17.INSIGNIA,true,false) as MeshInstance3D
            check(chest!=null and chest.get_parent()==torso and
                closed_outward(chest.mesh) and chest.has_meta(V17.OLD),
                "front cuirass is new fully closed tapered shell")
            check(symbol!=null and symbol.get_parent()==torso and
                symbol.has_meta(V17.OLD) and
                symbol.material_override is StandardMaterial3D and
                (symbol.material_override as StandardMaterial3D).transparency==
                    BaseMaterial3D.TRANSPARENCY_DISABLED and
                symbol.position.z<(-0.49),
                "faction emblem preserved ON the front of the cuirass")
            for side in [-1,1]:
                var suffix: String="_%d"%side
                var arm: Node3D=model.find_child(
                    "BrazoRig"+suffix,true,false) as Node3D
                var leg: Node3D=model.find_child(
                    "PiernaRig"+suffix,true,false) as Node3D
                var shoulder: MeshInstance3D=model.find_child(
                    V17.SHOULDER+suffix,true,false) as MeshInstance3D
                check(shoulder!=null and shoulder.get_parent()==arm and
                    closed_outward(shoulder.mesh) and
                    shoulder.has_meta(V17.OLD) and
                    shoulder.scale.x>0.7,
                    "real anatomically broadened shoulder still on arm rig")
                var stripe: MeshInstance3D=model.find_child(
                    "V8_FaccionHombrera"+suffix,true,false) as MeshInstance3D
                check(stripe!=null and stripe.get_parent()==arm
                    and stripe.has_meta(V17.OLD) and
                    absf(stripe.position.x)>0.34,
                    "faction arm identifier moved outside new armor")
                for label in [V17.KNEE+suffix,V17.POCKET+suffix,
                        V17.SOLE+suffix]:
                    var part: MeshInstance3D=model.find_child(
                        label,true,false) as MeshInstance3D
                    check(part!=null and part.get_parent()==leg
                        and closed_outward(part.mesh) and
                        part.has_meta(V17.OLD),
                        "solid no-gap knee, pouch or boot: "+label)
                if lod==8:
                    var knee_faction: MeshInstance3D=model.find_child(
                        "V3_IdentidadRodillaMapa"+suffix,
                        true,false) as MeshInstance3D
                    check(knee_faction!=null and
                        knee_faction.has_meta(V17.OLD) and
                        knee_faction.position.z<(-0.22),
                        "Android knee identity remains outside metal shell")
            # Enforce real Android LOD reduction instead of just claiming
            # that keeping mesh nodes constant guarantees mobile performance.
            if faction==0:
                var sculpt_triangles: int=face_count(chest.mesh)
                for side in [-1,1]:
                    var suffix: String="_%d"%side
                    for label in [V17.SHOULDER+suffix,
                            V17.KNEE+suffix,V17.POCKET+suffix,
                            V17.SOLE+suffix]:
                        var part: MeshInstance3D=model.find_child(
                            label,true,false) as MeshInstance3D
                        sculpt_triangles+=face_count(part.mesh)
                if lod==8:
                    mobile_triangles=sculpt_triangles
                else:
                    check(mobile_triangles>0 and
                        sculpt_triangles>mobile_triangles and
                        sculpt_triangles<=mobile_triangles*3.6,
                        "LOD8 external armor uses fewer triangles than hero")
            var current_mesh: Mesh=chest.mesh
            check(V17.show_finish(model,false) and
                chest.mesh!=current_mesh,
                "same physical torso restores approved V16 armor")
            check(V17.show_finish(model,true) and
                chest.mesh==current_mesh and
                mesh_count(model)==count_before,
                "real updated armor returns with ZERO extra mesh nodes")
            check(V6.pose(model,"inspect",1.0) and V6.reset(model),
                "shield and shoulder animation remain operational")
            model.free()
    for name in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var other: Node3D=Models.build(name,0,true,13)
        check(other!=null and not V17.has_model(other),
            "non-engineer infantry art unchanged "+name)
        if other!=null:
            other.free()

    var viewport:=SubViewport.new()
    viewport.size=Vector2i(860,700)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#182a39")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e7eff4")
    env.ambient_light_energy=0.83
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-38,0)
    sun.light_energy=2.45
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.15
    camera.current=true
    viewport.add_child(camera)
    var hero: Node3D=Models.build("infantry_engineer",6,true,13)
    check(hero!=null and V17.has_model(hero),
        "V17 hero real scene comparison exists")
    if hero!=null:
        viewport.add_child(hero)
        var positions: Dictionary={
            "front":Vector3(0,2.2,-4.7),
            "left":Vector3(-4.1,2.25,-2.6),
            "right":Vector3(4.1,2.25,-2.6),
            "rear":Vector3(0,2.25,4.8),
            "top":Vector3(2.6,4.9,-3.3)}
        var count_changes: int=0
        for label in ["front","left","right","rear","top"]:
            camera.position=positions[label]
            camera.look_at(Vector3(0,1.40,0),Vector3.UP)
            V17.show_finish(hero,false)
            var old: Image=await snapshot(viewport,"v16_"+label)
            V17.show_finish(hero,true)
            var new: Image=await snapshot(viewport,"v17_"+label)
            count_changes+=image_diff(old,new)
        print("V17 real changed picture samples: ",count_changes)
        check(count_changes>150,
            "real new chest and deltoids visibly differ in native Godot")
        hero.queue_free()
        await process_frame
    check(photos==10,"ten V16 versus V17 real native Godot PNGs")
    if failed>0:
        push_error("FAIL ENGINEER V17: %d violations"%failed)
        quit(1)
    else:
        print("PASS ENGINEER V17: 8 factions x 2 LOD, closed hard-surface chest, shoulder, knees, boots; 10 real 3D comparison images")
        quit(0)
