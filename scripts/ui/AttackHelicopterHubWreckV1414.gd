extends RefCounted
class_name TarvokaAttackHelicopterHubWreckV1414

# HAT-29 V14.14 — two physically cut fragments from the EXISTING V14.13
# central crown. Until the original V13 wreck is shown they cost no
# visible draws; the V1/V10/V14.13 rotor model remains wholly untouched.
# The original V13 wreck tween drives both via native launch/rest metadata.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const CROWN=preload("res://scripts/ui/AttackHelicopterHubCrownV1413.gd")
const FLAG="tarvoka_a01_hub_wreck_v1414"
const ENABLED="tarvoka_a01_hub_wreck_v1414_enabled"
const PREFIX="A01V1414_FragmentoCoronaRotor_"
const REST_POINTS=[
    Vector3(0.49,0.130,-0.42),
    Vector3(-0.58,0.138,-0.36)
]
const REST_ROTATIONS=[
    Vector3(69.0,22.0,-17.0),
    Vector3(-62.0,108.0,28.0)
]
const CUT_SECTORS=[
    Vector2(0.05,2.65),
    Vector2(3.02,5.90)
]
const LAUNCH=Vector3(0,2.068,0.08)
const BEFORE_TRIANGLES=616
const COLOR_DARK=Color("#434c51")
const COLOR_EXPOSED=Color("#69747a")

static func _node(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func _wreck(model: Node3D) -> Node3D:
    var v13: Node3D=_node(model,V13.WRECK)
    return v13

static func _fragment(model: Node3D,index: int) -> MeshInstance3D:
    var wreck: Node3D=_wreck(model)
    if wreck==null:
        return null
    var part: MeshInstance3D=_node(wreck,PREFIX+str(index)) as MeshInstance3D
    if part==null or part.get_parent()!=wreck:
        return null
    return part

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not CROWN.has_model(model) or not V13.has_model(model):
        return false
    for i in range(2):
        var part: MeshInstance3D=_fragment(model,i)
        if part==null or not (part.mesh is ArrayMesh):
            return false
        if not part.has_meta("a01_v13_rest"):
            return false
    return true

static func _sector(source: ArrayMesh,window: Vector2) -> ArrayMesh:
    var arrays: Array=source.surface_get_arrays(0)
    var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
    var builder:=SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Split authentic V14.13 triangles by the angular centroid, leaving
    # exposed jagged radial shears and a genuine missing metal sector.
    # No additional unbroken facsimile shell is added to the wreck.
    for tri in range(vertices.size()/3):
        var index: int=tri*3
        var a: Vector3=vertices[index]
        var b: Vector3=vertices[index+1]
        var c: Vector3=vertices[index+2]
        var centroid: Vector3=(a+b+c)/3.0
        var angle: float=atan2(centroid.z,centroid.x)
        if angle<0.0:
            angle+=TAU
        if angle<window.x or angle>window.y:
            continue
        builder.add_vertex(a)
        builder.add_vertex(b)
        builder.add_vertex(c)
    builder.generate_normals()
    return builder.commit()

static func _material(index: int) -> StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=COLOR_DARK if index==0 else COLOR_EXPOSED
    material.metallic=0.22
    material.roughness=0.83
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    return material

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    for i in range(2):
        _fragment(model,i).visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D) -> bool:
    if not CROWN.has_model(model) or not V13.has_model(model):
        return false
    if has_model(model):
        return set_enabled(model,true)
    var wreck: Node3D=_wreck(model)
    var cap: MeshInstance3D=_node(model,CROWN.CROWN) as MeshInstance3D
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if wreck==null or cap==null or rotor==null:
        return false
    if not (cap.mesh is ArrayMesh) or not (cap.get_parent()!=null):
        return false
    if not rotor.is_ancestor_of(cap) or wreck.is_ancestor_of(rotor):
        return false
    for i in range(2):
        if _node(wreck,PREFIX+str(i))!=null:
            return false
    var source: ArrayMesh=cap.mesh as ArrayMesh
    if source.get_surface_count()!=1:
        return false
    var vertices: PackedVector3Array=(
        source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            as PackedVector3Array)
    if vertices.size()!=BEFORE_TRIANGLES*3:
        return false
    var fragments: Array[ArrayMesh]=[]
    for sector in CUT_SECTORS:
        var fragment: ArrayMesh=_sector(source,sector)
        if fragment==null or fragment.get_surface_count()!=1:
            return false
        var count: int=(fragment.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            as PackedVector3Array).size()
        if count<120 or count>=vertices.size():
            return false
        fragments.append(fragment)
    # Only after complete preflight add two pieces to V13's EXISTING wreck.
    for i in range(2):
        var part:=MeshInstance3D.new()
        part.name=PREFIX+str(i)
        part.mesh=fragments[i]
        part.material_override=_material(i)
        part.position=REST_POINTS[i]
        part.rotation_degrees=REST_ROTATIONS[i]
        part.set_meta("a01_v13_launch",LAUNCH)
        part.set_meta("a01_v13_rest",part.position)
        part.set_meta("a01_v13_rot",part.rotation_degrees)
        part.set_meta("a01_v1414_from_original_crown",true)
        part.set_meta("a01_v1414_sector",CUT_SECTORS[i])
        wreck.add_child(part)
    model.set_meta(FLAG,true)
    return set_enabled(model,true)
