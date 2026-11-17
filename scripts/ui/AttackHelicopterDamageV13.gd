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

# Close a five-vertex irregular rotor cross-section into a genuine solid,
# rather than leaving featureless rectangular shards after destruction.
static func _blade_fragment(length: float) -> ArrayMesh:
    var outline: Array[Vector2]=[
        Vector2(-0.064,-0.50*length),
        Vector2(0.064,-0.50*length),
        Vector2(0.053,0.16*length),
        Vector2(0.006,0.50*length),
        Vector2(-0.060,0.34*length)]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(1,outline.size()-1):
        for index in [0,j,j+1]:
            var p: Vector2=outline[index]
            st.add_vertex(Vector3(p.x,0.022,p.y))
        for index in [0,j+1,j]:
            var p: Vector2=outline[index]
            st.add_vertex(Vector3(p.x,-0.022,p.y))
    for j in range(outline.size()):
        var k: int=(j+1)%outline.size()
        var a: Vector2=outline[j]
        var b: Vector2=outline[k]
        var tl:=Vector3(a.x,0.022,a.y)
        var tr:=Vector3(b.x,0.022,b.y)
        var bl:=Vector3(a.x,-0.022,a.y)
        var br:=Vector3(b.x,-0.022,b.y)
        for point in [tl,bl,br,tl,br,tr]:
            st.add_vertex(point)
    st.generate_normals()
    return st.commit()

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
        var puff:=_sphere(smoke,"A01V13_ColumnaHumo_%d" % i,
            Vector3(0.42+t*0.052,1.55+t*0.23,0.82+t*0.12),
            Vector3(0.22+t*0.08,0.24+t*0.07,0.22+t*0.09),fog)
        puff.set_meta("a01_v13_fx_rest",puff.position)
        puff.set_meta("a01_v13_fx_scale",puff.scale)
    var fire:=_group(body,FIRE)
    for i in range(3):
        var tint:=Color("#ffb236") if i==0 else (
            Color("#f56a2e") if i==1 else Color("#c83718"))
        var flame:=_sphere(fire,"A01V13_LlamaMotor_%d" % i,
            Vector3(0.45,1.54+float(i)*0.10,0.82),
            Vector3(0.11-float(i)*0.014,0.23,0.12),tint,true)
        flame.set_meta("a01_v13_fx_rest",flame.position)
        flame.set_meta("a01_v13_fx_scale",flame.scale)
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
    var shock:=TorusMesh.new()
    shock.inner_radius=0.125
    shock.outer_radius=0.159
    shock.rings=8
    shock.ring_segments=28
    var wave:=_mesh(burst,"A01V13_OndaChoqueLateral",shock,
        Color("#ffd68c"),Vector3(-0.54,1.18,-0.28),true)
    wave.rotation_degrees.z=90.0

static func _wreck(body: Node3D) -> void:
    var debris:=_group(body,WRECK)
    var steel:=Color("#4d565a")
    var graphite:=Color("#252d32")
    # Jagged solid blade fragments launch from the actual V1 hub at
    # (0,1.97,0.08), then settle onto separated positions by the skids.
    for i in range(3):
        var a: float=TAU*float(i)/3.0
        var blade:=_mesh(debris,"A01V13_FragmentoRotor_%d" % i,
            _blade_fragment(0.86-float(i)*0.17),graphite,
            Vector3(-0.76+float(i)*0.42,0.50,0.12+float(i)*0.43))
        blade.rotation_degrees=Vector3(
            -16.0+float(i)*15.0,27.0+float(i)*31.0,
            24.0-float(i)*17.0)
        blade.set_meta("a01_v13_launch",
            Vector3(cos(a)*0.43,1.97,sin(a)*0.43+0.08))
        blade.set_meta("a01_v13_rest",blade.position)
        blade.set_meta("a01_v13_rot",blade.rotation_degrees)
    # V1's tail rotor is also hidden at the final crash stage. A smaller,
    # actual torn-off blade now accounts for its missing silhouette.
    var tail_piece:=_mesh(debris,"A01V13_FragmentoRotorCola",
        _blade_fragment(0.32),graphite,Vector3(1.12,0.47,2.02))
    tail_piece.rotation_degrees=Vector3(35.0,71.0,-22.0)
    tail_piece.set_meta("a01_v13_launch",Vector3(0.285,1.38,2.62))
    tail_piece.set_meta("a01_v13_rest",tail_piece.position)
    tail_piece.set_meta("a01_v13_rot",tail_piece.rotation_degrees)
    for side in [-1,1]:
        var s: float=float(side)
        var piece:=_box(debris,"A01V13_FragmentoBlindaje_%d" % side,
            Vector3(s*0.91,0.49,-0.53),
            Vector3(0.35,0.035,0.33),steel,
            Vector3(0,s*23.0,s*37.0))
        piece.set_meta("a01_v13_launch",Vector3(s*0.59,1.06,-0.16))
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
    animate_ambient(model,0.0)
    # Hide the entire original main rotor assembly only in the destroyed
    # state. It is never modified or deleted; stage zero restores it.
    var main: Node3D=_part(model,V1.MAIN_ROTOR)
    if main!=null:
        main.visible=n<4
    var tail: Node3D=_part(model,V1.TAIL_ROTOR)
    if tail!=null:
        tail.visible=n<4
    return true

