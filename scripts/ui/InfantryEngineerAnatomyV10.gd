extends RefCounted
class_name TarvokaInfantryEngineerAnatomyV10

# Physical native art corrections observed in V9 Godot screenshots:
# overly cylindrical forearm links, oversized slab-like shoulders, and
# fingers remaining on the gun while the right hand holds the wrench.
# NO gameplay, class/camp, stats, cover, attack or collision changes.
const FLAG := "tarvoka_engineer_anatomy_v10"
const LINK := "V9_AntebrazoHaciaEmpunadura"
const TOOL_FINGER := "V10_DedoHerramienta_"
const SIDE_PLATE := "V10_CorazaCostalAnatomica"
const ROLE := "infantry_engineer"

static func _mat(color: Color, metallic: float=0.04,
        rough: float=0.81) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color=Color(color.r,color.g,color.b,1.0)
    m.metallic=metallic
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    return m

static func _ball(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, finish: Material, hero: bool) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=14 if hero else 9
    mesh.rings=8 if hero else 5
    var shape := MeshInstance3D.new()
    shape.name=label
    shape.mesh=mesh
    shape.material_override=finish
    shape.position=pos
    shape.scale=size
    parent.add_child(shape)
    return shape

static func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return (model!=null and bool(model.get_meta(FLAG,false)) and
        _find(model,TOOL_FINGER+"0")!=null and
        _find(model,SIDE_PLATE+"_1")!=null)

static func apply(model: Node3D, faction: Color, hero: bool) -> bool:
    if model==null or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!=ROLE or not bool(
            model.get_meta("tarvoka_engineer_helmet_grips_backpack_v9",false)):
        return false
    var chest: Node3D=_find(model,"TorsoRig")
    var gun: Node3D=_find(model,"ArmamentoRig")
    var tool: Node3D=_find(model,"V6_HerramientaArticuladaRig")
    var tool_glove: Node3D=_find(model,"V9_GuanteTrabajoFijadoHerramienta")
    if chest==null or gun==null or tool==null or tool_glove==null:
        return false
    for side in [-1,1]:
        if (_find(model,LINK+"_%d"%side)==null or
                _find(model,"V9_GuanteContacto_%d"%side)==null or
                _find(model,"BrazoRig_%d"%side)==null):
            return false

    var fabric := _mat(Color("#43564c"),0.02,0.94)
    var armor := _mat(Color("#859a9b"),0.30,0.41)
    var rubber := _mat(Color("#263438"),0.02,0.86)
    var paint := _mat(faction,0.17,0.39)

    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var link: MeshInstance3D=_find(model,LINK+"_%d"%side) as MeshInstance3D
        var glove: Node3D=_find(model,"V9_GuanteContacto_%d"%side)
        var old_shoulder: MeshInstance3D=_find(model,
            "V8_HombreraAnatomica_%d"%side) as MeshInstance3D
        # Preserve the dynamically updated V9 transform/physics-free linkage.
        # Only the cylinder cross section changes, tapering naturally from
        # armored elbow (R=.071) toward wrist (R=.050).
        var sleeve := CylinderMesh.new()
        sleeve.height=1.0
        sleeve.top_radius=0.050
        sleeve.bottom_radius=0.071
        sleeve.radial_segments=14 if hero else 8
        link.mesh=sleeve
        link.material_override=fabric
        if old_shoulder!=null:
            old_shoulder.scale=Vector3(0.338,0.310,0.329)

        _ball(arm,"V10_CodoSellado_%d"%side,
            Vector3(0,-0.55,-0.08),Vector3(0.195,0.205,0.195),
            rubber,hero)
        _ball(arm,"V10_CubiertaCodo_%d"%side,
            Vector3(0,-0.515,-0.173),Vector3(0.190,0.165,0.065),
            armor,hero)
        # Parent to the same real gun rig, not the already SCALED palm mesh:
        # otherwise a 14cm cuff inherits the 0.165 glove scale and shrinks
        # into an invisible two-centimeter rivet. V9.sync handles visibility.
        var grip_position: Vector3=(
            Vector3(-0.04,-0.225,-0.052) if side>0
            else Vector3(0.44,-0.155,-0.065))
        var rifle_cuff: MeshInstance3D=_ball(
            gun,"V10_MunecaContactoFusil_%d"%side,
            grip_position+Vector3(0,0.065,0.028),
            Vector3(0.140,0.145,0.150),rubber,hero)
        rifle_cuff.visible=true
        # Closed curved side profile lowers the cuboid tactical silhouette,
        # without removing the approved blue construction harness.
        _ball(chest,SIDE_PLATE+"_%d"%side,
            Vector3(float(side)*0.315,-0.095,-0.245),
            Vector3(0.145,0.355,0.165),armor,hero)
        _ball(chest,"V10_SelloCostillas_%d"%side,
            Vector3(float(side)*0.275,-0.19,-0.14),
            Vector3(0.128,0.225,0.135),fabric,hero)
        if hero:
            _ball(chest,"V10_MarcadorCostadoFaccion_%d"%side,
                Vector3(float(side)*0.375,0.020,-0.290),
                Vector3(0.045,0.115,0.048),paint,hero)

    # Replace the floating-finger illusion: the gun's three right digits
    # now hide whenever V9 sync moves its palm onto the tool. Three new
    # physical fingers instead follow the wrench's actual 3D pivot.
    for i in range(3):
        var finger: MeshInstance3D=_ball(tool,TOOL_FINGER+str(i),
            Vector3((float(i)-1.0)*0.046,-0.082,-0.105),
            Vector3(0.045,0.123,0.057),fabric,hero)
        finger.visible=false
    # Tool cuff lives directly on the animated wrench pivot for correct
    # physical proportions; it is never scaled down by its palm mesh.
    var work_cuff: MeshInstance3D=_ball(
        tool,"V10_MunecaContactoHerramienta",
        Vector3(0,0.013,-0.020),Vector3(0.140,0.145,0.150),
        rubber,hero)
    work_cuff.visible=false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v10_art_only",true)
    model.set_meta("tarvoka_engineer_v10_hero",hero)
    return true
