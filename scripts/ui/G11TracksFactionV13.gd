extends RefCounted
class_name TarvokaG11TracksFactionV13

# G11 V13 physical gear correction + durable faction paint.
# The original sprockets floated ~0.206 m outward of the belt centerline,
# had undersized 0.235 m teeth against an inner belt radius of 0.265 m,
# doubled up with V2 solid rollers and turned 720 degrees for only 2.15 m
# of shoe travel. This revision corrects the actual native geometry and
# kinematics, not an illustrative render. No gameplay rules are modified.
const FLAG := "tarvoka_g11_tracks_faction_v13"
const ROOT := "G11_CascoRaiz"
const ELEVATION := "G11_ElevacionLanzador"
const _FINISH = preload("res://scripts/ui/G11FinishV2.gd")
const TRACK_X: float = 0.79
const TRACK_Y: float = 0.35
const AXLE_Z: float = 1.04
const PITCH_RADIUS: float = 0.258
const TIPS_RADIUS: float = 0.265
const DRIVE_TEETH: int = 10
const SPOKES: int = 8
static var _drive_mesh: ArrayMesh
static var _idler_mesh: ArrayMesh
static var _hub_mesh: CylinderMesh

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _on_x(x: float, radius: float, a: float) -> Vector3:
    return Vector3(x,radius*cos(a),radius*sin(a))

static func _triangle(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    _triangle(st,a,b,c)
    _triangle(st,a,c,d)

static func _ring_segment(st: SurfaceTool, x: float,
        inner: float, outer_a: float, outer_b: float,
        angle_a: float, angle_b: float) -> void:
    _quad(st,_on_x(x,inner,angle_a),_on_x(x,inner,angle_b),
        _on_x(x,outer_b,angle_b),_on_x(x,outer_a,angle_a))

static func _gear_mesh(drive: bool) -> ArrayMesh:
    # Annular gear with genuinely open-spoke windows, actual teeth cut into
    # the outer circumference, and a bearing hole. The outward face lies
    # beyond the track's exterior skin but the teeth remain INSIDE the belt.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = DRIVE_TEETH*4 if drive else 60
    var back: float = 0.124
    var front: float = 0.180
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        var ra: float = 0.253
        var rb: float = 0.253
        if drive:
            ra = TIPS_RADIUS if i%4 == 1 or i%4 == 2 else 0.247
            rb = TIPS_RADIUS if (i+1)%4 == 1 or (i+1)%4 == 2 else 0.247
        # Side annulus: the eight negative-space apertures remain open.
        _ring_segment(st,front,0.171,ra,rb,a,b)
        _ring_segment(st,back,0.171,ra,rb,b,a)
        _quad(st,_on_x(back,ra,a),_on_x(back,rb,b),
            _on_x(front,rb,b),_on_x(front,ra,a))
        _quad(st,_on_x(back,0.171,b),_on_x(back,0.171,a),
            _on_x(front,0.171,a),_on_x(front,0.171,b))
        # A separate annular bearing hub has a true center aperture.
        _ring_segment(st,front+0.008,0.044,0.107,0.107,a,b)
        _ring_segment(st,back,0.044,0.107,0.107,b,a)
        _quad(st,_on_x(back,0.044,a),_on_x(back,0.044,b),
            _on_x(front+0.008,0.044,b),_on_x(front+0.008,0.044,a))
    # Eight narrow steel spokes connect hub and toothed outer rim, but they
    # never fill the real open slots between spokes.
    for spoke in range(SPOKES):
        var angle: float = TAU*float(spoke)/float(SPOKES)
        var a: float = angle-0.068
        var b: float = angle+0.068
        for x in [back,front]:
            _ring_segment(st,x,0.101,0.179,0.179,a,b)
        _quad(st,_on_x(back,0.104,a),_on_x(front,0.104,a),
            _on_x(front,0.174,a),_on_x(back,0.174,a))
        _quad(st,_on_x(back,0.104,b),_on_x(back,0.174,b),
            _on_x(front,0.174,b),_on_x(front,0.104,b))
    st.generate_normals()
    st.set_material(_mat(Color("#748582") if drive else Color("#889592"),
        0.72 if drive else 0.61,0.46 if drive else 0.56))
    return st.commit()

static func _hub() -> CylinderMesh:
    if _hub_mesh == null:
        _hub_mesh = CylinderMesh.new()
        _hub_mesh.top_radius = 0.057
        _hub_mesh.bottom_radius = 0.057
        _hub_mesh.height = 0.022
        _hub_mesh.radial_segments = 12
        _hub_mesh.material = _mat(Color("#273333"),0.45,0.71)
    return _hub_mesh

static func _add_hub(gear: MeshInstance3D, side: int,
        rear: bool) -> void:
    var cap := MeshInstance3D.new()
    cap.name = "G11V13_CabezalEje_%s" % ("impulsor" if rear else "tensor")
    cap.mesh = _hub()
    cap.position = Vector3(0.199,0,0)
    cap.rotation_degrees.z = 90.0
    gear.add_child(cap)
    # Six rivets on actual moving axle; no stationary fake overlay.
    var bolt := CylinderMesh.new()
    bolt.top_radius = 0.012
    bolt.bottom_radius = 0.012
    bolt.height = 0.011
    bolt.radial_segments = 7
    bolt.material = _mat(Color("#a5b0a9"),0.76,0.38)
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = bolt
    mm.instance_count = 6
    for i in range(6):
        var a: float = TAU*float(i)/6.0
        var pos := Vector3(0.198,cos(a)*0.078,sin(a)*0.078)
        mm.set_instance_transform(i,Transform3D(
            Basis(Vector3.FORWARD,PI*0.5),pos))
    var heads := MultiMeshInstance3D.new()
    heads.name = "G11V13_PernosEje_%s" % ("impulsor" if rear else "tensor")
    heads.multimesh = mm
    gear.add_child(heads)

static func _remove(root: Node3D, name: String) -> void:
    var existing: Node = root.find_child(name,true,false)
    if existing != null:
        existing.get_parent().remove_child(existing)
        existing.free()

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, material: Material) -> MeshInstance3D:
    var geom := BoxMesh.new()
    geom.size = size
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = geom
    part.position = pos
    part.material_override = material
    parent.add_child(part)
    return part

