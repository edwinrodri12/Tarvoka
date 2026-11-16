extends RefCounted
class_name TarvokaG13CabRearFinishV11

# V11: closed low-poly seams between the cab sidewalls and roof, plus
# a tapered rear deck. High-detail art only; the V1/V10 rig, tactical
# numbers, 8 faction colors and mobile LOD8 are intentionally untouched.
const FLAG := "tarvoka_g13_cab_rear_finish_v11"
const ROOF_SHOULDER := "G13_V11_CabRoofShoulder_%d"
const ROOF_GASKET := "G13_V11_CabRoofSeal_%d"
const REAR_DECK := "G13_V11_TaperedRearDeck"
const REAR_GUARD := "G13_V11_RearCornerGuard_%d"
const REAR_LIP := "G13_V11_RearDoorTopSeal"

# Measured against V1: roof lower face Y=1.3625, roof side X=0.650,
# roof range Z=[-1.240, -0.120]. Seams cross the lower face instead of
# floating above it or extending through the front glass.
const ROOF_Z_START := -1.145
const ROOF_Z_END := -0.205
const REAR_Z_START := 0.980
const REAR_Z_END := 1.240

static func _mat(color: Color,metallic: float=0.22,
        roughness: float=0.73)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3)->void:
    var n: Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(b)
    st.set_normal(n)
    st.add_vertex(c)

# A closed prismatic shell with separately shaped front/rear profiles.
# Flat triangle normals preserve deliberate machined-metal facets.
static func _closed_loft(front: Array[Vector2],rear: Array[Vector2],
        front_z: float,rear_z: float)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n: int=front.size()
    for i in range(n):
        var j: int=(i+1)%n
        var a:=Vector3(front[i].x,front[i].y,front_z)
        var b:=Vector3(front[j].x,front[j].y,front_z)
        var c:=Vector3(rear[j].x,rear[j].y,rear_z)
        var d:=Vector3(rear[i].x,rear[i].y,rear_z)
        _triangle(st,a,b,c)
        _triangle(st,a,c,d)
    for i in range(1,n-1):
        _triangle(st,
            Vector3(front[0].x,front[0].y,front_z),
            Vector3(front[i+1].x,front[i+1].y,front_z),
            Vector3(front[i].x,front[i].y,front_z))
        _triangle(st,
            Vector3(rear[0].x,rear[0].y,rear_z),
            Vector3(rear[i].x,rear[i].y,rear_z),
            Vector3(rear[i+1].x,rear[i+1].y,rear_z))
    return st.commit()

static func _mesh(parent: Node3D,name: String,mesh: Mesh,
        material: Material)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=mesh
    part.material_override=material
    parent.add_child(part)
    return part

static func _box(parent: Node3D,name: String,p: Vector3,dim: Vector3,
        material: Material,rotation: Vector3=Vector3.ZERO)->MeshInstance3D:
    var m:=BoxMesh.new()
    m.size=dim
    var part:=_mesh(parent,name,m,material)
    part.position=p
    part.rotation_degrees=rotation
    return part

static func _roof_profile(side: int)->Array[Vector2]:
    var sx: float=float(side)
    var profile: Array[Vector2]=[
        Vector2(sx*0.500,1.346),
        Vector2(sx*0.552,1.309),
        Vector2(sx*0.628,1.340),
        Vector2(sx*0.637,1.386),
        Vector2(sx*0.575,1.417),
        Vector2(sx*0.502,1.388)
    ]
    if side<0:
        profile.reverse()
    return profile

static func _rear_front_profile()->Array[Vector2]:
    # Lower deck touches the original hull top (0.865) and begins before
    # the original engine cover ends (z=1.035), avoiding open butt joints.
    return [
        Vector2(-0.49,0.852),Vector2(0.49,0.852),
        Vector2(0.526,0.968),Vector2(0.502,1.115),
        Vector2(-0.502,1.115),Vector2(-0.526,0.968)
    ]

static func _rear_end_profile()->Array[Vector2]:
    # Rear tapers inside the tailgate and never covers the two lamps at
    # +/-0.51, y=0.83, z=1.295, or the rear door at z=1.278.
    return [
        Vector2(-0.467,0.852),Vector2(0.467,0.852),
        Vector2(0.490,0.962),Vector2(0.461,1.032),
        Vector2(-0.461,1.032),Vector2(-0.490,0.962)
    ]

static func install(root: Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta("tarvoka_g13_silhouette_v10",false))):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var roof:=root.find_child("G13_CabRoof",true,false) as MeshInstance3D
    var door:=root.find_child("G13_RearServiceDoor",true,false) as MeshInstance3D
    if hull==null or roof==null or door==null:
        return false
    if roof.mesh is not BoxMesh or door.mesh is not BoxMesh:
        return false

    var armor:=_mat(Color("#758488"),0.34,0.68)
    var dark:=_mat(Color("#28353b"),0.11,0.83)
    var edge:=_mat(Color("#536267"),0.30,0.75)

    # 2 continuous faceted shoulder parts and 2 contrasting roof seals.
    # Unlike ornamental strips, the shoulders penetrate below the roof
    # slab and close its side-to-cabin transition.
    for side in [-1,1]:
        var profile: Array[Vector2]=_roof_profile(side)
        _mesh(hull,ROOF_SHOULDER % side,
            _closed_loft(profile,profile,ROOF_Z_START,ROOF_Z_END),armor)
        _box(hull,ROOF_GASKET % side,
            Vector3(float(side)*0.651,1.404,-0.675),
            Vector3(0.016,0.020,0.910),dark)
        # Body-side taper from top rear deck to tailgate; the guards end
        # well above the low rear lights.
        _box(hull,REAR_GUARD % side,
            Vector3(float(side)*0.565,0.995,1.145),
            Vector3(0.063,0.153,0.245),edge,Vector3(-12,0,0))

    _mesh(hull,REAR_DECK,
        _closed_loft(_rear_front_profile(),_rear_end_profile(),
            REAR_Z_START,REAR_Z_END),armor)
    # The door is left intact and visible; only its top gasket is added.
    _box(hull,REAR_LIP,Vector3(0,1.165,1.298),
        Vector3(0.86,0.023,0.020),dark)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v11_visual_only",true)
    return true
