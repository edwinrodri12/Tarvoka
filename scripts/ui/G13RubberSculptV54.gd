extends RefCounted
class_name TarvokaG13RubberSculptV54

# G13 V54: actual rounded vulcanized tyre carcass + individual tread lugs.
# HERO LOD13 ONLY. 4 original MultiMesh wheel instances and 32 existing
# tread instances remain; rolling pivots, axle positions, faction colors,
# guns, radar, gameplay and all lighter Android LOD8 geometry are unchanged.
const FLAG := "tarvoka_g13_v54_rounded_tires_and_rubber_lugs"
const PREVIOUS := "tarvoka_g13_v53_metal_rubber_material_finish"
const SAVED := "tarvoka_g13_v54_original_and_sculpted_tire_meshes"
const TIRE := "G13_Ruedas4x4MultiMesh"
const LUGS := "G13_V7_TreadBlocks"
const WHEEL_COUNT := 4
const LUG_BATCH_COUNT := 32
const RADIAL_SEGMENTS := 24
const LUGS_PER_TREAD_BATCH := 6
static var _tire_cache: ArrayMesh = null
static var _lug_cache: ArrayMesh = null

static func _normal(rings: Array[Vector2], idx: int, angle: float) -> Vector3:
    var before: int = maxi(0, idx-1)
    var after: int = mini(rings.size()-1, idx+1)
    var dy: float = rings[after].x-rings[before].x
    var dr: float = rings[after].y-rings[before].y
    var slope: float = dr/maxf(0.0001, dy)
    return Vector3(cos(angle),-slope,sin(angle)).normalized()

static func _vertex(st: SurfaceTool, pos: Vector3, normal: Vector3,
        uv: Vector2 = Vector2.ZERO) -> void:
    st.set_normal(normal)
    st.set_uv(uv)
    st.add_vertex(pos)

