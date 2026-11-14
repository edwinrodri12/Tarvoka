extends RefCounted
class_name TarvokaTankGunV22

# TARVOKA G09 V22: native, editable gun assembly on the EXISTING turret pivot.
# Resculpts four original cannon meshes instead of stacking duplicate barrels.
# The recoil cylinders and recessed bore use a tiny, shared geometry budget.
# Opt-in art_level=22; Android's default V10 and combat rules are unchanged.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V22CunaYCanon"
const GUN := "ElevacionCanon"
const PARTS := ["Canon120mm","ManguitoTermico","ExtractorGases","BocaCanon"]
const STEEL := Color("#576974")
const CERAMIC := Color("#75858B")
const DARK := Color("#18262D")
const SHAFT := Color("#A4AFB3")
const RECOIL_COUNT := 2
const REPLACED_MESHES := 4
static var _recoil_mesh: ArrayMesh

static func _material(tint: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m: StandardMaterial3D = Hero._army_material(tint,false)
    m.metallic = metallic
    m.roughness = roughness
    return m

static func _lathe(sections: Array, sides: int = 28) -> ArrayMesh:
    # Ring profile is [axial Y, radius]. Original cannon meshes have an
    # X=90deg transform: local negative Y points toward world negative Z.
    # A recessed front profile makes the muzzle genuinely hollow in silhouette.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in range(sections.size()-1):
        var lower := Vector2(float(sections[row][0]),float(sections[row][1]))
        var upper := Vector2(float(sections[row+1][0]),float(sections[row+1][1]))
        for i in range(sides):
            var a: float = TAU*float(i)/float(sides)
            var b: float = TAU*float(i+1)/float(sides)
            var l0 := Vector3(lower.y*cos(a),lower.x,lower.y*sin(a))
            var l1 := Vector3(lower.y*cos(b),lower.x,lower.y*sin(b))
            var u0 := Vector3(upper.y*cos(a),upper.x,upper.y*sin(a))
            var u1 := Vector3(upper.y*cos(b),upper.x,upper.y*sin(b))
            Hero._tri(st,l0,l1,u1)
            Hero._tri(st,l0,u1,u0)
    return st.commit()

static func _profiles() -> Array:
    # One continuous tapered barrel, keyed thermal sleeve, compact bore
    # evacuator and a proper annular muzzle crown rather than primitive boxes.
    return [
        [[-1.275,0.046],[-1.275,0.104],[-1.252,0.116],
         [-1.195,0.110],[-0.82,0.095],[-0.30,0.102],
         [0.76,0.118],[1.255,0.130],[1.275,0.001]],
        [[-0.405,0.111],[-0.398,0.139],[-0.362,0.153],
         [-0.310,0.143],[0.300,0.143],[0.365,0.153],
         [0.405,0.139],[0.411,0.111]],
        [[-0.170,0.109],[-0.158,0.142],[-0.110,0.174],
         [0.105,0.174],[0.157,0.144],[0.172,0.111]],
        [[-0.125,0.047],[-0.125,0.112],[-0.108,0.133],
         [-0.080,0.128],[0.085,0.119],[0.125,0.103]]
    ]

static func _recoil_rod_mesh() -> ArrayMesh:
    if _recoil_mesh != null:
        return _recoil_mesh
    _recoil_mesh = _lathe([
        Vector2(-0.470,0.010),Vector2(-0.466,0.051),
        Vector2(-0.420,0.062),Vector2(-0.255,0.052),
        Vector2(-0.235,0.040),Vector2(0.295,0.041),
        Vector2(0.335,0.073),Vector2(0.398,0.073),
        Vector2(0.435,0.055),Vector2(0.443,0.001)
    ],20)
    return _recoil_mesh

static func _part(pivot: Node3D, name: String, mesh: ArrayMesh,
        location: Vector3, tint: Color,
        metallic: float, roughness: float) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = mesh
    part.position = location
    part.rotation_degrees.x = 90.0
    part.material_override = _material(tint,metallic,roughness)
    pivot.add_child(part)
    return part

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_finish_v21",false):
        return false
    if model.get_meta("tarvoka_mbt_gun_v22",false):
        return false
    var pivot: Node3D = model.find_child(GUN,true,false) as Node3D
    if pivot == null:
        return false
    var originals: Array = []
    for label in PARTS:
        var part: MeshInstance3D = model.find_child(label,true,false) as MeshInstance3D
        if part == null or part.mesh == null or part.get_parent()!=pivot:
            return false
        originals.append(part)
    var profiles: Array = _profiles()
    for i in range(REPLACED_MESHES):
        var source: MeshInstance3D = originals[i]
        source.mesh = _lathe(profiles[i],32 if i==0 else 24)
        source.material_override = _material(
            CERAMIC if i==1 else (DARK if i==3 else STEEL),
            0.17 if i==1 else 0.48,0.82 if i==1 else 0.68)
    # The two recoil actuators move with the gun elevation and are visible
    # from below the existing faceted mantlet, unlike free-floating detailing.
    for side in [-1,1]:
        _part(pivot,"G09V22Amortiguador_%s" % side,
            _recoil_rod_mesh(),
            Vector3(float(side)*0.236,-0.092,-0.56),
            SHAFT,0.72,0.39)
    _part(pivot,"G09V22AnimaOscura",
        _lathe([[0.0,0.001],[0.0,0.047],[0.019,0.047]],24),
        Vector3(0.0,0.0,-2.493),DARK,0.07,0.97)
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_gun_v22",true)
    model.set_meta("tarvoka_mbt_gun_v22_replaced",REPLACED_MESHES)
    model.set_meta("tarvoka_mbt_gun_v22_recoil",RECOIL_COUNT)
    return true

static func apply_damage(model: Node3D, stage: int) -> void:
    if model == null or not model.get_meta("tarvoka_mbt_gun_v22",false):
        return
    for label in ["G09V22Amortiguador_-1","G09V22Amortiguador_1",
            "G09V22AnimaOscura"]:
        var part: Node3D = model.find_child(label,true,false) as Node3D
        if part != null:
            part.visible = stage < 4
