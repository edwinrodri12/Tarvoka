extends RefCounted
class_name TarvokaArmoredWorkshopBattle3D

# Canonical V2 artwork in the REAL modern armor_plant battle site.
# This renderer is visual-only and never manufactures units, repairs vehicles,
# changes ownership, grants combat to buildings or touches saved state.
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const STYLE=preload("res://scripts/ui/VisualStyle.gd")
const ART_VERSION:int=2
const CELL_MODEL_SCALE:float=0.099
const CHILD_NAME:String="TallerBlindados3DReal"
const SITE_KIND:String="armor_plant"

static func tier_for_site(site:Dictionary) -> int:
    return clampi(int(site.get("visual_level",1)),1,3)

static func damage_for_site(site:Dictionary) -> int:
    # A visual state, NOT HP. The engine cannot attack buildings yet.
    return clampi(int(site.get("visual_damage_stage",0)),0,4)

static func faction_for_owner(state:Dictionary,public_owner:int) -> int:
    if public_owner not in [0,1]:
        return -1 # Real neutral palette, never reveal fog-hidden allegiance.
    var index:int=Identity.index_for(Identity.key_for(state,public_owner))
    return index if index>=0 and index<STYLE.FACTIONS.size() else -1

static func build(level:int,faction:int,damage:int,
        profile:int=Mobile.PROFILE_TACTICAL) -> Node3D:
    if not Hero.valid(level,faction,damage) or profile not in [
            Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        return null
    var model:Node3D=Mobile.build(level,faction,damage,profile)
    if model==null:
        return null
    model.scale=Vector3.ONE*CELL_MODEL_SCALE
    var site:=Node3D.new()
    site.name="TallerBlindadosV2_CasillaReal"
    model.name=CHILD_NAME
    site.add_child(model)
    site.set_meta("site_kind",SITE_KIND)
    site.set_meta("approved_art_version",ART_VERSION)
    site.set_meta("game_visual_only",true)
    site.set_meta("no_gameplay_changes",true)
    site.set_meta("workshop_no_weapon",true)
    site.set_meta("is_fixed_building",true)
    site.set_meta("visual_tier",level)
    site.set_meta("visual_level",level)
    site.set_meta("visual_damage",damage)
    site.set_meta("visual_damage_stage",damage)
    site.set_meta("visual_faction",faction)
    site.set_meta("workshop_lod_profile",profile)
    site.set_meta("workshop_batches",int(model.get_meta("workshop_batches",0)))
    site.set_meta("workshop_instances",int(model.get_meta("workshop_instances",0)))
    site.set_meta("tactical_compact",true)
    return site

static func build_site(state:Dictionary,site:Dictionary,
        public_owner:int) -> Node3D:
    if str(site.get("kind",""))!=SITE_KIND:
        return null
    var level:int=tier_for_site(site)
    var damage:int=damage_for_site(site)
    var faction:int=faction_for_owner(state,public_owner)
    var result:Node3D=build(level,faction,damage)
    if result!=null:
        result.set_meta("public_owner",public_owner)
        result.set_meta("workshop_visual_state_from_site",true)
        result.set_meta("workshop_no_supply_duplication",true)
    return result

static func set_runtime_detail(site_node:Node3D,profile:int) -> bool:
    if site_node==null or not is_instance_valid(site_node):
        return false
    if profile not in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        return false
    if str(site_node.get_meta("site_kind",""))!=SITE_KIND or \
            int(site_node.get_meta("approved_art_version",0))!=ART_VERSION:
        return false
    if int(site_node.get_meta("workshop_lod_profile",-1))==profile:
        return true
    var level:int=int(site_node.get_meta("visual_tier",1))
    var faction:int=int(site_node.get_meta("visual_faction",-1))
    var damage:int=int(site_node.get_meta("visual_damage",0))
    var replacement:Node3D=Mobile.build(level,faction,damage,profile)
    if replacement==null:
        return false
    var current:Node3D=site_node.get_node_or_null(CHILD_NAME) as Node3D
    if current==null:
        replacement.free()
        return false
    # Build OFF-TREE first and preserve world cell root, owner and selection.
    replacement.scale=Vector3.ONE*CELL_MODEL_SCALE
    replacement.name=CHILD_NAME
    site_node.remove_child(current)
    current.free()
    site_node.add_child(replacement)
    site_node.set_meta("workshop_lod_profile",profile)
    site_node.set_meta("workshop_batches",int(replacement.get_meta("workshop_batches",0)))
    site_node.set_meta("workshop_instances",int(replacement.get_meta("workshop_instances",0)))
    return true
