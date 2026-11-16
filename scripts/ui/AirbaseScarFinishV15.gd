extends Node3D
class_name TarvokaAirbaseScarFinishV15

# True Godot 4.3 3D finish laid on top of, never replacing, V14 relief.
# Each of the nine V14 slots receives at most one pooled accent mesh.
# Separate concrete cracks, peeled steel and torn roof sheets; scorch
# geometry is deliberately irregular, not repeated circular decals.
const V14=preload("res://scripts/ui/AirbaseScarsV14.gd")
const STAGE_NAME: String="GrietasConcretoMetalDesgarradoV15"
const ACCENT_NAME: String="FracturasOrgánicasSobreRelieveV15"
const SEGMENTS: int=20
static var _cache: Dictionary={}
static var _material_shared: StandardMaterial3D

var _scar: TarvokaAirbaseScarsV14
var _details: Dictionary={}

static func _radius(attack: String) -> float:
    return V14._damage_radius(attack)

static func _polar(angle: float,radius: float,z: float) -> Vector3:
    return Vector3(cos(angle)*radius,sin(angle)*radius,z)

static func _tint(surface: String,attack: String) -> Color:
    if surface=="tower_concrete":
        return Color("#55534d") if attack=="bullet" else Color("#48433d")
    if surface=="hangar_roof":
        return Color("#b0bdc2") if attack=="bullet" else Color("#806a59")
    return Color("#cad3d2") if attack=="bullet" else Color("#98877a")

static func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3,color: Color) -> void:
    for vert in [a,b,c,a,c,d]:
        tool.set_color(color)
        tool.add_vertex(vert)

static func _triangle(tool: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,color: Color) -> void:
    for vert in [a,b,c]:
        tool.set_color(color)
        tool.add_vertex(vert)

static func _crack(tool: SurfaceTool,start: Vector3,
        finish: Vector3,width: float,color: Color) -> void:
    var heading: Vector3=finish-start
    if heading.length_squared()<0.000001:
        return
    var perp:=Vector3(-heading.y,heading.x,0).normalized()*width*0.5
    _quad(tool,start-perp,start+perp,finish+perp,finish-perp,color)

static func _concrete(tool: SurfaceTool,attack: String,
        slot: int,stats: Dictionary) -> void:
    var radius: float=_radius(attack)
    var dark: Color=_tint("tower_concrete",attack)
    var rays: int=5 if attack=="bullet" else 7 if attack=="missile" else 9
    var turn: float=0.41+float(slot)*0.29
    for ray in range(rays):
        var base: float=TAU*float(ray)/float(rays)+turn
        var previous: Vector3=_polar(base,radius*0.63,0.066)
        for piece in range(3):
            var r: float=radius*(0.63+float(piece+1)*0.37)
            var wobble: float=0.09*sin(float(ray*7+piece*13+slot*3))
            var point: Vector3=_polar(base+wobble,r,0.070)
            _crack(tool,previous,point,0.015 if attack=="bullet" else 0.021,dark)
            stats["crack_segments"]+=1
            if piece==1:
                var side: Vector3=_polar(base+0.28+0.06*float(ray%3),
                    radius*(1.38+0.17*float(ray%2)),0.071)
                _crack(tool,point,side,0.011,dark)
                stats["crack_segments"]+=1
            previous=point
    # Jagged chips stand above the wall: small triangular slivers rather
    # than one perfectly circular black disk.
    for chip in range(5 if attack=="bullet" else 9):
        var angle: float=TAU*float(chip)/float(5 if attack=="bullet" else 9)+turn
        var far: float=radius*(1.05+0.11*float(chip%3))
        _triangle(tool,
            _polar(angle-0.17,far,0.069),
            _polar(angle+0.12,far*1.09,0.072),
            _polar(angle+0.035,far*1.27,0.081),
            Color("#73716a"))
        stats["chips"]+=1

