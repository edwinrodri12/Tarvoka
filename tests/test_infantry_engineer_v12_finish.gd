extends SceneTree

# V12-native Godot 4.3 QA: 8 factions, two LODs, sealed PBR meshes,
# torso-fixed tool cases versus the genuinely rotating V6/V11 shield,
# reversible V11/V12 comparison and 8 real 3D SubViewport photos.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V11=preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const OUT := "res://build/qa/infantry-v12"
var failures: int=0
var pictures: int=0

func expect(ok: bool, reason: String) -> void:
    if not ok:
        failures+=1
        push_error("ENGINEER V12: "+reason)

func _key(vertex: Vector3) -> String:
    return "%d:%d:%d"%[roundi(vertex.x*100000.0),
        roundi(vertex.y*100000.0),roundi(vertex.z*100000.0)]

func _watertight(mesh: Mesh) -> bool:
    if not mesh is ArrayMesh or mesh.get_surface_count()==0:
        return false
    for surface in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surface)
        var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var index_array: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            index_array if index_array is PackedInt32Array else PackedInt32Array())
        var total: int=indices.size() if indices.size()>0 else verts.size()
        if total<12 or total%3!=0:
            return false
        var edges: Dictionary={}
        for j in range(0,total,3):
            var triangle: Array[String]=[]
            for k in range(3):
                var index: int=indices[j+k] if indices.size()>0 else j+k
                triangle.append(_key(verts[index]))
            for k in range(3):
                var edge: Array[String]=[triangle[k],triangle[(k+1)%3]]
                edge.sort()
                var key: String=edge[0]+"|"+edge[1]
                edges[key]=int(edges.get(key,0))+1
        for count in edges.values():
            if int(count)!=2:
                return false
    return true

