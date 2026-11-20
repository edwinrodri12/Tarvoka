extends SceneTree

# Verify approved workshop V2 in actual modern playable 3D battle.
# This is NOT a nine-tile art-studio fixture; Terrain.build() must use
# the canonical pre-existing armor_plant producers without gameplay changes.
const Workshop=preload("res://scripts/ui/ArmoredWorkshopBattle3D.gd")
const Driver=preload("res://scripts/ui/ArmoredWorkshopBattleLOD.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const LEFT=Vector2i(0,1)
const RIGHT=Vector2i(9,1)

func _initialize() -> void:
    call_deferred("_run")

static func _find(root:Node3D,cell:Vector2i) -> Node3D:
    return root.find_child(
        "Instalacion3D_armor_plant_%d_%d" % [cell.x,cell.y],
        true,false) as Node3D

func _run() -> void:
    assert(Workshop.build(0,0,0)==null)
    assert(Workshop.build(2,9,0)==null)
    assert(Workshop.build(2,0,5)==null)
    assert(Workshop.build(2,0,0,0)==null,
        "Battle must use Android profile, not hundreds of HERO meshes")
    var terrain:Array=Scenarios.terrain(0)
    var state:Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true)
    assert(not state.is_empty() and state["economy"].get("modern",false))
    assert(Economy.site_at(state["economy"],LEFT)["kind"]=="armor_plant")
    assert(Economy.site_at(state["economy"],RIGHT)["kind"]=="armor_plant")
    var original:Dictionary=state.duplicate(true)
    var scene:Node3D=Terrain.build(state,"",0)
    assert(scene!=null,"Modern battle scene could not build")
    var driver:Node=scene.get_node_or_null("TallerBlindadosLOD_Camara")
    assert(driver!=null and driver is TarvokaArmoredWorkshopBattleLOD)
    assert(driver.registered_count()==2)
    for cell in [LEFT,RIGHT]:
        var model:Node3D=_find(scene,cell)
        assert(model!=null,"Real armor_plant remained generic cube")
        assert(model.get_meta("kind","")=="armor_plant")
        assert(model.get_meta("site_kind","")=="armor_plant")
        assert(int(model.get_meta("approved_art_version",0))==2)
        assert(model.get_meta("game_visual_only",false))
        assert(model.get_meta("no_gameplay_changes",false))
        assert(model.get_meta("workshop_no_supply_duplication",false))
        assert(model.get_meta("workshop_no_weapon",false))
        assert(int(model.get_meta("visual_tier",0))==1)
        assert(int(model.get_meta("visual_damage",-1))==0)
        var child:Node3D=model.get_node_or_null(Workshop.CHILD_NAME) as Node3D
        assert(child!=null)
        assert(child.scale.is_equal_approx(
            Vector3.ONE*Workshop.CELL_MODEL_SCALE))
        assert(int(child.get_meta("workshop_lod_profile",0))==
            Mobile.PROFILE_TACTICAL)
        assert(int(child.get_meta("workshop_batches",0))>0)
        var persistent_id:int=model.get_instance_id()
        var persistent_position:Vector3=model.position
        assert(Workshop.set_runtime_detail(model,Mobile.PROFILE_DISTANT))
        assert(model.get_instance_id()==persistent_id)
        assert(model.position.is_equal_approx(persistent_position))
        assert(int(model.get_meta("workshop_lod_profile",0))==
            Mobile.PROFILE_DISTANT)
        assert(Workshop.set_runtime_detail(model,Mobile.PROFILE_TACTICAL))
        assert(int(model.get_meta("workshop_lod_profile",0))==
            Mobile.PROFILE_TACTICAL)
    assert(state==original,"3D map mutated game state/economy")
    scene.free()
    # Explicit visual tiers and stage D0-D4 must rebuild real geometry,
    # without changing money, site ownership or available unit catalog.
    for tier in [1,2,3]:
        for damage in [0,1,2,3,4]:
            var changed:Dictionary=original.duplicate(true)
            var left:Dictionary=Economy.site_at(changed["economy"],LEFT)
            left["visual_level"]=tier
            left["visual_damage_stage"]=damage
            var before:Dictionary=changed.duplicate(true)
            var render:Node3D=Terrain.build(changed,"",0)
            assert(render!=null)
            var art:Node3D=_find(render,LEFT)
            assert(art!=null and int(art.get_meta("visual_tier",0))==tier)
            assert(int(art.get_meta("visual_damage",-1))==damage)
            assert(int(art.get_meta("visual_faction",-2))>=0)
            assert(art.get_meta("kind","")=="armor_plant")
            var child:Node3D=art.get_node(Workshop.CHILD_NAME) as Node3D
            assert(int(child.get_meta("workshop_bays",0))==tier)
            assert(int(child.get_meta("workshop_damage",-1))==damage)
            assert(changed==before,
                "Visual tier/damage must not alter balance or economy")
            render.free()
    # All eight official faction colors are selectable in a real site.
    for faction in range(8):
        var colored:Dictionary=original.duplicate(true)
        var visual:Dictionary=Identity.from_state(colored)
        visual["0"]=str(Style.FACTIONS[faction]["key"])
        visual["1"]=str(Style.FACTIONS[(faction+1)%8]["key"])
        colored[Identity.STATE_FIELD]=visual
        var building:Node3D=Workshop.build_site(
            colored,Economy.site_at(colored["economy"],LEFT),0)
        assert(building!=null)
        assert(int(building.get_meta("visual_faction",-1))==faction)
        assert(building.get_meta("public_owner")==0)
        building.free()
    # Modern fog hides unexplored enemy armor installations entirely.
    var fog:Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true)
    assert(not fog.is_empty())
    var unknown:Node3D=Terrain.build(fog,"",0)
    assert(unknown!=null)
    assert(_find(unknown,RIGHT)==null,
        "Undiscovered hostile workshop leaks through fog")
    unknown.free()
    fog["explored"]["0"].append(RIGHT)
    var remembered:Node3D=Terrain.build(fog,"",0)
    assert(remembered!=null)
    var neutral:Node3D=_find(remembered,RIGHT)
    assert(neutral!=null)
    assert(neutral.get_meta("owner_public",-99)==-1)
    assert(int(neutral.get_meta("visual_faction",-99))==-1,
        "Fog-hidden enemy faction color leaked")
    remembered.free()
    assert(original==state)
    print("PASS WORKSHOP LIVE BATTLE: actual modern armor_plant sites, ",
        "N1-N3 x D0-D4, 8 palettes, visual-only production-safe, ",
        "fog-hidden neutral, stable 2.4m tile, 2 mobile LODs")
    quit(0)
