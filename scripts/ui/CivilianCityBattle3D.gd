extends RefCounted
class_name TarvokaCivilianCityBattle3D

# Reuse the EXACT civilian V1 + V2 + V3 + V4 artwork from the approved
# standalone studio in the existing read-only playable battle 3D camera.
# Cities remain pre-placed capturable income sites, never factories/HQs.
const City=preload("res://scripts/ui/CivilianCity3DV1.gd")
const LOD=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const Rules=preload("res://scripts/core/Rules.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const CELL_MODEL_SCALE := 0.125
const ART_VERSION := 4

static func tier_for_site(state: Dictionary,site: Dictionary) -> int:
    # Explicit visual tiers always win, with no connection to income.
    if site.has("visual_level"):
        return clampi(int(site["visual_level"]),1,3)
    # Default is mirrored across both army starts: low-rise outskirts and
    # a larger contested center. Big maps may feature a metropolis.
    var position: Vector2i=site.get("pos",Vector2i.ZERO)
    var terrain: Array=state.get("terrain",[])
    var dims: Vector2i=Rules.map_size(terrain) if Rules.valid_terrain(terrain) else Vector2i(10,8)
    if position.y>=int(dims.y/2):
        return 3 if dims.x>=20 else 2
    return 2 if dims.x>=20 else 1

static func damage_for_site(site: Dictionary) -> int:
    # A stage of cosmetic damage, not city HP or capture progression.
    return clampi(int(site.get("visual_damage_stage",0)),0,4)

static func faction_for_public_owner(state: Dictionary,public_owner: int) -> int:
    # Never consult the raw owner here. Fog can show an explored city whose
    # current ownership is unknown; the neutral palette MUST be used.
    if public_owner not in [0,1]:
        return -1
    var faction: int=Identity.index_for(Identity.key_for(state,public_owner))
    return faction if faction>=0 else -1

static func build(level: int,faction: int,damage: int,lod: int=2) -> Node3D:
    if not City.valid_spec(level,faction,damage) or lod<0 or lod>2:
        return null
    # V4.build_tactical creates the whole actual approved V1→V4 sculpt,
    # pruning unnecessary meshes rather than merely hiding them.
    var city: Node3D=LOD.build_tactical(level,faction,damage,lod)
    if city==null:
        return null
    city.name="CiudadCivilRealV4"
    city.scale=Vector3.ONE*CELL_MODEL_SCALE
    city.set_meta("approved_art_version",ART_VERSION)
    city.set_meta("game_visual_only",true)
    city.set_meta("visual_tier",level)
    city.set_meta("visual_damage",damage)
    city.set_meta("actual_3d_meshes",LOD.drawable_count(city))
    return city

static func build_site(state: Dictionary,site: Dictionary,
        public_owner: int,lod: int=2) -> Node3D:
    if str(site.get("kind",""))!="city":
        return null
    var tier: int=tier_for_site(state,site)
    var damage: int=damage_for_site(site)
    var faction: int=faction_for_public_owner(state,public_owner)
    var city: Node3D=build(tier,faction,damage,lod)
    if city!=null:
        city.set_meta("site_kind","city")
        city.set_meta("public_owner",public_owner)
        city.set_meta("visual_faction",faction)
        city.set_meta("tactical_compact",lod>0)
        city.set_meta("city_economy_untouched",true)
    return city

# Runtime LOD swaps the approved V4 sculpt only when the camera crosses
# a hysteresis threshold. The same city root stays at the same tile.
# This avoids keeping all the distant facade meshes alive on Android.
static func set_runtime_detail(city: Node3D,lod: int) -> bool:
    if city==null or not is_instance_valid(city) or lod<0 or lod>2:
        return false
    if int(city.get_meta("approved_art_version",-1))!=ART_VERSION or (
            str(city.get_meta("site_kind",""))!="city"):
        return false
    var old: int=int(city.get_meta("city_lod",2))
    if old==lod:
        return true
    var level: int=int(city.get_meta("visual_level",1))
    var faction: int=int(city.get_meta("visual_faction",-1))
    var damage: int=int(city.get_meta("visual_damage_stage",0))
    if not City.valid_spec(level,faction,damage):
        return false
    # Construct OFF-TREE before removing anything; no partial city on failure.
    var replacement: Node3D=LOD.build_tactical(level,faction,damage,lod)
    if replacement==null:
        return false
    var old_children: Array[Node]=[]
    for child in city.get_children():
        old_children.append(child)
    for child in old_children:
        city.remove_child(child)
        child.free()
    var new_children: Array[Node]=[]
    for child in replacement.get_children():
        new_children.append(child)
    for child in new_children:
        replacement.remove_child(child)
        city.add_child(child)
    city.set_meta("city_lod",lod)
    city.set_meta("city_drawable_count",LOD.drawable_count(city))
    city.set_meta("city_mesh_count",LOD.drawable_count(city))
    city.set_meta("actual_3d_meshes",LOD.drawable_count(city))
    city.set_meta("removed_render_meshes",int(
        replacement.get_meta("removed_render_meshes",0)))
    city.set_meta("tactical_compact",lod>0)
    replacement.free()
    return true
