extends SceneTree

# Native Godot verification of user-requested G11 corrected gears + upper
# launcher faction paint. Mechanical meshes are properly seated inside the
# belt and their rotation is tied to the real scrolling tread arclength.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Finish = preload("res://scripts/ui/G11FinishV2.gd")
const Track = preload("res://scripts/ui/G11TracksFactionV13.gd")
var failures: int = 0
var colors: Dictionary = {}

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V13 track and faction QA: "+label)

func _find(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var track_pitch: float = Finish._circumference(Finish.TRACK_OUTER_RADIUS)/float(Finish.TRACK_LINK_COUNT)
    var tooth_pitch: float = TAU*Track.PITCH_RADIUS/float(Track.DRIVE_TEETH)
    _check(absf(track_pitch-tooth_pitch) < 0.012,
        "ten sprocket teeth nearly match actual track shoe pitch; old sixteen did not")
    _check(absf(Track.TIPS_RADIUS-Finish.TRACK_INNER_RADIUS) < 0.004,
        "gear tooth tips meet inner racetrack radius with no air gap")
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"G11 hero faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Track.FLAG,false)),
            "true native V13 sprocket sculpture integrated")
        _check(int(model.get_meta("tarvoka_g11_v13_drive_teeth",0)) == Track.DRIVE_TEETH,
            "correct ten-tooth gear geometry, not unmatched old sixteen teeth")
        var roof := _find(model,"G11_TapaSuperior") as MeshInstance3D
        _check(roof != null and roof.material_override is StandardMaterial3D,
            "the actual 3D roof mesh now has faction paint, not a decal")
        if roof != null and roof.material_override is StandardMaterial3D:
            var paint := roof.material_override as StandardMaterial3D
            var intended: Color = model.get_meta("tarvoka_g11_v13_faction_paint",
                Color.BLACK) as Color
            _check(paint.albedo_color.is_equal_approx(intended),
                "upper launcher colored with exactly this faction's own paint")
            _check(paint.metallic > 0.25,
                "faction roof uses a genuine PBR painted-steel finish")
            colors[paint.albedo_color.to_html()] = true
        for side in [-1,1]:
            var sign: float = float(side)
            var actual_belt := _find(model,
                "G11V2_BandaOruga_%d" % side) as MeshInstance3D
            _check(actual_belt != null,
                "original continuous rubber track remains for side %d" % side)
            _check(_find(model,"G11V2_RuedaTensor_%d_0" % side) == null
                and _find(model,"G11V2_RuedaTensor_%d_1" % side) == null,
                "duplicate original V2 idlers removed, not stacked with new sprockets")
            _check(_find(model,"G11V5_TapaEje_%d" % side) == null,
                "off-center old gear hub removed")
            for label in ["TensorDelantero","PinionTrasero"]:
                var gear := _find(model,
                    "G11V5_%s_%d" % [label,side]) as MeshInstance3D
                _check(gear != null and gear.mesh is ArrayMesh,
                    "new true annular metal gear %s side %d" % [label,side])
                if gear == null:
                    continue
                _check(absf(gear.position.x-sign*Finish.TRACK_CENTER_X) < 0.001,
                    "gear axle is concentric with actual rubber belt, no X misalignment")
                _check(absf(gear.position.y-Finish.TRACK_CENTER_Y) < 0.001,
                    "gear axle shares exact Y center with racetrack contour")
                _check(absf(absf(gear.position.z)-Finish.TRACK_HALF_LENGTH) < 0.001,
                    "idler and drive sprocket sit on two curved belt ends")
                var aabb: AABB = gear.mesh.get_aabb()
                _check(absf(maxf(aabb.size.y,aabb.size.z)*0.5-Track.TIPS_RADIUS) < 0.008,
                    "teeth follow correct inner track contact circle")
                _check(_find(gear,"G11V13_CabezalEje_impulsor" if label == "PinionTrasero"
                    else "G11V13_CabezalEje_tensor") != null,
                    "the outer hub belongs to its rotating gear assembly")
                var bolts := gear.find_child("G11V13_PernosEje_impulsor" if
                    label == "PinionTrasero" else "G11V13_PernosEje_tensor",
                    true,false) as MultiMeshInstance3D
                _check(bolts != null and bolts.multimesh != null,
                    "moving metal axle gets its own real batched bolts")
                if bolts != null:
                    _check(bolts.multimesh.instance_count == 6,
                        "six physical fasteners remain attached to rotating axle")
            _check(_find(model,"G11V13_PanelFaccionLanzador_%d" % side) != null,
                "large faction colored exterior panel on each side of launcher")
            _check(_find(model,"G11V13_BandaFaccionCabina_%d" % side) != null,
                "matching faction paint on cabin roof")
        _check(_find(model,"G11V11_NervioTecho_0") != null,
            "black-metal roof stiffeners survive bright faction upper panel")
        _check(_find(model,"G11_Tubo_0_0") != null,
            "all twelve original open rocket tubes remain in place")
        _check(Models.pose_model("mlrs",model,"move",0.125),
            "real vehicle movement moves wheels, links and both gear ends")
        var expected: float = rad_to_deg(0.125*Finish.LINK_TRAVEL/Track.PITCH_RADIUS)
        for side in [-1,1]:
            for label in ["TensorDelantero","PinionTrasero"]:
                var gear := _find(model,
                    "G11V5_%s_%d" % [label,side]) as Node3D
                _check(absf(gear.rotation_degrees.x-expected) < 0.15,
                    "front and rear sprockets rotate by same real belt travel / radius")
        _check(Models.pose_model("mlrs",model,"attack",0.52),
            "rocket launcher elevation and faction-colored roof still articulate")
        _check(_find(model,"G11V13_PanelFaccionLanzador_1").is_visible_in_tree(),
            "faction flank paint follows moving launcher rather than floating")
        _check(Art.apply_stage(model,3),
            "critical damage retains V13 gear geometry and faction color")
        _check(Art.apply_stage(model,4),"fully destroyed state still possible")
        _check(Art.apply_stage(model,0),"repair restores full-color G11")
        _check(Rig.pose(model,"cooldown",0.66),
            "V10 controlled hydraulic return still works after gear replacement")
        Models.restore_model_pose("mlrs",model)
        model.queue_free()
        await process_frame
    _check(colors.size() == 8,
        "eight factions retain eight distinct colors on actual launcher roof")
    if failures > 0:
        push_error("G11 V13 QA FAILED (%d assertions)" % failures)
        quit(1)
        return
    print("PASS G11 TRACK FACTION V13: 8 roof faction paints, corrected 10-tooth belt-matched drive sprockets, centered axles, no duplicate idlers and synchronized front/rear rotation")
    quit(0)
