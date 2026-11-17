extends SceneTree

# A01 V11 integration: actual geometry on the original spinning tail,
# preserved V10 optical finish, and unchanged lightweight Android LOD.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const V11=preload("res://scripts/ui/AttackHelicopterTailV11.gd")
var failures: int=0

func _check(ok: bool,desc: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V11: "+desc)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var low: Node3D=Models.build("attack_heli",0,true,10)
    _check(low!=null and not V11.has_model(low),
        "Android tactical art <=10 has no V11 mesh")
    if low!=null:
        low.free()
    var paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and V10.has_model(model) and V11.has_model(model),
            "V11 and V10 coexist on faction %d" % faction)
        if model==null or not V11.has_model(model):
            if model!=null: model.free()
            continue
        root.add_child(model)
        var before: int=Models.inspect_meshes(model)
        var tail: Node3D=model.find_child(V1.TAIL_ROTOR,true,false) as Node3D
        var hub: Node3D=model.find_child(V11.TAIL_HUB,true,false) as Node3D
        var fixed: Node3D=model.find_child(V11.ROOT,true,false) as Node3D
        var pylons: Node3D=model.find_child(V11.PYLONS,true,false) as Node3D
        var gearbox: MeshInstance3D=model.find_child(V11.GEARBOX,true,false) as MeshInstance3D
        var shaft: MeshInstance3D=model.find_child(V11.SHAFT,true,false) as MeshInstance3D
        _check(tail!=null and hub!=null and hub.get_parent()==tail,
            "tail pitch ring inherits the authentic animated rotor pivot")
        _check(fixed!=null and fixed.visible and gearbox!=null
            and shaft!=null and gearbox.mesh is SphereMesh
            and shaft.mesh is CylinderMesh,
            "real closed gearbox, drive shaft and three physical supports")
        _check(pylons!=null and pylons.visible,"pylon support geometry is present")
        for i in range(4):
            var pivot: Node3D=model.find_child(
                V3.LEGACY_TAIL+str(i),true,false) as Node3D
            var pitch: Node3D=model.find_child(
                V11.PITCH_LINK+str(i),true,false) as Node3D
            _check(pivot!=null and pitch!=null and pitch.get_parent()==pivot,
                "blade %d pitch link follows its real quarter-turn arm" % i)
        for side in [-1,1]:
            for i in range(4):
                var ring: MeshInstance3D=model.find_child(
                    V11.RETAINER+"%d_%d" % [side,i],true,false) as MeshInstance3D
                _check(ring!=null and ring.mesh is TorusMesh,
                    "rocket mouth %d/%d is a true 3D hollow retainer" % [side,i])
        _check(V11.apply(model,Models.faction_paint_color(faction)),
            "V11 apply is idempotent")
        _check(Models.inspect_meshes(model)==before,
            "V11 repeated apply never duplicates geometry")
        var paint: MeshInstance3D=model.find_child("A01V8_AlaInsignia_1",true,false) as MeshInstance3D
        if paint!=null and paint.material_override is StandardMaterial3D:
            paints[(paint.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        _check(V11.set_enabled(model,false) and not fixed.visible
            and not hub.visible and not pylons.visible,
            "V10 vs V11 comparison completely hides each new root")
        for i in range(4):
            var pitch: Node3D=model.find_child(
                V11.PITCH_LINK+str(i),true,false) as Node3D
            _check(pitch!=null and not pitch.visible,
                "comparison hides each rotor-blade-attached mechanism")
        _check(V11.set_enabled(model,true) and fixed.visible
            and hub.visible and pylons.visible,
            "V11 comparison restores exactly the same geometry")
        _check(Models.pose_model("attack_heli",model,"move",0.46),
            "original V1 animated rotors work with V11 gear train")
        _check(Models.pose_model("attack_heli",model,"attack",0.34),
            "original V1 attack works with V11 pylons")
        Models.restore_model_pose("attack_heli",model)
        _check(V10.has_model(model) and V11.has_model(model) and fixed.visible,
            "art and animation preserve the V10 high-quality glass")
        model.queue_free()
        await process_frame
    _check(paints.size()==8,"V8 unique identity is preserved for eight armies")
    if failures>0:
        push_error("A01 V11 native QA failed %d checks" % failures)
        quit(1)
        return
    print("PASS A01 V11: eight factions, attached tail pitch links, real gearbox and shaft, sixteen launcher details, reversible comparison and unchanged Android LOD")
    quit(0)
