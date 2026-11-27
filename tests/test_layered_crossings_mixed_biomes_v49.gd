extends SceneTree

const Bridges = preload("res://scripts/core/LayeredCrossingsV48.gd")
const Art = preload("res://scripts/ui/LayeredBridgeArtV48.gd")
const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Preview = preload("res://scripts/ui/MixedBiomePreviewV49.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("water" if x==4 else "plain")
        map.append(row)
    var crossing := Vector2i(4,3)
    map[3][4] = "road"
    var before: Array = map.duplicate(true)
    var records: Array = [{"x":4,"y":3,"axis":"ew"}]
    var index: Dictionary = Bridges.index_records(map,records)
    assert(index["valid"])
    var cells: Dictionary = index["cells"]
    assert(not Bridges.index_records(map,records+records)["valid"])
    assert(not Bridges.index_records(map,[{"x":4,"y":3,"axis":"ns"}])["valid"])
    assert(not Bridges.index_records(map,[{"x":4,"y":2,"axis":"ew"}])["valid"])
    assert(Bridges.allows_step(map,cells,Vector2i(3,3),crossing,"ground"))
    assert(Bridges.allows_step(map,cells,Vector2i(4,2),crossing,"naval"))
    assert(not Bridges.allows_step(map,cells,Vector2i(4,2),crossing,"ground"))
    assert(not Bridges.allows_step(map,cells,Vector2i(3,3),crossing,"naval"))
    assert(Bridges.allows_step(map,cells,crossing,Vector2i(4,4),"air"))
    var units: Array = [{"id":"G","pos":crossing,"domain":"ground","faction":0,"hp":10},
        {"id":"N","pos":crossing,"domain":"naval","faction":1,"hp":10},
        {"id":"A","pos":crossing,"domain":"air","faction":1,"hp":10}]
    assert(Bridges.occupancy(map,cells,units)["valid"])
    assert(not Bridges.occupancy(map,cells,units+[units[0].duplicate(true)])["valid"])
    var ground: Dictionary = Bridges.reachable(map,cells,units,crossing,"ground",0,2)
    assert(ground.has(Vector2i(5,3)) and not ground.has(Vector2i(4,4)))
    var naval: Dictionary = Bridges.reachable(map,cells,units,crossing,"naval",1,2)
    assert(naval.has(Vector2i(4,5)) and not naval.has(Vector2i(5,3)))
    var enemy_ship: Array = [units[1]]
    var ground_cross: Dictionary = Bridges.reachable(map,cells,enemy_ship,Vector2i(3,3),"ground",0,2)
    assert(ground_cross.has(crossing) and ground_cross.has(Vector2i(5,3)))
    var enemy_ground: Array = [units[0]]
    var naval_cross: Dictionary = Bridges.reachable(map,cells,enemy_ground,Vector2i(4,2),"naval",1,2)
    assert(naval_cross.has(crossing) and naval_cross.has(Vector2i(4,4)))
    assert(not Bridges.reachable(map,cells,enemy_ground,Vector2i(3,3),"ground",1,2).has(crossing))
    assert(not Rules.reachable(Vector2i(4,2),2,map,[],"naval").has(crossing))
    assert(Bridges.public_cells(cells,{}).is_empty())
    assert(Bridges.public_cells(cells,{crossing:true})==cells)
    assert(map==before)
    _check_layered_session(map,records,crossing)
    _check_fog_supply(map,records,crossing)
    _check_long_supply(map,records,cells)
    _check_geographic_crossings()
    # CPU-readable mesh bounds, not an actual rendered review.
    for axis in ["ew","ns"]:
        var model: Node3D = Art.build(axis)
        assert(model!=null and model.get_child_count()==9)
        assert(float(model.get_meta("clearance"))>=0.9)
        for part in model.get_children():
            var box: BoxMesh = part.mesh
            assert(part.position.y-box.size.y*0.5>=Art.DECK_BOTTOM-0.001)
        model.free()
    assert(Art.build("invalid")==null)

    var cases := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for primary in Scenarios.GEOGRAPHY_BIOMES:
            for secondary in Scenarios.GEOGRAPHY_BIOMES:
                if primary==secondary:
                    continue
                var config: Dictionary = {"version":1,"primary":primary,"secondary":secondary}
                var regions: Dictionary = Regions.generate(1729,dims,config)
                assert(regions.size()==dims.x*dims.y)
                assert(regions==Regions.generate(1729,dims,config))
                var blend := false
                for cell in regions:
                    var region: Dictionary = regions[cell]
                    var weight: int = region["secondary_weight"]
                    assert(weight>=0 and weight<=1000)
                    assert(region==regions[Vector2i(dims.x-1-cell.x,cell.y)])
                    if weight>0 and weight<1000:
                        blend = true
                    if cell.y==0:
                        assert(weight==0)
                    elif cell.y==dims.y-1:
                        assert(weight==1000)
                assert(blend)
                assert(Regions.public_regions(regions,{}).is_empty())
                assert(Regions.public_regions(regions,{Vector2i.ZERO:true}).size()==1)
                cases += 1
    assert(cases==216)
    # Four contrasting region pairs, three supported sizes and two seeds.
    var geographic_cases := 0
    for pair in [["temperate","winter"],["desert","tropical"],["wetland","urban"],["coastal","archipelago"]]:
        var config: Dictionary = {"version":1,"primary":pair[0],"secondary":pair[1]}
        for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
            for seed in [1729,999999]:
                var mixed: Array = Regions.geographic_candidate(seed,dims,config)
                assert(Rules.valid_terrain(mixed))
                assert(mixed==Regions.geographic_candidate(seed,dims,config))
                var connected: Dictionary = Scenarios._geo_reachable_land(mixed,Vector2i(1,Scenarios.scale_y(2,dims)))
                for y in range(dims.y):
                    for x in range(dims.x):
                        assert(mixed[y][x]==mixed[y][dims.x-1-x])
                        if mixed[y][x]!="water":
                            assert(connected.has(Vector2i(x,y)))
                for anchor in Scenarios._large_anchor_cells(dims):
                    if anchor.y>0 and anchor.y<dims.y-1:
                        assert(mixed[anchor.y][anchor.x]!="water")
                geographic_cases += 1
    assert(geographic_cases==24)
    # V50.1 optimized mirrored region generation must be equivalent to
    # independent single-cell sampling, including transition weights.
    var cfg: Dictionary = {"version":1,"primary":"desert","secondary":"tropical"}
    var big := Vector2i(40,30)
    var field: Dictionary = Regions.generate(1729,big,cfg)
    for cell in field:
        assert(field[cell]==Regions.region_at(1729,big,cell,cfg))
    var original: Dictionary = field[Vector2i(39,0)].duplicate(true)
    field[Vector2i.ZERO]["secondary_weight"] = 999
    assert(field[Vector2i(39,0)]==original)
    var terrain: Array = Regions.geographic_candidate(1729,big,cfg)
    var cached_state: Dictionary = Session.start([],terrain)
    cached_state["visual_biome"] = "desert"
    cached_state["map_seed"] = 1729
    cached_state[Scenarios.GEOGRAPHY_FIELD] = Scenarios.GEOGRAPHY_VERSION
    cached_state[Regions.FIELD] = cfg
    cached_state[Regions.SEED_FIELD] = 1729
    cached_state[Regions.GENERATED_FIELD] = true
    var encoded: String = Codec.encode(cached_state)
    assert(not encoded.is_empty() and Codec.decode(encoded)==cached_state)
    var began: int = Time.get_ticks_usec()
    for attempt in range(12):
        assert(Codec.encode(cached_state)==encoded)
    print("V50_CACHED_SAVE_12 ms=",float(Time.get_ticks_usec()-began)/1000.0)
    var changed: Dictionary = cached_state.duplicate(true)
    changed["terrain"][0][0] = "plain" if terrain[0][0]!="plain" else "mountain"
    assert(Codec.encode(changed).is_empty())
    changed = cached_state.duplicate(true)
    changed[Regions.SEED_FIELD] = 1730
    changed["map_seed"] = 1730
    assert(Codec.encode(changed).is_empty())
    assert(Codec.encode(cached_state)==encoded)
    var mix: Dictionary = {"version":1,"primary":"temperate","secondary":"winter"}
    var north := Vector2i(2,0)
    var south := Vector2i(2,7)
    var preview: Image = Preview.build_image(map,1729,mix,{north:true,south:true})
    assert(preview!=null and preview.get_size()==Vector2i(10,8))
    assert(preview.get_pixel(north.x,north.y)!=preview.get_pixel(south.x,south.y))
    assert(preview.get_pixel(0,0).to_html()==Preview.UNKNOWN.to_html())
    var altered: Array = map.duplicate(true)
    altered[0][0] = "mountain"
    var hidden_preview: Image = Preview.build_image(altered,1729,mix,{north:true,south:true})
    assert(preview.get_data()==hidden_preview.get_data())
    assert(Regions.generate(0,Vector2i(10,8),{"version":1,"primary":"desert","secondary":"winter"}).is_empty())
    assert(Regions.generate(1729,Vector2i(10,8),{"version":2,"primary":"desert","secondary":"winter"}).is_empty())
    print("PASS V48_V49_EXPERIMENT: layered crossing, model clearance, 216 mixed region cases")
    quit(0)

func _fixture(id: String,pos: Vector2i,domain: String,side: int) -> Dictionary:
    return {"id":id,"pos":pos,"domain":domain,"faction":side,"hp":10,
        "move_points":2,"attack":4,"defense":1,"cover":0,"acted":false,
        "moved":false,"target_domains":[domain]}

func _check_layered_session(map: Array,records: Array,crossing: Vector2i) -> void:
    var units: Array = [_fixture("G",Vector2i(3,3),"ground",0),
        _fixture("N",crossing,"naval",1),
        _fixture("A",crossing,"air",1),
        _fixture("E",Vector2i(7,3),"ground",1)]
    var state: Dictionary = Session.start_layered(units,map,records)
    assert(not state.is_empty())
    assert(Codec.decode(Codec.encode(state))==state)
    var original: Dictionary = state.duplicate(true)
    var action: Dictionary = Session.move(state,"G",crossing)
    assert(action["valid"] and state==original)
    state = action["state"]
    assert(state["units"][0]["pos"]==crossing)
    assert(state["units"][1]["pos"]==crossing)
    assert(state["units"][2]["pos"]==crossing)
    var choices: Array = Bridges.selectable_units(state,crossing,0,{crossing:true})
    assert(choices.size()==3)
    assert(choices[0]["domain"]=="ground" and choices[0]["friendly"])
    assert(choices[1]["domain"]=="naval" and not choices[1]["friendly"])
    assert(choices[2]["domain"]=="air")
    assert(Bridges.selectable_units(state,crossing,0,{}).is_empty())
    assert(Codec.decode(Codec.encode(state))==state)
    assert(not Session.move(state,"G",Vector2i(5,3))["valid"])
    assert(not Session.attack(state,"G","N")["valid"])
    var turn: Dictionary = Session.end_turn(state)
    assert(turn["valid"])
    var sailed: Dictionary = Session.move(turn["state"],"N",Vector2i(4,5))
    assert(sailed["valid"])
    assert(Codec.decode(Codec.encode(sailed["state"]))==sailed["state"])
    var raw: Dictionary = JSON.parse_string(Codec.encode(state))
    raw[Bridges.FIELD]["version"] = 2
    assert(Codec.decode(JSON.stringify(raw)).is_empty())
    raw = JSON.parse_string(Codec.encode(state))
    raw[Bridges.FIELD]["records"][0]["x"] = 4.5
    assert(Codec.decode(JSON.stringify(raw)).is_empty())
    var unsupported: Dictionary = state.duplicate(true)
    unsupported["map_seed"] = 1729
    assert(Codec.encode(unsupported).is_empty())
    assert(not Session.end_turn(unsupported)["valid"])
    var legacy: Dictionary = Session.start([units[0],units[3]],map)
    var legacy_raw: String = Codec.encode(legacy)
    assert(not legacy_raw.is_empty() and not legacy_raw.contains(Bridges.FIELD))
    assert(Codec.decode(legacy_raw)==legacy)
    var ai_state: Dictionary = Session.start_layered(units,map,records)
    var ai_before: Dictionary = ai_state.duplicate(true)
    var ai: Dictionary = AI.step(ai_state)
    assert(ai["valid"] and ai["action"]=="move")
    assert(ai_state==ai_before)
    assert(ai["state"]["units"][0]["pos"]==Vector2i(5,3))
    assert(Codec.decode(Codec.encode(ai["state"]))==ai["state"])
    # Combat from distinct tiles uses the existing attack engine.
    var combat_units: Array = [_fixture("S",Vector2i(4,2),"naval",0),
        _fixture("T",crossing,"naval",1)]
    var battle: Dictionary = Session.start_layered(combat_units,map,records)
    var hit: Dictionary = Session.attack(battle,"S","T")
    assert(hit["valid"] and hit["damage"]>0)
    assert(Codec.decode(Codec.encode(hit["state"]))==hit["state"])

func _check_fog_supply(map: Array,records: Array,crossing: Vector2i) -> void:
    var scout: Dictionary = _fixture("F",Vector2i(1,3),"ground",0)
    scout["vision"] = 1
    scout["move_points"] = 5
    var hidden: Dictionary = _fixture("H",crossing,"naval",1)
    var fog: Dictionary = Session.start_layered([scout,hidden],map,records,0,"clear",true)
    assert(not fog.is_empty())
    assert(Codec.decode(Codec.encode(fog))==fog)
    var observed: Dictionary = Visibility.observed_state(fog,0)
    assert(observed["units"].size()==1 and observed[Bridges.FIELD]["records"].is_empty())
    assert(not Session.move(fog,"F",crossing)["valid"])
    assert(AI.step(fog)["valid"]==false)
    var moved: Dictionary = Session.move(fog,"F",Vector2i(2,3))
    assert(moved["valid"])
    var reveal: Dictionary = Session.start_layered([_fixture("F",Vector2i(3,3),"ground",0),hidden],map,records,0,"clear",true)
    assert(Visibility.observed_state(reveal,0)[Bridges.FIELD]["records"].size()==1)
    assert(Session.move(reveal,"F",crossing)["valid"])
    # Modern economy on land away from the bridge. Friendly truck can
    # supply a tank from the deck approach, and a unit may be produced at base.
    var tank: Dictionary = Roles.make_unit("T",0,crossing,"tank")
    var truck: Dictionary = Roles.make_unit("L",0,Vector2i(3,3),"logistics")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(7,3),"tank")
    var economy: Dictionary = Session.start_layered([tank,truck,enemy],map,records,0,"clear",false,true,true)
    assert(not economy.is_empty())
    economy["units"][0]["ammo"] = 0
    assert(Logistics.quote(economy,"T")["valid"])
    var supplied: Dictionary = Session.resupply(economy,"T")
    assert(supplied["valid"] and supplied["state"]["units"][0]["ammo"]>0)
    assert(Codec.decode(Codec.encode(supplied["state"]))==supplied["state"])
    var purchased: Dictionary = Session.purchase(economy,Vector2i(0,1),"tank")
    assert(purchased["valid"])
    assert(Codec.decode(Codec.encode(purchased["state"]))==purchased["state"])
    var bad: Dictionary = economy.duplicate(true)
    bad["economy"]["sites"][0]["pos"] = crossing
    assert(not Bridges.state_index(bad)["valid"])
    assert(Codec.encode(bad).is_empty())
    var rotor: Dictionary = Roles.make_unit("R",0,crossing,"attack_heli")
    assert(not Logistics.field_air_service_allowed(economy,rotor))

