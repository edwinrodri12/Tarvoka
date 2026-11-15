extends RefCounted
class_name TarvokaG11ArmorFinishV11

# G11 hero V11: original, actually modeled hard-surface final-detail pass.
# Rebalances the launcher silhouette, physically chamfers outer rails, applies
# distinct metallic PBR surface finishes to the twelve open launch tubes, and
# adds realistic wear, bracing and roof/maintenance fittings.
# Pure presentation; no attack, defenses, resource, animation or LOD changes.
const FLAG := "tarvoka_g11_armor_finish_v11"
const ELEVATION := "G11_ElevacionLanzador"
const TURRET := "G11_GiroPlataforma"
const ROOT := "G11_CascoRaiz"
const TUBES := 12
const FASTENERS := 16
const FACE_Z := -0.792
const _NICKEL := Color("#b7c0b6")
static var _scuffs: ArrayMesh
static var _rail_bolt: CylinderMesh
static var _faction_cache: Dictionary = {}

static func _mat(tint: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.metallic = metallic
    m.roughness = roughness
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _tri(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3, d: Vector3) -> void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _mesh(parent: Node3D, label: String,
        mesh: Mesh, pos: Vector3, material: Material = null) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    if material != null:
        node.material_override = material
    node.position = pos
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, material: Material) -> MeshInstance3D:
    var geom := BoxMesh.new()
    geom.size = size
    return _mesh(parent,label,geom,pos,material)

