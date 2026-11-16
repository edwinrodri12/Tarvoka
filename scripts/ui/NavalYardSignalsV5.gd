extends RefCounted
class_name TarvokaNavalYardSignsV5

# Visual-only additive V5 for the original Godot 4.3 Naval Base.
# Correct scale, genuine cast-shadow support members, readable berth numerals
# and restrained marine lamps. Preserve V1-V4, factions and damage holes.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME: String="SenalizacionIluminacionYEscalaAstilleroV5"
const IRON=Color("#253844")
const METAL=Color("#80979c")
const WORN=Color("#85695d")
const SAFETY=Color("#e0c477")
const LABEL=Color("#ebf3ef")
const RED=Color("#e26f62")
const GREEN=Color("#6fdbb0")
const GLASS=Color("#c0d0cf")
static var _emission_cache: Dictionary={}

static func _group(parent: Node3D,name: String) -> Node3D:
    return Base._group(parent,name)

static func _box(parent: Node3D,name: String,at: Vector3,
        size: Vector3,color: Color,metal: float=0.22,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,name,at,size,color,metal,rotation)

static func _beam(parent: Node3D,name: String,
        a: Vector3,b: Vector3,r: float,color: Color) -> void:
    Base._beam(parent,name,a,b,r,color)

static func _cylinder(parent: Node3D,name: String,
        at: Vector3,r: float,h: float,color: Color) -> MeshInstance3D:
    return Base._cylinder(parent,name,at,r,h,color,0.37,12)

