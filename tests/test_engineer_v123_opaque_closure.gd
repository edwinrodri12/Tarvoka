extends SceneTree

# TARVOKA G05/infantry_engineer V12.3: real Godot 4.3 airtight body volumes,
# anti-transparency, outward normals and same-camera visual A/B QA.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V9=preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const V11=preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const OUT: String="res://build/qa/infantry-v123-opaque"
var errors: int=0
var photos: int=0

func check(ok: bool, why: String) -> void:
    if not ok:
        errors+=1
        push_error("ENGINEER V12.3 OPAQUE: "+why)

func _key(p: Vector3) -> String:
    return "%d:%d:%d"%[
        roundi(p.x*100000.0),roundi(p.y*100000.0),roundi(p.z*100000.0)]

# Manifold edge counts AND outward signed volume. An inside-out closed hull
# used to pass the old watertight-only test while disappearing in WebGL.
func closed_outward(mesh: Mesh) -> bool:
    if not mesh is ArrayMesh or mesh.get_surface_count()==0:
        return false
    for surface in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surface)
        var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var raw_indices: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            raw_indices if raw_indices is PackedInt32Array else PackedInt32Array())
        var total: int=indices.size() if indices.size()>0 else verts.size()
        if total<12 or total%3!=0:
            return false
        var edges: Dictionary={}
        var volume: float=0.0
        for i in range(0,total,3):
            var ia: int=indices[i] if indices.size()>0 else i
            var ib: int=indices[i+1] if indices.size()>0 else i+1
            var ic: int=indices[i+2] if indices.size()>0 else i+2
            var a: Vector3=verts[ia]
            var b: Vector3=verts[ib]
            var c: Vector3=verts[ic]
            volume+=a.dot(b.cross(c))/6.0
            var triangle: Array[String]=[_key(a),_key(b),_key(c)]
            if triangle[0]==triangle[1] or triangle[1]==triangle[2] or (
                    triangle[0]==triangle[2]):
                return false
            for n in range(3):
                var edge: Array[String]=[triangle[n],triangle[(n+1)%3]]
                edge.sort()
                var k: String=edge[0]+"|"+edge[1]
                edges[k]=int(edges.get(k,0))+1
        if volume<0.00000001:
            return false
        for count in edges.values():
            if int(count)!=2:
                return false
    return true

func take(view: SubViewport, label: String) -> Image:
    await process_frame
    await process_frame
    var img: Image=view.get_texture().get_image()
    check(img!=null and not img.is_empty(),"Godot 3D output exists "+label)
    if img!=null and not img.is_empty():
        check(img.save_png(OUT+"/"+label+".png")==OK,
            "save native solid screenshot "+label)
        photos+=1
    return img

