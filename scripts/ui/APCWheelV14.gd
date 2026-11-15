extends RefCounted
class_name TarvokaAPCWheelV14

# P06 V14 production running gear. Real open-spoke rims, sidewall bead,
# brake disks, static calipers and articulated visible suspension.
# All wheel geometry attaches to the EXISTING six V1 rotating/steering
# pivots; chassis arms stay static in world space and only follow travel.
# No change to V2 tread, traction, movement, stats, combat or LOD.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V13=preload("res://scripts/ui/APCSurfaceV13.gd")
const FLAG := "tarvoka_apc_wheel_v14"
const WHEEL_ROOT := "P06V14_LlantaEsculpida"
const SUSPENSION := "P06V14_SuspensionArticulada"
const CHASSIS := "P06V14_TrenRodajeMecanico"
const DAMAGE := "P06V14_NeumaticoCortado"
const WRECK := "P06V14_SuspensionDesprendida"
const SHOW := "tarvoka_apc_wheel_v14_visible"
const STAGE := "tarvoka_apc_wheel_v14_stage"
const PIVOT_PREFIX := "RuedaMotorizadaP06_"
const BOLT_COUNT := 8
const SPOKES := 6
const WHEEL_COUNT := 6
const STRUT_BODY := 0.245
const ORIGINAL := ["AnilloLlanta","BujeCentral","PernosP06"]
static var _rim_mesh: ArrayMesh
static var _coil_mesh: ArrayMesh
static var _bolts: CylinderMesh

static func _material(color: Color,metal: float=0.42,
        rough: float=0.70) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    return mat

static func _group(parent: Node3D,name: String) -> Node3D:
    var group:=Node3D.new()
    group.name=name
    parent.add_child(group)
    return group

