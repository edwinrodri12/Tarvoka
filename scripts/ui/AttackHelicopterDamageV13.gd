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


# V13.1 sculpted mesh effects: vertex alpha fades through the volume instead
# of using dark opaque balls. All meshes remain native editable Godot assets.
static func _fx_material(is_fire: bool) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color.WHITE
    m.vertex_color_use_as_albedo=true
    m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.roughness=1.0
    if is_fire:
        m.emission_enabled=true
        m.emission=Color("#ff7f31")
        m.emission_energy_multiplier=0.32
    return m

static func _fx_point(height: float,radius: float,segment: int,seed: float,
        bend: float) -> Vector3:
    var a: float=TAU*float(segment)/10.0
    var jagged: float=1.0+0.13*sin(a*3.0+seed+height*9.0)
    return Vector3(
        cos(a)*radius*jagged+bend*height*height,
        height,
        sin(a)*radius*(1.0+0.10*cos(a*4.0+seed))
    )

static func _fx_vertex(st: SurfaceTool,pos: Vector3,color: Color) -> void:
    st.set_color(color)
    st.add_vertex(pos)

static func _fx_sculpt(is_fire: bool,seed: float) -> ArrayMesh:
    var heights: Array=[0.0,0.035,0.12,0.20,0.30,0.40] if is_fire else [
        0.0,0.09,0.20,0.34,0.49,0.63]
    var radii: Array=[0.054,0.088,0.081,0.061,0.039,0.003] if is_fire else [
        0.035,0.095,0.15,0.19,0.145,0.009]
    var colors: Array=[
        Color(1.0,0.92,0.43,0.80),
        Color(1.0,0.73,0.22,0.96),
        Color(1.0,0.39,0.10,0.93),
        Color(0.92,0.20,0.055,0.77),
        Color(0.59,0.13,0.055,0.41),
        Color(0.40,0.12,0.08,0.0)
    ] if is_fire else [
        Color(0.16,0.20,0.22,0.0),
        Color(0.17,0.21,0.235,0.34),
        Color(0.22,0.25,0.27,0.31),
        Color(0.27,0.30,0.315,0.23),
        Color(0.33,0.36,0.37,0.13),
        Color(0.38,0.40,0.41,0.0)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bend: float=(0.21 if is_fire else 0.32)*(sin(seed*1.73)*0.7+0.3)
    for ring in range(heights.size()-1):
        for j in range(10):
            var a: Vector3=_fx_point(heights[ring],radii[ring],j,seed,bend)
            var b: Vector3=_fx_point(heights[ring],radii[ring],j+1,seed,bend)
            var c: Vector3=_fx_point(heights[ring+1],radii[ring+1],j,seed,bend)
            var d: Vector3=_fx_point(heights[ring+1],radii[ring+1],j+1,seed,bend)
            _fx_vertex(st,a,colors[ring])
            _fx_vertex(st,c,colors[ring+1])
            _fx_vertex(st,b,colors[ring])
            _fx_vertex(st,b,colors[ring])
            _fx_vertex(st,c,colors[ring+1])
            _fx_vertex(st,d,colors[ring+1])
    st.generate_normals()
    return st.commit()

static func _particles(body: Node3D) -> void:
    var smoke:=_group(body,SMOKE)
    # Staggered ribbons on the engine pods, not a line of solid balls.
    # Sculpted smoke never touches the HUD or tactical-map LOD<=10.
    for i in range(8):
        var right: bool=i<6
        var lane: float=float(i%6)
        var side: float=1.0 if right else -1.0
        var puff:=_mesh(smoke,"A01V13_ColumnaHumo_%d" % i,
            _fx_sculpt(false,0.79+float(i)*1.49),Color.WHITE,
            Vector3(side*(0.59+0.045*sin(float(i)*1.83)),
                1.51+0.055*float(i%3),
                0.73+0.09*cos(lane*1.56)))
        puff.material_override=_fx_material(false)
        puff.scale=Vector3(
            0.88+0.12*float(i%3),
            0.78+0.08*float(i%2),
            0.89+0.08*float(i%4))
        puff.set_meta("a01_v13_fx_rest",puff.position)
        puff.set_meta("a01_v13_fx_scale",puff.scale)
    var fire:=_group(body,FIRE)
    # Bright base, orange outer tongues and short ember tips extend
    # outside the engine shell rather than hiding inside the armour.
    for i in range(6):
        var right: bool=i<4
        var side: float=1.0 if right else -1.0
        var flame:=_mesh(fire,"A01V13_LlamaMotor_%d" % i,
            _fx_sculpt(true,1.9+float(i)*1.26),Color.WHITE,
            Vector3(side*(0.66+0.028*float(i%3)),
                1.52+0.024*float(i%2),
                0.74+0.075*sin(float(i)*1.5)))
        flame.material_override=_fx_material(true)
        flame.scale=Vector3(
            1.0-0.09*float(i%3),
            0.79+0.10*float(i%3),
            0.84+0.07*float(i%2))
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
            Vector3(-0.76+float(i)*0.42,0.105,0.12+float(i)*0.43))
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
        _blade_fragment(0.32),graphite,Vector3(1.12,0.087,2.02))
    tail_piece.rotation_degrees=Vector3(35.0,71.0,-22.0)
    tail_piece.set_meta("a01_v13_launch",Vector3(0.285,1.38,2.62))
    tail_piece.set_meta("a01_v13_rest",tail_piece.position)
    tail_piece.set_meta("a01_v13_rot",tail_piece.rotation_degrees)
    for side in [-1,1]:
        var s: float=float(side)
        var piece:=_box(debris,"A01V13_FragmentoBlindaje_%d" % side,
            Vector3(s*0.91,0.115,-0.53),
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
    var previous: int=stage(model)
    var n: int=clampi(level,0,MAX_STAGE)
    var wreck: Node3D=_part(model,WRECK)
    if n==MAX_STAGE and previous<MAX_STAGE:
        # Take a snapshot of the actual world pose BEFORE the helicopter
        # banks and falls. The shards detach from the fuselage's transform
        # but retain the same world pose as the original rotor hubs.
        var body: Node3D=_part(model,V1.ROOT)
        var launch_frame: Transform3D=body.global_transform
        wreck.top_level=true
        wreck.global_transform=launch_frame
    elif n<MAX_STAGE and previous==MAX_STAGE:
        # Repair returns the debris node to the original V1 body tree.
        # Repeating destroy/repair never leaves world-space orphan shards.
        wreck.top_level=false
        wreck.transform=Transform3D.IDENTITY
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
            0.09*sin(clock*0.82+float(i)*1.27),phase*0.46,
            0.065*sin(clock*0.67+float(i)*1.7))
        puff.scale=base_size*Vector3(
            0.91+0.22*phase,0.89+0.16*phase,0.91+0.24*phase)
        var vapor: StandardMaterial3D=puff.material_override as StandardMaterial3D
        if vapor!=null:
            # Every wisp fades in and out of its loop without popping.
            vapor.albedo_color=Color(1.0,1.0,1.0,0.18+0.82*sin(PI*phase))
    for i in range(fire.get_child_count()):
        var flame: MeshInstance3D=fire.get_child(i) as MeshInstance3D
        if flame==null or not flame.has_meta("a01_v13_fx_rest"):
            continue
        var start: Vector3=flame.get_meta("a01_v13_fx_rest") as Vector3
        var shape: Vector3=flame.get_meta("a01_v13_fx_scale") as Vector3
        flame.position=start+Vector3(
            0.028*sin(clock*5.1+float(i)*1.4),
            0.022*sin(clock*4.3+float(i)),0.017*sin(clock*4.7+float(i)))
        flame.rotation_degrees.z=7.0*sin(clock*3.7+float(i)*0.85)
        flame.scale=shape*Vector3(
            0.89+0.13*sin(clock*5.3+float(i)),
            0.84+0.23*sin(clock*7.2+float(i)*0.6),
            0.88+0.14*sin(clock*4.1+float(i)))
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
