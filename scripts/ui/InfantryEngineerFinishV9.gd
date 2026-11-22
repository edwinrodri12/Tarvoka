extends RefCounted
class_name TarvokaInfantryEngineerFinishV9

# Native Godot 4.3 hero/tactical art. The engineer's V8 rig, identity,
# hinge animations and tactical stats remain untouched.
# V9 resolves flat stacked helmet shells, visually detached rifle hands,
# and dorsal equipment with no visible structural anchorage.
const FLAG := "tarvoka_engineer_helmet_grips_backpack_v9"
const HELMET := "V9_CascoContinuoBiselado"
const COLLAR := "V9_CuelloProtegidoContinuo"
const GRIP := "V9_GuanteContacto"
const LINK := "V9_AntebrazoHaciaEmpunadura"
const BACK := "V9_ArnesDorsalFijo"
const TOOL_GLOVE := "V9_GuanteTrabajoFijadoHerramienta"
const ROLE := "infantry_engineer"

static func _mat(color: Color, metal: float, rough: float,
        clearcoat: bool = false) -> StandardMaterial3D:
    var finish := StandardMaterial3D.new()
    finish.albedo_color=Color(color.r,color.g,color.b,1.0)
    finish.metallic=metal
    finish.roughness=rough
    finish.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    if clearcoat:
        finish.clearcoat_enabled=true
        finish.clearcoat=0.87
        finish.clearcoat_roughness=0.20
    return finish

