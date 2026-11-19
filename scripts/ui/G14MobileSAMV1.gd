extends RefCounted
class_name TarvokaG14MobileSAMV1

# G14 V1: original 8x8 heavy mobile SAM visual prototype for TARVOKA.
# Godot 4.3 native meshes only. No changes to playable "sam" logic,
# target acquisition, damage, ammunition, range or saved battles.
const FLAG := "tarvoka_g14_v1_native_sam_8x8"
const CHASSIS := "G14_Chasis8x8"
const LAUNCHER := "G14_PlataformaGiro"
const ELEVATION := "G14_ElevacionLanzadores"
const RADAR := "G14_RadarGiratorio"
const WHEELS := "G14_Ruedas8x8"
const HUBS := "G14_Bujes8x8"
const WHEEL_X: float = 1.055
const WHEEL_Y: float = 0.398
const WHEEL_RADIUS: float = 0.365
const AXLES := [-1.48,-0.60,0.52,1.39]
const TUBES: int = 4
const MAX_DRAW_FX: int = 4

static func _mat(color: Color,metal: float=0.15,rough: float=0.7,
        emit: bool=false)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    if emit:
        mat.emission_enabled=true
        mat.emission=color
        mat.emission_energy_multiplier=1.8
    return mat

static func _box(parent: Node3D,label: String,center: Vector3,
        size: Vector3,mat: Material,angles: Vector3=Vector3.ZERO)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.material_override=mat
    node.position=center
    node.rotation_degrees=angles
    parent.add_child(node)
    return node

static func _cylinder(parent: Node3D,label: String,center: Vector3,
        radius: float,height: float,mat: Material,angles: Vector3=Vector3.ZERO,
        radial: int=16)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=radial
    node.mesh=mesh
    node.material_override=mat
    node.position=center
    node.rotation_degrees=angles
    parent.add_child(node)
    return node

static func _batch(parent: Node3D,label: String,radius: float,
        width: float,material: Material,segments: int)->MultiMeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=width
    mesh.radial_segments=segments
    mesh.material=material
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=mesh
    mm.instance_count=8
    var n:=MultiMeshInstance3D.new()
    n.name=label
    n.multimesh=mm
    parent.add_child(n)
    return n

static func _wheel_pose(root: Node3D,t: float)->bool:
    var tires:=root.find_child(WHEELS,true,false) as MultiMeshInstance3D
    var hubs:=root.find_child(HUBS,true,false) as MultiMeshInstance3D
    if tires==null or hubs==null or tires.multimesh==null or (
            hubs.multimesh==null):
        return false
    if tires.multimesh.instance_count!=8 or hubs.multimesh.instance_count!=8:
        return false
    var spin: float=TAU*1.9*t
    var i:int=0
    for side in [-1,1]:
        for z in AXLES:
            var axis:=Basis(Vector3.FORWARD,PI*0.5)
            var rotation:=Basis(Vector3.RIGHT,spin)
            var basis:Basis=rotation*axis
            var center:=Vector3(float(side)*WHEEL_X,WHEEL_Y,float(z))
            tires.multimesh.set_instance_transform(i,Transform3D(basis,center))
            hubs.multimesh.set_instance_transform(i,Transform3D(
                basis,center+Vector3(float(side)*0.158,0,0)))
            i+=1
    return true