static func _cyl(parent: Node3D, label: String, pos: Vector3,
        radius: float, length: float, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geom := CylinderMesh.new()
    geom.top_radius = radius
    geom.bottom_radius = radius
    geom.height = length
    geom.radial_segments = 12
    var node := _mesh(parent,label,geom,pos,material)
    node.rotation_degrees = rotation
    return node

static func _beveled_extrusion(width: float, height: float,
        depth: float, bevel: float) -> ArrayMesh:
    # Closed octagonal profile with a true bevel at each of its four edges,
    # extruded longitudinally. Avoid fake flat strips and sharp block corners.
    var hx: float = width*0.5
    var hy: float = height*0.5
    var b: float = minf(bevel,minf(hx*0.55,hy*0.55))
    var contour: Array[Vector2] = [
        Vector2(-hx+b,-hy),Vector2(hx-b,-hy),
        Vector2(hx,-hy+b),Vector2(hx,hy-b),
        Vector2(hx-b,hy),Vector2(-hx+b,hy),
        Vector2(-hx,hy-b),Vector2(-hx,-hy+b)]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(contour.size()):
        var j: int = (i+1)%contour.size()
        var a: Vector2 = contour[i]
        var c: Vector2 = contour[j]
        _quad(st,Vector3(a.x,a.y,-depth*0.5),
            Vector3(c.x,c.y,-depth*0.5),
            Vector3(c.x,c.y,depth*0.5),
            Vector3(a.x,a.y,depth*0.5))
        _tri(st,Vector3.ZERO+Vector3(0,0,-depth*0.5),
            Vector3(c.x,c.y,-depth*0.5),
            Vector3(a.x,a.y,-depth*0.5))
        _tri(st,Vector3(0,0,depth*0.5),
            Vector3(a.x,a.y,depth*0.5),
            Vector3(c.x,c.y,depth*0.5))
    st.generate_normals()
    return st.commit()

static func _wear_geometry() -> ArrayMesh:
    if _scuffs != null:
        return _scuffs
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Three thin imperfect patches per lip, combined into one mesh instance.
    # Physical arc sectors on the outer lip, never closing the bore opening.
    for col in range(4):
        for row in range(3):
            var tube: int = col*3+row
            var origin := Vector2(-0.42+float(col)*0.28,
                -0.24+float(row)*0.24)
            for patch in range(3):
                var center_angle: float = (float(tube*7+patch*13)
                    *0.41+0.25)
                var reach: float = 0.22+float((tube+patch)%3)*0.065
                var inner: float = 0.106+0.002*float(patch%2)
                var outer: float = 0.110+0.001*float((tube+patch)%2)
                for k in range(5):
                    var a: float = center_angle-reach*0.5+reach*float(k)/5.0
                    var b: float = center_angle-reach*0.5+reach*float(k+1)/5.0
                    var p0 := Vector3(origin.x+cos(a)*inner,
                        origin.y+sin(a)*inner,-0.754)
                    var p1 := Vector3(origin.x+cos(b)*inner,
                        origin.y+sin(b)*inner,-0.754)
                    var p2 := Vector3(origin.x+cos(b)*outer,
                        origin.y+sin(b)*outer,-0.754)
                    var p3 := Vector3(origin.x+cos(a)*outer,
                        origin.y+sin(a)*outer,-0.754)
                    _quad(st,p0,p1,p2,p3)
    st.generate_normals()
    _scuffs = st.commit()
    return _scuffs

static func _cheek_mesh() -> ArrayMesh:
    # Sculpted outer side shield, narrow near the front so the 12 physical
    # barrels, the cooling glow, and the moving dual hydraulics stay exposed.
    var outline: Array[Vector2] = [
        Vector2(-0.16,0.21),Vector2(0.21,0.27),
        Vector2(0.35,0.62),Vector2(0.22,0.79),
        Vector2(-0.15,0.80)]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var h: float = 0.025
    var center := Vector2(0.09,0.52)
    for i in range(outline.size()):
        var j: int = (i+1)%outline.size()
        var a: Vector2 = outline[i]
        var b: Vector2 = outline[j]
        _tri(st,Vector3(h,center.x,center.y),
            Vector3(h,a.x,a.y),Vector3(h,b.x,b.y))
        _tri(st,Vector3(-h,center.x,center.y),
            Vector3(-h,b.x,b.y),Vector3(-h,a.x,a.y))
        _quad(st,Vector3(-h,a.x,a.y),Vector3(-h,b.x,b.y),
            Vector3(h,b.x,b.y),Vector3(h,a.x,a.y))
    st.generate_normals()
    return st.commit()

static func _fastener_mesh() -> CylinderMesh:
    if _rail_bolt == null:
        _rail_bolt = CylinderMesh.new()
        _rail_bolt.top_radius = 0.013
        _rail_bolt.bottom_radius = 0.013
        _rail_bolt.height = 0.011
        _rail_bolt.radial_segments = 8
        _rail_bolt.material = _mat(Color("#9fa9a5"),0.74,0.38)
    return _rail_bolt

static func _bolts(parent: Node3D) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = _fastener_mesh()
    mm.instance_count = FASTENERS
    var positions: Array[Vector3] = []
    for x in [-0.587,0.587]:
        for y in [-0.30,-0.10,0.10,0.30]:
            positions.append(Vector3(x,y,FACE_Z-0.042))
    for x in [-0.42,-0.14,0.14,0.42]:
        for y in [-0.420,0.420]:
            positions.append(Vector3(x,y,FACE_Z-0.042))
    var basis := Basis(Vector3.RIGHT,PI*0.5)
    for i in range(positions.size()):
        mm.set_instance_transform(i,Transform3D(basis,positions[i]))
    var node := MultiMeshInstance3D.new()
    node.name = "G11V11_PernosMarcosLote"
    node.multimesh = mm
    parent.add_child(node)

static func _refine_tubes(launcher: Node3D) -> bool:
    var tube := launcher.find_child("G11_Tubo_0_0",true,false) as MeshInstance3D
    if tube == null or not (tube.mesh is ArrayMesh):
        return false
    # GeometryV4 uses the same ArrayMesh across all twelve launch tubes.
    # Material edits do not change the bore's actual depth or any animation.
    var mesh := tube.mesh as ArrayMesh
    if mesh.get_surface_count() != 3:
        return false
    mesh.surface_set_material(0,_mat(Color("#3d4848"),0.59,0.64))
    mesh.surface_set_material(1,_mat(Color("#9fa9a4"),0.77,0.47))
    mesh.surface_set_material(2,_mat(Color("#111819"),0.10,0.97))
    return true

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_cooldown_v10",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    var turret := model.find_child(TURRET,true,false) as Node3D
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if root == null or turret == null or launcher == null:
        return false
    if not _refine_tubes(launcher):
        return false
    var steel := _mat(Color("#697a77"),0.52,0.67)
    var dark := _mat(Color("#222c2d"),0.32,0.81)
    var polished := _mat(Color("#a8b5af"),0.72,0.45)
    var rubber := _mat(Color("#303838"),0.19,0.91)
    var warm := _mat(_NICKEL,0.82,0.41)
    var rail_geom := _beveled_extrusion(0.10,0.092,1.61,0.023)
    for side in [-1,1]:
        var sign: float = float(side)
        for height_side in [-1,1]:
            var ypos: float = float(height_side)*0.397
            _mesh(launcher,
                "G11V11_CantoneraBiselada_%d_%d" % [side,height_side],
                rail_geom,Vector3(sign*0.589,ypos,-0.003),
                steel if height_side > 0 else dark)
        var cheek := _mesh(launcher,"G11V11_CacheteProtector_%d" % side,
            _cheek_mesh(),Vector3(sign*0.696,0,0.0),steel)
        if side < 0:
            cheek.scale.x = -1.0
        _box(launcher,"G11V11_JuntaCachete_%d" % side,
            Vector3(sign*0.731,0.07,0.69),
            Vector3(0.012,0.20,0.17),rubber)
        # Rear plate now has individual recessed service latches.
        _box(launcher,"G11V11_BaseCierreTrasero_%d" % side,
            Vector3(sign*0.31,0.13,0.975),
            Vector3(0.17,0.12,0.018),dark)
        _cyl(launcher,"G11V11_CerrojoMantenimiento_%d" % side,
            Vector3(sign*0.31,0.13,0.992),
            0.041,0.017,polished,Vector3(90,0,0))
    _box(launcher,"G11V11_TravesanoSuperior",
        Vector3(0,0.422,FACE_Z),Vector3(1.15,0.067,0.072),steel)
    _box(launcher,"G11V11_TravesanoInferior",
        Vector3(0,-0.422,FACE_Z),Vector3(1.15,0.067,0.072),dark)
    for i in range(3):
        var x: float = -0.28+float(i)*0.28
        # Genuine thin ribs pass only BETWEEN tube columns, without
        # intersecting the 0.115-radius nozzle lips.
        _box(launcher,"G11V11_DivisorVertical_%d" % i,
            Vector3(x,0.0,FACE_Z),
            Vector3(0.020,0.723,0.058),steel)
    _bolts(launcher)
    _mesh(launcher,"G11V11_RozadurasBocas",
        _wear_geometry(),Vector3.ZERO,warm)
    # Fine roofing detail gives the same visual precision to the cab,
    # without replacing the accepted octagonal body or faction paint.
    _box(root,"G11V11_TapaFiltroTecho",
        Vector3(0.305,1.554,-0.83),
        Vector3(0.19,0.027,0.25),steel)
    for i in range(3):
        _box(root,"G11V11_RejillaTecho_%d" % i,
            Vector3(0.305,1.575,-0.90+float(i)*0.067),
            Vector3(0.15,0.012,0.022),dark)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v11_true_beveled_rails",4)
    model.set_meta("tarvoka_g11_v11_new_bevel_and_service_parts",true)
    model.set_meta("tarvoka_g11_v11_lip_wear_sectors",36)
    return true
