extends RefCounted
class_name TarvokaInfantryVariantsV4

# Four distinct physical 3D specialist kits plus existing native Engineer
# (five camp/specialist-related models including Engineer; six core including Guard) for infantry
# skeleton. Studio-only art. No changes to game balance, combat, capture,
# ammunition, healing or camp mechanics.
const ROLES := [
    "infantry_sniper","infantry_logistic",
    "infantry_medic","infantry_commando"
]
const FLAG := "tarvoka_infantry_variant_v4"
const KIT_V5 := "tarvoka_infantry_specialist_kit_v5"
const Sculpt = preload("res://scripts/ui/InfantrySculptFinishV2.gd")
const ROUNDED_KIT := ["V4_CapaCamuflajePrecision","V4_BolsaSuministros","V4_KitMedicoVerde",
    "V4_BotiquinCintura","V4_FundaInstrumentos"]
const MARKER := {
    "infantry_sniper":"V4_CanonPrecision",
    "infantry_logistic":"V4_BolsaSuministros",
    "infantry_medic":"V4_KitMedicoVerde",
    "infantry_commando":"V4_VisoresComando"
}

static func supports(role: String) -> bool:
    return role in ROLES

static func _mat(color: Color, metal: float=0.03, rough: float=0.70) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    color.a=1.0
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    return mat

