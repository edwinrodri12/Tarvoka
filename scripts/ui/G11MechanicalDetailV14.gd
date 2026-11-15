extends RefCounted
class_name TarvokaG11MechanicalDetailV14

# G11 V14: actual Godot meshes, not a 2D concept or overlay.
# Art only: preserves the V13 ten-tooth sprockets, faction roof, rocket bores,
# damage rules, movement distances, ammunition, economy and combat statistics.
const FLAG := "tarvoka_g11_mechanical_detail_v14"
const ROOT := "G11_CascoRaiz"
const TURRET := "G11_GiroPlataforma"
const LAUNCHER := "G11_ElevacionLanzador"
const HOSES_PER_SIDE := 2
const HOSE_SEGMENTS := 7
const _SIDES := [-1,1]

static func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var out := StandardMaterial3D.new()
    out.albedo_color = color
    out.metallic = metallic
    out.roughness = roughness
    return out

static func _mesh(parent: Node3D, name: String, shape: Mesh,
        position: Vector3, material: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = name
    item.mesh = shape
    item.position = position
    item.material_override = material
    parent.add_child(item)
    return item

static func _box(parent: Node3D, name: String, position: Vector3,
        dimensions: Vector3, material: Material) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size = dimensions
    return _mesh(parent,name,shape,position,material)

static func _cyl(parent: Node3D, name: String, position: Vector3,
        radius: float, length: float, material: Material,
        rotate_z: float = 0.0) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = length
    shape.radial_segments = 12
    var item := _mesh(parent,name,shape,position,material)
    item.rotation_degrees.z = rotate_z
    return item

static func _align_segment(item: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var displacement: Vector3 = b-a
    var length: float = displacement.length()
    item.visible = length > 0.0001
    if not item.visible:
        return
    item.position = (a+b)*0.5
    item.quaternion = Quaternion(Vector3.UP,displacement/length)
    item.scale = Vector3(1.0,length,1.0)

static func _hose_point(a: Vector3, b: Vector3,
        control: Vector3, t: float) -> Vector3:
    var u: float = 1.0-t
    return a*u*u + control*2.0*u*t + b*t*t

static func update_hoses(model: Node3D) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var turret := model.find_child(TURRET,true,false) as Node3D
    var elevation := model.find_child(LAUNCHER,true,false) as Node3D
    if turret == null or elevation == null:
        return false
    for side in _SIDES:
        var sign: float = float(side)
        for line in range(HOSES_PER_SIDE):
            # Source stays on the rotating turret; destination follows the
            # elevating launcher through its REAL local transform.
            var start := Vector3(sign*0.565,0.215+float(line)*0.076,0.408)
            var finish: Vector3 = elevation.transform * Vector3(
                sign*0.677,-0.245+float(line)*0.075,0.488)
            # Curved, hanging service slack prevents a rigid disconnected bar
            # when launcher angle changes from idle to attack/cooldown.
            var bend: Vector3 = (start+finish)*0.5 + Vector3(
                sign*0.160,-0.125,0.080)
            for segment in range(HOSE_SEGMENTS):
                var label := "G11V14_Manguera_%d_%d_%02d" % [side,line,segment]
                var link := turret.find_child(label,true,false) as MeshInstance3D
                if link == null:
                    return false
                var a: Vector3 = _hose_point(
                    start,finish,bend,float(segment)/float(HOSE_SEGMENTS))
                var b: Vector3 = _hose_point(
                    start,finish,bend,float(segment+1)/float(HOSE_SEGMENTS))
                _align_segment(link,a,b)
    return true

static func apply(model: Node3D, faction: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_tracks_faction_v13",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    var turret := model.find_child(TURRET,true,false) as Node3D
    var launcher := model.find_child(LAUNCHER,true,false) as Node3D
    if root == null or turret == null or launcher == null:
        return false
    # Guard the mechanics and approved V13 paint instead of overwriting them.
    for component in ["G11_TapaSuperior","G11_Tubo_0_0",
            "G11V13_PanelFaccionLanzador_-1",
            "G11V13_PanelFaccionLanzador_1"]:
        if model.find_child(component,true,false) == null:
            return false

    var metal := _mat(Color("#6f807c"),0.63,0.54)
    var edge := _mat(Color("#263334"),0.39,0.75)
    var black := _mat(Color("#151e20"),0.11,0.91)
    var polished := _mat(Color("#aebbb4"),0.78,0.37)
    var marking := _mat(faction.lightened(0.10),0.35,0.55)

    # Service-access volume at the back of the missile pod, behind all
    # twelve open muzzles: actual depth, perimeter seal and two hinged latches.
    _box(launcher,"G11V14_RegistroTrasero",
        Vector3(0,-0.153,0.994),Vector3(0.390,0.268,0.028),edge)
    _box(launcher,"G11V14_PuertaRegistro",
        Vector3(0,-0.153,1.011),Vector3(0.337,0.217,0.017),metal)
    _box(launcher,"G11V14_RelievePorton",
        Vector3(0,-0.145,1.023),Vector3(0.280,0.018,0.009),black)
    for side in _SIDES:
        var sign: float = float(side)
        _cyl(launcher,"G11V14_BisagraRegistro_%d" % side,
            Vector3(sign*0.136,-0.032,1.026),
            0.022,0.051,polished,90.0)
        _box(launcher,"G11V14_CierreRegistro_%d" % side,
            Vector3(sign*0.136,-0.224,1.033),
            Vector3(0.065,0.033,0.013),black)

        # Exposed steel side inspection doors on the aft half, deliberately
        # behind V13's large forward faction-colored launcher panels.
        _box(launcher,"G11V14_CajaLateral_%d" % side,
            Vector3(sign*0.747,-0.136,0.500),
            Vector3(0.035,0.245,0.304),black)
        _box(launcher,"G11V14_PuertaLateral_%d" % side,
            Vector3(sign*0.771,-0.136,0.500),
            Vector3(0.013,0.197,0.259),metal)
        _box(launcher,"G11V14_SelloLateral_%d" % side,
            Vector3(sign*0.781,-0.136,0.500),
            Vector3(0.009,0.150,0.197),edge)
        _box(launcher,"G11V14_MarcaLateral_%d" % side,
            Vector3(sign*0.787,-0.075,0.478),
            Vector3(0.010,0.029,0.111),marking)
        # Reinforced concentric cheek boss and spindle cover share the
        # elevation node, so they never float away from the rotating pod.
        _cyl(launcher,"G11V14_CoronaEjeElevacion_%d" % side,
            Vector3(sign*0.710,-0.050,0.260),
            0.176,0.038,edge,90.0)
        _cyl(launcher,"G11V14_TapaEjeElevacion_%d" % side,
            Vector3(sign*0.735,-0.050,0.260),
            0.121,0.018,polished,90.0)
        # Two paired hydraulic hose outlets anchored to actual nodes.
        for line in range(HOSES_PER_SIDE):
            _cyl(turret,"G11V14_PuertoBase_%d_%d" % [side,line],
                Vector3(sign*0.565,0.215+float(line)*0.076,0.408),
                0.030,0.049,polished,90.0)
            _cyl(launcher,"G11V14_PuertoLanzador_%d_%d" % [side,line],
                Vector3(sign*0.677,-0.245+float(line)*0.075,0.488),
                0.030,0.044,polished,90.0)
            for segment in range(HOSE_SEGMENTS):
                _cyl(turret,"G11V14_Manguera_%d_%d_%02d" %
                    [side,line,segment],Vector3.ZERO,
                    0.011+float(line)*0.002,1.0,black)
        # Visible lock pins and a support plate under the pivot, with no
        # interference with the V13 road wheels or the missile bores.
        _box(turret,"G11V14_SoporteArticulacion_%d" % side,
            Vector3(sign*0.522,0.175,0.345),
            Vector3(0.087,0.170,0.268),edge)
        _cyl(turret,"G11V14_TornilloSoporte_%d" % side,
            Vector3(sign*0.575,0.175,0.345),
            0.034,0.018,polished,90.0)

    # Small real fasteners along the service door, not photo-textured dots.
    var bolt_shape := CylinderMesh.new()
    bolt_shape.top_radius = 0.014
    bolt_shape.bottom_radius = 0.014
    bolt_shape.height = 0.011
    bolt_shape.radial_segments = 7
    bolt_shape.material = polished
    var bolts := MultiMesh.new()
    bolts.transform_format = MultiMesh.TRANSFORM_3D
    bolts.mesh = bolt_shape
    bolts.instance_count = 8
    var index: int = 0
    for y in [-0.245,-0.060]:
        for x in [-0.151,-0.050,0.050,0.151]:
            bolts.set_instance_transform(index,Transform3D(
                Basis(Vector3.RIGHT,PI*0.5),Vector3(x,y,1.031)))
            index += 1
    var heads := MultiMeshInstance3D.new()
    heads.name = "G11V14_PernosRegistro"
    heads.multimesh = bolts
    launcher.add_child(heads)

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v14_hoses",4)
    model.set_meta("tarvoka_g11_v14_segments",HOSE_SEGMENTS)
    return update_hoses(model)
