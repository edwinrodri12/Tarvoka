extends RefCounted
class_name TarvokaG11TacticalReadabilityV24

# Real tactical-scale G11 LOD finish, NOT a hero model duplication.
# Replace the two large rectangular track boxes with one shared 3D capsule
# per side. Near LOD uses a hollow belt so the existing batched wheels
# appear INSIDE its aperture. Far LOD uses a sealed capsule with NO wheels.
# Repositions existing guards and enamel strips rather than layering meshes.
const FLAG := "tarvoka_g11_tactical_readability_v24"
const SOURCE := "tarvoka_g11_mobile_lod"
const LOD_FAR := 8
const LOD_NEAR := 10
const TRACK_CENTER_X: float = 0.79
const TRACK_OUTER_HALF_X: float = 0.145
const TRACK_OUTER_RADIUS: float = 0.257
const TRACK_INNER_RADIUS: float = 0.184
const TRACK_CENTER_Y: float = 0.330
const TRACK_END_Z: float = 1.030
const TRACK_ARC_STEPS: int = 10
const TACTICAL_WHEEL_RADIUS: float = 0.160
const TACTICAL_WHEEL_X: float = 0.912
const TACTICAL_WHEEL_Y: float = 0.330
const TACTICAL_WHEEL_WIDTH: float = 0.044
const WHEEL_FIRST_Z: float = -1.0
const WHEEL_PITCH: float = 0.40
const GUARD_Y: float = 0.660
const GUARD_HEIGHT: float = 0.100
const PAINT_X: float = 0.950
static var _hollow: ArrayMesh
static var _sealed: ArrayMesh
static var _track_pbr: StandardMaterial3D

static func _position(x: float, p: Vector2) -> Vector3:
    # Profile is (y,z), extruded to actual native 3D chassis X.
    return Vector3(x,p.x,p.y)

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _stadium(radius: float) -> Array[Vector2]:
    var path: Array[Vector2] = []
    # Front (+z) arc: upper -> outer end -> lower.
    for i in range(TRACK_ARC_STEPS+1):
        var theta: float = PI*0.5-PI*float(i)/float(TRACK_ARC_STEPS)
        path.append(Vector2(
            TRACK_CENTER_Y+radius*sin(theta),
            TRACK_END_Z+radius*cos(theta)))
    # Back (-z) arc: lower -> rear end -> upper.
    for i in range(TRACK_ARC_STEPS+1):
        var theta: float = -PI*0.5-PI*float(i)/float(TRACK_ARC_STEPS)
        path.append(Vector2(
            TRACK_CENTER_Y+radius*sin(theta),
            -TRACK_END_Z+radius*cos(theta)))
    return path

static func _make_track(hollow: bool) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var outer: Array[Vector2] = _stadium(TRACK_OUTER_RADIUS)
    var inner: Array[Vector2] = _stadium(TRACK_INNER_RADIUS)
    var count: int = outer.size()
    var half: float = TRACK_OUTER_HALF_X
    for i in range(count):
        var j: int = (i+1)%count
        var a: Vector2 = outer[i]
        var b: Vector2 = outer[j]
        # Physical outer crown with both inboard/outboard shoulders.
        _quad(st,_position(-half,a),_position(half,a),
            _position(half,b),_position(-half,b))
        if hollow:
            # Exterior steel/rubber ring and true open center (not fake
            # decals). The wheels are visible through the actual aperture.
            var c: Vector2 = inner[i]
            var d: Vector2 = inner[j]
            _quad(st,_position(half,a),_position(half,b),
                _position(half,d),_position(half,c))
            _quad(st,_position(-half,b),_position(-half,a),
                _position(-half,c),_position(-half,d))
            _quad(st,_position(half,d),_position(-half,d),
                _position(-half,c),_position(half,c))
        else:
            # Sealed far-distance endcaps with no hidden wheel geometry:
            # use a triangle fan rather than a rectangular wheel stack.
            var center := Vector2(TRACK_CENTER_Y,0)
            st.add_vertex(_position(half,center))
            st.add_vertex(_position(half,a))
            st.add_vertex(_position(half,b))
            st.add_vertex(_position(-half,center))
            st.add_vertex(_position(-half,b))
            st.add_vertex(_position(-half,a))
    st.generate_normals()
    return st.commit()

