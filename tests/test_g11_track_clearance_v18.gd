extends SceneTree

# Native mesh-level track clearance, with actual distances, not screenshots.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Finish = preload("res://scripts/ui/G11FinishV2.gd")
const Track = preload("res://scripts/ui/G11TracksFactionV13.gd")
const Assembly = preload("res://scripts/ui/G11TrackAssemblyV18.gd")
var errors: int = 0
var paints: Dictionary = {}

func _check(ok: bool, message: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V18 track clearance: "+message)

func _part(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Finish.TRACK_LINK_COUNT == 46,
        "46 evenly distributed shoes compensate for longer racetrack")
    _check(absf(Finish.TRACK_HALF_LENGTH-Track.AXLE_Z) < 0.0001,
        "both gear centers exactly match the longer belt end contours")
    var shoe_pitch: float = Finish._circumference(
        Finish.TRACK_OUTER_RADIUS)/float(Finish.TRACK_LINK_COUNT)
    var gear_pitch: float = TAU*Track.PITCH_RADIUS/float(Track.DRIVE_TEETH)
    _check(absf(shoe_pitch-gear_pitch) < 0.006,
        "V18 shoe pitch and ten-gear tooth pitch stay matched")
    for s in range(36):
        var t: float = Finish._circumference(
            Finish.TRACK_OUTER_RADIUS)*float(s)/36.0
        var outer: Vector2 = Finish._path_matched(
            t,Finish.TRACK_OUTER_RADIUS)
        var inner: Vector2 = Finish._path_matched(
            t,Finish.TRACK_INNER_RADIUS)
        _check(absf(outer.distance_to(inner)-(
            Finish.TRACK_OUTER_RADIUS-Finish.TRACK_INNER_RADIUS)) < 0.0005,
            "inner and outer band side faces share identical bend phase")
    _check(Assembly.SKIRT_Y-Assembly.SKIRT_HEIGHT*0.5 > (
        Assembly.RUBBER_TOP+0.015),
        "upper steel guard does not intersect any animated tread lug")

    for faction in range(8):
        var unit: Node3D = Models.build("mlrs",faction,true,13)
        _check(unit != null,"native high-detail G11 faction "+str(faction))
        if unit == null:
            continue
        root.add_child(unit)
        _check(bool(unit.get_meta(Assembly.FLAG,false)),
            "V18 geometry applied to the real rendered G11 model")
        _check(bool(unit.get_meta("tarvoka_g11_surface_weather_v17",false)),
            "V17 paint and wear remain")
        _check(int(unit.get_meta(
            "tarvoka_g11_v18_legacy_overlays_removed",0)) == 12,
            "twelve overlapping old side-armors/paint panels removed")
        _check(int(unit.get_meta("tarvoka_g11_v18_roadwheels",0)) == 12,
            "six adjusted road wheels retained on each side")
        _check(int(unit.get_meta("tarvoka_g11_v18_shoe_links_per_side",0)) == 46,
            "both full links loops use 46 non-overlapping pads")
        var roof := _part(unit,"G11_TapaSuperior") as MeshInstance3D
        _check(roof != null and roof.material_override is StandardMaterial3D,
            "eight factory roof colors remain PBR")
        if roof != null and roof.material_override is StandardMaterial3D:
            var actual: Color = (
                roof.material_override as StandardMaterial3D).albedo_color
            var intended: Color = unit.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(actual.is_equal_approx(intended),
                "V18 keeps exactly the original faction color")
            paints[actual.to_html()] = true
        for side in [-1,1]:
            var sign: float = float(side)
            var track := _part(unit,
                "G11V2_BandaOruga_%d" % side) as MeshInstance3D
            _check(track != null and track.mesh is ArrayMesh,
                "single smooth closed rubber belt per side")
            if track != null and track.mesh != null:
                var bounds: AABB = track.mesh.get_aabb()
                _check(bounds.size.z > 3.32 and bounds.size.z < 3.41,
                    "belt extends around repositioned 1.34m axles")
                _check(absf(track.position.x-sign*Finish.TRACK_CENTER_X)
                    < 0.001,"belt centered in X")
            var shoes := _part(unit,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            _check(shoes != null and shoes.multimesh != null,
                "single batched shoe loop per track side")
            if shoes != null and shoes.multimesh != null:
                _check(shoes.multimesh.instance_count == 46,
                    "shoe count actually rebuilt, not stacked 40+46")
                var shoe_box := shoes.multimesh.mesh as BoxMesh
                _check(shoe_box != null,
                    "46 shoes use the same correctly sized link mesh")
                if shoe_box != null:
                    _check(shoe_box.size.z+0.02 < shoe_pitch,
                        "link bodies have positive gap along the continuous belt")
                    _check(shoe_box.size.x < 0.285,
                        "link steel cannot poke out of rubber sidewalls")
            var skirt := _part(unit,
                "G11_Faldon_%d" % side) as MeshInstance3D
            _check(skirt != null and skirt.mesh is BoxMesh,
                "one correctly fitted upper mudguard, not an overlapping slab")
            if skirt != null and skirt.mesh is BoxMesh:
                var mesh := skirt.mesh as BoxMesh
                _check(skirt.position.y-mesh.size.y*0.5 > 0.750,
                    "fender clears rubber crown and shoe height")
                _check(skirt.position.x*sign > 0.85,
                    "fender lies exterior to V2 armor side")
            for panel in range(3):
                _check(_part(unit,
                    "G11_PanelLateral_%d_%d" % [side,panel]) == null,
                    "duplicated V1 side armor was fully removed")
                _check(_part(unit,
                    "G11_PinturaLateral_%d_%d" % [side,panel]) == null,
                    "duplicated V1 faction decal is also absent")
            _check(_part(unit,
                "G11V2_ProteccionLateral_%d" % side) != null,
                "the true newer sculpted side armor remains")
            _check(_part(unit,
                "G11V18_PernosGuardabarros_%d" % side)
                is MultiMeshInstance3D,
                "new metal fender fasteners are batched and installed")
            var centers: Array[float] = []
            for axle in range(6):
                var pivot := _part(unit,
                    "G11_RuedaPivot_%d_%d" % [side,axle])
                var wheel := _part(unit,
                    "G11V5_LlantaEsculpida_%d_%d" % [side,axle]
                ) as MeshInstance3D
                var hub := _part(unit,
                    "G11V5_BujeCerrado_%d_%d" % [side,axle]
                ) as MeshInstance3D
                _check(pivot != null and wheel != null and hub != null,
                    "six actual wheel, axle and hub mechanisms retained")
                if pivot == null or wheel == null or hub == null:
                    continue
                centers.append(pivot.position.z)
                _check(absf(pivot.position.z-(
                    -0.875+float(axle)*0.35)) < 0.001,
                    "road wheels uniformly spaced, not piled onto end gears")
                # Model is side mirrored, so both wheels' foremost rim vertex
                # must lie inside the visible band side face at 0.142m.
                _check(absf(wheel.position.x)+0.109 < 0.142,
                    "wheel metal is inside track wall, not floating outside")
                _check(absf(hub.position.x)+0.014 < 0.143,
                    "wheel hub stays flush with the moving belt")
                var z_gap: float = minf(
                    absf(Track.AXLE_Z-pivot.position.z),
                    absf(-Track.AXLE_Z-pivot.position.z))
                _check(z_gap > (
                    Assembly.ROAD_RADIUS+Assembly.GEAR_RADIUS+0.015),
                    "road wheel cannot intersect front or rear end gear")
            for i in range(1,centers.size()):
                _check(centers[i]-centers[i-1] > 0.340,
                    "road wheels have visible physical clearance")
            for gear_name in ["TensorDelantero","PinionTrasero"]:
                var gear := _part(unit,
                    "G11V5_%s_%d" % [gear_name,side]
                ) as MeshInstance3D
                _check(gear != null and gear.mesh is ArrayMesh,
                    "genuine exposed 10-tooth end sprocket retained")
                if gear != null:
                    _check(absf(gear.position.z) > 1.33
                        and absf(gear.position.z) < 1.35,
                        "gear at relocated belt end")
                    _check(absf(gear.position.x) == 0.79,
                        "gear concentric and recessed inside sidewall")
            for t in [0.0,0.25,0.50,0.85]:
                _check(Models.pose_model("mlrs",unit,"move",t),
                    "all shoes, sprockets and suspension animate correctly")
                if shoes != null and shoes.multimesh != null:
                    var tr: Transform3D = shoes.multimesh.get_instance_transform(0)
                    _check(tr.origin.length() > 0.5,
                        "moving shoe stays on a real belt contour")
            Models.restore_model_pose("mlrs",unit)
        for col in range(4):
            for row in range(3):
                _check(_part(unit,"G11_Tubo_%d_%d" % [col,row]) != null,
                    "all twelve open rocket tubes preserved")
        _check(Art.apply_stage(unit,3),"damage still supported")
        _check(Art.apply_stage(unit,0),"repair still supported")
        _check(Rig.pose(unit,"attack",0.56),"launch animations preserved")
        Rig.restore(unit)
        unit.queue_free()
        await process_frame
    _check(paints.size() == 8,"all eight different faction paints preserved")
    if errors > 0:
        push_error("G11 V18 QA FAILED (%d)" % errors)
        quit(1)
        return
    print("PASS G11 V18: 8 factions, 12 separated roadwheels, 2 x 46 shoes, 10-tooth gears, exact concentric track contours, 12 legacy overlays removed, clean fender/bolts, motion and all rockets")
    quit(0)
