extends SceneTree

# G15 V3: real native geometry, PBR rubber sidewalls, eight faction liveries,
# original antenna actions and actual V2/V3 comparison in Godot 4.3.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const OUT="res://build/qa/g15-v3"
var problems:int=0
var captures:Array[String]=[]

func check(ok:bool,why:String)->void:
    if not ok:
        problems+=1
        push_error("G15 V3 native sculpt: "+why)

func _initialize()->void:
    call_deferred("_run")

func _snap(name:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var shot:Image=root.get_texture().get_image()
    var p:String=ProjectSettings.globalize_path(
        OUT.path_join(name+".png"))
    check(shot!=null and shot.get_width()>=640 and
        shot.get_height()>=480,"render actual Godot camera image "+name)
    if shot!=null:
        check(shot.save_png(p)==OK,"saved actual native 3D PNG "+name)
        captures.append(name+".png")

func _difference(a_name:String,b_name:String)->int:
    var a:Image=Image.load_from_file(
        ProjectSettings.globalize_path(OUT.path_join(a_name+".png")))
    var b:Image=Image.load_from_file(
        ProjectSettings.globalize_path(OUT.path_join(b_name+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var altered:int=0
    for y in range(0,a.get_height(),3):
        for x in range(0,a.get_width(),3):
            var c:Color=a.get_pixel(x,y)
            var d:Color=b.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.14:
                altered+=1
    return altered

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "V3 output directory")
    var stage:=Node3D.new()
    root.add_child(stage)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=5.55
    stage.add_child(cam)
    cam.current=true
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-50,-33,0)
    light.light_energy=2.05
    stage.add_child(light)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,123,0)
    fill.light_energy=0.81
    stage.add_child(fill)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#26333e")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#aabcc9")
    env.ambient_light_energy=0.72
    world.environment=env
    stage.add_child(world)
    var hues:Dictionary={}
    for faction in range(8):
        for art_level in [8,13]:
            var hero:bool=art_level==13
            var unit:=Models.build("ew_mobile",faction,true,art_level)
            check(unit!=null,"faction %d level %d can render" % [
                faction,art_level])
            if unit==null:
                continue
            check(V1.has_model(unit) and bool(unit.get_meta(V2.FLAG,false)) and
                bool(unit.get_meta(V3.FLAG,false)),
                "V1 and V2 remain intact beneath genuine V3 sculpture")
            var existing_wheels:=unit.find_child(
                V1.WHEEL_GROUP,true,false) as Node3D
            check(existing_wheels!=null and
                existing_wheels.get_child_count()==6,
                "all six original physical wheel pivots still rotate")
            var tire_count:int=0
            for wheel in existing_wheels.get_children():
                for node in wheel.get_children():
                    if str(node.name).begins_with(V3.SIDEWALL_PREFIX):
                        tire_count+=1
                        check((node as MeshInstance3D).mesh is TorusMesh,
                            "tire bulges are actual 3D curved TorusMesh")
                        var rubber:StandardMaterial3D=(
                            (node as MeshInstance3D).material_override
                            as StandardMaterial3D)
                        check(rubber.metallic==0.0 and rubber.roughness>=0.92,
                            "nonmetal matte synthetic tire rubber")
            check(tire_count==(6 if hero else 0),
                "six sculpted bulged tires for inspection, zero extra on LOD8")
            for shape_name in [V3.SHELTER,V3.CAB,V3.ROOF]:
                var m:=unit.find_child(shape_name,true,false) as MeshInstance3D
                check(m!=null and m.mesh is ArrayMesh,
                    "closed real chamfered native surface "+shape_name)
                if m!=null:
                    check(m.mesh.get_faces().size()==28*3,
                        "28 watertight triangles, not fake box "+shape_name)
            for old_name in V3.OLD:
                var old:=unit.find_child(old_name,true,false) as MeshInstance3D
                check(old!=null and not old.visible,
                    "obsolete flat block is hidden "+old_name)
            var panel:=unit.find_child("G15_SidePaint_-1",
                true,false) as MeshInstance3D
            if panel!=null and panel.material_override is StandardMaterial3D:
                hues[(panel.material_override as StandardMaterial3D).
                    albedo_color.to_html()]=true
            check(unit.find_child(V2.FENDERS,true,false)!=null and
                unit.find_child(V2.BRACES,true,false)!=null,
                "V2 six curved fenders and mast welded gussets remain")
            check(Models.pose_model("ew_mobile",unit,"deploy",0.34),
                "V3 retains original mast deploy")
            check(Models.pose_model("ew_mobile",unit,"scan",0.62),
                "V3 retains original head sweep")
            check(Models.pose_model("ew_mobile",unit,"jam",0.47),
                "V3 retains visuals-only signal demo")
            check(Models.pose_model("ew_mobile",unit,"move",0.38),
                "V3 retains original six-wheel motion")
            Models.restore_model_pose("ew_mobile",unit)
            check(str(unit.get_meta("tarvoka_g15_visual_pose",""))=="idle",
                "restores entire native model without remeshing")
            check(bool(unit.get_meta("tarvoka_g15_v3_no_gameplay_changes",false)),
                "pure art finish only, no fictional EW combat power")
            check(V3.show_finish(unit,false),
                "old square shelter remains inspectable for V2 comparison")
            check(unit.find_child(V3.SHELTER,true,false).visible==false and
                unit.find_child("G15_ElectronicShelter",true,false).visible,
                "V2 square shelter visible only when V3 hidden")
            check(V3.show_finish(unit,true) and
                unit.find_child(V3.SHELTER,true,false).visible,
                "V3 is reversibly displayed with all existing physical pivots")
            if faction in [0,3] and hero:
                stage.add_child(unit)
                for view in range(2):
                    cam.position=(
                        Vector3(5.35,4.1,6.2) if view==0 else
                        Vector3(-5.5,2.5,-3.1))
                    cam.look_at(Vector3(0,1.52,0))
                    var prefix:String="g15-f%02d-angle%d" % [
                        faction,view]
                    check(V3.show_finish(unit,false),"V2 before native capture")
                    await _snap(prefix+"-v2")
                    check(V3.show_finish(unit,true),"V3 after native capture")
                    await _snap(prefix+"-v3")
                    check(_difference(prefix+"-v2",prefix+"-v3")>25,
                        "V3 chamfered metal truly changes visible Godot pixels")
                stage.remove_child(unit)
                unit.free()
            else:
                unit.free()
    check(hues.size()==8,
        "G15 V3 preserves all eight approved distinct faction colors")
    check(captures.size()==8,
        "eight real render comparisons: 2 factions x 2 views x before/after")
    var report:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v3-manifest.json")),FileAccess.WRITE)
    if report!=null:
        report.store_string(JSON.stringify({
            "unit":"G15 electronic warfare native 6x6",
            "version":"V3 real chamfered body and cab, shelter electronics and tire sidewalls",
            "faction_count":8,
            "lods":[8,13],
            "captured":captures,
            "no_gameplay_changes":true,
            "art_final":false,
            "failures":problems
        },"  "))
        report.close()
    stage.queue_free()
    await process_frame
    if problems==0:
        print("PASS G15 V3 NATIVE 3D: 3 closed bevelled shells, rubber torus sidewalls, V1/V2 preserved, 8 factions, 2 LODs, antenna rig and 8 real Godot screenshots")
    else:
        print("FAIL G15 V3 NATIVE 3D: %d findings" % problems)
    quit(1 if problems>0 else 0)
