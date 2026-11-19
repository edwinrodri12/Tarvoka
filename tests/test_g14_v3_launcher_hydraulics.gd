extends SceneTree

# TARVOKA G14 V3: native mechanical articulation and true 3D render proof.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G14MobileSAMV1.gd")
const V2=preload("res://scripts/ui/G14MobileSAMExteriorV2.gd")
const V3=preload("res://scripts/ui/G14MobileSAMLauncherV3.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var failures:int=0

func check(ok:bool,label:String)->void:
    if not ok:
        failures+=1
        push_error("G14 V3 NATIVE 3D: "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var sam:Dictionary=Arsenal.profile("sam")
    check(not Arsenal.valid("sam_mobile") and Arsenal.code("sam")=="G14",
        "new model is art only; combat keeps G14")
    check(int(sam.get("cost",-1))==900 and
        int(sam.get("attack_min_range",-1))==2 and
        int(sam.get("attack_range",-1))==5,
        "combat production and attack rules unchanged")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1000,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.name="G14_V3_GodotNativeFourPodVerification"
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#273846")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#ecf3ed")
    environment.ambient_light_energy=0.62
    world.environment=environment
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-35,0)
    sun.light_energy=1.65
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=6.7
    camera.position=Vector3(5.1,4.0,5.7)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.31,0),Vector3.UP)
    camera.current=true
    const OUT="res://build/qa/g14-v3"
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "Godot G14 V3 native render directory")
    var captures:int=0
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("sam_mobile",faction,true,lod)
            check(model!=null,"factory builds G14 V3 faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            viewport.add_child(model)
            check(V1.has_model(model) and V2.has_model(model) and V3.has_model(model),
                "V3 reuses same real G14 V1/V2 vehicle, not a separate placeholder")
            check(int(model.get_meta("tarvoka_g14_v3_hydraulics",-1))==2 and
                int(model.get_meta("tarvoka_g14_v3_launcher_hatches",-1))==4,
                "two true telescopic pistons and four individually hinged doors")
            var elevated:=model.find_child(V1.ELEVATION,true,false) as Node3D
            var platform:=model.find_child(V1.LAUNCHER,true,false) as Node3D
            check(elevated!=null and platform!=null,
                "preserves original pitch and yaw pivots")
            var before_piston:float=0.0
            for side in [-1,1]:
                var ram:=model.find_child(V3.SHAFT+str(side),true,false
                    ) as MeshInstance3D
                var barrel:=model.find_child(V3.HOUSING+str(side),true,false
                    ) as MeshInstance3D
                var pin:=model.find_child(V3.PIVOT+str(side),true,false
                    ) as MeshInstance3D
                check(ram!=null and barrel!=null and pin!=null,
                    "real actuator housing, exposed shaft and ball joint %d" % side)
                if ram!=null:
                    check(ram.mesh is CylinderMesh and ram.scale.y>0.05,
                        "telescopic piston is real cylinder geometry")
                    if side==1:
                        before_piston=ram.scale.y
            for i in range(4):
                var mouth:=model.find_child(V3.MOUTH+str(i),true,false
                    ) as MeshInstance3D
                var hinge:=model.find_child(V3.HATCH+str(i),true,false
                    ) as Node3D
                var v1door:=model.find_child("G14_TapaLanzador_%d" % i,
                    true,false) as MeshInstance3D
                check(mouth!=null and mouth.mesh is TorusMesh and hinge!=null,
                    "four sealed launch mouths and four mechanical hatches")
                check(v1door!=null and not v1door.visible,
                    "V1 flush doors hidden behind actual V3 articulated doors")
            check(Models.pose_model("sam_mobile",model,"deploy",1.0),
                "real launcher deploys via original pitch authority")
            var extended:=model.find_child(V3.SHAFT+"1",true,false
                ) as MeshInstance3D
            if extended!=null:
                check(extended.scale.y>before_piston+0.06,
                    "hydraulic shaft physically extends with launcher angle")
            check(Models.pose_model("sam_mobile",model,"aim",1.0,
                Vector2i(1,-1)),"SAM aim retains turret azimuth")
            if platform!=null:
                check(absf(platform.rotation_degrees.y)>5.0,
                    "aim really rotates original turntable")
            check(Models.pose_model("sam_mobile",model,"launch",0.37,
                Vector2i(1,-1)),"second missile launch frame updates all hinges")
            var active:=model.find_child(V3.HATCH+"1",true,false) as Node3D
            var closed:=model.find_child(V3.HATCH+"0",true,false) as Node3D
            var burst:=model.find_child("G14_MisilAnimado_1",true,false
                ) as MeshInstance3D
            check(active!=null and closed!=null and burst!=null,
                "true four-door launch parts survive animation")
            if active!=null and closed!=null:
                check(absf(active.rotation_degrees.y)>60.0 and
                    absf(closed.rotation_degrees.y)<0.01,
                    "ONLY the selected missile hatch opens (no global door group)")
            if burst!=null:
                check(burst.visible,"V1 visual missile is not blocked by new rig")
            Models.restore_model_pose("sam_mobile",model)
            if active!=null:
                check(absf(active.rotation_degrees.y)<0.01,
                    "door closes after action cancellation")
            if extended!=null:
                check(absf(extended.scale.y-before_piston)<0.03,
                    "piston retracts to the true original resting position")
            var legacy:=model.find_child("G14_TapaLanzador_0",true,false
                ) as MeshInstance3D
            check(V3.show_finish(model,false),"V3 hide works for prior review")
            if legacy!=null:
                check(legacy.visible,"original V1/V2 launch cap restored")
            check(V3.show_finish(model,true),"V3 mechanical mount restored")
            if legacy!=null:
                check(not legacy.visible,"legacy cap hidden when V3 returns")
            if lod==13:
                # Side-by-side real native engine captures, not concept art.
                check(V3.show_finish(model,false),"V2 comparison frame available")
                model.rotation_degrees.y=23.0
                await process_frame
                await process_frame
                await process_frame
                var before:Image=viewport.get_texture().get_image()
                check(before!=null and not before.is_empty() and
                    before.save_png("%s/g14_v2_faction_%02d.png" % [
                        OUT,faction])==OK,"native V2 review image")
                captures+=1
                check(V3.show_finish(model,true),"V3 restored before capture")
                check(Models.pose_model("sam_mobile",model,"deploy",1.0),
                    "native fully deployed mechanical mount")
                model.rotation_degrees.y=23.0
                await process_frame
                await process_frame
                await process_frame
                var after:Image=viewport.get_texture().get_image()
                check(after!=null and not after.is_empty() and
                    after.save_png("%s/g14_v3_faction_%02d.png" % [
                        OUT,faction])==OK,"native V3 review image")
                captures+=1
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(captures==16,"eight authentic Godot V2/V3 before-after pairs")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G14 V3 NATIVE 3D: %d failed assertions" % failures)
        quit(1)
        return
    print("PASS G14 V3 NATIVE 3D: two real-length rams, four isolated hatches, eight factions, LOD8/13, 16 captures")
    quit(0)
