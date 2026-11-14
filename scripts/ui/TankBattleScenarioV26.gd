extends Node3D
class_name TarvokaTankBattleScenarioV26

# G09 V26 VISUAL QA. Real Godot 3D ground and lighting, NOT gameplay terrain.
# Twelve reproducible combinations help judge faction readability and
# V25 roughness in a battlefield-like context, without changing tank meshes,
# pathfinding, movement rules, combat, Android art defaults or saved games.
# Only ONE 3D terrain draw mesh; procedural textures generated on demand.
const TERRAIN_NAMES := ["Asfalto", "Bosque", "Desierto", "Nieve"]
const LIGHT_NAMES := ["Día", "Atardecer", "Noche"]
const TERRAIN_COLOR := [
    Color("#626C71"),Color("#4C664E"),Color("#BCA477"),Color("#CEDDE7")
]
const SKY_COLORS := [
    Color("#6D9BAF"),Color("#9E6C5E"),Color("#0B1D35")
]
const AMBIENT_COLORS := [
    Color("#CADCE5"),Color("#D2A893"),Color("#8EA9C6")
]
const SUN_COLORS := [
    Color("#FFF2DE"),Color("#F5B883"),Color("#A9C8EF")
]
const SIZE := 128
const GRID := 28
const SPAN := 14.0
static var _ground_albedo: Dictionary = {}
static var _ground_meshes: Dictionary = {}

var terrain_index := 0
var light_index := 0
var active := false
var ground: MeshInstance3D
var world: WorldEnvironment
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D

static func _hash(x: int,y: int,seed: int) -> float:
    return float(posmod(x*9283+y*5393+seed*491+73,104729))/104728.0

static func _terrain_texture(terrain: int) -> ImageTexture:
    if _ground_albedo.has(terrain):
        return _ground_albedo[terrain] as ImageTexture
    var img := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
    var pigment: Color = TERRAIN_COLOR[terrain]
    for y in range(SIZE):
        for x in range(SIZE):
            var noise: float = _hash(x,y,terrain+1)
            var noise2: float = _hash(int(x/8),int(y/8),terrain+7)
            var grit: float = 0.89+0.17*(noise2-0.5)+0.13*(noise-0.5)
            # Paving seams, clumps of grass, dune dust and scattered snow.
            if terrain==0 and (posmod(x+4,43)==0 or posmod(y+7,43)==0):
                grit *= 0.63
            elif terrain==1 and noise>0.965:
                grit *= 1.16
            elif terrain==2 and noise2>0.74:
                grit *= 1.05
            elif terrain==3 and noise<0.075:
                grit *= 0.85
            img.set_pixel(x,y,Color(
                clampf(pigment.r*grit,0.0,1.0),
                clampf(pigment.g*grit,0.0,1.0),
                clampf(pigment.b*grit,0.0,1.0),1.0))
    img.generate_mipmaps()
    var tex := ImageTexture.create_from_image(img)
    _ground_albedo[terrain] = tex
    return tex

static func _height(x: float,z: float,terrain: int) -> float:
    # Flat beneath the vehicle: this is a material/light test, not a change
    # to the rigid body rig. Gentle undulations only in the outer background.
    var radius: float = Vector2(x,z).length()
    var outer: float = smoothstep(2.40,5.25,radius)
    var amplitude: float = [0.045,0.19,0.16,0.075][terrain]
    return -0.115+amplitude*outer*(
        sin(x*1.18+0.33*float(terrain))*cos(z*0.98)
        +0.36*sin(x*2.05-z*1.74))

static func _vertex(st: SurfaceTool,point: Vector3) -> void:
    st.set_uv(Vector2(point.x*0.29+0.5,point.z*0.29+0.5))
    st.add_vertex(point)

static func _mesh(terrain: int) -> ArrayMesh:
    if _ground_meshes.has(terrain):
        return _ground_meshes[terrain] as ArrayMesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in range(GRID):
        for x in range(GRID):
            var x0: float = SPAN*(float(x)/float(GRID)-0.5)
            var x1: float = SPAN*(float(x+1)/float(GRID)-0.5)
            var z0: float = SPAN*(float(z)/float(GRID)-0.5)
            var z1: float = SPAN*(float(z+1)/float(GRID)-0.5)
            var a := Vector3(x0,_height(x0,z0,terrain),z0)
            var b := Vector3(x1,_height(x1,z0,terrain),z0)
            var c := Vector3(x0,_height(x0,z1,terrain),z1)
            var d := Vector3(x1,_height(x1,z1,terrain),z1)
            # Correct upward-facing winding for opaque PBR ground.
            _vertex(st,a)
            _vertex(st,c)
            _vertex(st,b)
            _vertex(st,b)
            _vertex(st,c)
            _vertex(st,d)
    st.generate_normals()
    var result: ArrayMesh = st.commit()
    _ground_meshes[terrain] = result
    return result

static func _material(terrain: int) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = _terrain_texture(terrain)
    mat.albedo_color = Color.WHITE
    mat.metallic = 0.03 if terrain!=0 else 0.13
    mat.roughness = 0.91 if terrain!=3 else 0.86
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

func setup(env: WorldEnvironment,main_light: DirectionalLight3D,
        secondary_light: DirectionalLight3D) -> void:
    world = env
    key_light = main_light
    fill_light = secondary_light
    ground = MeshInstance3D.new()
    ground.name = "G09V26CampoDePruebaReal"
    add_child(ground)
    apply_conditions()

func set_active(enabled: bool) -> void:
    active = enabled
    apply_conditions()

func set_conditions(terrain: int,period: int) -> void:
    terrain_index = clampi(terrain,0,TERRAIN_NAMES.size()-1)
    light_index = clampi(period,0,LIGHT_NAMES.size()-1)
    apply_conditions()

func apply_conditions() -> void:
    if ground == null or world == null or key_light == null or fill_light == null:
        return
    ground.visible = active
    if active:
        ground.mesh = _mesh(terrain_index)
        ground.material_override = _material(terrain_index)
    var scene: Environment = world.environment
    if active:
        scene.background_color = SKY_COLORS[light_index]
        scene.ambient_light_color = AMBIENT_COLORS[light_index]
        scene.ambient_light_energy = [0.87,0.59,0.39][light_index]
        key_light.light_color = SUN_COLORS[light_index]
        key_light.light_energy = [1.49,0.95,0.41][light_index]
        key_light.rotation_degrees = [
            Vector3(-46,-32,0),Vector3(-19,-56,0),Vector3(-30,88,0)
        ][light_index]
        key_light.shadow_enabled = true
        fill_light.light_color = Color("#C9E2F1") if light_index!=1 else Color("#9FBCE8")
        fill_light.light_energy = [0.72,0.34,0.24][light_index]
    else:
        # Restore the EXACT pre-V26 neutral studio lighting for all older
        # visual regression tests and the prior 25 model comparisons.
        scene.background_color = Color("#14232D")
        scene.ambient_light_color = Color("#C1D5DE")
        scene.ambient_light_energy = 0.84
        key_light.light_color = Color.WHITE
        key_light.light_energy = 1.65
        key_light.rotation_degrees = Vector3(-46,-32,0)
        key_light.shadow_enabled = false
        fill_light.light_color = Color.WHITE
        fill_light.light_energy = 0.8
