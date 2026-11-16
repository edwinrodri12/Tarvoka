extends RefCounted
class_name TarvokaG13SurfaceFinishV8

# V8: shared PBR surface pass for G13 hero sculpt, never applied to
# tactical low LOD. Does not create meshes or modify combat/economy.
const FLAG := "tarvoka_g13_surface_finish_v8"
const PAINT_NAMES := [
    "G13_SideEnamel_-1","G13_SideEnamel_1",
    "G13_TurretFaction_-1","G13_TurretFaction_1",
    "G13_V2_FactionFlank_-1","G13_V2_FactionFlank_1",
    "G13_V2_TurretInsignia_-1","G13_V2_TurretInsignia_1",
    "G13_V2_RoofFaction"
]
const OPTIC_NAMES := [
    "G13_FrontGlass_-1","G13_FrontGlass_1",
    "G13_OpticDirector","G13_RadarReceiver"
]
const STEEL_NAMES := [
    "G13_RemoteWeaponHousing","G13_SealedCab","G13_SlopedGlacis",
    "G13_CabRoof","G13_EngineCover","G13_V2_TurretCheek_-1",
    "G13_V2_TurretCheek_1","G13_RearServiceDoor"
]
const RUBBER_NAMES := [
    "G13_V2_Fender_-1_-1","G13_V2_Fender_-1_1",
    "G13_V2_Fender_1_-1","G13_V2_Fender_1_1"
]
const FLASH_COLOR := Color(1.0,0.69,0.21)

static func _mat(c: Color,metallic: float,rough: float,
        emission: Color=Color.BLACK,emission_energy: float=0.0)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metallic
    m.roughness=rough
    if emission_energy>0.0:
        m.emission_enabled=true
        m.emission=emission
        m.emission_energy_multiplier=emission_energy
    return m

static func _paint(root: Node,name: String,material: Material)->bool:
    var part:=root.find_child(name,true,false) as MeshInstance3D
    if part==null:
        return false
    part.material_override=material
    return true

static func _repaint(root: Node,names: Array,material: Material)->int:
    var changed:=0
    for part_name in names:
        if _paint(root,str(part_name),material):
            changed+=1
    return changed

static func apply(root: Node3D,enamel: Color)->bool:
    if root==null or bool(root.get_meta(FLAG,false)):
        return false
    if not bool(root.get_meta("tarvoka_g13_detail_v2",false)):
        return false
    var faction:=_mat(enamel.darkened(0.08),0.34,0.53)
    var armor:=_mat(Color("#788589"),0.38,0.69)
    var optical:=_mat(Color("#295366"),0.13,0.25)
    var rubber:=_mat(Color("#242b2f"),0.02,0.92)
    var flash:=_mat(Color("#f4b555"),0.0,0.32,FLASH_COLOR,1.4)
    # Apply only to known G13 nodes, not shared resources belonging to
    # tanks/APCs or the other faction models.
    var paints:=_repaint(root,PAINT_NAMES,faction)
    var optics:=_repaint(root,OPTIC_NAMES,optical)
    var steel:=_repaint(root,STEEL_NAMES,armor)
    var fenders:=_repaint(root,RUBBER_NAMES,rubber)
    var flashes:=0
    for side in [-1,1]:
        if _paint(root,"G13_FlashCone_%d" % side,flash):
            flashes+=1
    if paints!=PAINT_NAMES.size() or optics!=OPTIC_NAMES.size() or (
            steel!=STEEL_NAMES.size() or fenders!=RUBBER_NAMES.size()
            or flashes!=2):
        return false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_surface_v8_visual_only",true)
    root.set_meta("tarvoka_g13_surface_v8_faction_paint",enamel.to_html())
    return true
