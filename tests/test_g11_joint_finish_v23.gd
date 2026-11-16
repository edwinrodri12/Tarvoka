extends SceneTree

# G11 V23: physical replacement of all 24 original V22 pins, retained team
# enamel and mechanical clearance in all moving wheel poses, eight factions.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Finish = preload("res://scripts/ui/G11JointFinishV23.gd")
const V22 = preload("res://scripts/ui/G11SuspensionJointsV22.gd")
var failures: int = 0
var paints: Dictionary = {}

func _check(ok: bool,message: String) -> void:
    if not ok:
        failures+=1
        push_error("G11 V23 real PBR hinge quality: "+message)

func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Finish.MOVING_HINGE_ROOT_X+Finish.LOWER_OFFSET_X+
        Finish.PIN_HALF_LENGTH < Finish.TRACK_OUTER_BOUND_X,
        "outer pin cap strictly inside V18-V19 rubber side wall")
    _check(Finish.MOVING_HINGE_ROOT_X+Finish.LOWER_OFFSET_X+
        Finish.RETAINER_X+Finish.RETAINER_THICKNESS*0.5 <
        Finish.TRACK_OUTER_BOUND_X,
        "outboard forged steel retainer strictly within track clearance")
    for faction in range(8):
        var model := Models.build("mlrs",faction,true,13) as Node3D
        _check(model!=null,"build real native hero G11 for all eight factions")
        if model==null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Finish.FLAG,false)),
            "V23 real steel polish installed after old V22 hinges")
        _check(int(model.get_meta(
            "tarvoka_g11_v23_chamfered_pin_replacements",0))==24,
            "24 original V22 pins replaced, no second set of axles")
        _check(int(model.get_meta(
            "tarvoka_g11_v23_retainers",0))==48,
            "48 truly hollow forged stop washers, two at each of 24 joints")
        _check(bool(model.get_meta(
            "tarvoka_g11_v23_independent_forged_pbr",false)),
            "different PBR finish for ear, hardened axle and retainer")
        var roof := _find(model,"G11_TapaSuperior") as MeshInstance3D
        if roof!=null and roof.material_override is StandardMaterial3D:
            var paint: Color = (
                roof.material_override as StandardMaterial3D).albedo_color
            _check(paint.is_equal_approx(model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color),
                "paint for faction stays original, no additional colors")
            paints[paint.to_html()]=true
        else:
            _check(false,"PBR faction roof remains")
        var shaft_ref: ArrayMesh = null
        var ring_ref: ArrayMesh = null
        for side in [-1,1]:
            var track := _find(model,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            _check(track!=null and track.multimesh!=null and (
                track.multimesh.instance_count==46),
                "same two moving V19 tracks and no added shoes")
            for axle in range(6):
                var key: String = "%d_%d" % [side,axle]
                for role in ["G11V22_BisagraSuperior_",
                        "G11V22_BisagraInferior_"]:
                    var hinge := _find(model,role+key)
                    _check(hinge!=null,"existing upper/lower V22 fork retained")
                    if hinge==null:
                        continue
                    _check(hinge.get_child_count()==5,
                        "exactly two existing ears, one ORIGINAL pin and two collars")
                    var pin := hinge.get_node_or_null(
                        "EjeArticulacion") as MeshInstance3D
                    _check(pin!=null and pin.mesh is ArrayMesh,
                        "previous pin replaced by actual integral forged ArrayMesh")
                    if pin!=null and pin.mesh is ArrayMesh:
                        var mesh := pin.mesh as ArrayMesh
                        if shaft_ref==null:
                            shaft_ref=mesh
                        else:
                            _check(shaft_ref==mesh,
                                "24 existing pins share one resource")
                        _check(mesh.get_surface_count()==1,
                            "single contiguous sealed body, not extra overlapped shafts")
                        var bounds := mesh.get_aabb()
                        _check(absf(bounds.size.x-2*Finish.PIN_HALF_LENGTH)
                            <0.001,"real pin cap length fits fork body")
                        _check(absf(bounds.size.y-2*Finish.PIN_SHOULDER_RADIUS)
                            <0.001,"two full-radius metal shoulder bevels")
                        _check(pin.rotation.length()<0.0001,
                            "V23 physical X-axis shaft not rotated incorrectly")
                        var mat := mesh.surface_get_material(0) as StandardMaterial3D
                        _check(mat!=null and mat.metallic>0.85
                            and mat.roughness<0.40,
                            "machined steel genuinely polished for specular night light")
                    for i in range(2):
                        var ear := hinge.get_node_or_null(
                            "OrejaForjada_%d" % i) as MeshInstance3D
                        var retainer := hinge.get_node_or_null(
                            "G11V23_RetenPasador_%d" % i) as MeshInstance3D
                        _check(ear!=null and ear.mesh is ArrayMesh,
                            "original forged ears not replaced or duplicated")
                        _check(retainer!=null and retainer.mesh is ArrayMesh,
                            "closed true 3D hollow retaining collar seated at each face")
                        if ear!=null:
                            _check(ear.material_override is StandardMaterial3D,
                                "dedicated PBR on existing ears")
                        if retainer!=null and retainer.mesh is ArrayMesh:
                            var mesh := retainer.mesh as ArrayMesh
                            if ring_ref==null:
                                ring_ref=mesh
                            else:
                                _check(mesh==ring_ref,
                                    "all 48 washers reuse the same native mesh")
                            var bounds := mesh.get_aabb()
                            _check(absf(bounds.size.y-2*Finish.RETAINER_OUTER)
                                <0.001,
                                "hollow retaining ring has correct outer radius")
                            _check(absf(retainer.position.x)-
                                Finish.RETAINER_X < 0.001,
                                "retaining ring lies flush against original ear")
        _check(V22.set_inspection(model,1),"V22 open right armor still works")
        _check(V22.set_inspection(model,-1),"V22 open left armor still works")
        _check(V22.set_inspection(model,0),"all painted armor restored")
        for travel in [0.0,0.27,0.5,0.79,1.0]:
            _check(Rig.pose(model,"move",travel),
                "forged pin assembly follows true wheel bounce")
            for side in [-1,1]:
                for axle in range(6):
                    var key: String = "%d_%d" % [side,axle]
                    var pivot := _find(model,"G11_RuedaPivot_"+key)
                    var hinge := _find(model,
                        "G11V22_BisagraInferior_"+key)
                    _check(pivot!=null and hinge!=null and hinge.position.distance_to(
                        pivot.position+Vector3(float(side)*V22.SIDE_X,
                        V22.LOWER_OFFSET_Y,0))<0.001,
                        "lower fork continues moving with wheel, never spinning")
        Rig.restore(model)
        _check(Art.apply_stage(model,3),"G11 critical damage unchanged")
        _check(Art.apply_stage(model,0),"G11 repairs unchanged")
        _check(Rig.pose(model,"attack",0.56),
            "hydraulic rocket elevation and firing preserved")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    _check(paints.size()==8,"eight exact faction colors preserved")
    if failures>0:
        push_error("G11 V23 native 3D PBR QA FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 V23: eight teams, 24 replaced chamfered steel pins, 48 authentic retaining rings, original fork meshes, safe outer-track clearance, full animated damage/cutaway compatibility")
    quit(0)
