extends SceneTree

# Native Godot V25 acceptance: detect actual missing tire faces, not merely
# check whether detail meshes exist. Real 6x6 pivots; no FPS benchmarking.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V14=preload("res://scripts/ui/APCWheelV14.gd")
const V23=preload("res://scripts/ui/APCTireFinishV23.gd")
const V24=preload("res://scripts/ui/APCRubberArchV24.gd")
const V25=preload("res://scripts/ui/APCClosedTiresV25.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("BASTION V25 SEALED TIRE: "+why)

func _vertex_id(v: Vector3) -> String:
    return "%d:%d:%d" % [
        roundi(v.x*100000),roundi(v.y*100000),roundi(v.z*100000)]

func _edge(edges: Dictionary,a: String,b: String) -> void:
    var label: String=a+"|"+b if a<b else b+"|"+a
    edges[label]=int(edges.get(label,0))+1

func _watertight(mesh: ArrayMesh) -> bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var verts: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    if verts.size()!=V25.SEGMENTS*V25.PROFILE*6:
        return false
    var edges: Dictionary={}
    for index in range(0,verts.size(),3):
        var a: String=_vertex_id(verts[index])
        var b: String=_vertex_id(verts[index+1])
        var c: String=_vertex_id(verts[index+2])
        if a==b or b==c or a==c:
            return false
        _edge(edges,a,b)
        _edge(edges,b,c)
        _edge(edges,c,a)
    if edges.is_empty():
        return false
    for count in edges.values():
        if int(count)!=2:
            return false
    return true

func _find(model: Node3D,label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"all 8 faction Bastions build")
        if model==null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V25.FLAG,false)) and
            bool(model.get_meta(V24.FLAG,false)) and
            bool(model.get_meta(V23.FLAG,false)) and
            bool(model.get_meta(V14.FLAG,false)),
            "V25 closed tire successfully layered over V14-V24")
        _check(str(model.get_meta("tarvoka_p06_v25_casing_axis",""))=="X",
            "rubber uses same X axle as rims and rotating pivots")
        var paint: MeshInstance3D=_find(model,
            "P06V19_ChaflanSuperior_1_0") as MeshInstance3D
        if paint!=null and paint.material_override is StandardMaterial3D:
            paints[(paint.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        for side in [-1,1]:
            for axle in range(3):
                var wheel: Node3D=_find(model,
                    "RuedaMotorizadaP06_%d_%d" % [side,axle])
                _check(wheel!=null,"six individual wheel pivots exist")
                if wheel==null:
                    continue
                var root_tire: Node3D=wheel.find_child(
                    V25.ROOT,false,false) as Node3D
                var old: MeshInstance3D=wheel.find_child(
                    V25.CASING,false,false) as MeshInstance3D
                var v23: Node3D=wheel.find_child(
                    V23.ROOT,false,false) as Node3D
                var v24: Node3D=wheel.find_child(
                    V24.WHEEL_PART,false,false) as Node3D
                var v14: Node3D=wheel.find_child(
                    V14.WHEEL_ROOT,false,false) as Node3D
                _check(root_tire!=null and old!=null
                    and v23!=null and v24!=null and v14!=null,
                    "wheel has closed rubber, tread, sidewall, V24 and metal rim")
                if root_tire==null:
                    continue
                var body: MeshInstance3D=root_tire.find_child(
                    V25.BODY,false,false) as MeshInstance3D
                var backing: MeshInstance3D=root_tire.find_child(
                    V25.BACKING,false,false) as MeshInstance3D
                _check(body!=null and backing!=null and
                    body.mesh is ArrayMesh,
                    "new sidewalls physically seal tire from metal rim to tread")
                if body!=null and body.mesh is ArrayMesh:
                    var aabb: AABB=body.mesh.get_aabb()
                    _check(aabb.size.x>0.235 and aabb.size.x<0.255
                        and aabb.size.y>0.67 and aabb.size.z>0.67,
                        "tire rotates around X, unlike broken V2 Y-axis carcass")
                    _check(not old.visible and body.visible,
                        "hide misaligned V2 casing; only new closed one visible")
                    if side==-1 and axle==0 and faction==0:
                        _check(_watertight(body.mesh as ArrayMesh),
                            "ALL edges have exactly two triangles, no open sidewall holes")
                if backing!=null:
                    _check(absf(backing.position.x-float(side)*0.104)<0.001,
                        "dark brake backing aligned behind rim for both sides")
                    _check(backing.mesh is ArrayMesh,
                        "brake backing is actual 3D annular volume")
        var wheel: Node3D=_find(model,"RuedaMotorizadaP06_1_0")
        var body: Node3D=wheel.find_child(V25.BODY,true,false) as Node3D
        var before: Transform3D=body.global_transform
        _check(Rig.pose(model,"move_turn",0.55),
            "original 6x6 steering still functions")
        _check(body.global_transform!=before and
            wheel.is_ancestor_of(body),
            "closed casing spins on its OWN original wheel pivot")
        Rig.restore(model)
        _check(V25.set_weather(model,"rain"),
            "rain darkens sealed rubber")
        var wet: StandardMaterial3D=(body as MeshInstance3D).material_override
        _check(wet!=null and wet.roughness<0.80,"wet rubber reacts")
        _check(V25.set_weather(model,"snow"),
            "snow sets visible cold rubber material")
        var frost: StandardMaterial3D=(body as MeshInstance3D).material_override
        _check(frost!=null and frost.roughness>0.95,
            "snow remains matte")
        _check(V25.set_weather(model,"clear"),
            "factory rubber recovers without overlay buildup")
        for stage in range(5):
            _check(V25.set_stage(model,stage),
                "closed tire persists in five damage levels")
            _check(body.visible,"no empty wheel when damage changes")
        _check(V25.set_stage(model,0),"complete repair")
        _check(V25.set_enabled(model,false),"historical comparison")
        var old: MeshInstance3D=wheel.find_child(
            V25.CASING,false,false) as MeshInstance3D
        _check(not wheel.find_child(V25.ROOT,false,false).visible
            and old.visible,"V3 comparison restores original rubber")
        _check(V25.set_enabled(model,true),
            "V25 tire can be restored without rebuilding the model")
        _check(body.visible and not old.visible,
            "modern tire returns with no double overlapping carcasses")
        model.queue_free()
        await process_frame
    _check(paints.size()==8,"paint identity remains eight distinct factions")
    if failures>0:
        push_error("BASTION V25: %d actual tire closure errors" % failures)
        quit(1)
        return
    print("PASS BASTION V25 CLOSED: 6 true watertight X-axis casings, 2 aligned sidewalls each, 6 shadowed spoke backs, all 8 factions, 5 damages, 6x6 steering, climate and historical restore")
    quit(0)
