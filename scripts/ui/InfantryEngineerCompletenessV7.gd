extends RefCounted
class_name TarvokaInfantryEngineerCompletenessV7

# A 360-degree completeness pass on the SAME approved Engineer character.
# The V2 closed helmet ends too high: the old peach skin sphere was visible
# across its entire REAR at eye level. Replace this with real opaque coverage.
# Art only, no class / game rules / gameplay physics changes.
const FLAG := "tarvoka_engineer_full_helmet_and_joint_closure_v7"
const ROLE := "infantry_engineer"
const REAR := "V7_CascoPosteriorCompletamenteCerrado"
const NAPE := "V7_NucaHermetica"
const MASK := "V7_MascaraResistenciaIngeniero"
const COLOR := "V7_IdentidadCascoPosterior"

static func _paint(tint: Color, metallic: float, rough: float,
        gloss: bool=false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color=Color(tint.r,tint.g,tint.b,1.0)
    m.metallic=metallic
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    if gloss:
        m.clearcoat_enabled=true
        m.clearcoat=0.72
        m.clearcoat_roughness=0.14
    return m

static func _ellipsoid(parent: Node3D, name: String, at: Vector3,
        dimensions: Vector3, mat: Material, detail: bool) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=16 if detail else 10
    mesh.rings=8 if detail else 5
    var part := MeshInstance3D.new()
    part.name=name
    part.mesh=mesh
    part.position=at
    part.scale=dimensions
    part.material_override=mat
    parent.add_child(part)
    return part

static func _piece(parent: Node3D, name: String, at: Vector3,
        dimensions: Vector3, mat: Material,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name=name
    var mesh := BoxMesh.new()
    mesh.size=dimensions
    part.mesh=mesh
    part.material_override=mat
    part.position=at
    part.rotation_degrees=rot
    parent.add_child(part)
    return part

static func _find(model: Node3D, part: String) -> Node3D:
    return model.find_child(part,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return (model!=null and bool(model.get_meta(FLAG,false)) and
        _find(model,REAR)!=null and _find(model,NAPE)!=null)

static func apply(model: Node3D, role: String, faction: Color,
        hero: bool) -> bool:
    if model==null or role!=ROLE or has_model(model):
        return false
    if not bool(model.get_meta("tarvoka_infantry_engineer_finish_v6",false)):
        return false
    var head: Node3D=_find(model,"CabezaRig")
    var torso: Node3D=_find(model,"TorsoRig")
    if head==null or torso==null:
        return false
    for side in [-1,1]:
        if (_find(model,"PiernaRig_%d"%side)==null or
                _find(model,"BrazoRig_%d"%side)==null):
            return false
    var armor := _paint(Color("#798d8b"),0.28,0.44)
    var alloy := _paint(Color("#a0b0b2"),0.51,0.33)
    var rubber := _paint(Color("#27343a"),0.04,0.80)
    var cloth := _paint(Color("#4b6056"),0.03,0.89)
    var faction_mat := _paint(faction,0.14,0.42)
    var optic := _paint(Color("#184c67"),0.17,0.13,true)

    # Hide ONLY the Engineer's exposed bare scalp and cheek prototypes.
    # The original V2 helmet upper shell, brow and visor remain present.
    for name in ["Cabeza","V2_Mejilla_-1","V2_Mejilla_1"]:
        var former: Node3D=_find(head,name)
        if former!=null:
            former.visible=false

    # Closed posterior cranium extends BELOW the original V2 shell.
    # Mesh geometry is volumetric, sealed and visible from ALL 360 degrees.
    _ellipsoid(head,REAR,Vector3(0,0.26,0.177),
        Vector3(0.48,0.50,0.39),armor,hero)
    _ellipsoid(head,NAPE,Vector3(0,0.095,0.205),
        Vector3(0.38,0.245,0.29),rubber,hero)
    _piece(head,"V7_CollarSoldadoContinuo",Vector3(0,-0.018,0.075),
        Vector3(0.41,0.125,0.33),cloth)
    _piece(head,MASK,Vector3(0,0.12,-0.286),
        Vector3(0.35,0.21,0.095),rubber)
    _piece(head,"V7_FiltroCentralRespirador",Vector3(0,0.115,-0.349),
        Vector3(0.16,0.105,0.038),alloy)
    _piece(head,"V7_VisorIngenieroFrontal",Vector3(0,0.254,-0.318),
        Vector3(0.395,0.115,0.031),optic)
    _piece(head,COLOR,Vector3(0,0.437,0.376),
        Vector3(0.32,0.075,0.033),faction_mat)

    for side in [-1,1]:
        var x: float=float(side)
        _ellipsoid(head,"V7_ProteccionOido_%d"%side,
            Vector3(x*0.254,0.205,0.067),
            Vector3(0.13,0.29,0.27),rubber,hero)
        _piece(head,"V7_SelloLateral_%d"%side,
            Vector3(x*0.22,0.085,-0.179),
            Vector3(0.095,0.19,0.18),armor)
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var leg: Node3D=_find(model,"PiernaRig_%d"%side)
        _ellipsoid(arm,"V7_HombroArticulado_%d"%side,
            Vector3(0,0.005,-0.04),Vector3(0.315,0.245,0.32),
            armor,hero)
        _ellipsoid(leg,"V7_RodilleraCerrarHueco_%d"%side,
            Vector3(0,-0.48,-0.17),Vector3(0.23,0.21,0.115),
            armor,hero)
        _ellipsoid(leg,"V7_PunteraBotaReforzada_%d"%side,
            Vector3(0,-0.868,-0.27),Vector3(0.24,0.14,0.215),
            rubber,hero)
        if hero:
            _piece(arm,"V7_PlacaHombroFaccion_%d"%side,
                Vector3(x*0.163,-0.02,-0.105),
                Vector3(0.025,0.11,0.20),faction_mat)
            _piece(leg,"V7_ClipRodillera_%d"%side,
                Vector3(0,-0.47,-0.243),
                Vector3(0.16,0.038,0.025),alloy)

    # The articulated V6 tool remains independent. This body-side keeper
    # visibly anchors its default storage point without blocking the motion.
    _piece(torso,"V7_FundaFijaHerramientaDeIngeniero",
        Vector3(0.45,-0.43,-0.27),Vector3(0.17,0.23,0.18),cloth)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_closure_visual_only",true)
    model.set_meta("tarvoka_engineer_closure_hero",hero)
    return true
