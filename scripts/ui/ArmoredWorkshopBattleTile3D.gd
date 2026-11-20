extends RefCounted
class_name TarvokaArmoredWorkshopBattleTile3D

# An INERT native preview of 9 original TARVOKA 2.4m battle tiles.
# It runs inside the existing EDIFICIOS studio: no game-state read/write,
# additional playable building, supply rules, new income or collision.
const Preview=preload("res://scripts/ui/ArmoredWorkshopBattlePreview3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const TILE:float=2.4
const STAGE="PruebaTacticaNueveCasillas"
const WORKSHOP_NODE="TallerEnCasillaCentral"
const GRASS=Color("#608163")
const GRASS_ALT=Color("#68876a")
const ASPHALT=Color("#837e70")
const LANE=Color("#ded0a1")
static var _grass_mat:StandardMaterial3D
static var _grass_alt_mat:StandardMaterial3D
static var _asphalt_mat:StandardMaterial3D
static var _lane_mat:StandardMaterial3D
static var _tile:BoxMesh

static func _material(color:Color) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.roughness=0.91
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    return mat

static func _plate(root:Node3D,label:String,position:Vector3,
        dimensions:Vector3,material:StandardMaterial3D) -> void:
    var m:=BoxMesh.new()
    m.size=dimensions
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=m
    part.material_override=material
    part.position=position
    root.add_child(part)

static func build(level:int=1,faction:int=-1,damage:int=0,
        profile:int=Mobile.PROFILE_TACTICAL) -> Node3D:
    # A native tactical preview is NEVER allowed to instantiate HERO V1/V2.
    if profile not in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        return null
    if not Mobile.valid(level,faction,damage,profile):
        return null
    var workshop:Node3D=Preview.build(level,faction,damage,profile)
    if workshop==null:
        return null
    if _grass_mat==null:
        _grass_mat=_material(GRASS)
        _grass_alt_mat=_material(GRASS_ALT)
        _asphalt_mat=_material(ASPHALT)
        _lane_mat=_material(LANE)
    var root:=Node3D.new()
    root.name=STAGE
    var terrain:=Node3D.new()
    terrain.name="Terreno3DRealNueveCasillas"
    root.add_child(terrain)
    for z in range(-1,2):
        for x in range(-1,2):
            var road:bool=z==-1
            var mat:StandardMaterial3D=                _asphalt_mat if road else _grass_mat if (x+z)%2==0 else _grass_alt_mat
            _plate(terrain,"Casilla_%d_%d" % [x,z],
                Vector3(float(x)*TILE,-0.095,float(z)*TILE),
                Vector3(TILE-0.075,0.18,TILE-0.075),mat)
            if road:
                _plate(terrain,"MarcaCalzada_%d" % x,
                    Vector3(float(x)*TILE,0.0,float(z)*TILE),
                    Vector3(0.46,0.014,0.05),_lane_mat)
    workshop.name=WORKSHOP_NODE
    workshop.position=Vector3(0,0.055,0)
    root.add_child(workshop)
    root.set_meta("visual_preview_only",true)
    root.set_meta("not_a_real_battle_state",true)
    root.set_meta("gameplay_unchanged",true)
    root.set_meta("workshop_art_approved",false)
    root.set_meta("tile_meters",TILE)
    root.set_meta("tile_count",9)
    root.set_meta("workshop_art_version",2)
    root.set_meta("workshop_bays",level)
    root.set_meta("workshop_level",level)
    root.set_meta("workshop_faction",faction)
    root.set_meta("workshop_damage",damage)
    root.set_meta("workshop_lod_profile",profile)
    root.set_meta("workshop_batches",
        int(workshop.get_meta("workshop_batches",0)))
    root.set_meta("workshop_instances",
        int(workshop.get_meta("workshop_instances",0)))
    return root