static func apply(model: Node3D, paint: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_cab_chassis_v12",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if root == null or launcher == null:
        return false
    var pod_top := launcher.find_child(
        "G11_TapaSuperior",true,false) as MeshInstance3D
    if pod_top == null:
        return false
    if _drive_mesh == null:
        _drive_mesh = _gear_mesh(true)
        _idler_mesh = _gear_mesh(false)
    for side in [-1,1]:
        var sign: float = float(side)
        # The old V2 solid idler duplicates the V5 sprocket and is visibly
        # offset in X. Remove that extra wheel on each end of BOTH belts.
        for old in range(2):
            _remove(root,"G11V2_RuedaTensor_%d_%d" % [side,old])
        _remove(root,"G11V5_TapaEje_%d" % side)
        var front := root.find_child(
            "G11V5_TensorDelantero_%d" % side,true,false) as MeshInstance3D
        var drive := root.find_child(
            "G11V5_PinionTrasero_%d" % side,true,false) as MeshInstance3D
        if front == null or drive == null:
            return false
        front.mesh = _idler_mesh
        drive.mesh = _drive_mesh
        for item in [front,drive]:
            var is_rear: bool = item == drive
            item.position = Vector3(sign*TRACK_X,TRACK_Y,
                AXLE_Z if is_rear else -AXLE_Z)
            item.scale = Vector3(-1,1,1) if side < 0 else Vector3.ONE
            _add_hub(item,side,is_rear)
        # Additional pressure-resistant axle guard is a 3D brace welded to
        # chassis, not another disconnected solid sprocket disk.
        var dark := _mat(Color("#333e3e"),0.40,0.70)
        _box(root,"G11V13_SoporteEje_%d" % side,
            Vector3(sign*0.710,0.36,1.04),
            Vector3(0.085,0.114,0.18),dark)
    # Repaint the genuine octagonal roof mesh itself, not a floating decal:
    # most of the upper rocket pod is now faction-colored, while the V11
    # three dark ribs, metal chamfers and the 12 interiors remain readable.
    var finish := _mat(paint,0.33,0.51)
    pod_top.material_override = finish
    var accent := _mat(paint.darkened(0.08),0.38,0.55)
    for side in [-1,1]:
        var sign: float = float(side)
        # Flank panels are large enough for tactical team readability
        # without overpainting the weathered metal of the front or rear.
        _box(launcher,"G11V13_PanelFaccionLanzador_%d" % side,
            Vector3(sign*0.714,0.12,-0.33),
            Vector3(0.019,0.25,0.61),accent)
        _box(root,"G11V13_BandaFaccionCabina_%d" % side,
            Vector3(sign*0.517,1.552,-0.88),
            Vector3(0.083,0.011,0.30),accent)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v13_sprocket_pitch_radius",PITCH_RADIUS)
    model.set_meta("tarvoka_g11_v13_drive_teeth",DRIVE_TEETH)
    model.set_meta("tarvoka_g11_v13_faction_paint",paint)
    model.set_meta("tarvoka_g11_v5_sprocket_teeth",DRIVE_TEETH)
    return update_tracks(model,0.0)

static func update_tracks(model: Node3D, progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    var radians: float = progress*_FINISH.LINK_TRAVEL/PITCH_RADIUS
    var angle: float = rad_to_deg(radians)
    for side in [-1,1]:
        for role in ["TensorDelantero","PinionTrasero"]:
            var name: String = "G11V5_%s_%d" % [role,side]
            var gear := root.find_child(name,true,false) as Node3D
            if gear == null:
                return false
            gear.rotation_degrees.x = angle
    return true
