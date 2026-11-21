extends RefCounted
class_name TarvokaInfantryFamilyV1

# First native, editable infantry FAMILY. Geometry only: no balance, combat,
# fog, capture, economy, ammunition, or save-format modifications.
# line = G01, scout = G03. All infantry_* options are STUDIO-ONLY previews.
const ROLES := [
    "line", "infantry_urban", "infantry_defense",
    "scout", "infantry_antitank", "infantry_engineer",
    "infantry_sniper", "infantry_logistic", "infantry_medic",
    "infantry_commando"
]
const FLAG := "tarvoka_infantry_family_v1"
const UNIFORM := Color("#596a65")
const CLOTH := Color("#45554d")
const PLATE := Color("#6d807f")
const RUBBER := Color("#1d292d")
const STEEL := Color("#8c9da3")
const GLASS := Color("#254d64")
const SKIN := Color("#bd9275")
const DAMAGE := Color("#47352f")

static func supports(role: String) -> bool:
    return role in ROLES

static func _mat(color: Color, metallic: float = 0.08, roughness: float = 0.66) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    var opaque: Color = color
    opaque.a = 1.0
    mat.albedo_color = opaque
    mat.metallic = metallic
    mat.roughness = roughness
    mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    return mat

static func _box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3,
        color: Color, rotation: Vector3 = Vector3.ZERO,
        metal: float = 0.08) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.material_override = _mat(color,metal)
    node.position = at
    node.rotation_degrees = rotation
    parent.add_child(node)
    return node

static func _sphere(parent: Node3D, label: String, at: Vector3,
        dimensions: Vector3, color: Color, metal: float = 0.05) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 12
    mesh.rings = 6
    node.mesh = mesh
    node.scale = dimensions
    node.position = at
    node.material_override = _mat(color,metal)
    parent.add_child(node)
    return node

static func _cylinder(parent: Node3D, label: String, at: Vector3,
        radius: float, height: float, color: Color,
        rotation: Vector3 = Vector3.ZERO, sides: int = 10) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = maxi(6,sides)
    node.mesh = mesh
    node.material_override = _mat(color,0.22)
    node.position = at
    node.rotation_degrees = rotation
    parent.add_child(node)
    return node

static func _joint(parent: Node3D, label: String, at: Vector3) -> Node3D:
    var joint := Node3D.new()
    joint.name = label
    joint.position = at
    parent.add_child(joint)
    return joint

static func _rifle(parent: Node3D, short_weapon: bool, accent: Color) -> void:
    var length: float = 0.53 if short_weapon else 0.75
    _box(parent,"ReceptorFusil",Vector3.ZERO,Vector3(0.44,0.14,0.15),RUBBER)
    _box(parent,"CulataFusil",Vector3(-0.36,0.0,0.01),Vector3(0.28,0.15,0.14),PLATE)
    _cylinder(parent,"CanonFusil",Vector3(0.27+length*0.5,0.01,0.0),
        0.042,length,RUBBER,Vector3(0,0,90))
    _box(parent,"CargadorFusil",Vector3(-0.04,-0.16,0.0),
        Vector3(0.13,0.23,0.12),RUBBER,Vector3(0,0,-12))
    _box(parent,"OpticaFusil",Vector3(0.04,0.135,0.0),
        Vector3(0.23,0.09,0.13),STEEL)
    _sphere(parent,"LenteOptica",Vector3(0.17,0.14,-0.003),
        Vector3(0.06,0.052,0.08),GLASS)
    _box(parent,"FaccionMarcadorFusil",Vector3(-0.11,0.083,-0.082),
        Vector3(0.21,0.045,0.012),accent)

