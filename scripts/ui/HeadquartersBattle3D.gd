extends RefCounted
class_name TarvokaHeadquartersBattle3D

# Same two pre-existing command CITY sites as 2D CommandCityArtV14.
# Art only: no new HQ kind, structure HP, buildings, capture or income rules.
const MapLOD=preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const Command=preload("res://scripts/ui/CommandCityArtV14.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Rules=preload("res://scripts/core/Rules.gd")
const CHILD_NAME:String="CuartelGeneralMapaV6"
const MODEL_SCALE:float=0.152
const DAMAGE_APPEARANCES:=["operativo","leve","moderado","critico","destruido"]

static func build(level:int,faction:int,damage:int) -> Node3D:
    if level<1 or level>3 or faction< -1 or faction>=Style.FACTIONS.size():
        return null
    if damage<0 or damage>=DAMAGE_APPEARANCES.size():
        return null
    var appearance:String=DAMAGE_APPEARANCES[damage]
    var actual:Node3D=MapLOD.build_map_only(level,faction,appearance)
    if actual==null:
        return null
    var root:=Node3D.new()
    root.name="CuartelGeneralTacticoRealV24"
    root.scale=Vector3.ONE*MODEL_SCALE
    root.add_child(actual)
    # Real approved shield atlas, never a fabricated stand-in. The neutral
    # model and collapsed ruins never receive a faction emblem.
    if faction>=0 and damage<4:
        var crest:Texture2D=Style.emblem_texture(faction)
        if crest!=null:
            var shield:=Sprite3D.new()
            shield.name="EscudoOficialDeFaccion"
            shield.texture=crest
            shield.pixel_size=0.0053
            shield.position=Vector3(0,2.87+0.91*float(level-1)+0.76,-3.56)
            shield.rotation.y=PI
            shield.shaded=true
            shield.double_sided=true
            root.add_child(shield)
    root.set_meta("site_kind","visual_headquarters")
    root.set_meta("building_visual","headquarters")
    root.set_meta("visual_tier",level)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("game_visual_only",true)
    root.set_meta("city_economy_untouched",true)
    root.set_meta("hq_art_family","approved V5/V13 tactical sculpt")
    root.set_meta("hq_native_geometry",true)
    return root

static func build_site(state:Dictionary,site:Dictionary,
        public_owner:int,owner_currently_visible:bool=true) -> Node3D:
    if str(site.get("kind",""))!="city":
        return null
    if not site.get("pos") is Vector2i:
        return null
    var terrain:Array=state.get("terrain",[])
    if not Rules.valid_terrain(terrain):
        return null
    var cell:Vector2i=site["pos"]
    if not Command.is_visual_command_city(
            "city",cell,Rules.map_size(terrain)):
        return null
    # Unknown ownership and unsighted upgrades use a public neutral base.
    var faction:int=Command.faction_index(state,public_owner)
    var level:int=clampi(int(site.get("visual_level",1)),1,3) if owner_currently_visible else 1
    var damage:int=clampi(int(site.get("visual_damage_stage",0)),0,4) if owner_currently_visible else 0
    var visual:Node3D=build(level,faction,damage)
    if visual!=null:
        visual.set_meta("public_owner",public_owner)
        visual.set_meta("production_authority","UrbanEconomy")
        visual.set_meta("site_kind","visual_headquarters")
        visual.set_meta("gameplay_site_kind","city")
        visual.set_meta("fog_safe_model",true)
    return visual
