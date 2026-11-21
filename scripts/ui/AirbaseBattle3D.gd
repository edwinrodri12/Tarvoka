extends RefCounted
class_name TarvokaAirbaseBattle3D

# Gameplay bridge for the ALREADY-EXISTING modern airbase producer.
# Approved V4 tactical 3D art, reused from the V16 Airbase Studio lineage.
# One native MeshInstance, four material surfaces, zero extra economy logic.
const Proxy=preload("res://scripts/ui/AirbaseMapLODV4.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const SITE_KIND:String="airbase"
const CHILD_NAME:String="BaseAereaMapaV4_UnaMalla"
const CELL_MODEL_SCALE:float=0.159
const PROFILE_DISTANT:int=Proxy.PROFILE_DISTANT
const PROFILE_CLOSE:int=Proxy.PROFILE_CLOSE

static func tier_for_site(site:Dictionary) -> int:
    return clampi(int(site.get("visual_level",1)),1,3)

static func damage_for_site(site:Dictionary) -> int:
    # Visual only. Buildings have no attackable HP in this ruleset.
    return clampi(int(site.get("visual_damage_stage",0)),0,4)

static func faction_for_owner(state:Dictionary,public_owner:int) -> int:
    if public_owner not in [0,1]:
        return -1
    var index:int=Identity.index_for(Identity.key_for(state,public_owner))
    return index if index>=0 and index<Style.FACTIONS.size() else -1

static func build(level:int,faction:int,damage:int,
        profile:int=PROFILE_DISTANT) -> Node3D:
    var mesh:MeshInstance3D=Proxy.build_proxy(level,faction,damage,profile)
    if mesh==null:
        return null
    mesh.name=CHILD_NAME
    mesh.scale=Vector3.ONE*CELL_MODEL_SCALE
    var root:=Node3D.new()
    root.name="BaseAerea_Produccion3D_Real"
    root.add_child(mesh)
    root.set_meta("site_kind",SITE_KIND)
    root.set_meta("native_airbase_tactical_v4",true)
    root.set_meta("game_visual_only",true)
    root.set_meta("no_gameplay_changes",true)
    root.set_meta("is_fixed_building",true)
    root.set_meta("no_building_weapon",true)
    root.set_meta("visual_tier",level)
    root.set_meta("visual_damage",damage)
    root.set_meta("visual_faction",faction)
    root.set_meta("airbase_mesh_surfaces",Proxy.surface_budget(mesh))
    root.set_meta("airbase_lod_profile",profile)
    root.set_meta("airbase_close_fidelity",profile==PROFILE_CLOSE)
    root.set_meta("airbase_approved_studio_art","Airbase V16 source")
    return root

static func build_site(state:Dictionary,site:Dictionary,
        public_owner:int) -> Node3D:
    if str(site.get("kind",""))!=SITE_KIND:
        return null
    var scene:Node3D=build(tier_for_site(site),
        faction_for_owner(state,public_owner),damage_for_site(site))
    if scene!=null:
        scene.set_meta("public_owner",public_owner)
        scene.set_meta("production_authority","UrbanEconomy")
        scene.set_meta("fog_safe_model",true)
    return scene

# Toggle only the visible art mesh. Camera zoom can never modify economy,
# the public fog-filtered faction, building level, selection or owner.
static func set_runtime_detail(root:Node3D,profile:int) -> bool:
    if root==null or not is_instance_valid(root):
        return false
    if str(root.get_meta("site_kind",""))!=SITE_KIND or \
            profile not in [PROFILE_DISTANT,PROFILE_CLOSE]:
        return false
    if int(root.get_meta("airbase_lod_profile",-1))==profile:
        return true
    var level:int=int(root.get_meta("visual_tier",1))
    var faction:int=int(root.get_meta("visual_faction",-1))
    var damage:int=int(root.get_meta("visual_damage",0))
    var updated:MeshInstance3D=Proxy.build_proxy(
        level,faction,damage,profile)
    if updated==null:
        return false
    var current:MeshInstance3D=root.get_node_or_null(
        CHILD_NAME) as MeshInstance3D
    if current==null:
        updated.free()
        return false
    updated.name=CHILD_NAME
    updated.scale=Vector3.ONE*CELL_MODEL_SCALE
    root.remove_child(current)
    current.free()
    root.add_child(updated)
    root.set_meta("airbase_lod_profile",profile)
    root.set_meta("airbase_close_fidelity",profile==PROFILE_CLOSE)
    root.set_meta("airbase_mesh_surfaces",Proxy.surface_budget(updated))
    return true
