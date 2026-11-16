extends RefCounted
class_name TarvokaAPCTireFinishV23

# Bastion P06 V23: completes ALL SIX actual wheel meshes.
# The V2 carcass stays; sparse 48-block tread is replaced by 160 closed,
# curved interleaved chevron grips PER WHEEL in ONE batched ArrayMesh.
# 2 complete sidewalls, 4 circular raised beads, 48 sidewall embossings,
# and reversible rain/snow/worn-tire meshes. Existing V14 spokes, hubs,
# steering pivots, brakes, 6x6 suspension and stats are never reparented.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V14=preload("res://scripts/ui/APCWheelV14.gd")
const V22=preload("res://scripts/ui/APCWeatherFinishV22.gd")
const FLAG := "tarvoka_apc_complete_tires_v23"
const ROOT := "P06V23_NeumaticosCompletos"
const TREAD := "P06V23_BandaContinua160Tacos"
const SHOULDER := "P06V23_FlancosYTalones"
const SNOW := "P06V23_NieveSobreHombros"
const WET := "P06V23_GotasYLaminaHumeda"
const SCAR := "P06V23_CorteLateral"
const ORIGINAL := "tarvoka_p06_v23_original_carcase"
const BASE_MAT := "tarvoka_p06_v23_tread_original"
const SHOW := "tarvoka_apc_v23_visible"
const STAGE := "tarvoka_apc_v23_stage"
const WEATHER := "tarvoka_apc_v23_weather"
const SEGMENTS := 40
const ROWS := 4
const LUG_COUNT := SEGMENTS*ROWS
const SIDEWALL_RIBS := 24
const OUTER_RADIUS := 0.360
const INNER_RADIUS := 0.347
const MIN_GUARD_CLEARANCE := 0.414-OUTER_RADIUS

static func _material(color: Color,metal: float,rough: float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _group(parent: Node3D,name: String) -> Node3D:
    var group:=Node3D.new()
    group.name=name
    parent.add_child(group)
    return group

static func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        tool.add_vertex(vertex)

static func _point(x: float,radial: float,angle: float) -> Vector3:
    return Vector3(x,radial*sin(angle),radial*cos(angle))

static func _closed_block(tool: SurfaceTool,
        x0: float,x1: float,
        a0: float,a1: float,
        b0: float,b1: float) -> void:
    # Eight corner solid, not a flat tread decal. Different angles at the
    # x ends make a diagonal chevron. All six faces are present.
    var p: Array[Vector3]=[
        _point(x0,INNER_RADIUS,a0),_point(x1,INNER_RADIUS,b0),
        _point(x1,INNER_RADIUS,b1),_point(x0,INNER_RADIUS,a1),
        _point(x0,OUTER_RADIUS,a0),_point(x1,OUTER_RADIUS,b0),
        _point(x1,OUTER_RADIUS,b1),_point(x0,OUTER_RADIUS,a1)]
    _quad(tool,p[4],p[5],p[6],p[7])
    _quad(tool,p[3],p[2],p[1],p[0])
    for edge in range(4):
        var nxt: int=(edge+1)%4
        _quad(tool,p[edge],p[nxt],p[nxt+4],p[edge+4])

static func _tread_mesh() -> ArrayMesh:
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var span: float=TAU/float(SEGMENTS)
    var centers: Array[float]=[-0.080,-0.027,0.027,0.080]
    for row in range(ROWS):
        var x: float=centers[row]
        var slant: float=-0.022 if row<2 else 0.022
        for sector in range(SEGMENTS):
            var angle: float=span*(float(sector)+(
                0.45 if row in [1,2] else 0.0))
            var half: float=span*0.435
            _closed_block(tool,
                x-0.024,x+0.024,
                angle-half-slant,angle+half-slant,
                angle-half+slant,angle+half+slant)
    tool.generate_normals()
    return tool.commit()

static func _rib_mesh(side: int) -> ArrayMesh:
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var x0: float=float(side)*0.116
    var x1: float=float(side)*0.131
    for n in range(SIDEWALL_RIBS):
        var angle: float=TAU*float(n)/float(SIDEWALL_RIBS)
        var v: Array[Vector3]=[
            _point(x0,0.312,angle-0.043),
            _point(x0,0.330,angle-0.043),
            _point(x0,0.330,angle+0.043),
            _point(x0,0.312,angle+0.043),
            _point(x1,0.312,angle-0.043),
            _point(x1,0.330,angle-0.043),
            _point(x1,0.330,angle+0.043),
            _point(x1,0.312,angle+0.043)]
        _quad(tool,v[4],v[5],v[6],v[7])
        _quad(tool,v[3],v[2],v[1],v[0])
        for edge in range(4):
            var nxt: int=(edge+1)%4
            _quad(tool,v[edge],v[nxt],v[nxt+4],v[edge+4])
    tool.generate_normals()
    return tool.commit()

static func _torus(parent: Node3D,name: String,
        x: float,inner: float,outer: float,
        material: Material) -> void:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=36
    mesh.ring_segments=12
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=mesh
    node.material_override=material
    node.position=Vector3(x,0,0)
    node.rotation_degrees.z=90
    parent.add_child(node)

static func _weather_mesh(snow: bool) -> ArrayMesh:
    # Two upper shoulders, well inside the V18 static wheelwell radius.
    # Curved 3D pieces, no screen-space simulated patches.
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1,1]:
        var x: float=float(side)*0.100
        for i in range(11):
            var a: float=deg_to_rad(47.0+float(i)*7.2)
            var b: float=a+deg_to_rad(5.5)
            var radius0: float=0.3605
            var radius1: float=0.362 if snow else 0.3616
            var z0: float=x-0.009
            var z1: float=x+0.009
            var p: Array[Vector3]=[
                _point(z0,radius0,a),_point(z1,radius0,a),
                _point(z1,radius0,b),_point(z0,radius0,b),
                _point(z0,radius1,a),_point(z1,radius1,a),
                _point(z1,radius1,b),_point(z0,radius1,b)]
            _quad(tool,p[4],p[5],p[6],p[7])
            for edge in range(4):
                var nxt: int=(edge+1)%4
                _quad(tool,p[edge],p[nxt],p[nxt+4],p[edge+4])
    tool.generate_normals()
    return tool.commit()

