extends Node3D
class_name TarvokaAirbaseScarsV14

# Visual-only persistent surface relief. This does NOT cut the collision
# mesh or alter structural HP. It places a contoured 3D dent/scar just
# outside the existing steel, concrete and roof faces. Marks survive FX
# completion and studio rebuild via an event ledger in the studio controller.
# Nine capped pooled pairs: 3 surfaces x 3 marks each. No lights/physics.
const V1=preload("res://scripts/ui/Airbase3DV1.gd")
const V10=preload("res://scripts/ui/AirbaseStructureV10.gd")
const V13=preload("res://scripts/ui/AirbaseImpactsV13.gd")
const STAGE_NAME: String="MarcasPersistentesImpactosBaseAereaV14"
signal mark_changed(surface: String,slot: int,attack: String)
signal marks_cleared()
const MAX_PER_SURFACE: int=3
const SURFACES: Array[String]=["gate_metal","tower_concrete","hangar_roof"]
const ATTACKS: Array[String]=["bullet","missile","bombardment"]
static var _dent_meshes: Dictionary={}
static var _soot_meshes: Dictionary={}
static var _materials: Dictionary={}

var damage_stage: int=0
var _history: Array[Dictionary]=[]
var _counts: Dictionary={}
var _slots: Dictionary={}

static func _tone(surface: String) -> Color:
    match surface:
        "gate_metal":
            return Color("#6e7777")
        "tower_concrete":
            return Color("#b9b7a9")
        "hangar_roof":
            return Color("#72838c")
    return Color.WHITE

static func _damage_radius(attack: String) -> float:
    match attack:
        "bullet":
            return 0.11
        "missile":
            return 0.27
        "bombardment":
            return 0.32
    return 0.0

static func _material(surface: String,soot: bool=false) -> StandardMaterial3D:
    var key: String=surface+("_soot" if soot else "_metal")
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.roughness=0.85 if soot else 0.67
    mat.metallic=0.02 if soot else 0.37 if surface!="tower_concrete" else 0.03
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    if soot:
        mat.albedo_color=Color(0.09,0.085,0.08,0.50)
        mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_ALWAYS
    else:
        mat.albedo_color=Color.WHITE
        mat.vertex_color_use_as_albedo=true
    _materials[key]=mat
    return mat

static func _ring(tool: SurfaceTool,r0: float,r1: float,
        z0: float,z1: float,c0: Color,c1: Color,
        segment: int,count: int,irregular: float) -> void:
    for step in [segment,segment+1]:
        var phi: float=TAU*float(step%count)/float(count)
        var rough: float=1.0+sin(phi*5.0+0.6)*irregular+cos(
            phi*7.0-0.2)*irregular*0.50
        for ring_index in [0,1]:
            var radius: float=(r0 if ring_index==0 else r1)*rough
            var depth: float=z0 if ring_index==0 else z1
            tool.set_color(c0 if ring_index==0 else c1)
            tool.add_vertex(Vector3(cos(phi)*radius,sin(phi)*radius,depth))

static func _add_quad(tool: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3,d: Vector3,
        color_a: Color,color_b: Color) -> void:
    for vertex in [a,b,c,a,c,d]:
        tool.set_color(color_a if vertex==a or vertex==d else color_b)
        tool.add_vertex(vertex)

static func _relief(attack: String,surface: String) -> ArrayMesh:
    var key: String=surface+"/"+attack
    if _dent_meshes.has(key):
        return _dent_meshes[key] as ArrayMesh
    var radius: float=_damage_radius(attack)
    var metal: Color=_tone(surface)
    var highlight: Color=metal.lightened(0.28)
    var char: Color=Color("#242624") if surface!="tower_concrete" else Color("#55524b")
    var rings: Array[float]=[1.12,0.77,0.50,0.08]
    var heights: Array[float]=[0.008,0.061,0.026,0.020]
    var colors: Array[Color]=[metal,highlight,char,char.darkened(0.40)]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var steps: int=20
    # A fully solid 3D raised rim enclosing a sunken dark center. The
    # source slab is deliberately unchanged: real CSG holes cost more.
    for layer in range(3):
        for i in range(steps):
            var phi0: float=TAU*float(i)/float(steps)
            var phi1: float=TAU*float(i+1)/float(steps)
            var rough0: float=1.0+0.075*sin(phi0*5.0)+0.045*cos(phi0*7.0)
            var rough1: float=1.0+0.075*sin(phi1*5.0)+0.045*cos(phi1*7.0)
            var points: Array[Vector3]=[
                Vector3(cos(phi0)*radius*rings[layer]*rough0,
                    sin(phi0)*radius*rings[layer]*rough0,heights[layer]),
                Vector3(cos(phi1)*radius*rings[layer]*rough1,
                    sin(phi1)*radius*rings[layer]*rough1,heights[layer]),
                Vector3(cos(phi1)*radius*rings[layer+1]*rough1,
                    sin(phi1)*radius*rings[layer+1]*rough1,heights[layer+1]),
                Vector3(cos(phi0)*radius*rings[layer+1]*rough0,
                    sin(phi0)*radius*rings[layer+1]*rough0,heights[layer+1])]
            for j in [0,1,2,0,2,3]:
                st.set_color(colors[layer] if j in [0,1,3] else colors[layer+1])
                st.add_vertex(points[j])
    st.generate_normals()
    var mesh: ArrayMesh=st.commit()
    _dent_meshes[key]=mesh
    return mesh

