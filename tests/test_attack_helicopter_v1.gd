extends SceneTree

# A01 V1 native-geometry regression. Does not touch game rules or stats.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Art=preload("res://scripts/ui/AttackHelicopterV1.gd")
var failures: int=0

func _check(ok: bool, why: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 HELICOPTER V1: "+why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var cheap: Node3D=Models.build("attack_heli",0,true,10)
    _check(cheap!=null,"historical lightweight helicopter builds")
    if cheap!=null:
        _check(not Art.has_model(cheap),"battle LOD never allocates new hero sculpt")
        _check(cheap.find_child("Fuselaje",true,false)!=null,
            "older compact battle hull stays intact")
        cheap.free()
    var colors: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"V1 builds for faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(Art.has_model(model),"native art flag and root")
        _check(model.find_child("Fuselaje",true,false)==null,
            "old placeholder isn't hidden under the finished 3D geometry")
        for name in ["A01_MonocascoFacetado","A01_CarenadoCristalTandem",
                Art.MAIN_ROTOR,Art.TAIL_ROTOR,"A01_VigaColaSellada",
                Art.GUN,Art.FLASH,"A01_Patin_-1","A01_Patin_1"]:
            _check(model.find_child(name,true,false)!=null,
                "physical component "+name)
        for side in [-1,1]:
            for tube in range(4):
                _check(model.find_child("A01_Lanzador_%d_%d" % [side,tube],
                    true,false)!=null,"8 left/right missile tubes")
        var paint: MeshInstance3D=model.find_child(
            "A01_PanelFaccion_1",true,false) as MeshInstance3D
        _check(paint!=null,"full faction metal side panel")
        if paint!=null and paint.material_override is StandardMaterial3D:
            colors[(paint.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        _check(Models.inspect_meshes(model)>45,
            "real mesh sculpture rather than a decal or 2D rendering")
        var rotor: Node3D=model.find_child(Art.MAIN_ROTOR,true,false) as Node3D
        var tail: Node3D=model.find_child(Art.TAIL_ROTOR,true,false) as Node3D
        var flash: Node3D=model.find_child(Art.FLASH,true,false) as Node3D
        _check(rotor.get_child_count()>=5,"four real main rotor blades and hub")
        _check(tail.get_child_count()>=5,"four real tail rotor blades and hub")
        _check(not flash.visible,"weapon does not flash at idle")
        var before: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.41),
            "visual move action on shared model bridge")
        _check(not is_equal_approx(rotor.rotation_degrees.y,0.0),
            "main rotor rotates during flight")
        _check(not is_equal_approx(tail.rotation_degrees.x,0.0),
            "tail rotor rotates during flight")
        _check(model.position!=before,"flight has a physical body response")
        _check(Models.pose_model("attack_heli",model,"attack",0.34),
            "visual fire animation")
        _check(flash.visible,"timed muzzle effect appears during burst")
        _check(Models.pose_model("attack_heli",model,"attack",0.95),
            "attack timing ends")
        _check(not flash.visible,"muzzle flash vanishes after burst")
        _check(Models.pose_model("attack_heli",model,"hit_explosive",0.42),
            "impact animation")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==before,"exact resting location restored")
        _check(rotor.rotation_degrees==Vector3.ZERO and
            tail.rotation_degrees==Vector3.ZERO and not flash.visible,
            "animation restoration leaves no floating parts or effects")
        model.queue_free()
        await process_frame
    _check(colors.size()==8,"paint accents genuinely differ for eight factions")
    if failures>0:
        push_error("A01 HERO V1 failed %d checks" % failures)
        quit(1)
        return
    print("PASS A01 V1: 8 faction builds, closed sculpt, 2 physical rotors, 8 tubes, responsive shots, low-detail battle fallback and full pose restoration")
    quit(0)
