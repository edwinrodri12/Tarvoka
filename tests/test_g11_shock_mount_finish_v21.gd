extends SceneTree

# Native Godot 4.3 acceptance for real V21 rebuilt spring mount alignment.
# Geometry, parent hierarchy, eight teams, driving, damage and launcher.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Finish = preload("res://scripts/ui/G11ShockMountFinishV21.gd")
var failures: int = 0
var colors: Dictionary = {}

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V21 suspension: "+label)

func _part(model: Node3D,label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Finish.SEAT_Y-Finish.SEAT_THICKNESS*0.5 >= (
        Finish.SPRING_MAX_Y-0.002),
        "two spring seats only meet end windings, never compress the coil")
    _check(Finish.SEAT_RADIUS <= Finish.WIRE_RADIUS+0.002,
        "seats stay inside existing spring outer contour")
    _check(Finish.GLAND_INNER_RADIUS >= 0.027,
        "piston gland fits original V5 27mm steel rod")
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"real high-quality G11 for faction "+str(faction))
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Finish.FLAG,false)),
            "V21 corrected mounts integrated, no sketch fallback")
        _check(bool(model.get_meta("tarvoka_g11_wheel_suspension_v20",false)),
            "all 12 V20 closed spoked wheels and helical springs retained")
        _check(bool(model.get_meta("tarvoka_g11_track_finish_v19",false)),
            "46 moving links per side and V19 anti-slip cleats retained")
        _check(int(model.get_meta(
            "tarvoka_g11_v21_corrected_mount_positions",0))==12,
            "12 original brackets repaired rather than 12 duplicate brackets")
        _check(int(model.get_meta(
            "tarvoka_g11_v21_metal_spring_seats",0))==24,
            "24 true spring-end seats only on original dampers")
        _check(int(model.get_meta(
            "tarvoka_g11_v21_piston_glands",0))==12,
            "12 rubber piston glands follow original telescoping rods")
        _check(int(model.get_meta(
            "tarvoka_g11_v21_original_mount_bolts",0))==24,
            "24 mounting bolts on original supports")
        var roof := _part(model,"G11_TapaSuperior") as MeshInstance3D
        if roof != null and roof.material_override is StandardMaterial3D:
            var c: Color = (
                roof.material_override as StandardMaterial3D).albedo_color
            _check(c.is_equal_approx(model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color),
                "no faction palette or roof-albedo changes")
            colors[c.to_html()] = true
        else:
            _check(false,"PBR faction roof retained")
        for side in [-1,1]:
            var tracks := _part(model,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            _check(tracks != null and tracks.multimesh != null and (
                tracks.multimesh.instance_count==46),
                "same two 46-shoe loops, no extra belts")
            for axle in range(6):
                var key: String = "%d_%d" % [side,axle]
                var pivot := _part(model,"G11_RuedaPivot_"+key) as Node3D
                var mount := _part(model,
                    "G11V5_SoporteSuspension_"+key) as MeshInstance3D
                var damper := _part(model,
                    "G11V5_Amortiguador_"+key) as MeshInstance3D
                var piston := _part(model,
                    "G11V5_VastagoSuspension_"+key) as MeshInstance3D
                var coil := _part(model,
                    "G11V20_MuelleHelicoidal_"+key) as MeshInstance3D
                var upper := _part(model,
                    "G11V21_AsientoMuelleSuperior_"+key) as MeshInstance3D
                var lower := _part(model,
                    "G11V21_AsientoMuelleInferior_"+key) as MeshInstance3D
                var seal := _part(model,
                    "G11V21_RetenVastago_"+key) as MeshInstance3D
                var screws := _part(model,
                    "G11V21_PernosSoporte_"+key) as MultiMeshInstance3D
                _check(pivot != null and mount != null and damper != null
                    and piston != null and coil != null and upper != null
                    and lower != null and seal != null and screws != null,
                    "12 original aligned upper joints and single live shock assemblies")
                if pivot == null or mount == null or damper == null or (
                        piston == null or coil == null or upper == null or
                        lower == null or seal == null or screws == null):
                    continue
                _check(mount.position.distance_to(Vector3(
                    float(side)*Finish.UPPER_X,Finish.UPPER_Y,
                    pivot.position.z+Finish.UPPER_Z_OFFSET)) < 0.001,
                    "legacy bracket exactly follows repositioned V18 upper anchor")
                _check(mount.mesh is ArrayMesh,
                    "existing V20 beveled bracket reused, not duplicate box")
                _check(upper.get_parent()==damper
                    and lower.get_parent()==damper and coil.get_parent()==damper,
                    "both metal spring seats and existing coil inherit damper transform")
                _check(seal.get_parent()==piston,
                    "gland inherits lower telescopic rod instead of floating")
                for ring in [upper,lower]:
                    _check(ring.mesh is ArrayMesh,
                        "genuine closed annular metal spring seat")
                    if ring.mesh is ArrayMesh:
                        var b: AABB = ring.mesh.get_aabb()
                        _check(absf(b.size.x-2.0*Finish.SEAT_RADIUS)<0.001
                            and absf(b.size.z-2.0*Finish.SEAT_RADIUS)<0.001,
                            "true PBR seat with correct radius")
                        _check(absf(b.size.y-Finish.SEAT_THICKNESS)<0.001,
                            "steel collar keeps 14mm extrusion thickness")
                _check(absf(upper.position.y-Finish.SEAT_Y)<0.001
                    and absf(lower.position.y+Finish.SEAT_Y)<0.001,
                    "end collars are correctly seated, not stacked on winding")
                _check(seal.mesh is ArrayMesh,
                    "actual piston seal has metallic/rubber annular geometry")
                if seal.mesh is ArrayMesh:
                    var sb: AABB = seal.mesh.get_aabb()
                    _check(absf(sb.size.x-2.0*Finish.GLAND_RADIUS)<0.001,
                        "piston guide uses exact 36mm outer radius")
                _check(absf(seal.position.y-Finish.GLAND_Y)<0.001,
                    "seal is at outer end of original sliding piston")
                _check(screws.get_parent()==mount
                    and screws.multimesh != null
                    and screws.multimesh.instance_count==2,
                    "two physical original-mount fasteners are firmly attached")
                _check(coil.material_override is StandardMaterial3D,
                    "visible steel spring receives an independent PBR finish")
                _check(_part(model,
                    "G11_Rueda_%d_%d" % [side,axle])==null,
                    "no old blockout wheel revived")
            for g in ["TensorDelantero","PinionTrasero"]:
                _check(_part(model,
                    "G11V5_%s_%d" % [g,side])!=null,
                    "two real sprockets still installed on each belt")
        for progress in [0.0,0.24,0.50,0.78,1.0]:
            _check(Rig.pose(model,"move",progress),
                "live coil seats and 12 correctly positioned shock supports survive march")
            var sample := _part(model,
                "G11V5_Amortiguador_1_2") as MeshInstance3D
            var upper_sample := _part(model,
                "G11V21_AsientoMuelleSuperior_1_2") as MeshInstance3D
            if sample != null and upper_sample != null:
                _check(upper_sample.get_parent()==sample,
                    "seat stays with moving shock under animation")
        Rig.restore(model)
        var wheel := _part(model,"G11_RuedaPivot_1_2")
        _check(wheel != null and absf(wheel.position.y-0.265)<0.001,
            "wheels return to exact suspension rest height")
        _check(Art.apply_stage(model,3),"critical damage supported")
        _check(Art.apply_stage(model,0),"repair supported")
        _check(Rig.pose(model,"attack",0.54),"hydraulic missile elevation intact")
        Rig.restore(model)
        for col in range(4):
            for row in range(3):
                _check(_part(model,
                    "G11_Tubo_%d_%d" % [col,row])!=null,
                    "twelve original hollow rocket tubes maintained")
        model.queue_free()
        await process_frame
    _check(colors.size()==8,"all eight unique faction colors preserved")
    if failures>0:
        push_error("G11 V21 spring mount QA FAILED (%d)" % failures)
        quit(1)
        return
    print("PASS G11 V21: all eight teams, 12 aligned legacy mounts, 24 moving annular spring seats, 12 piston seals, 24 bracket fasteners, no duplicate shocks, all V19/V20 animations and launch/damage states")
    quit(0)
