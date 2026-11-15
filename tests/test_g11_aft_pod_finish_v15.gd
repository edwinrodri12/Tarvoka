extends SceneTree

# V15 independent Godot 4.3 validation: geometry, facade, 8 colors and
# damage/articulation regressions. No combat or mobile performance benchmarks.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Finish = preload("res://scripts/ui/G11AftPodFinishV15.gd")
const V14 = preload("res://scripts/ui/G11MechanicalDetailV14.gd")
var errors: int = 0
var colors: Dictionary = {}

func _check(ok: bool, info: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V15 sculpture: "+info)

func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"native faction %d constructed" % faction)
        if model == null:
            continue
        root.add_child(model)
        var pod := _find(model,Finish.ELEVATION)
        _check(bool(model.get_meta(Finish.FLAG,false)),
            "V15 geometry applied after V14")
        _check(int(model.get_meta("tarvoka_g11_v15_chamfered_cheeks",0)) == 2,
            "two real beveled rear cheeks")
        _check(int(model.get_meta("tarvoka_g11_v15_rear_louvers",0)) == 6,
            "six aft ventilation fins")
        _check(bool(model.get_meta(V14.FLAG,false)),
            "V14 animated hoses still present")
        _check(int(model.get_meta("tarvoka_g11_v13_drive_teeth",0)) == 10,
            "V13 correctly matched ten-tooth gears untouched")
        var roof := _find(model,"G11_TapaSuperior") as MeshInstance3D
        _check(roof != null and roof.material_override is StandardMaterial3D,
            "approved real faction roof still physically painted")
        if roof != null and roof.material_override is StandardMaterial3D:
            var tint := (roof.material_override as StandardMaterial3D).albedo_color
            var original: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(tint.is_equal_approx(original),
                "true roof material retains specific faction color")
            colors[tint.to_html()] = true
        for c in range(4):
            for row in range(3):
                _check(_find(model,"G11_Tubo_%d_%d" % [c,row]) != null,
                    "all twelve individual rocket bores intact")
        for side in [-1,1]:
            var cheek := _find(model,
                "G11V15_CacheteAftBiselado_%d" % side) as MeshInstance3D
            _check(cheek != null and cheek.mesh is ArrayMesh,
                "physical extruded 3D rear cheek on side %d" % side)
            if cheek != null and cheek.mesh != null:
                var aabb: AABB = cheek.mesh.get_aabb()
                _check(aabb.size.x > 0.052 and aabb.size.y > 0.26
                    and aabb.size.z > 0.53,
                    "rear cheek is truly volumetric, sloped and readable")
                _check(cheek.position.x*float(side) > 0.72,
                    "rear cheek exterior is clear of central twelve tubes")
            for part in ["RecesoSuperior","NervioBajo","FraccionCostado",
                    "MontanteTrasero"]:
                _check(_find(model,"G11V15_%s_%d" % [part,side]) != null,
                    "aft sculpt %s on side %d" % [part,side])
            _check(_find(model,"G11V13_PanelFaccionLanzador_%d" % side) != null,
                "V13 faction stripes still exposed")
            for bolt in range(3):
                _check(_find(model,"G11V15_TornilloCachete_%d_%d" %
                    [side,bolt]) != null,
                    "physical fasteners on extruded armor")
        for tier in range(2):
            var rail := _find(model,
                "G11V15_TravesanoTrasero_%d" % tier) as MeshInstance3D
            _check(rail != null and rail.mesh is ArrayMesh,
                "rear chamfered structural cross-member")
            if rail != null:
                _check(absf(rail.rotation_degrees.y-90.0) < 0.1,
                    "transverse beam across width not missile bores")
        for slot in range(6):
            _check(_find(model,"G11V15_LamaRespiradero_%02d" % slot) != null,
                "individual real 3D rear cooling slot")
        _check(_find(model,"G11V14_PuertaRegistro") != null,
            "V14 rear maintenance door remains accessible")
        _check(_find(model,"G11V15_RespiraderoTrasero") != null,
            "ventilation uses real dark recessed geometry")

        var bent := _find(model,"G11V15_PanelDoblado")
        var scuffs := _find(model,"G11V15_DesgasteCostados")
        _check(bent != null and scuffs != null,
            "new visual damage layers have separate geometry")
        if bent != null and scuffs != null:
            _check(not bent.visible and not scuffs.visible,
                "intact vehicle has clean, undamaged armor")
        _check(Art.apply_stage(model,2),"moderate damage can be applied")
        if bent != null and scuffs != null:
            _check(not bent.visible and scuffs.visible,
                "moderate damage shows scuffs but not fractured beam")
        _check(Art.apply_stage(model,3),"critical damage can be applied")
        if bent != null and scuffs != null:
            _check(bent.visible and scuffs.visible,
                "critical damage bends the afterbody beam")
        _check(Art.apply_stage(model,0),"repair restores 3D afterbody")
        if bent != null and scuffs != null:
            _check(not bent.visible and not scuffs.visible,
                "repair fully removes visible V15 damage")

        var upper := _find(model,"G11V15_CacheteAftBiselado_1")
        var rest: Vector3 = pod.transform*upper.position if (
            upper != null and pod != null) else Vector3.ZERO
        _check(Rig.pose(model,"attack",0.55),
            "real pod rotates/elevates while rear geometry remains attached")
        if upper != null and pod != null:
            _check((pod.transform*upper.position).distance_to(rest) > 0.012,
                "new rear armor actually follows launcher articulation")
        _check(Rig.pose(model,"cooldown",0.48),
            "cooldown maintains correct V15 attachment")
        _check(Rig.pose(model,"move",0.34),
            "track animation still operates with V15 added")
        Rig.restore(model)
        if upper != null and pod != null:
            _check((pod.transform*upper.position).distance_to(rest) < 0.001,
                "rear silhouette restores exactly to idle")
        model.queue_free()
        await process_frame
    _check(colors.size() == 8,"all eight roof colors remain distinct")
    if errors > 0:
        push_error("G11 V15 QA FAILED (%d)" % errors)
        quit(1)
        return
    print("PASS G11 V15: 8 faction roofs, 2 volumetric armored cheeks, chamfered rear frame, 6 vents, service hatch, damage/repair, animated hydraulics and all 12 open tubes")
    quit(0)
