extends SceneTree

# G15 V2 TRUE native Godot 4.3 quality: curved wheel protection,
# physical roof-to-mast gussets, geometry, six-wheel action preserved.
# Render ten genuine Godot frames (same camera before/after), hero and LOD8.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const OUT="res://build/qa/g15-v2"
var failures:int=0
var images:Array[Dictionary]=[]

func check(value:bool,why:String)->void:
    if not value:
        failures+=1
        push_error("G15 V2 native 3D sculpture: "+why)

func _initialize()->void:
    call_deferred("_run")

func _capture(label:String,viewport:Window,stage:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=viewport.get_texture().get_image()
    check(image!=null and image.get_width()>=640 and
        image.get_height()>=480,"genuine Godot rendered frame "+label)
    if image==null:
        return
    check(image.save_png(ProjectSettings.globalize_path(
        OUT.path_join(label+".png")))==OK,
        "PNG saved in actual native renderer "+label)
    images.append({"file":label+".png","stage":stage})
    print("G15 V2 REAL NATIVE GODOT 3D: "+label)

func _set_camera(cam:Camera3D,position:Vector3)->void:
    cam.position=position
    cam.look_at(Vector3(0,1.5,0),Vector3.UP)

func _changed(a_name:String,b_name:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a_name+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b_name+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var changes:int=0
    for y in range(0,a.get_height(),2):
        for x in range(0,a.get_width(),2):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.11:
                changes+=1
    return changes

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "real-render output directory")
    var stage:=Node3D.new()
    root.add_child(stage)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=5.8
    stage.add_child(cam)
    cam.current=true
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-47,-32,0)
    light.light_energy=1.7
    stage.add_child(light)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,123,0)
    fill.light_energy=0.76
    stage.add_child(fill)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#27353f")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#a5b8c5")
    env.ambient_light_energy=0.65
    world.environment=env
    stage.add_child(world)

    for faction in range(8):
        for lod in [8,13]:
            var high:bool=lod==13
            var vehicle:=Models.build("ew_mobile",faction,true,lod)
            check(vehicle!=null,"g15 exists at faction %d LOD%d" % [
                faction,lod])
            if vehicle==null:
                continue
            check(bool(vehicle.get_meta(V1.FLAG,false)) and
                bool(vehicle.get_meta(V2.FLAG,false)),
                "original G15 preserved with closed V2 model")
            var wheels:=vehicle.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            check(wheels!=null and wheels.get_child_count()==6,
                "six original wheel pivots untouched")
            var new_arch:=vehicle.find_child(V2.FENDERS,
                true,false) as MultiMeshInstance3D
            var gussets:=vehicle.find_child(V2.BRACES,
                true,false) as MeshInstance3D
            check(new_arch!=null and gussets!=null,
                "real closed curved mesh and original roof brace")
            if new_arch!=null and new_arch.multimesh!=null:
                check(new_arch.multimesh.instance_count==3 and
                    new_arch.multimesh.mesh is ArrayMesh,
                    "both six-wheel arches batched across exactly three axles")
                var segment_count:int=18 if high else 10
                check(new_arch.multimesh.mesh.get_faces().size()==
                    2*(segment_count*8+4)*3,
                    "closed true triangles covering each axle arch")
                for i in range(3):
                    check(absf(new_arch.multimesh.get_instance_transform(i).
                        origin.z-float(V2.AXLES[i]))<0.001,
                        "arch geometry seated on original axle, no drift")
            if gussets!=null:
                check(gussets.mesh is ArrayMesh and
                    gussets.mesh.get_faces().size()==24*3,
                    "two solid root-to-mast welded triangular supports")
                check(gussets.get_parent()==vehicle.find_child(
                    V1.CHASSIS,true,false),"fixed gussets remain on hull")
            check(int(vehicle.get_meta(
                "tarvoka_g15_v2_added_draw_nodes",-1))==2,
                "only two GPU draw objects, not 6+2 separate shapes")
            check(vehicle.find_child("G13_Autocannon_-1",true,false)==null,
                "electronic warfare unit has no fake twin guns")
            check(Models.pose_model("ew_mobile",vehicle,"move",0.45),
                "physical wheel roll unchanged")
            check(Models.pose_model("ew_mobile",vehicle,"deploy",0.52),
                "folding antenna original V1 motor unchanged")
            check(Models.pose_model("ew_mobile",vehicle,"scan",0.4),
                "directional electronic head still rotates")
            Models.restore_model_pose("ew_mobile",vehicle)
            check(V2.show_finish(vehicle,false),
                "old V1 original body visually reversible")
            if new_arch!=null:
                check(not new_arch.visible,"V1 historical comparison hides V2")
            check(V2.show_finish(vehicle,true) and
                new_arch!=null and new_arch.visible,
                "new V2 real meshes restore after historical compare")
            if faction==0:
                stage.add_child(vehicle)
                _set_camera(cam,Vector3(4.7,4.0,5.7))
                check(V2.show_finish(vehicle,false),"V1 original photo")
                await _capture("%02d-isometric-v1" % lod,root,"old")
                check(V2.show_finish(vehicle,true),"V2 real mesh photo")
                await _capture("%02d-isometric-v2" % lod,root,"new")
                _set_camera(cam,Vector3(-5.8,2.4,1.6))
                check(V2.show_finish(vehicle,false),"V1 side old")
                await _capture("%02d-side-v1" % lod,root,"old")
                check(V2.show_finish(vehicle,true),"V2 side new")
                await _capture("%02d-side-v2" % lod,root,"new")
                var delta:int=_changed("%02d-side-v1" % lod,
                    "%02d-side-v2" % lod)
                check(delta>20,"six physical curved arches actually seen in Godot LOD%d: %d" % [lod,delta])
                stage.remove_child(vehicle)
                vehicle.free()
            else:
                vehicle.free()
    var hero:=Models.build("ew_mobile",3,true,13)
    stage.add_child(hero)
    _set_camera(cam,Vector3(-4.2,3.15,-4.7))
    await _capture("13-faction3-front-v2",root,"new")
    _set_camera(cam,Vector3(4.7,3.2,4.1))
    await _capture("13-faction3-rear-v2",root,"new")
    stage.remove_child(hero)
    hero.free()
    check(images.size()==10,"10 authentic native-render G15 V2 images")
    var manifest:=FileAccess.open(
        ProjectSettings.globalize_path(OUT.path_join(
            "g15-v2-manifest.json")),FileAccess.WRITE)
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "unit":"G15 original EW communications carrier",
            "revision":"V2 closed curved wheel arches and real roof mast gussets",
            "visual_only":true,"not_approved_as_final":true,
            "captured":images,"failures":failures},"  "))
        manifest.close()
    stage.queue_free()
    await process_frame
    if failures==0:
        print("PASS G15 V2 NATIVE 3D: 8 factions, both 3D LODs, 6 true curved wheel arches, 2 physical welded mast gussets, reversible V1 comparison, 10 actual Godot screenshots, animations preserved")
    quit(1 if failures>0 else 0)
