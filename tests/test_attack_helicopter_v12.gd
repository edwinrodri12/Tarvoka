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

# All coordinates are compared in the MODEL'S original local space.
# This avoids false positives from scene camera angles or faction transforms.
func _model_bounds(model: Node3D,part: MeshInstance3D) -> AABB:
    var to_model: Transform3D=model.global_transform.affine_inverse()*part.global_transform
    return to_model*part.get_aabb()

func _minimum_box_gap(a: AABB,b: AABB) -> float:
    var gap_x: float=maxf(0.0,maxf(b.position.x-a.end.x,a.position.x-b.end.x))
    var gap_y: float=maxf(0.0,maxf(b.position.y-a.end.y,a.position.y-b.end.y))
    var gap_z: float=maxf(0.0,maxf(b.position.z-a.end.z,a.position.z-b.end.z))
    return Vector3(gap_x,gap_y,gap_z).length()

func _verify_underbody(model: Node3D,label: String) -> void:
    # Skid nose rails are at x~+/-0.65, while the gimbal is centered at x=0.
    # Test COMPLETE transformed mesh bounds (not only arbitrary node origins).
    for side in [-1,1]:
        var skid: MeshInstance3D=model.find_child(
            "A01V5_PatinTubularCurvado_%d" % side,true,false) as MeshInstance3D
        var upper: MeshInstance3D=model.find_child(
            "A01V12_PilarCunaSuperior_%d" % side,true,false) as MeshInstance3D
        var forward: MeshInstance3D=model.find_child(
            "A01V12_PilarCunaDelantero_%d" % side,true,false) as MeshInstance3D
        var guide: MeshInstance3D=model.find_child(
            "A01V12_GuiaMovilCanon_%d" % side,true,false) as MeshInstance3D
        _check(skid!=null and upper!=null and forward!=null and guide!=null,
            "underbody native meshes present: side=%d, pose=%s" % [side,label])
        if skid==null or upper==null or forward==null or guide==null:
            continue
        var a: AABB=_model_bounds(model,skid)
        for piece in [upper,forward,guide]:
            var gap: float=_minimum_box_gap(a,_model_bounds(model,piece))
            _check(gap>=0.035,
                "physical skid-vs-cradle clearance >=0.035 units: %s %d/%s gap=%.4f" %
                [label,side,piece.name,gap])
    var skids_left: MeshInstance3D=model.find_child(
        "A01V5_PatinTubularCurvado_-1",true,false) as MeshInstance3D
    var skids_right: MeshInstance3D=model.find_child(
        "A01V5_PatinTubularCurvado_1",true,false) as MeshInstance3D
    var gimbal: MeshInstance3D=model.find_child(
        V12.GIMBAL,true,false) as MeshInstance3D
    var bridge: MeshInstance3D=model.find_child(
        "A01V12_PuenteTransversalCuna",true,false) as MeshInstance3D
    if gimbal!=null and bridge!=null:
        _check(_minimum_box_gap(_model_bounds(model,gimbal),
                _model_bounds(model,bridge))>=0.020,
            "fixed bridge clears original animated gimbal: "+label)
    if gimbal!=null and skids_left!=null and skids_right!=null:
        for skid in [skids_left,skids_right]:
            _check(_minimum_box_gap(_model_bounds(model,gimbal),
                    _model_bounds(model,skid))>=0.12,
                "both skids stay clear of central cannon during "+label)

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
        # V12.1: genuine side gussets clear the original moving gun.
        var gusset: MeshInstance3D=model.find_child(
            "A01V12_PilarCunaDelantero_1",true,false) as MeshInstance3D
        var guide: MeshInstance3D=model.find_child(
            "A01V12_GuiaMovilCanon_1",true,false) as MeshInstance3D
        var bridge: MeshInstance3D=model.find_child(
            "A01V12_PuenteTransversalCuna",true,false) as MeshInstance3D
        _check(gusset!=null and guide!=null and bridge!=null
            and gusset.mesh is CylinderMesh and bridge.mesh is CylinderMesh,
            "V12.1 three-dimensional cradle bridge and exposed gussets")
        _check(gusset!=null and absf(gusset.position.x)>=0.295
            and moving!=null and guide!=null and guide.get_parent()==moving,
            "braces clear 0.19m gun shell and moving guides inherit original pivot")
        var guide_rest: Vector3=guide.global_position if guide!=null else Vector3.ZERO
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
        _verify_underbody(model,"reposo")
        _check(Models.pose_model("attack_heli",model,"attack",0.36),
            "original A01 gun still pitches and fires in attack animation")
        _check(absf(gun.rotation_degrees.x)>0.2 and moving.get_parent()==gun,
            "V12 cannon cover rotates with actual animated gun")
        _check(guide!=null and guide.global_position.distance_to(guide_rest)>0.005,
            "V12.1 guide rail physically follows pitched gun, not static fuselage")
        _verify_underbody(model,"disparo")
        Models.restore_model_pose("attack_heli",model)
        # Sample the full pitch curve, not only one firing instant.
        for phase in [0.08,0.20,0.34,0.48,0.62,0.78,0.92]:
            _check(Models.pose_model("attack_heli",model,"attack",phase),
                "attack pose remains valid throughout cannon pitch sweep")
            _verify_underbody(model,"disparo_%.2f" % phase)
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
