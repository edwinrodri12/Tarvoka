extends RefCounted
class_name TarvokaA02FpvArtV1

# Fictional game sculpture; abstract Godot display units, not engineering.
const FLAG:String="tarvoka_a02_fpv_art_v1"
const BODY:String="A02_VisualBody"
const PAINT:String="A02_FactionCrown"

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _part(parent:Node3D,tag:String,mesh:Mesh,at:Vector3,
        size:Vector3,paint:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=tag
    n.mesh=mesh
    n.position=at
    n.scale=size
    n.material_override=paint
    parent.add_child(n)
    return n

static func _oval(parent:Node3D,tag:String,at:Vector3,size:Vector3,
        paint:Material,hero:bool)->MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=16 if hero else 10
    mesh.rings=6 if hero else 4
    return _part(parent,tag,mesh,at,size,paint)

static func build(root:Node3D,faction:Color,hero:bool)->bool:
    if root==null or root.has_meta(FLAG):
        return false
    var body:=Node3D.new()
    body.name=BODY
    root.add_child(body)
    var graphite:=_mat(Color("#33414a"),0.12,0.74)
    var shell:=_mat(Color("#84949e"),0.17,0.66)
    var enamel:=_mat(faction,0.13,0.65)
    var glass:=_mat(Color("#377c91"),0.17,0.25)
    _oval(body,"A02_ClosedCentralShell",Vector3(0,0.96,0),Vector3(0.72,0.48,1.05),graphite,hero)
    _oval(body,PAINT,Vector3(0,1.105,-0.045),Vector3(0.61,0.29,0.83),enamel,hero)
    _oval(body,"A02_FrontVisor",Vector3(0,0.99,-0.465),Vector3(0.35,0.25,0.20),glass,hero)
    _oval(body,"A02_SealedUndershell",Vector3(0,0.805,0.07),Vector3(0.57,0.30,0.77),shell,hero)
    for i in range(4):
        var side:float=-1.0 if i%2==0 else 1.0
        var depth:float=-1.0 if i<2 else 1.0
        var at:=Vector3(side*0.61,0.98,depth*0.52)
        var shoulder:=_oval(body,"A02_SculptedShoulder_"+str(i),
            Vector3(side*0.34,0.96,depth*0.28),Vector3(0.75,0.24,0.32),shell,hero)
        shoulder.rotation_degrees.y=-side*depth*34.0
        var ring:=TorusMesh.new()
        ring.inner_radius=0.28
        ring.outer_radius=0.42
        ring.rings=24 if hero else 12
        ring.ring_segments=10 if hero else 6
        _part(body,"A02_ClosedRotorGuard_"+str(i),ring,at,Vector3.ONE,enamel)
        var rotor:=Node3D.new()
        rotor.name="A02_VisualRotor_"+str(i)
        rotor.position=at
        body.add_child(rotor)
        _oval(rotor,"A02_RotorCap",Vector3.ZERO,Vector3(0.22,0.14,0.22),shell,hero)
        for j in range(2):
            var graphic:=_oval(rotor,"A02_RotorGraphic_"+str(j),Vector3(0,0.025,0),
                Vector3(0.48,0.042,0.085),graphite,hero)
            graphic.rotation_degrees.y=float(j)*90.0
        if hero:
            _oval(body,"A02_ShoulderBadge_"+str(i),Vector3(side*0.34,1.065,depth*0.28),
                Vector3(0.22,0.07,0.20),enamel,true)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a02_visual_only",true)
    root.set_meta("tarvoka_a02_lod",13 if hero else 8)
    return true

static func restore(root:Node3D)->void:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return
    body.rotation=Vector3.ZERO
    body.position=Vector3.ZERO
    for i in range(4):
        var rotor:=body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
        if rotor!=null:
            rotor.rotation=Vector3.ZERO

static func pose(root:Node3D,kind:String,progress:float)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)) or not kind in ["idle","move","hit"]:
        return false
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return false
    var p:float=clampf(progress,0.0,1.0)
    var envelope:float=pow(sin(p*PI),2.0)
    body.position.y=0.06*envelope if kind=="move" else 0.0
    body.rotation_degrees.z=4.0*sin(p*TAU)*envelope if kind=="move" else (7.0*sin(p*TAU)*envelope if kind=="hit" else 0.0)
    for i in range(4):
        var rotor:=body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
        if rotor!=null:
            rotor.rotation_degrees.y=(1.0 if i%2==0 else -1.0)*720.0*p if kind=="move" else 0.0
    return true
