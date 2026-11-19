extends SceneTree

# G15 V11 actual Godot 4.3 QA: multi-angle HERO13/L0D8,
# original 6x6 pivots, PBR nonmetal rubber, reversible optical trim.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V10=preload("res://scripts/ui/G15OpticalGlazingV10.gd")
const V11=preload("res://scripts/ui/G15Detail360V11.gd")
const OUT="res://build/qa/g15-v11"
var failures:int=0
var captures:int=0

func check(ok:bool,why:String)->void:
    if not ok:
        failures+=1
        push_error("G15 V11 360 REAL 3D QA: "+why)

func _initialize()->void:
    call_deferred("_run")

func _capture(label:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=root.get_texture().get_image()
    check(img!=null and img.get_size()==Vector2i(1024,768),
        "real Godot 1024x768 render "+label)
    if img!=null:
        check(img.save_png(ProjectSettings.globalize_path(
            OUT.path_join(label+".png")))==OK,
            "save native actual-frame "+label)
        captures+=1

func _difference(a:String,b:String)->int:
    var first:=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a+".png")))
    var second:=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b+".png")))
    if first==null or second==null or first.get_size()!=second.get_size():
        return -1
    var count:int=0
    for y in range(0,first.get_height(),3):
        for x in range(0,first.get_width(),3):
            var c:Color=first.get_pixel(x,y)
            var d:Color=second.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.12:
                count+=1
    return count

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"QA capture directory")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.70
    stage.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-28,0)
    sun.light_energy=2.1
    stage.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-25,145,0)
    fill.light_energy=0.96
    stage.add_child(fill)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#25333e")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#b6cbd5")
    env.ambient_light_energy=0.86
    var world:=WorldEnvironment.new()
    world.environment=env
    stage.add_child(world)

    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod>=13
            var model:Node3D=Models.build("ew_mobile",faction,true,lod)
            check(model!=null,"G15 8 factions and two native LODs")
            if model==null:
                continue
            check(bool(model.get_meta(V10.FLAG,false)) and
                bool(model.get_meta(V11.FLAG,false)) and
                bool(model.get_meta("tarvoka_g15_v11_no_gameplay_changes",false)),
                "V10 intact plus native V11 solely visual")
            var assembly:=model.find_child(V11.ASSEMBLY,true,false) as Node3D
            var wheels:=model.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            check(assembly!=null,"front cab sculpt is native node")
            check(wheels!=null and wheels.get_child_count()==6,
                "six original moving pivots preserved")
            if wheels==null:
                model.free()
                continue
            for side in [-1,1]:
                var wipe:=model.find_child(V11.WIPER+str(side),
                    true,false) as MeshInstance3D
                check(wipe!=null and wipe.mesh is CylinderMesh,
                    "physical 3D windshield blade on both panes")
            var ring_count:int=0
            for wheel in wheels.get_children():
                var token:String=str(wheel.name).trim_prefix("G15_Wheel_")
                var rubber:=wheel.find_child(V11.TIRE+token,
                    false,false) as MeshInstance3D
                var bead:=wheel.find_child(V11.BEAD+token,
                    false,false) as MeshInstance3D
                var marks:=wheel.find_child(V11.MARK+token,
                    false,false) as MultiMeshInstance3D
                check(rubber!=null and bead!=null and marks!=null,
                    "native sidewall shoulders on original wheel "+token)
                if rubber!=null:
                    ring_count+=1
                    var mat:=rubber.material_override as StandardMaterial3D
                    check(rubber.mesh is TorusMesh and mat!=null and
                        mat.metallic==0.0 and mat.roughness>0.85,
                        "matte non-metallic sculpted rubber "+token)
                if marks!=null:
                    check(marks.multimesh.instance_count==(12 if hero else 6),
                        "LOD-aware shoulder embossed marks "+token)
            check(ring_count==6,"six complete 3D tyre shoulder rigs")
            check(V11.show_finish(model,false),"V11 reversible old finish")
            for wheel in wheels.get_children():
                var token:String=str(wheel.name).trim_prefix("G15_Wheel_")
                var part:=wheel.find_child(V11.TIRE+token,
                    false,false) as Node3D
                check(part!=null and not part.visible,
                    "V11 wheel shoulder hides for previous comparison")
            check(V11.show_finish(model,true),"V11 restored")
            check(V10.show_finish(model,false),
                "V10 old glazing comparator still operates")
            var shield:=model.find_child(V11.ASSEMBLY,true,false) as Node3D
            check(shield!=null and not shield.visible,
                "historical V10 comparison hides added V11 cab")
            for wheel in wheels.get_children():
                var token:String=str(wheel.name).trim_prefix("G15_Wheel_")
                var shoulder:=wheel.find_child(V11.TIRE+token,
                    false,false) as Node3D
                check(shoulder!=null and not shoulder.visible,
                    "V10 historical comparator hides newer V11 tyre shoulder")
            check(V10.show_finish(model,true),
                "new optical geometry restored without losing 6x6")
            check(Models.pose_model("ew_mobile",model,"move",0.52),
                "six wheels still move")
            check(Models.pose_model("ew_mobile",model,"deploy",0.5),
                "original hydraulic EW mast still deploys")
            check(Models.pose_model("ew_mobile",model,"scan",0.45),
                "original EW arrays still scan")
            check(Models.pose_model("ew_mobile",model,"damage",0.5),
                "original damage rig unchanged")
            Models.restore_model_pose("ew_mobile",model)
            if hero and faction in [0,3]:
                stage.add_child(model)
                for view in range(3):
                    camera.position=(
                        Vector3(4.9,2.62,-6.2) if view==0 else
                        (Vector3(-5.1,3.3,-3.85) if view==1 else
                         Vector3(4.75,3.0,5.22)))
                    camera.look_at(Vector3(0,1.38,-0.15))
                    var key:String="g15-f%02d-a%d" % [faction,view]
                    check(V11.show_finish(model,false),
                        "capture earlier 360 finish")
                    await _capture(key+"-v10")
                    check(V11.show_finish(model,true),
                        "capture refined 360 finish")
                    await _capture(key+"-v11")
                    check(_difference(key+"-v10",key+"-v11")>8,
                        "real 3D V11 sidewall/wiper pixels change "+key)
                stage.remove_child(model)
                model.free()
            else:
                model.free()
    check(captures==12,"12 authentic V10/V11 multi-angle Godot renders")
    var file:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v11-manifest.json")),FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify({
            "version":"G15 V11","real_3d":true,"factions":8,
            "lods":[8,13],"original_wheels":6,"captures":captures,
            "no_gameplay_changes":true,"errors":failures
        },"  "))
        file.close()
    stage.queue_free()
    await process_frame
    if failures==0:
        print("PASS G15 V11 360 NATIVE: six matte rubber shoulders, two real front wipers, 8 factions, 2 LODs, 12 actual Godot angles")
    else:
        print("FAIL G15 V11 360 NATIVE: %d problems" % failures)
    quit(1 if failures>0 else 0)
