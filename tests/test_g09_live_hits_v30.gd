extends SceneTree

const Viewer=preload("res://scripts/ui/Battle3DMapView.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Hit=preload("res://scripts/ui/TankHitReactionV30.gd")
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Damage=preload("res://scripts/ui/TankDamage3D.gd")
const Rig=preload("res://scripts/ui/TankVisualRig3D.gd")

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
    # The G09 itself now aims and fires in the LIVE battle viewer after
    # orders succeed, not only when previewed in the art studio.
    var shooter: Node3D=v._scene.find_child(
        "Unidad3D_FRIEND",true,false) as Node3D
    assert(shooter!=null and shooter.get_meta("tarvoka_hit_v30",false))
    var muzzle: Node3D=shooter.find_child(
        "EfectoFogonazoCanon",true,false) as Node3D
    var turret: Node3D=shooter.find_child(
        "TorretaGiratoria",true,false) as Node3D
    assert(muzzle!=null and turret!=null)
    v._shot_model_id="FRIEND"
    v._shot_heading=Vector2i(1,0)
    v._shot_elapsed=0.0
    v._process(0.005)
    assert(not muzzle.visible)
    v._process(Rig.SHOT_DURATION*0.44)
    assert(muzzle.visible)
    assert(absf(turret.rotation_degrees.y)>25.0)
    v._process(Rig.SHOT_DURATION*2.0)
    assert(v._shot_model_id.is_empty())
    assert(not muzzle.visible)

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
    # Real HP -> permanent damage stages, entirely cosmetic.
    var wounded: Dictionary=state.duplicate(true)
    for item in wounded["units"]:
        if item["id"]=="TARGET":
            item["hp"]=4
    var wounded_scene: Node3D=Terrain.build(wounded,"FRIEND",12.0,true)
    var wounded_model: Node3D=wounded_scene.find_child(
        "Unidad3D_TARGET",true,false) as Node3D
    assert(wounded_model!=null)
    assert(Damage.current_stage(wounded_model)==2)
    assert(wounded_model.get_meta("tarvoka_damage_polished_v30",false))
    var fragment: MeshInstance3D=wounded_model.find_child(
        "BlindajeDesgarradoReal",true,false) as MeshInstance3D
    assert(fragment!=null and fragment.visible)
    wounded_scene.free()
    v.close_view()
    assert(v.open_from_state(wounded,"FRIEND"))
    assert(v._damage_smoke_elapsed==0.0)
    v._process(0.23)
    assert(v._damage_smoke_elapsed>0.20)
    var damaged_tank: Node3D=v._scene.find_child(
        "Unidad3D_TARGET",true,false) as Node3D
    assert(damaged_tank!=null and Damage.current_stage(damaged_tank)==2)
    assert(state==snapshot)
    v.close_view()
    assert(v._hit_model_id.is_empty())
    v.queue_free()
    print("PASS G09 V30 LIVE: battle tank fires, target receives ballistic/explosive shock, damaged smoke animates and combat state stays unchanged")
    quit(0)
