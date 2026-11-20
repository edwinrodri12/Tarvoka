extends RefCounted
class_name TarvokaArmoredWorkshopBattlePreview3D

# VISUAL BRIDGE ONLY. This is not imported by BattleTerrain3D and does not
# introduce an economy site, production rule, capture, collision or supplies.
# Reuses the same Android geometry used by the 3D design studio, fitted
# inside the actual 2.4m tactical grid tile for art approval screenshots.
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const TILE_WIDTH:float=2.4
const USABLE_FOOTPRINT:float=2.17
const SITE_KIND:String="armored_workshop"
const VISUAL_ART_VERSION:int=2

static func _dimensions(level:int) -> Vector2:
    if level==1:
        return Vector2(9.5+2.40,12.0+3.80)
    if level==2:
        return Vector2(15.0+2.40,15.0+3.80)
    if level==3:
        return Vector2(20.5+2.40,18.0+3.80)
    return Vector2.ZERO

static func scale_for_level(level:int) -> float:
    var footprint:Vector2=_dimensions(level)
    if footprint.x<=0 or footprint.y<=0:
        return 0.0
    return USABLE_FOOTPRINT/maxf(footprint.x,footprint.y)

static func color_index_for_public_owner(state:Dictionary,
        public_owner:int) -> int:
    # Unseen/explored-but-not-currently-visible buildings cannot leak an
    # enemy faction color. Neutral is always -1, not official yellow.
    if public_owner not in [0,1]:
        return -1
    var key:String=Identity.key_for(state,public_owner)
    var index:int=Identity.index_for(key)
    return index if index>=0 else -1

static func build(level:int,faction:int,damage:int,
        lod:int=Mobile.PROFILE_TACTICAL) -> Node3D:
    if lod not in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        return null
    if not Mobile.valid(level,faction,damage,lod):
        return null
    var model:Node3D=Mobile.build(level,faction,damage,lod)
    if model==null:
        return null
    var root:=Node3D.new()
    root.name="TallerDeBlindadosPreparacionMapa3D"
    root.add_child(model)
    model.scale=Vector3.ONE*scale_for_level(level)
    root.set_meta("preview_only",true)
    root.set_meta("game_visual_only",true)
    root.set_meta("gameplay_unchanged",true)
    root.set_meta("approved",false)
    root.set_meta("site_kind",SITE_KIND)
    root.set_meta("visual_art_version",VISUAL_ART_VERSION)
    root.set_meta("visual_level",level)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("workshop_lod",lod)
    root.set_meta("tile_width",TILE_WIDTH)
    root.set_meta("footprint_m",_dimensions(level))
    root.set_meta("scale",scale_for_level(level))
    root.set_meta("workshop_batches",int(model.get_meta("workshop_batches",0)))
    root.set_meta("workshop_instances",int(model.get_meta("workshop_instances",0)))
    return root

static func build_preview_site(state:Dictionary,site:Dictionary,
        public_owner:int,lod:int=Mobile.PROFILE_TACTICAL) -> Node3D:
    if str(site.get("kind",""))!=SITE_KIND:
        return null
    var level:int=clampi(int(site.get("visual_level",1)),1,3)
    var damage:int=clampi(int(site.get("visual_damage_stage",0)),0,4)
    var faction:int=color_index_for_public_owner(state,public_owner)
    var root:Node3D=build(level,faction,damage,lod)
    if root!=null:
        root.set_meta("public_owner",public_owner)
        root.set_meta("battle_cell",site.get("pos",Vector2i.ZERO))
        root.set_meta("fog_safe",true)
    return root

static func set_preview_detail(root:Node3D,lod:int) -> bool:
    # Same parent/tile/transform survives detail swaps, allowing the caller
    # to keep camera focus and selection markers unchanged.
    if root==null or not is_instance_valid(root):
        return false
    if str(root.get_meta("site_kind",""))!=SITE_KIND or not bool(
            root.get_meta("preview_only",false)):
        return false
    if lod not in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        return false
    if int(root.get_meta("workshop_lod",-1))==lod:
        return true
    var level:int=int(root.get_meta("visual_level",0))
    var faction:int=int(root.get_meta("visual_faction",-2))
    var damage:int=int(root.get_meta("visual_damage_stage",-1))
    var replacement:Node3D=Mobile.build(level,faction,damage,lod)
    if replacement==null:
        return false
    replacement.scale=Vector3.ONE*scale_for_level(level)
    for child in root.get_children():
        root.remove_child(child)
        child.free()
    root.add_child(replacement)
    root.set_meta("workshop_lod",lod)
    root.set_meta("workshop_batches",
        int(replacement.get_meta("workshop_batches",0)))
    root.set_meta("workshop_instances",
        int(replacement.get_meta("workshop_instances",0)))
    return true