static func _mesh(parent: Node3D,name: String,
        shape: Mesh,material: Material) -> MeshInstance3D:
    var piece:=MeshInstance3D.new()
    piece.name=name
    piece.mesh=shape
    piece.material_override=material
    parent.add_child(piece)
    return piece

static func _tire(parent: Node3D,side: int,axle: int,
        tread_mesh: ArrayMesh,rubber: Material,
        snow_mesh: ArrayMesh,wet_mesh: ArrayMesh) -> bool:
    var wheel: Node3D=parent.find_child(
        "RuedaMotorizadaP06_%d_%d" % [side,axle],true,false) as Node3D
    if wheel==null:
        return false
    var carcass: MeshInstance3D=wheel.find_child(
        "NeumaticoTodoTerreno",false,false) as MeshInstance3D
    var old_lugs: MultiMeshInstance3D=wheel.find_child(
        "APC_V2_TacosTodoTerreno",true,false) as MultiMeshInstance3D
    if carcass==null or old_lugs==null:
        return false
    # Keep original V2 carcass curvature and old geometry for historic view.
    old_lugs.visible=false
    var root_node: Node3D=_group(wheel,ROOT)
    var tread: MeshInstance3D=_mesh(root_node,TREAD,tread_mesh,rubber)
    tread.set_meta(BASE_MAT,rubber)
    var flanks: Node3D=_group(root_node,SHOULDER)
    var seam: Material=_material(Color("#1c2022"),0.02,0.94)
    for direction in [-1,1]:
        var s: float=float(direction)
        _torus(flanks,"P06V23_AnilloHombro_%d" % direction,
            s*0.118,0.331,0.344,seam)
        _torus(flanks,"P06V23_AnilloCostado_%d" % direction,
            s*0.121,0.235,0.245,seam)
        _mesh(flanks,"P06V23_NerviosFlanco_%d" % direction,
            _rib_mesh(direction),rubber)
    var snow: MeshInstance3D=_mesh(root_node,SNOW,
        snow_mesh,_material(Color("#d4dde5"),0.0,0.99))
    snow.visible=false
    var wet: MeshInstance3D=_mesh(root_node,WET,
        wet_mesh,_material(Color("#52636d"),0.10,0.27))
    wet.visible=false
    var scar: Node3D=_group(root_node,SCAR)
    scar.visible=false
    if side==-1 and axle==0:
        # Real dark volume at the same front-left sidewall where V14 shows
        # exposed cords in critical damage; visible only while tire is torn.
        var damage:=BoxMesh.new()
        damage.size=Vector3(0.021,0.060,0.047)
        var cut: MeshInstance3D=_mesh(scar,
            "P06V23_GomaDesgarrada",damage,
            _material(Color("#171919"),0.01,0.99))
        cut.position=Vector3(-0.132,0.238,-0.176)
    root_node.set_meta("tarvoka_p06_v23_side",side)
    root_node.set_meta("tarvoka_p06_v23_axle",axle)
    return true

