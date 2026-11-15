extends RefCounted
class_name TarvokaAPCExteriorV11

# Sculpted front/side finishing pass for the original P06 6x6.
# Real sealed bevelled 3D armor, continuous wheel arch returns and proper
# recovery-eye geometry. Not a static image, texture patch or combat upgrade.
# Every faction is painted independently; damage and V3 comparisons reversible.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V6 = preload("res://scripts/ui/APCFinishV6.gd")
const V10 = preload("res://scripts/ui/APCRearDesignV10.gd")
const FLAG := "tarvoka_apc_exterior_v11"
const ROOT := "P06V11_BlindajeExteriorEsculpido"
const FRONT := "P06V11_ProaFaceteada"
const FLANKS := "P06V11_CostadosModulares"
const ARCHES := "P06V11_ArcosRuedaEsculpidos"
const DETAILS := "P06V11_DetallesDeFabricacion"
const SHOW := "tarvoka_apc_exterior_v11_visible"
const STAGE := "tarvoka_apc_exterior_v11_stage"
const WHEEL_ARCH_INNER := 0.386
const WHEEL_ARCH_OUTER := 0.452
const WHEEL_ARCH_SEGMENTS := 14

static func _node(parent: Node3D,name: String) -> Node3D:
    var n := Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _mat(color: Color,metal: float=0.34,rough: float=0.79) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        st.add_vertex(vertex)

static func _surface(parent: Node3D,name: String,vertices: Array[Vector3],
        paint: Material) -> MeshInstance3D:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for vertex in vertices:
        st.add_vertex(vertex)
    st.generate_normals()
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=st.commit()
    node.material_override=paint
    parent.add_child(node)
    return node

