extends RefCounted
class_name TarvokaInfantryEngineerFinishV6

# Native Godot 4.3 art-only finish. No barrier collision, defensive bonuses,
# new camp orders, repair mechanics or tactical class changes.
# V5 is retained as the editable comparison source but hidden by the V6 rig.
const FLAG := "tarvoka_infantry_engineer_finish_v6"
const ROLE := "infantry_engineer"
const RIG := "V6_BarreraArticuladaRig"
const PANEL := "V6_PlacaPrincipalDeAcero"
const COLOR := "V6_IdentidadFaccionBarrera"
const TOOL := "V6_HerramientaArticuladaRig"
const WINGS := ["V6_AlaIzquierdaRig", "V6_AlaDerechaRig"]
const V5_HIDDEN := [
    "V5_BarreraPlegadaIngeniero", "V5_FaccionBarreraIngeniero",
    "V5_AlaBarreraIngeniero_-1", "V5_AlaBarreraIngeniero_1",
    "V5_SujecionBarreraIngeniero_-1", "V5_SujecionBarreraIngeniero_1",
    "V5_BisagraIngeniero_-1", "V5_BisagraIngeniero_1",
    "V5_CierreObraIngeniero"
]

static func _mat(tint: Color, metal: float = 0.05, rough: float = 0.72) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(tint.r,tint.g,tint.b,1.0)
    m.metallic = metal
    m.roughness = rough
    m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    return m

static func _joint(parent: Node3D, label: String, at: Vector3) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = at
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, at: Vector3,
        dimensions: Vector3, paint: Material,
        degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = at
    node.rotation_degrees = degrees
    node.material_override = paint
    parent.add_child(node)
    return node

static func _pin(parent: Node3D, label: String, at: Vector3, height: float,
        radius: float, paint: Material, degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 10
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = at
    node.rotation_degrees = degrees
    node.material_override = paint
    parent.add_child(node)
    return node

static func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG,false)) and _find(model,RIG)!=null

