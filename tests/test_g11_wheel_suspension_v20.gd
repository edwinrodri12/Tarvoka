extends SceneTree

# Physical V20 wheel face, damper-helix and old track compatibility test.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const V20 = preload("res://scripts/ui/G11WheelSuspensionV20.gd")
var failures: int = 0
var paints: Dictionary = {}

func _check(valid: bool, what: String) -> void:
    if not valid:
        failures += 1
        push_error("G11 V20 wheel/suspension: "+what)

func _part(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(V20.HUB_CENTER_X+0.007 < 0.142,
        "physical hub head stays inside moving rubber side wall")
    _check(V20.RIVET_X+0.010 < 0.142,
        "all original fasteners are inset from the moving belt")
    _check(V20.SPRING_RADIUS-V20.SPRING_WIRE>0.052,
        "real coil is outside cylindrical V5 damper without intersection")
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"eight native Godot 3D faction models")
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V20.FLAG,false)),
            "V20 geometry is actually installed in renderer")
        _check(bool(model.get_meta("tarvoka_g11_track_finish_v19",false)),
            "V19 real chevron links preserved")
        _check(int(model.get_meta("tarvoka_g11_v20_closed_roadwheels",0))==12,
            "twelve physical replacement wheels, no duplicates")
        _check(int(model.get_meta("tarvoka_g11_v20_physical_spoked_faces",0))==12,
            "twelve original wheel spoked faces kept open")
        _check(int(model.get_meta("tarvoka_g11_v20_suspension_springs",0))==12,
            "12 real animated helical coils not painted decals")
        _check(int(model.get_meta("tarvoka_g11_v20_existing_hub_bolts_refit",0))==72,
            "72 old hardware instances repositioned, not doubled")
        _check(int(model.get_meta("tarvoka_g11_v20_replaced_mount_brackets",0))==12,
            "12 native corner-biselled suspension bracket replacements")
        var roof := _part(model,"G11_TapaSuperior") as MeshInstance3D
        if roof != null and roof.material_override is StandardMaterial3D:
            var paint: Color = (
                roof.material_override as StandardMaterial3D).albedo_color
            var expected: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(paint.is_equal_approx(expected),
                "no change to approved V13 faction PBR paint")
            paints[paint.to_html()] = true
        else:
            _check(false,"painted native roof exists")
        var first_wheel: Mesh = null
        var first_coil: Mesh = null
        for side in [-1,1]:
            _check(_part(model,
                "G11V2_OrugaAnimada_%d" % side) is MultiMeshInstance3D,
                "same existing V19 moving track retained")
            var track := _part(model,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            if track != null and track.multimesh != null:
                _check(track.multimesh.instance_count==46,
                    "46 real 3D bevelled links per side retained")
            for axle in range(6):
                var key: String = "%d_%d" % [side,axle]
                var pivot := _part(model,
                    "G11_RuedaPivot_"+key) as Node3D
                var wheel := _part(model,
                    "G11V5_LlantaEsculpida_"+key) as MeshInstance3D
                var hub := _part(model,
                    "G11V5_BujeCerrado_"+key) as MeshInstance3D
                var screws := _part(model,
                    "G11V5_PernosRueda_"+key) as MultiMeshInstance3D
                var damper := _part(model,
                    "G11V5_Amortiguador_"+key) as MeshInstance3D
                var shaft := _part(model,
                    "G11V5_VastagoSuspension_"+key) as MeshInstance3D
                var bracket := _part(model,
                    "G11V5_SoporteSuspension_"+key) as MeshInstance3D
                var coil := _part(model,
                    "G11V20_MuelleHelicoidal_"+key) as MeshInstance3D
                _check(pivot != null and wheel != null and hub != null
                    and screws != null and damper != null
                    and shaft != null and bracket != null and coil != null,
                    "one wheel + one hub + one preexisting screw set + "
                    + "two telescopic shock sections and one genuine spring")
                if wheel == null or hub == null or screws == null or (
                        damper == null or coil == null or bracket == null):
                    continue
                var mesh := wheel.mesh as ArrayMesh
                _check(mesh != null and mesh.get_surface_count()==3,
                    "wheel consists of rubber, open-web steel, recessed cavity")
                if mesh != null:
                    if first_wheel == null:
                        first_wheel = mesh
                    else:
                        _check(first_wheel == mesh,
                            "all 12 wheels share one cached sculpted mesh")
                    var box: AABB = mesh.get_aabb()
                    _check(absf(box.size.y-0.330)<0.001 and (
                        absf(box.size.z-0.330)<0.001),
                        "wheels still have calibrated 165mm circular radius")
                    _check(absf(box.end.x-V20.WHEEL_FRONT_X)<0.001
                        and absf(box.position.x-V20.WHEEL_BACK_X)<0.001,
                        "closed wheel rim is recessed inside track sidewall")
                    var web: PackedVector3Array = (
                        mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX]
                    )
                    _check(web.size()>800,
                        "eight open-space metallic wheel webs are true 3D strips")
                _check(hub.mesh is CylinderMesh,
                    "original actual bearing cap sculpt is preserved")
                if hub.mesh is CylinderMesh:
                    _check(absf((
                        hub.mesh as CylinderMesh).top_radius
                        -V20.HUB_RADIUS)<0.001,
                        "bearing cap fits smaller central wheel aperture")
                _check(absf(hub.position.x-
                    float(side)*V20.HUB_CENTER_X)<0.001,
                    "hub is inset and aligned with actual wheel center")
                if screws.multimesh != null:
                    _check(screws.multimesh.instance_count==6,
                        "no duplicate old bolt instances")
                    for n in range(6):
                        var p: Vector3 = screws.multimesh.get_instance_transform(
                            n).origin
                        _check(absf(absf(p.x)-V20.RIVET_X)<0.001,
                            "hardware lies within revised steel wheel face")
                        _check(absf(Vector2(p.y,p.z).length()-
                            V20.RIVET_R)<0.001,
                            "all six bolts centered on real web mounting ring")
                _check(coil.get_parent()==damper,
                    "helical spring is attached to moving strut, never floating")
                if coil.mesh != null:
                    if first_coil == null:
                        first_coil = coil.mesh
                    else:
                        _check(first_coil==coil.mesh,
                            "all twelve coils share one native 3D helix mesh")
                    var coil_box: AABB = coil.mesh.get_aabb()
                    _check(coil_box.size.y > 0.80 and coil_box.size.y < 0.84,
                        "true eight-turn helix remains inside damper stroke")
                    _check(coil_box.size.x > 0.130 and coil_box.size.x < 0.142,
                        "no spring wire is pressed through damper cylinder")
                _check(bracket.mesh is ArrayMesh,
                    "existing metal bracket replaced with beveled volume")
                if bracket.mesh is ArrayMesh:
                    var bb: AABB = bracket.mesh.get_aabb()
                    _check(absf(bb.size.z-V20.BRACKET_Z)<0.001,
                        "chamfered bracket remains exactly in legacy mounts")
                _check(_part(model,
                    "G11_Rueda_%d_%d" % [side,axle])==null,
                    "no old original wheel hidden underneath")
        var sample := _part(model,"G11V5_Amortiguador_1_2") as MeshInstance3D
        var home: Transform3D = sample.transform if sample else Transform3D.IDENTITY
        var wheel_home := _part(model,"G11_RuedaPivot_1_2") as Node3D
        for t in [0.0,0.23,0.48,0.78,1.0]:
            _check(Rig.pose(model,"move",t),
                "suspension, helix and wheel rims follow chassis animation")
            if sample != null:
                _check(sample.visible,
                    "real moving damper/spring never vanishes while driving")
        Rig.restore(model)
        if sample != null:
            _check(sample.transform.origin.distance_to(home.origin)<0.002,
                "shock and child coil restore their exact rest position")
        if wheel_home != null:
            _check(absf(wheel_home.position.y-0.265)<0.001,
                "no residual suspension offset at rest")
        _check(Art.apply_stage(model,3),"critical damage remains operable")
        _check(Art.apply_stage(model,0),"full repair remains operable")
        _check(Rig.pose(model,"attack",0.55),
            "12 open rocket tubes and V14 launcher hydraulics still articulate")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    _check(paints.size()==8,"eight unique fac colors remain unchanged")
    if failures>0:
        push_error("G11 V20 native mesh QA FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 V20: 12 closed real 3D roadwheels, 8 metal webs each, 12 helical suspension springs, 72 original bolts refit, 12 original mounts beveled, 8 factions, no hidden wheels, V19 treads and all motion states")
    quit(0)