static func _steel(tool: SurfaceTool,surface: String,
        attack: String,slot: int,stats: Dictionary) -> void:
    var radius: float=_radius(attack)
    var steel: Color=_tint(surface,attack)
    var dark:=Color("#332f2c")
    var angle_offset: float=float(slot)*0.37
    # Each raised, folded metal lip is two joined triangles with a
    # displaced centre ridge. Topology differs for hangar sheet vs gate.
    var folds: int=3 if attack=="bullet" else 5 if attack=="missile" else 7
    if surface=="hangar_roof":
        folds+=1
    for fold in range(folds):
        var angle: float=TAU*float(fold)/float(folds)+angle_offset
        var a: Vector3=_polar(angle-0.20,radius*0.63,0.071)
        var b: Vector3=_polar(angle+0.17,radius*0.85,0.076)
        var lifted: Vector3=_polar(angle+0.07,radius*(1.04+0.08*float(fold%3)),
            0.125 if surface=="hangar_roof" else 0.107)
        var tail: Vector3=_polar(angle+0.025,
            radius*(1.37+0.10*float(fold%2)),0.046)
        _triangle(tool,a,b,lifted,steel)
        _triangle(tool,b,tail,lifted,dark)
        stats["folds"]+=1
    # Scratches run tangentially across the deformation; they are not
    # hairline circles or duplicated effects from V14.
    for scrape in range(3 if attack=="bullet" else 5):
        var heading: float=float(scrape)*0.72+angle_offset
        var a: Vector3=_polar(heading,radius*0.94,0.080)
        var b: Vector3=_polar(heading+0.32,
            radius*(1.22+0.08*float(scrape%2)),0.083)
        _crack(tool,a,b,0.010,dark)
        stats["scratches"]+=1

static func _burn(tool: SurfaceTool,attack: String,
        slot: int,stats: Dictionary) -> void:
    if attack=="bullet":
        return
    var radius: float=_radius(attack)
    var ash:=Color("#292a28")
    var count: int=10 if attack=="bombardment" else 7
    var offset: float=float(slot)*0.31
    for island in range(count):
        var angle: float=offset+TAU*float(island)/float(count)
        var r0: float=radius*(1.30+0.07*float(island%2))
        var r1: float=r0+radius*(0.24+0.09*float(island%3))
        _triangle(tool,
            _polar(angle-0.17,r0,0.019),
            _polar(angle+0.15,r0*1.02,0.019),
            _polar(angle+0.01,r1,0.020),
            ash)
        stats["soot_islands"]+=1

static func _build_mesh(surface: String,attack: String,
        slot: int) -> ArrayMesh:
    var key: String="%s/%s/%d" % [surface,attack,slot]
    if _cache.has(key):
        return _cache[key] as ArrayMesh
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var metrics: Dictionary={
        "crack_segments":0,"chips":0,"folds":0,
        "scratches":0,"soot_islands":0
    }
    if surface=="tower_concrete":
        _concrete(tool,attack,slot,metrics)
    else:
        _steel(tool,surface,attack,slot,metrics)
    _burn(tool,attack,slot,metrics)
    tool.generate_normals()
    var mesh: ArrayMesh=tool.commit()
    mesh.set_meta("tarvoka_v15_finish",metrics)
    _cache[key]=mesh
    return mesh

static func _mat() -> StandardMaterial3D:
    if _material_shared!=null:
        return _material_shared
    _material_shared=StandardMaterial3D.new()
    _material_shared.albedo_color=Color.WHITE
    _material_shared.vertex_color_use_as_albedo=true
    _material_shared.metallic=0.23
    _material_shared.roughness=0.79
    _material_shared.cull_mode=BaseMaterial3D.CULL_DISABLED
    return _material_shared

func bind_to_scars(scar: TarvokaAirbaseScarsV14) -> bool:
    if scar==null or _scar!=null:
        return false
    _scar=scar
    scar.mark_changed.connect(_on_mark)
    scar.marks_cleared.connect(_on_clear)
    return true

func _on_mark(surface: String,slot: int,attack: String) -> void:
    if _scar==null or surface not in V14.SURFACES or \
            attack not in V14.ATTACKS:
        return
    if slot<0 or slot>=V14.MAX_PER_SURFACE:
        return
    var detail_key: String="%s/%d" % [surface,slot]
    var detail: MeshInstance3D=_details.get(detail_key) as MeshInstance3D
    if detail==null:
        var anchor: Node3D=(_scar._slots[surface] as Array)[slot]["root"] as Node3D
        if anchor==null:
            return
        detail=MeshInstance3D.new()
        detail.name=ACCENT_NAME
        detail.material_override=_mat()
        detail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        anchor.add_child(detail)
        _details[detail_key]=detail
    detail.mesh=_build_mesh(surface,attack,slot)
    detail.visible=true

func _on_clear() -> void:
    for detail in _details.values():
        (detail as MeshInstance3D).visible=false

func active_detail_slots() -> int:
    var active: int=0
    for detail in _details.values():
        var mesh: MeshInstance3D=detail as MeshInstance3D
        if mesh.visible and mesh.get_parent().visible:
            active+=1
    return active

func total_detail_slots() -> int:
    return _details.size()

func finish_stats(surface: String,attack: String,
        slot: int) -> Dictionary:
    if surface not in V14.SURFACES or attack not in V14.ATTACKS or \
            slot<0 or slot>=V14.MAX_PER_SURFACE:
        return {}
    return _build_mesh(surface,attack,slot).get_meta("tarvoka_v15_finish",{})
