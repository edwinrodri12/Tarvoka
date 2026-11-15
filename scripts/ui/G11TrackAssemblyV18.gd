extends RefCounted
class_name TarvokaG11TrackAssemblyV18

# V18 final assembly clearance: removes duplicate legacy flank boxes, lifts
# actual steel mudguard above the animated rubber and verifies no road wheels
# intersect one another or either end sprocket. Actual Godot meshes, not art.
# Only presentation geometry: preserve every approved faction and game stat.
const FLAG := "tarvoka_g11_track_clearance_v18"
const ROOT := "G11_CascoRaiz"
const ROAD_WHEELS := 6
const ROAD_Z_START := -0.875
const ROAD_Z_STEP := 0.350
const ROAD_RADIUS := 0.165
const GEAR_RADIUS := 0.265
const AXLE_Z := 1.34
const SIDE_X := 0.79
const FENDER_Z_LENGTH := 2.90
const SKIRT_Y := 0.811
const SKIRT_HEIGHT := 0.091
const RUBBER_TOP := 0.35+0.35+0.011+0.021
const _SIDES := [-1,1]

static func _delete(root: Node3D, label: String) -> bool:
    var old := root.find_child(label,true,false)
    if old == null:
        return false
    old.get_parent().remove_child(old)
    old.free()
    return true

static func _material() -> StandardMaterial3D:
    var steel := StandardMaterial3D.new()
    steel.albedo_color = Color("#52615f")
    steel.metallic = 0.48
    steel.roughness = 0.76
    return steel

static func _bolt_mesh() -> CylinderMesh:
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color("#9baca5")
    metal.metallic = 0.67
    metal.roughness = 0.48
    var shape := CylinderMesh.new()
    shape.top_radius = 0.014
    shape.bottom_radius = 0.014
    shape.height = 0.019
    shape.radial_segments = 8
    shape.material = metal
    return shape

static func _verify_positions(root: Node3D) -> bool:
    for side in _SIDES:
        var sign: float = float(side)
        var wheel_centers: Array[float] = []
        for wheel in range(ROAD_WHEELS):
            var pivot := root.find_child(
                "G11_RuedaPivot_%d_%d" % [side,wheel],
                true,false) as Node3D
            var body := root.find_child(
                "G11V5_LlantaEsculpida_%d_%d" % [side,wheel],
                true,false) as MeshInstance3D
            if pivot == null or body == null:
                return false
            var z: float = ROAD_Z_START+float(wheel)*ROAD_Z_STEP
            if absf(pivot.position.z-z) > 0.0001:
                return false
            # The outward-facing wheel annulus is 0.018 + 0.109 m
            # from its track's X center, well inside outer belt face 0.142.
            if absf(body.position.x) > 0.020:
                return false
            if absf(pivot.position.x-sign*SIDE_X) > 0.001:
                return false
            wheel_centers.append(z)
        for i in range(wheel_centers.size()):
            if i > 0 and (
                wheel_centers[i]-wheel_centers[i-1]
                < 2.0*ROAD_RADIUS+0.010):
                return false
            if AXLE_Z-absf(wheel_centers[i]) < (
                    GEAR_RADIUS+ROAD_RADIUS+0.015):
                return false
        for role in ["TensorDelantero","PinionTrasero"]:
            var gear := root.find_child(
                "G11V5_%s_%d" % [role,side],true,false
            ) as MeshInstance3D
            if gear == null or not gear.mesh is ArrayMesh:
                return false
            if absf(gear.position.x-sign*SIDE_X) > 0.001:
                return false
            if absf(absf(gear.position.z)-AXLE_Z) > 0.001:
                return false
        var skirt := root.find_child(
            "G11_Faldon_%d" % side,true,false) as MeshInstance3D
        if skirt == null or not skirt.mesh is BoxMesh:
            return false
        var shape := skirt.mesh as BoxMesh
        if skirt.position.y-shape.size.y*0.5 < RUBBER_TOP+0.016:
            return false
    return true

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta(
            "tarvoka_g11_surface_weather_v17",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    for side in _SIDES:
        var links := root.find_child(
            "G11V2_OrugaAnimada_%d" % side,true,false
        ) as MultiMeshInstance3D
        if links == null or links.multimesh == null or (
                links.multimesh.instance_count != 46):
            return false
        var band := root.find_child(
            "G11V2_BandaOruga_%d" % side,true,false
        ) as MeshInstance3D
        if band == null or band.mesh == null:
            return false
        var guard := root.find_child(
            "G11_Faldon_%d" % side,true,false
        ) as MeshInstance3D
        if guard == null or not guard.mesh is BoxMesh:
            return false
    # Old V1 three-piece lateral metal armor and matching paint were still
    # sculpted in precisely the same place as the replacement V2 armor.
    var removed: int = 0
    var bolt_geometry := _bolt_mesh()
    for side in _SIDES:
        var sign: float = float(side)
        for panel in range(3):
            for label in ["G11_PanelLateral_%d_%d",
                    "G11_PinturaLateral_%d_%d"]:
                if _delete(root,label % [side,panel]):
                    removed += 1
        var guard := root.find_child(
            "G11_Faldon_%d" % side,true,false
        ) as MeshInstance3D
        # Instead of a broad sheet intersecting the rubber crown, the
        # original piece becomes one narrow, fitted steel fender above it.
        guard.position = Vector3(sign*0.880,SKIRT_Y,-0.020)
        var guard_shape := (guard.mesh as BoxMesh).duplicate() as BoxMesh
        guard_shape.size = Vector3(0.185,SKIRT_HEIGHT,FENDER_Z_LENGTH)
        guard.mesh = guard_shape
        guard.material_override = _material()

        var team_band := root.find_child(
            "G11V2_BandaFaccion_%d" % side,
            true,false) as MeshInstance3D
        if team_band == null:
            return false
        # The factory marking now slightly intersects, rather than floats
        # above, the true V2 armor side surface.
        team_band.position.x = sign*0.751

        # Visible metal fasteners are anchored to the relocated skirt's
        # *outer face*, not scattered over the moving rubber track.
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = bolt_geometry
        mm.instance_count = 4
        for n in range(4):
            var x: float = sign*(0.880+0.185*0.5+0.004)
            var z: float = -1.18+float(n)*0.78
            mm.set_instance_transform(n,Transform3D(
                Basis(Vector3.FORWARD,PI*0.5),
                Vector3(x,SKIRT_Y,z)))
        var rivets := MultiMeshInstance3D.new()
        rivets.name = "G11V18_PernosGuardabarros_%d" % side
        rivets.multimesh = mm
        root.add_child(rivets)

    # A failed mesh seam/clearance must not get stamped as approved geometry.
    if not _verify_positions(root):
        return false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v18_legacy_overlays_removed",removed)
    model.set_meta("tarvoka_g11_v18_roadwheels",12)
    model.set_meta("tarvoka_g11_v18_shoe_links_per_side",46)
    return removed == 12
