extends RefCounted
class_name TarvokaAttackHelicopterDamageV13

# V13 Studio-only visual destruction. No gameplay HP/damage modifications.
# Original V1 animation rig, V12.1 cannon and mobile art-level <=10 remain.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V12=preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
const FLAG := "tarvoka_a01_damage_fx_v13"
const STAGE := "tarvoka_a01_damage_stage_v13"
const ROOT := "A01V13_DanoYDestruccion"
const IMPACT := "A01V13_ChispasImpacto"
const SCRATCH := "A01V13_ImpactosBala"
const BURN := "A01V13_BlindajeChamuscado"
const SMOKE := "A01V13_HumoMotor"
const FIRE := "A01V13_FuegoMotor"
const WRECK := "A01V13_RotorYEscombrosDesprendidos"
const MAX_STAGE := 4
const DESTROY_DURATION := 2.35
const STAGE_LABELS := ["Intacto","Daño leve","Daño moderado","Daño crítico","Destruido"]

static func _part(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _part(model,ROOT)!=null and _part(model,IMPACT)!=null
        and _part(model,SMOKE)!=null and _part(model,WRECK)!=null)

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _mat(color: Color,metal: float=0.16,
        rough: float=0.70,glow: bool=false) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    if color.a<0.99:
        m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    if glow:
        m.emission_enabled=true
        m.emission=color
        m.emission_energy_multiplier=1.6
    return m

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        color: Color,pos: Vector3=Vector3.ZERO,
        glow: bool=false) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.material_override=_mat(color,0.12,0.74,glow)
    n.position=pos
    parent.add_child(n)
    return n

