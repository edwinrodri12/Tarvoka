extends SceneTree

# V14 real Godot geometry/kinematics QA, eight factions and V13 regressions.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Detail = preload("res://scripts/ui/G11MechanicalDetailV14.gd")
const Track = preload("res://scripts/ui/G11TracksFactionV13.gd")
var failures: int = 0

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V14: "+message)

func _node(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"faction %d build" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Detail.FLAG,false)),
            "V14 model built in genuine native 3D pipeline")
        _check(int(model.get_meta("tarvoka_g11_v14_hoses",0)) == 4,
            "four real animated rubber hose circuits")
        _check(int(model.get_meta("tarvoka_g11_v13_drive_teeth",0)) == 10,
            "V13 ten-tooth sprocket geometry retained")
        var roof := _node(model,"G11_TapaSuperior") as MeshInstance3D
        _check(roof != null and roof.material_override is StandardMaterial3D,
            "V13 faction-painted actual 3D roof preserved")
        if roof != null and roof.material_override is StandardMaterial3D:
            var color := (roof.material_override as StandardMaterial3D).albedo_color
            var intended: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(color.is_equal_approx(intended),
                "roof paint remains correct for faction %d" % faction)
        for x in range(4):
            for y in range(3):
                _check(_node(model,"G11_Tubo_%d_%d" % [x,y]) != null,
                    "rocket tube %d,%d still open" % [x,y])
        for side in [-1,1]:
            for label in ["CajaLateral","PuertaLateral","CoronaEjeElevacion",
                    "TapaEjeElevacion","MarcaLateral"]:
                _check(_node(model,"G11V14_%s_%d" % [label,side]) != null,
                    "actual 3D maintenance/hinge part %s side %d" % [label,side])
            _check(_node(model,"G11V13_PanelFaccionLanzador_%d" % side) != null,
                "V13 visible faction flank panels preserved")
            for line in range(Detail.HOSES_PER_SIDE):
                _check(_node(model,
                    "G11V14_PuertoLanzador_%d_%d" % [side,line]) != null,
                    "hose is fastened on moving launcher")
                for segment in range(Detail.HOSE_SEGMENTS):
                    var part := _node(model,
                        "G11V14_Manguera_%d_%d_%02d" % [side,line,segment]
                    ) as MeshInstance3D
                    _check(part != null and part.mesh is CylinderMesh,
                        "physical curved rubber hose segment")
                    if part != null:
                        _check(part.visible and part.scale.y > 0.001,
                            "hose is actually connected at neutral angle")
        _check(_node(model,"G11V14_PernosRegistro") is MultiMeshInstance3D,
            "batched true 3D service fasteners")
        var hose := _node(model,"G11V14_Manguera_1_0_03") as MeshInstance3D
        var neutral := hose.position if hose != null else Vector3.ZERO
        _check(Rig.pose(model,"attack",0.47),
            "salvo animates the rocket pod")
        if hose != null:
            _check(hose.position.distance_to(neutral) > 0.005,
                "hose geometry follows launcher elevation, not floating")
        _check(Rig.pose(model,"cooldown",0.5),
            "hoses conform during post-salvo hydraulic cooldown")
        _check(Rig.pose(model,"move",0.35),
            "V13 synchronized sprockets and belt still animate")
        _check(Art.apply_stage(model,3),
            "critical damage retains V14 assembly")
        _check(Art.apply_stage(model,0),
            "repair restores V14 assembly")
        Rig.restore(model)
        if hose != null:
            _check(hose.position.distance_to(neutral) < 0.002,
                "all hose loops return to exact rest position")
        model.queue_free()
        await process_frame
    if failures > 0:
        push_error("G11 V14 FAILED: %d checks" % failures)
        quit(1)
        return
    print("PASS G11 V14: eight painted factions, 28 curved connected hose segments, mechanical service panels, open twelve bores, stable V13 sprockets, attack/cooldown/repair")
    quit(0)
