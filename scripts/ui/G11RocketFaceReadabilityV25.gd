extends RefCounted
class_name TarvokaG11RocketFaceReadabilityV25

# Sculpt the EXISTING tactical G11 launcher face into a readable 4×3 rack.
# The old 12 solid cylinder impostors are replaced IN PLACE with one shared
# hollow tube mesh; the near batch's solid caps become physical metal rings.
# This makes the rear +Z face recognizable under the standard 3D map camera.
# One original paint patch is resized (not duplicated). No extra nodes,
# no gameplay change and no modification to the V23 hero/rocket animation.
const FLAG := "tarvoka_g11_rocket_face_readability_v25"
const REQUIRED := "tarvoka_g11_tactical_readability_v24"
const MOUTH_Z := 0.830
const RIM_Z := 0.906
const TUBE_LENGTH := 0.140
const TUBE_OUTER_RADIUS := 0.098
const TUBE_INNER_RADIUS := 0.074
const LIP_RADIUS := 0.111
const RIM_OUTER_RADIUS := 0.113
const RIM_INNER_RADIUS := 0.092
const RIM_HALF_LENGTH := 0.011
const MOUTHS := 12
const SEGMENTS := 18
static var _tube_mesh: ArrayMesh
static var _rim_mesh: ArrayMesh

static func _point(y: float,r: float,a: float) -> Vector3:
    return Vector3(r*cos(a),y,r*sin(a))

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3,shade: Color) -> void:
    for p in [a,b,c,a,c,d]:
        st.set_color(shade)
        st.add_vertex(p)

static func _ring(st: SurfaceTool,y0: float,r0: float,
        y1: float,r1: float,shade: Color) -> void:
    for k in range(SEGMENTS):
        var a: float=TAU*float(k)/float(SEGMENTS)
        var b: float=TAU*float(k+1)/float(SEGMENTS)
        _quad(st,_point(y0,r0,a),_point(y0,r0,b),
            _point(y1,r1,b),_point(y1,r1,a),shade)

static func _finish(st: SurfaceTool) -> ArrayMesh:
    st.generate_normals()
    var mat := StandardMaterial3D.new()
    mat.albedo_color=Color.WHITE
    mat.vertex_color_use_as_albedo=true
    mat.metallic=0.42
    mat.roughness=0.74
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    st.set_material(mat)
    return st.commit()

static func _mouth() -> ArrayMesh:
    if _tube_mesh!=null:
        return _tube_mesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var back: float=-TUBE_LENGTH*0.5
    var front: float=TUBE_LENGTH*0.5
    # Steel outer casing, contrasted machined rim and truly recessed
    # black interior. Same single GPU surface for all twelve openings.
    _ring(st,back,TUBE_OUTER_RADIUS,front,TUBE_OUTER_RADIUS,
        Color("#4b5a58"))
    _ring(st,front,TUBE_OUTER_RADIUS,front+0.002,LIP_RADIUS,
        Color("#9cadab"))
    _ring(st,front+0.002,LIP_RADIUS,front+0.004,TUBE_INNER_RADIUS,
        Color("#7c8c89"))
    _ring(st,front+0.004,TUBE_INNER_RADIUS,front-0.054,TUBE_INNER_RADIUS,
        Color("#172224"))
    _ring(st,front-0.054,TUBE_INNER_RADIUS,front-0.057,0.0,
        Color("#0b171a"))
    _tube_mesh=_finish(st)
    return _tube_mesh

static func _lip() -> ArrayMesh:
    if _rim_mesh!=null:
        return _rim_mesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var h: float=RIM_HALF_LENGTH
    _ring(st,-h,RIM_OUTER_RADIUS,h,RIM_OUTER_RADIUS,Color("#899c98"))
    _ring(st,h,RIM_OUTER_RADIUS,h,RIM_INNER_RADIUS,Color("#a1b4af"))
    _ring(st,h,RIM_INNER_RADIUS,-h,RIM_INNER_RADIUS,Color("#4f605d"))
    _ring(st,-h,RIM_INNER_RADIUS,-h,RIM_OUTER_RADIUS,Color("#70817e"))
    _rim_mesh=_finish(st)
    return _rim_mesh

static func _part(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func apply(model: Node3D) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta(REQUIRED,false))):
        return false
    var tubes := _part(model,
        "G11Mobile_Lote12Tubos") as MultiMeshInstance3D
    var paint := _part(model,
        "G11Mobile_MarcaModulo") as MeshInstance3D
    if tubes==null or tubes.multimesh==null or (
            tubes.multimesh.instance_count!=MOUTHS) or (
            paint==null or not paint.mesh is BoxMesh):
        return false
    var rims := _part(model,
        "G11Mobile_Lote12Bordes") as MultiMeshInstance3D
    if rims!=null and (rims.multimesh==null or
            rims.multimesh.instance_count!=MOUTHS):
        return false
    if MOUTH_Z-TUBE_LENGTH*0.5<0.76-0.002:
        return false
    tubes.multimesh.mesh=_mouth()
    var tube_axis := Basis(Vector3.RIGHT,PI*0.5)
    for column in range(4):
        for row in range(3):
            var index: int=column*3+row
            var x: float=-0.42+float(column)*0.28
            var y: float=-0.26+float(row)*0.25
            tubes.multimesh.set_instance_transform(index,
                Transform3D(tube_axis,Vector3(x,y,MOUTH_Z)))
    if rims!=null:
        rims.multimesh.mesh=_lip()
        for column in range(4):
            for row in range(3):
                var index: int=column*3+row
                var x: float=-0.42+float(column)*0.28
                var y: float=-0.26+float(row)*0.25
                rims.multimesh.set_instance_transform(index,
                    Transform3D(tube_axis,Vector3(x,y,RIM_Z)))
    # Retain approved faction paint but don't let one huge solid red/blue
    # rectangle replace a recognizable 12-mouth launch-pod silhouette.
    var patch := paint.mesh as BoxMesh
    patch.size=Vector3(0.85,0.035,0.22)
    paint.position=Vector3(0,0.478,-0.33)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v25_actual_hollow_rocket_mouths",12)
    model.set_meta("tarvoka_g11_v25_original_faction_patch_retained",true)
    model.set_meta("tarvoka_g11_v25_existing_rims_opened",rims!=null)
    return true