static func _material_state(root_node: Node3D,
        weather: String,stage: int) -> void:
    var tread: MeshInstance3D=root_node.find_child(
        TREAD,false,false) as MeshInstance3D
    if tread!=null:
        var source: StandardMaterial3D=tread.get_meta(
            BASE_MAT) as StandardMaterial3D
        if source!=null:
            var mat: StandardMaterial3D=source
            if weather!="clear":
                mat=source.duplicate() as StandardMaterial3D
                if weather=="rain":
                    mat.roughness=0.70
                    mat.albedo_color=source.albedo_color.darkened(0.08)
                else:
                    mat.roughness=0.98
                    mat.albedo_color=source.albedo_color.lerp(
                        Color("#87939a"),0.10)
            tread.material_override=mat
    var snow: Node3D=root_node.find_child(SNOW,false,false) as Node3D
    var wet: Node3D=root_node.find_child(WET,false,false) as Node3D
    if snow!=null:
        snow.visible=weather=="snow" and stage<4
    if wet!=null:
        wet.visible=weather=="rain" and stage<4
    var scar: Node3D=root_node.find_child(SCAR,false,false) as Node3D
    if scar!=null:
        scar.visible=(int(root_node.get_meta("tarvoka_p06_v23_side",0))==-1
            and int(root_node.get_meta("tarvoka_p06_v23_axle",-1))==0
            and stage>=3)

static func apply(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(V22.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var tire_mesh: ArrayMesh=_tread_mesh()
    var snow_mesh: ArrayMesh=_weather_mesh(true)
    var wet_mesh: ArrayMesh=_weather_mesh(false)
    var rubber: StandardMaterial3D=_material(
        Color("#252a2c"),0.018,0.96)
    for side in [-1,1]:
        for axle in range(3):
            if not _tire(model,side,axle,tire_mesh,rubber,
                    snow_mesh,wet_mesh):
                return false
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    model.set_meta(WEATHER,"clear")
    model.set_meta("tarvoka_p06_v23_lugs_per_wheel",LUG_COUNT)
    set_stage(model,0)
    return true

static func _refresh(model: Node3D) -> void:
    var shown: bool=bool(model.get_meta(SHOW,true))
    var weather: String=str(model.get_meta(WEATHER,"clear"))
    var stage: int=int(model.get_meta(STAGE,0))
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],true,false) as Node3D
            if wheel==null:
                continue
            var root_node: Node3D=wheel.find_child(
                ROOT,false,false) as Node3D
            var old_lugs: Node3D=wheel.find_child(
                "APC_V2_TacosTodoTerreno",true,false) as Node3D
            if root_node!=null:
                root_node.visible=shown
                _material_state(root_node,weather,stage)
            if old_lugs!=null:
                old_lugs.visible=not shown

static func set_weather(model: Node3D,weather: String) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not weather in V22.WEATHERS:
        return false
    model.set_meta(WEATHER,weather)
    _refresh(model)
    return true

static func set_stage(model: Node3D,stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(STAGE,clampi(stage,0,4))
    _refresh(model)
    return true

static func set_enabled(model: Node3D,shown: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,shown)
    _refresh(model)
    return true