static func _box(parent: Node3D,name: String,at: Vector3,
        shape: Vector3,mat: Material,
        rotate: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=shape
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=mesh
    node.material_override=mat
    node.position=at
    node.rotation_degrees=rotate
    parent.add_child(node)
    return node

static func _plate(parent: Node3D,name: String,
        points: Array[Vector3],offset: Vector3,
        material: Material) -> MeshInstance3D:
    # Completely closed thin armored volume, with actual outer chamfer
    # sidewalls rather than floating flat quads. Surface Tool normals give
    # a faceted welded-metal appearance even at grazing camera angles.
    var front: Array[Vector3]=[]
    var rear: Array[Vector3]=[]
    for point in points:
        front.append(point+offset)
        rear.append(point-offset*0.40)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _quad(st,front[0],front[1],front[2],front[3])
    _quad(st,rear[3],rear[2],rear[1],rear[0])
    for edge in range(4):
        var nxt: int=(edge+1)%4
        _quad(st,front[edge],rear[edge],rear[nxt],front[nxt])
    st.generate_normals()
    var piece:=MeshInstance3D.new()
    piece.name=name
    piece.mesh=st.commit()
    piece.material_override=material
    parent.add_child(piece)
    return piece

static func _seam(parent: Node3D,name: String,
        start: Vector3,end: Vector3,radius: float,
        material: Material) -> void:
    var vector: Vector3=end-start
    var rod:=CylinderMesh.new()
    rod.top_radius=radius
    rod.bottom_radius=radius
    rod.height=vector.length()
    rod.radial_segments=7
    var item:=MeshInstance3D.new()
    item.name=name
    item.mesh=rod
    item.material_override=material
    item.position=(start+end)*0.5
    item.basis=Basis(Quaternion(Vector3.UP,vector.normalized()))
    parent.add_child(item)

static func _nose(root: Node3D,armor: Material,
        accent: Material,steel: Material,dark: Material,
        lens: Material) -> void:
    var nose:=_node(root,FRONT)
    # The V1 wedge is not covered by a flat slab: each separate trapezoidal
    # cheek follows its sloped existing glacis with low-profile real depth.
    for side in [-1,1]:
        var s: float=float(side)
        var face: Array[Vector3]=[
            Vector3(s*0.088,1.070,-1.455),
            Vector3(s*0.555,0.846,-1.451),
            Vector3(s*0.699,1.105,-1.255),
            Vector3(s*0.104,1.144,-1.249)]
        _plate(nose,"P06V11_GlacisBisagrado_%d" % side,face,
            Vector3(0.003*s,0.016,-0.016),armor)
        _seam(nose,"P06V11_CordonGlacis_%d" % side,
            Vector3(s*0.102,1.162,-1.250),
            Vector3(s*0.687,1.117,-1.256),0.009,steel)
        # Each light has an armored hood and two genuinely separate guard
        # rails, leaving the original V1 lens unobstructed from the front.
        var x: float=s*0.465
        _box(nose,"P06V11_CajaFaroRehundido_%d" % side,
            Vector3(x,0.779,-1.515),
            Vector3(0.213,0.133,0.039),dark)
        _box(nose,"P06V11_CristalFaroFrontal_%d" % side,
            Vector3(x,0.779,-1.538),
            Vector3(0.148,0.071,0.014),lens)
        _box(nose,"P06V11_ViseraFaro_%d" % side,
            Vector3(x,0.866,-1.510),
            Vector3(0.232,0.027,0.083),armor,
            Vector3(0,0,-5.0*s))
        for rail in [-1,1]:
            _box(nose,"P06V11_RejaProtectorFaro_%d_%d" % [side,rail],
                Vector3(x+float(rail)*0.065,0.779,-1.563),
                Vector3(0.012,0.111,0.014),steel)
        # A real welded toroidal retrieval eye replaces the impression of
        # a squared-off fake hook, but remains anchored to V6 towing block.
        var loop_mesh:=TorusMesh.new()
        loop_mesh.inner_radius=0.051
        loop_mesh.outer_radius=0.080
        loop_mesh.rings=12
        loop_mesh.ring_segments=10
        var ring:=MeshInstance3D.new()
        ring.name="P06V11_ArgollaRescateCircular_%d" % side
        ring.mesh=loop_mesh
        ring.material_override=steel
        ring.position=Vector3(s*0.52,0.483,-1.625)
        ring.rotation_degrees.x=90.0
        nose.add_child(ring)
    # Raised center seam + a V-faceted hood. This seam follows the actual
    # front armor and does not obscure the existing five-slot cooling intake.
    _seam(nose,"P06V11_JuntaCentralProa",
        Vector3(0,1.075,-1.477),Vector3(0,1.156,-1.254),
        0.008,steel)
    for side in [-1,1]:
        var s: float=float(side)
        _box(nose,"P06V11_RefuerzoRefrigeracion_%d" % side,
            Vector3(s*0.323,0.762,-1.509),
            Vector3(0.036,0.176,0.081),accent)
    # A shallow armored lip above the grille looks integrated with the wedge.
    _box(nose,"P06V11_LabioBlindajeParrilla",
        Vector3(0,0.868,-1.500),
        Vector3(0.622,0.022,0.081),armor)

static func _side_armor(root: Node3D,armor: Material,
        edge: Material,weld: Material) -> void:
    var flank:=_node(root,FLANKS)
    var slices: Array[float]=[-1.19,-0.62,0.03,0.70,1.20]
    for side in [-1,1]:
        var s: float=float(side)
        for section in range(4):
            var front: float=slices[section]+0.026
            var rear: float=slices[section+1]-0.026
            # Shallow bevel follows the V2 upper side hull, rather than
            # piling rectangular boxes on top of the six tire arches.
            var section_points: Array[Vector3]=[
                Vector3(s*0.814,1.300,front),
                Vector3(s*0.815,1.300,rear),
                Vector3(s*0.856,1.071,rear),
                Vector3(s*0.856,1.071,front)]
            _plate(flank,"P06V11_ModuloBlindaje_%d_%d" % [side,section],
                section_points,Vector3(s*0.016,0.0,0.0),
                edge if section==2 else armor)
            _seam(flank,
                "P06V11_CordonSoldaduraVertical_%d_%d" % [side,section],
                Vector3(s*0.835,1.299,front-0.019),
                Vector3(s*0.874,1.071,front-0.019),0.007,weld)
        _seam(flank,"P06V11_BordeSuperiorBlindaje_%d" % side,
            Vector3(s*0.830,1.318,-1.16),
            Vector3(s*0.830,1.318,1.18),0.008,weld)
        # Mid-height service release is inset and aligned with the modular
        # armor seams; it is not a large black slab covering faction paint.
        for z in [-0.625,0.028,0.695]:
            _box(flank,"P06V11_TapaPestillo_%d_%d" % [side,int(z*1000.0)],
                Vector3(s*0.884,1.093,z),
                Vector3(0.038,0.049,0.093),edge,
                Vector3(0.0,0.0,s*-7.0))
    # The hull has deliberately no new 2D texture or flat decal banding.

static func _arch(root: Node3D,side: int,axle: int,
        metal: Material) -> MeshInstance3D:
    var s: float=float(side)
    var z: float=float(V1.WHEEL_Z[axle])
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Four-side contour: outer vertical lip + upper chamfer + narrow return.
    # Physically attached at the wheel opening; the moving tire never clips
    # the inner 0.386-radius clearance. No fake rectangular guard strips.
    for i in range(WHEEL_ARCH_SEGMENTS):
        var a: float=deg_to_rad(16.0+148.0*float(i)/float(WHEEL_ARCH_SEGMENTS))
        var b: float=deg_to_rad(16.0+148.0*float(i+1)/float(WHEEL_ARCH_SEGMENTS))
        var points: Array[Vector3]=[]
        for angle in [a,b]:
            var c: float=cos(angle)
            var y: float=sin(angle)
            points.append(Vector3(s*0.973,
                V1.WHEEL_RADIUS+0.08+WHEEL_ARCH_INNER*y,
                z+WHEEL_ARCH_INNER*c))
            points.append(Vector3(s*0.989,
                V1.WHEEL_RADIUS+0.08+WHEEL_ARCH_OUTER*y,
                z+WHEEL_ARCH_OUTER*c))
            points.append(Vector3(s*0.937,
                V1.WHEEL_RADIUS+0.08+(WHEEL_ARCH_OUTER+0.012)*y,
                z+(WHEEL_ARCH_OUTER+0.012)*c))
        _quad(st,points[0],points[3],points[4],points[1])
        _quad(st,points[1],points[4],points[5],points[2])
    st.generate_normals()
    var arch:=MeshInstance3D.new()
    arch.name="P06V11_GuardabarrosCurvo_%d_%d" % [side,axle]
    arch.mesh=st.commit()
    arch.material_override=metal
    root.add_child(arch)
    return arch

static func _fenders(root: Node3D,
        armor: Material,steel: Material) -> void:
    var fenders:=_node(root,ARCHES)
    for side in [-1,1]:
        for axle in range(3):
            _arch(fenders,side,axle,armor)
            # Deliberate triangular tie-ins between the wheel opening and
            # hull shell; no horizontal floating box above the tire.
            var z: float=float(V1.WHEEL_Z[axle])
            _plate(fenders,
                "P06V11_CartelaUnion_%d_%d" % [side,axle],[
                    Vector3(float(side)*0.843,0.950,z-0.226),
                    Vector3(float(side)*0.843,0.950,z+0.226),
                    Vector3(float(side)*0.944,0.843,z+0.192),
                    Vector3(float(side)*0.944,0.843,z-0.192)],
                Vector3(float(side)*0.011,0.0,0.0),steel)

static func apply(model: Node3D,faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V10.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var upper: Node3D=model.find_child(V6.ROOT,true,false) as Node3D
    if upper==null:
        return false
    var root:=_node(upper,ROOT)
    var paint:=_mat(Color("#53646b").lerp(faction_color,0.55),0.34,0.78)
    var darkpaint:=_mat(Color("#3c4a50").lerp(faction_color,0.35),0.38,0.82)
    var steel:=_mat(Color("#7d888b"),0.60,0.72)
    var dark:=_mat(Color("#253238"),0.23,0.87)
    var lens:=_mat(Color("#e6d4a4"),0.11,0.35)
    _nose(root,paint,darkpaint,steel,dark,lens)
    _side_armor(root,paint,darkpaint,steel)
    _fenders(root,paint,steel)
    # Replace earlier rectangular fender strips and box-shaped 'tow eyes'
    # with the new flush curved guards / genuinely hollow circular rings.
    # Their originals remain in the tree ONLY for historical comparison.
    for obsolete_name in ["SeisBordesGuardabarro",
            "ArgollaArrastre_-1","ArgollaArrastre_1"]:
        var obsolete: Node3D=model.find_child(
            obsolete_name,true,false) as Node3D
        if obsolete!=null:
            obsolete.visible=false
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return true

static func set_stage(model: Node3D,stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var value: int=clampi(stage,0,4)
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var exterior: Node3D=model.find_child(ROOT,true,false) as Node3D
    if exterior!=null:
        exterior.visible=enabled and value<4
    # The right middle original V2 panel folds outward at moderate damage;
    # its new V11 superficial applique must disappear rather than cover
    # the broken opening. The left front arch shears off at critical damage.
    var right: Node3D=model.find_child(
        "P06V11_ModuloBlindaje_1_1",true,false) as Node3D
    if right!=null:
        right.visible=enabled and value<2
    var broken_weld: Node3D=model.find_child(
        "P06V11_CordonSoldaduraVertical_1_1",true,false) as Node3D
    if broken_weld!=null:
        broken_weld.visible=enabled and value<2
    var left_arch: Node3D=model.find_child(
        "P06V11_GuardabarrosCurvo_-1_0",true,false) as Node3D
    if left_arch!=null:
        left_arch.visible=enabled and value<3
    var left_tie: Node3D=model.find_child(
        "P06V11_CartelaUnion_-1_0",true,false) as Node3D
    if left_tie!=null:
        left_tie.visible=enabled and value<3
    model.set_meta(STAGE,value)
    return true

static func set_enabled(model: Node3D,show: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    # When the user compares to V3/V10, the earlier V6 decorative pieces
    # remain part of their original tier. V11 alone hides its replaced boxes.
    for obsolete_name in ["SeisBordesGuardabarro",
            "ArgollaArrastre_-1","ArgollaArrastre_1"]:
        var obsolete: Node3D=model.find_child(
            obsolete_name,true,false) as Node3D
        if obsolete!=null:
            obsolete.visible=not show
    model.set_meta(SHOW,show)
    return set_stage(model,int(model.get_meta(STAGE,0)))
