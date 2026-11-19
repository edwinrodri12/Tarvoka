extends SceneTree

# G15 V4: visual-only native antenna, hinged mast and actuated cylinder QA.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const OUT="res://build/qa/g15-v4"
var errors:int=0
var saved:int=0

func check(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G15 V4 artwork: "+reason)

func _initialize()->void:
    call_deferred("_run")

func capture(name:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var pic:Image=root.get_texture().get_image()
    check(pic!=null and pic.get_width()>=800,"actual Godot image "+name)
    if pic!=null:
        check(pic.save_png(ProjectSettings.globalize_path(
            OUT.path_join(name+".png")))==OK,"save native image "+name)
        saved+=1

func changed(a:String,b:String)->int:
    var im_a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a+".png")))
    var im_b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b+".png")))
    if im_a==null or im_b==null or im_a.get_size()!=im_b.get_size():
        return -1
    var count:int=0
    for y in range(0,im_a.get_height(),3):
        for x in range(0,im_a.get_width(),3):
            var p:Color=im_a.get_pixel(x,y)
            var q:Color=im_b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.14:
                count+=1
    return count

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"QA output directory")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.8
    stage.add_child(camera)
    camera.current=true
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-48,-35,0)
    key.light_energy=2.05
    stage.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-26,122,0)
    fill.light_energy=0.78
    stage.add_child(fill)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#263540")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#a9becd")
    env.ambient_light_energy=0.70
    world.environment=env
    stage.add_child(world)
    var faction_colors:Dictionary={}
    for faction in range(8):
        for lod in [8,13]:
            var high:bool=lod==13
            var vehicle:Node3D=Models.build("ew_mobile",faction,true,lod)
            check(vehicle!=null,"native G15 faction %d LOD%d" % [faction,lod])
            if vehicle==null:
                continue
            check(V1.has_model(vehicle) and
                bool(vehicle.get_meta(V2.FLAG,false)) and
                bool(vehicle.get_meta(V3.FLAG,false)) and
                bool(vehicle.get_meta(V4.FLAG,false)),
                "V1/V2/V3 retained and V4 installed")
            check(bool(vehicle.get_meta("tarvoka_g15_v4_no_gameplay_changes",false)),
                "all changes are art only")
            var head:=vehicle.find_child(V1.ROTOR,true,false) as Node3D
            var mast:=vehicle.find_child(V1.MAST,true,false) as Node3D
            var new_array:=vehicle.find_child(V4.ARRAY,true,false) as Node3D
            var moving:=vehicle.find_child(V4.MAST_HARDWARE,true,false) as Node3D
            var fixed:=vehicle.find_child(V4.FIXED_HINGE,true,false) as Node3D
            var barrel:=vehicle.find_child(V4.BARREL,true,false) as MeshInstance3D
            var piston:=vehicle.find_child(V4.PISTON,true,false) as MeshInstance3D
            var cells:=vehicle.find_child(V4.CELLS,true,false) as MultiMeshInstance3D
            check(new_array!=null and new_array.get_parent()==head,
                "EW array rotates together with original head")
            check(moving!=null and moving.get_parent()==mast,
                "structural truss follows folding mast")
            check(fixed!=null and barrel!=null and piston!=null and
                barrel.get_parent()==fixed and piston.get_parent()==fixed,
                "actuator is fixed to vehicle chassis, not suspended in air")
            check(cells!=null and cells.multimesh!=null and
                cells.multimesh.instance_count==(42 if high else 16),
                "batched real phased-array elements and correct lightweight LOD")
            for side in [-1,1]:
                var panel:=vehicle.find_child("G15_V4_CantedPanel_%s" % side,
                    true,false) as Node3D
                var shell:=vehicle.find_child("G15_V4_BevelArmor_%s" % side,
                    true,false) as MeshInstance3D
                var stripe:=vehicle.find_child("G15_V4_PanelFactionRail_%s" % side,
                    true,false) as MeshInstance3D
                check(panel!=null and absf(panel.rotation_degrees.z)>7.0,
                    "slanted panel silhouette visible")
                check(shell!=null and shell.mesh is ArrayMesh and
                    shell.mesh.get_faces().size()==84,
                    "solid chamfered electronic panel geometry")
                check(stripe!=null and
                    stripe.material_override is StandardMaterial3D,
                    "real faction enamel on antenna")
                if stripe!=null:
                    var material:=stripe.material_override as StandardMaterial3D
                    faction_colors[material.albedo_color.to_html()]=true
            var old:=vehicle.find_child("G15_AntennaPanel_-1",
                true,false) as MeshInstance3D
            check(old!=null and not old.visible,
                "old simple panels hidden under upgraded design")
            check(Models.pose_model("ew_mobile",vehicle,"deploy",0.0),
                "folded 6x6 EW mast pose")
            var span_folded:float=barrel.scale.y
            var pose_folded:Vector3=barrel.position
            check(Models.pose_model("ew_mobile",vehicle,"deploy",1.0),
                "fully deployed physical EW antenna pose")
            var span_open:float=barrel.scale.y
            check(absf(span_folded-span_open)>0.03 or
                pose_folded.distance_to(barrel.position)>0.08,
                "hydraulic cylinder follows mast, not a static decoration")
            check(Models.pose_model("ew_mobile",vehicle,"scan",0.6),
                "directional EW head scan retained")
            check(absf(head.rotation_degrees.y)>90.0,
                "head carries genuine rotating native array")
            check(Models.pose_model("ew_mobile",vehicle,"jam",0.5),
                "visual-only EW signal animation retained")
            Models.restore_model_pose("ew_mobile",vehicle)
            check(head.rotation==Vector3.ZERO and mast.rotation==Vector3.ZERO and
                absf(barrel.scale.y-span_open)<0.002,
                "exact mast and hydraulic rig reset")
            check(V4.show_finish(vehicle,false) and not new_array.visible and
                old.visible,"V3 historical antenna comparison reversible")
            check(V4.show_finish(vehicle,true) and new_array.visible and
                not old.visible,"complete V4 materials restored")
            if high and faction in [0,3]:
                stage.add_child(vehicle)
                for view in range(2):
                    camera.position=(
                        Vector3(4.8,4.2,-5.8) if view==0 else
                        Vector3(-5.1,3.9,5.4))
                    camera.look_at(Vector3(0,1.96,0))
                    var tag:String="g15-f%02d-view%d" % [faction,view]
                    check(V4.show_finish(vehicle,false),"legacy antenna capture")
                    await capture(tag+"-v3")
                    check(V4.show_finish(vehicle,true),"updated antenna capture")
                    await capture(tag+"-v4")
                    check(changed(tag+"-v3",tag+"-v4")>25,
                        "real pixels differ V3 to V4 in Godot renderer")
                if faction==0:
                    camera.position=Vector3(3.9,3.4,-4.6)
                    camera.look_at(Vector3(0,2.02,0))
                    check(Models.pose_model("ew_mobile",vehicle,"deploy",0.0),
                        "hydraulic folded capture")
                    await capture("g15-v4-folded")
                    check(Models.pose_model("ew_mobile",vehicle,"deploy",1.0),
                        "hydraulic deployed capture")
                    await capture("g15-v4-deployed")
                    check(changed("g15-v4-folded","g15-v4-deployed")>45,
                        "true visual difference in animated mast deployment")
                stage.remove_child(vehicle)
                vehicle.free()
            else:
                vehicle.free()
    check(faction_colors.size()==8,"all 8 distinct G15 paints preserved")
    check(saved==10,"8 real before/after images + 2 mast position images")
    var report:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v4-manifest.json")),FileAccess.WRITE)
    if report!=null:
        report.store_string(JSON.stringify({
            "model":"G15 actual Godot 3D war-electronics carrier",
            "revision":"V4 twin canted EW arrays with physical moving actuator",
            "factions":8,"lods":[8,13],"captures":saved,
            "combat_changes":false,"art_final":false,"errors":errors
        },"  "))
        report.close()
    stage.queue_free()
    await process_frame
    print(("PASS G15 V4 NATIVE 3D:" if errors==0 else "FAIL G15 V4 NATIVE 3D:")+
        " 2 closed EW arrays, batched cells, dynamic hydraulic mast, 8 factions, 2 LODs, 10 native Godot renders; findings=%d" % errors)
    quit(1 if errors>0 else 0)