static func _halo(attack: String) -> ArrayMesh:
    if _soot_meshes.has(attack):
        return _soot_meshes[attack] as ArrayMesh
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var radius: float=_damage_radius(attack)
    for i in range(20):
        var a: float=TAU*float(i)/20.0
        var b: float=TAU*float(i+1)/20.0
        var r1: float=radius*(1.43+0.08*sin(a*6.0))
        var r2: float=radius*1.12
        var r3: float=radius*(1.43+0.08*sin(b*6.0))
        var points: Array[Vector3]=[
            Vector3(cos(a)*r1,sin(a)*r1,0.010),
            Vector3(cos(b)*r3,sin(b)*r3,0.010),
            Vector3(cos(b)*r2,sin(b)*r2,0.011),
            Vector3(cos(a)*r2,sin(a)*r2,0.011)]
        for j in [0,1,2,0,2,3]:
            st.add_vertex(points[j])
    st.generate_normals()
    var mesh: ArrayMesh=st.commit()
    _soot_meshes[attack]=mesh
    return mesh

static func _position(surface: String,slot: int) -> Vector3:
    var at: Vector3=V13.surface_position(surface)
    var offsets: Array[float]=[0.0,-0.34,0.33]
    var dx: float=offsets[slot]
    match surface:
        "gate_metal":
            at.x+=dx
            at.y+=0.15*float(slot%2)
            at.z=-4.174 # original V1 gate face is z=-4.150
        "tower_concrete":
            # Stay inside the exposed left concrete bay, rather than
            # placing over the central/front metal frame.
            at.x+=dx*0.30
            at.y+=0.30*float(slot)
            at.z=-2.864
        "hangar_roof":
            var local_x: float=2.80+dx
            at.x=V1.HANGAR_CENTER_X+local_x
            at.y=V10._roof_y(local_x)+0.034
            at.z+=0.31*float(slot-1)
    return at

static func _normal(surface: String,slot: int) -> Vector3:
    if surface!="hangar_roof":
        return Vector3(0,0,-1)
    var x: float=2.80+[0.0,-0.34,0.33][slot]
    var slope: float=(V10._roof_y(x+0.06)-V10._roof_y(x-0.06))/0.12
    return Vector3(-slope,1,0).normalized()

func _ready() -> void:
    name=STAGE_NAME
    set_meta("tarvoka_visual_only",true)
    for surface in SURFACES:
        _counts[surface]=0
        var group:=Node3D.new()
        group.name="SuperficiePersistenteV14_"+surface
        add_child(group)
        var faces: Array[Dictionary]=[]
        for i in range(MAX_PER_SURFACE):
            var anchor:=Node3D.new()
            anchor.name="HuellaDeImpactoV14_%s_%d" % [surface,i]
            anchor.visible=false
            group.add_child(anchor)
            var relief:=MeshInstance3D.new()
            relief.name="AbolladuraConRelieveV14"
            relief.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            relief.material_override=_material(surface)
            anchor.add_child(relief)
            var soot:=MeshInstance3D.new()
            soot.name="HaloCarbonizadoV14"
            soot.material_override=_material(surface,true)
            soot.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            anchor.add_child(soot)
            faces.append({"root":anchor,"relief":relief,"soot":soot})
        _slots[surface]=faces

func add_mark(attack: String,surface: String) -> bool:
    if not V13.valid_attack(attack,surface,damage_stage):
        return false
    var marks: int=3 if attack=="bombardment" else 1
    for index in range(marks):
        var count: int=int(_counts[surface])
        var slot: int=count%MAX_PER_SURFACE
        var face: Dictionary=(_slots[surface] as Array)[slot]
        var anchor: Node3D=face["root"] as Node3D
        var relief: MeshInstance3D=face["relief"] as MeshInstance3D
        var soot: MeshInstance3D=face["soot"] as MeshInstance3D
        relief.mesh=_relief(attack,surface)
        soot.mesh=_halo(attack)
        soot.visible=attack!="bullet"
        anchor.position=_position(surface,slot)
        var n: Vector3=_normal(surface,slot)
        anchor.basis=Basis.looking_at(-n,
            Vector3.FORWARD if surface=="hangar_roof" else Vector3.UP)
        # Shallow concrete crater rather than a wall-mounted plaque.
        anchor.scale=Vector3(1.0,1.0,0.64) if surface=="tower_concrete" else Vector3.ONE
        anchor.visible=true
        _counts[surface]=count+1
        mark_changed.emit(surface,slot,attack)
    _history.append({"attack":attack,"surface":surface})
    return true

func clear_marks() -> void:
    for surface in SURFACES:
        _counts[surface]=0
        for face in _slots[surface]:
            var anchor: Node3D=face["root"] as Node3D
            anchor.visible=false
    _history.clear()
    marks_cleared.emit()

func restore(events: Array[Dictionary]) -> void:
    clear_marks()
    for entry in events:
        if entry.has("attack") and entry.has("surface"):
            add_mark(str(entry["attack"]),str(entry["surface"]))

func event_count() -> int:
    return _history.size()

func visible_marks(surface: String) -> int:
    if surface not in SURFACES:
        return 0
    return mini(int(_counts[surface]),MAX_PER_SURFACE)

func active_mesh_instances() -> int:
    var total: int=0
    for surface in SURFACES:
        for face in _slots[surface]:
            if (face["root"] as Node3D).visible:
                total+=1
                if (face["soot"] as MeshInstance3D).visible:
                    total+=1
    return total

func snapshot() -> Array[Dictionary]:
    return _history.duplicate(true)