# V50.9: reverse costs must respect deck/channel and allowed knowledge.
func _check_long_supply(map: Array,records: Array,cells: Dictionary) -> void:
    var ground: Dictionary = Bridges.distances_to(map,cells,[Vector2i(7,3)],"ground")
    assert(ground[Vector2i(2,3)]==10)
    assert(not ground.has(Vector2i(4,2)))
    var naval: Dictionary = Bridges.distances_to(map,cells,[Vector2i(4,5)],"naval")
    assert(naval[Vector2i(4,1)]==8 and not naval.has(Vector2i(5,3)))
    var allowed: Dictionary = {}
    for y in range(8):
        for x in range(10):
            if x!=4:
                allowed[Vector2i(x,y)] = true
    assert(not Bridges.distances_to(map,cells,[Vector2i(7,3)],"ground",false,"clear","foot",allowed).has(Vector2i(2,3)))
    var tank: Dictionary = Roles.make_unit("R",0,Vector2i(7,3),"tank")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(9,7),"tank")
    var state: Dictionary = Session.start_layered([tank,enemy],map,records,0,"clear",false,true,true)
    assert(not state.is_empty())
    state["units"][0]["ammo"] = 0
    var before: Dictionary = state.duplicate(true)
    var result: Dictionary = AI.step(state)
    assert(result["valid"] and result["action"]=="move" and state==before)
    var pos: Vector2i = result["state"]["units"][0]["pos"]
    var return_cost: Dictionary = Bridges.distances_to(map,cells,[Vector2i(0,3)],"ground",true)
    assert(return_cost[pos]<return_cost[Vector2i(7,3)])
    assert(pos.x<7 and Codec.decode(Codec.encode(result["state"]))==result["state"])
    print("PASS V50_9_LONG_SUPPLY: reverse graph, known-only path and legal multi-turn return")

