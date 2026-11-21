extends SceneTree

# GPU-visible screenshots of REAL BattleTerrain3D, plus actual V24 meshes
# for all approved palettes and staged damage. No fictitious illustration.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const HQ=preload("res://scripts/ui/HeadquartersBattle3D.gd")
const Curves=preload("res://scripts/ui/HeadquartersCurvedRoof3D.gd")
const Accents=preload("res://scripts/ui/HeadquartersBattleAccents3D.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const OUT:String="res://artifacts/hq_v24_native"
var _view:SubViewport
var _camera:Camera3D
var _stage:Node3D

func _initialize() -> void:
    call_deferred("_run")

func _setup() -> void:
    _view=SubViewport.new()
    _view.name="CapturasHQV24Nativas"
    _view.size=Vector2i(1280,720)
    _view.own_world_3d=true
    _view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(_view)
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#203342")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#cedee0")
    environment.ambient_light_energy=0.72
    world.environment=environment
    _view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-55,-30,0)
    sun.light_energy=1.2
    _view.add_child(sun)
    _camera=Camera3D.new()
    _camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    _camera.near=0.05
    _camera.far=220.0
    _view.add_child(_camera)
    _camera.current=true

func _stage_scene(scene:Node3D) -> void:
    if _stage!=null:
        _view.remove_child(_stage)
        _stage.free()
    _stage=scene
    _view.add_child(_stage)

func _camera_at(target:Vector3,distance:Vector3,zoom:float) -> void:
    _camera.position=target+distance
    _camera.size=zoom
    _camera.look_at(target,Vector3.UP)

func _snap(label:String) -> void:
    for i in range(6):
        await RenderingServer.frame_post_draw
    var frame:Image=_view.get_texture().get_image()
    assert(frame!=null)
    assert(frame.get_size()==Vector2i(1280,720))
    assert(frame.save_png(OUT+"/"+label+".png")==OK)

func _grid(variants:Array,columns:int,spacing:float) -> Node3D:
    var scene:=Node3D.new()
    scene.name="GaleriaMallasRealesHQV24"
    for i in range(variants.size()):
        var cfg:Dictionary=variants[i]
        var hq:Node3D=HQ.build(
            int(cfg.get("level",3)),
            int(cfg.get("faction",-1)),
            int(cfg.get("damage",0)))
        assert(hq!=null)
        assert(hq.get_node_or_null(Curves.NAME)!=null)
        assert(hq.get_node_or_null(Accents.NAME)!=null)
        hq.position=Vector3(float(i%columns)*spacing,0.0,
            float(int(i/columns))*spacing)
        scene.add_child(hq)
    return scene

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    _setup()
    var current:Dictionary=Session.start(
        Roles.experimental_armies(),Scenarios.terrain(0),
        0,false,false,true,true)
    var safe:Dictionary=current.duplicate(true)
    var actual:Node3D=Terrain.build(current,"",0)
    assert(actual!=null)
    assert(actual.find_child("Instalacion3D_city_2_1",true,false)!=null)
    assert(actual.find_child("Instalacion3D_city_7_1",true,false)!=null)
    _stage_scene(actual)
    var target:Vector3=Terrain.world_at(Vector2i(2,1))
    _camera_at(target+Vector3(0,0.4,0),Vector3(5,7,-7),5.2)
    await _snap("01_real_battle_close")
    _camera_at(Vector3(10.8,0,8.4),Vector3(14,24,23),34.0)
    await _snap("02_real_battle_far")
    assert(current==safe,"Only screenshots, never mutate battle state")

    var national:Array=[]
    for f in range(8):
        national.append({"level":3,"faction":f,"damage":0})
    national.append({"level":3,"faction":-1,"damage":0})
    _stage_scene(_grid(national,4,3.05))
    _camera_at(Vector3(4.575,0,1.525),Vector3(8,10,-12),10.8)
    await _snap("03_eight_factions_and_neutral")
    var damage:Array=[]
    for d in range(5):
        damage.append({"level":3,"faction":0,"damage":d})
    _stage_scene(_grid(damage,5,3.05))
    _camera_at(Vector3(6.1,0,0),Vector3(8,10,-12),8.6)
    await _snap("04_damage_D0_to_D4")
    var tiers:Array=[]
    for lv in [1,2,3]:
        tiers.append({"level":lv,"faction":1,"damage":0})
    _stage_scene(_grid(tiers,3,3.3))
    _camera_at(Vector3(3.3,0,0),Vector3(6,9,-10),6.0)
    await _snap("05_levels_N1_to_N3")
    # Individual eye-level front quarter view to see metal, real glazing,
    # crest and solid entrance rather than only thumbnails from above.
    _stage_scene(_grid([{"level":3,"faction":0,"damage":0}],1,3.0))
    _camera_at(Vector3(0,0.60,0),Vector3(2.4,2.6,-3.8),2.9)
    await _snap("06_closeup_materials_and_official_crest")
    _stage_scene(_grid([{"level":3,"faction":0,"damage":4}],1,3.0))
    _camera_at(Vector3(0,0.46,0),Vector3(2.4,2.6,-3.8),2.9)
    await _snap("07_destroyed_command_arch_detail")
    # Native mesh budgets: six shell, three curved roofs, four native trims.
    for damage_value in range(5):
        var item:Node3D=HQ.build(3,4,damage_value)
        assert(item.get_meta("hq_material_surfaces")==13)
        var curve:MeshInstance3D=item.get_node(Curves.NAME)
        assert(curve!=null)
        assert(curve.mesh.get_surface_count()==3)
        assert(curve.mesh.get_faces().size()>0)
        item.free()
    _stage_scene(Node3D.new())
    _view.queue_free()
    print("PASS HQ V24 VISUAL GALLERY: actual 3D battle close/far, 8 official factions, neutral, N1-N3, D0-D4, seven native PNG captures")
    quit(0)
