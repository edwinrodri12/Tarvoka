extends RefCounted
class_name TarvokaInfantryBarracksBattle3D

# Canonical, approved V11 model used by the ACTUAL playable battle's
# read-only 3D renderer. The source stages are the exact eleven Godot
# models approved in TARVOKA Estudio 3D (not screenshots or a new viewer).
# No production, capture, economy, ownership or map collision changes.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V4=preload("res://scripts/ui/InfantryBarracksRearFacadeV4.gd")
const V5=preload("res://scripts/ui/InfantryBarracksEntranceYardV5.gd")
const V6=preload("res://scripts/ui/InfantryBarracksRoofCommandV6.gd")
const V7=preload("res://scripts/ui/InfantryBarracksSideTowersV7.gd")
const V8=preload("res://scripts/ui/InfantryBarracksTowerFinishV8.gd")
const V9=preload("res://scripts/ui/InfantryBarracksFinalAccessV9.gd")
const V10=preload("res://scripts/ui/InfantryBarracksFrontWindowV10.gd")
const V11=preload("res://scripts/ui/InfantryBarracksWindowShadeV11.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")

const ART_VERSION=11
const CELL_MODEL_SCALE=0.113
const NEUTRAL_FACTION_ART=7

# A visual tier is not an extra type of production facility and cannot
# confer upgrades or bonuses. The game may explicitly set a visual tier
# for a pre-placed factory; absent that, it uses the ordinary N1 barrack.
static func tier_for_site(site: Dictionary) -> int:
    return clampi(int(site.get("visual_level",1)),1,3)

static func damage_for_site(site: Dictionary) -> int:
    # Not HP: site health does not exist in current game mechanics.
    return clampi(int(site.get("visual_damage_stage",0)),0,4)

static func color_index_for_owner(state: Dictionary,
        public_owner: int) -> int:
    if public_owner not in [0,1]:
        return NEUTRAL_FACTION_ART
    var key: String=Identity.key_for(state,public_owner)
    var index: int=Identity.index_for(key)
    return index if index>=0 else NEUTRAL_FACTION_ART

static func build(level: int,faction: int,damage: int) -> Node3D:
    if not Base.valid_spec(level,faction,damage):
        return null
    var model: Node3D=Base.build(level,faction,damage)
    if model==null:
        return null
    # Keep exactly the same art-stage order and properties as Estudio 3D.
    if (not V2.apply(model,level,faction,damage) or
            not V3.apply(model,level,faction,damage) or
            not V4.apply(model,level,faction,damage) or
            not V5.apply(model,level,faction,damage) or
            not V6.apply(model,level,faction,damage) or
            not V7.apply(model,level,faction,damage) or
            not V8.apply(model,level,faction,damage) or
            not V9.apply(model,level,faction,damage) or
            not V10.apply(model,level,faction,damage) or
            not V11.apply(model,level,faction,damage)):
        model.free()
        return null
    # Original art has ~16m foundation; scale it into the 2.4m square
    # tactical tile without touching adjacent tiles or selection rays.
    model.scale=Vector3.ONE*CELL_MODEL_SCALE
    model.name="CuartelDeInfanteriaFinalV11"
    model.set_meta("approved_art_version",ART_VERSION)
    model.set_meta("game_visual_only",true)
    model.set_meta("actual_3d_meshes",Base.mesh_count(model))
    return model

static func build_site(state: Dictionary,site: Dictionary,
        public_owner: int) -> Node3D:
    if str(site.get("kind",""))!="factory":
        return null
    var level: int=tier_for_site(site)
    var damage: int=damage_for_site(site)
    var color_index: int=color_index_for_owner(state,public_owner)
    var model: Node3D=build(level,color_index,damage)
    if model!=null:
        model.set_meta("site_kind","factory")
        model.set_meta("public_owner",public_owner)
        model.set_meta("visual_tier",level)
        model.set_meta("visual_damage",damage)
    return model
