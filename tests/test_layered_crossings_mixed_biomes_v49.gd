extends SceneTree

const Bridges = preload("res://scripts/core/LayeredCrossingsV48.gd")
const Art = preload("res://scripts/ui/LayeredBridgeArtV48.gd")
const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
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
    unsupported["fog_enabled"] = true
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