static func build(root: Node3D,enamel: Color,high_detail: bool=true)->bool:
    if root==null or root.has_meta(FLAG):
        return false
    var steel:=_mat(Color("#6e7c80"),0.45,0.48)
    var armor:=_mat(Color("#58696d"),0.31,0.67)
    var shadow:=_mat(Color("#252d32"),0.18,0.83)
    var rubber:=_mat(Color("#202529"),0.05,0.95)
    var alloy:=_mat(Color("#9aaab2"),0.68,0.33)
    var glass:=_mat(Color("#427f9b"),0.30,0.12)
    var faction:=_mat(enamel.darkened(0.07),0.25,0.54)
    var dark_panel:=_mat(Color("#2a4656"),0.23,0.39)
    var highlight:=_mat(Color("#ffc787"),0.05,0.28,true)
    var body:=Node3D.new()
    body.name=CHASSIS
    root.add_child(body)
    # Four-axle silhouette, distinct from G13's 4x4 and G15's EW 6x6.
    _box(body,"G14_BastidorPrincipal",Vector3(0,0.65,0),
        Vector3(1.69,0.39,3.72),shadow)
    _box(body,"G14_PisoBlindado",Vector3(0,0.90,0),
        Vector3(1.74,0.21,3.45),armor)
    _box(body,"G14_CabinaBlindada",Vector3(0,1.21,-1.21),
        Vector3(1.60,0.70,1.11),steel)
    _box(body,"G14_ProaInclinada",Vector3(0,1.05,-1.76),
        Vector3(1.58,0.43,0.39),armor,Vector3(-21,0,0))
    _box(body,"G14_TechoCabina",Vector3(0,1.59,-1.18),
        Vector3(1.76,0.095,1.05),armor)
    _box(body,"G14_Parachoques",Vector3(0,0.64,-1.94),
        Vector3(1.80,0.19,0.18),shadow)
    _box(body,"G14_PlataformaTrasera",Vector3(0,1.13,0.83),
        Vector3(1.79,0.25,2.02),steel)
    for side in [-1,1]:
        var s:float=float(side)
        _box(body,"G14_Parabrisas_%d" % side,Vector3(s*0.41,1.36,-1.78),
            Vector3(0.62,0.28,0.042),glass,Vector3(-12,0,0))
        _box(body,"G14_VidrioLateral_%d" % side,
            Vector3(s*0.813,1.37,-1.26),Vector3(0.044,0.27,0.51),glass)
        _box(body,"G14_FaccionCabina_%d" % side,
            Vector3(s*0.819,1.05,-1.22),
            Vector3(0.042,0.17,0.88),faction)
        _box(body,"G14_PanelFaccion_%d" % side,
            Vector3(s*0.91,1.06,0.76),
            Vector3(0.049,0.15,1.65),faction)
        _box(body,"G14_Faros_%d" % side,Vector3(s*0.63,0.94,-1.963),
            Vector3(0.24,0.13,0.035),alloy)
        _box(body,"G14_ArcoBlindado_%d" % side,
            Vector3(s*0.91,0.78,0.17),
            Vector3(0.13,0.24,3.36),armor)
        if high_detail:
            for j in range(4):
                _box(body,"G14_RejillaServicio_%d_%d" % [side,j],
                    Vector3(s*0.773,1.606,-1.52+float(j)*0.18),
                    Vector3(0.19,0.018,0.065),shadow)
            _box(body,"G14_MarcaMecanica_%d" % side,
                Vector3(s*0.831,1.61,-1.03),
                Vector3(0.10,0.015,0.33),faction)
    _box(body,"G14_EscotillaServicio",Vector3(0,1.268,1.72),
        Vector3(1.07,0.04,0.24),shadow)
    _box(body,"G14_CarenadoMotor",Vector3(0,1.25,-0.34),
        Vector3(1.47,0.13,0.55),armor)
    _batch(body,WHEELS,WHEEL_RADIUS,0.255,rubber,24 if high_detail else 14)
    _batch(body,HUBS,0.151,0.039,alloy,20 if high_detail else 12)

    # Two-by-two enclosed SAM launcher cells on one yaw + elevation rig.
    var turret:=Node3D.new()
    turret.name=LAUNCHER
    turret.position=Vector3(0,1.40,0.75)
    body.add_child(turret)
    _cylinder(turret,"G14_AnilloAzimut",Vector3(0,0.015,0),
        0.67,0.15,shadow,Vector3.ZERO,24)
    _box(turret,"G14_BaseDeLanzadores",Vector3(0,0.16,0),
        Vector3(1.31,0.29,1.20),armor)
    var elevation:=Node3D.new()
    elevation.name=ELEVATION
    elevation.position=Vector3(0,0.31,0.29)
    turret.add_child(elevation)
    _cylinder(elevation,"G14_BisagraElevacion",
        Vector3(0,0,0),0.18,1.26,alloy,Vector3(0,0,90))
    for i in range(TUBES):
        var x:float=-0.36 if i%2==0 else 0.36
        var y:float=-0.23 if i<2 else 0.23
        _box(elevation,"G14_ContenedorSAM_%d" % i,
            Vector3(x,y,-0.70),Vector3(0.56,0.39,1.64),steel)
        _box(elevation,"G14_AroBoca_%d" % i,
            Vector3(x,y,-1.541),Vector3(0.60,0.44,0.105),shadow)
        _box(elevation,"G14_TapaLanzador_%d" % i,
            Vector3(x,y,-1.599),Vector3(0.41,0.28,0.018),dark_panel)
        _box(elevation,"G14_SelloTrasero_%d" % i,
            Vector3(x,y,0.151),Vector3(0.57,0.39,0.05),shadow)
        if high_detail:
            _box(elevation,"G14_CostillaDeContenedor_%d" % i,
                Vector3(x+0.27,y,-0.68),Vector3(0.028,0.29,1.44),faction)
        # Visual-only missile travel and exhaust: no combat projectile.
        var missile:=_cylinder(elevation,"G14_MisilAnimado_%d" % i,
            Vector3(x,y,-1.60),0.10,0.57,alloy,
            Vector3(90,0,0),12)
        missile.visible=false
        var flash:=_cylinder(elevation,"G14_EscapeVisual_%d" % i,
            Vector3(x,y,-1.66),0.15,0.28,highlight,
            Vector3(90,0,0),10)
        flash.visible=false
    # Rear independent, folding radar — not the G13 turret-top dish.
    var radar:=Node3D.new()
    radar.name=RADAR
    radar.position=Vector3(0.58,1.44,1.49)
    body.add_child(radar)
    _cylinder(radar,"G14_BaseRadar",Vector3(0,0.12,0),
        0.19,0.22,shadow)
    _box(radar,"G14_MastilRadar",Vector3(0,0.49,0),
        Vector3(0.16,0.61,0.16),alloy)
    _box(radar,"G14_AntenaPhasedArray",Vector3(0,0.92,0),
        Vector3(0.99,0.58,0.075),dark_panel,Vector3(-9,0,0))
    _box(radar,"G14_CrestaRadar",Vector3(0,0.92,-0.051),
        Vector3(0.85,0.04,0.018),faction)
    # Deployable feet, hinged at the chassis corners.
    for side in [-1,1]:
        for at in [-1,1]:
            var leg:=Node3D.new()
            leg.name="G14_Estabilizador_%d_%d" % [side,at]
            leg.position=Vector3(float(side)*0.84,0.83,float(at)*1.34)
            body.add_child(leg)
            _box(leg,"G14_BrazoEstabilizador",Vector3(float(side)*0.31,-0.12,0),
                Vector3(0.65,0.13,0.15),alloy)
            _box(leg,"G14_ZapataEstabilizadora",
                Vector3(float(side)*0.66,-0.33,0),
                Vector3(0.16,0.46,0.28),shadow)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g14_v1_art_only",true)
    root.set_meta("tarvoka_g14_v1_high_detail",high_detail)
    root.set_meta("tarvoka_g14_v1_sam_cells",TUBES)
    root.set_meta("tarvoka_g14_v1_wheels",8)
    root.set_meta("tarvoka_g14_v1_faction_color",enamel.to_html())
    restore(root)
    return _wheel_pose(root,0.0)

