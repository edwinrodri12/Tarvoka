extends SceneTree

# Native Godot V14 acceptance: genuine arm/helmet silhouette edits,
# identical-camera comparisons and unchanged G05 mechanical rig.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V9=preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const V13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const V14=preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const OUT: String="res://build/qa/engineer-v14"
var errors: int=0
var images: int=0

func check(condition: bool, message: String) -> void:
    if not condition:
        errors+=1
        push_error("ENGINEER V14: "+message)

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

func count_meshes(root: Node) -> int:
    var count: int=1 if root is MeshInstance3D else 0
    for child in root.get_children():
        count+=count_meshes(child)
    return count

func screenshot(view: SubViewport, label: String) -> Image:
    await process_frame
    await process_frame
    var frame: Image=view.get_texture().get_image()
    check(frame!=null and not frame.is_empty(),"photo exists "+label)
    if frame!=null and not frame.is_empty():
        check(frame.save_png(OUT+"/"+label+".png")==OK,
            "PNG saved "+label)
        images+=1
    return frame

func image_delta(before: Image, after: Image) -> int:
    if before==null or after==null or before.get_size()!=after.get_size():
        return 0
    var changed: int=0
    for y in range(90,before.get_height()-90,3):
        for x in range(95,before.get_width()-95,3):
            var a: Color=before.get_pixel(x,y)
            var b: Color=after.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.13:
                changed+=1
    return changed

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"create QA output")
    for faction in range(8):
        for lod in [8,13]:
            var engineer: Node3D=Models.build(
                "infantry_engineer",faction,true,lod)
            check(engineer!=null and V14.has_model(engineer)
                and V13.has_model(engineer) and V12.has_seals(engineer),
                "V14 must inherit the closed V13/V12.3 F%d L%d"%[faction,lod])
            if engineer==null or not V14.has_model(engineer):
                if engineer!=null: engineer.free()
                continue
            var before_count: int=count_meshes(engineer)
            var head: Node3D=engineer.find_child(
                "CabezaRig",true,false) as Node3D
            var torso: Node3D=engineer.find_child(
                "TorsoRig",true,false) as Node3D
            var helmet: MeshInstance3D=engineer.find_child(
                V9.HELMET,true,false) as MeshInstance3D
            var vest: MeshInstance3D=engineer.find_child(
                V14.FRONT,true,false) as MeshInstance3D
            check(helmet!=null and helmet.get_parent()==head and
                closed_outward(helmet.mesh) and
                vest!=null and vest.get_parent()==torso and
                closed_outward(vest.mesh),
                "closed smooth helmet/vest have real outward surfaces")
            # Replace what users actually saw as angular: the V5 brow,
            # V7 respirator and rectangular V6 folding shield / wings.
            for name in ["V5_ViseraObraIngeniero",
                    "V7_MascaraResistenciaIngeniero",
                    "V7_FiltroCentralRespirador",
                    "V6_PlacaPrincipalDeAcero",
                    "V6_CostraBlindajeExterior",
                    "V6_AlaMetal_-1","V6_AlaMetal_1"]:
                var source: MeshInstance3D=engineer.find_child(
                    name,true,false) as MeshInstance3D
                check(source!=null and source.mesh is ArrayMesh and
                    closed_outward(source.mesh) and source.has_meta(V14.OLD),
                    "V14 replaces actual visible boxy exterior with closed curved "+name)
            var arms: Array=[]
            for side in [-1,1]:
                var arm: Node3D=engineer.find_child(
                    "BrazoRig_%d"%side,true,false) as Node3D
                var shoulder: MeshInstance3D=engineer.find_child(
                    V14.SHOULDER+"_%d"%side,true,false) as MeshInstance3D
                var neck_seal: MeshInstance3D=engineer.find_child(
                    V12.SEAL_NECK,true,false) as MeshInstance3D
                check(shoulder!=null and shoulder.get_parent()==arm
                    and closed_outward(shoulder.mesh) and
                    shoulder.mesh.get_faces().size()>220,
                    "deltoid V14 is a sealed anatomically contoured shoulder")
                check(neck_seal!=null and neck_seal.get_parent()==head
                    and neck_seal.scale.y>0.29,
                    "neck/helmet physically intersect: no floating gap")
                arms.append(arm)
            var smoothed_shoulder: MeshInstance3D=engineer.find_child(
                V14.SHOULDER+"_1",true,false) as MeshInstance3D
            var v14_mesh: Mesh=smoothed_shoulder.mesh
            check(V14.show_contours(engineer,false) and
                smoothed_shoulder.mesh!=v14_mesh,
                "V13 previous real shoulder mesh restored")
            check(V14.show_contours(engineer,true) and
                smoothed_shoulder.mesh==v14_mesh and
                count_meshes(engineer)==before_count,
                "anatomical contour restored without extra draw calls")
            var pivot: Node3D=engineer.find_child(
                V6.RIG,true,false) as Node3D
            check(V6.pose(engineer,"inspect",1.0) and
                is_equal_approx(pivot.rotation_degrees.x,-54.0),
                "full shield movement unaffected by body reshaping")
            check(V6.reset(engineer),"shield pose resets correctly")
            engineer.free()
    for role in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var soldier: Node3D=Models.build(role,0,true,13)
        check(soldier!=null and not V14.has_model(soldier),
            "other five infantry roles are unchanged: "+role)
        if soldier!=null: soldier.free()

    var view:=SubViewport.new()
    view.size=Vector2i(860,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#152837")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e7f2f6")
    env.ambient_light_energy=0.82
    world.environment=env
    view.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-52,-38,0)
    light.light_energy=2.5
    view.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.2
    camera.current=true
    view.add_child(camera)
    var art: Node3D=Models.build("infantry_engineer",6,true,13)
    check(art!=null and V14.has_model(art),"hero 3D QA view")
    if art!=null:
        view.add_child(art)
        var views: Dictionary={
            "front":Vector3(0,2.2,-4.7),
            "left":Vector3(-4.1,2.25,-2.6),
            "right":Vector3(4.1,2.25,-2.6),
            "rear":Vector3(0,2.25,4.8),
            "top":Vector3(2.6,4.9,-3.3)}
        var total: int=0
        for label in ["front","left","right","rear","top"]:
            camera.position=views[label]
            camera.look_at(Vector3(0,1.40,0),Vector3.UP)
            V14.show_contours(art,false)
            var previous: Image=await screenshot(view,"v13_"+label)
            V14.show_contours(art,true)
            var updated: Image=await screenshot(view,"v14_"+label)
            total+=image_delta(previous,updated)
        print("V14 anatomy same-camera changed samples: ",total)
        check(total>45,
            "helmet and shoulder silhouette visibly improved in native render")
        art.queue_free()
        await process_frame
    check(images==10,"ten authentic native Godot before/after PNG")
    if errors>0:
        push_error("FAIL ENGINEER V14: %d violations"%errors)
        quit(1)
    else:
        print("PASS ENGINEER V14: 8 factions x 2 LOD, curved sealed helmet, anatomical deltoids, neck/torso continuity and ten native captures")
        quit(0)
