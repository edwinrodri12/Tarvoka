extends SceneTree

# Non-gameplay diagnostic: identify the exact remaining square rear face
# from source-authored G11 components using isolated Godot 4.3 renders.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const NAMES=[
    "G11_RampaPosteriorCerrada",
    "G11V2_CascoOctogonalCerrado",
    "G11_Estabilizador_-1",
    "G11_Estabilizador_1",
    "G11_ZapataEstabilizador_-1",
    "G11_ZapataEstabilizador_1",
    "G11V2_ProteccionLateral_-1",
    "G11V2_ProteccionLateral_1",
    "G11_Faldon_-1",
    "G11_Faldon_1",
    "G11V12_GuardaLodoTrasera_-1",
    "G11V12_GuardaLodoTrasera_1",
    "G11V13_SoporteEje_-1",
    "G11V13_SoporteEje_1"
]
var saves:=0
var failures:=0
func _check(ok: bool,text: String)->void:
    if not ok:
        failures+=1
        push_error("G11 rear geometry isolation: "+text)

func _shot(view: SubViewport,dir: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:=view.get_texture().get_image()
    _check(image!=null and not image.is_empty(),"frame "+name)
    if image!=null and not image.is_empty():
        var state:=image.save_png(dir.path_join(name))
        _check(state==OK,"write "+name)
        if state==OK:
            saves+=1

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:=OS.get_environment("G11_REAR_ISOLATE_DIR")
    if folder.is_empty():
        folder="/tmp/g11-rear-isolation"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,"output folder")
    var viewport:=SubViewport.new()
    viewport.own_world_3d=true
    viewport.size=Vector2i(960,680)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var sky:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#374c56")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e2eeee")
    env.ambient_light_energy=0.67
    sky.environment=env
    viewport.add_child(sky)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-45,-35,0)
    sun.light_energy=1.3
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.5
    viewport.add_child(camera)
    var model:=Models.build("mlrs",0,true,13) as Node3D
    _check(model!=null,"real original hero 3D loaded")
    if model==null:
        quit(1)
        return
    viewport.add_child(model)
    for angle in ["rear","quarter"]:
        camera.position=(Vector3(0.8,0.08,3.6)
            if angle=="rear" else Vector3(2.48,0.12,2.7))
        camera.look_at(Vector3(0,0.48,0.82),Vector3.UP)
        await _shot(viewport,folder,"g11_%s_00_baseline.png" % angle)
        for i in range(NAMES.size()):
            var part:=model.find_child(NAMES[i],true,false) as Node3D
            _check(part!=null,"find "+str(NAMES[i]))
            if part==null:
                continue
            part.visible=false
            await _shot(viewport,folder,
                "g11_%s_%02d_without_%s.png" % [
                    angle,i+1,str(NAMES[i]).replace("/","_")])
            part.visible=true
    model.queue_free()
    await process_frame
    _check(saves==2*(NAMES.size()+1),"two angles x 15 cases recorded")
    if failures>0:
        push_error("G11 rear isolation FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 REAR ISOLATION: 30 real camera frames isolate each rear plate, stabilizer, inner hull, guard and sprocket support")
    quit(0)
