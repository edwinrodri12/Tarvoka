extends SceneTree

const Bridges = preload("res://scripts/core/LayeredCrossingsV48.gd")
const Art = preload("res://scripts/ui/LayeredBridgeArtV48.gd")
const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Rules = preload("res://scripts/core/Rules.gd")
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