# V51: deterministic topology overlay, no change to seed-generated terrain.
func _check_geographic_crossings() -> void:
    # Deliberate positive fixture: two separated mirrored spans and four
    # safe two-tile approaches. No dependence on random seeds for this test.
    var fixture: Array = Scenarios.terrain(0,Vector2i(24,18))
    for x in [6,17]:
        fixture[8][x] = "road"
        fixture[7][x] = "water"
        fixture[9][x] = "water"
    var candidates: Array = Bridges.geographic_records(fixture)
    assert(candidates==[{"x":6,"y":8,"axis":"ew"},{"x":17,"y":8,"axis":"ew"}])
    assert(Bridges.index_records(fixture,candidates)["valid"])
    fixture[8][8] = "mountain"
    assert(Bridges.geographic_records(fixture).is_empty())
    var cases := 0
    var with_spans := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for biome in Scenarios.GEOGRAPHY_BIOMES:
            for seed in [1,1729,999999]:
                var map: Array = Scenarios.geographic_terrain(seed,dims,biome)
                var before: Array = map.duplicate(true)
                var records: Array = Bridges.geographic_records(map)
                assert(records==Bridges.geographic_records(map) and map==before)
                assert(Bridges.index_records(map,records)["valid"])
                cases += 1
                if records.is_empty():
                    continue
                with_spans += 1
                var cells: Dictionary = Bridges.index_records(map,records)["cells"]
                for cell in cells:
                    assert(cells.get(Vector2i(dims.x-1-cell.x,cell.y))==cells[cell])
                var state: Dictionary = Session.start([Roles.make_unit("P",0,Vector2i(1,Scenarios.scale_y(2,dims)),"tank"),
                    Roles.make_unit("E",1,Vector2i(dims.x-2,Scenarios.scale_y(2,dims)),"tank")],map)
                state["map_seed"] = seed
                state[Scenarios.GEOGRAPHY_FIELD] = Scenarios.GEOGRAPHY_VERSION
                if biome!="temperate":
                    state["visual_biome"] = biome
                var layered: Dictionary = Session.with_geographic_crossings(state)
                assert(not layered.is_empty() and not state.has(Bridges.FIELD))
                assert(layered["terrain"]==before)
                assert(Codec.decode(Codec.encode(layered))==layered)
                var tampered: Dictionary = layered.duplicate(true)
                tampered[Bridges.FIELD]["records"].pop_back()
                assert(Codec.encode(tampered).is_empty())
    assert(cases==81)
    print("V51_GEOGRAPHIC_CROSSINGS maps=",cases," maps_with_safe_spans=",with_spans)
