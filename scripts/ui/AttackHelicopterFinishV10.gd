extends RefCounted
class_name TarvokaAttackHelicopterFinishV10

# A01 V10: physically grounded close-view materials, glass reflections,
# rotor retaining hardware, windshield seals and weapon muzzle band.
# Strictly an art_level >= 13 Studio overlay, never tactical Android LOD.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V8=preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const FLAG := "tarvoka_a01_hero_finish_v10"
const ENABLED := "tarvoka_a01_hero_finish_v10_enabled"
const ROOT := "A01V10_AcabadosOpticosYMecanicos"
const ROTOR := "A01V10_BujeMecanicoRotor"
const GUN := "A01V10_AnilloMecanicoCanon"
const WINDSHIELD := "A01V10_BarraSelladoParabrisas_"
const ROTOR_BOLT := "A01V10_PernoBujeRotor_"
const MATERIAL_BEFORE := "a01_v10_material_original"
const MATERIAL_AFTER := "a01_v10_material_enhanced"

const MATERIAL_TARGETS := [
    "A01_V2_CupulaTandemCristal3D",
    "A01_Optica",
    "A01_BujePrincipal",
    "A01V4_MotorCarenado_-1",
    "A01V4_MotorCarenado_1",
    "A01V4_BlindajeLateral_-1",
    "A01V4_BlindajeLateral_1",
    "A01V4_InteriorEscape_-1",
    "A01V4_InteriorEscape_1"
]

static func _node(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _node(model,ROOT)!=null and _node(model,ROTOR)!=null
        and _node(model,GUN)!=null)

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _material(color: Color,
        metallic: float=0.48,roughness: float=0.39) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metallic
    mat.roughness=roughness
    mat.metallic_specular=0.70
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        color: Color,pos: Vector3=Vector3.ZERO,
        metallic: float=0.48) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.position=pos
    n.material_override=_material(color,metallic)
    parent.add_child(n)
    return n

static func _rod(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,color: Color) -> MeshInstance3D:
    var axis: Vector3=b-a
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=axis.length()
    shape.radial_segments=10
    var n:=_mesh(parent,name,shape,color,(a+b)*0.5)
    n.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return n

static func _bolt(parent: Node3D,name: String,pos: Vector3) -> void:
    var hex:=CylinderMesh.new()
    hex.top_radius=0.032
    hex.bottom_radius=0.032
    hex.height=0.044
    hex.radial_segments=6
    _mesh(parent,name,hex,Color("#b8c8ce"),pos,0.61)

static func _canopy_windscreen(body: Node3D) -> void:
    # Both 3D windscreen retaining bars follow the actual V2 canopy loft's
    # front roof curve. No drawn-on 2D fake reflections or floating rectangles.
    for side in [-1,1]:
        var sign: float=float(side)
        _rod(body,WINDSHIELD+str(side),
            Vector3(sign*0.039,1.495,-1.423),
            Vector3(sign*0.137,1.664,-1.168),
            0.010,Color("#a6bac2"))
        var fixture:=SphereMesh.new()
        fixture.radius=0.026
        fixture.height=0.052
        fixture.radial_segments=10
        fixture.rings=6
        _mesh(body,"A01V10_FijacionParabrisas_"+str(side),
            fixture,Color("#34434a"),
            Vector3(sign*0.137,1.664,-1.168))

static func _rotor_hub(rotor: Node3D) -> void:
    # All original V1/V3 motor/pitch animation transforms are preserved.
    var hardware:=_group(rotor,ROTOR)
    var ring:=TorusMesh.new()
    ring.inner_radius=0.156
    ring.outer_radius=0.229
    ring.rings=10
    ring.ring_segments=28
    _mesh(hardware,"A01V10_CoronaSuperiorRotor",ring,
        Color("#a9b9bf"),Vector3(0,0.098,0),0.68)
    for i in range(4):
        var a: float=TAU*float(i)/4.0+PI/4.0
        _bolt(hardware,ROTOR_BOLT+str(i),
            Vector3(cos(a)*0.164,0.118,sin(a)*0.164))

static func _weapon_detail(weapon: Node3D) -> void:
    var node:=_group(weapon,GUN)
    var ring:=TorusMesh.new()
    ring.inner_radius=0.077
    ring.outer_radius=0.107
    ring.rings=8
    ring.ring_segments=22
    var band:=_mesh(node,"A01V10_AroCromadoCanon",ring,
        Color("#aab6ba"),Vector3(0,0,-0.518),0.60)
    # Face axis perpendicular to the original real Z-directed V1 barrel.
    band.rotation_degrees.x=90.0

static func _material_variant(mesh: MeshInstance3D,name: String) -> StandardMaterial3D:
    var before: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    var variant: StandardMaterial3D=before.duplicate() as StandardMaterial3D
    match name:
        V2.GLASS:
            variant.albedo_color=Color(0.22,0.48,0.63,0.73)
            variant.metallic=0.02
            variant.roughness=0.115
            variant.metallic_specular=0.87
        "A01_Optica":
            variant.albedo_color=Color("#488da7")
            variant.metallic=0.06
            variant.roughness=0.14
            variant.metallic_specular=0.92
        "A01_BujePrincipal":
            variant.albedo_color=Color("#a4b2b8")
            variant.metallic=0.67
            variant.roughness=0.31
        _:
            if name.begins_with(V4.NACELLE):
                variant.albedo_color=Color("#71818b")
                variant.metallic=0.43
                variant.roughness=0.45
            elif name.begins_with(V4.SIDE_PANEL):
                variant.albedo_color=Color("#76828a")
                variant.metallic=0.28
                variant.roughness=0.56
            elif name.begins_with("A01V4_InteriorEscape_"):
                variant.albedo_color=Color("#202e35")
                variant.metallic=0.48
                variant.roughness=0.37
    return variant

static func _patch_material(mesh: MeshInstance3D,name: String) -> void:
    if mesh.has_meta(MATERIAL_BEFORE):
        return
    mesh.set_meta(MATERIAL_BEFORE,mesh.material_override)
    mesh.set_meta(MATERIAL_AFTER,_material_variant(mesh,name))

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    for component in [ROOT,ROTOR,GUN]:
        var layer: Node3D=_node(model,component)
        layer.visible=enabled
    for name in MATERIAL_TARGETS:
        var mesh: MeshInstance3D=_node(model,name) as MeshInstance3D
        if mesh==null or not mesh.has_meta(MATERIAL_BEFORE):
            return false
        mesh.material_override=(
            mesh.get_meta(MATERIAL_AFTER) if enabled else
            mesh.get_meta(MATERIAL_BEFORE))
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,_faction: Color) -> bool:
    if not V8.has_model(model) or not V2.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_node(model,V1.ROOT)
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    var weapon: Node3D=_node(model,V1.GUN)
    if body==null or rotor==null or weapon==null:
        return false
    # Preflight every material: don't leave a half-applied broken A01.
    for name in MATERIAL_TARGETS:
        var part: MeshInstance3D=_node(model,name) as MeshInstance3D
        if part==null or not (part.material_override is StandardMaterial3D):
            return false
    var layer:=_group(body,ROOT)
    _canopy_windscreen(layer)
    _rotor_hub(rotor)
    _weapon_detail(weapon)
    for name in MATERIAL_TARGETS:
        _patch_material(_node(model,name) as MeshInstance3D,name)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
