extends SceneTree

# Godot 4.3 screenshots of the real workshop LOD models, scaled into the
# game's 2.4m tactical grid. This fixture does not create battle state.
const Preview=preload("res://scripts/ui/ArmoredWorkshopBattlePreview3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_map_preview"
const CELL:float=2.4

func _initialize() -> void:
    call_deferred("_run")

func _tile(parent:Node3D,at:Vector3,color:Color) -> void:
    var mesh:=BoxMesh.new()
    mesh.size=Vector3(CELL-0.065,0.12,CELL-0.065)
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.roughness=0.94
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    var instance:=MeshInstance3D.new()
    instance.mesh=mesh
    instance.material_override=mat
    instance.position=at
    parent.add_child(instance)

func _camera_at(camera:Camera3D,overhead:bool=false) -> void:
    var yaw:float=deg_to_rad(145.0 if not overhead else 48.0)
    var tilt:float=deg_to_rad(49.0 if not overhead else 77.0)
    var focus:=Vector3(0,0.38,0)
    var distance:float=18.0
    camera.size=9.35
    camera.position=focus+Vector3(
        sin(yaw)*cos(tilt)*distance,
        sin(tilt)*distance,
        cos(yaw)*cos(tilt)*distance)
    camera.look_at(focus,Vector3.UP)

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#253a47")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce4e2")
    env.ambient_light_energy=0.63
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-28,0)
    sun.shadow_enabled=true
    sun.light_energy=1.26
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    viewport.add_child(camera)
    camera.current=true
    var terrain:=Node3D.new()
    terrain.name="EscalaMapaTactico2P4Metros"
    viewport.add_child(terrain)
    for z in range(-1,2):
        for x in range(-1,2):
            var road:bool=z==-1
            var tile_color:Color=Color("#9b8c70") if road else Color("#638462")
            _tile(terrain,Vector3(float(x)*CELL,-0.06,
                float(z)*CELL),tile_color)
    var records:Array=[]
    var count:int=0
    for level in [1,2,3]:
        for lod in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
            var workshop:Node3D=Preview.build(level,3,0,lod)
            assert(workshop!=null)
            workshop.position.y=0.05
            viewport.add_child(workshop)
            _camera_at(camera)
            var filename:String="N%d_Solar_LOD%d_escala_batalla.png" % [
                level,lod]
            records.append(await _save(viewport,filename,level,lod,0))
            count+=1
            viewport.remove_child(workshop)
            workshop.free()
    for damage in [3,4]:
        var workshop:Node3D=Preview.build(
            3,3,damage,Mobile.PROFILE_TACTICAL)
        assert(workshop!=null)
        workshop.position.y=0.05
        viewport.add_child(workshop)
        _camera_at(camera)
        var filename:String="N3_Solar_D%d_escombros_batalla.png" % damage
        records.append(await _save(viewport,filename,3,
            Mobile.PROFILE_TACTICAL,damage))
        count+=1
        viewport.remove_child(workshop)
        workshop.free()
    assert(count==8)
    var file:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify({
        "engine":"Godot 4.3", "scene":"art_only_battle_scale",
        "tactical_tile_meters":CELL,
        "count":count,"captures":records}, "\t"))
    file.close()
    print("PASS WORKSHOP BATTLE PREVIEW: 8 real OpenGL 2.4m tile-scale",
        " renderings; tactical/distant N1-N3, critical D3-D4")
    viewport.queue_free()
    quit(0)

func _save(viewport:SubViewport,filename:String,
        level:int,lod:int,damage:int) -> Dictionary:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var pic:Image=viewport.get_texture().get_image()
    assert(pic!=null and pic.get_width()==960 and pic.get_height()==720)
    assert(pic.get_pixel(470,360).a>0.8,
        "Empty map-scale 3D render for "+filename)
    var result:Error=pic.save_png(OUTPUT+"/"+filename)
    assert(result==OK)
    return {"file":filename,"level":level,"lod":lod,"damage":damage}
