extends RefCounted
class_name TarvokaG11CabChassisV12

# G11 V12 hard-surface quality pass: cab, chassis and service equipment.
# Native 3D geometry and PBR metals, not fake surface screenshots.
# Pure visual layer. Never modifies combat, ammunition, stats or faction rules.
const FLAG := "tarvoka_g11_cab_chassis_v12"
const ROOT := "G11_CascoRaiz"
const SIDE_DOOR := "G11V12_PuertaBlindada_"
const SIDE_GLASS := "G11V12_CristalLateral_"
const SIDE_FRAME := "G11V12_MarcoVentanilla_"
const SIDE_STEP := "G11V12_EscalonAntideslizante_"
const REAR_SERVICE := "G11V12_CierrePorton_"
const FASTENERS := 24
const GLASS_COUNT := 2
const LOUVERS := 7
const _SIDES := [-1,1]

static func _mat(color: Color, metal: float, rough: float,
        translucent: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metal
    material.roughness = rough
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if translucent:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

static func _mesh(parent: Node3D, label: String, geometry: Mesh,
        position: Vector3, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = geometry
    part.material_override = material
    part.position = position
    part.rotation_degrees = rotation
    parent.add_child(part)
    return part

static func _box(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, mat: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    return _mesh(parent,label,mesh,pos,mat,angles)

static func _cyl(parent: Node3D, label: String, pos: Vector3,
        radius: float, depth: float, mat: Material,
        rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = depth
    cylinder.radial_segments = 12
    return _mesh(parent,label,cylinder,pos,mat,rot)

static func _tri(st: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _bevel(width: float, height: float,
        thickness: float, bevel: float) -> ArrayMesh:
    # Closed eight-edge slab along Z, real face chamfers and side depth.
    var hx: float = width*0.5
    var hy: float = height*0.5
    var b: float = minf(bevel,minf(hx*0.45,hy*0.45))
    var points: Array[Vector2] = [
        Vector2(-hx+b,-hy),Vector2(hx-b,-hy),
        Vector2(hx,-hy+b),Vector2(hx,hy-b),
        Vector2(hx-b,hy),Vector2(-hx+b,hy),
        Vector2(-hx,hy-b),Vector2(-hx,-hy+b)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(points.size()):
        var j: int = (i+1)%points.size()
        var a: Vector2 = points[i]
        var c: Vector2 = points[j]
        _quad(st,Vector3(a.x,a.y,-thickness*0.5),
            Vector3(c.x,c.y,-thickness*0.5),
            Vector3(c.x,c.y,thickness*0.5),
            Vector3(a.x,a.y,thickness*0.5))
        _tri(st,Vector3(0,0,-thickness*0.5),
            Vector3(c.x,c.y,-thickness*0.5),
            Vector3(a.x,a.y,-thickness*0.5))
        _tri(st,Vector3(0,0,thickness*0.5),
            Vector3(a.x,a.y,thickness*0.5),
            Vector3(c.x,c.y,thickness*0.5))
    st.generate_normals()
    return st.commit()

static func _side_shape(points: Array[Vector2],
        depth: float) -> ArrayMesh:
    # Solid irregular armor side profile in (Y,Z), extruded on X.
    # Faces are triangular fans with thick real sidewalls.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center := Vector2.ZERO
    for p in points:
        center += p
    center /= float(points.size())
    for i in range(points.size()):
        var j: int = (i+1)%points.size()
        var a: Vector2 = points[i]
        var b: Vector2 = points[j]
        _tri(st,Vector3(depth*0.5,center.x,center.y),
            Vector3(depth*0.5,a.x,a.y),
            Vector3(depth*0.5,b.x,b.y))
        _tri(st,Vector3(-depth*0.5,center.x,center.y),
            Vector3(-depth*0.5,b.x,b.y),
            Vector3(-depth*0.5,a.x,a.y))
        _quad(st,Vector3(-depth*0.5,a.x,a.y),
            Vector3(-depth*0.5,b.x,b.y),
            Vector3(depth*0.5,b.x,b.y),
            Vector3(depth*0.5,a.x,a.y))
    st.generate_normals()
    return st.commit()

static func _fastener_batch(root: Node3D, bright: StandardMaterial3D) -> void:
    # 24 real shallow hardware heads, one GPU batch for both side doors and
    # the rear service hatch. Hardware stays parented to the actual chassis.
    var head := CylinderMesh.new()
    head.top_radius = 0.012
    head.bottom_radius = 0.012
    head.height = 0.008
    head.radial_segments = 8
    head.material = bright
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = head
    mm.instance_count = FASTENERS
    var position_index: int = 0
    for side in _SIDES:
        var x: float = float(side)*0.670
        for z in [-1.12,-0.88,-0.65,-0.49]:
            for y in [1.00,1.17]:
                var basis := Basis(Vector3.FORWARD,PI*0.5)
                mm.set_instance_transform(position_index,
                    Transform3D(basis,Vector3(x,y,z)))
                position_index += 1
    for x in [-0.34,-0.20,0.20,0.34]:
        for y in [0.58,0.82]:
            var rear := Basis(Vector3.RIGHT,PI*0.5)
            mm.set_instance_transform(position_index,
                Transform3D(rear,Vector3(x,y,1.548)))
            position_index += 1
    var hardware := MultiMeshInstance3D.new()
    hardware.name = "G11V12_PernosBlindajeLote"
    hardware.multimesh = mm
    root.add_child(hardware)

static func _remove(root: Node3D, name: String) -> void:
    var old := root.find_child(name,true,false)
    if old != null:
        old.get_parent().remove_child(old)
        old.free()

static func _door_shapes() -> Dictionary:
    var armor: Array[Vector2] = [
        Vector2(0.99,-1.19),Vector2(1.18,-1.19),
        Vector2(1.20,-0.92),Vector2(1.17,-0.48),
        Vector2(0.98,-0.48)]
    var window_base: Array[Vector2] = [
        Vector2(1.225,-1.153),Vector2(1.415,-1.080),
        Vector2(1.436,-0.666),Vector2(1.225,-0.600)]
    var window_glass: Array[Vector2] = [
        Vector2(1.246,-1.122),Vector2(1.393,-1.059),
        Vector2(1.414,-0.691),Vector2(1.245,-0.641)]
    return {"armor":_side_shape(armor,0.025),
        "frame":_side_shape(window_base,0.014),
        "glass":_side_shape(window_glass,0.012)}

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_armor_finish_v11",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    var shell := root.find_child("G11V2_CabinaBiselada",
        true,false) as MeshInstance3D
    var chassis := root.find_child("G11V2_CascoOctogonalCerrado",
        true,false) as MeshInstance3D
    if shell == null or chassis == null:
        return false
    var armor := _mat(Color("#778784"),0.49,0.66)
    var muted := _mat(Color("#546461"),0.51,0.70)
    var dark := _mat(Color("#263232"),0.30,0.84)
    var rubber := _mat(Color("#171f21"),0.06,0.97)
    var bright := _mat(Color("#b2bbb4"),0.75,0.42)
    var lens := _mat(Color("#456b76"),0.22,0.31)
    var mirror := _mat(Color("#a7bdbd"),0.65,0.26)
    var warning := _mat(faction_color.darkened(0.12),0.33,0.65)
    var door_meshes: Dictionary = _door_shapes()
    for side in _SIDES:
        var sign: float = float(side)
        # The V2 bevel and V3 weathered main cab remain intact. Genuine
        # separate armored door, seal and side window are built on the flank.
        _mesh(root,SIDE_DOOR+"%d" % side,
            door_meshes["armor"] as ArrayMesh,
            Vector3(sign*0.651,0,0),armor)
        _mesh(root,SIDE_FRAME+"%d" % side,
            door_meshes["frame"] as ArrayMesh,
            Vector3(sign*0.660,0,0),rubber)
        _mesh(root,SIDE_GLASS+"%d" % side,
            door_meshes["glass"] as ArrayMesh,
            Vector3(sign*0.672,0,0),lens)
        _box(root,"G11V12_DivisorVidrio_%d" % side,
            Vector3(sign*0.684,1.32,-0.858),
            Vector3(0.011,0.178,0.019),dark)
        _box(root,"G11V12_CierrePuerta_%d" % side,
            Vector3(sign*0.672,1.11,-0.568),
            Vector3(0.020,0.039,0.095),bright)
        # Short faction-colored technical stripe remains a restrained accent,
        # not a repaint of the existing eight unique faction schemes.
        _box(root,"G11V12_MarcaFaccionCabina_%d" % side,
            Vector3(sign*0.675,1.02,-0.815),
            Vector3(0.010,0.023,0.24),warning)
        # Replace the old cuboid rearview mount with slender 3D supports,
        # thick bevelled mirror housing, and reflective glass on front face.
        _remove(root,"G11_SoporteRetrovisor_%d" % side)
        _box(root,"G11V12_BrazoRetrovisor_%d" % side,
            Vector3(sign*0.765,1.295,-1.228),
            Vector3(0.21,0.018,0.020),dark)
        var housing := _mesh(root,"G11V12_CarcasaEspejo_%d" % side,
            _bevel(0.126,0.190,0.073,0.028),
            Vector3(sign*0.864,1.340,-1.245),dark)
        housing.rotation_degrees.y = sign*7.0
        _box(root,"G11V12_CristalEspejo_%d" % side,
            Vector3(sign*0.864,1.340,-1.286),
            Vector3(0.091,0.143,0.009),mirror)
        # Side footsteps and two brackets sit above moving tread belts.
        # These must not intersect V5 wheels/suspension below y=0.70.
        _box(root,SIDE_STEP+"%d" % side,
            Vector3(sign*0.830,0.742,-0.965),
            Vector3(0.208,0.033,0.455),dark)
        for rib in range(5):
            _box(root,"G11V12_GomaEscalon_%d_%d" % [side,rib],
                Vector3(sign*0.832,0.762,-1.125+float(rib)*0.081),
                Vector3(0.163,0.008,0.021),rubber)
        for brace in [-1,1]:
            _box(root,"G11V12_SoporteEscalon_%d_%d" % [side,brace],
                Vector3(sign*0.758,0.717,-0.96+float(brace)*0.17),
                Vector3(0.043,0.090,0.027),muted)
        # The first visual review found that the top engine grilles could
        # disappear behind the raised rocket pod. A second, actually
        # exposed lateral intake creates a readable service silhouette.
        _box(root,"G11V12_BaseRespiraderoCostado_%d" % side,
            Vector3(sign*0.773,0.928,1.108),
            Vector3(0.036,0.227,0.270),dark)
        _box(root,"G11V12_MarcoRespiraderoCostado_%d" % side,
            Vector3(sign*0.801,0.927,1.108),
            Vector3(0.018,0.198,0.247),armor)
        for slit in range(4):
            _box(root,"G11V12_AletaRespiraderoCostado_%d_%d" % [side,slit],
                Vector3(sign*0.816,0.926,1.021+float(slit)*0.055),
                Vector3(0.013,0.144,0.023),muted)
        # Distinct rear wheel arch guard: slender real beveled metal lip.
        _box(root,"G11V12_GuardaLodoTrasera_%d" % side,
            Vector3(sign*0.863,0.702,1.122),
            Vector3(0.148,0.049,0.185),armor)
    # Two front wipers align with the actual inclined windscreen surface,
    # instead of a decorative rectangle disconnected from the glazing.
    for side in _SIDES:
        var sign: float = float(side)
        _cyl(root,"G11V12_PivoteLimpiaparabrisas_%d" % side,
            Vector3(sign*0.30,1.191,-1.382),0.019,0.028,
            dark,Vector3(90,0,0))
        _box(root,"G11V12_BrazoLimpiaparabrisas_%d" % side,
            Vector3(sign*0.235,1.289,-1.397),
            Vector3(0.018,0.197,0.017),bright,
            Vector3(0,0,sign*25.0))
        _box(root,"G11V12_GomaLimpiaparabrisas_%d" % side,
            Vector3(sign*0.224,1.357,-1.415),
            Vector3(0.015,0.132,0.012),rubber,
            Vector3(0,0,sign*21.0))
    # Beveled front bumper and center grille with actual dark slots.
    _mesh(root,"G11V12_ParachoquesBiselado",
        _bevel(1.19,0.125,0.083,0.030),
        Vector3(0,0.654,-1.543),muted)
    _mesh(root,"G11V12_EmbocaduraRejillaProa",
        _bevel(0.63,0.195,0.026,0.032),
        Vector3(0,0.887,-1.536),dark)
    for slot in range(6):
        _box(root,"G11V12_AletaRejillaProa_%d" % slot,
            Vector3(-0.242+float(slot)*0.097,0.885,-1.558),
            Vector3(0.012,0.143,0.010),bright)
    # Real chassis aft compartment, latches and hinged service plate.
    for side in _SIDES:
        var sign: float = float(side)
        _box(root,REAR_SERVICE+"%d" % side,
            Vector3(sign*0.288,0.71,1.553),
            Vector3(0.11,0.050,0.024),bright)
        _cyl(root,"G11V12_BocallavePorton_%d" % side,
            Vector3(sign*0.288,0.71,1.572),0.018,0.014,
            dark,Vector3(90,0,0))
    # Main 6 V1 rectangular slots become recessed dark apertures and slim
    # metallic aero louvers with truthful depth.
    for old_index in range(6):
        _remove(root,"G11_RejillaMotor_%d" % old_index)
    _box(root,"G11V12_CajaVentilacionMotor",
        Vector3(0,1.130,1.057),
        Vector3(1.015,0.044,0.465),dark)
    for louver in range(LOUVERS):
        _box(root,"G11V12_AletaVentilacionMotor_%d" % louver,
            Vector3(-0.438+float(louver)*0.146,1.156,1.05),
            Vector3(0.065,0.014,0.383),muted,
            Vector3(0,0,5.0 if louver%2 == 0 else -5.0))
    # Protect against false seams painted into changing visual damage.
    _fastener_batch(root,bright)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v12_side_windows",GLASS_COUNT)
    model.set_meta("tarvoka_g11_v12_recessed_motor_louvers",LOUVERS)
    model.set_meta("tarvoka_g11_v12_hardware",FASTENERS)
    model.set_meta("tarvoka_g11_v12_lateral_air_slats",8)
    return set_stage(model,0)

static func set_stage(model: Node3D, stage: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var level: int = clampi(stage,0,4)
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    # Stage 2: right side panel is damaged, not the cab; don't hide its
    # window or faction stripe. Stage 3 exposes the engine and charred metal:
    # pristine engine louvers must then stop covering the V6 damage sculpture.
    for label in ["G11V12_CajaVentilacionMotor"]:
        var plate := root.find_child(label,true,false) as Node3D
        if plate != null:
            plate.visible = level < 3
    for i in range(LOUVERS):
        var blade := root.find_child(
            "G11V12_AletaVentilacionMotor_%d" % i,true,false) as Node3D
        if blade != null:
            blade.visible = level < 3
    for side in _SIDES:
        for name in ["G11V12_BaseRespiraderoCostado_%d",
                "G11V12_MarcoRespiraderoCostado_%d"]:
            var vent := root.find_child(name % side,true,false) as Node3D
            if vent != null:
                vent.visible = level < 3
        for slit in range(4):
            var blade := root.find_child(
                "G11V12_AletaRespiraderoCostado_%d_%d" % [side,slit],
                true,false) as Node3D
            if blade != null:
                blade.visible = level < 3
    # Critical damage does not erase the outer cabin or intact windshield:
    # localized destruction remains in V6's physically deformed engine bay.
    return true