static func apply(model: Node3D, role: String, faction_color: Color, hero: bool) -> bool:
    if model==null or role!=ROLE or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!=ROLE or \
            not bool(model.get_meta("tarvoka_infantry_engineer_silhouette_v5",false)):
        return false
    var chest: Node3D=_find(model,"TorsoRig")
    if chest==null:
        return false
    var faction: StandardMaterial3D=_mat(faction_color,0.13,0.43)
    var enamel: StandardMaterial3D=_mat(Color("#71878a"),0.48,0.36)
    var steel: StandardMaterial3D=_mat(Color("#9eabb0"),0.58,0.27)
    var dark: StandardMaterial3D=_mat(Color("#273338"),0.12,0.72)
    var rubber: StandardMaterial3D=_mat(Color("#252f31"),0.02,0.90)
    var seam: StandardMaterial3D=_mat(Color("#445b55"),0.04,0.86)

    # Replace static V5 rear board with the same silhouette on a real hinge.
    # Grouping both wings with the central plate prevents floating components
    # when inspecting the model from above, below, front and back.
    var pivot: Node3D=_joint(chest,RIG,Vector3(0,0.10,0.55))
    _box(pivot,PANEL,Vector3(0,0,0.13),Vector3(1.12,0.68,0.12),enamel)
    _box(pivot,"V6_CostraBlindajeExterior",Vector3(0,-0.045,0.206),
        Vector3(0.93,0.45,0.037),dark)
    _box(pivot,COLOR,Vector3(0,0.145,0.219),
        Vector3(0.80,0.18,0.045),faction)
    _box(pivot,"V6_CintaInteriorIdentidad",Vector3(0,0.11,0.058),
        Vector3(0.62,0.12,0.032),faction)
    for side in [-1,1]:
        var edge: float=float(side)
        var wing: Node3D=_joint(pivot,WINGS[0] if side<0 else WINGS[1],
            Vector3(edge*0.56,0,0.10))
        _box(wing,"V6_AlaMetal_%d"%side,Vector3(edge*0.08,-0.015,0),
            Vector3(0.18,0.70,0.11),dark)
        _box(wing,"V6_CantoGoma_%d"%side,Vector3(edge*0.17,-0.015,0.015),
            Vector3(0.038,0.71,0.12),rubber)
        _box(wing,"V6_BandaFaccionAla_%d"%side,
            Vector3(edge*0.08,0.16,0.067),Vector3(0.13,0.16,0.029),faction)
        _box(pivot,"V6_RielSoldado_%d"%side,Vector3(edge*0.42,-0.13,0.212),
            Vector3(0.055,0.30,0.027),steel)
        # Back straps physically attach to the folded metal plate.
        _box(pivot,"V6_CinchaAnclada_%d"%side,
            Vector3(edge*0.37,-0.14,0.044),Vector3(0.11,0.36,0.08),seam)
        if hero:
            _pin(pivot,"V6_PernoBisagra_%d"%side,
                Vector3(edge*0.50,0.33,0.13),0.13,0.054,
                steel,Vector3(90,0,0))
            for i in range(2):
                _pin(pivot,"V6_Remache_%d_%d"%[side,i],
                    Vector3(edge*0.43,-0.07-float(i)*0.20,0.23),
                    0.036,0.027,steel,Vector3(90,0,0))
            _box(pivot,"V6_CantoneraAcero_%d"%side,
                Vector3(edge*0.47,0.305,0.20),
                Vector3(0.15,0.08,0.05),steel)

    # Front tool is separate and articulated; the existing engineer rifle,
    # arms, work animation and V5 construction identity are not replaced.
    var tool: Node3D=_joint(chest,TOOL,Vector3(0.45,-0.29,-0.36))
    _box(tool,"V6_EmpunaduraHerramienta",Vector3.ZERO,
        Vector3(0.09,0.34,0.10),rubber)
    _box(tool,"V6_CabezalLlave",Vector3(0,0.20,-0.02),
        Vector3(0.18,0.09,0.07),steel)
    if hero:
        _box(tool,"V6_DedosLlave_-1",Vector3(-0.09,0.255,-0.02),
            Vector3(0.05,0.12,0.065),steel)
        _box(tool,"V6_DedosLlave_1",Vector3(0.09,0.255,-0.02),
            Vector3(0.05,0.12,0.065),steel)
        _box(tool,"V6_IndicadorEmpunadura",Vector3(0,-0.07,-0.058),
            Vector3(0.065,0.13,0.015),faction)
        _box(pivot,"V6_JuntaSuperior",Vector3(0,0.34,0.125),
            Vector3(0.96,0.045,0.06),rubber)
        _box(pivot,"V6_CierreCentral",Vector3(0,-0.28,0.229),
            Vector3(0.32,0.11,0.055),steel)

    # Damage is presentation only and follows existing native D0-D4.
    var scratch: MeshInstance3D=_box(pivot,"V6_RayonesD2",
        Vector3(0.12,-0.07,0.232),Vector3(0.39,0.026,0.022),
        _mat(Color("#463d3a"),0.08,0.86),Vector3(0,0,-22))
    scratch.visible=false
    var dent: MeshInstance3D=_box(pivot,"V6_FracturaD3",
        Vector3(-0.24,-0.18,0.240),Vector3(0.18,0.18,0.029),
        _mat(Color("#45322f"),0.06,0.89),Vector3(0,0,25))
    dent.visible=false

    for name in V5_HIDDEN:
        var old: Node3D=_find(model,name)
        if old!=null:
            old.visible=false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_infantry_engineer_v6_hero",hero)
    model.set_meta("tarvoka_infantry_engineer_visual_only",true)
    reset(model)
    return true

static func reset(model: Node3D) -> bool:
    return pose(model,"reset",0.0)

static func sync_damage(model: Node3D) -> void:
    if not has_model(model):
        return
    var stage: int=int(model.get_meta("tarvoka_infantry_damage",0))
    var scratch: Node3D=_find(model,"V6_RayonesD2")
    var dent: Node3D=_find(model,"V6_FracturaD3")
    if scratch!=null:
        scratch.visible=stage>=2
    if dent!=null:
        dent.visible=stage>=3

static func pose(model: Node3D, kind: String, progress: float) -> bool:
    if not has_model(model):
        return false
    if kind not in ["reset","inspect","work","repair","capture",
            "move","idle","aim","attack","damage","damaged",
            "hit_bullet","hit_explosive"]:
        return false
    var panel: Node3D=_find(model,RIG)
    var tool: Node3D=_find(model,TOOL)
    var left: Node3D=_find(model,WINGS[0])
    var right: Node3D=_find(model,WINGS[1])
    if panel==null or tool==null or left==null or right==null:
        return false
    var t: float=clampf(progress,0.0,1.0)
    var inspect: float=t if kind=="inspect" else 0.0
    # Swivel of the folded, inert display equipment: never creates a fort.
    panel.rotation_degrees.x=-54.0*inspect
    left.rotation_degrees.y=-33.0*inspect
    right.rotation_degrees.y=33.0*inspect
    tool.rotation_degrees=Vector3.ZERO
    if kind in ["work","repair","capture"]:
        var stroke: float=sin(t*PI*2.0)
        tool.rotation_degrees.z=22.0+17.0*stroke
        tool.rotation_degrees.x=-12.0+6.0*stroke
        panel.rotation_degrees.x=-8.0*maxf(0.0,sin(t*PI))
    sync_damage(model)
    model.set_meta("tarvoka_infantry_engineer_v6_inspection",kind=="inspect")
    return true