static func _tyre_mesh() -> ArrayMesh:
    if _tire_cache != null:
        return _tire_cache
    # Ring profile uses local Y along the original wheel cylinder axis.
    # 0.31m rolling radius and 0.24m width are preserved to avoid collision
    # with the existing V40-V52 wheel arches and hubcaps.
    var rings: Array[Vector2] = [
        Vector2(-0.120,0.238),
        Vector2(-0.116,0.260),
        Vector2(-0.103,0.283),
        Vector2(-0.080,0.303),
        Vector2(-0.052,0.309),
        Vector2(0.000,0.310),
        Vector2(0.052,0.309),
        Vector2(0.080,0.303),
        Vector2(0.103,0.283),
        Vector2(0.116,0.260),
        Vector2(0.120,0.238)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in range(rings.size()-1):
        for segment in range(RADIAL_SEGMENTS):
            var a0: float = TAU*float(segment)/float(RADIAL_SEGMENTS)
            var a1: float = TAU*float(segment+1)/float(RADIAL_SEGMENTS)
            var p0 := Vector3(
                cos(a0)*rings[row].y,rings[row].x,sin(a0)*rings[row].y)
            var p1 := Vector3(
                cos(a1)*rings[row].y,rings[row].x,sin(a1)*rings[row].y)
            var p2 := Vector3(
                cos(a1)*rings[row+1].y,rings[row+1].x,
                sin(a1)*rings[row+1].y)
            var p3 := Vector3(
                cos(a0)*rings[row+1].y,rings[row+1].x,
                sin(a0)*rings[row+1].y)
            var n0 := _normal(rings,row,a0)
            var n1 := _normal(rings,row,a1)
            var n2 := _normal(rings,row+1,a1)
            var n3 := _normal(rings,row+1,a0)
            # Godot's native clockwise convention: computed face cross
            # points inward while the stored vertex normal points OUT.
            # Otherwise the intact rubber carcass is culled from outside.
            _vertex(st,p0,n0,Vector2(float(segment)/24.0,float(row)/10.0))
            _vertex(st,p1,n1,Vector2(float(segment+1)/24.0,float(row)/10.0))
            _vertex(st,p2,n2,Vector2(float(segment+1)/24.0,float(row+1)/10.0))
            _vertex(st,p0,n0,Vector2(float(segment)/24.0,float(row)/10.0))
            _vertex(st,p2,n2,Vector2(float(segment+1)/24.0,float(row+1)/10.0))
            _vertex(st,p3,n3,Vector2(float(segment)/24.0,float(row+1)/10.0))
    # Closed rubber inner faces; original stamped metal V46 hubs remain on top.
    for segment in range(RADIAL_SEGMENTS):
        var a0: float=TAU*float(segment)/float(RADIAL_SEGMENTS)
        var a1: float=TAU*float(segment+1)/float(RADIAL_SEGMENTS)
        var r: float=rings[0].y
        _vertex(st,Vector3(0,-0.120,0),Vector3.DOWN)
        _vertex(st,Vector3(cos(a1)*r,-0.120,sin(a1)*r),Vector3.DOWN)
        _vertex(st,Vector3(cos(a0)*r,-0.120,sin(a0)*r),Vector3.DOWN)
        _vertex(st,Vector3(0,0.120,0),Vector3.UP)
        _vertex(st,Vector3(cos(a0)*r,0.120,sin(a0)*r),Vector3.UP)
        _vertex(st,Vector3(cos(a1)*r,0.120,sin(a1)*r),Vector3.UP)
    _tire_cache=st.commit() as ArrayMesh
    return _tire_cache

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    var n: Vector3=(b-a).cross(c-a).normalized()
    _vertex(st,a,n)
    _vertex(st,c,n)
    _vertex(st,b,n)
    _vertex(st,a,n)
    _vertex(st,d,n)
    _vertex(st,c,n)

static func _lug(st: SurfaceTool,center: Vector3) -> void:
    var minp: Vector3 = center-Vector3(0.025,0.006,0.027)
    var maxp: Vector3 = center+Vector3(0.025,0.006,0.027)
    var x:float=minp.x
    var xx:float=maxp.x
    var y:float=minp.y
    var yy:float=maxp.y
    var z:float=minp.z
    var zz:float=maxp.z
    _quad(st,Vector3(x,y,zz),Vector3(xx,y,zz),
        Vector3(xx,yy,zz),Vector3(x,yy,zz))
    _quad(st,Vector3(xx,y,z),Vector3(x,y,z),
        Vector3(x,yy,z),Vector3(xx,yy,z))
    _quad(st,Vector3(xx,y,zz),Vector3(xx,y,z),
        Vector3(xx,yy,z),Vector3(xx,yy,zz))
    _quad(st,Vector3(x,y,z),Vector3(x,y,zz),
        Vector3(x,yy,zz),Vector3(x,yy,z))
    _quad(st,Vector3(x,yy,zz),Vector3(xx,yy,zz),
        Vector3(xx,yy,z),Vector3(x,yy,z))
    _quad(st,Vector3(x,y,z),Vector3(xx,y,z),
        Vector3(xx,y,zz),Vector3(x,y,zz))

static func _tread_mesh() -> ArrayMesh:
    if _lug_cache != null:
        return _lug_cache
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Six small rounded-tyre-compatible blocks replace each of the eight
    # enormous rigid rectangular pads, WITHOUT a new draw object/instance.
    # Staggered paired rows give three-dimensional tire grip at studio zoom.
    for row in [-1,1]:
        for step in [-1,0,1]:
            _lug(st,Vector3(
                float(row)*0.033,0.003,
                float(step)*0.070+float(row)*0.009))
    _lug_cache=st.commit() as ArrayMesh
    return _lug_cache

static func apply(root: Node3D) -> bool:
    if root==null or not bool(root.get_meta(PREVIOUS,false)) or (
            not bool(root.get_meta("tarvoka_g13_v1_high_detail",false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var tires:=root.find_child(TIRE,true,false) as MultiMeshInstance3D
    var pads:=root.find_child(LUGS,true,false) as MultiMeshInstance3D
    if tires==null or pads==null or tires.multimesh==null or (
            pads.multimesh==null) or (
            tires.multimesh.instance_count!=WHEEL_COUNT) or (
            pads.multimesh.instance_count!=LUG_BATCH_COUNT):
        return false
    var rubber: ArrayMesh=_tyre_mesh()
    var tread: ArrayMesh=_tread_mesh()
    if rubber==null or tread==null:
        return false
    var original_tire: Mesh=tires.multimesh.mesh
    var original_pad: Mesh=pads.multimesh.mesh
    if original_tire==null or original_pad==null:
        return false
    # Existing wheel transforms & V53 material overrides survive the swap.
    root.set_meta(SAVED,{
        "old_tire":original_tire,"old_tread":original_pad,
        "new_tire":rubber,"new_tread":tread
    })
    tires.multimesh.mesh=rubber
    pads.multimesh.mesh=tread
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v54_wheel_instances",4)
    root.set_meta("tarvoka_g13_v54_total_tread_lugs",192)
    root.set_meta("tarvoka_g13_v54_new_draw_nodes",0)
    root.set_meta("tarvoka_g13_v54_wheel_radius_m",0.310)
    root.set_meta("tarvoka_g13_v54_lod8_unchanged",true)
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var old: Dictionary=root.get_meta(SAVED,{})
    for key in ["old_tire","old_tread","new_tire","new_tread"]:
        if not old.has(key) or not old[key] is Mesh:
            return false
    var tires:=root.find_child(TIRE,true,false) as MultiMeshInstance3D
    var pads:=root.find_child(LUGS,true,false) as MultiMeshInstance3D
    if tires==null or pads==null or tires.multimesh==null or (
            pads.multimesh==null):
        return false
    tires.multimesh.mesh=old["new_tire"] if enabled else old["old_tire"]
    pads.multimesh.mesh=old["new_tread"] if enabled else old["old_tread"]
    root.set_meta("tarvoka_g13_v54_preview_enabled",enabled)
    return true
