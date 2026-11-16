extends RefCounted
class_name TarvokaAttackHelicopterEnginesV4

# A01 V4: replace rectangular V1/V2 engine and side armor with truly shaped
# enclosed 3D panels. Studio-only, preserving V1 rotor/weapon animation pivots.
const V1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2 = preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V3 = preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const FLAG := "tarvoka_a01_engines_armor_v4"
const ENABLED := "tarvoka_a01_v4_enabled"
const ROOT := "A01V4_MotoresYBlindajeLateral"
const NACELLE := "A01V4_MotorCarenado_"
const INTAKE := "A01V4_TomaAireAnular_"
const SIDE_PANEL := "A01V4_BlindajeLateral_"
const FACTION_STRIPE := "A01V4_InsigniaFaccion_"
const TRANSMISSION := "A01V4_CajaTransmisionEsculpida"
const SIDES := 16
const ORIGINAL_ENGINE := [
    "A01_RejillaAdmisión_", "A01_ProteccionMotor_", "A01_Escape_",
    "A01_PanelFaccion_", "A01_V2_ProteccionHombro_",
    "A01_V2_TapaMantenimiento_"
]
const ORIGINAL_TOP := [
    "A01_V2_TapaSuperiorTransmision",
    "A01_V2_JuntaTapaSuperior",
    "A01_V2_BandaIdentificacionSuperior"
]

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false) != null)

static func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _group(parent: Node3D,name: String) -> Node3D:
    var n := Node3D.new()
    n.name = name
    parent.add_child(n)
    return n

static func _mat(color: Color,metal: float=0.27,rough: float=0.58) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _mesh(parent: Node3D,name: String,geometry: Mesh,color: Color,
        pos: Vector3=Vector3.ZERO,rot: Vector3=Vector3.ZERO,
        metal: float=0.27,rough: float=0.58) -> MeshInstance3D:
    var m:=MeshInstance3D.new()
    m.name=name
    m.mesh=geometry
    m.position=pos
    m.rotation_degrees=rot
    m.material_override=_mat(color,metal,rough)
    parent.add_child(m)
    return m

