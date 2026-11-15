extends SceneTree

# G11 renderer regression: real editable meshes, eight faction palettes,
# reversible visual damage and motion independent from game-state logic.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const FinishV2 = preload("res://scripts/ui/G11FinishV2.gd")
const SurfaceV3 = preload("res://scripts/ui/G11SurfaceV3.gd")
const GeometryV4 = preload("res://scripts/ui/G11GeometryV4.gd")
const MechanicsV5 = preload("res://scripts/ui/G11MechanicsV5.gd")
var failed: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failed += 1
        push_error("G11 3D QA: " + label)

func _find(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Existing battle LOD must not allocate the heavy showroom geometry.
    var battle: Node3D = Models.build("mlrs",0,true,10)
    _check(battle != null,"low-detail battle proxy exists")
    if battle != null:
        _check(not Art.has_model(battle),"battle doesn't allocate studio sculpt")
        _check(_find(battle,"CestaLanzacohetesElevada") != null,
            "battle retains original launch pod")
        battle.free()
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"studio model faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(Art.has_model(model),"complete G11 mesh in faction %d" % faction)
        _check(Rig.has_rig(model),"G11 moving articulated rig")
        _check(bool(model.get_meta(FinishV2.FLAG,false)),
            "commercial V2 finish installed on 3D native model")
        _check(bool(model.get_meta(SurfaceV3.FLAG,false)),
            "weathered V3 surface installed")
        _check(bool(model.get_meta(GeometryV4.FLAG,false)),
            "genuine hollow tubes and hydraulic V4 rig installed")
        _check(int(model.get_meta("tarvoka_g11_hollow_tubes",0)) == 12,
            "all twelve tubes replaced by open bore geometry")
        _check(bool(model.get_meta(MechanicsV5.FLAG,false)),
            "full sculpt V5 running gear and horizontal bearing installed")
        _check(int(model.get_meta("tarvoka_g11_v5_sculpted_roadwheels",0)) == 12,
            "twelve solid wheel proxies replaced by real annular wheels")
        _check(int(model.get_meta("tarvoka_g11_v5_sprocket_teeth",0)) == 16,
            "toothed drive sprocket count")
        var bearing := _find(model,"G11V5_CoronaGiroHorizontal") as MeshInstance3D
        _check(bearing != null and bearing.mesh is ArrayMesh,
            "rotating turret uses a horizontal 3D bearing ring")
        if bearing != null and bearing.mesh != null:
            var bounds: AABB = bearing.mesh.get_aabb()
            _check(bounds.size.y < bounds.size.x*0.2,
                "bearing ring is correctly horizontal, not sideways")
        _check(int(model.get_meta("tarvoka_g11_fastener_count",0)) == 28,
            "maintenance fasteners registered")
        var fasteners: MultiMeshInstance3D = _find(model,
            "G11V3_TornillosMantenimientoLote") as MultiMeshInstance3D
        _check(fasteners != null and fasteners.multimesh != null,
            "batched hardware mesh exists")
        if fasteners != null and fasteners.multimesh != null:
            _check(fasteners.multimesh.instance_count == SurfaceV3.FASTENER_COUNT,
                "all 28 hardware pieces share one MultiMesh")
        var hull: MeshInstance3D = _find(model,
            "G11V2_CascoOctogonalCerrado") as MeshInstance3D
        _check(hull != null and hull.material_override is StandardMaterial3D,
            "hull uses real Godot PBR material")
        if hull != null and hull.material_override is StandardMaterial3D:
            var material: StandardMaterial3D = hull.material_override as StandardMaterial3D
            _check(material.albedo_texture is ImageTexture,
                "wear is procedural texture, not floating fake decals")
        _check(_find(model,"G11V3_ServicioTrasero") != null,
            "rear service hatch is closed from behind")
        _check(_find(model,"G11V2_CabinaBiselada") != null,
            "cab is truly chamfered geometry")
        _check(_find(model,"G11V2_CascoOctogonalCerrado") != null,
            "lower armored hull is closed with bevels")
        _check(_find(model,"G11_Oruga_1") == null,
            "old giant rectangular rubber track slab removed")
        for side in [-1,1]:
            var belt: MeshInstance3D = _find(model,
                "G11V2_BandaOruga_%d" % side) as MeshInstance3D
            var treads: MultiMeshInstance3D = _find(model,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            _check(belt != null and belt.mesh != null,
                "closed belt contour on side %d" % side)
            _check(treads != null and treads.multimesh != null,
                "batched tread geometry on side %d" % side)
            if treads != null and treads.multimesh != null:
                _check(treads.multimesh.instance_count == FinishV2.TRACK_LINK_COUNT,
                    "all treads batched in one draw per side")
        _check(Models.inspect_meshes(model) > 80,"more than 80 real 3D meshes")
        for row in range(3):
            for column in range(4):
                _check(_find(model,"G11_Tubo_%d_%d" % [column,row]) != null,
                    "tube %d/%d" % [column,row])
                _check(_find(model,"G11_BocaInterior_%d_%d" % [column,row]) != null,
                    "real dark tube opening")
                var tube: MeshInstance3D = _find(model,
                    "G11_Tubo_%d_%d" % [column,row]) as MeshInstance3D
                _check(tube != null and tube.mesh is ArrayMesh,
                    "real shared mesh is not a primitive closed cylinder")
                if tube != null and tube.mesh is ArrayMesh:
                    _check(tube.mesh.get_surface_count() == 3,
                        "barrel includes exterior, annular mouth and internal bore")
                _check(_find(model,"G11_AroBoca_%d_%d" % [column,row]) == null,
                    "obsolete fake front ring deleted")
        for side in [-1,1]:
            for axle in range(6):
                _check(_find(model,"G11_RuedaPivot_%d_%d" % [side,axle]) != null,
                    "12 articulated roadwheel pivots")
        for side in [-1,1]:
            _check(_find(model,"G11V5_PinionTrasero_%d" % side) != null,
                "toothed rear sprocket each track")
            _check(_find(model,"G11V5_TensorDelantero_%d" % side) != null,
                "toothed front tension roller each track")
            for axle in range(6):
                var wheel: MeshInstance3D = _find(model,
                    "G11V5_LlantaEsculpida_%d_%d" % [side,axle]) as MeshInstance3D
                _check(wheel != null and wheel.mesh is ArrayMesh,
                    "actual sculpted annular roadwheel side %d axle %d" % [side,axle])
                if wheel != null and wheel.mesh is ArrayMesh:
                    _check(wheel.mesh.get_surface_count() == 2,
                        "rubber tire profile and recessed metal rim are distinct")
                var bolts: MultiMeshInstance3D = _find(model,
                    "G11V5_PernosRueda_%d_%d" % [side,axle]) as MultiMeshInstance3D
                _check(bolts != null and bolts.multimesh != null,
                    "wheel hub bolts are genuine instanced 3D geometry")
                if bolts != null and bolts.multimesh != null:
                    _check(bolts.multimesh.instance_count == 6,
                        "six nuts per wheel, one GPU batch")
                _check(_find(model,"G11_Rueda_%d_%d" % [side,axle]) == null,
                    "old blockout roadwheel disk removed")
                _check(_find(model,"G11V5_Amortiguador_%d_%d" % [side,axle]) != null,
                    "active suspension strut side %d axle %d" % [side,axle])
        _check(_find(model,"G11V5_TapaEscotilla") != null,
            "round roof access hatch with actual thickness")
        var paint := _find(model,"G11_PinturaLateral_1_0") as MeshInstance3D
        _check(paint != null and paint.material_override != null,
            "faction color on actual mesh")
        for side in [-1,1]:
            _check(_find(model,"G11V4_CilindroHidraulico_%d" % side) != null,
                "articulated hydraulic actuator side %d" % side)
            _check(_find(model,"G11V4_ArticulacionAlta_%d" % side) != null,
                "upper moving joint side %d" % side)
        _check(_find(model,"G11V4_TapaControlPosterior") != null,
            "rear enclosed service module has actual depth")
        var hydraulic_rest: float = _find(model,
            "G11V4_VastagoHidraulico_1").scale.y
        var shock_rest: float = _find(model,
            "G11V5_Amortiguador_1_0").scale.y
        var start: Vector3 = model.position
        var inst: MultiMeshInstance3D = _find(model,
            "G11V2_OrugaAnimada_1") as MultiMeshInstance3D
        var at_rest: Transform3D = inst.multimesh.get_instance_transform(0)
        _check(Models.pose_model("mlrs",model,"move",0.125),
            "animated roadwheel suspension and drive sprocket")
        _check(absf(_find(model,"G11V5_Amortiguador_1_0").scale.y
            -shock_rest) > 0.004,
            "telescopic suspension follows moving wheel pivots")
        var sprocket: Node3D = _find(model,"G11V5_PinionTrasero_1")
        _check(sprocket != null and absf(sprocket.rotation_degrees.x-90.0) < 0.1,
            "drive sprocket rotates synchronously with tracks")
        _check(Models.pose_model("mlrs",model,"move",0.25),"moving tracks")
        var while_moving: Transform3D = inst.multimesh.get_instance_transform(0)
        _check(at_rest.origin.distance_to(while_moving.origin) > 0.05,
            "track links actually traverse the contour while moving")
        _check(absf(_find(model,"G11_RuedaPivot_1_0").rotation_degrees.x) > 1.0,
            "roadwheels rotate during movement")
        # Check hydraulic travel during elevation BEFORE launch recoil; the
        # recoil briefly returns the actuator toward its initial length.
        _check(Models.pose_model("mlrs",model,"attack",0.24,Vector2i(1,0)),
            "launcher elevates and both pistons telescope")
        _check(absf(_find(model,"G11V4_VastagoHidraulico_1").scale.y
            -hydraulic_rest) > 0.01,"hydraulic pistons extend with live launcher")
        _check(Models.pose_model("mlrs",model,"attack",0.35,Vector2i(1,0)),
            "launcher aims and fires")
        _check(_find(model,"G11_GiroPlataforma").rotation_degrees.y < -20.0,
            "azimuth rotation")
        _check(_find(model,"G11_ElevacionLanzador").rotation_degrees.x > 20.0,
            "launch elevation")
        _check(_find(model,"G11_EfectoFogonazo").visible,"rocket muzzle flash")
        _check(Models.pose_model("mlrs",model,"hit_bullet",0.15),
            "small-arms impact reaction")
        _check(_find(model,"G11_ImpactoBalas").visible,"bullet impact VFX")
        _check(Models.pose_model("mlrs",model,"hit_explosive",0.30),
            "explosive impact reaction")
        _check(_find(model,"G11_ImpactoExplosivo").visible,"explosion VFX")
        for level in range(5):
            _check(Art.apply_stage(model,level),"damage stage %d" % level)
            _check(Art.stage(model) == level,"persist damage stage")
            _check(_find(model,"G11_ElevacionLanzador").visible == (level < 4),
                "destruction toggles launcher")
        _check(Models.pose_model("mlrs",model,"attack",0.30),
            "destroyed rocket unit safely ignores fire")
        _check(not _find(model,"G11_EfectoFogonazo").visible,
            "destroyed G11 cannot show live salvo")
        _check(Art.apply_stage(model,0),"complete repair")
        Models.restore_model_pose("mlrs",model)
        var reset_link: Transform3D = inst.multimesh.get_instance_transform(0)
        _check(at_rest.origin.distance_to(reset_link.origin) < 0.001,
            "tread links return to initial position")
        _check(absf(_find(model,"G11V4_VastagoHidraulico_1").scale.y
            -hydraulic_rest) < 0.002,"hydraulic pistons restore after animation")
        _check(absf(_find(model,"G11V5_Amortiguador_1_0").scale.y
            -shock_rest) < 0.002,"suspension returns to exact rest length")
        _check(absf(_find(model,"G11V5_PinionTrasero_1").rotation_degrees.x)
            < 0.002,"drive sprocket restores original orientation")
        _check(model.position.distance_to(start) < 0.001,
            "restore starting model transform")
        _check(not _find(model,"G11_ImpactoExplosivo").visible,
            "impact is reversible")
        model.queue_free()
        await process_frame
    if failed > 0:
        push_error("G11 3D QA FAILED (%d checks)" % failed)
        quit(1)
        return
    print("PASS G11 3D: V5 sculpted 12 annular wheels, 16-tooth rear sprockets, active suspension, horizontal bearing, hollow launch tubes, 8 factions and damage")
    quit(0)
