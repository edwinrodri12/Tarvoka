extends RefCounted
class_name TarvokaNavalFendersV8

# Additive native Godot 4.3 harbor art; no ship collision, physics or economy.
# Fenders, animated water-contact foam and industrial runoff join the
# existing V1-V7 port. All new intact pieces obey the five damage states.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const V7=preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const FOAM_SHADER=preload("res://assets/shaders/naval_contact_foam_v8.gdshader")

const STAGE_NAME: String="DefensasHidrodinamicaYAccesoAstilleroV8"
const RUBBER=Color("#25353c")
const WORN_RUBBER=Color("#455357")
const STEEL=Color("#7d969b")
const STEEL_DARK=Color("#374c56")
const RUST=Color("#986c57")
const SAFETY=Color("#e1b968")
const ALGAE=Color("#698a81")
const DAY_REFLECTIVE=Color("#b9ccca")
static var _reflective: StandardMaterial3D

static func _box(parent: Node3D,label: String,at: Vector3,
        size: Vector3,color: Color,metal: float=0.22,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,label,at,size,color,metal,rot)

static func _cylinder(parent: Node3D,label: String,at: Vector3,
        radius: float,height: float,color: Color) -> MeshInstance3D:
    return Base._cylinder(parent,label,at,radius,height,color,0.23,12)