static func _mesh(near: bool) -> ArrayMesh:
    if near:
        if _hollow==null:
            _hollow=_make_track(true)
        return _hollow
    if _sealed==null:
        _sealed=_make_track(false)
    return _sealed

static func _rubber() -> StandardMaterial3D:
    if _track_pbr==null:
        _track_pbr=StandardMaterial3D.new()
        _track_pbr.albedo_color=Color("#242b2e")
        _track_pbr.metallic=0.03
        _track_pbr.roughness=0.93
        # Both faces of the physical hollow track are visible at 3/4 angles.
        _track_pbr.cull_mode=BaseMaterial3D.CULL_DISABLED
    return _track_pbr

static func _part(root: Node3D,name: String) -> Node3D:
    return root.find_child(name,true,false) as Node3D

static func apply(model: Node3D, near: bool) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not model.has_meta(SOURCE)):
        return false
    var level: int = int(model.get_meta(SOURCE,0))
    if level!=(LOD_NEAR if near else LOD_FAR):
        return false
    # 1mm of exterior wheel clearance, in the original 29cm-wide tracks.
    if TACTICAL_WHEEL_X+TACTICAL_WHEEL_WIDTH*0.5 >= (
            TRACK_CENTER_X+TRACK_OUTER_HALF_X):
        return false
    if TACTICAL_WHEEL_RADIUS>=TRACK_INNER_RADIUS:
        return false
    if GUARD_Y-GUARD_HEIGHT*0.5<=TRACK_CENTER_Y+TRACK_OUTER_RADIUS:
        return false
    for side in [-1,1]:
        for prefix in [
            "G11Mobile_Oruga_","G11Mobile_Faldon_",
            "G11Mobile_PinturaCostado_"
        ]:
            var part := _part(model,prefix+str(side)) as MeshInstance3D
            if part==null or not part.mesh is BoxMesh:
                return false
    var batch := _part(model,"G11Mobile_Lote12Ruedas") as MultiMeshInstance3D
    if near and (batch==null or batch.multimesh==null or
            batch.multimesh.instance_count!=12 or
            not batch.multimesh.mesh is CylinderMesh):
        return false
    if not near and batch!=null:
        return false
    var track_mesh: ArrayMesh = _mesh(near)
    for side in [-1,1]:
        var sign: float = float(side)
        var track := _part(model,
            "G11Mobile_Oruga_%d" % side) as MeshInstance3D
        # Actual replacement of a solid box; never add an overlaid band.
        track.mesh=track_mesh
        track.material_override=_rubber()
        track.position=Vector3(sign*TRACK_CENTER_X,0,0)
        var guard := _part(model,
            "G11Mobile_Faldon_%d" % side) as MeshInstance3D
        var shield_mesh := guard.mesh as BoxMesh
        shield_mesh.size=Vector3(shield_mesh.size.x,
            GUARD_HEIGHT,shield_mesh.size.z)
        guard.position.y=GUARD_Y
        var stripe := _part(model,
            "G11Mobile_PinturaCostado_%d" % side) as MeshInstance3D
        stripe.position.x=sign*PAINT_X
        stripe.position.y=0.676
    if near:
        var cylinder := batch.multimesh.mesh as CylinderMesh
        cylinder.top_radius=TACTICAL_WHEEL_RADIUS
        cylinder.bottom_radius=TACTICAL_WHEEL_RADIUS
        cylinder.height=TACTICAL_WHEEL_WIDTH
        var basis := Basis(Vector3.FORWARD,PI*0.5)
        var k: int=0
        for side in [-1,1]:
            for axle in range(6):
                batch.multimesh.set_instance_transform(k,
                    Transform3D(basis,Vector3(
                        float(side)*TACTICAL_WHEEL_X,
                        TACTICAL_WHEEL_Y,
                        WHEEL_FIRST_Z+WHEEL_PITCH*float(axle))))
                k+=1
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v24_actual_near_hollow_belt",near)
    model.set_meta("tarvoka_g11_v24_actual_far_closed_belt",not near)
    model.set_meta("tarvoka_g11_v24_replaced_track_meshes",2)
    model.set_meta("tarvoka_g11_v24_wheels_inset",12 if near else 0)
    model.set_meta("tarvoka_g11_v24_repositioned_original_guards",2)
    model.set_meta(ACTIVE_LOD,LOD_NEAR if near else LOD_FAR)
    model.set_meta("tarvoka_g11_v25_near_wheels_visible",near)
    return true


