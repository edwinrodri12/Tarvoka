extends SceneTree

# V24: actual two city landmarks get native grouped 3D HQ geometry in
# live BattleTerrain3D; not another economic site, rule, or building HP.
const Battle=preload("res://scripts/ui/BattleTerrain3D.gd")
const HQ=preload("res://scripts/ui/HeadquartersBattle3D.gd")
const MapLOD=preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const Curves=preload("res://scripts/ui/HeadquartersCurvedRoof3D.gd")
const Command=preload("res://scripts/ui/CommandCityArtV14.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _at(battle:Node3D,cell:Vector2i) -> Node3D:
    return battle.find_child("Instalacion3D_city_%d_%d" % [
        cell.x,cell.y],true,false) as Node3D

static func _mesh(model:Node3D) -> MeshInstance3D:
    var body:Node3D=model.get_node_or_null(HQ.CHILD_NAME)
    if body==null:
        return null
    return body.get_node_or_null("MallaConsolidadaMapaV5") as MeshInstance3D

func _run() -> void:
    assert(HQ.build(0,0,0)==null)
    assert(HQ.build(1,8,0)==null)
    assert(HQ.build(1,-2,0)==null)
    assert(HQ.build(1,0,-1)==null)
    assert(HQ.build(1,0,5)==null)
    # Do not leak even a temporary native MeshInstance3D at test shutdown;
    # Godot Compatibility CI treats abandoned graphics RIDs as failures.
    var neutral_probe:Node3D=MapLOD.build_map_only(1,-1,"operativo")
    assert(neutral_probe!=null)
    neutral_probe.free()
    var tested:int=0
    for tier in [1,2,3]:
        for damage in [0,1,2,3,4]:
            for faction in range(-1,8):
                var sample:Node3D=HQ.build(tier,faction,damage)
                assert(sample!=null)
                assert(sample.get_meta("hq_native_geometry",false))
                assert(sample.get_meta("game_visual_only",false))
                var piece:MeshInstance3D=_mesh(sample)
                assert(piece!=null and piece.mesh is ArrayMesh)
                assert(piece.mesh.get_surface_count()==6)
                var arches:MeshInstance3D=sample.get_node_or_null(
                    Curves.NAME) as MeshInstance3D
                assert(arches!=null and arches.mesh!=null)
                assert(arches.mesh.get_surface_count()==3)
                assert(arches.mesh.get_faces().size()>0)
                assert(int(sample.get_meta("hq_material_surfaces",0))==9)
                assert(piece.get_aabb().size.x*HQ.MODEL_SCALE<2.40)
                assert(piece.get_aabb().size.z*HQ.MODEL_SCALE<2.40)
                assert(sample.get_meta("visual_damage_stage")==damage)
                assert(sample.get_meta("visual_faction")==faction)
                var crest:Node3D=sample.get_node_or_null(
                    "EscudoOficialDeFaccion")
                assert((crest!=null)==(faction>=0 and damage<4))
                sample.free()
                tested+=1
    assert(tested==135)
    var terrain:Array=Scenarios.terrain(0)
    var state:Dictionary=Session.start(Roles.experimental_armies(),
        terrain,0,false,false,true,true)
    var before:Dictionary=state.duplicate(true)
    var headquarters:Array=[Vector2i(2,1),Vector2i(7,1)]
    for other_size in [Vector2i(24,18),Vector2i(40,30)]:
        var bigger:Array=Scenarios.terrain(0,other_size)
        var bigger_economy:Dictionary=Economy.create(bigger,true)
        var total:int=0
        for site in bigger_economy["sites"]:
            if Command.is_visual_command_city(str(site["kind"]),
                    site["pos"],other_size):
                total+=1
        assert(total==2)
    var original_count:int=state["economy"]["sites"].size()
    var render:Node3D=Battle.build(state,"",0)
    assert(render!=null)
    for capital in headquarters:
        var model:Node3D=_at(render,capital)
        assert(model!=null)
        assert(model.get_meta("site_kind")=="visual_headquarters")
        assert(model.get_meta("kind")=="city")
        assert(model.get_meta("battle_cell")==capital)
        assert(_mesh(model)!=null)
        assert(model.get_meta("production_authority")=="UrbanEconomy")
    for ordinary in [Vector2i(3,4),Vector2i(6,4)]:
        var city:Node3D=_at(render,ordinary)
        assert(city!=null and city.get_meta("site_kind")=="city")
    assert(state==before)
    assert(state["economy"]["sites"].size()==original_count)
    assert(Economy.income_for(state["economy"],0)==Economy.MODERN_CITY_INCOME)
    render.free()

    # All approved faction mappings must color the same actual HQ tiles.
    for faction in range(8):
        var color_state:Dictionary=state.duplicate(true)
        color_state[Identity.STATE_FIELD]={
            "0":str(Style.FACTIONS[faction]["key"]),
            "1":str(Style.FACTIONS[(faction+1)%8]["key"])}
        var capital_site:Dictionary=Economy.site_at(
            color_state["economy"],headquarters[0])
        var colored:Node3D=HQ.build_site(color_state,capital_site,0,true)
        assert(colored!=null)
        assert(int(colored.get_meta("visual_faction",-1))==faction)
        assert(colored.has_node("EscudoOficialDeFaccion"))
        colored.free()
    var captured:Dictionary=state.duplicate(true)
    Economy.site_at(captured["economy"],headquarters[0])["owner"]=1
    var captured_render:Node3D=Battle.build(captured,"",0)
    var painted:Node3D=_at(captured_render,headquarters[0])
    assert(int(painted.get_meta("visual_faction",-1))==
        Identity.index_for(Identity.key_for(captured,1)))
    assert(Economy.income_for(captured["economy"],1)==
        Economy.MODERN_CITY_INCOME*2)
    captured_render.free()

    # In unexplored fog, there is no building. Explored-but-unsighted
    # shows only N1 D0 neutral (no crest, owner, or recent upgrade).
    var fog:Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true,true)
    var rival:Vector2i=headquarters[1]
    var hidden:Node3D=Battle.build(fog,"",0)
    assert(_at(hidden,rival)==null)
    hidden.free()
    fog["explored"]["0"].append(rival)
    var foe_site:Dictionary=Economy.site_at(fog["economy"],rival)
    foe_site["visual_level"]=3
    foe_site["visual_damage_stage"]=4
    var state_fog_saved:Dictionary=fog.duplicate(true)
    var remembered:Node3D=Battle.build(fog,"",0)
    var neutral:Node3D=_at(remembered,rival)
    assert(neutral!=null)
    assert(int(neutral.get_meta("visual_faction",99))==-1)
    assert(int(neutral.get_meta("visual_tier",99))==1)
    assert(int(neutral.get_meta("visual_damage_stage",99))==0)
    assert(not neutral.has_node("EscudoOficialDeFaccion"))
    assert(fog==state_fog_saved)
    remembered.free()
    print("PASS HQ V24 LIVE 3D: 2 original command cities, 135 native variants, authentic 3D curved roofs, official crests, neutral fog, saved economy and scaled 3D footprint")
    quit(0)
