extends SceneTree

# Real BattleSession modern producers, not a second mock economy.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Airbase=preload("res://scripts/ui/AirbaseBattle3D.gd")
const Proxy=preload("res://scripts/ui/AirbaseMapLODV4.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _find(root:Node3D,cell:Vector2i) -> Node3D:
    return root.find_child("Instalacion3D_airbase_%d_%d" % [
        cell.x,cell.y],true,false) as Node3D

func _run() -> void:
    assert(Airbase.build(0,0,0)==null)
    assert(Airbase.build(1,8,0)==null)
    assert(Airbase.build(1,-2,0)==null)
    assert(Airbase.build(1,0,5)==null)
    assert(Airbase.build_site({},{"kind":"factory"},0)==null)
    var terrain:Array=Scenarios.terrain(0)
    var state:Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true,true)
    assert(bool(state["economy"].get("modern",false)))
    var airfields:Array=[]
    for item in state["economy"]["sites"]:
        if str(item.get("kind",""))=="airbase":
            airfields.append(item["pos"])
    assert(airfields.size()==2)
    var old:Dictionary=state.duplicate(true)
    var battle:Node3D=Terrain.build(state,"",0)
    assert(battle!=null)
    for cell in airfields:
        var model:Node3D=_find(battle,cell)
        assert(model!=null,"Real airbase stayed a generic cube")
        assert(str(model.get_meta("kind",""))=="airbase")
        assert(bool(model.get_meta("native_airbase_tactical_v4",false)))
        assert(bool(model.get_meta("game_visual_only",false)))
        assert(str(model.get_meta("production_authority",""))=="UrbanEconomy")
        assert(int(model.get_meta("airbase_mesh_surfaces",99))==4)
        assert(model.get_meta("battle_cell") == cell)
        assert(int(model.get_meta("visual_tier",0))==1)
        assert(int(model.get_meta("visual_damage",-1))==0)
        var child:MeshInstance3D=model.get_node(Airbase.CHILD_NAME)
        assert(child!=null and child.mesh!=null)
        assert(child.scale.is_equal_approx(
            Vector3.ONE*Airbase.CELL_MODEL_SCALE))
        assert(child.mesh.get_surface_count()==4)
    assert(state==old,"Render mutated real economy")
    battle.free()

    # Every approved faction, tier and visual damage can render in ONE
    # four-surface native model without creating 120 real producer sites.
    var variants:int=0
    for tier in [1,2,3]:
        for damage in [0,1,2,3,4]:
            for faction in range(8):
                var sample:Node3D=Airbase.build(tier,faction,damage)
                assert(sample!=null)
                assert(int(sample.get_meta("airbase_mesh_surfaces",99))==4)
                assert(int(sample.get_meta("visual_faction",-1))==faction)
                sample.free()
                variants+=1
    assert(variants==120)
    var neutral:Node3D=Airbase.build(3,-1,4)
    assert(neutral!=null and int(
        neutral.get_meta("visual_faction",99))==-1)
    neutral.free()
    for faction in range(8):
        var colored:Dictionary=old.duplicate(true)
        var mapping:Dictionary=Identity.from_state(colored)
        mapping["0"]=str(Style.FACTIONS[faction]["key"])
        mapping["1"]=str(Style.FACTIONS[(faction+1)%8]["key"])
        assert(Identity.is_valid(mapping),"The two armies need distinct official identities")
        colored[Identity.STATE_FIELD]=mapping
        var owned:Node3D=Airbase.build_site(colored,
            Economy.site_at(colored["economy"],airfields[0]),0)
        assert(owned!=null)
        assert(int(owned.get_meta("visual_faction",-1))==faction)
        owned.free()

    # Hidden enemy installations must not reveal their present level,
    # damage or faction paint even when their position is explored.
    var fog:Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true,true)
    var foe:Vector2i=airfields[1]
    var unknown:Node3D=Terrain.build(fog,"",0)
    assert(unknown!=null)
    assert(_find(unknown,foe)==null,"Undiscovered airbase leaked")
    unknown.free()
    fog["explored"]["0"].append(foe)
    var target:Dictionary=Economy.site_at(fog["economy"],foe)
    target["visual_level"]=3
    target["visual_damage_stage"]=4
    var saved:Dictionary=fog.duplicate(true)
    var explored:Node3D=Terrain.build(fog,"",0)
    assert(explored!=null)
    var silhouette:Node3D=_find(explored,foe)
    assert(silhouette!=null,"Explored site should remain remembered")
    assert(int(silhouette.get_meta("visual_faction",99))==-1)
    assert(int(silhouette.get_meta("visual_tier",99))==1)
    assert(int(silhouette.get_meta("visual_damage",99))==0)
    assert(fog==saved,"Fog rendering mutated state")
    explored.free()
    assert(state==old)
    print("PASS AIRBASE REAL BATTLE V1: actual airbase producers, ",
        variants," faction/level/damage variants, neutral silhouette, ",
        "four-surface Android model, fog safety and unchanged economy")
    quit(0)