func changed_pixels(a: Image, b: Image) -> int:
    if a==null or b==null or a.is_empty() or b.is_empty() or (
            a.get_size()!=b.get_size()):
        return 0
    var count: int=0
    for y in range(80,a.get_height()-80,3):
        for x in range(95,a.get_width()-95,3):
            var first: Color=a.get_pixel(x,y)
            var second: Color=b.get_pixel(x,y)
            if absf(first.r-second.r)+absf(first.g-second.g)+(
                    absf(first.b-second.b))>0.16:
                count+=1
    return count

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "create 3D QA folder")
    for faction in range(8):
        for lod in [8,13]:
            var model: Node3D=Models.build(
                "infantry_engineer",faction,true,lod)
            check(model!=null,"build engineer F%d L%d"%[faction,lod])
            if model==null:
                continue
            check(V12.has_model(model) and V12.has_seals(model)
                and V12.is_visible(model),
                "ALL V12.3 physical closures exist F%d L%d"%[faction,lod])
            var torso: Node3D=model.find_child("TorsoRig",true,false) as Node3D
            var head: Node3D=model.find_child("CabezaRig",true,false) as Node3D
            var hips: Node3D=model.find_child("CaderaRig",true,false) as Node3D
            var shield: Node3D=model.find_child(V6.RIG,true,false) as Node3D
            var fixed: Array[String]=[
                V12.SEAL_SKULL,V12.SEAL_FACE,V12.SEAL_NECK,
                V12.SEAL_TORSO,V12.SEAL_WAIST]
            for name in fixed:
                var part: MeshInstance3D=model.find_child(
                    name,true,false) as MeshInstance3D
                var anchor: Node3D=(
                    head if name in [
                        V12.SEAL_SKULL,V12.SEAL_FACE,V12.SEAL_NECK]
                    else torso)
                check(part!=null and part.mesh is SphereMesh
                    and part.get_parent()==anchor,
                    "sealed 3D solid "+name+" F%d L%d"%[faction,lod])
            for side in [-1,1]:
                var arm: Node3D=model.find_child(
                    "BrazoRig_%d"%side,true,false) as Node3D
                var leg: Node3D=model.find_child(
                    "PiernaRig_%d"%side,true,false) as Node3D
                var names: Array[String]=[
                    V12.SEAL_SHOULDER,V12.SEAL_ARM,
                    V12.SEAL_HIP,V12.SEAL_BOOT,V12.SEAL_SHIELD]
                var parents: Array[Node3D]=[torso,arm,leg,leg,shield]
                for i in range(names.size()):
                    var name: String=names[i]+"_%d"%side
                    var node: MeshInstance3D=model.find_child(
                        name,true,false) as MeshInstance3D
                    check(node!=null and node.get_parent()==parents[i]
                        and node.mesh is SphereMesh,
                        "actual physical joint seal "+name)
            for item in model.find_children(V12.SEAL+"*","MeshInstance3D",
                    true,false):
                var node: MeshInstance3D=item as MeshInstance3D
                var mat: StandardMaterial3D=(
                    node.material_override as StandardMaterial3D)
                check(node.visible and mat!=null and
                    mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED
                    and mat.cull_mode==BaseMaterial3D.CULL_BACK
                    and mat.albedo_color.a>=0.999,
                    "no alpha cutout or two-sided cheat in "+node.name)
                check(node.scale.x>0 and node.scale.y>0 and node.scale.z>0,
                    "solid positive geometry scale "+node.name)
            # Existing handcrafted custom meshes must not be open or
            # inside-out either. V12.3 leaves their original contours.
            for name in [V9.HELMET,V11.LOWER,V12.MAIN,
                    V12.FRAME,V12.CASE+"_1",V12.CASE+"_-1"]:
                var node: MeshInstance3D=model.find_child(
                    name,true,false) as MeshInstance3D
                check(node!=null and closed_outward(node.mesh),
                    "watertight, outward-facing original metal "+name)
            check(V12.show_seals(model,false) and V12.has_model(model),
                "V12.2 comparison preserves rig and all original geometry")
            check(V12.show_seals(model,true) and V12.has_seals(model),
                "V12.3 seals restore without model reload")
            if shield!=null:
                check(V6.pose(model,"inspect",1.0),
                    "opened shield moves with physical seam covers")
                check(is_equal_approx(shield.rotation_degrees.x,-54.0),
                    "hinge range unchanged by opaque shells")
                check(V6.reset(model),"shield closes after test")
            model.free()
    for role in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var unrelated: Node3D=Models.build(role,0,true,13)
        check(unrelated!=null and not V12.has_seals(unrelated),
            "no changes to other infantry "+role)
        if unrelated!=null:
            unrelated.free()
    var view:=SubViewport.new()
    view.size=Vector2i(860,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env_node:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#b63a77")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#c7dbe8")
    env.ambient_light_energy=0.78
    env_node.environment=env
    view.add_child(env_node)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-45,-30,0)
    sun.light_energy=2.3
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.60
    camera.current=true
    view.add_child(camera)
    var art: Node3D=Models.build("infantry_engineer",6,true,13)
    check(art!=null and V12.has_seals(art),"hero visual comparison ready")
    if art!=null:
        view.add_child(art)
        var angles: Dictionary={
            "front":Vector3(0.0,2.40,-5.1),
            "left":Vector3(-4.5,2.30,-2.0),
            "right":Vector3(4.5,2.30,-2.0),
            "top":Vector3(3.2,5.4,-3.8),
            "rear":Vector3(0.0,2.40,5.1)}
        var changed_total: int=0
        for label in ["front","left","right","top","rear"]:
            camera.position=angles[label]
            camera.look_at(Vector3(0,1.42,0),Vector3.UP)
            check(V12.show_seals(art,false),
                "hide only V12.3 seals for authentic V12.2 comparator")
            var before: Image=await take(view,"before_"+label)
            check(V12.show_seals(art,true),
                "bring back real V12.3 solids in same 3D rig")
            var after: Image=await take(view,"solid_"+label)
            changed_total+=changed_pixels(before,after)
        print("Engineer V12.3 changed screen samples: ",changed_total)
        check(changed_total>=8,
            "solid material is actually visible and not buried in old mesh")
        art.queue_free()
        await process_frame
    check(photos==10,"ten real Godot before/after views")
    if errors>0:
        push_error("FAIL ENGINEER V12.3 OPAQUE: %d errors"%errors)
        quit(1)
    else:
        print("PASS ENGINEER V12.3 OPAQUE: 8 factions x LOD8/13, closed outward custom metal, 15 physical joint seals, opaque PBR, 10 Godot photos")
        quit(0)
