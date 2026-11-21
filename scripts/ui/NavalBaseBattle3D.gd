extends RefCounted
class_name TarvokaNavalBaseBattle3D

# Read-only model for the EXISTING naval `shipyard` producer on navigable
# water: maps the V13 Naval Base artwork to Android 3D tactical profiles.
# There is NO separate new shipyard building.
const Model=preload("res://scripts/ui/NavalBaseTactical3D.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const SITE_KIND:String="shipyard"
const CHILD_NAME:String="BaseNaval3D_Compacta"
const MODEL_SCALE:float=0.155
const PROFILE_DISTANT:int=Model.PROFILE_DISTANT
const PROFILE_CLOSE:int=Model.PROFILE_CLOSE

static func owner_faction(state:Dictionary,public_owner:int) -> int:
    if public_owner not in [0,1]:
        return -1
    var index:int=Identity.index_for(Identity.key_for(state,public_owner))
    return index if index>=0 and index<Style.FACTIONS.size() else -1

static func build(tier:int,faction:int,damage:int,
        profile:int=PROFILE_DISTANT) -> Node3D:
    var mesh:MeshInstance3D=Model.build_proxy(tier,faction,damage,profile)
    if mesh==null:
        return null
    mesh.scale=Vector3.ONE*MODEL_SCALE
    var root:=Node3D.new()
    root.name="BaseNaval3D_ProduccionExistente"
    root.add_child(mesh)
    root.set_meta("site_kind",SITE_KIND)
    root.set_meta("naval_v13_tactical_reference",true)
    root.set_meta("naval_mobile_profile",profile)
    root.set_meta("visual_level",tier)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("mesh_surface_count",mesh.mesh.get_surface_count())
    root.set_meta("game_visual_only",true)
    root.set_meta("no_building_weapon",true)
    root.set_meta("no_gameplay_changes",true)
    return root

static func build_site(state:Dictionary,site:Dictionary,
        public_owner:int) -> Node3D:
    if str(site.get("kind",""))!=SITE_KIND:
        return null
    var root:Node3D=build(
        clampi(int(site.get("visual_level",1)),1,3),
        owner_faction(state,public_owner),
        clampi(int(site.get("visual_damage_stage",0)),0,4))
    if root!=null:
        root.set_meta("public_owner",public_owner)
        root.set_meta("production_authority","UrbanEconomy")
        root.set_meta("fog_safe_model",true)
    return root

static func set_runtime_detail(root:Node3D,profile:int) -> bool:
    if root==null or not is_instance_valid(root) or \
            str(root.get_meta("site_kind",""))!=SITE_KIND or \
            profile not in [PROFILE_DISTANT,PROFILE_CLOSE]:
        return false
    if int(root.get_meta("naval_mobile_profile",-1))==profile:
        return true
    var tier:int=int(root.get_meta("visual_level",1))
    var faction:int=int(root.get_meta("visual_faction",-1))
    var damage:int=int(root.get_meta("visual_damage_stage",0))
    var fresh:MeshInstance3D=Model.build_proxy(tier,faction,damage,profile)
    if fresh==null:
        return false
    var old:MeshInstance3D=root.get_node_or_null(
        CHILD_NAME) as MeshInstance3D
    if old==null:
        fresh.free()
        return false
    fresh.scale=Vector3.ONE*MODEL_SCALE
    root.remove_child(old)
    old.free()
    root.add_child(fresh)
    root.set_meta("naval_mobile_profile",profile)
    root.set_meta("mesh_surface_count",fresh.mesh.get_surface_count())
    return true
