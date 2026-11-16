extends SceneTree

# A01 V4 native Godot 4.3 regression: model replacement, eight paints,
# sealed engine/armor meshes, V1-V4 reversible studio and mobile battle LOD.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V4: "+why)

func _vertex(v: Vector3) -> String:
    return "%d:%d:%d" % [
        roundi(v.x*100000),roundi(v.y*100000),roundi(v.z*100000)]

func _edge(edges: Dictionary,a: String,b: String) -> void:
    var key: String=a+"|"+b if a<b else b+"|"+a
    edges[key]=int(edges.get(key,0))+1

func _watertight(mesh: ArrayMesh) -> bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var vert: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    if vert.size()<60 or vert.size()%3!=0:
        return false
    var edges: Dictionary={}
    for i in range(0,vert.size(),3):
        var a: String=_vertex(vert[i])
        var b: String=_vertex(vert[i+1])
        var c: String=_vertex(vert[i+2])
        if a==b or b==c or a==c:
            return false
        _edge(edges,a,b)
        _edge(edges,b,c)
        _edge(edges,c,a)
    for n in edges.values():
        if int(n)!=2:
            return false
    return not edges.is_empty()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var cheap: Node3D=Models.build("attack_heli",0,true,10)
    _check(cheap!=null,"old mobile helicopter builds")
    if cheap!=null:
        _check(not V4.has_model(cheap) and not V3.has_model(cheap)
            and not V2.has_model(cheap) and not V1.has_model(cheap),
            "mobile tactical helicopter unchanged by studio-only sculptures")
        cheap.free()
    var paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"native V4 built for faction "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V1.has_model(model) and V2.has_model(model) and
            V3.has_model(model) and V4.has_model(model),
            "every earlier A01 source installed and retained")
        var parts_count: int=Models.inspect_meshes(model)
        _check(parts_count>160,"physical layered model instead of 2D placeholder")
        for side in [-1,1]:
            var engine: MeshInstance3D=model.find_child(
                V4.NACELLE+str(side),true,false) as MeshInstance3D
            var intake: MeshInstance3D=model.find_child(
                V4.INTAKE+str(side),true,false) as MeshInstance3D
            var panel: MeshInstance3D=model.find_child(
                V4.SIDE_PANEL+str(side),true,false) as MeshInstance3D
            _check(engine!=null and engine.mesh is ArrayMesh,
                "closed engine nacelle exists on both sides")
            if engine!=null and engine.mesh is ArrayMesh:
                _check(_watertight(engine.mesh as ArrayMesh),
                    "engine nacelle closed in all 16 radial segments")
            _check(intake!=null and intake.mesh is ArrayMesh,
                "air intake has real annular lip and recessed throat")
            _check(panel!=null and panel.mesh is ArrayMesh,
                "new side armor is an actual 3D polygon")
            if panel!=null and panel.mesh is ArrayMesh:
                _check(_watertight(panel.mesh as ArrayMesh),
                    "side armor panel is watertight")
            for prefix in V4.ORIGINAL_ENGINE:
                var old: Node3D=model.find_child(prefix+str(side),true,false)
                _check(old!=null and not old.visible,
                    "old disconnected box fully replaced: "+prefix)
            for n in range(3):
                _check(model.find_child(
                    "A01_V2_RejillaMotor_%d_%d" % [side,n],true,false)!=null,
                    "old panel vents kept for reversible V2 comparison")
            _check(model.find_child("A01V4_RejillaCurva_%d_4" % side,
                true,false)!=null,"curved 5-slot engine vents installed")
            _check(model.find_child("A01V4_BordeMetalEscape_"+str(side),
                true,false)!=null,"visible rear exhaust mouth and deep nozzle")
            _check(model.find_child("A01V4_ToberaEscape_"+str(side),
                true,false)!=null,"integrated exhaust assembly")
            var accent: MeshInstance3D=model.find_child(
                V4.FACTION_STRIPE+str(side),true,false) as MeshInstance3D
            _check(accent!=null and accent.material_override is StandardMaterial3D,
                "narrow physically sculpted faction identification panel")
            if side==1 and accent!=null and accent.material_override is StandardMaterial3D:
                paints[(accent.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        var transmission: MeshInstance3D=model.find_child(
            V4.TRANSMISSION,true,false) as MeshInstance3D
        _check(transmission!=null and transmission.mesh is ArrayMesh,
            "old gearbox rectangle replaced with sealed sculpted fairing")
        if transmission!=null and transmission.mesh is ArrayMesh:
            _check(_watertight(transmission.mesh as ArrayMesh),
                "gearbox 3D mesh is closed")
        _check(V4.apply(model,Models.faction_paint_color(faction)),
            "applying V4 is safely idempotent")
        _check(Models.inspect_meshes(model)==parts_count,
            "idempotent render budget unchanged")
        _check(V4.set_enabled(model,false),"revert engine and armor to prior V2")
        var v4layer: Node3D=model.find_child(V4.ROOT,true,false) as Node3D
        _check(v4layer!=null and not v4layer.visible,
            "V4 assembly disabled during comparison")
        var old_motor: Node3D=model.find_child("A01_ProteccionMotor_1",
            true,false) as Node3D
        _check(old_motor!=null and old_motor.visible,
            "original engine is actually visible in comparison mode")
        _check(V4.set_enabled(model,true),"return to V4 without extra meshes")
        _check(v4layer.visible and not old_motor.visible,
            "V4 restored, no old engine overlap")
        _check(Models.pose_model("attack_heli",model,"move",0.38),
            "previous rotor animation still works with V4 skin")
        _check(Models.pose_model("attack_heli",model,"attack",0.34),
            "front cannon still responds with V4 geometry")
        Models.restore_model_pose("attack_heli",model)
        _check(v4layer.visible,"flight/fire cycle preserves V4 armor")
        model.queue_free()
        await process_frame
    _check(paints.size()==8,"eight faction colors survive V4 color reduction")
    if failures>0:
        push_error("A01 V4 QA failed %d assertions" % failures)
        quit(1)
        return
    print("PASS A01 V4: eight factions, closed engine nacelles and gearbox, watertight 3D armor, reversible old engines, visible intake/outlet geometry and preserved mobile battle LOD")
    quit(0)
