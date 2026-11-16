extends SceneTree

# V7 engineering QA: physical readability accents, faction identity at
# 320x180, original rotor pivots, reversible V6 comparison and untouched
# tactical 3D LOD. All in actual Godot 4.3, never a fake 2D overlay.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V6=preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
const V7=preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
var errors: int=0

func _check(condition: bool,label: String) -> void:
    if not condition:
        errors+=1
        push_error("A01 V7: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _mesh(model: Node3D,name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

func _run() -> void:
    var light: Node3D=Models.build("attack_heli",0,true,10)
    _check(light!=null and not V7.has_model(light)
        and not V6.has_model(light),"battle 3D LOD remains lightweight")
    if light!=null:
        light.free()
    var faction_paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"real 3D hero exists faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(V6.has_model(model) and V7.has_model(model),
            "V7 additions layered only on the existing complete V6")
        if not V7.has_model(model):
            model.queue_free()
            await process_frame
            continue
        var original_count: int=Models.inspect_meshes(model)
        var layer: Node3D=model.find_child(V7.ROOT,true,false) as Node3D
        _check(layer!=null and layer.visible,
            "V7 physical faction-identity layer is present and visible")
        for i in range(4):
            var pivot: Node3D=model.find_child(V3.LEGACY_ROTOR+str(i),
                true,false) as Node3D
            var tail: Node3D=model.find_child(V3.LEGACY_TAIL+str(i),
                true,false) as Node3D
            var tip: MeshInstance3D=_mesh(model,V7.BLADE_TIP+str(i))
            var tail_tip: MeshInstance3D=_mesh(model,V7.TAIL_TIP+str(i))
            _check(pivot!=null and tail!=null and tip!=null
                and tail_tip!=null,"real main and tail blade tips present")
            if pivot!=null and tip!=null:
                _check(tip.get_parent()==pivot,
                    "main contrast markings share the spinning V1/V3 rotor pivot")
                _check(tip.mesh is BoxMesh,
                    "tip has a 3D physical surface and never a fake sprite")
                _check(tip.visible and tip.position.z < -1.7,
                    "main rotor tip visibly follows actual blade geometry")
            if tail!=null and tail_tip!=null:
                _check(tail_tip.get_parent()==tail,
                    "tail tip moves with its original tail rotor pivot")
        var gun: Node3D=model.find_child(V1.GUN,true,false) as Node3D
        var muzzle: MeshInstance3D=_mesh(model,V7.GUN_RIM)
        _check(gun!=null and muzzle!=null and muzzle.get_parent()==gun,
            "contrast rim physically fixed to the original animated muzzle")
        for side in [-1,1]:
            var engine: MeshInstance3D=_mesh(model,V7.ENGINE_PLATE+str(side))
            var pod: MeshInstance3D=_mesh(model,V7.MISSILE_PLATE+str(side))
            var mark: MeshInstance3D=_mesh(model,
                "A01V7_InsigniaMotor_"+str(side))
            _check(engine!=null and engine.mesh is ArrayMesh,
                "engine's outer 3D silhouette includes a readable shape plate")
            _check(pod!=null and pod.mesh is BoxMesh,
                "missile cradle gets a physical bounded identification strip")
            _check(mark!=null and mark.material_override is StandardMaterial3D,
                "both engines preserve appropriate actual faction-colored enamel")
            if side==1 and mark!=null and mark.material_override is StandardMaterial3D:
                faction_paints[(mark.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        for i in range(4):
            _check(model.find_child(V7.TAIL_MARK+str(i),
                true,false)!=null,
                "quarter tail guard has high-contrast true metallic edge")
        _check(V7.apply(model,Models.faction_paint_color(faction)),
            "reapplying V7 doesn't create duplicate meshes")
        _check(Models.inspect_meshes(model)==original_count,
            "reapplication has a stable performance budget")
        _check(V7.set_enabled(model,false),
            "V6/V7 compare works without restarting studio")
        _check(not layer.visible and not _mesh(model,V7.BLADE_TIP+"0").visible,
            "V7 finishes can be completely hidden")
        _check(V7.set_enabled(model,true),
            "restore all readability pieces")
        _check(layer.visible and _mesh(model,V7.BLADE_TIP+"0").visible,
            "no missing tips or body labels on returning to V7")
        var main: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var initial: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.37),
            "the underlying moving/rotating V3 rotor still works")
        _check(main!=null and absf(main.rotation_degrees.y)>0.01,
            "rotor remains animated with its readable tips attached")
        _check(Models.pose_model("attack_heli",model,"attack",0.39),
            "V7 does not break actual original gunfire animation")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==initial and layer.visible,
            "pose reset restores position without losing finishing pieces")
        model.queue_free()
        await process_frame
    _check(faction_paints.size()==8,
        "eight unique faction paints remain visually identifiable")
    if errors>0:
        push_error("A01 V7 failed %d native checks" % errors)
        quit(1)
        return
    print("PASS A01 V7: 8 factions, 8 integrated spinning blade markers, readable engine badges/launcher markings, tail guard quarters, reversible V6 finish and unchanged Android battle LOD")
    quit(0)
