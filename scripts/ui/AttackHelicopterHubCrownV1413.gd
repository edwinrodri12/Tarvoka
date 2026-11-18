extends RefCounted
class_name TarvokaAttackHelicopterHubCrownV1413

# HAT-29 V14.13 - close/finish the original spinning V10 crown IN PLACE.
# Real Godot 4.3 mesh: one single machined, closed, stepped metal cover;
# NOT an added decorative dome, duplicate rotor or a screenshot.
# The original V1 hub, V10 bolts, V14.5 ring and all pitch pivots survive.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const SEAM=preload("res://scripts/ui/AttackHelicopterBladeSeamV1412.gd")
const FLAG="tarvoka_a01_hub_crown_v1413"
const ENABLED="tarvoka_a01_hub_crown_v1413_enabled"
const CROWN="A01V10_CoronaSuperiorRotor"
const ORIGINAL_MESH="a01_v1413_original_crown_mesh"
const ORIGINAL_MATERIAL="a01_v1413_original_crown_material"
const RADIAL_SEGMENTS=28
const PROFILE=[
    Vector2(0.224,-0.044), # Below V1's y=.060 hub lid: real contact
    Vector2(0.233,-0.031),
    Vector2(0.236,-0.015), # Wide retaining rim
    Vector2(0.233,0.013),
    Vector2(0.211,0.029), # Chamfered top shoulder
    Vector2(0.187,0.032),
    Vector2(0.170,0.021), # Seat the four original V10 hex bolts
    Vector2(0.150,0.015),
    Vector2(0.121,0.024), # Enclosed inset cap, no bright open bowl
    Vector2(0.095,0.027),
    Vector2(0.060,0.031)
]
const CENTER_HEIGHT=0.033
const GRAPHITE=Color("#5c7078")

static func _node(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _crown(model: Node3D) -> MeshInstance3D:
    var main: Node3D=_node(model,V1.MAIN_ROTOR)
    if main==null:
        return null
    var v10: Node3D=_node(model,V10.ROTOR)
    if v10==null or v10.get_parent()!=main:
        return null
    var mesh: MeshInstance3D=_node(v10,CROWN) as MeshInstance3D
    if mesh==null or mesh.get_parent()!=v10:
        return null
    return mesh

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var cap: MeshInstance3D=_crown(model)
    return SEAM.has_model(model) and cap!=null and (
        cap.get_meta(ORIGINAL_MESH) is TorusMesh)

static func _point(radius: float,y: float,angle: float) -> Vector3:
    return Vector3(radius*cos(angle),y,radius*sin(angle))

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _machined_cover() -> ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # A lathed ring profile entirely inside the original rotor crown.
    # XZ ring orientation gives outward face normals when the profile
    # runs bottom-outside -> top-outside -> top-inside.
    for ring in range(PROFILE.size()-1):
        var low: Vector2=PROFILE[ring]
        var high: Vector2=PROFILE[ring+1]
        for i in range(RADIAL_SEGMENTS):
            var angle: float=TAU*float(i)/float(RADIAL_SEGMENTS)
            var angle_next: float=TAU*float(i+1)/float(RADIAL_SEGMENTS)
            _quad(st,
                _point(low.x,low.y,angle),
                _point(high.x,high.y,angle),
                _point(high.x,high.y,angle_next),
                _point(low.x,low.y,angle_next))
    # Close the top center, visible from overhead, and close the lower
    # flat face, physically seated against the ORIGINAL V1 cylinder.
    var small: Vector2=PROFILE[PROFILE.size()-1]
    var base: Vector2=PROFILE[0]
    for i in range(RADIAL_SEGMENTS):
        var angle: float=TAU*float(i)/float(RADIAL_SEGMENTS)
        var angle_next: float=TAU*float(i+1)/float(RADIAL_SEGMENTS)
        _tri(st,
            Vector3(0,CENTER_HEIGHT,0),
            _point(small.x,small.y,angle_next),
            _point(small.x,small.y,angle))
        _tri(st,
            Vector3(0,base.y,0),
            _point(base.x,base.y,angle),
            _point(base.x,base.y,angle_next))
    st.generate_normals()
    return st.commit()

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    var cap: MeshInstance3D=_crown(model)
    if enabled:
        cap.mesh=_machined_cover()
        var previous: StandardMaterial3D=cap.get_meta(
            ORIGINAL_MATERIAL) as StandardMaterial3D
        if previous!=null:
            var finish: StandardMaterial3D=previous.duplicate() as StandardMaterial3D
            finish.albedo_color=GRAPHITE
            finish.metallic=0.49
            finish.roughness=0.57
            cap.material_override=finish
    else:
        cap.mesh=cap.get_meta(ORIGINAL_MESH) as Mesh
        cap.material_override=cap.get_meta(ORIGINAL_MATERIAL) as Material
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D) -> bool:
    if not SEAM.has_model(model) or not V10.has_model(model):
        return false
    if has_model(model):
        return set_enabled(model,true)
    var cap: MeshInstance3D=_crown(model)
    var original_hub: MeshInstance3D=_node(model,"A01_BujePrincipal") as MeshInstance3D
    if cap==null or original_hub==null or not (cap.mesh is TorusMesh):
        return false
    if not is_equal_approx(cap.position.y,0.098):
        return false
    if original_hub.get_parent()!=_node(model,V1.MAIN_ROTOR):
        return false
    if not (cap.material_override is StandardMaterial3D):
        return false
    cap.set_meta(ORIGINAL_MESH,cap.mesh)
    cap.set_meta(ORIGINAL_MATERIAL,cap.material_override)
    model.set_meta(FLAG,true)
    return set_enabled(model,true)