static func has_model(root: Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func restore(root: Node3D)->void:
    if not has_model(root):
        return
    var turret:=root.find_child(LAUNCHER,true,false) as Node3D
    var elevation:=root.find_child(ELEVATION,true,false) as Node3D
    var radar:=root.find_child(RADAR,true,false) as Node3D
    root.rotation_degrees.z=0.0
    if turret!=null:
        turret.rotation_degrees=Vector3.ZERO
    if elevation!=null:
        elevation.rotation_degrees=Vector3(12,0,0)
    if radar!=null:
        radar.rotation_degrees=Vector3(-8,0,0)
    _wheel_pose(root,0.0)
    for side in [-1,1]:
        for at in [-1,1]:
            var leg:=root.find_child("G14_Estabilizador_%d_%d" % [side,at],
                true,false) as Node3D
            if leg!=null:
                leg.rotation_degrees=Vector3.ZERO
    for i in range(TUBES):
        var missile:=root.find_child("G14_MisilAnimado_%d" % i,
            true,false) as Node3D
        var flash:=root.find_child("G14_EscapeVisual_%d" % i,
            true,false) as Node3D
        if missile!=null:
            missile.visible=false
            missile.position.z=-1.60
        if flash!=null:
            flash.visible=false
    root.set_meta("tarvoka_g14_v1_pose","idle")

static func pose(root: Node3D,kind: String,t: float,
        heading: Vector2i=Vector2i(0,-1))->bool:
    if not has_model(root) or kind not in [
            "idle","move","deploy","scan","aim","launch","stow","hit"]:
        return false
    var p:float=clampf(t,0.0,1.0)
    restore(root)
    var turret:=root.find_child(LAUNCHER,true,false) as Node3D
    var elevation:=root.find_child(ELEVATION,true,false) as Node3D
    var radar:=root.find_child(RADAR,true,false) as Node3D
    if turret==null or elevation==null or radar==null:
        return false
    var yaw:float=0.0
    if heading!=Vector2i.ZERO:
        yaw=rad_to_deg(atan2(float(heading.x),-float(heading.y)))
    match kind:
        "move":
            _wheel_pose(root,p)
            radar.rotation_degrees.x=-8.0
        "deploy","scan","aim","launch":
            var erected:float=smoothstep(0.0,0.75,p) if kind=="deploy" else 1.0
            elevation.rotation_degrees.x=12.0+34.0*erected
            radar.rotation_degrees.x=-8.0+8.0*erected
            turret.rotation_degrees.y=yaw if kind in ["aim","launch"] else 0.0
            if kind=="scan":
                radar.rotation_degrees.y=-65.0+130.0*p
            for side in [-1,1]:
                for at in [-1,1]:
                    var leg:=root.find_child(
                        "G14_Estabilizador_%d_%d" % [side,at],
                        true,false) as Node3D
                    if leg!=null:
                        leg.rotation_degrees.z=float(side)*(-18.0)*erected
            if kind=="launch":
                var index:int=clampi(int(floor(p*4.0)),0,TUBES-1)
                var local_p:float=fmod(p*4.0,1.0)
                var missile:=root.find_child(
                    "G14_MisilAnimado_%d" % index,true,false) as Node3D
                var flash:=root.find_child(
                    "G14_EscapeVisual_%d" % index,true,false) as Node3D
                if missile!=null:
                    missile.visible=local_p>0.13 and local_p<0.90 and p<0.99
                    missile.position.z=-1.60-1.65*local_p
                if flash!=null:
                    flash.visible=local_p>0.10 and local_p<0.42 and p<0.99
        "stow":
            elevation.rotation_degrees.x=46.0-34.0*p
            radar.rotation_degrees.x=-8.0*p
        "hit":
            root.rotation_degrees.z=sin(p*PI)*1.6
    root.set_meta("tarvoka_g14_v1_pose",kind)
    return true