# Ambient smoke/fire has its own clock and NEVER touches the original
# helicopter pose, so the particles continue after an impact animation ends.
# Oscillating local meshes avoid spawning particles on Android/WebGL.
static func animate_ambient(model: Node3D,seconds: float) -> bool:
    if not has_model(model):
        return false
    var clock: float=maxf(0.0,seconds)
    var smoke: Node3D=_part(model,SMOKE)
    var fire: Node3D=_part(model,FIRE)
    for i in range(smoke.get_child_count()):
        var puff: MeshInstance3D=smoke.get_child(i) as MeshInstance3D
        if puff==null or not puff.has_meta("a01_v13_fx_rest"):
            continue
        var base_pos: Vector3=puff.get_meta("a01_v13_fx_rest") as Vector3
        var base_size: Vector3=puff.get_meta("a01_v13_fx_scale") as Vector3
        var phase: float=fposmod(clock*0.43+float(i)*0.21,1.0)
        puff.position=base_pos+Vector3(
            0.055*sin(clock*0.9+float(i)),phase*0.19,
            0.045*sin(clock*0.75+float(i)*1.3))
        puff.scale=base_size*(0.88+phase*0.28)
    for i in range(fire.get_child_count()):
        var flame: MeshInstance3D=fire.get_child(i) as MeshInstance3D
        if flame==null or not flame.has_meta("a01_v13_fx_rest"):
            continue
        var start: Vector3=flame.get_meta("a01_v13_fx_rest") as Vector3
        var shape: Vector3=flame.get_meta("a01_v13_fx_scale") as Vector3
        flame.position=start+Vector3(
            0.012*sin(clock*5.1+float(i)*1.4),
            0.024*sin(clock*4.3+float(i)),0.0)
        flame.scale=shape*Vector3(
            0.92+0.08*sin(clock*5.3+float(i)),
            0.90+0.19*sin(clock*7.2+float(i)*0.6),
            0.94+0.07*sin(clock*4.1+float(i)))
    return true

static func _animate_fx(model: Node3D,kind: String,t: float) -> void:
    var burst: Node3D=_part(model,IMPACT)
    var fire: Node3D=_part(model,FIRE)
    var smoke: Node3D=_part(model,SMOKE)
    var wreck: Node3D=_part(model,WRECK)
    var n: int=stage(model)
    burst.visible=kind in ["hit_bullet","hit_explosive","destroy"] and t>=0.16 and t<0.44
    burst.scale=Vector3.ONE*(0.70+0.40*sin(PI*t))
    var wave: Node3D=_part(model,"A01V13_OndaChoqueLateral")
    if wave!=null:
        var expansion: float=clampf((t-0.16)/0.28,0.0,1.0)
        wave.scale=Vector3.ONE*(0.45+1.85*expansion)
    smoke.visible=n>=2 or (kind=="destroy" and t>0.20)
    smoke.position.y=0.045*sin(TAU*t) if kind=="destroy" else 0.0
    fire.visible=n>=3 or (kind=="destroy" and t>0.29)
    fire.scale=Vector3.ONE*(0.94+0.12*sin(TAU*t*3.0))
    animate_ambient(model,t*DESTROY_DURATION)
    if kind=="destroy":
        for child in wreck.get_children():
            var piece: MeshInstance3D=child as MeshInstance3D
            if piece!=null and piece.has_meta("a01_v13_rest"):
                var rest: Vector3=piece.get_meta("a01_v13_rest") as Vector3
                var launch: Vector3=piece.get_meta("a01_v13_launch") as Vector3
                var angle: Vector3=piece.get_meta("a01_v13_rot") as Vector3
                var progress: float=t*t*(3.0-2.0*t)
                piece.position=launch.lerp(rest,progress)+Vector3(
                    0,0.28*sin(PI*t),0)
                piece.rotation_degrees=angle+Vector3(
                    42.0*sin(PI*t),74.0*sin(PI*t),38.0*sin(PI*t))
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
