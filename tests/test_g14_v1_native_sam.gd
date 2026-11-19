extends SceneTree

# G14 V1 authentic Godot 3D verification in all 8 approved faction palettes.
# Visual prototype only; the existing playable SAM and balance are unchanged.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G14=preload("res://scripts/ui/G14MobileSAMV1.gd")
const Factions=preload("res://scripts/ui/VisualStyle.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var errors:int=0

func check(ok:bool,label:String)->void:
    if not ok:
        errors+=1
        push_error("G14 V1 native QA: "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(Models.supports("sam_mobile"),"new art-only G14 role supported")
    check(not Arsenal.valid("sam_mobile"),"art-only prototype is not a new playable unit")
    check(Arsenal.valid("sam") and Arsenal.code("sam")=="G14",
        "existing playable G14 SAM profile remains unchanged")
    var viewport:=SubViewport.new()
    viewport.name="G14V1Native3DAudit"
    viewport.size=Vector2i(960,680)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#263744")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dfe8ed")
    env.ambient_light_energy=0.55
    environment.environment=env
    viewport.add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-34,0)
    sun.light_energy=1.6
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=6.3
    camera.position=Vector3(5.4,4.1,6.1)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.38,0),Vector3.UP)
    camera.current=true
    var output: String="res://build/qa/g14-v1"
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(output))==OK,
        "native evidence folder accessible")
    var captures:int=0
    for faction in range(Factions.FACTIONS.size()):
        for art_level in [8,13]:
            var model:=Models.build("sam_mobile",faction,true,art_level)
            check(model!=null,"eight-faction LOD %d build #%d" % [art_level,faction])
            if model==null:
                continue
            viewport.add_child(model)
            check(G14.has_model(model),"native mesh G14 flag")
            check(bool(model.get_meta("tarvoka_g14_v1_art_only",false)),
                "G14 art cannot secretly change BattleSession")
            check(int(model.get_meta("tarvoka_g14_v1_wheels",-1))==8 and
                int(model.get_meta("tarvoka_g14_v1_sam_cells",-1))==4,
                "eight real wheels and four SAM canisters")
            var wheels:=model.find_child(G14.WHEELS,true,false) as MultiMeshInstance3D
            var hubs:=model.find_child(G14.HUBS,true,false) as MultiMeshInstance3D
            check(wheels!=null and hubs!=null,"both native 8x8 wheel batches")
            if wheels!=null and hubs!=null:
                check(wheels.multimesh.instance_count==8 and
                    hubs.multimesh.instance_count==8,
                    "real 8x8 tire and wheel-hub transforms")
            for i in range(4):
                check(model.find_child("G14_ContenedorSAM_%d" % i,true,false)
                    is MeshInstance3D,"SAM canister %d is real 3D" % i)
            var launcher:=model.find_child(G14.LAUNCHER,true,false) as Node3D
            var mount:=model.find_child(G14.ELEVATION,true,false) as Node3D
            var radar:=model.find_child(G14.RADAR,true,false) as Node3D
            check(launcher!=null and mount!=null and radar!=null,
                "launcher yaw, missile elevation and radar independent pivots")
            check(G14.pose(model,"deploy",1.0),
                "launcher and stabilizers deploy")
            if mount!=null:
                check(absf(mount.rotation_degrees.x-46.0)<0.01,
                    "launcher elevates to 46-degree display stance")
            check(G14.pose(model,"scan",0.75),"search radar scans")
            if radar!=null:
                check(absf(radar.rotation_degrees.y)>1.0,
                    "radar physical antenna rotates")
            check(G14.pose(model,"launch",0.30,Vector2i(1,-1)),
                "visual launch sequence animates")
            var flash:=model.find_child("G14_EscapeVisual_1",true,false) as Node3D
            var missile:=model.find_child("G14_MisilAnimado_1",true,false) as Node3D
            check(flash!=null and missile!=null and flash.visible and missile.visible,
                "selected missile and exhaust are visible during burst")
            check(G14.pose(model,"hit",0.50),"native impact visual works")
            check(absf(model.rotation_degrees.z)>1.0,
                "G14 impact visibly tilts real model")
            G14.restore(model)
            check(str(model.get_meta("tarvoka_g14_v1_pose",""))=="idle" and
                absf(model.rotation_degrees.z)<0.001,
                "all animations restore original pose")
            if faction<8 and art_level==13:
                check(G14.pose(model,"deploy",1.0),
                    "renderable 8-faction deployed pose")
                model.rotation_degrees.y=22.0
                await process_frame
                await process_frame
                await process_frame
                var picture:Image=viewport.get_texture().get_image()
                var path:String="%s/g14_faction_%02d.png" % [output,faction]
                check(picture!=null and not picture.is_empty() and
                    picture.save_png(path)==OK,
                    "authentic Godot screenshot faction %d" % faction)
                captures+=1
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(captures==8,"eight native PNG samples generated")
    viewport.queue_free()
    await process_frame
    if errors>0:
        printerr("FAIL G14 V1 NATIVE 3D: %d errors" % errors)
        quit(1)
        return
    print("PASS G14 V1 NATIVE 3D: 8 factions, LOD8/13, 8x8, four SAM cells, poses, 8 captures")
    quit(0)
