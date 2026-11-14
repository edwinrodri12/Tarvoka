extends SceneTree

# G09 V27 integration/Android visual budget regression.
# Uses the ACTUAL BattleSession, BattleTerrain3D and Battle3DMapView;
# assert rendering of real 25-art G09 mesh inside playable tactical map.
const Renderer = preload("res://scripts/ui/BattleTerrain3D.gd")
const Viewer = preload("res://scripts/ui/Battle3DMapView.gd")
const Budget = preload("res://scripts/ui/TankBattleLOD27.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _unit(id: String,x: int,y: int,role: String="tank",
        faction: int=0) -> Dictionary:
    return {"id":id,"role":role,"faction":faction,"hp":10,
        "pos":Vector2i(x,y),"vision":5,"move_points":4,
        "attack":5,"acted":false}

func _assert_tank(scene: Node3D,id: String,art: int) -> Node3D:
    var model: Node3D = scene.find_child(
        "Unidad3D_"+id,true,false) as Node3D
    assert(model!=null)
    assert(int(model.get_meta("battle_art_level",-1))==art)
    if art==25:
        assert(model.get_meta("tarvoka_mbt_wear_v25",false))
        assert(model.get_meta("tarvoka_mbt_gun_v22",false))
        assert(Models.paintable_count(model)==14)
    else:
        assert(not model.get_meta("tarvoka_mbt_wear_v25",false))
    return model

func _run() -> void:
    assert(Budget.tier(55.0)==Budget.FAR)
    assert(Budget.tier(31.0)==Budget.MEDIUM)
    assert(Budget.tier(12.0)==Budget.HERO)
    assert(Budget.tank_art_level(10.0,true,true,0,0)==25)
    assert(Budget.tank_art_level(10.0,false,true,0,0)==10)
    assert(Budget.tank_art_level(10.0,true,false,0,0)==10)
    assert(Budget.tank_art_level(33.0,true,true,0,0)==10)
    assert(Budget.tank_art_level(55.0,true,true,0,0)==6)
    assert(Budget.tank_art_level(10.0,true,true,1,0)==10)
    assert(Budget.tank_art_level(19.0,false,true,0,4)==6)

    var flat: Array = Scenarios.terrain(0)
    var state: Dictionary = Session.start([
        _unit("T0",1,1),_unit("T1",2,1),_unit("T2",3,1),
        _unit("L0",1,2,"line"),
        _unit("ENEMY",5,5,"tank",1)
    ],flat,0,true,false,false,false,false)
    var before: Dictionary = state.duplicate(true)
    var far: Node3D = Renderer.build(state,"T0",55.0,true)
    assert(far!=null and far.get_meta("visual_only",false))
    _assert_tank(far,"T0",6)
    var far_stats: Dictionary = far.get_meta("render_stats")["units"]
    assert(int(far_stats["g09_v25"])==0)
    assert(int(far_stats["g09_v10"])==0)
    assert(int(far_stats["g09_v6"])>=3)

    var medium_stats: Dictionary = Renderer.refresh_unit_lod(
        far,state,"T0",29.0,true)
    assert(int(medium_stats["g09_v25"])==0)
    assert(int(medium_stats["g09_v10"])>=3)
    _assert_tank(far,"T0",10)
    assert(far.get_meta("battle_camera_size")==29.0)
    var hero_stats: Dictionary = Renderer.refresh_unit_lod(
        far,state,"T0",12.0,true)
    assert(int(hero_stats["g09_v25"])==1)
    assert(int(hero_stats["g09_v10"])>=2)
    var hero: Node3D = _assert_tank(far,"T0",25)
    assert(hero.get_meta("battle_g09_v25",false))
    assert(Models.inspect_meshes(hero)>Models.inspect_meshes(
        _assert_tank(far,"T1",10)))
    assert(far.find_child("UnidadesDinamicasG09",false,false).get_child_count()==
        int(hero_stats["visible"]))
    var economy_stats: Dictionary = Renderer.refresh_unit_lod(
        far,state,"T0",12.0,false)
    assert(int(economy_stats["g09_v25"])==0)
    assert(int(economy_stats["g09_v10"])>=3)
    _assert_tank(far,"T0",10)
    assert(state==before)
    far.free()

    var viewer := Viewer.new()
    root.add_child(viewer)
    assert(viewer.open_from_state(state,"T0"))
    assert(viewer.visible)
    assert(viewer._scene.get_meta("visual_only",false))
    var yaw: float = viewer._yaw
    var initial_zoom: float = viewer._camera_size
    assert(viewer._g09_high_detail)
    assert(viewer._g09_detail_button!=null)
    assert(viewer._scene.get_meta("battle_v25_enabled",false))
    viewer._zoom_anchored(0.30,viewer.holder.size*0.5)
    assert(viewer._camera_size<initial_zoom)
    assert(viewer._g09_lod_band==Budget.HERO)
    _assert_tank(viewer._scene,"T0",25)
    assert(is_equal_approx(viewer._yaw,yaw))
    viewer._toggle_g09_detail()
    assert(not viewer._g09_high_detail)
    _assert_tank(viewer._scene,"T0",10)
    viewer._toggle_g09_detail()
    assert(viewer._g09_high_detail)
    _assert_tank(viewer._scene,"T0",25)
    viewer._zoom_anchored(12.0,viewer.holder.size*0.5)
    assert(viewer._g09_lod_band==Budget.FAR)
    _assert_tank(viewer._scene,"T0",6)
    assert(viewer._scene.get_meta("public_cells").size()==
        state["terrain"].size()*state["terrain"][0].size())
    assert(state==before)
    viewer.close_view()
    assert(not viewer.visible)
    viewer.queue_free()

    # A player may never discover an invisible opponent via a camera zoom.
    var fog: Dictionary = Session.start([
        _unit("T0",1,1),
        _unit("SECRET",flat[0].size()-2,flat.size()-2,"tank",1)
    ],flat,0,true,true,true,false,false)
    var fog_before: Dictionary = fog.duplicate(true)
    var hidden: Node3D = Renderer.build(fog,"T0",12.0,true)
    assert(hidden!=null)
    assert(hidden.find_child("Unidad3D_SECRET",true,false)==null)
    assert(int(hidden.get_meta("render_stats")["units"]["hidden_enemies"])==1)
    var swap: Dictionary = Renderer.refresh_unit_lod(
        hidden,fog,"T0",62.0,false)
    assert(swap.size()>0)
    assert(hidden.find_child("Unidad3D_SECRET",true,false)==null)
    assert(fog==fog_before)
    hidden.free()
    print("PASS G09 V27: real 3D battle V25 selected zoom, V10 mid, V6 far, AUTO/ECO, state and fog unchanged")
    quit(0)