static func _launcher(parent: Node3D, accent: Color) -> void:
    _cylinder(parent,"LanzadorAntiblindaje",Vector3(0.19,0.09,0.0),
        0.145,1.28,PLATE,Vector3(0,0,90),14)
    _cylinder(parent,"TuboInteriorSellado",Vector3(0.86,0.09,0.0),
        0.115,0.08,RUBBER,Vector3(0,0,90),14)
    _box(parent,"CunaLanzador",Vector3(0.16,-0.10,0.0),
        Vector3(0.45,0.12,0.18),RUBBER)
    _box(parent,"OpticaLanzador",Vector3(-0.10,0.27,0.0),
        Vector3(0.26,0.12,0.14),GLASS)
    _box(parent,"FaccionAnilloLanzador",Vector3(0.52,0.09,0.0),
        Vector3(0.10,0.31,0.31),accent)

static func build(model: Node3D, role: String, faction_color: Color,
        hero: bool = true) -> bool:
    if model == null or not supports(role):
        return false
    if bool(model.get_meta(FLAG,false)):
        return false
    var accent: Color = faction_color
    accent.a = 1.0
    var soldier := _joint(model,"Infanteria_3D",Vector3.ZERO)
    var hips := _joint(soldier,"CaderaRig",Vector3(0,1.00,0))
    _sphere(hips,"CinturaEquipo",Vector3.ZERO,Vector3(0.60,0.25,0.33),CLOTH)
    _box(hips,"FaccionCinturon",Vector3(0,0,-0.183),
        Vector3(0.37,0.075,0.035),accent)
    for side in [-1,1]:
        var x: float = float(side)*0.205
        var leg := _joint(hips,"PiernaRig_%d" % side,Vector3(x,-0.05,0))
        _sphere(leg,"Muslo_%d" % side,Vector3(0,-0.23,0.02),
            Vector3(0.255,0.53,0.29),UNIFORM)
        _box(leg,"BolsilloPierna_%d" % side,Vector3(float(side)*0.12,-0.26,-0.01),
            Vector3(0.075,0.20,0.20),CLOTH)
        _sphere(leg,"Espinillera_%d" % side,Vector3(0,-0.63,-0.035),
            Vector3(0.22,0.47,0.25),PLATE)
        _box(leg,"Rodillera_%d" % side,Vector3(0,-0.48,-0.15),
            Vector3(0.22,0.16,0.068),RUBBER)
        _box(leg,"Bota_%d" % side,Vector3(0,-0.885,-0.095),
            Vector3(0.23,0.22,0.40),RUBBER)
        if hero:
            _box(leg,"HebillaBota_%d" % side,Vector3(0,-0.81,-0.302),
                Vector3(0.18,0.055,0.024),STEEL,Vector3.ZERO,0.38)
    var upper := _joint(soldier,"TorsoRig",Vector3(0,1.46,0))
    _sphere(upper,"PetoBase",Vector3.ZERO,Vector3(0.76,0.83,0.42),CLOTH)
    _box(upper,"CorazaFrontal",Vector3(0,0.012,-0.255),
        Vector3(0.60,0.54,0.095),PLATE)
    _box(upper,"PanelAbdominal",Vector3(0,-0.29,-0.207),
        Vector3(0.53,0.16,0.11),RUBBER)
    _box(upper,"FaccionPecho",Vector3(0,0.25,-0.309),
        Vector3(0.50,0.13,0.025),accent)
    _box(upper,"FaccionDorsal",Vector3(0,0.18,0.247),
        Vector3(0.54,0.12,0.029),accent)
    _box(upper,"MochilaRigida",Vector3(0,0.02,0.36),
        Vector3(0.54,0.67,0.27),RUBBER)
    _box(upper,"FaccionMochila",Vector3(0,-0.17,0.509),
        Vector3(0.43,0.14,0.030),accent)
    if hero:
        for i in range(3):
            _box(upper,"CinchaMOLLE_%02d" % i,
                Vector3(0,0.13-float(i)*0.14,-0.323),
                Vector3(0.49,0.026,0.023),STEEL)
        for side in [-1,1]:
            _box(upper,"BolsaCostado_%d" % side,
                Vector3(float(side)*0.32,-0.19,0.15),
                Vector3(0.15,0.28,0.24),UNIFORM)
    for side in [-1,1]:
        var x: float = float(side)*0.44
        var arm := _joint(upper,"BrazoRig_%d" % side,Vector3(x,0.265,0))
        arm.rotation_degrees.z = float(side)*-8.0
        _sphere(arm,"Manga_%d" % side,Vector3(float(side)*0.01,-0.22,0.005),
            Vector3(0.27,0.48,0.32),UNIFORM)
        _box(arm,"Hombrera_%d" % side,Vector3(0,-0.02,-0.05),
            Vector3(0.34,0.21,0.32),PLATE)
        _box(arm,"FaccionHombro_%d" % side,
            Vector3(float(side)*0.165,-0.024,-0.045),
            Vector3(0.027,0.22,0.22),accent)
        _sphere(arm,"Antebrazo_%d" % side,Vector3(0,-0.54,-0.09),
            Vector3(0.22,0.42,0.26),CLOTH)
        _sphere(arm,"Guante_%d" % side,Vector3(0,-0.78,-0.12),
            Vector3(0.21,0.17,0.23),RUBBER)
    var head := _joint(upper,"CabezaRig",Vector3(0,0.48,0))
    _cylinder(head,"CuelloProtegido",Vector3(0,0.038,0),
        0.145,0.17,UNIFORM)
    _sphere(head,"Cabeza",Vector3(0,0.24,-0.01),Vector3(0.40,0.43,0.40),SKIN)
    _sphere(head,"CascoSolido",Vector3(0,0.37,0.025),
        Vector3(0.55,0.39,0.52),PLATE)
    _box(head,"ViseraBlindada",Vector3(0,0.37,-0.28),
        Vector3(0.51,0.09,0.12),RUBBER)
    _box(head,"VisorSellado",Vector3(0,0.22,-0.231),
        Vector3(0.37,0.15,0.075),GLASS)
    _box(head,"FaccionCasco",Vector3(0,0.57,-0.05),
        Vector3(0.37,0.045,0.29),accent)
    if hero:
        for side in [-1,1]:
            _sphere(head,"Orejeras_%d" % side,
                Vector3(float(side)*0.277,0.26,0.0),
                Vector3(0.08,0.20,0.20),RUBBER)
        _box(head,"Barbiquejo",Vector3(0,0.06,-0.20),
            Vector3(0.22,0.055,0.06),RUBBER)
    var weapon := _joint(upper,"ArmamentoRig",Vector3(0.23,-0.09,-0.48))
    weapon.rotation_degrees = Vector3(0,-16,7)
    if role == "infantry_antitank":
        weapon.position = Vector3(0.13,0.23,-0.47)
        weapon.rotation_degrees = Vector3(0,-10,-10)
        _launcher(weapon,accent)
        _cylinder(upper,"ContenedorMunicionAT",Vector3(0.35,-0.17,0.46),
            0.115,0.56,RUBBER,Vector3(90,0,0))
    elif role == "infantry_engineer":
        _rifle(weapon,true,accent)
        _box(upper,"CajaHerramientas",Vector3(-0.34,-0.25,0.35),
            Vector3(0.32,0.28,0.28),STEEL)
        _box(upper,"FaccionBotiquinIngenieria",Vector3(-0.34,-0.25,0.499),
            Vector3(0.24,0.10,0.018),accent)
        _cylinder(upper,"HerramientaPlegada",Vector3(0.37,-0.16,0.32),
            0.035,0.58,STEEL,Vector3(25,0,18))
    else:
        _rifle(weapon,role in ["infantry_urban","scout",
            "infantry_logistic","infantry_medic","infantry_commando"],accent)
    if role == "scout":
        for side in [-1,1]:
            _cylinder(head,"OpticaExploracion_%d" % side,
                Vector3(float(side)*0.14,0.45,-0.32),
                0.075,0.23,RUBBER,Vector3(90,0,0))
            _sphere(head,"LenteExploracion_%d" % side,
                Vector3(float(side)*0.14,0.45,-0.44),
                Vector3(0.12,0.12,0.06),GLASS)
        _cylinder(upper,"AntenaExplorador",Vector3(0.23,0.46,0.39),
            0.025,0.69,STEEL)
    elif role == "infantry_urban":
        _box(upper,"EscudoUrbanoPlegado",Vector3(-0.34,-0.10,-0.39),
            Vector3(0.43,0.68,0.095),STEEL,Vector3(0,10,-8))
        _box(upper,"FaccionEscudoUrbano",Vector3(-0.34,0.11,-0.447),
            Vector3(0.31,0.13,0.025),accent,Vector3(0,10,-8))
        _box(head,"ProteccionMandibula",Vector3(0,0.06,-0.247),
            Vector3(0.40,0.16,0.095),RUBBER)
    elif role == "infantry_defense":
        _box(upper,"ProteccionTorno",Vector3(0,-0.09,-0.38),
            Vector3(0.67,0.53,0.13),STEEL)
        _box(upper,"FaccionBlindajeDefensivo",Vector3(0,-0.05,-0.457),
            Vector3(0.52,0.12,0.018),accent)
        _box(head,"VisorCascoReforzado",Vector3(0,0.20,-0.294),
            Vector3(0.48,0.23,0.09),RUBBER)
    # Historic V1 compare view: physical silhouettes for the four missing
    # agreed designs, without changing tactical combat or camp rules.
    if role=="infantry_sniper":
        _cylinder(weapon,"MiraPrecisionBase",Vector3(0.22,0.23,0),
            0.07,0.43,GLASS,Vector3(0,0,90))
        _cylinder(weapon,"CanonPrecisionBase",Vector3(1.07,0,0),
            0.035,0.24,STEEL,Vector3(0,0,90))
    elif role=="infantry_logistic":
        _box(upper,"CargaLogisticaBase",Vector3(0,0.02,0.54),
            Vector3(0.64,0.62,0.29),CLOTH)
    elif role=="infantry_medic":
        _box(upper,"BotiquinMedicoBase",Vector3(-0.32,-0.09,0.51),
            Vector3(0.36,0.45,0.19),CLOTH)
        _box(upper,"IdentificadorMedicoBase",Vector3(-0.32,0.04,0.626),
            Vector3(0.25,0.075,0.028),accent)
    elif role=="infantry_commando":
        _box(head,"OpticaComandoBase",Vector3(0,0.425,-0.325),
            Vector3(0.37,0.13,0.17),GLASS)
        _cylinder(upper,"AntenaComandoBase",Vector3(0.27,0.44,0.35),
            0.019,0.51,STEEL)
    # Physical, opaque impact marks exist in all LODs. Each remains hidden
    # until the Studio damage state explicitly reveals its numbered stage.
    var impacts := _joint(upper,"DaniosFisicos",Vector3.ZERO)
    for stage in range(1,5):
        var chip := _box(impacts,"Impacto_%d" % stage,
            Vector3(-0.20+float(stage)*0.07,0.13-float(stage)*0.13,-0.326),
            Vector3(0.12+float(stage)*0.035,0.031,0.024),DAMAGE,
            Vector3(0,0,-28+stage*14))
        chip.set_meta("min_damage_stage",stage)
        chip.visible = false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_infantry_role",role)
    model.set_meta("tarvoka_infantry_visual_only",true)
    model.set_meta("tarvoka_infantry_lod",13 if hero else 8)
    model.set_meta("tarvoka_infantry_color",accent.to_html(false))
    return true

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG,false))

