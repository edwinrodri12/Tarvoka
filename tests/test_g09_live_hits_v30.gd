extends SceneTree

const Viewer=preload("res://scripts/ui/Battle3DMapView.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Hit=preload("res://scripts/ui/TankHitReactionV30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _tank(id: String,x: int,y: int,faction: int) -> Dictionary:
    return {"id":id,"role":"tank","faction":faction,"hp":10,
        "pos":Vector2i(x,y),"vision":6,"move_points":4,
        "attack":5,"acted":false}

func _run() -> void:
    var terrain: Array=Scenarios.terrain(0)
    var state: Dictionary=Session.start([
        _tank("FRIEND",1,1,0),_tank("TARGET",3,2,1)
    ],terrain,0,true,false,false,false,false)
    var snapshot: Dictionary=state.duplicate(true)
    var v:=Viewer.new()
    root.add_child(v)
    assert(v.open_from_state(state,"FRIEND"))
    var target: Node3D=v._scene.find_child(
        "Unidad3D_TARGET",true,false) as Node3D
    assert(target!=null and target.get_meta("tarvoka_hit_v30",false))
    assert(target.get_meta("tarvoka_mbt_track_wide_v30",false))
    var identity: int=target.get_instance_id()
    for kind in [Hit.BULLET,Hit.EXPLOSIVE]:
        v._hit_model_id="TARGET"
        v._hit_type=kind
        v._hit_elapsed=0.0
        v._process(0.06)
        assert(target.get_instance_id()==identity)
        var spark: MeshInstance3D=target.find_child(
            "DestelloRicochet",true,false) as MeshInstance3D
        var boom: MeshInstance3D=target.find_child(
            "ExplosionCentral",true,false) as MeshInstance3D
        if kind==Hit.BULLET:
            assert(spark.visible and not boom.visible)
        else:
            assert(boom.visible and not spark.visible)
        v._process(2.5)
        assert(v._hit_model_id.is_empty())
        assert(not spark.visible and not boom.visible)
    assert(state==snapshot)
    v.close_view()
    assert(v._hit_model_id.is_empty())
    v.queue_free()
    print("PASS G09 V30 LIVE: native 3D battle target gets independent bullet/explosive reactions without changing combat state")
    quit(0)