static func _box(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,color: Color,rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var b:=BoxMesh.new()
    b.size=size
    var n:=_mesh(parent,name,b,color,pos)
    n.rotation_degrees=rotation
    return n

static func _sphere(parent: Node3D,name: String,
        pos: Vector3,diameter: Vector3,color: Color,glow: bool=false) -> MeshInstance3D:
    var b:=SphereMesh.new()
    b.radius=0.5
    b.height=1.0
    b.radial_segments=12
    b.rings=6
    var n:=_mesh(parent,name,b,color,pos,glow)
    n.scale=diameter
    return n

static func _rod(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,color: Color,glow: bool=false) -> MeshInstance3D:
    var axis: Vector3=b-a
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=axis.length()
    mesh.radial_segments=8
    var n:=_mesh(parent,name,mesh,color,(a+b)*0.5,glow)
    n.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return n

static func _bullets(body: Node3D) -> void:
    var layer:=_group(body,SCRATCH)
    var crater:=Color("#252c31")
    var exposed:=Color("#aab7be")
    for side in [-1,1]:
        var s: float=float(side)
        # Opaque burn indent + radial silver scratch outlines.
        _sphere(layer,"A01V13_ImpactoCasco_%d" % side,
            Vector3(s*0.62,1.07,-0.19),
            Vector3(0.025,0.108,0.132),crater)
        for i in range(3):
            var a: float=TAU*float(i)/3.0
            var y: float=1.07+sin(a)*0.050
            var z: float=-0.19+cos(a)*0.061
            _rod(layer,"A01V13_Rayadura_%d_%d" % [side,i],
                Vector3(s*0.637,y,z),
                Vector3(s*0.639,y+sin(a)*0.051,z+cos(a)*0.057),
                0.007,exposed)
    _sphere(layer,"A01V13_CicatrizMorro",
        Vector3(0.025,0.914,-1.627),
        Vector3(0.16,0.042,0.048),crater)

static func _burns(body: Node3D) -> void:
    var layer:=_group(body,BURN)
    var black:=Color("#292c2c")
    var soot:=Color("#383433")
    for side in [-1,1]:
        var s: float=float(side)
        # Contoured areas stay on the metal motor pod, never on the glass.
        _sphere(layer,"A01V13_QuemadoMotor_%d" % side,
            Vector3(s*0.51,1.545,0.73),
            Vector3(0.12,0.17,0.34),black)
        _sphere(layer,"A01V13_QuemadoAla_%d" % side,
            Vector3(s*0.88,0.835,-0.14),
            Vector3(0.37,0.035,0.26),soot)

static func _particles(body: Node3D) -> void:
    var smoke:=_group(body,SMOKE)
    for i in range(4):
        var t: float=float(i)
        var fog:=Color(0.19,0.23,0.26,0.37-t*0.045)
        _sphere(smoke,"A01V13_ColumnaHumo_%d" % i,
            Vector3(0.42+t*0.052,1.55+t*0.23,0.82+t*0.12),
            Vector3(0.22+t*0.08,0.24+t*0.07,0.22+t*0.09),fog)
    var fire:=_group(body,FIRE)
    for i in range(3):
        var tint:=Color("#ffb236") if i==0 else (
            Color("#f56a2e") if i==1 else Color("#c83718"))
        _sphere(fire,"A01V13_LlamaMotor_%d" % i,
            Vector3(0.45,1.54+float(i)*0.10,0.82),
            Vector3(0.11-float(i)*0.014,0.23,0.12),tint,true)
    var burst:=_group(body,IMPACT)
    _sphere(burst,"A01V13_NucleoDestelloImpacto",
        Vector3(-0.52,1.18,-0.28),Vector3(0.20,0.19,0.22),
        Color("#ffab32"),true)
    for i in range(6):
        var a: float=TAU*float(i)/6.0
        var from: Vector3=Vector3(-0.52,1.18,-0.28)
        var to: Vector3=from+Vector3(cos(a)*0.25,sin(a)*0.18,0.12)
        _rod(burst,"A01V13_Chispa_%d" % i,
            from,to,0.012,Color("#ffdf73"),true)

static func _wreck(body: Node3D) -> void:
    var debris:=_group(body,WRECK)
    var steel:=Color("#4d565a")
    var graphite:=Color("#252d32")
    # Broken rotor blades are rigid debris, not extra spinning V1 blades.
    for i in range(3):
        var blade:=_box(debris,"A01V13_FragmentoRotor_%d" % i,
            Vector3(-0.76+float(i)*0.42,0.50,0.12+float(i)*0.43),
            Vector3(0.12,0.040,0.85-float(i)*0.18),graphite,
            Vector3(-16+float(i)*15,27+float(i)*31,24-float(i)*17))
        blade.set_meta("a01_v13_rest",blade.position)
        blade.set_meta("a01_v13_rot",blade.rotation_degrees)
    for side in [-1,1]:
        var s: float=float(side)
        var piece:=_box(debris,"A01V13_FragmentoBlindaje_%d" % side,
            Vector3(s*0.91,0.49,-0.53),
            Vector3(0.35,0.035,0.33),steel,
            Vector3(0,s*23.0,s*37.0))
        piece.set_meta("a01_v13_rest",piece.position)
        piece.set_meta("a01_v13_rot",piece.rotation_degrees)
    _sphere(debris,"A01V13_CarbonizacionFinal",
        Vector3(0,1.53,0.42),Vector3(0.54,0.085,0.60),Color("#1b2429"))

static func stage(model: Node3D) -> int:
    if not has_model(model):
        return 0
    return clampi(int(model.get_meta(STAGE,0)),0,MAX_STAGE)

static func set_stage(model: Node3D,level: int) -> bool:
    if not has_model(model):
        return false
    var n: int=clampi(level,0,MAX_STAGE)
    model.set_meta(STAGE,n)
    _part(model,SCRATCH).visible=n>=1
    _part(model,BURN).visible=n>=2
    _part(model,SMOKE).visible=n>=2
    _part(model,FIRE).visible=n>=3
    _part(model,WRECK).visible=n>=4
    _part(model,IMPACT).visible=false
    # Hide the entire original main rotor assembly only in the destroyed
    # state. It is never modified or deleted; stage zero restores it.
    var main: Node3D=_part(model,V1.MAIN_ROTOR)
    if main!=null:
        main.visible=n<4
    var tail: Node3D=_part(model,V1.TAIL_ROTOR)
    if tail!=null:
        tail.visible=n<4
    return true

static func _animate_fx(model: Node3D,kind: String,t: float) -> void:
    var burst: Node3D=_part(model,IMPACT)
    var fire: Node3D=_part(model,FIRE)
    var smoke: Node3D=_part(model,SMOKE)
    var wreck: Node3D=_part(model,WRECK)
    var n: int=stage(model)
    burst.visible=kind in ["hit_bullet","hit_explosive","destroy"] and t>=0.16 and t<0.44
    burst.scale=Vector3.ONE*(0.70+0.40*sin(PI*t))
    smoke.visible=n>=2 or (kind=="destroy" and t>0.20)
    smoke.position.y=0.045*sin(TAU*t) if kind=="destroy" else 0.0
    fire.visible=n>=3 or (kind=="destroy" and t>0.29)
    fire.scale=Vector3.ONE*(0.94+0.12*sin(TAU*t*3.0))
    if kind=="destroy":
        for child in wreck.get_children():
            var piece: MeshInstance3D=child as MeshInstance3D
            if piece!=null and piece.has_meta("a01_v13_rest"):
                var rest: Vector3=piece.get_meta("a01_v13_rest") as Vector3
                var angle: Vector3=piece.get_meta("a01_v13_rot") as Vector3
                piece.position=rest+Vector3(rest.x*0.38*t,-0.14*t*t,rest.z*0.23*t)
                piece.rotation_degrees=angle+Vector3(32*t,49*t,23*t)
    else:
        for child in wreck.get_children():
            var piece: MeshInstance3D=child as MeshInstance3D
            if piece!=null and piece.has_meta("a01_v13_rest"):
                piece.position=piece.get_meta("a01_v13_rest") as Vector3
                piece.rotation_degrees=piece.get_meta("a01_v13_rot") as Vector3

static func pose(model: Node3D,kind: String,progress: float) -> bool:
    if not has_model(model):
        return false
    var t: float=clampf(progress,0.0,1.0)
    if kind=="destroy":
        if not V1.pose(model,"hit_explosive",t):
            return false
        # Destruction is preview-only: full visible fall + violent bank.
        model.rotation_degrees.z+=70.0*t*t*(3.0-2.0*t)
        model.rotation_degrees.x-=13.0*sin(PI*t)
        model.position.y-=0.47*t*t
        _part(model,WRECK).visible=true
    elif not V1.pose(model,kind,t):
        return false
    _animate_fx(model,kind,t)
    return true

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    V1.restore(model)
    _animate_fx(model,"idle",0.0)

static func apply(model: Node3D,_faction: Color) -> bool:
    if not V12.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_part(model,V1.ROOT)
    if body==null or _part(model,V1.MAIN_ROTOR)==null:
        return false
    var root_node:=_group(body,ROOT)
    _bullets(root_node)
    _burns(root_node)
    _particles(root_node)
    _wreck(root_node)
    model.set_meta(FLAG,true)
    return set_stage(model,0)