static func _box(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,color: Color,rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var b:=BoxMesh.new()
    b.size=size
    return _mesh(parent,name,b,color,pos,rot)

static func _sphere(parent: Node3D,name: String,pos: Vector3,
        scale: Vector3,color: Color) -> MeshInstance3D:
    var s:=SphereMesh.new()
    s.radius=0.5
    s.height=1.0
    s.radial_segments=12
    s.rings=6
    var n:=_mesh(parent,name,s,color,pos)
    n.scale=scale
    return n

static func _cylinder(parent: Node3D,name: String,pos: Vector3,
        radius: float,length: float,color: Color,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var c:=CylinderMesh.new()
    c.top_radius=radius
    c.bottom_radius=radius
    c.height=length
    c.radial_segments=16
    return _mesh(parent,name,c,color,pos,rot)

static func _tri(s: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    s.add_vertex(a)
    s.add_vertex(b)
    s.add_vertex(c)

static func _station(s: Vector4,index: int) -> Vector3:
    var angle: float=TAU*float(index%SIDES)/float(SIDES)
    # Forward is -Z, so X and Y are oval radii; Vector4=(Z,Y,width,height).
    return Vector3(cos(angle)*s.z,s.y+sin(angle)*s.w,s.x)

static func _closed_shell(stations: Array[Vector4]) -> ArrayMesh:
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(stations.size()-1):
        for n in range(SIDES):
            var a: Vector3=_station(stations[i],n)
            var b: Vector3=_station(stations[i],n+1)
            var c: Vector3=_station(stations[i+1],n+1)
            var d: Vector3=_station(stations[i+1],n)
            _tri(tool,a,b,c)
            _tri(tool,a,c,d)
    var first: Vector4=stations[0]
    var last: Vector4=stations[stations.size()-1]
    for n in range(SIDES):
        _tri(tool,Vector3(0,first.y,first.x),
            _station(first,n+1),_station(first,n))
        _tri(tool,Vector3(0,last.y,last.x),
            _station(last,n),_station(last,n+1))
    tool.generate_normals()
    return tool.commit()

static func _panel_solid(points: Array[Vector2],thick: float) -> ArrayMesh:
    # Polygon in YZ extruded along X, both caps closed. (Y,Z) points.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center:=Vector2.ZERO
    for v in points:
        center+=v
    center/=float(points.size())
    for i in range(points.size()):
        var a: Vector2=points[i]
        var b: Vector2=points[(i+1)%points.size()]
        var frontcenter:=Vector3(thick*0.5,center.x,center.y)
        var front_a:=Vector3(thick*0.5,a.x,a.y)
        var front_b:=Vector3(thick*0.5,b.x,b.y)
        var backcenter:=Vector3(-thick*0.5,center.x,center.y)
        var back_a:=Vector3(-thick*0.5,a.x,a.y)
        var back_b:=Vector3(-thick*0.5,b.x,b.y)
        _tri(st,frontcenter,front_a,front_b)
        _tri(st,backcenter,back_b,back_a)
        _tri(st,front_a,back_a,back_b)
        _tri(st,front_a,back_b,front_b)
    st.generate_normals()
    return st.commit()

static func _intake_mesh(outer_w: float,outer_h: float,
        inner_w: float,inner_h: float) -> ArrayMesh:
    # Physical dark well: annular mouth + recessed inner wall, no fake decal.
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for n in range(SIDES):
        var a: float=TAU*float(n)/float(SIDES)
        var b: float=TAU*float(n+1)/float(SIDES)
        var oa:=Vector3(outer_w*cos(a),outer_h*sin(a),0)
        var ob:=Vector3(outer_w*cos(b),outer_h*sin(b),0)
        var ia:=Vector3(inner_w*cos(a),inner_h*sin(a),-0.009)
        var ib:=Vector3(inner_w*cos(b),inner_h*sin(b),-0.009)
        var deep_a:=Vector3(inner_w*cos(a),inner_h*sin(a),0.085)
        var deep_b:=Vector3(inner_w*cos(b),inner_h*sin(b),0.085)
        _tri(tool,oa,ob,ib)
        _tri(tool,oa,ib,ia)
        _tri(tool,ia,ib,deep_b)
        _tri(tool,ia,deep_b,deep_a)
    tool.generate_normals()
    return tool.commit()

static func _strut(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> void:
    var axis: Vector3=b-a
    if axis.length_squared()<0.0001:
        return
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=axis.length()
    cylinder.radial_segments=8
    var part:=_mesh(parent,name,cylinder,color,(a+b)*0.5)
    part.quaternion=Quaternion(Vector3.UP,axis.normalized())

static func _engine(parent: Node3D,side: int,color: Color) -> void:
    var sign: float=float(side)
    var center:=Vector3(sign*0.335,0,0)
    var steel:=Color("#66747c")
    var dark:=Color("#27343b")
    var silver:=Color("#a1afb5")
    var inset:=Color("#121b20")
    var engine:=_group(parent,"A01V4_MotorConjunto_"+str(side))
    var stations: Array[Vector4]=[
        Vector4(0.12,1.59,0.112,0.090),
        Vector4(0.19,1.60,0.205,0.158),
        Vector4(0.40,1.625,0.252,0.216),
        Vector4(0.76,1.64,0.274,0.224),
        Vector4(1.03,1.625,0.244,0.194),
        Vector4(1.24,1.595,0.152,0.131)
    ]
    _mesh(engine,NACELLE+str(side),_closed_shell(stations),steel,center)
    _mesh(engine,INTAKE+str(side),_intake_mesh(
        0.116,0.096,0.078,0.058),silver,
        Vector3(sign*0.335,1.59,0.105))
    _sphere(engine,"A01V4_FondoTomaAire_"+str(side),
        Vector3(sign*0.335,1.59,0.187),
        Vector3(0.16,0.13,0.028),inset)
    for n in range(3):
        var y: float=1.54+float(n)*0.043
        _box(engine,"A01V4_AletaAdmision_%d_%d" % [side,n],
            Vector3(sign*0.335,y,0.116),
            Vector3(0.132,0.012,0.02),dark)
    # Rear outlet is a real 3D dual-shell nozzle with visible inner throat.
    var exhaust:=_group(engine,"A01V4_ToberaEscape_"+str(side))
    exhaust.position=Vector3(sign*0.44,1.57,1.21)
    _cylinder(exhaust,"A01V4_BordeMetalEscape_"+str(side),
        Vector3.ZERO,0.143,0.14,silver,Vector3(90,0,0))
    _cylinder(exhaust,"A01V4_InteriorEscape_"+str(side),
        Vector3(0,0,0.086),0.110,0.060,inset,Vector3(90,0,0))
    _cylinder(exhaust,"A01V4_CentroEscape_"+str(side),
        Vector3(0,0,0.116),0.072,0.022,dark,Vector3(90,0,0))
    # Louver row follows an inclined engine skin; it is not a flat block.
    for n in range(5):
        var z: float=0.47+0.104*float(n)
        var lift: float=0.032*sin(PI*float(n)/4.0)
        _box(engine,"A01V4_RejillaCurva_%d_%d" % [side,n],
            Vector3(sign*0.568,1.69+lift,z),
            Vector3(0.035,0.032,0.078),dark,
            Vector3(0,sign*11.0,-sign*15.0))
    # Thin factory paint, not a saturated box over the whole engine.
    _box(engine,"A01V4_InsigniaMotor_"+str(side),
        Vector3(sign*0.338,1.859,0.68),
        Vector3(0.082,0.012,0.30),color)
    for n in range(3):
        var z: float=0.50+float(n)*0.20
        _sphere(engine,"A01V4_PernoMotor_%d_%d" % [side,n],
            Vector3(sign*0.580,1.585,z),
            Vector3(0.028,0.028,0.028),silver)

static func _armor(parent: Node3D,side: int,color: Color) -> void:
    var sign: float=float(side)
    var steel:=Color("#697880")
    var trim:=Color("#a8b3b7")
    var dark:=Color("#29343b")
    var armor:=_group(parent,"A01V4_PanelCostadoConjunto_"+str(side))
    var plate: Array[Vector2]=[
        Vector2(1.02,-0.075),
        Vector2(1.18,-0.125),
        Vector2(1.30,0.06),
        Vector2(1.28,0.44),
        Vector2(1.11,0.76),
        Vector2(0.98,0.63)
    ]
    _mesh(armor,SIDE_PANEL+str(side),
        _panel_solid(plate,0.040),steel,
        Vector3(sign*0.633,0,0))
    var emblem: Array[Vector2]=[
        Vector2(1.200,0.150),
        Vector2(1.252,0.215),
        Vector2(1.245,0.355),
        Vector2(1.193,0.294)
    ]
    _mesh(armor,FACTION_STRIPE+str(side),
        _panel_solid(emblem,0.015),color,
        Vector3(sign*0.666,0,0))
    _strut(armor,"A01V4_BiselFrontalPanel_"+str(side),
        Vector3(sign*0.668,1.02,-0.075),
        Vector3(sign*0.668,1.18,-0.125),0.015,dark)
    _strut(armor,"A01V4_BiselPosteriorPanel_"+str(side),
        Vector3(sign*0.668,1.28,0.44),
        Vector3(sign*0.668,1.11,0.76),0.014,dark)
    for n in range(4):
        var z: float=0.06+0.15*float(n)
        _sphere(armor,"A01V4_RemonteRemache_%d_%d" % [side,n],
            Vector3(sign*0.663,1.085,z),
            Vector3(0.027,0.027,0.027),trim)
    _box(armor,"A01V4_TapaTrampilla_"+str(side),
        Vector3(sign*0.675,1.09,0.47),
        Vector3(0.029,0.090,0.145),dark,
        Vector3(0,-sign*6.0,0))
    _box(armor,"A01V4_ManetaTrampilla_"+str(side),
        Vector3(sign*0.691,1.10,0.47),
        Vector3(0.020,0.019,0.08),trim)
    # Matching narrow vents in the aft flank, integrated behind the armor.
    for n in range(3):
        _box(armor,"A01V4_RespiraderoCostado_%d_%d" % [side,n],
            Vector3(sign*0.580,1.39,0.73+float(n)*0.085),
            Vector3(0.023,0.045,0.065),dark,
            Vector3(0,sign*9.0,0))

static func _gearbox(parent: Node3D,color: Color) -> void:
    var metal:=Color("#6a7981")
    var gunmetal:=Color("#303c43")
    var fairing: Array[Vector4]=[
        Vector4(0.18,1.69,0.16,0.09),
        Vector4(0.31,1.69,0.27,0.13),
        Vector4(0.70,1.69,0.32,0.13),
        Vector4(0.91,1.69,0.21,0.10)
    ]
    _mesh(parent,TRANSMISSION,_closed_shell(fairing),metal)
    for n in range(3):
        var z: float=0.42+0.13*float(n)
        _box(parent,"A01V4_LaminillaCajaCambio_"+str(n),
            Vector3(0,1.817,z),
            Vector3(0.47,0.012,0.022),gunmetal)
    _box(parent,"A01V4_MarcaCajaCambios",
        Vector3(0,1.826,0.68),Vector3(0.105,0.012,0.09),color)

static func _hide_legacy(model: Node3D,enabled: bool) -> bool:
    # Preserve V1/V2 for exact reversible visual comparison.
    for side in [-1,1]:
        for prefix in ORIGINAL_ENGINE:
            var component: Node3D=_find(model,prefix+str(side))
            if component==null:
                return false
            component.visible=not enabled
        for n in range(3):
            var vent: Node3D=_find(model,
                "A01_V2_RejillaMotor_%d_%d" % [side,n])
            if vent==null:
                return false
            vent.visible=not enabled
    for name in ORIGINAL_TOP:
        var roof: Node3D=_find(model,name)
        if roof==null:
            return false
        roof.visible=not enabled
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    if not _hide_legacy(model,enabled):
        return false
    var v4: Node3D=_find(model,ROOT)
    v4.visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,color: Color) -> bool:
    if not V3.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_find(model,V1.ROOT)
    if body==null:
        return false
    # No hide/modify until we can prove all old geometry is present.
    for side in [-1,1]:
        for prefix in ORIGINAL_ENGINE:
            if _find(model,prefix+str(side))==null:
                return false
        for n in range(3):
            if _find(model,"A01_V2_RejillaMotor_%d_%d" % [side,n])==null:
                return false
    for name in ORIGINAL_TOP:
        if _find(model,name)==null:
            return false
    var layer:=_group(body,ROOT)
    for side in [-1,1]:
        _engine(layer,side,color)
        _armor(layer,side,color)
    _gearbox(layer,color)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
