extends SceneTree

# V16 geometry regression for the actual G11 native 3D renderer.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const V16 = preload("res://scripts/ui/G11FrontFrameV16.gd")
var failures: int = 0
var paints: Dictionary = {}

func _check(ok: bool, info: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V16: "+info)

func _part(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"faction %d exists" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V16.FLAG,false)),"G11 V16 applied")
        _check(bool(model.get_meta("tarvoka_g11_aft_pod_finish_v15",false)),
            "V15 rear shell preserved")
        _check(bool(model.get_meta("tarvoka_g11_mechanical_detail_v14",false)),
            "V14 curved hoses preserved")
        _check(int(model.get_meta("tarvoka_g11_v13_drive_teeth",0)) == 10,
            "V13 matching sprockets preserved")
        _check(int(model.get_meta("tarvoka_g11_v16_open_tube_faces",0)) == 12,
            "V16 intentionally keeps all twelve firing bores open")
        var roof := _part(model,"G11_TapaSuperior") as MeshInstance3D
        _check(roof != null and roof.material_override is StandardMaterial3D,
            "original faction-colored roof remains a real PBR mesh")
        if roof != null and roof.material_override is StandardMaterial3D:
            var roof_paint := (roof.material_override as StandardMaterial3D).albedo_color
            var faction_paint: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(roof_paint.is_equal_approx(faction_paint),
                "V16 retains exact team-colored steel roof")
            paints[roof_paint.to_html()] = true
        for c in range(4):
            for row in range(3):
                var tube := _part(model,"G11_Tubo_%d_%d" % [c,row]
                ) as MeshInstance3D
                _check(tube != null and tube.mesh is ArrayMesh,
                    "12 hollow native rocket tubes remain distinct")
        var top := _part(model,"G11V16_MarcoSuperiorFrontal") as MeshInstance3D
        var low := _part(model,"G11V16_MarcoInferiorFrontal") as MeshInstance3D
        _check(top != null and top.mesh is ArrayMesh,
            "top bevel is solid 3D extrusion")
        _check(low != null and low.mesh is ArrayMesh,
            "bottom bevel is solid 3D extrusion")
        if top != null and low != null:
            _check(top.position.y > 0.43 and low.position.y < -0.43,
                "transverse frame does not block upper/lower tube margins")
        for side in [-1,1]:
            var edge := _part(model,"G11V16_MarcoLateralFrontal_%d" % side
                ) as MeshInstance3D
            _check(edge != null and edge.mesh is ArrayMesh,
                "beveled front side rail is real mesh")
            if edge != null:
                _check(absf(edge.position.x) > 0.56,
                    "front rail outside furthest tube bore radius")
            for sy in [-1,1]:
                var cap := _part(model,"G11V16_CartelaEsquina_%d_%d" % [side,sy]
                    ) as MeshInstance3D
                _check(cap != null and cap.mesh is ArrayMesh,
                    "four angled corner gussets have physical triangles")
                if cap != null:
                    var bb: AABB = cap.mesh.get_aabb()
                    _check(bb.size.z > 0.07 and bb.size.x > 0.07
                        and bb.size.y > 0.07,
                        "corner gusset has depth, width and height")
                _check(_part(model,
                    "G11V16_PernoCartela_%d_%d" % [side,sy]) != null,
                    "corner bolt is real native geometry")
            for part_name in ["LabioTechoBiselado","TapaTecho","BisagraTecho",
                    "CierreTecho","CosturaTrasera"]:
                _check(_part(model,"G11V16_%s_%d" % [part_name,side]) != null,
                    "roof and rear detail %s mirrored correctly" % part_name)
            for weld in range(2):
                _check(_part(model,
                    "G11V16_CordonSoldaduraTecho_%d_%d" % [side,weld]) != null,
                    "real roof weld cylinders remain visible")
            _check(_part(model,"G11V13_PanelFaccionLanzador_%d" % side) != null,
                "V13 launcher panel unchanged")

        var moderate := _part(model,"G11V16_DesperfectosFrontales")
        var critical := _part(model,"G11V16_DanoMarcoCritico")
        _check(moderate != null and critical != null,
            "two independent reversible damage states")
        _check(Art.apply_stage(model,2),"V16 survives medium damage")
        if moderate != null and critical != null:
            _check(moderate.visible and not critical.visible,
                "medium: only scratches visible")
        _check(Art.apply_stage(model,3),"V16 survives critical damage")
        if moderate != null and critical != null:
            _check(moderate.visible and critical.visible,
                "critical: bent armor edge appears")
        _check(Art.apply_stage(model,0),"V16 recovers after repair")
        if moderate != null and critical != null:
            _check(not moderate.visible and not critical.visible,
                "repair completely removes new damage")
        var pod := _part(model,V16.POD) as Node3D
        var bracket := _part(model,"G11V16_CartelaEsquina_1_1") as Node3D
        var rest := pod.transform*bracket.position if (
            pod != null and bracket != null) else Vector3.ZERO
        _check(Rig.pose(model,"attack",0.60),
            "V16 frame follows the real rocket firing motion")
        if pod != null and bracket != null:
            _check((pod.transform*bracket.position).distance_to(rest) > 0.02,
                "new mesh is attached to elevating structure")
        _check(Rig.pose(model,"cooldown",0.66),
            "V16 mesh stays aligned during hydraulic cooldown")
        _check(Rig.pose(model,"move",0.42),
            "V13 wheel travel continues with V16 attached")
        Rig.restore(model)
        if pod != null and bracket != null:
            _check((pod.transform*bracket.position).distance_to(rest) < 0.002,
                "new meshes return to their exact rest coordinates")
        model.queue_free()
        await process_frame
    _check(paints.size() == 8,"eight different real faction roof paints remain")
    if failures > 0:
        push_error("G11 V16 QA FAILED: %d checks" % failures)
        quit(1)
        return
    print("PASS G11 V16: open 12 muzzles, real beveled front, four triangular gussets, roof welds and hatches, 8 factions, V13-V15 compatibility and reversible damage")
    quit(0)