static func _box(parent: Node3D, part: String, pos: Vector3,
        dims: Vector3, mat: StandardMaterial3D,
        degrees: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=dims
    var piece:=MeshInstance3D.new()
    piece.name=part
    piece.mesh=mesh
    if part in ROUNDED_KIT or part.begins_with("V4_ModuloSuministro_") or part.begins_with("V4_HombreraEspecial_"):
        var profile: Array[Vector3] = [
            Vector3(dims.x*0.38,-dims.y*0.50,dims.z*0.38),
            Vector3(dims.x*0.50,-dims.y*0.37,dims.z*0.50),
            Vector3(dims.x*0.50,dims.y*0.37,dims.z*0.50),
            Vector3(dims.x*0.38,dims.y*0.50,dims.z*0.38)]
        piece.mesh=Sculpt._organic_mesh(profile,12,PackedFloat32Array(),0.42)
        piece.set_meta(KIT_V5,true)
    piece.material_override=mat
    piece.position=pos
    piece.rotation_degrees=degrees
    parent.add_child(piece)
    return piece

static func _tube(parent: Node3D, part: String, pos: Vector3,
        length: float, radius: float, mat: StandardMaterial3D,
        degrees: Vector3=Vector3(0,0,90)) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=12
    var piece:=MeshInstance3D.new()
    piece.name=part
    piece.mesh=mesh
    piece.position=pos
    piece.rotation_degrees=degrees
    piece.material_override=mat
    parent.add_child(piece)
    return piece

static func _orb(parent: Node3D, part: String, pos: Vector3,
        dims: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=12
    mesh.rings=6
    var piece:=MeshInstance3D.new()
    piece.name=part
    piece.mesh=mesh
    piece.position=pos
    piece.scale=dims
    piece.material_override=mat
    parent.add_child(piece)
    return piece

static func apply(model: Node3D, role: String, faction_color: Color,
        hero: bool) -> bool:
    if model==null or not supports(role):
        return false
    if not bool(model.get_meta("tarvoka_infantry_sculpt_finish_v2",false)):
        return false
    if model.has_meta(FLAG):
        return false
    var upper: Node3D=model.find_child("TorsoRig",true,false) as Node3D
    var head: Node3D=model.find_child("CabezaRig",true,false) as Node3D
    var gun: Node3D=model.find_child("ArmamentoRig",true,false) as Node3D
    if upper==null or head==null or gun==null:
        return false
    var color:=Color(faction_color.r,faction_color.g,faction_color.b,1.0)
    var accent:=_mat(color,0.12,0.46)
    var armor:=_mat(Color("#617373"),0.25,0.52)
    var dark:=_mat(Color("#222d31"),0.08,0.78)
    var steel:=_mat(Color("#a3b1b4"),0.56,0.32)
    var glass:=_mat(Color("#204a60"),0.23,0.13)
    var pack:=_mat(Color("#536f5d"),0.02,0.84)
    var white:=_mat(Color("#e8efea"),0.01,0.72)
    match role:
        "infantry_sniper":
            # Long precision barrel, dedicated glass optic and two bipod feet.
            _tube(gun,"V4_CanonPrecision",Vector3(1.02,0.01,-0.02),
                0.58,0.034,steel)
            _tube(gun,"V4_BocachaPrecision",Vector3(1.30,0.01,-0.02),
                0.11,0.065,dark)
            _tube(gun,"V4_OpticaPrecision",Vector3(0.20,0.22,-0.01),
                0.45,0.075,dark)
            _orb(gun,"V4_CristalPrecision",Vector3(0.44,0.22,-0.01),
                Vector3(0.03,0.12,0.12),glass)
            _box(upper,"V4_CapaCamuflajePrecision",Vector3(0,0.30,0.20),
                Vector3(0.59,0.28,0.38),pack)
            _box(upper,"V4_FaccionPrecision",Vector3(0,0.12,-0.407),
                Vector3(0.30,0.10,0.035),accent)
            if hero:
                for side in [-1,1]:
                    _tube(gun,"V4_BipodePrecision_%d"%side,
                        Vector3(0.89,-0.23,float(side)*0.085),
                        0.43,0.022,steel,Vector3(0,0,18+side*15))
        "infantry_logistic":
            # A supply specialist ON FOOT, distinct from the G16 truck.
            _box(upper,"V4_BolsaSuministros",Vector3(0,0.03,0.58),
                Vector3(0.61,0.66,0.34),pack)
            for side in [-1,1]:
                _box(upper,"V4_ModuloSuministro_%d"%side,
                    Vector3(float(side)*0.36,-0.12,0.47),
                    Vector3(0.22,0.35,0.23),armor)
                _box(upper,"V4_MarcaCarga_%d"%side,
                    Vector3(float(side)*0.37,0.09,0.592),
                    Vector3(0.17,0.075,0.028),accent)
            _box(upper,"V4_EtiquetaLogistica",Vector3(0,0.21,0.769),
                Vector3(0.42,0.13,0.035),accent)
            if hero:
                for side in [-1,1]:
                    _tube(upper,"V4_CantimploraSuministro_%d"%side,
                        Vector3(float(side)*0.31,-0.34,0.36),
                        0.28,0.072,steel,Vector3.ZERO)
        "infantry_medic":
            # Neutral white medical plus over green, not a Red Cross emblem.
            _box(upper,"V4_KitMedicoVerde",Vector3(-0.27,-0.08,0.55),
                Vector3(0.48,0.53,0.27),pack)
            _box(upper,"V4_MarcaMedicaVertical",
                Vector3(-0.27,-0.08,0.702),
                Vector3(0.11,0.34,0.038),white)
            _box(upper,"V4_MarcaMedicaHorizontal",
                Vector3(-0.27,-0.08,0.726),
                Vector3(0.32,0.11,0.038),white)
            _box(upper,"V4_InsigniaMedicaFaccion",
                Vector3(0,0.22,-0.389),
                Vector3(0.44,0.12,0.04),accent)
            _box(upper,"V4_BotiquinCintura",Vector3(0.35,-0.38,-0.05),
                Vector3(0.23,0.24,0.20),pack)
            if hero:
                _tube(upper,"V4_VendaEsteril",Vector3(0.36,-0.15,0.38),
                    0.26,0.09,white,Vector3(90,0,0))
                _box(upper,"V4_FundaInstrumentos",Vector3(-0.34,-0.34,0.25),
                    Vector3(0.12,0.24,0.09),steel)
        "infantry_commando":
            # FS-24: three night optics, suppressed rifle and field radio.
            for side in [-1,0,1]:
                var lens_name:String=(
                    "V4_VisoresComando" if side==0 else
                    "V4_OpticaComando_%d"%side)
                _tube(head,lens_name,Vector3(float(side)*0.14,0.40,-0.36),
                    0.19,0.065,dark,Vector3(90,0,0))
                _orb(head,"V4_CristalNV_%d"%side,
                    Vector3(float(side)*0.14,0.40,-0.47),
                    Vector3(0.11,0.11,0.04),glass)
            _tube(gun,"V4_SilenciadorComando",Vector3(1.02,0,0),
                0.38,0.062,dark)
            _tube(upper,"V4_AntenaComando",Vector3(0.27,0.53,0.40),
                0.59,0.019,steel,Vector3.ZERO)
            _box(upper,"V4_InsigniaFS24",Vector3(0.25,0.25,-0.30),
                Vector3(0.16,0.12,0.036),accent)
            if hero:
                for side in [-1,1]:
                    _box(upper,"V4_HombreraEspecial_%d"%side,
                        Vector3(float(side)*0.43,0.25,-0.02),
                        Vector3(0.19,0.13,0.27),dark)
        _:
            return false
    if role=="infantry_logistic":
        var pack_badge: Node3D=model.find_child("V4_EtiquetaLogistica",true,false) as Node3D
        if pack_badge!=null:
            pack_badge.position.z=0.756
    if role=="infantry_medic":
        var cross_v: Node3D=model.find_child("V4_MarcaMedicaVertical",true,false) as Node3D
        var cross_h: Node3D=model.find_child("V4_MarcaMedicaHorizontal",true,false) as Node3D
        if cross_v!=null and cross_h!=null:
            cross_v.position.z=0.692
            cross_h.position.z=0.705
    # Align the existing native flash to the visible specialist silhouette.
    var flash: Node3D=gun.find_child("V2_DestelloDisparo3D",true,false) as Node3D
    if flash!=null:
        if role=="infantry_sniper":
            flash.position.x=1.355
        elif role=="infantry_commando":
            flash.position.x=1.21
    # Compact physical service props, distinct from the carried kits.
    # They are hidden except during the original visual work animation.
    if role in ["infantry_medic","infantry_logistic"]:
        var service:=Node3D.new()
        service.name=Sculpt.SERVICE_RIG
        upper.add_child(service)
        service.visible=false
        if role=="infantry_medic":
            _box(service,"V6_MedicalPouch",Vector3(0,0.045,-0.035),Vector3(0.22,0.15,0.13),pack)
            _box(service,"V6_MedicalBandage",Vector3(0,0.08,-0.108),Vector3(0.13,0.045,0.02),white)
        else:
            _box(service,"V6_SupplyCase",Vector3(0,0.04,-0.045),Vector3(0.25,0.18,0.15),armor)
            _box(service,"V6_SupplyFaction",Vector3(0,0.07,-0.128),Vector3(0.18,0.05,0.02),accent)
        _box(service,"V6_ServiceHandle",Vector3(0,-0.04,0.018),Vector3(0.13,0.035,0.04),dark)
    model.set_meta(KIT_V5,true)
    model.set_meta(FLAG,role)
    model.set_meta("tarvoka_infantry_variant_visual_only",true)
    model.set_meta("tarvoka_infantry_variant_hero",hero)
    return true

static func has_model(model: Node3D, role: String) -> bool:
    return model!=null and supports(role) and str(model.get_meta(FLAG,""))==role
