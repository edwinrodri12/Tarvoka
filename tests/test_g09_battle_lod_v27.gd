extends SceneTree

# V27 legacy route, upgraded for V28: one original V25 G09 across ALL
# distances, in-place microdetail/shadow/material budgets, no old silhouettes.
const Renderer = preload("res://scripts/ui/BattleTerrain3D.gd")
const Viewer = preload("res://scripts/ui/Battle3DMapView.gd")
const Budget = preload("res://scripts/ui/TankBattleLOD27.gd")
const Adaptive = preload("res://scripts/ui/TankAdaptiveV28.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Wear = preload("res://scripts/ui/TankWearV25.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _unit(id: String,x: int,y: int,role: String="tank",
        faction: int=0) -> Dictionary:
    return {"id":id,"role":role,"faction":faction,"hp":10,
        "pos":Vector2i(x,y),"vision":5,"move_points":4,
        "attack":5,"acted":false}

func _tank(scene: Node3D,id: String) -> Node3D:
    var model: Node3D = scene.find_child("Unidad3D_"+id,true,false) as Node3D
    assert(model!=null)
    assert(int(model.get_meta("battle_art_level",-1))==25)
    assert(model.get_meta("tarvoka_mbt_wear_v25",false))
    assert(model.get_meta("battle_g09_v25",false))
    assert(Models.paintable_count(model)==14)
    assert(Wear._targets().size()==17)
    return model

