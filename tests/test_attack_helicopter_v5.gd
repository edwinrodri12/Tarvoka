extends SceneTree

# A01 V5 native Godot acceptance; ensures landing/engine mounts are actual
# connected, closed meshes and never added to Android tactical low-detail LOD.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V5=preload("res://scripts/ui/AttackHelicopterLandingV5.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V5: "+why)

func _vertex(v: Vector3) -> String:
    return "%d:%d:%d" % [
        roundi(v.x*100000),roundi(v.y*100000),roundi(v.z*100000)]

func _edge(edges: Dictionary,a: String,b: String) -> void:
    var key: String=a+"|"+b if a<b else b+"|"+a
    edges[key]=int(edges.get(key,0))+1

func _closed(mesh: ArrayMesh) -> bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var vert: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    if vert.size()<100 or vert.size()%3!=0:
        return false
    var edges: Dictionary={}
    for n in range(0,vert.size(),3):
        var a: String=_vertex(vert[n])
        var b: String=_vertex(vert[n+1])
        var c: String=_vertex(vert[n+2])
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
    var light: Node3D=Models.build("attack_heli",0,true,10)
    _check(light!=null and not V5.has_model(light) and not V4.has_model(light),
        "Android battle LOD keeps old cheap geometry")
    if light!=null:
        _check(light.find_child("Fuselaje",true,false)!=null,
            "existing Android fuselage preserved")
        light.free()
    var faction_colors: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"V5 builds for faction "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V1.has_model(model) and V4.has_model(model) and V5.has_model(model),
            "real layered A01 V1 through V5 are present")
        if not V5.has_model(model):
            # A missing sculpt must fail cleanly, not hang on null checks.
            model.queue_free()
            await process_frame
            continue
        var layer: Node3D=model.find_child(V5.ROOT,true,false) as Node3D
        var count: int=Models.inspect_meshes(model)
        _check(count>170,"detailed real 3D meshes, not decals")
        _check(layer!=null and layer.visible,"new V5 geometry enabled")
        for side in [-1,1]:
            var skid: MeshInstance3D=model.find_child(V5.SKID+str(side),
                true,false) as MeshInstance3D
            var saddle: MeshInstance3D=model.find_child(
                V5.ENGINE_SADDLE+str(side),true,false) as MeshInstance3D
            var gasket: MeshInstance3D=model.find_child(
                V5.ENGINE_GASKET+str(side),true,false) as MeshInstance3D
            _check(skid!=null and skid.mesh is ArrayMesh,
                "true curved 3D skid tube both sides")
            if skid!=null and skid.mesh is ArrayMesh:
                _check(_closed(skid.mesh as ArrayMesh),
                    "continuous capped skid tube has no open ends")
                var box: AABB=skid.mesh.get_aabb()
                _check(box.size.z>2.4 and box.size.y>0.22,
                    "skid long and tips curve UP, not flat rectangle")
                _check(box.size.x<0.22,"skid remains a slim structural tube")
            _check(saddle!=null and saddle.mesh is ArrayMesh and
                gasket!=null and gasket.mesh is ArrayMesh,
                "enclosed engine shoulder and gasket replace floating gap")
            if saddle!=null and saddle.mesh is ArrayMesh:
                _check(_closed(saddle.mesh as ArrayMesh),
                    "16? sealed engine-to-hull mount has closed caps and joints")
            if gasket!=null and gasket.mesh is ArrayMesh:
                _check(_closed(gasket.mesh as ArrayMesh),
                    "rubber gasket is a real closed mesh")
            var old: Node3D=model.find_child("A01_Patin_%d" % side,
                true,false) as Node3D
            _check(old!=null and not old.visible,
                "old box skid hidden, no overlapping twin")
            for n in range(2):
                _check(model.find_child(V5.ARM+"%d_%d" % [side,n],
                    true,false)!=null,"angled landing support "+str(n))
                _check(model.find_child(
                    "A01V5_AnclajeSuperior_%d_%d" % [side,n],
                    true,false)!=null,"support joins the fuselage")
                _check(model.find_child(
                    "A01V5_BrazoMontajeMotor_%d_%d" % [side,n],
                    true,false)!=null,"engine mechanical mounts retain two anchors")
            var marker: MeshInstance3D=model.find_child(
                "A01V5_MarcaPatinFaccion_"+str(side),
                true,false) as MeshInstance3D
            _check(marker!=null and marker.material_override is StandardMaterial3D,
                "small real faction paint marking on skid")
            if side==1 and marker!=null and marker.material_override is StandardMaterial3D:
                faction_colors[(marker.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        for n in range(2):
            _check(model.find_child(V5.CROSSBAR+str(n),true,false)!=null,
                "cross-braced skids are physically tied together")
        _check(V5.apply(model,Models.faction_paint_color(faction)),
            "reapplying V5 is safe")
        _check(count==Models.inspect_meshes(model),
            "no geometry duplication on reapply")
        _check(V5.set_enabled(model,false),"preview can return to prior skids")
        var oldskid: Node3D=model.find_child("A01_Patin_1",
            true,false) as Node3D
        _check(not layer.visible and oldskid.visible,
            "previous straight skid visible for comparison")
        _check(V5.set_enabled(model,true),"preview can reenable V5")
        _check(layer.visible and not oldskid.visible,
            "only curved skid shown after return")
        var before: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.36),
            "legacy moving rotors and flight anim remain operational")
        _check(model.position!=before,"flight height animation intact")
        _check(Models.pose_model("attack_heli",model,"attack",0.35),
            "front cannon animation continues")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==before and layer.visible,
            "restore reestablishes starting position without losing V5 parts")
        model.queue_free()
        await process_frame
    _check(faction_colors.size()==8,"eight faction accents remain unique")
    if failures>0:
        push_error("A01 V5 failed %d assertions" % failures)
        quit(1)
        return
    print("PASS A01 V5: 8 factions, two closed curved landing rails, 4 angled supports, crossbars, sealed engine mounts/gaskets, old LOD and animation safety")
    quit(0)