# V25 live battle uses the same V24 surfaces at either projected pixel size.
# A distant G11 starts with NO road-wheel batch; when the camera zooms closer,
# the first near transition lazily creates exactly one original-style
# MultiMesh, then reuses it forever. No duplicate track boxes or unit models.
const ACTIVE_LOD := "tarvoka_g11_v25_active_lod"
const ROADWHEEL_BATCH := "G11Mobile_Lote12Ruedas"
static var _live_wheel_mesh: CylinderMesh

static func _wheel_batch(model: Node3D) -> MultiMeshInstance3D:
    var existing := model.find_child(
        ROADWHEEL_BATCH,true,false) as MultiMeshInstance3D
    if existing!=null:
        return existing
    if _live_wheel_mesh==null:
        _live_wheel_mesh=CylinderMesh.new()
        _live_wheel_mesh.top_radius=TACTICAL_WHEEL_RADIUS
        _live_wheel_mesh.bottom_radius=TACTICAL_WHEEL_RADIUS
        _live_wheel_mesh.height=TACTICAL_WHEEL_WIDTH
        _live_wheel_mesh.radial_segments=10
        var mat := StandardMaterial3D.new()
        mat.albedo_color=Color("#a5afad")
        mat.metallic=0.59
        mat.roughness=0.45
        _live_wheel_mesh.material=mat
    var batch := MultiMesh.new()
    batch.transform_format=MultiMesh.TRANSFORM_3D
    batch.mesh=_live_wheel_mesh
    batch.instance_count=12
    var basis := Basis(Vector3.FORWARD,PI*0.5)
    var k: int=0
    for side in [-1,1]:
        for axle in range(6):
            batch.set_instance_transform(k,Transform3D(basis,Vector3(
                float(side)*TACTICAL_WHEEL_X,TACTICAL_WHEEL_Y,
                WHEEL_FIRST_Z+float(axle)*WHEEL_PITCH)))
            k+=1
    var instance := MultiMeshInstance3D.new()
    instance.name=ROADWHEEL_BATCH
    instance.multimesh=batch
    model.add_child(instance)
    return instance

static func active_level(model: Node3D) -> int:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return 0
    return int(model.get_meta(ACTIVE_LOD,
        LOD_NEAR if bool(model.get_meta(
            "tarvoka_g11_v24_actual_near_hollow_belt",false)) else LOD_FAR))

static func set_level(model: Node3D,level: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)) or (
            level!=LOD_FAR and level!=LOD_NEAR):
        return false
    if active_level(model)==level:
        return true
    var target_near: bool=level==LOD_NEAR
    var wheels: MultiMeshInstance3D=null
    if target_near:
        wheels=_wheel_batch(model)
        if wheels==null or wheels.multimesh==null or (
                wheels.multimesh.instance_count!=12):
            return false
    else:
        wheels=model.find_child(
            ROADWHEEL_BATCH,true,false) as MultiMeshInstance3D
    for side in [-1,1]:
        var track := _part(model,
            "G11Mobile_Oruga_%d" % side) as MeshInstance3D
        if track==null:
            return false
        track.mesh=_mesh(target_near)
    if wheels!=null:
        wheels.visible=target_near
    model.set_meta(ACTIVE_LOD,level)
    model.set_meta("tarvoka_g11_v25_near_wheels_visible",target_near)
    return true