static func set_damage(model: Node3D, stage: int) -> bool:
    if not has_model(model):
        return false
    var level: int = clampi(stage,0,4)
    var impacts: Node3D = model.find_child("DaniosFisicos",true,false) as Node3D
    if impacts == null:
        return false
    for chip in impacts.get_children():
        if chip is MeshInstance3D:
            chip.visible = int(chip.get_meta("min_damage_stage",5)) <= level
    model.set_meta("tarvoka_infantry_damage",level)
    return true

static func damage_stage(model: Node3D) -> int:
    return int(model.get_meta("tarvoka_infantry_damage",0)) if has_model(model) else -1

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    var soldier: Node3D = model.find_child("Infanteria_3D",true,false) as Node3D
    if soldier == null:
        return
    soldier.position = Vector3.ZERO
    soldier.rotation_degrees = Vector3.ZERO
    for name in ["TorsoRig","CabezaRig","ArmamentoRig","PiernaRig_-1",
            "PiernaRig_1","BrazoRig_-1","BrazoRig_1"]:
        var part: Node3D = model.find_child(name,true,false) as Node3D
        if part != null:
            part.rotation_degrees = Vector3.ZERO
    var weapon: Node3D = model.find_child("ArmamentoRig",true,false) as Node3D
    if weapon != null:
        weapon.position = Vector3(0.13,0.23,-0.47) if str(model.get_meta("tarvoka_infantry_role","")) == "infantry_antitank" else Vector3(0.23,-0.09,-0.48)
        weapon.rotation_degrees = Vector3(0,-10,-10) if str(model.get_meta("tarvoka_infantry_role","")) == "infantry_antitank" else Vector3(0,-16,7)
    for side in [-1,1]:
        var arm: Node3D = model.find_child("BrazoRig_%d" % side,true,false) as Node3D
        if arm != null:
            arm.rotation_degrees.z = float(side)*-8.0
    set_damage(model,0)

