extends SceneTree
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Art=preload("res://scripts/ui/A02FpvArtV1.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var failures:int=0

func check(ok:bool,msg:String)->void:
    if not ok:
        failures+=1
        push_error("A02 V1: "+msg)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var profile:Dictionary=Arsenal.profile("fpv").duplicate(true)
    check(profile.get("code","")=="A02","catalogue identity")
    var vp:=SubViewport.new()
    vp.size=Vector2i(960,680)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#edf5fc")
    env.ambient_light_energy=0.72
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-30,0)
    light.light_energy=1.7
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.15
    camera.position=Vector3(3.3,3.2,-4)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.95,0),Vector3.UP)
    camera.current=true
    var out:String="res://build/qa/a02-v1"
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))==OK,"capture directory")
    var count:int=0
    for faction in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("fpv",faction,true,lod)
            check(model!=null,"native A02 factory")
            if model==null:
                continue
            vp.add_child(model)
            check(bool(model.get_meta(Art.FLAG,false)) and int(model.get_meta("tarvoka_a02_lod",0))==lod,"correct LOD")
            var paint:=model.find_child(Art.PAINT,true,false) as MeshInstance3D
            check(paint!=null and paint.material_override is StandardMaterial3D,"faction crown")
            if paint!=null and paint.material_override is StandardMaterial3D:
                check((paint.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Models.faction_paint_color(faction)),"official color")
            var tris:int=0
            for child in model.find_children("*","MeshInstance3D",true,false):
                var part:=child as MeshInstance3D
                check(part.mesh!=null and part.material_override is StandardMaterial3D,"native mesh")
                if part.mesh!=null:
                    tris+=part.mesh.get_faces().size()/3
                if part.material_override is StandardMaterial3D:
                    check((part.material_override as StandardMaterial3D).transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"opaque")
            check(tris<=(12000 if lod==8 else 24000),"initial triangle budget")
            for i in range(4):
                check(model.find_child("A02_ClosedRotorGuard_"+str(i),true,false)!=null and model.find_child("A02_VisualRotor_"+str(i),true,false)!=null,"four rotor assemblies")
            check(Models.pose_model("fpv",model,"move",0.25),"motion")
            Art.restore(model)
            await process_frame
            await process_frame
            await process_frame
            var pixels:Image=vp.get_texture().get_image()
            if pixels!=null and not pixels.is_empty() and pixels.save_png(out+"/a02-f%d-lod%d.png"%[faction,lod])==OK:
                count+=1
            vp.remove_child(model)
            model.free()
    check(count==16,"16 authentic faction/LOD captures")
    check(Arsenal.profile("fpv")==profile,"no catalogue changes")
    vp.queue_free()
    if failures==0:
        print("PASS A02 FPV ART V1: 8 factions, 2 LODs, 16 Godot renders")
    quit(0 if failures==0 else 1)
