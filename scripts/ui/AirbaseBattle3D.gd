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

static func build(level:int,faction:int,damage:int) -> Node3D:
    var mesh:MeshInstance3D=Proxy.build_proxy(level,faction,damage)
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