func _run() -> void:
    assert(Budget.tier(55.0)==Budget.FAR)
    assert(Budget.tier(31.0)==Budget.MEDIUM)
    assert(Budget.tier(12.0)==Budget.HERO)
    for size in [10.0,29.0,55.0,90.0]:
        assert(Budget.tank_art_level(size,true,true,0,0)==25)
        assert(Budget.tank_art_level(size,false,false,1,4)==25)
    assert(Adaptive.tier(12.0,true)==Adaptive.CLOSE)
    assert(Adaptive.tier(30.0,true)==Adaptive.MEDIUM)
    assert(Adaptive.tier(55.0,true)==Adaptive.DISTANT)
    assert(Adaptive.tier(12.0,false)==Adaptive.MEDIUM)

    var flat: Array = Scenarios.terrain(0)
    var state: Dictionary = Session.start([
        _unit("T0",1,1),_unit("T1",2,1),_unit("T2",3,1),
        _unit("L0",1,2,"line"),
        _unit("ENEMY",5,5,"tank",1)
    ],flat,0,true,false,false,false,false)
    var before: Dictionary = state.duplicate(true)
    var scene: Node3D = Renderer.build(state,"T0",55.0,true)
    assert(scene!=null and scene.get_meta("visual_only"))
    var first: Node3D = _tank(scene,"T0")
    var second: Node3D = _tank(scene,"T1")
    var first_id: int = first.get_instance_id()
    var second_id: int = second.get_instance_id()
    var mesh_count: int = Models.inspect_meshes(first)
    var first_mesh: MeshInstance3D = first.find_child(
        "G09V14LomoBlindadoCentral_-1",true,false) as MeshInstance3D
    assert(first_mesh!=null and first_mesh.visible)
    var paint: Material = first_mesh.material_override
    assert(paint is StandardMaterial3D)
    assert((paint as StandardMaterial3D).albedo_texture!=null)
    var far_stats: Dictionary = scene.get_meta("render_stats")["units"]
    assert(int(far_stats["g09_v25"])>=3)
    assert(int(far_stats["g09_v10"])==0 and int(far_stats["g09_v6"])==0)
    assert(int(far_stats["g09_shadow_off"])>0)
    assert(int(far_stats["g09_shader_simplified"])>0)
    assert(int(first.get_meta("v28_visual_tier",-1))==Adaptive.DISTANT)
    var far_visible: bool = first_mesh.visible

    var medium_stats: Dictionary = Renderer.refresh_unit_lod(
        scene,state,"T0",29.0,true)
    assert(int(medium_stats["g09_v25"])>=3)
    assert(_tank(scene,"T0").get_instance_id()==first_id)
    assert(_tank(scene,"T1").get_instance_id()==second_id)
    assert(Models.inspect_meshes(first)==mesh_count)
    assert(int(first.get_meta("v28_visual_tier",-1))==Adaptive.MEDIUM)
    assert(first_mesh.visible==far_visible)
    assert(first_mesh.material_override is StandardMaterial3D)
    assert((first_mesh.material_override as StandardMaterial3D).albedo_texture!=null)
    var close: Dictionary = Renderer.refresh_unit_lod(
        scene,state,"T0",12.0,true)
    assert(int(close["g09_close"])==1)
    assert(_tank(scene,"T0").get_instance_id()==first_id)
    assert(_tank(scene,"T1").get_instance_id()==second_id)
    assert(int(first.get_meta("v28_visual_tier",-1))==Adaptive.CLOSE)
    assert(int(second.get_meta("v28_visual_tier",-1))==Adaptive.CLOSE)
    assert(first_mesh.visible==far_visible)
    assert(Models.inspect_meshes(first)==mesh_count)
    assert(close["g09_shadow_off"]<far_stats["g09_shadow_off"])
    var eco: Dictionary = Renderer.refresh_unit_lod(
        scene,state,"T0",12.0,false)
    assert(int(eco["g09_v25"])>=3)
    assert(int(first.get_meta("v28_visual_tier",-1))==Adaptive.MEDIUM)
    assert(_tank(scene,"T0").get_instance_id()==first_id)
    assert(first_mesh.visible and (first_mesh.material_override as StandardMaterial3D).albedo_texture!=null)
    assert(scene.get_meta("public_cells").size()==flat.size()*flat[0].size())
    assert(state==before)
    scene.free()

    var viewer := Viewer.new()
    root.add_child(viewer)
    assert(viewer.open_from_state(state,"T0"))
    assert(viewer.visible and viewer._g09_high_detail)
    var tracked: Node3D = _tank(viewer._scene,"T0")
    var tracked_id: int = tracked.get_instance_id()
    var yaw: float = viewer._yaw
    viewer._zoom_anchored(0.30,viewer.holder.size*0.5)
    assert(viewer._g09_lod_band==Budget.HERO)
    assert(_tank(viewer._scene,"T0").get_instance_id()==tracked_id)
    viewer._toggle_g09_detail()
    assert(not viewer._g09_high_detail)
    assert(_tank(viewer._scene,"T0").get_instance_id()==tracked_id)
    viewer._toggle_g09_detail()
    assert(viewer._g09_high_detail)
    assert(_tank(viewer._scene,"T0").get_instance_id()==tracked_id)
    viewer._zoom_anchored(12.0,viewer.holder.size*0.5)
    assert(viewer._g09_lod_band==Budget.FAR)
    assert(_tank(viewer._scene,"T0").get_instance_id()==tracked_id)
    assert(is_equal_approx(viewer._yaw,yaw))
    assert(state==before)
    viewer.close_view()
    assert(not viewer.visible)
    viewer.queue_free()

    # FOG proof: even distant quality refresh cannot expose enemy data.
    var fog: Dictionary = Session.start([
        _unit("T0",1,1),
        _unit("SECRET",flat[0].size()-2,flat.size()-2,"tank",1)
    ],flat,0,true,true,true,false,false)
    var fog_before: Dictionary = fog.duplicate(true)
    var hidden: Node3D = Renderer.build(fog,"T0",12.0,true)
    assert(hidden!=null)
    assert(hidden.find_child("Unidad3D_SECRET",true,false)==null)
    assert(int(hidden.get_meta("render_stats")["units"]["hidden_enemies"])==1)
    var refresh: Dictionary = Renderer.refresh_unit_lod(
        hidden,fog,"T0",62.0,false)
    assert(refresh.size()>0)
    assert(hidden.find_child("Unidad3D_SECRET",true,false)==null)
    assert(fog==fog_before)
    hidden.free()
    print("PASS G09 V27: legacy route now preserves V25 silhouette and materials across all bands")
    print("PASS G09 V28: in-place LOD, 17 armor coats, 14 faction zones, no rebuild on zoom, ECO, fog protected")
    quit(0)
