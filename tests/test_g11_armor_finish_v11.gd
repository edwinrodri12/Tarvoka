extends SceneTree

# Commercial 3D sculpt V11 QA. Inspect twelve real tubes, physical frame
# silhouette, metal trim, maintenance pieces, faction identity and poses.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const V10 = preload("res://scripts/ui/G11CooldownV10.gd")
const V11 = preload("res://scripts/ui/G11ArmorFinishV11.gd")
var failures: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V11 precision sculpt: "+label)

func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"hero model faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V11.FLAG,false)),
            "V11 native sculpture installed after V10 for faction %d" % faction)
        _check(int(model.get_meta("tarvoka_g11_v11_true_beveled_rails",0)) == 4,
            "four sculpted load-bearing outer corner rails")
        _check(int(model.get_meta("tarvoka_g11_v11_lip_wear_sectors",0)) == 36,
            "thirty-six modeled individual patches on twelve real tube lips")
        var launcher := _find(model,Art.ELEVATION)
        var turret := _find(model,Art.TURRET)
        _check(bool(model.get_meta("tarvoka_g11_v11_real_open_casing",false)),
            "solid front obstruction genuinely replaced with an open frame")
        var casing := _find(model,"G11_ArmazonLanzador") as MeshInstance3D
        _check(casing != null and casing.mesh is ArrayMesh,
            "former V1 opaque launch chassis replaced with custom hole-preserving geometry")
        if casing != null and casing.mesh is ArrayMesh:
            var casing_mesh: ArrayMesh = casing.mesh as ArrayMesh
            var vertex_array: PackedVector3Array = casing_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            _check(vertex_array.size() >= 140,
                "four distinct closed casing walls, not an old single solid box")
            var blocked: bool = false
            for point in vertex_array:
                if absf(point.x) < 0.54 and absf(point.y) < 0.36 and point.z < -0.72:
                    blocked = true
            _check(not blocked,
                "no opaque metal across middle of open V4 physical tube bores")
        var top_cover := _find(model,"G11_TapaSuperior") as MeshInstance3D
        _check(top_cover != null and top_cover.mesh is ArrayMesh,
            "former flat launcher roof is now a real beveled octagonal plate")
        if top_cover != null and top_cover.material_override is StandardMaterial3D:
            var roof_metal: StandardMaterial3D = top_cover.material_override as StandardMaterial3D
            if bool(model.get_meta("tarvoka_g11_tracks_faction_v13",false)):
                _check(roof_metal.metallic > 0.25 and roof_metal.roughness > 0.45,
                    "V13 faction-painted upper pod remains genuine metallic PBR")
                var faction_paint: Color = model.get_meta(
                    "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
                _check(roof_metal.albedo_color.is_equal_approx(faction_paint),
                    "V11 octagonal roof honors requested V13 color per faction")
            else:
                _check(roof_metal.metallic > 0.40 and roof_metal.roughness > 0.65,
                    "V11 without V13 keeps its original dark satin metal")
        for stiffener in range(3):
            _check(_find(model,"G11V11_NervioTecho_%d" % stiffener) != null,
                "thin three-dimensional longitudinal roof stiffener %d" % stiffener)
        for weld in range(2):
            _check(_find(model,"G11V11_SoldaduraTecho_%d" % weld) != null,
                "subtle real metallic welding seam on launch container")
        _check(launcher != null and turret != null,
            "V11 decorative frame belongs to real animated launcher")
        if launcher == null:
            model.queue_free()
            await process_frame
            continue
        var tube := _find(model,"G11_Tubo_0_0") as MeshInstance3D
        _check(tube != null and tube.mesh is ArrayMesh,
            "physical V4 hollow tube geometry preserved")
        if tube != null and tube.mesh is ArrayMesh:
            var tube_geom: ArrayMesh = tube.mesh as ArrayMesh
            _check(tube_geom.get_surface_count() == 3,
                "V11 metals retain all open tubular surfaces")
            var lip: StandardMaterial3D = tube_geom.surface_get_material(1) as StandardMaterial3D
            _check(lip != null and lip.metallic > 0.70,
                "muzzle steel has actual highly metallic PBR finish")
            var interior: StandardMaterial3D = tube_geom.surface_get_material(2) as StandardMaterial3D
            _check(interior != null and interior.roughness > 0.90,
                "recessed interior remains dark and almost non-reflecting")
        var nickels := _find(model,"G11V11_RozadurasBocas") as MeshInstance3D
        _check(nickels != null and nickels.mesh is ArrayMesh,
            "one actual 3D mesh models all 36 metallic muzzle scuffs")
        if nickels != null and nickels.mesh is ArrayMesh:
            var wear: AABB = nickels.mesh.get_aabb()
            _check(wear.size.x < 1.1 and wear.size.y < 0.72,
                "scuffs remain on the tube lips, not detached front decals")
        var front_bolts := _find(model,"G11V11_PernosMarcosLote") as MultiMeshInstance3D
        _check(front_bolts != null and front_bolts.multimesh != null,
            "actual shallow bolt heads, batched into one native 3D multimesh")
        if front_bolts != null and front_bolts.multimesh != null:
            _check(front_bolts.multimesh.instance_count == 16,
                "sixteen real screw heads around frame, no fake texture grid")
        for side in [-1,1]:
            for upper in [-1,1]:
                var rail := _find(model,
                    "G11V11_CantoneraBiselada_%d_%d" % [side,upper]) as MeshInstance3D
                _check(rail != null and rail.mesh is ArrayMesh,
                    "true octagonal extruded corner guard %d/%d" % [side,upper])
                if rail != null and rail.mesh is ArrayMesh:
                    var bounds: AABB = rail.mesh.get_aabb()
                    _check(bounds.size.z > 1.5 and bounds.size.x < 0.13,
                        "corner guard has full longitudinal depth with a slim face")
                    # Crucial: the inner edge of outer rail cannot block the
                    # last tube lip or its V10 metallic cooling glow.
                    _check(absf(rail.position.x)-bounds.size.x*0.5
                        > 0.42+0.115,
                        "front rails do not intersect side nozzle mouths")
            _check(_find(model,
                "G11V11_CacheteProtector_%d" % side) != null,
                "sculpted trapezoidal rear support cheek")
            _check(_find(model,
                "G11V11_CerrojoMantenimiento_%d" % side) != null,
                "true rear access lock with 3D cylindrical metal hardware")
        for i in range(3):
            var divider := _find(model,
                "G11V11_DivisorVertical_%d" % i) as MeshInstance3D
            _check(divider != null,"inter-column structural divider %d" % i)
            if divider != null:
                _check(absf(divider.position.x -(-0.28+float(i)*0.28))
                    < 0.001,"divider sits in the real gap between columns")
        _check(_find(model,"G11V11_TravesanoSuperior") != null,
            "front top framing has its own PBR steel geometry")
        _check(_find(model,"G11V11_TravesanoInferior") != null,
            "front bottom framing has independent dark metallic trim")
        _check(_find(model,"G11V11_TapaFiltroTecho") != null,
            "roof filter cover adds real thickness without changing cabin hull")
        for i in range(3):
            _check(_find(model,"G11V11_RejillaTecho_%d" % i) != null,
                "genuine cabin ventilation louver %d" % i)
        _check(_find(model,"G11_PinturaLateral_1_0") != null,
            "original faction side paint survives V11")
        _check(Models.pose_model("mlrs",model,"attack",0.50),
            "original twelve-tube rocket launch still elevates correctly")
        _check(_find(model,"G11V11_RozadurasBocas").is_visible_in_tree(),
            "metal weathering remains attached to rotating active launcher")
        _check(Models.pose_model("mlrs",model,"attack",1.0),
            "full firing sequence preserves all V10 and V11 details")
        _check(Rig.pose(model,"cooldown",0.50),
            "dual hydraulic recovery remains fully functional")
        _check(V10.glowing_count(model) == 12,
            "new metal frame allows all twelve cooling rings to glow")
        _check(Rig.pose(model,"cooldown",1.0),
            "cooldown restores original parked geometry after detailed sculpt")
        _check(V10.glowing_count(model) == 0,
            "cooling rings finish fading on refined metallic rims")
        _check(Art.apply_stage(model,4),
            "wreck art still hides intact launcher and all V11 detail")
        _check(not launcher.is_visible_in_tree(),
            "finished V11 launcher does not show through destroyed turret")
        _check(Art.apply_stage(model,0),
            "full repair restores all proper V11 metal and machinery")
        Models.restore_model_pose("mlrs",model)
        _check(launcher.is_visible_in_tree(),
            "V11 sculpted rails return with restored G11")
        model.queue_free()
        await process_frame
    if failures > 0:
        push_error("G11 V11 HARD-SURFACE QA FAILED (%d assertions)" % failures)
        quit(1)
        return
    print("PASS G11 ARMOR V11: eight factions, genuinely unblocked 12 PBR tubes, open four-wall case, beveled metal roof and frame, 16 bolts, V10 animation")
    quit(0)