static func _part(parent: Node3D,name: String,shape: Mesh,
        material: Material,pos: Vector3=Vector3.ZERO,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=shape
    part.material_override=material
    part.position=pos
    part.rotation_degrees=rot
    parent.add_child(part)
    return part

static func _box(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,material: Material) -> MeshInstance3D:
    var shape:=BoxMesh.new()
    shape.size=size
    return _part(parent,name,shape,material,pos)

static func _cylinder(parent: Node3D,name: String,pos: Vector3,
        radius: float,height: float,material: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=height
    shape.radial_segments=12
    return _part(parent,name,shape,material,pos,rotation)

static func _torus(parent: Node3D,name: String,pos: Vector3,
        inside: float,outside: float,material: Material) -> MeshInstance3D:
    var ring:=TorusMesh.new()
    ring.inner_radius=inside
    ring.outer_radius=outside
    ring.rings=14
    ring.ring_segments=16
    return _part(parent,name,ring,material,pos,Vector3(0,0,90))

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        st.add_vertex(vertex)

static func _sculpted_spokes() -> ArrayMesh:
    if _rim_mesh!=null:
        return _rim_mesh
    # One closed extrusion per spoke with six genuine empty gaps. An opaque
    # solid rim cylinder would hide the black brake disc and the hub relief.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(SPOKES):
        var ang: float=TAU*float(i)/float(SPOKES)
        var a0: float=ang-0.170
        var a1: float=ang+0.170
        var b0: float=ang-0.235
        var b1: float=ang+0.235
        var v: Array[Vector3]=[
            Vector3(0.135,0.093*cos(a0),0.093*sin(a0)),
            Vector3(0.135,0.188*cos(b0),0.188*sin(b0)),
            Vector3(0.135,0.188*cos(b1),0.188*sin(b1)),
            Vector3(0.135,0.093*cos(a1),0.093*sin(a1))]
        var front: Array[Vector3]=[]
        for p in v:
            front.append(Vector3(0.173,p.y,p.z))
        _quad(st,front[0],front[1],front[2],front[3])
        _quad(st,v[3],v[2],v[1],v[0])
        for j in range(4):
            var next: int=(j+1)%4
            _quad(st,v[j],v[next],front[next],front[j])
    st.generate_normals()
    _rim_mesh=st.commit()
    return _rim_mesh

static func _helical_spring() -> ArrayMesh:
    if _coil_mesh!=null:
        return _coil_mesh
    # Visible continuous steel spring around a rigid hydraulic damper.
    # Local Y = [0, 1], later aligned between body anchor and wheel joint.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var turns: int=5
    var segments: int=100
    for i in range(segments):
        var a: float=float(i)/float(segments)
        var b: float=float(i+1)/float(segments)
        var angle_a: float=TAU*float(turns)*a
        var angle_b: float=TAU*float(turns)*b
        var center_a:=Vector3(0.076*cos(angle_a),
            a,0.076*sin(angle_a))
        var center_b:=Vector3(0.076*cos(angle_b),
            b,0.076*sin(angle_b))
        for j in range(6):
            var theta_a: float=TAU*float(j)/6.0
            var theta_b: float=TAU*float(j+1)/6.0
            var p0:=center_a+Vector3(0.008*cos(theta_a),
                0.0,0.008*sin(theta_a))
            var p1:=center_a+Vector3(0.008*cos(theta_b),
                0.0,0.008*sin(theta_b))
            var p2:=center_b+Vector3(0.008*cos(theta_b),
                0.0,0.008*sin(theta_b))
            var p3:=center_b+Vector3(0.008*cos(theta_a),
                0.0,0.008*sin(theta_a))
            _quad(st,p0,p1,p2,p3)
    st.generate_normals()
    _coil_mesh=st.commit()
    return _coil_mesh

static func _bolt_mesh() -> CylinderMesh:
    if _bolts==null:
        _bolts=CylinderMesh.new()
        _bolts.top_radius=0.013
        _bolts.bottom_radius=0.013
        _bolts.height=0.019
        _bolts.radial_segments=6
    return _bolts

static func _wheel(wheel: Node3D,side: int,axle: int,
        rubber: Material,metal: Material,brake: Material,
        bolts: Material,damaged: Material) -> bool:
    if wheel==null:
        return false
    var surface:=_group(wheel,WHEEL_ROOT)
    var s: float=float(side)
    # Keep the V2 3D tire carcass and 48 aggressive tread blocks. Replace
    # only the old solid painted rim, its tiny center and the obsolete bolts.
    _torus(surface,"P06V14_AnilloTalónNeumático",
        Vector3(s*0.122,0,0),0.283,0.307,rubber)
    _torus(surface,"P06V14_AroLlantaExterior",
        Vector3(s*0.139,0,0),0.195,0.224,metal)
    _torus(surface,"P06V14_BordeLlantaInterior",
        Vector3(-s*0.131,0,0),0.192,0.221,metal)
    _torus(surface,"P06V14_DiscoFrenoVentilado",
        Vector3(s*0.111,0,0),0.155,0.178,brake)
    var spoke: MeshInstance3D=_part(surface,
        "P06V14_SeisRadiosCalados",_sculpted_spokes(),metal)
    spoke.scale.x=s
    _cylinder(surface,"P06V14_BujeEstriado",
        Vector3(s*0.171,0,0),0.096,0.031,metal,
        Vector3(0,0,90))
    _torus(surface,"P06V14_AnilloReténBuje",
        Vector3(s*0.192,0,0),0.071,0.085,brake)
    var nut:=CylinderMesh.new()
    nut.top_radius=0.044
    nut.bottom_radius=0.044
    nut.height=0.028
    nut.radial_segments=6
    _part(surface,"P06V14_TuercaEjeHexagonal",nut,bolts,
        Vector3(s*0.202,0,0),Vector3(0,0,90))
    var ring:=MultiMesh.new()
    ring.transform_format=MultiMesh.TRANSFORM_3D
    ring.mesh=_bolt_mesh()
    ring.instance_count=BOLT_COUNT
    for i in range(BOLT_COUNT):
        var a: float=TAU*float(i)/float(BOLT_COUNT)
        ring.set_instance_transform(i,Transform3D(
            Basis(Vector3.FORWARD,PI*0.5),
            Vector3(s*0.184,0.137*cos(a),0.137*sin(a))))
    var fasteners:=MultiMeshInstance3D.new()
    fasteners.name="P06V14_OchoPernosLlanta"
    fasteners.multimesh=ring
    fasteners.material_override=bolts
    surface.add_child(fasteners)
    # Sidewall stamping is relief, but not a decal that scales poorly.
    # The original tire itself remains the V2 molded-black rubber.
    var puncture:=_group(surface,DAMAGE)
    puncture.visible=false
    if side==-1 and axle==0:
        _box(puncture,"P06V14_CorteGomaSidewall",
            Vector3(s*0.131,0.240,-0.178),
            Vector3(0.013,0.084,0.031),damaged)
        _box(puncture,"P06V14_CuerdaAceroExpuesta",
            Vector3(s*0.141,0.232,-0.164),
            Vector3(0.019,0.070,0.012),metal)
    surface.set_meta("tarvoka_apc_v14_wheel_index",
        axle+(0 if side<0 else 3))
    return true

static func _link(part: Node3D,from: Vector3,to: Vector3) -> void:
    var vector: Vector3=to-from
    var magnitude: float=maxf(0.001,vector.length())
    part.position=(from+to)*0.5
    part.basis=Basis(Quaternion(Vector3.UP,vector.normalized()))
    part.scale=Vector3(1.0,magnitude,1.0)

static func _suspension(root: Node3D,side: int,axle: int,
        steel: Material,chrome: Material,
        brake: Material,dark: Material) -> Node3D:
    var block:=_group(root,
        "P06V14_Suspension_%d_%d" % [side,axle])
    var s: float=float(side)
    var z: float=float(V1.WHEEL_Z[axle])
    # No control arm pivots under the SPINNING wheel. The separate knuckle,
    # wishbones and fixed brake caliper follow suspension compression ONLY.
    _cylinder(block,"P06V14_BrazoSuperior",
        Vector3.ZERO,0.033,1.0,steel)
    _cylinder(block,"P06V14_BrazoInferior",
        Vector3.ZERO,0.039,1.0,steel)
    _cylinder(block,"P06V14_SemiejeTransmision",
        Vector3.ZERO,0.043,1.0,dark)
    _cylinder(block,"P06V14_CamisaAmortiguador",
        Vector3.ZERO,0.035,1.0,dark)
    _cylinder(block,"P06V14_VastagoAmortiguador",
        Vector3.ZERO,0.017,1.0,chrome)
    _part(block,"P06V14_ResorteHelicoidalReal",
        _helical_spring(),steel)
    var knuckle:=_group(block,"P06V14_ManguetaFreno")
    _cylinder(knuckle,"P06V14_CuerpoMangueta",
        Vector3.ZERO,0.081,0.115,steel,
        Vector3(0,0,90))
    _box(knuckle,"P06V14_PinzaFrenoEstatica",
        Vector3(s*0.090,0.178,0),
        Vector3(0.087,0.088,0.105),brake)
    _box(knuckle,"P06V14_ProtectorDisco",
        Vector3(s*0.051,-0.172,0.0),
        Vector3(0.031,0.070,0.119),dark)
    for arm in ["P06V14_BrazoSuperior","P06V14_BrazoInferior"]:
        var endpoint:=SphereMesh.new()
        endpoint.radius=0.044
        endpoint.height=0.088
        endpoint.radial_segments=10
        endpoint.rings=5
        _part(block,
            "P06V14_Rotula_%s" % arm,endpoint,steel)
    block.set_meta("tarvoka_apc_v14_side",side)
    block.set_meta("tarvoka_apc_v14_axle",axle)
    block.set_meta("tarvoka_apc_v14_z",z)
    return block

static func _pose_block(block: Node3D,
        wheel: Node3D) -> bool:
    if block==null or wheel==null:
        return false
    var side: int=int(block.get_meta(
        "tarvoka_apc_v14_side",0))
    var s: float=float(side)
    var z: float=float(block.get_meta("tarvoka_apc_v14_z",0))
    var wheel_y: float=wheel.position.y
    var inner_upper:=Vector3(s*0.480,0.593,z-0.055)
    var outer_upper:=Vector3(s*0.798,wheel_y+0.128,z-0.025)
    var inner_lower:=Vector3(s*0.487,0.345,z+0.045)
    var outer_lower:=Vector3(s*0.802,wheel_y-0.131,z+0.015)
    var shaft_from:=Vector3(s*0.390,0.432,z)
    var shaft_to:=Vector3(s*0.798,wheel_y,z)
    var shock_start:=Vector3(s*0.623,0.899,z+0.072)
    var shock_end:=Vector3(s*0.785,wheel_y-0.064,z+0.031)
    var vector: Vector3=shock_end-shock_start
    if vector.length()<=STRUT_BODY+0.02:
        return false
    var shock_joint: Vector3=shock_start+vector.normalized()*STRUT_BODY
    var specs: Array=[
        ["P06V14_BrazoSuperior",inner_upper,outer_upper],
        ["P06V14_BrazoInferior",inner_lower,outer_lower],
        ["P06V14_SemiejeTransmision",shaft_from,shaft_to],
        ["P06V14_CamisaAmortiguador",shock_start,shock_joint],
        ["P06V14_VastagoAmortiguador",shock_joint,shock_end],
        ["P06V14_ResorteHelicoidalReal",shock_start,shock_joint]]
    for definition in specs:
        var beam: Node3D=block.find_child(str(definition[0]),
            false,false) as Node3D
        if beam==null:
            return false
        _link(beam,definition[1],definition[2])
    for pair in [
            ["P06V14_Rotula_P06V14_BrazoSuperior",outer_upper],
            ["P06V14_Rotula_P06V14_BrazoInferior",outer_lower]]:
        var pivot: Node3D=block.find_child(str(pair[0]),
            false,false) as Node3D
        if pivot!=null:
            pivot.position=pair[1]
    var spindle: Node3D=block.find_child(
        "P06V14_ManguetaFreno",false,false) as Node3D
    if spindle!=null:
        spindle.position=Vector3(s*0.845,wheel_y,z)
        spindle.rotation_degrees.y=wheel.rotation_degrees.y if (
            int(block.get_meta("tarvoka_apc_v14_axle",1))==0) else 0.0
    block.set_meta("tarvoka_apc_v14_shock_rod_length",
        (shock_end-shock_joint).length())
    return true

static func pose(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var root: Node3D=model.find_child(CHASSIS,true,false) as Node3D
    if root==null:
        return false
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "%s%d_%d" % [PIVOT_PREFIX,side,axle],
                true,false) as Node3D
            var assembly: Node3D=root.find_child(
                "P06V14_Suspension_%d_%d" % [side,axle],
                false,false) as Node3D
            if not _pose_block(assembly,wheel):
                return false
    return true

static func _original_parts(model: Node3D,enabled: bool) -> void:
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "%s%d_%d" % [PIVOT_PREFIX,side,axle],
                true,false) as Node3D
            if wheel==null:
                continue
            for old_name in ORIGINAL:
                var old: Node3D=wheel.find_child(
                    old_name,false,false) as Node3D
                if old!=null:
                    old.visible=not enabled
            var arm: Node3D=model.find_child(
                "BrazoSuspension_%d_%d" % [side,axle],
                true,false) as Node3D
            if arm!=null:
                arm.visible=not enabled

static func apply(model: Node3D,faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V13.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D=model.find_child(V1.ROOT,
        true,false) as Node3D
    if hull==null:
        return false
    var metal:=_material(
        Color("#646f74").lerp(faction_color,0.16),0.57,0.70)
    var steel:=_material(Color("#838c8f"),0.65,0.57)
    var chrome:=_material(Color("#b4bfc3"),0.78,0.32)
    var brake:=_material(Color("#40474b"),0.50,0.88)
    var rubber:=_material(Color("#25282a"),0.03,0.97)
    var damaged:=_material(Color("#181c1d"),0.12,0.94)
    var chassis:=_group(hull,CHASSIS)
    var susp:=_group(chassis,SUSPENSION)
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=hull.find_child(
                "%s%d_%d" % [PIVOT_PREFIX,side,axle],
                false,false) as Node3D
            if wheel==null or not _wheel(wheel,side,axle,rubber,
                    metal,brake,steel,damaged):
                chassis.queue_free()
                return false
            _suspension(susp,side,axle,steel,chrome,brake,damaged)
    var wreck:=_group(chassis,WRECK)
    wreck.visible=false
    _box(wreck,"P06V14_HorquillaPartida",
        Vector3(0.780,0.405,-1.06),
        Vector3(0.214,0.051,0.088),steel)
    _box(wreck,"P06V14_AmortiguadorTorcido",
        Vector3(0.772,0.607,-1.06),
        Vector3(0.065,0.306,0.064),brake)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    model.set_meta("tarvoka_apc_v14_spokes",SPOKES)
    model.set_meta("tarvoka_apc_v14_wheel_count",WHEEL_COUNT)
    if not pose(model):
        model.set_meta(FLAG,false)
        chassis.queue_free()
        return false
    _original_parts(model,true)
    return true

static func set_stage(model: Node3D,stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var value: int=clampi(stage,0,4)
    var show: bool=bool(model.get_meta(SHOW,true))
    var chassis: Node3D=model.find_child(
        CHASSIS,true,false) as Node3D
    if chassis!=null:
        chassis.visible=show
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "%s%d_%d" % [PIVOT_PREFIX,side,axle],
                true,false) as Node3D
            if wheel==null:
                continue
            var detail: Node3D=wheel.find_child(
                WHEEL_ROOT,false,false) as Node3D
            var puncture: Node3D=wheel.find_child(
                DAMAGE,true,false) as Node3D
            if detail!=null:
                detail.visible=show
            if puncture!=null:
                puncture.visible=show and side==-1 and axle==0 and value>=3
    var wreck: Node3D=model.find_child(
        WRECK,true,false) as Node3D
    if wreck!=null:
        wreck.visible=show and value==4
    model.set_meta(STAGE,value)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    _original_parts(model,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