static func _mesh(parent: Node3D, label: String, shape: Mesh,
        position: Vector3, paint: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.material_override=paint
    node.position=position
    parent.add_child(node)
    return node

static func _ball(parent: Node3D, label: String, position: Vector3,
        size: Vector3, paint: Material, hero: bool) -> MeshInstance3D:
    var sphere := SphereMesh.new()
    sphere.radius=0.5
    sphere.height=1.0
    sphere.radial_segments=16 if hero else 10
    sphere.rings=9 if hero else 6
    var node: MeshInstance3D=_mesh(parent,label,sphere,position,paint)
    node.scale=size
    return node

static func _box(parent: Node3D, label: String, position: Vector3,
        size: Vector3, paint: Material) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size=size
    return _mesh(parent,label,shape,position,paint)

# Continuous 360 shell with bottom and top caps. Not a one-sided helmet.
# The radius tapers toward the crown, rather than piling spheres and boxes.
static func _crown(parent: Node3D, paint: Material, hero: bool) -> MeshInstance3D:
    var rings: Array[Vector3]=[
        Vector3(0.17,0.135,0.185), Vector3(0.250,0.190,0.235),
        Vector3(0.282,0.300,0.272), Vector3(0.286,0.415,0.284),
        Vector3(0.252,0.525,0.253), Vector3(0.164,0.605,0.160),
        Vector3(0.060,0.636,0.055)
    ]
    var segments: int=18 if hero else 12
    var build := SurfaceTool.new()
    build.begin(Mesh.PRIMITIVE_TRIANGLES)
    for r in range(rings.size()-1):
        for i in range(segments):
            var a: float=TAU*float(i)/float(segments)
            var b: float=TAU*float(i+1)/float(segments)
            var lo: Vector3=rings[r]
            var hi: Vector3=rings[r+1]
            var a0 := Vector3(cos(a)*lo.x,lo.y,sin(a)*lo.z+0.006)
            var b0 := Vector3(cos(b)*lo.x,lo.y,sin(b)*lo.z+0.006)
            var a1 := Vector3(cos(a)*hi.x,hi.y,sin(a)*hi.z+0.006)
            var b1 := Vector3(cos(b)*hi.x,hi.y,sin(b)*hi.z+0.006)
            for point in [a0,a1,b0,b0,a1,b1]:
                build.add_vertex(point)
    var first: Vector3=rings[0]
    var last: Vector3=rings[-1]
    for i in range(segments):
        var a: float=TAU*float(i)/float(segments)
        var b: float=TAU*float(i+1)/float(segments)
        var low_a := Vector3(cos(a)*first.x,first.y,sin(a)*first.z+0.006)
        var low_b := Vector3(cos(b)*first.x,first.y,sin(b)*first.z+0.006)
        var high_a := Vector3(cos(a)*last.x,last.y,sin(a)*last.z+0.006)
        var high_b := Vector3(cos(b)*last.x,last.y,sin(b)*last.z+0.006)
        for point in [Vector3(0,first.y,0.006),low_a,low_b,
                Vector3(0,last.y,0.006),high_b,high_a]:
            build.add_vertex(point)
    build.generate_normals()
    return _mesh(parent,HELMET,build.commit(),Vector3.ZERO,paint)

static func _find(model: Node3D, part: String) -> Node3D:
    return model.find_child(part,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return (model!=null and bool(model.get_meta(FLAG,false)) and
        _find(model,HELMET)!=null and _find(model,GRIP+"_1")!=null and
        _find(model,GRIP+"_-1")!=null and _find(model,BACK+"_1")!=null)

# Right hand stays on the pistol grip, left on the forward handguard.
# In construction/work the right glove transfers to the moving wrench.
# Unlike static pseudo-hands, the arm-to-contact links are updated AFTER
# the native V2 attack/work/move pose, using the real sibling transforms.
static func _contact(side: int) -> Vector3:
    return (Vector3(-0.04,-0.225,-0.052) if side>0
        else Vector3(0.44,-0.155,-0.065))

static func sync(model: Node3D, kind: String="idle") -> bool:
    if not has_model(model):
        return false
    var gun: Node3D=_find(model,"ArmamentoRig")
    var tool: Node3D=_find(model,"V6_HerramientaArticuladaRig")
    var operating: bool=kind in ["work","repair","capture"]
    if gun==null or tool==null:
        return false
    var work_glove: Node3D=_find(model,TOOL_GLOVE)
    if work_glove!=null:
        work_glove.visible=operating
    # Individual original V9 digits are independent gun children. They MUST
    # disappear with the right glove when it transfers to the articulated
    # construction tool; V10 tool digits then appear in the moving tool rig.
    for finger in range(3):
        var work_digit: Node3D=_find(model,"V10_DedoHerramienta_%d"%finger)
        if work_digit!=null:
            work_digit.visible=operating
    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var glove: Node3D=_find(model,GRIP+"_%d"%side)
        var link: MeshInstance3D=_find(model,LINK+"_%d"%side) as MeshInstance3D
        if arm==null or glove==null or link==null:
            return false
        var working: bool=operating and side>0
        glove.visible=not working
        for finger in range(3):
            var rifle_digit: Node3D=_find(model,
                "V9_DedosCerrados_%d_%d"%[side,finger])
            if rifle_digit!=null:
                rifle_digit.visible=not working
        var contact_local: Vector3=(
            tool.transform*Vector3(0,-0.055,-0.048) if working
            else gun.transform*_contact(side))
        var position_in_arm: Vector3=arm.transform.affine_inverse()*contact_local
        var elbow := Vector3(0,-0.58,-0.10)
        var distance: Vector3=position_in_arm-elbow
        var length: float=maxf(0.075,distance.length())
        link.position=elbow+distance*0.5
        link.quaternion=Quaternion(Vector3.UP,
            distance.normalized() if distance.length()>0.0001 else Vector3.UP)
        link.scale=Vector3(1,length,1)
    model.set_meta("tarvoka_v9_hand_contact_pose",kind)
    return true

static func apply(model: Node3D, faction_color: Color, hero: bool) -> bool:
    if model==null or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!=ROLE or not bool(
            model.get_meta("tarvoka_infantry_engineer_premium_v8",false)):
        return false
    var head: Node3D=_find(model,"CabezaRig")
    var chest: Node3D=_find(model,"TorsoRig")
    var gun: Node3D=_find(model,"ArmamentoRig")
    var tool: Node3D=_find(model,"V6_HerramientaArticuladaRig")
    if head==null or chest==null or gun==null or tool==null:
        return false
    for side in [-1,1]:
        if _find(model,"BrazoRig_%d"%side)==null:
            return false

    var ceramic := _mat(Color("#899b9d"),0.32,0.42)
    var seam := _mat(Color("#273439"),0.05,0.86)
    var flexible := _mat(Color("#53695d"),0.02,0.93)
    var buckle := _mat(Color("#a7b9bc"),0.67,0.28)
    var optic := _mat(Color("#1c5874"),0.21,0.13,true)
    var faction := _mat(faction_color,0.14,0.38)

    # Preserve the original V5 construction brow and faction insignia.
    # Hide ONLY the V2 shell and redundant V7 box-visor/neck shell.
    for outdated in ["V2_CascoEsferoideCerrado",
            "V7_VisorIngenieroFrontal","V7_CollarSoldadoContinuo"]:
        var old: Node3D=_find(model,outdated)
        if old!=null:
            old.visible=false
    _crown(head,ceramic,hero)
    _ball(head,COLLAR,Vector3(0,0.045,0.030),
        Vector3(0.36,0.255,0.315),flexible,hero)
    _ball(head,"V9_BaseCollarBlindado",Vector3(0,0.022,-0.064),
        Vector3(0.40,0.135,0.275),ceramic,hero)
    _ball(head,"V9_VisorContinuoOpaco",Vector3(0,0.255,-0.270),
        Vector3(0.39,0.150,0.088),optic,hero)
    for side in [-1,1]:
        var x: float=float(side)
        _ball(head,"V9_CubiertaAuricularPerfil_%d"%side,
            Vector3(x*0.253,0.235,0.033),Vector3(0.111,0.210,0.215),
            seam,hero)
        _box(head,"V9_CierreNucaBajoCasco_%d"%side,
            Vector3(x*0.140,0.082,0.282),
            Vector3(0.098,0.068,0.042),buckle)
        if hero:
            _box(head,"V9_InsigniaLateralCasco_%d"%side,
                Vector3(x*0.293,0.327,-0.066),
                Vector3(0.020,0.075,0.120),faction)

    # Both palms are actually attached to the firearm and remain locked on
    # their real metal grips throughout 3D move / aim / attack animation.
    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var old_glove: Node3D=_find(model,"V2_PalmaGuante_%d"%side)
        if old_glove!=null:
            old_glove.visible=false
        for finger in range(4):
            var old_finger: Node3D=_find(model,
                "V2_DedoGuante_%d_%d"%[side,finger])
            if old_finger!=null:
                old_finger.visible=false
        var palm: MeshInstance3D=_ball(gun,GRIP+"_%d"%side,
            _contact(side),Vector3(0.165,0.18,0.185),seam,hero)
        palm.set_meta("contact_side",side)
        if hero:
            for i in range(3):
                _ball(gun,"V9_DedosCerrados_%d_%d"%[side,i],
                    _contact(side)+Vector3((float(i)-1.0)*0.047,
                        -0.078,-0.047),
                    Vector3(0.043,0.105,0.068),flexible,hero)
        var sleeve := CylinderMesh.new()
        sleeve.height=1.0
        sleeve.top_radius=0.086
        sleeve.bottom_radius=0.113
        sleeve.radial_segments=12 if hero else 8
        _mesh(arm,LINK+"_%d"%side,sleeve,
            Vector3(0,-0.65,-0.10),flexible)
        _ball(arm,"V9_CodoBlindado_%d"%side,Vector3(0,-0.53,-0.09),
            Vector3(0.22,0.23,0.20),ceramic,hero)

    _ball(tool,TOOL_GLOVE,Vector3(0,-0.055,-0.048),
        Vector3(0.165,0.18,0.185),seam,hero)
    var work_hand: Node3D=_find(model,TOOL_GLOVE)
    work_hand.visible=false

    # Side-mounted pouches and anchored load-bearing straps. Everything is
    # fixed on TorsoRig: the articulating rear shield swings independently.
    for side in [-1,1]:
        var x: float=float(side)
        _ball(chest,BACK+"_%d"%side,
            Vector3(x*0.315,-0.012,0.365),
            Vector3(0.085,0.68,0.145),flexible,hero)
        _ball(chest,"V9_BolsaHerramientasRig_%d"%side,
            Vector3(x*0.464,-0.245,0.302),
            Vector3(0.205,0.30,0.255),flexible,hero)
        _box(chest,"V9_TapaBolsaHerramientas_%d"%side,
            Vector3(x*0.463,-0.126,0.235),
            Vector3(0.18,0.059,0.10),ceramic)
        _box(chest,"V9_CierreBolsaFaccion_%d"%side,
            Vector3(x*0.466,-0.145,0.181),
            Vector3(0.107,0.042,0.021),faction)
        if hero:
            _box(chest,"V9_BrocheArnesFijo_%d"%side,
                Vector3(x*0.310,0.18,0.460),
                Vector3(0.11,0.08,0.038),buckle)
            _box(chest,"V9_RemacheBolsa_%d"%side,
                Vector3(x*0.467,-0.232,0.157),
                Vector3(0.037,0.035,0.022),buckle)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v9_art_only",true)
    model.set_meta("tarvoka_engineer_v9_hero",hero)
    return sync(model,"idle")
