extends SceneTree

# Actual Godot 4.3 native A01 reconnaissance UAV: distinct from attack HAT-29.
# The new art-only preview must never change tactical unit profiles or fog.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v1"
var failures:int=0
var captures:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("A01 UAV V1 QA: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(Models.supports("uav_recon"),"A01 art has its own role")
    check(not Arsenal.valid("uav_recon"),"3D art does not duplicate tactical role")
    check(Arsenal.valid("uav_recon") and Arsenal.code("uav_recon")=="A01",
        "A01 tactical ID stays assigned to the reconnaissance UAV")
    var p:Dictionary=Arsenal.profile("uav_recon")
    check(int(p.get("attack",-1))==0 and str(p.get("domain",""))=="air" and
        int(p.get("vision",0))==7 and int(p.get("cost",0))==250,
        "no weapons, existing vision7, cost250 and air domain unchanged")
    check(Arsenal.code("attack_heli")=="A05",
        "A01 recon and the existing attack-helicopter game role stay distinct")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"screenshot folder created")

    var vp:=SubViewport.new()
    vp.size=Vector2i(960,680)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var sky:=Environment.new()
    sky.background_mode=Environment.BG_COLOR
    sky.background_color=Color("#172b3a")
    sky.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color=Color("#e9f2fa")
    sky.ambient_light_energy=0.70
    world.environment=sky
    vp.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-35,0)
    sun.light_energy=2.0
    vp.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.75
    camera.position=Vector3(4.7,3.9,5.6)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.90,0),Vector3.UP)
    camera.current=true
    var colors:Dictionary={}

    for faction in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",faction,true,lod)
            check(model!=null,"native airframe faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            vp.add_child(model)
            check(Drone.has_model(model),"closed A01 fuselage, optical pod and prop")
            check(bool(model.get_meta("tarvoka_a01_unarmed",false)) and
                bool(model.get_meta("tarvoka_a01_visual_only",false)),
                "no attack or tactical fog modifications")
            check(int(model.get_meta("tarvoka_a01_native_lod",0))==lod,
                "real Android vs studio LOD profile")
            check(model.find_child(Drone.WING_L,true,false)!=null and
                model.find_child(Drone.WING_R,true,false)!=null,
                "physical left/right wing mesh")
            var stripe:=model.find_child(Drone.COLOR_MARK+"_L",
                true,false) as MeshInstance3D
            check(stripe!=null and stripe.mesh is BoxMesh and
                stripe.material_override is StandardMaterial3D,
                "physical faction-painted wing stripe, no decal")
            if stripe!=null and stripe.material_override is StandardMaterial3D:
                var tone:Color=(stripe.material_override as StandardMaterial3D).albedo_color
                colors[tone.to_html()]=true
                check(tone.is_equal_approx(Models.faction_paint_color(faction)),
                    "faction %d matches official palette" % faction)
            check(Models.pose_model("uav_recon",model,"scan",0.25),
                "real optical gimbal scan animation")
            var optics:=model.find_child(Drone.SENSOR,true,false) as Node3D
            check(optics!=null and absf(optics.rotation_degrees.y)>20,
                "optical gimbal actually swivels, not static")
            check(Models.pose_model("uav_recon",model,"move",0.35),
                "actual pusher motor in flight")
            var prop:=model.find_child(Drone.PROPELLER,true,false) as Node3D
            check(prop!=null and absf(prop.rotation_degrees.z)>100,
                "visible physical propeller spin")
            check(not Models.pose_model("uav_recon",model,"attack",0.7),
                "recon UAV does not create fake attack animation")
            Models.restore_model_pose("uav_recon",model)
            check(optics!=null and absf(optics.rotation_degrees.y)<0.01,
                "restoring original gimbal pose")
            check(Models.inspect_meshes(model)>=21,
                "no missing closed composite surfaces")
            await process_frame
            await process_frame
            await process_frame
            var shot:Image=vp.get_texture().get_image()
            check(shot!=null and not shot.is_empty(),
                "real engine screenshot faction %d LOD%d" % [faction,lod])
            if shot!=null and not shot.is_empty():
                check(shot.save_png("%s/a01-f%d-lod%d.png" % [OUT,faction,lod])==OK,
                    "save genuine A01 Godot rendering")
                captures+=1
            vp.remove_child(model)
            model.free()

    check(colors.size()==8,"all eight faction colors produce distinct painted meshes")
    check(captures==16,"sixteen actual A01 V1 Godot 3D renders")
    vp.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 RECON UAV V1: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 RECON UAV V1: sixteen native renders; 8 factions, LOD8/13, optics, prop, unarmed safety")
        quit(0)
