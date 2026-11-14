extends RefCounted
class_name TarvokaTankTrackAlignmentV31

# Final mechanical correction: V30 widened the authentic 84+84 tread shoes
# but left their axles at the old OUTBOARD x=1.335. Their outer edges reached
# x=1.546, overhanging both end sprockets and the armored skirt.
# V31 moves the COMPLETE running-gear assembly INBOARD as one coherent axle:
# 168 shoes, 4 sprockets, 4 end hubs, 48 teeth, 14 wheels, 14 wheel hubs and
# two 35-spoke batches. Nothing about the 0.422m tread width, materials,
# hull, turret, 5 damage stages or bullet/explosion animations is changed.
const Tracks = preload("res://scripts/ui/TankFinalTracksV29.gd")
const WheelSpokes = preload("res://scripts/ui/TankDetailV14.gd")
const ROOT := "G09V31OrugasAlineadasAlInterior"
const TRACK_CENTER_X := 1.145
const ROAD_WHEEL_X := TRACK_CENTER_X
const HUB_X := 1.192
const SPOKE_X := 1.198
const TOOTH_X := TRACK_CENTER_X + 0.022
const MAX_TRACK_OUTER_X := 1.365
const EXPECTED_OUTER_X := TRACK_CENTER_X + Tracks.TRACK_WIDTH_V30*0.5

static func apply(model: Node3D) -> bool:
    if model==null or not model.get_meta("tarvoka_mbt_track_wide_v30",false):
        return false
    if model.get_meta("tarvoka_mbt_tracks_inboard_v31",false):
        return false
    if EXPECTED_OUTER_X>MAX_TRACK_OUTER_X:
        return false
    # Preflight all required geometry BEFORE mutating even a single node.
    for side in [-1,1]:
        for index in range(7):
            if not (model.find_child("RuedaG09V7_%s_%02d" % [side,index],
                    true,false) is MeshInstance3D):
                return false
            if not (model.find_child("BujeG09V7_%s_%02d" % [side,index],
                    true,false) is MeshInstance3D):
                return false
        for end in [-1,1]:
            if not (model.find_child("RuedaMotrizG09_%s_%s" % [side,end],
                    true,false) is MeshInstance3D):
                return false
            if not (model.find_child("EjeMotrizG09_%s_%s" % [side,end],
                    true,false) is MeshInstance3D):
                return false
        var spoke: MultiMeshInstance3D = model.find_child(
            "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
        if spoke==null or spoke.multimesh==null or (
                spoke.multimesh.instance_count!=35):
            return false
        var track: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        if track==null or track.multimesh==null or (
                track.multimesh.instance_count!=Tracks.SHOE_COUNT):
            return false
    for side in [-1,1]:
        var x: float = float(side)
        for index in range(7):
            var wheel: MeshInstance3D = model.find_child(
                "RuedaG09V7_%s_%02d" % [side,index],true,false) as MeshInstance3D
            var hub: MeshInstance3D = model.find_child(
                "BujeG09V7_%s_%02d" % [side,index],true,false) as MeshInstance3D
            wheel.position.x=x*ROAD_WHEEL_X
            hub.position.x=x*HUB_X
        for end in [-1,1]:
            var drum: MeshInstance3D = model.find_child(
                "RuedaMotrizG09_%s_%s" % [side,end],true,false) as MeshInstance3D
            var drive_hub: MeshInstance3D = model.find_child(
                "EjeMotrizG09_%s_%s" % [side,end],true,false) as MeshInstance3D
            drum.position.x=x*ROAD_WHEEL_X
            drive_hub.position.x=x*HUB_X
    # These two metadata values are consumed by the existing per-frame
    # animation functions. WITHOUT them, movement snaps tracks/spokes back
    # outboard after an otherwise correct static initial screenshot.
    model.set_meta("tarvoka_track_axle_x_v31",TRACK_CENTER_X)
    model.set_meta("tarvoka_wheel_spokes_x_v31",SPOKE_X)
    model.set_meta("tarvoka_mbt_tracks_inboard_v31",true)
    model.set_meta("tarvoka_track_outer_x_v31",EXPECTED_OUTER_X)
    WheelSpokes.animate_wheels(model,0.0)
    Tracks.slide_tracks(model,0.0)
    var marker:=Node3D.new()
    marker.name=ROOT
    model.add_child(marker)
    return true
