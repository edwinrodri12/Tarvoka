extends SceneTree

# Godot 4.3 native regression for A01 V8: real closed physical faction
# identity on both wings, nacelles and fin. Tactical Android LOD unchanged.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V7=preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
const V8=preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
var errors: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        errors+=1
        push_error("A01 V8: "+description)

func _p(v: Vector3) -> String:
    return "%d:%d:%d" % [roundi(v.x*100000),roundi(v.y*100000),roundi(v.z*100000)]

func _edge(edges: Dictionary,a: String,b: String) -> void:
    var key: String=a+"|"+b if a<b else b+"|"+a
    edges[key]=int(edges.get(key,0))+1

func _closed(mesh: ArrayMesh) -> bool:
    if mesh==null or mesh.get_surface_count()<1:
        return false
    var vertices: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    if vertices.size()<12 or vertices.size()%3!=0:
        return false
    var edges: Dictionary={}
    for k in range(0,vertices.size(),3):
        var a: String=_p(vertices[k])
        var b: String=_p(vertices[k+1])
        var c: String=_p(vertices[k+2])
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
    var battle: Node3D=Models.build("attack_heli",0,true,10)
    _check(battle!=null and not V8.has_model(battle) and not V7.has_model(battle),
        "old fast battle model still used in Android")
    if battle!=null:
        battle.free()
    var palette: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"3D hero builds for army "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V1.has_model(model) and V3.has_model(model) and
            V7.has_model(model) and V8.has_model(model),
            "V8 builds over intact V1–V7 mechanical sculpture")
        if not V8.has_model(model):
            model.queue_free()
            await process_frame
            continue
        var layer: Node3D=model.find_child(V8.ROOT,true,false) as Node3D
        var n: int=Models.inspect_meshes(model)
        _check(layer!=null and layer.visible,"V8 shoulder and wing layer visible")
        for side in [-1,1]:
            var wing: MeshInstance3D=model.find_child(V8.WING+str(side),
                true,false) as MeshInstance3D
            var engine: MeshInstance3D=model.find_child(V8.ENGINE+str(side),
                true,false) as MeshInstance3D
            var fin: MeshInstance3D=model.find_child(V8.FIN+str(side),
                true,false) as MeshInstance3D
            _check(wing!=null and engine!=null and fin!=null,
                "3 real closed wing / turbine / tail surfaces for each side")
            if wing!=null and wing.mesh is ArrayMesh:
                _check(_closed(wing.mesh as ArrayMesh),
                    "faction wingtip is closed, not floating flat 2D paint")
                var bounds: AABB=wing.mesh.get_aabb()
                _check(bounds.size.x>0.30 and bounds.size.z>0.20,
                    "wingtip faction area has genuine optical width")
            if engine!=null and engine.mesh is ArrayMesh:
                _check(_closed(engine.mesh as ArrayMesh),
                    "nacelle shoulder is a closed bent original 3D mesh")
                var vv: PackedVector3Array=(engine.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                var max_gap: float=0
                for vertex in vv:
                    var yy: float=V8._engine_skin(vertex.z,absf(vertex.x)-0.335)
                    max_gap=maxf(max_gap,absf(vertex.y-yy))
                _check(max_gap<=0.012,
                    "shoulder enamel fits real V4 shell within 12mm, no floating polygons")
            if fin!=null:
                _check(fin.get_parent().name=="A01_AletaVertical",
                    "tail paint inherits exact original rotated fin transform")
            var legacy: Node3D=model.find_child(
                "A01V3_FranjaFaccion_%d" % side,true,false) as Node3D
            _check(legacy!=null and not legacy.visible,
                "V3 narrow stripe hidden so new V8 wing panel never overlaps")
            if side==1 and wing!=null and wing.material_override is StandardMaterial3D:
                palette[(wing.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        _check(V8.apply(model,Models.faction_paint_color(faction)),
            "V8 idempotent apply does not duplicate panel art")
        _check(Models.inspect_meshes(model)==n,"stable mesh budget after idempotent apply")
        _check(V8.set_enabled(model,false),"V7-only comparison can be displayed")
        _check(not layer.visible,"all V8 physical bodies hidden")
        var old: Node3D=model.find_child("A01V3_FranjaFaccion_1",true,false)
        _check(old!=null and old.visible,
            "historical V3 small wing stripe returns when comparing to V7")
        _check(V8.set_enabled(model,true),"V8 can be restored exactly")
        _check(layer.visible and not old.visible,
            "V8 restores only new wing panels, no doubled 3D overlays")
        var initial: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.42),
            "V8 does not break rotor-driven movement")
        _check(Models.pose_model("attack_heli",model,"attack",0.31),
            "V8 does not break firing")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==initial,"V1 flying rig remains reversible")
        model.queue_free()
        await process_frame
    _check(palette.size()==8,"all eight army colors remain distinct")
    if errors>0:
        push_error("A01 V8 native test failed %d checks" % errors)
        quit(1)
        return
    print("PASS A01 V8: 8 factions, 2 closed wing enamel panels, 2 curved motor shoulders, 2 fin labels, reversible V7 comparison and unchanged Android battle LOD")
    quit(0)
