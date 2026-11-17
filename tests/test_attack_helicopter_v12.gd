extends SceneTree

# A01 V12 Godot 4.3 native geometry and reversible close-view comparison.
# No battle rules, no alternative renderer, no change to original firing.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const V11=preload("res://scripts/ui/AttackHelicopterTailV11.gd")
const V12=preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
var failures: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V12: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var low: Node3D=Models.build("attack_heli",0,true,10)
    _check(low!=null and not V12.has_model(low),
        "mobile tactical LOD10 does not allocate the V12 front sculpt")
    if low!=null:
        low.free()
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and V10.has_model(model)
            and V11.has_model(model) and V12.has_model(model),
            "faction %d contains authentic V10/V11/V12 hero model" % faction)
        if model==null or not V12.has_model(model):
            if model!=null:
                model.free()
            continue
        root.add_child(model)
        var body: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
        var gun: Node3D=model.find_child(V1.GUN,true,false) as Node3D
        var nose: Node3D=model.find_child(V12.ROOT,true,false) as Node3D
        var moving: Node3D=model.find_child(V12.GUN_ROOT,true,false) as Node3D
        var cheek_l: MeshInstance3D=model.find_child(
            V12.LEFT_CHEEK,true,false) as MeshInstance3D
        var cheek_r: MeshInstance3D=model.find_child(
            V12.RIGHT_CHEEK,true,false) as MeshInstance3D
        _check(body!=null and nose!=null and nose.get_parent()==body
            and moving!=null and moving.get_parent()==gun,
            "new nose stays fixed, cannon gimbal inherits V1 pitch pivot")
        _check(cheek_l!=null and cheek_r!=null
            and cheek_l.mesh is ArrayMesh and cheek_r.mesh is ArrayMesh
            and cheek_l.mesh.get_surface_count()>0
            and cheek_r.mesh.get_surface_count()>0,
            "both front armour cheeks are sealed native triangle meshes")
        var gimbal: MeshInstance3D=model.find_child(
            V12.GIMBAL,true,false) as MeshInstance3D
        var optic: MeshInstance3D=model.find_child(
            V12.OPTIC_RING,true,false) as MeshInstance3D
        _check(gimbal!=null and gimbal.mesh is CylinderMesh
            and optic!=null and optic.mesh is TorusMesh,
            "articulated gimbal and genuine hollow 3D optic retainer")
        for side in [-1,1]:
            var trunnion: MeshInstance3D=model.find_child(
                V12.TRUNNION+str(side),true,false) as MeshInstance3D
            _check(trunnion!=null and trunnion.get_parent()==moving
                and trunnion.mesh is CylinderMesh,
                "left/right rotary bearing belongs to animated gun")
        var meshes: int=Models.inspect_meshes(model)
        _check(V12.apply(model,Models.faction_paint_color(faction))
            and Models.inspect_meshes(model)==meshes,
            "idempotent V12 apply does not duplicate armoured parts")
        _check(V12.set_enabled(model,false) and not nose.visible
            and not moving.visible and V11.has_model(model)
            and V10.has_model(model),
            "V11 comparison hides only V12 parts, preserving previous model")
        _check(V12.set_enabled(model,true) and nose.visible
            and moving.visible,"V12 comparison restores the exact parts")
        _check(Models.pose_model("attack_heli",model,"attack",0.36),
            "original A01 gun still pitches and fires in attack animation")
        _check(absf(gun.rotation_degrees.x)>0.2 and moving.get_parent()==gun,
            "V12 cannon cover rotates with actual animated gun")
        Models.restore_model_pose("attack_heli",model)
        _check(Models.pose_model("attack_heli",model,"move",0.52),
            "original A01 aerial movement remains intact")
        Models.restore_model_pose("attack_heli",model)
        _check(V10.has_model(model) and V11.has_model(model)
            and V12.has_model(model),
            "earlier original airframe, gearbox and optics remain intact")
        model.queue_free()
        await process_frame
    if failures>0:
        push_error("A01 V12 failed %d genuine native checks" % failures)
        quit(1)
        return
    print("PASS A01 V12: eight armies, two sealed cheeks, original gun-pivot gimbal, optic bezel, reversible V11 comparison, unchanged Android LOD and move/attack")
    quit(0)