func _photo(view: SubViewport, label: String) -> void:
    await process_frame
    await process_frame
    var frame: Image=view.get_texture().get_image()
    expect(frame!=null and not frame.is_empty(),"render "+label)
    if frame!=null and not frame.is_empty():
        expect(frame.save_png(OUT+"/"+label+".png")==OK,"save PNG "+label)
        pictures+=1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    expect(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"create QA directory")
    for faction in range(8):
        for lod in [8,13]:
            var soldier: Node3D=Models.build("infantry_engineer",faction,true,lod)
            expect(soldier!=null,"native F%d L%d"%[faction,lod])
            if soldier==null:
                continue
            var torso: Node3D=soldier.find_child("TorsoRig",true,false) as Node3D
            var shield: Node3D=soldier.find_child(V6.RIG,true,false) as Node3D
            expect(V11.has_model(soldier) and V12.has_model(soldier) and
                V12.is_visible(soldier),"V11 intact and V12 loaded on F%d L%d"%[faction,lod])
            var central: MeshInstance3D=soldier.find_child(
                V12.MAIN,true,false) as MeshInstance3D
            expect(central!=null and central.get_parent()==shield and
                _watertight(central.mesh) and central.position.z>0.38,
                "V12 main chamfered shield shell physically on EXTERIOR")
            var frame: MeshInstance3D=soldier.find_child(
                V12.FRAME,true,false) as MeshInstance3D
            expect(frame!=null and frame.get_parent()==shield and
                _watertight(frame.mesh),
                "closed perimeter pressing is attached to the moving rig")
            for side in [-1,1]:
                var outer: MeshInstance3D=soldier.find_child(
                    V12.OUTER+"_%d"%side,true,false) as MeshInstance3D
                var stripe: MeshInstance3D=soldier.find_child(
                    V12.ACCENT+"_%d"%side,true,false) as MeshInstance3D
                var pouch: MeshInstance3D=soldier.find_child(
                    V12.CASE+"_%d"%side,true,false) as MeshInstance3D
                var side_mark: MeshInstance3D=soldier.find_child(
                    V12.POUCH_ID+"_%d"%side,true,false) as MeshInstance3D
                var wing_skin: MeshInstance3D=soldier.find_child(
                    V12.WING_SKIN+"_%d"%side,true,false) as MeshInstance3D
                expect(wing_skin!=null and _watertight(wing_skin.mesh) and
                    wing_skin.get_parent()==soldier.find_child(
                    "V6_AlaIzquierdaRig" if side<0 else "V6_AlaDerechaRig",
                    true,false),
                    "V12 outer wings truly follow their own rotating pivots")
                var rack: Node3D=soldier.find_child(
                    V12.RACK+"_%d"%side,true,false) as Node3D
                expect(outer!=null and stripe!=null and pouch!=null and
                    rack!=null and side_mark!=null,
                    "both sides V12 physical case and faction insignia")
                if outer!=null and stripe!=null and pouch!=null and rack!=null:
                    expect(outer.get_parent()==shield and stripe.get_parent()==shield and
                        pouch.get_parent()==torso and rack.get_parent()==torso,
                        "shield details move, dorsal cases remain anchored")
                    expect(_watertight(outer.mesh) and _watertight(stripe.mesh)
                        and pouch.mesh is ArrayMesh and _watertight(pouch.mesh)
                        and _watertight(side_mark.mesh),
                        "solid watertight faceted armor, sculpted cases, faction inlay")
                    var side_mat: StandardMaterial3D=(
                        side_mark.material_override as StandardMaterial3D)
                    expect(side_mat!=null and side_mat.transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED and
                        side_mat.albedo_color.is_equal_approx(
                            Models.faction_paint_color(faction)),
                        "side-pouch plate has exact faction color F%d L%d"%[faction,lod])
                    var mat: StandardMaterial3D=stripe.material_override as StandardMaterial3D
                    expect(mat!=null and mat.transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED and
                        mat.albedo_color.is_equal_approx(
                        Models.faction_paint_color(faction)),
                        "fully opaque true faction material")
                    expect(pouch.visible and outer.visible,
                        "external armor and pouch physically visible")
            if shield!=null:
                expect(V6.pose(soldier,"inspect",1.0),"V6 3D inspection opens")
                expect(is_equal_approx(shield.rotation_degrees.x,-54.0),
                    "real shield rotates including V12 exterior")
                expect(V6.reset(soldier),"V6 folded pose resets")
            var damage: Node3D=soldier.find_child(
                "V6_RayonesD2",true,false) as Node3D
            expect(damage!=null and damage.position.z>0.58,
                "V6 D2 damage stays above sculpted V12 outer surface")
            expect(V12.show_finish(soldier,false) and not V12.is_visible(soldier),
                "V11 native comparison genuinely removes V12 surfaces")
            expect(damage!=null and is_equal_approx(damage.position.z,0.232),
                "V11 original V6 damage depth restored")
            expect(V12.show_finish(soldier,true) and V12.is_visible(soldier),
                "V12 real mesh returns without rebuild")
            expect(damage!=null and damage.position.z>0.58,
                "V12 visibility restores damage overlay without rebuilding")
            soldier.free()
    for other in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var model: Node3D=Models.build(other,0,true,13)
        expect(model!=null and not V12.has_model(model),
            "no engineer art added to "+other)
        if model!=null:
            model.free()

    var view := SubViewport.new()
    view.size=Vector2i(860,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#1a2935")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#d9e7ef")
    env.ambient_light_energy=0.84
    env_node.environment=env
    view.add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-34,0)
    sun.light_energy=2.4
    view.add_child(sun)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees=Vector3(-22,146,0)
    rim.light_energy=1.4
    view.add_child(rim)
    var camera := Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.4
    view.add_child(camera)
    camera.current=true
    var art: Node3D=Models.build("infantry_engineer",0,true,13)
    expect(art!=null and V12.has_model(art),"3D inspection mesh loaded")
    if art!=null:
        view.add_child(art)
        var angles := {
            "rear":Vector3(0,2.30,4.8),
            "right":Vector3(4.8,2.30,0),
            "left":Vector3(-4.8,2.30,0)
        }
        camera.position=angles["rear"]
        camera.look_at(Vector3(0,1.30,0),Vector3.UP)
        await _photo(view,"engineer_v12_rear_folded")
        V6.pose(art,"inspect",1.0)
        await _photo(view,"engineer_v12_rear_open")
        V6.pose(art,"inspect",0.5)
        camera.position=angles["left"]
        camera.look_at(Vector3(0,1.3,0),Vector3.UP)
        await _photo(view,"engineer_v12_left_half_open")
        V6.reset(art)
        camera.position=angles["right"]
        camera.look_at(Vector3(0,1.3,0),Vector3.UP)
        await _photo(view,"engineer_v12_right_closed")
        camera.size=2.05
        camera.position=angles["rear"]
        camera.look_at(Vector3(0,1.52,0),Vector3.UP)
        await _photo(view,"engineer_v12_exterior_enamel_close")
        camera.position=angles["right"]
        camera.look_at(Vector3(0,1.50,0),Vector3.UP)
        await _photo(view,"engineer_v12_dorsal_cases_close")
        # Identical rear framing before/after makes visual regression
        # independently inspectable, rather than comparing different cameras.
        V12.show_finish(art,false)
        camera.position=angles["rear"]
        camera.look_at(Vector3(0,1.52,0),Vector3.UP)
        await _photo(view,"engineer_v11_same_camera_comparison")
        art.queue_free()
        await process_frame
    var faction_art: Node3D=Models.build("infantry_engineer",7,true,13)
    expect(faction_art!=null and V12.has_model(faction_art),
        "second actual faction render uses latest V12 mesh")
    if faction_art!=null:
        view.add_child(faction_art)
        camera.size=2.05
        camera.position=Vector3(0,2.30,4.8)
        camera.look_at(Vector3(0,1.52,0),Vector3.UP)
        await _photo(view,"engineer_v12_faction7_rear")
        faction_art.queue_free()
        await process_frame
    expect(pictures==8,"eight real Godot 3D PNGs")
    # Same rear shot, same lighting, same camera: assert the new finish is
    # actually visible, rather than merely present as occluded geometry.
    var modern: Image=Image.load_from_file(
        OUT+"/engineer_v12_exterior_enamel_close.png")
    var legacy: Image=Image.load_from_file(
        OUT+"/engineer_v11_same_camera_comparison.png")
    expect(modern!=null and legacy!=null and
        modern.get_size()==legacy.get_size(),
        "V11/V12 screenshots have the exact same camera framing")
    if modern!=null and legacy!=null and modern.get_size()==legacy.get_size():
        var changed: int=0
        for y in range(240,580,3):
            for x in range(170,695,3):
                var p: Color=modern.get_pixel(x,y)
                var q: Color=legacy.get_pixel(x,y)
                if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.35:
                    changed+=1
        print("Engineer V12.2 true same-camera visual pixels changed (3px samples): ",changed)
        expect(changed>900,
            "V12.2 visible sculpt must materially differ from V11 photo")
    if failures>0:
        push_error("FAIL ENGINEER V12: %d assertions"%failures)
        quit(1)
    else:
        print("PASS ENGINEER V12: 8 factions x 2 LOD, solid exterior, fixed tool packs, reversible comparison and 8 Godot PNGs")
        quit(0)
