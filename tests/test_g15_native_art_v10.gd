extends SceneTree

# TARVOKA G15 V10: actual Godot 4.3 native geometry + before/after
# 12 authentic screenshots. No combat logic, no image mockups.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const V9=preload("res://scripts/ui/G15ProductionSurfaceV9.gd")
const V10=preload("res://scripts/ui/G15OpticalGlazingV10.gd")
const OUT="res://build/qa/g15-v10"
var failures:int=0
var images:int=0
var faction_colors:Dictionary={}

func check(ok:bool,what:String)->void:
    if not ok:
        failures+=1
        push_error("G15 V10 REAL 3D QA: "+what)

func _initialize()->void:
    call_deferred("_run")

func _shot(label:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var screen:Image=root.get_texture().get_image()
    check(screen!=null and screen.get_size()==Vector2i(1024,768),
        "real 1024x768 Godot viewport")
    if screen!=null:
        check(screen.save_png(ProjectSettings.globalize_path(
            OUT.path_join(label+".png")))==OK,
            "saved Godot 3D render "+label)
        images+=1

func _difference(name_a:String,name_b:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(name_a+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(name_b+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var changed:int=0
    for y in range(0,a.get_height(),3):
        for x in range(0,a.get_width(),3):
            var c:Color=a.get_pixel(x,y)
            var d:Color=b.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.12:
                changed+=1
    return changed

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "output directory")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.85
    stage.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-28,0)
    sun.light_energy=2.1
    stage.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-25,145,0)
    fill.light_energy=0.95
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
        for quality in [8,13]:
            var hero:bool=quality>=13
            var model:Node3D=Models.build("ew_mobile",faction,true,quality)
            check(model!=null,"eight factions × both LODs")
            if model==null:
                continue
            check(V1.has_model(model) and
                bool(model.get_meta(V9.FLAG,false)) and
                bool(model.get_meta(V10.FLAG,false)),
                "all previous G15 art intact and V10 active")
            check(bool(model.get_meta(
                "tarvoka_g15_v10_no_gameplay_changes",false)),
                "visual-only no BattleSession changes")
            var wheels:=model.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            check(wheels!=null and wheels.get_child_count()==6,
                "all six original moving 6x6 wheel pivots")
            var body:=model.find_child(V10.ASSEMBLY,true,false) as Node3D
            check(body!=null,"physical V10 node group present")
            for side in [-1,1]:
                var side_id:String=str(side)
                var glass:=model.find_child(V10.FRONT+side_id,
                    true,false) as MeshInstance3D
                var sideglass:=model.find_child(V10.SIDE+side_id,
                    true,false) as MeshInstance3D
                check(glass!=null and sideglass!=null,
                    "two curved windshields and two convex door glasses")
                if glass!=null:
                    check(glass.mesh is ArrayMesh and
                        glass.mesh.get_faces().size()>=24,
                        "front glass tessellated with real triangles")
                    check(glass.mesh.get_aabb().size.z>0.013,
                        "front glass has measurable convex curvature")
                    var mat:=glass.material_override as StandardMaterial3D
                    check(mat!=null and mat.clearcoat_enabled and
                        mat.roughness<0.15 and mat.albedo_color.b>mat.albedo_color.r,
                        "proper dark-blue PBR reflective specular coating")
                if sideglass!=null:
                    check(sideglass.mesh is ArrayMesh and
                        sideglass.mesh.get_aabb().size.x>0.005,
                        "side window has real outboard curved geometry")
                    if sideglass.mesh is ArrayMesh:
                        var arrays:Array=sideglass.mesh.surface_get_arrays(0)
                        var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
                        check(normals.size()>0 and
                            normals[0].x*float(side)>0.80,
                            "side glass PBR normals face outward on both sides")
                var old:=model.find_child(
                    "G15_V6_SpecularGlass_"+side_id,true,false
                    ) as MeshInstance3D
                check(old!=null and not old.visible,
                    "previous flat windshield hidden, not overlapping")
                var stripe:=model.find_child(
                    "G15_V10_EnamelAboveSideGlass_"+side_id,
                    true,false) as MeshInstance3D
                check(stripe!=null and
                    stripe.material_override is StandardMaterial3D,
                    "faction color is painted on the new window arch")
                if stripe!=null:
                    var coating:=stripe.material_override as StandardMaterial3D
                    faction_colors[coating.albedo_color.to_html()]=true
                var rear:=model.find_child(
                    "G15_V10_RearSidePanel_"+side_id,
                    true,false) as MeshInstance3D
                check(rear!=null and rear.mesh is BoxMesh and
                    rear.position.z>1.77,
                    "native physical raised rear service panels")
                var glow:=model.find_child(
                    V10.REFLECTION+side_id,true,false)
                check((glow!=null)==hero,
                    "hero only: additional physical optical highlight")
            check(Models.pose_model("ew_mobile",model,"move",0.50),
                "six-wheel drive animation unchanged")
            check(Models.pose_model("ew_mobile",model,"deploy",0.52),
                "EW hydraulic mast deployment unchanged")
            check(Models.pose_model("ew_mobile",model,"scan",0.47),
                "phased array scan animation unchanged")
            check(Models.pose_model("ew_mobile",model,"damage",0.66),
                "V5 destructible radar still animates")
            Models.restore_model_pose("ew_mobile",model)
            if hero and faction in [0,3]:
                stage.add_child(model)
                for view in range(3):
                    camera.position=(
                        Vector3(4.9,2.62,-6.20) if view==0 else
                        (Vector3(-5.10,3.30,-3.85) if view==1 else
                         Vector3(4.75,3.00,5.22)))
                    camera.look_at(Vector3(0,1.38,-0.15))
                    var stem:String="g15-f%02d-view%d" % [faction,view]
                    check(V10.show_finish(model,false),
                        "reversibly restore V9 glass")
                    await _shot(stem+"-v9")
                    check(V10.show_finish(model,true),
                        "restore V10 convex optics")
                    await _shot(stem+"-v10")
                    check(_difference(stem+"-v9",stem+"-v10")>32,
                        "camera confirms real rendered V10/V9 difference")
                stage.remove_child(model)
                model.free()
            else:
                check(V10.show_finish(model,false),
                    "V9 historical material comparison")
                check(V10.show_finish(model,true),
                    "V10 back on across every faction and LOD")
                model.free()
    check(faction_colors.size()==8,
        "eight original paint colors survive")
    check(images==12,"12 real before/after Godot PNG renders")
    var file:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v10-manifest.json")),FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify({
            "version":"G15 V10","panes":4,"real_3d":true,
            "factions":8,"lods":[8,13],"images":images,
            "art_only":true,"errors":failures
        },"  "))
        file.close()
    stage.queue_free()
    await process_frame
    if failures==0:
        print("PASS G15 V10 NATIVE 3D: curved four-window PBR cab, rear EW service, unchanged mast and all eight factions, 12 actual Godot renders")
    else:
        print("FAIL G15 V10 NATIVE 3D: %d findings" % failures)
    quit(1 if failures>0 else 0)
