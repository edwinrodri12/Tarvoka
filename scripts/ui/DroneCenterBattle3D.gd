extends RefCounted
class_name TarvokaDroneCenterBattle3D

# Pure art adapter for EXISTING UrbanEconomy `drone_center` producer.
# This is not a second base, nor a new buildable/economic resource.
const Model=preload("res://scripts/ui/DroneCenterModel3D.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const SITE_KIND:String="drone_center"
const CHILD_NAME:String="CentroDrones3D_Malla"
const SCALE:float=0.159
const DISTANT:int=Model.DISTANT
const CLOSE:int=Model.CLOSE

static func faction_index(state:Dictionary,owner:int) -> int:
    if owner not in [0,1]:
        return -1
    var index:int=Identity.index_for(Identity.key_for(state,owner))
    return index if index>=0 and index<Style.FACTIONS.size() else -1

static func build(tier:int,faction:int,damage:int,
        lod:int=DISTANT) -> Node3D:
    var mesh:MeshInstance3D=Model.build_mesh(tier,faction,damage,lod)
    if mesh==null:
        return null
    mesh.scale=Vector3.ONE*SCALE
    var root:=Node3D.new()
    root.name="CentroDeDrones3D"
    root.add_child(mesh)
    root.set_meta("site_kind",SITE_KIND)
    root.set_meta("drone_center_model_v1",true)
    root.set_meta("drone_center_lod",lod)
    root.set_meta("visual_tier",tier)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("render_surface_count",mesh.mesh.get_surface_count())
    root.set_meta("game_visual_only",true)
    root.set_meta("no_gameplay_changes",true)
    return root

static func build_site(state:Dictionary,site:Dictionary,
        public_owner:int) -> Node3D:
    if str(site.get("kind",""))!=SITE_KIND:
        return null
    var root:Node3D=build(clampi(int(site.get("visual_level",1)),1,3),
        faction_index(state,public_owner),
        clampi(int(site.get("visual_damage_stage",0)),0,4))
    if root!=null:
        root.set_meta("public_owner",public_owner)
        root.set_meta("production_authority","UrbanEconomy")
        root.set_meta("fog_safe_model",true)
    return root

static func set_runtime_detail(root:Node3D,lod:int) -> bool:
    if root==null or not is_instance_valid(root) or \
            str(root.get_meta("site_kind",""))!=SITE_KIND or \
            lod not in [DISTANT,CLOSE]:
        return false
    if int(root.get_meta("drone_center_lod",-1))==lod:
        return true
    var mesh:MeshInstance3D=Model.build_mesh(
        int(root.get_meta("visual_tier",1)),
        int(root.get_meta("visual_faction",-1)),
        int(root.get_meta("visual_damage_stage",0)),lod)
    if mesh==null:
        return false
    var old:MeshInstance3D=root.get_node_or_null(
        CHILD_NAME) as MeshInstance3D
    if old==null:
        mesh.free()
        return false
    mesh.scale=Vector3.ONE*SCALE
    root.remove_child(old)
    old.free()
    root.add_child(mesh)
    root.set_meta("drone_center_lod",lod)
    root.set_meta("render_surface_count",mesh.mesh.get_surface_count())
    return true