static func _beam(parent: Node3D,label: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> void:
    Base._beam(parent,label,a,b,radius,color)

static func _reflect_material() -> StandardMaterial3D:
    if _reflective==null:
        _reflective=StandardMaterial3D.new()
        _reflective.albedo_color=DAY_REFLECTIVE
        _reflective.roughness=0.52
        _reflective.emission_enabled=true
        _reflective.emission=DAY_REFLECTIVE
        _reflective.emission_energy_multiplier=0.33
    return _reflective

static func _fender(body: Node3D,label: String,
        x: float,z: float,direction: String) -> void:
    var anchor: Vector3=Vector3(x,0.32,z)
    _cylinder(body,label,anchor,0.145,0.46,RUBBER)
    var cap_offset:=Vector3(-0.01,0,0) if direction=="east" else Vector3.ZERO
    _box(body,label+"_SoporteSuperior",
        anchor+Vector3(0,0.275,0)+cap_offset,
        Vector3(0.28,0.052,0.28),STEEL,0.42)
    _box(body,label+"_SoporteInferior",
        anchor+Vector3(0,-0.273,0)+cap_offset,
        Vector3(0.27,0.050,0.27),STEEL_DARK,0.37)
    _cylinder(body,label+"_AnilloCaucho",
        anchor+Vector3(0,0.02,0),0.158,0.052,WORN_RUBBER)

static func _east_fenders(stage: Node3D,damage: int) -> void:
    var near: Node3D=stage.get_node("DetallesCercanosDefensasV8")
    var far: Node3D=stage.get_node("PerfilesLejanosDefensasV8")
    if damage==4:
        for i in range(3):
            _box(near,"GomaMuelleEsteArrancada_%02d" % i,
                Vector3(1.09,0.20,-3.8+float(i)*3.10),
                Vector3(0.24,0.14,0.30),RUST,0.10,
                Vector3(11,23*float(i),19))
        return
    for i in range(7):
        if damage>=2 and i in [2,3]:
            continue
        var z: float=-4.10+float(i)*1.35
        if damage==3:
            # Torn rubber pads remain on the surviving east wall.
            _box(near,"GomaMuelleEsteRota_%02d" % i,
                Vector3(1.04,0.23,z),
                Vector3(0.23,0.22,0.26),WORN_RUBBER,0.08,
                Vector3(13,float(i)*11,8))
            continue
        _fender(near,"FenderVerticalMuelleEste_%02d" % i,
            1.055,z,"east")
        _box(near,"EscurrimientoBajoFender_%02d" % i,
            Vector3(1.007,0.074,z),
            Vector3(0.025,0.075,0.23),ALGAE,0.06)
        # The far LOD does not duplicate full-res fenders.
        _box(far,"FenderSiluetaMuelleEste_%02d" % i,
            Vector3(1.05,0.29,z),
            Vector3(0.23,0.45,0.33),RUBBER,0.07)

static func _pier_fenders(stage: Node3D,damage: int,
        accent: Color) -> void:
    var near: Node3D=stage.get_node("DetallesCercanosDefensasV8")
    var far: Node3D=stage.get_node("PerfilesLejanosDefensasV8")
    if damage==4:
        _box(near,"RestosDefensaEspigonDestruido",
            Vector3(-4.2,0.24,-4.22),
            Vector3(0.46,0.21,0.20),WORN_RUBBER,0.09,
            Vector3(0,0,21))
        return
    for side in [-1,1]:
        if damage>=3 and side==1:
            continue
        var z: float=float(side)*4.19
        for i in range(3):
            var x: float=-5.10+float(i)*1.83
            if damage>=2 and i==1:
                continue
            if damage==3:
                _box(near,"DefensaEspigonRota_%s_%d" % [side,i],
                    Vector3(x,0.25,z),
                    Vector3(0.30,0.25,0.24),WORN_RUBBER,0.10,
                    Vector3(0,0,18))
                continue
            var label: String="DefensaNeumaticaEspigon_%s_%d" % [side,i]
            _fender(near,label,x,z,"pier")
            # Hook and steel chain keep the fender mechanically attached.
            _beam(near,"CadenaDefensa_%s_%d" % [side,i],
                Vector3(x,0.59,z),
                Vector3(x+0.16,0.69,z+float(side)*0.12),
                0.027,STEEL)
            _box(far,"DefensaTacticaEspigon_%s_%d" % [side,i],
                Vector3(x,0.30,z),
                Vector3(0.37,0.48,0.21),STEEL_DARK,0.17)
        if damage<=1:
            _box(far,"MarcaFaccionDefensas_%s" % side,
                Vector3(-1.90,0.69,float(side)*4.85),
                Vector3(1.08,0.024,0.16),accent,0.12)

static func _foam_strip(parent: Node3D,name: String,
        pos: Vector3,width: float,length: float,
        mat: ShaderMaterial,rot_degrees: float=0.0) -> void:
    var mesh:=PlaneMesh.new()
    mesh.size=Vector2(width,length)
    var waterline:=MeshInstance3D.new()
    waterline.name=name
    waterline.mesh=mesh
    waterline.material_override=mat
    waterline.position=pos
    waterline.rotation_degrees.y=rot_degrees
    waterline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(waterline)

static func _water_contact(stage: Node3D,damage: int) -> void:
    var near: Node3D=stage.get_node("EspumaContactoCercanaV8")
    var far: Node3D=stage.get_node("EspumaContactoLejanaV8")
    var mat:=ShaderMaterial.new()
    mat.shader=FOAM_SHADER
    mat.set_shader_parameter("foam_opacity",0.31)
    mat.set_shader_parameter("night_factor",1.0)
    stage.set_meta("naval_v8_foam_material",mat)
    # V2 water plane is y=0.046. Narrow, separated surface strips prevent
    # Z fighting while avoiding a huge second transparent water sheet.
    # Each strip lies within the real V2 water rectangle and inside the U.
    for i in range(9):
        if damage>=4 and i%3!=0:
            continue
        var z: float=-4.40+float(i)*1.10
        _foam_strip(near,"EspumaContactMuelleEste_%02d" % i,
            Vector3(0.999,0.061,z),0.19,0.71,mat)
    for side in [-1,1]:
        # The positive pier has no continuous face in critical/destruction.
        if damage>=3 and side==1:
            continue
        for i in range(6):
            if damage==4 and i%3!=0:
                continue
            var x: float=-5.36+float(i)*1.06
            _foam_strip(near,"EspumaInteriorEspigon_%s_%02d" % [side,i],
                Vector3(x,0.061,float(side)*4.16),
                0.20,0.65,mat,90.0)
    # A very subtle simplified foam profile at tactical zoom.
    _foam_strip(far,"TrazoEspumaOrientacionEste",
        Vector3(1.00,0.061,0),0.085,8.82,mat)
    if damage<3:
        for side in [-1,1]:
            _foam_strip(far,"TrazoEspumaEspigon_%s" % side,
                Vector3(-2.55,0.061,float(side)*4.16),
                0.075,5.00,mat,90.0)

static func _shipyard_drainage(stage: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var near: Node3D=stage.get_node("DetallesCercanosDefensasV8")
    var far: Node3D=stage.get_node("PerfilesLejanosDefensasV8")
    # Service strip on land, immediately east of the seawall, close to the
    # existing V3 gangway at (2.67, 1.36) and V2 supply pedestals.
    if damage==4:
        _box(near,"CunetaAstilleroDemolida",
            Vector3(2.48,0.56,-3.78),
            Vector3(0.23,0.09,0.83),RUST,0.16,
            Vector3(0,10,12))
        return
    for i in range(5):
        if damage>=3 and i>=2:
            continue
        var z: float=-3.75+float(i)*1.04
        _box(near,"CanalDrenajeAstillero_%02d" % i,
            Vector3(2.40,0.548,z),
            Vector3(0.22,0.035,0.94),
            STEEL_DARK if damage<=1 else RUST,0.22)
        if damage<=2:
            for slot in range(3):
                _box(near,"RanuraDrenaje_%02d_%d" % [i,slot],
                    Vector3(2.405,0.572,
                        z-0.29+float(slot)*0.29),
                    Vector3(0.17,0.011,0.041),STEEL,0.31)
    if damage<=2:
        _box(far,"DireccionServiciosMuelle",
            Vector3(2.40,0.567,-1.63),
            Vector3(0.21,0.037,4.97),STEEL_DARK,0.18)
    # Pipe from the edge service line toward the real embarkation hinge;
    # not a fictional elevated bridge crossing the navigation channel.
    if level>=2 and damage<=2:
        for i in range(2):
            var z: float=0.26+float(i)*0.32
            _beam(near,"ConductorServicioPasarela_%d" % i,
                Vector3(2.57,0.68,z),
                Vector3(2.57,0.68,1.26),0.026,
                STEEL if damage<2 else RUST)
        if damage<=1:
            _box(near,"ProtectorConexionFaccion",
                Vector3(2.57,0.73,1.26),
                Vector3(0.21,0.08,0.21),accent,0.24)
        else:
            _box(near,"ProtectorConexionDañado",
                Vector3(2.58,0.68,1.22),
                Vector3(0.17,0.07,0.23),RUST,0.11,
                Vector3(0,0,11))

static func _night_reflectors(stage: Node3D,damage: int) -> void:
    var night: Node3D=stage.get_node("GuiasNocturnasMuellesV8")
    if damage>=3:
        return
    for i in range(3):
        if damage>=1 and i==2:
            continue
        var z: float=-3.72+float(i)*3.63
        var marker:=_box(night,"ReflectorFenderEste_%d" % i,
            Vector3(1.31,0.65,z),
            Vector3(0.16,0.025,0.14),DAY_REFLECTIVE,0.05)
        marker.material_override=_reflect_material()

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var root: Node3D=model.get_node(STAGE_NAME)
    (root.get_node("DetallesCercanosDefensasV8") as Node3D).visible=near_view
    (root.get_node("EspumaContactoCercanaV8") as Node3D).visible=near_view
    (root.get_node("PerfilesLejanosDefensasV8") as Node3D).visible=not near_view
    (root.get_node("EspumaContactoLejanaV8") as Node3D).visible=not near_view
    root.set_meta("naval_v8_close_mode",near_view)
    return true

static func set_night(model: Node3D,enabled: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var root: Node3D=model.get_node(STAGE_NAME)
    (root.get_node("GuiasNocturnasMuellesV8") as Node3D).visible=enabled
    var mat: ShaderMaterial=root.get_meta("naval_v8_foam_material") as ShaderMaterial
    if mat!=null:
        mat.set_shader_parameter("night_factor",0.42 if enabled else 1.0)
    root.set_meta("naval_v8_night_enabled",enabled)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    for stage in [V2.STAGE_NAME,V3.STAGE_NAME,V4.STAGE_NAME,
            V5.STAGE_NAME,V6.STAGE_NAME,V7.STAGE_NAME]:
        if not model.has_node(stage):
            return false
    if model.has_node(STAGE_NAME):
        return false
    var root:=Base._group(model,STAGE_NAME)
    Base._group(root,"DetallesCercanosDefensasV8")
    Base._group(root,"PerfilesLejanosDefensasV8")
    Base._group(root,"EspumaContactoCercanaV8")
    Base._group(root,"EspumaContactoLejanaV8")
    Base._group(root,"GuiasNocturnasMuellesV8")
    _east_fenders(root,damage)
    _pier_fenders(root,damage,Style.faction_color(faction))
    _water_contact(root,damage)
    _shipyard_drainage(root,level,damage,Style.faction_color(faction))
    _night_reflectors(root,damage)
    root.set_meta("naval_v8_level",level)
    root.set_meta("naval_v8_faction",faction)
    root.set_meta("naval_v8_damage",damage)
    root.set_meta("naval_v8_original_water_preserved",true)
    set_detail(model,true)
    set_night(model,false)
    return true
