extends SceneTree
# Engineer V16: physically re-sculpted unified closed-body silhouette QA.
# Same real Godot mesh/view, no extra nodes, unchanged animation/factions.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const V15=preload("res://scripts/ui/InfantryEngineerGearV15.gd")
const V16=preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const OUT: String="res://build/qa/engineer-v16"
var errors: int=0
var count_png: int=0

func check(ok: bool, message: String) -> void:
    if not ok:
        errors+=1
        push_error("ENGINEER V16: "+message)

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
            # Godot clockwise front faces: negate conventional signed volume.
            volume-=a.dot(b.cross(c))/6.0
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


func mesh_count(node: Node) -> int:
    var count: int=1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count+=mesh_count(child)
    return count

func picture(view: SubViewport, name: String) -> Image:
    await process_frame
    await process_frame
    var image: Image=view.get_texture().get_image()
    check(image!=null and not image.is_empty(),"real Godot render "+name)
    if image!=null and not image.is_empty():
        check(image.save_png(OUT+"/"+name+".png")==OK,
            "save Godot 3D image "+name)
        count_png+=1
    return image

func changed_pixels(previous: Image, new: Image) -> int:
    if previous==null or new==null or previous.is_empty() or (
            new.is_empty() or previous.get_size()!=new.get_size()):
        return 0
    var changed: int=0
    for y in range(80,previous.get_height()-80,3):
        for x in range(90,previous.get_width()-90,3):
            var a: Color=previous.get_pixel(x,y)
            var b: Color=new.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.16:
                changed+=1
    return changed

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"output folder exists")
    for faction in range(8):
        for lod in [8,13]:
            var hero: bool=lod>=13
            var model: Node3D=Models.build("infantry_engineer",
                faction,true,lod)
            check(model!=null,"engineer built F%d L%d"%[faction,lod])
            if model==null:
                continue
            check(V16.has_model(model) and V15.has_model(model) and
                V12.has_seals(model),
                "real V16 uses approved physically sealed V12.3-V15 base")
            if not V16.has_model(model):
                model.free()
                continue
            var original_count: int=mesh_count(model)
            var torso: Node3D=model.find_child(
                "TorsoRig",true,false) as Node3D
            var pelvis: Node3D=model.find_child(
                "CaderaRig",true,false) as Node3D
            for spec in [[V16.CORE,"TorsoRig"],
                    [V16.PELVIS,"CaderaRig"]]:
                var node: MeshInstance3D=model.find_child(
                    str(spec[0]),true,false) as MeshInstance3D
                check(node!=null and node.get_parent().name==str(spec[1])
                    and node.mesh is ArrayMesh
                    and closed_outward(node.mesh) and node.has_meta(V16.OLD),
                    "physical sealed torso/waist anatomical taper "+str(spec[0]))
            for side in [-1,1]:
                var suffix: String="_%d"%side
                var leg: Node3D=model.find_child(
                    "PiernaRig"+suffix,true,false) as Node3D
                check(leg!=null and leg.get_parent()==pelvis,
                    "leg continues following untouched existing hip rig")
                for name in [V16.THIGH,V16.SHIN,V16.BOOT]:
                    var part: MeshInstance3D=model.find_child(
                        name+suffix,true,false) as MeshInstance3D
                    check(part!=null and part.get_parent()==leg and
                        part.mesh is ArrayMesh and
                        closed_outward(part.mesh) and part.has_meta(V16.OLD),
                        "closed anatomical femur-calf-boot exterior "+name+suffix)
                for name in ["V8_JuntaRodillaCerrada",
                        "V8_CantoneraRodillaPosterior",
                        "V8_PantorrillaContinua"]:
                    var cap: MeshInstance3D=model.find_child(
                        name+suffix,true,false) as MeshInstance3D
                    check(cap!=null and cap.mesh is SphereMesh and
                        cap.material_override is StandardMaterial3D and
                        (cap.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "solid flex seal remains and stays fully opaque "+name)
            var core: MeshInstance3D=model.find_child(
                V16.CORE,true,false) as MeshInstance3D
            var improved: Mesh=core.mesh
            check(V16.show_contours(model,false) and core.mesh!=improved
                and core.mesh is SphereMesh,
                "reversible comparison genuinely restores V15 torso")
            check(V16.show_contours(model,true) and core.mesh==improved
                and mesh_count(model)==original_count,
                "V16 torso returns without new draw calls")
            check(V6.pose(model,"inspect",1.0) and
                V6.reset(model),"real articulating shield survives V16")
            model.free()
    for role in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var other: Node3D=Models.build(role,0,true,13)
        check(other!=null and not V16.has_model(other),
            "does not sculpt non-engineer infantry "+role)
        if other!=null: other.free()

    var view:=SubViewport.new()
    view.size=Vector2i(860,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env_node:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#182a37")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e5f0f5")
    env.ambient_light_energy=0.85
    env_node.environment=env
    view.add_child(env_node)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-37,0)
    sun.light_energy=2.4
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.16
    camera.current=true
    view.add_child(camera)
    var soldier: Node3D=Models.build("infantry_engineer",6,true,13)
    check(soldier!=null and V16.has_model(soldier),
        "hero silhouette visible for 360 render")
    if soldier!=null:
        view.add_child(soldier)
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
            V16.show_contours(soldier,false)
            var previous: Image=await picture(view,"v15_"+label)
            V16.show_contours(soldier,true)
            var updated: Image=await picture(view,"v16_"+label)
            changed+=changed_pixels(previous,updated)
        print("Engineer V16 silhouette changed pixel samples: ",changed)
        check(changed>50,
            "new anatomically tapered core and limbs visibly differ")
        soldier.queue_free()
        await process_frame
    check(count_png==10,"ten same-camera native Godot PNGs")
    if errors>0:
        push_error("FAIL ENGINEER V16: %d errors"%errors)
        quit(1)
    else:
        print("PASS ENGINEER V16: 8 factions x 2 LODs, sealed torso/pelvis/limbs, no new mesh nodes, ten real Godot views")
        quit(0)
