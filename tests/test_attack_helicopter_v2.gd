extends SceneTree

# Native Godot acceptance for A01 V2. Verify real enclosed meshes, not
# an extra decorative badge, and leave battle LOD/game mechanics untouched.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V2 GEOMETRY: "+why)

func _vertex(v: Vector3) -> String:
    return "%d:%d:%d" % [
        roundi(v.x*100000),roundi(v.y*100000),roundi(v.z*100000)]

func _edge(edges: Dictionary,a: String,b: String) -> void:
    var label: String=a+"|"+b if a<b else b+"|"+a
    edges[label]=int(edges.get(label,0))+1

func _watertight(mesh: ArrayMesh) -> bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var verts: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    if verts.size()<120 or verts.size()%3!=0:
        return false
    var edges: Dictionary={}
    for n in range(0,verts.size(),3):
        var a: String=_vertex(verts[n])
        var b: String=_vertex(verts[n+1])
        var c: String=_vertex(verts[n+2])
        if a==b or a==c or b==c:
            return false
        _edge(edges,a,b)
        _edge(edges,b,c)
        _edge(edges,c,a)
    for uses in edges.values():
        if int(uses)!=2:
            return false
    return not edges.is_empty()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var small: Node3D=Models.build("attack_heli",0,true,10)
    _check(small!=null,"old battle model still exists")
    if small!=null:
        _check(not V1.has_model(small) and not V2.has_model(small),
            "mobile LOD has no hero-only geometry")
        _check(small.find_child("Fuselaje",true,false)!=null,
            "mobile LOD retains original silhouette")
        small.free()

    var faction_paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"eight faction models build")
        if model==null:
            continue
        root.add_child(model)
        _check(V1.has_model(model) and V2.has_model(model),
            "V2 is layered over the exact old hero A01")
        var original: Node3D=model.find_child("A01_MonocascoFacetado",true,false)
        var original_glass: Node3D=model.find_child(
            "A01_CarenadoCristalTandem",true,false)
        var replacement: Node3D=model.find_child(V2.ROOT,true,false)
        var new_hull: MeshInstance3D=model.find_child(V2.HULL,true,false) as MeshInstance3D
        var new_glass: MeshInstance3D=model.find_child(V2.GLASS,true,false) as MeshInstance3D
        _check(original!=null and original_glass!=null and replacement!=null,
            "originals and new sculpt remain reversible")
        _check(new_hull!=null and new_glass!=null and
            new_hull.mesh is ArrayMesh and new_glass.mesh is ArrayMesh,
            "12 sided hull and canopy are native Godot ArrayMesh")
        if new_hull!=null and new_hull.mesh is ArrayMesh:
            _check(_watertight(new_hull.mesh as ArrayMesh),
                "12-sided hull is watertight with capped front and rear")
        if new_glass!=null and new_glass.mesh is ArrayMesh:
            _check(_watertight(new_glass.mesh as ArrayMesh),
                "canopy is a closed 3D volume, not a painted flat decal")
            var mat: StandardMaterial3D=new_glass.material_override as StandardMaterial3D
            _check(mat!=null and mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and
                mat.albedo_color.a>0.5 and mat.albedo_color.a<0.9,
                "canopy glass is tinted translucent PBR")
        _check(not original.visible and not original_glass.visible and replacement.visible,
            "V1 shape is physically replaced, not drawn underneath new shape")
        for label in ["A01_V2_Asiento_0","A01_V2_Asiento_1",
                "A01_V2_Respaldo_0","A01_V2_Respaldo_1",
                "A01_V2_PuertaCabina_-1","A01_V2_PuertaCabina_1",
                "A01_V2_TapaSuperiorTransmision",
                "A01_V2_Costilla_3_2","A01_V2_MarcoLong_3_2",
                V1.MAIN_ROTOR,V1.TAIL_ROTOR,V1.GUN]:
            _check(model.find_child(label,true,false)!=null,
                "real V2 frame, seat, door or preserved V1 rig "+label)
        var side: MeshInstance3D=model.find_child(
            "A01_V2_ProteccionHombro_1",true,false) as MeshInstance3D
        _check(side!=null and side.material_override is StandardMaterial3D,
            "physical faction shoulder enamel")
        if side!=null and side.material_override is StandardMaterial3D:
            faction_paints[(side.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        var count: int=Models.inspect_meshes(model)
        _check(count>90,"the actual detailed sculpt is present")
        _check(V2.apply(model,Models.faction_paint_color(faction)),
            "re-applying V2 is idempotent")
        _check(Models.inspect_meshes(model)==count,
            "re-applying V2 does not duplicate panels")
        _check(V2.set_enabled(model,false),"reversible V1 comparison")
        _check(original.visible and original_glass.visible and not replacement.visible,
            "V1 geometry restored in comparison")
        _check(V2.set_enabled(model,true),"restore new sculpt")
        _check(not original.visible and not original_glass.visible and replacement.visible,
            "new V2 frame and canopy come back without overlapping old parts")
        var previous: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.35),
            "original rotor and flight animation still works")
        _check(model.position!=previous,"flight still visually moves body")
        _check(Models.pose_model("attack_heli",model,"attack",0.35),
            "original gun continues to fire")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==previous,"fully reversible pose")
        _check(replacement.visible,"V2 remains enabled after animations")
        model.queue_free()
        await process_frame
    _check(faction_paints.size()==8,
        "V2 armored enamel differentiates all eight factions")
    if failures>0:
        push_error("A01 V2: %d failures" % failures)
        quit(1)
        return
    print("PASS A01 V2: eight faction hulls and translucent canopies truly watertight, cockpit frames/seats/doors, reversible versions, preserved rotor and battle LOD")
    quit(0)