static func pose(model: Node3D, kind: String, progress: float,
        heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_model(model):
        return false
    var soldier: Node3D = model.find_child("Infanteria_3D",true,false) as Node3D
    var torso: Node3D = model.find_child("TorsoRig",true,false) as Node3D
    var weapon: Node3D = model.find_child("ArmamentoRig",true,false) as Node3D
    if soldier == null or torso == null or weapon == null:
        return false
    var t: float = clampf(progress,0.0,1.0)
    # Preserve persistent damage when moving or aiming; poses never heal HP.
    var stage: int = damage_stage(model)
    var yaw: float = rad_to_deg(atan2(float(heading.x),-float(heading.y)))
    soldier.rotation_degrees.y = yaw
    soldier.position.y = 0.0
    torso.rotation_degrees = Vector3.ZERO
    weapon.position = Vector3(0.13,0.23,-0.47) if str(model.get_meta("tarvoka_infantry_role","")) == "infantry_antitank" else Vector3(0.23,-0.09,-0.48)
    for side in [-1,1]:
        var leg: Node3D = model.find_child("PiernaRig_%d" % side,true,false) as Node3D
        if leg != null:
            leg.rotation_degrees.x = 0.0
    match kind:
        "move":
            soldier.position.y = 0.055*absf(sin(t*TAU*2.0))
            torso.rotation_degrees.x = -5.0
            for side in [-1,1]:
                var leg: Node3D = model.find_child("PiernaRig_%d" % side,true,false) as Node3D
                if leg != null:
                    leg.rotation_degrees.x = sin(t*TAU*2.0+float(side)*PI*0.5)*24.0
        "attack", "aim":
            torso.rotation_degrees.y = -10.0
            weapon.position.z += -0.085*sin(t*PI) if kind == "attack" else 0.0
        "capture", "work", "repair":
            torso.rotation_degrees.x = 21.0*sin(t*PI)
            var leg: Node3D = model.find_child("PiernaRig_-1",true,false) as Node3D
            if leg != null:
                leg.rotation_degrees.x = 33.0*sin(t*PI)
        "damage", "damaged", "hit_bullet", "hit_explosive":
            soldier.rotation_degrees.z = 13.0*sin(t*PI)
            torso.rotation_degrees.x = -17.0*sin(t*PI)
            if kind == "damage":
                set_damage(model,maxi(stage,clampi(ceili(t*4.0),0,4)))
        "idle":
            pass
        _:
            return false
    if stage >= 4:
        soldier.rotation_degrees.z = -74.0
        soldier.position.y = -0.22
    return true