static func _glow(color: Color) -> StandardMaterial3D:
    var key: String=color.to_html()
    if _emission_cache.has(key):
        return _emission_cache[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=0.12
    mat.roughness=0.31
    mat.emission_enabled=true
    mat.emission=color
    mat.emission_energy_multiplier=0.75
    _emission_cache[key]=mat
    return mat

static func _digit(parent: Node3D,prefix: String,value: int,
        x: float,y: float,z: float) -> void:
    # Seven REAL raised geometry segments rather than a flat sign texture.
    # [top, upper-right, lower-right, bottom, lower-left, upper-left, middle]
    var active: Array[int]=[]
    match value:
        0: active=[0,1,2,3,4,5]
        1: active=[1,2]
        2: active=[0,1,6,4,3]
    for part in active:
        var dx: float=0.0
        var dy: float=0.0
        var size:=Vector3(0.137,0.028,0.026)
        match part:
            0: dy=0.135
            1:
                dx=0.069
                dy=0.068
                size=Vector3(0.028,0.117,0.026)
            2:
                dx=0.069
                dy=-0.068
                size=Vector3(0.028,0.117,0.026)
            3: dy=-0.135
            4:
                dx=-0.069
                dy=-0.068
                size=Vector3(0.028,0.117,0.026)
            5:
                dx=-0.069
                dy=0.068
                size=Vector3(0.028,0.117,0.026)
            6: dy=0.0
        _box(parent,"%s_Tramo_%d" % [prefix,part],
            Vector3(x+dx,y+dy,z),size,LABEL,0.12)

static func _berth_numbers(stage: Node3D,damage: int) -> void:
    if damage==4:
        return
    var plates:=_group(stage,"NumeracionMuellesFisicaV5")
    for pier in [-1,1]:
        # The far-side +pier has actually snapped in V1/V2 at critical damage.
        if damage>=3 and pier==1:
            continue
        var z: float=float(pier)*4.85
        var x: float=-5.02
        var face_z: float=z+float(pier)*0.105
        _box(plates,"PlacaMuelle_%s" % pier,
            Vector3(x,1.00,z),Vector3(0.64,0.45,0.13),IRON,0.37)
        _box(plates,"BordeFaccionMuelle_%s" % pier,
            Vector3(x,1.225,z),Vector3(0.60,0.045,0.16),
            SAFETY,0.23)
        _digit(plates,"NumeroMuelle_%s_0" % pier,0,
            x-0.16,1.01,face_z)
        _digit(plates,"NumeroMuelle_%s_%d" % [pier,1 if pier==-1 else 2],
            1 if pier==-1 else 2,x+0.16,1.01,face_z)
        _box(plates,"ZapataPlacaMuelle_%s" % pier,
            Vector3(x,0.73,z),Vector3(0.17,0.28,0.15),METAL,0.26)
    plates.set_meta("naval_v5_no_signs_on_missing_pier",true)

static func _shipyard_geometry(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var yard:=_group(stage,"EstructuraEscalaYSombrasAstilleroV5")
    if damage==4:
        # The ruined site cannot suddenly grow new intact foundations.
        _box(yard,"VigaAstilleroDerrumbadaV5",
            Vector3(3.52,0.73,-0.28),Vector3(1.33,0.10,0.18),
            WORN,0.18,Vector3(14,21,9))
        return
    # Correct proportion relative to existing 1.94m service bed in V3.
    # Steel shadow-casting feet and cross braces remain attached to it.
    for side in [-1,1]:
        var z: float=0.20+float(side)*0.54
        for station in [-1,1]:
            var x: float=3.46+float(station)*0.82
            _box(yard,"PieBancada_%s_%s" % [side,station],
                Vector3(x,0.51,z),Vector3(0.15,0.29,0.14),
                METAL if damage<3 else WORN,0.43)
        if damage<=2:
            _beam(yard,"ArriostreBancada_%s" % side,
                Vector3(2.64,0.44,z),Vector3(4.28,0.72,z),
                0.042,IRON)
            _box(yard,"CantoneraBancada_%s" % side,
                Vector3(3.46,0.77,z),Vector3(1.80,0.10,0.12),
                accent,0.35)
    if damage>=3:
        _beam(yard,"TiranteBancadaDoblado",
            Vector3(2.68,0.72,0.73),Vector3(3.62,0.40,0.46),
            0.047,WORN)
        return
    # Real-world scaled equipment, no giant extra tower masking the HQ.
    for i in range(2):
        var x: float=2.80+float(i)*1.33
        _box(yard,"PosteGuardiaZonaTrabajo_%d" % i,
            Vector3(x,1.06,1.16),Vector3(0.080,0.83,0.080),
            IRON,0.35)
        _box(yard,"ReflectivoZonaTrabajo_%d" % i,
            Vector3(x,1.50,1.16),Vector3(0.16,0.09,0.11),
            SAFETY,0.12)
    # The old V3 crane is only present at level 3 and damage 0/1.
    if level==3 and damage<=1:
        _box(yard,"RefuerzoPuenteGruaIzquierdoV5",
            Vector3(2.49,3.25,0.14),
            Vector3(0.18,0.18,1.77),IRON,0.36)
        _box(yard,"RefuerzoPuenteGruaDerechoV5",
            Vector3(4.45,3.25,0.14),
            Vector3(0.18,0.18,1.77),IRON,0.36)
        for sign in [-1,1]:
            var z: float=0.14+float(sign)*0.80
            _beam(yard,"CartelaPuenteGrua_%s" % sign,
                Vector3(2.49,2.81,z),Vector3(3.00,3.21,z),
                0.039,METAL)
    yard.set_meta("naval_v5_real_shadow_geometry",true)

static func _navigation(stage: Node3D,damage: int) -> void:
    if damage>=4:
        return
    var marks:=_group(stage,"BalizasMaritimasModeradasV5")
    for side in [-1,1]:
        if damage>=3 and side==1:
            continue
        var pos:=Vector3(-5.48,0.95,float(side)*4.85)
        var color: Color=RED if side<0 else GREEN
        _cylinder(marks,"BalizaPedestal_%s" % side,
            pos,0.09,0.68,IRON)
        _cylinder(marks,"BalizaLente_%s" % side,
            pos+Vector3(0,0.45,0),0.18,0.22,color)
        var lens:=marks.get_node("BalizaLente_%s" % side) as MeshInstance3D
        if damage<=1:
            lens.material_override=_glow(color)
        _box(marks,"CubiertaLente_%s" % side,
            pos+Vector3(0,0.60,0),
            Vector3(0.42,0.08,0.36),IRON,0.24)
        if damage>=2:
            lens.rotation_degrees.z=18.0
        marks.set_meta("naval_v5_navigation_still_operational",
            damage<=1)

static func _lamps(stage: Node3D,level: int,damage: int) -> void:
    if damage>=3:
        return
    var light_group:=_group(stage,"IluminacionDeServicioReguladaV5")
    for station in range(2):
        if damage>=1 and station==1:
            continue
        var z: float=-3.20+float(station)*6.25
        var x: float=2.97
        _box(light_group,"PosteReflectorServicio_%d" % station,
            Vector3(x,1.46,z),Vector3(0.13,1.79,0.14),
            IRON,0.31)
        _box(light_group,"BrazoReflectorServicio_%d" % station,
            Vector3(x-0.32,2.27,z),
            Vector3(0.63,0.095,0.10),METAL,0.32)
        _box(light_group,"CuerpoReflectorServicio_%d" % station,
            Vector3(x-0.64,2.21,z),
            Vector3(0.38,0.21,0.31),IRON,0.43)
        var glass:=_box(light_group,
            "DifusorReflectorServicio_%d" % station,
            Vector3(x-0.64,2.075,z),
            Vector3(0.30,0.034,0.23),GLASS,0.15)
        glass.material_override=_glow(Color("#dfd5a8"))
        # Genuine limited-range SpotLight. No expensive shadow maps: the
        # existing scene's directional light handles silhouette shadows.
        var lamp:=SpotLight3D.new()
        lamp.name="ConoLuzServicio_%d" % station
        lamp.position=Vector3(x-0.64,2.05,z)
        lamp.light_color=Color("#ffe3ad")
        lamp.light_energy=0.34 if level<3 else 0.43
        lamp.spot_range=3.6
        lamp.spot_angle=42.0
        lamp.shadow_enabled=false
        # Quaternion works before model is added to the active SceneTree.
        var direction: Vector3=(
            Vector3(1.75,0.62,z)-lamp.position).normalized()
        lamp.basis=Basis(Quaternion(Vector3.FORWARD,direction))
        light_group.add_child(lamp)
    light_group.set_meta("naval_v5_spot_shadow_maps",0)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V2.STAGE_NAME) or not model.has_node(V3.STAGE_NAME):
        return false
    if not model.has_node(V4.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    var stage:=_group(model,STAGE_NAME)
    _berth_numbers(stage,damage)
    _shipyard_geometry(stage,level,damage,Style.faction_color(faction))
    _navigation(stage,damage)
    _lamps(stage,level,damage)
    stage.set_meta("naval_v5_level",level)
    stage.set_meta("naval_v5_faction",faction)
    stage.set_meta("naval_v5_damage",damage)
    stage.set_meta("naval_v5_preserves_official_emblems",true)
    return true
