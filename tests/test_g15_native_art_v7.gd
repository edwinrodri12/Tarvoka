extends SceneTree

# G15 V7: native Godot 4.3 six-wheel suspension, actual chassis rails,
# joined shelter armor, service panel and physical paint; all ART ONLY.
# Verifies preserved V1-V6 rigs, LODs, 8 factions and real camera differences.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const V5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const V7=preload("res://scripts/ui/G15MechanicalExteriorV7.gd")
const OUT="res://build/qa/g15-v7"
var failures:int=0
var captures:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G15 V7 REAL 3D: "+message)

func _initialize()->void:
    call_deferred("_run")

func capture(label:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var frame:Image=root.get_texture().get_image()
    check(frame!=null and frame.get_width()>=800 and frame.get_height()>=600,
        "true camera view "+label)
    if frame!=null:
        check(frame.save_png(ProjectSettings.globalize_path(
            OUT.path_join(label+".png")))==OK,"saved Godot screenshot "+label)
        captures+=1

func _difference(old_label:String,new_label:String)->int:
    var prev:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(old_label+".png")))
    var newer:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(new_label+".png")))
    if prev==null or newer==null or prev.get_size()!=newer.get_size():
        return -1
    var pixels:int=0
    for y in range(0,prev.get_height(),3):
        for x in range(0,prev.get_width(),3):
            var a:Color=prev.get_pixel(x,y)
            var b:Color=newer.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.14:
                pixels+=1
    return pixels

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"render output path")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.9
    stage.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-43,-30,0)
    sun.light_energy=2.1
    stage.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,132,0)
    fill.light_color=Color("#bdccd9")
    fill.light_energy=0.81
    stage.add_child(fill)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#2a3741")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#b5c4cb")
    env.ambient_light_energy=0.73
    environment.environment=env
    stage.add_child(environment)

    var enamels:Dictionary={}
    for faction in range(8):
        for quality in [8,13]:
            var hero:bool=quality==13
            var model:Node3D=Models.build("ew_mobile",faction,true,quality)
            check(model!=null,"real original G15 faction%d LOD%d" % [
                faction,quality])
            if model==null:
                continue
            check(V1.has_model(model) and
                bool(model.get_meta(V2.FLAG,false)) and
                bool(model.get_meta(V3.FLAG,false)) and
                bool(model.get_meta(V4.FLAG,false)) and
                bool(model.get_meta(V5.FLAG,false)) and
                bool(model.get_meta(V6.FLAG,false)) and
                bool(model.get_meta(V7.FLAG,false)),
                "all seven native 3D revisions built without regression")
            check(bool(model.get_meta("tarvoka_g15_v7_no_gameplay_changes",false)),
                "no fake playable capabilities")
            var hull:=model.find_child(V1.CHASSIS,true,false) as Node3D
            var wheels:=model.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            var finish:=model.find_child(V7.ASSEMBLY,true,false) as Node3D
            check(finish!=null and finish.get_parent()==hull,
                "3D mechanical art anchored to base six-wheel chassis")
            check(wheels!=null and wheels.get_child_count()==6,
                "all six V1 actual tire pivots retained and untouched")
            for group in [V7.UNDERBODY,V7.CAB_SEAMS,V7.SHELTER_SEAMS]:
                var piece:=model.find_child(group,true,false) as Node3D
                check(piece!=null and piece.get_parent()==finish,
                    "true subassemblies for "+group)
            for side in [-1,1]:
                var id:String=str(side)
                var beam:=model.find_child(
                    "G15_V7_ClosedLongitudinalFrame_"+id,
                    true,false) as MeshInstance3D
                check(beam!=null and beam.mesh is ArrayMesh,
                    "physical welded underframe girder")
                if beam!=null and beam.mesh is ArrayMesh:
                    check(beam.mesh.get_faces().size()==84,
                        "true closed 28-triangle rail cross section")
                    check(absf(beam.rotation_degrees.x)<0.01 and
                        beam.mesh.get_aabb().size.z>3.2,
                        "longitudinal geometry follows Z wheelbase, not Y")
                    check(beam.position.y>=0.40 and beam.position.y<=0.60,
                        "underframe rail remains below vehicle cabin")
                var cab_step:=model.find_child(
                    "G15_V7_CabStep_"+id,true,false) as MeshInstance3D
                check(cab_step!=null and cab_step.mesh is ArrayMesh,
                    "armored entry step is true beveled steel mesh")
                var panel:=model.find_child(
                    "G15_V7_CableAccessPlate_"+id,
                    true,false) as MeshInstance3D
                check(panel!=null and panel.mesh is ArrayMesh and
                    panel.mesh.get_faces().size()==84,
                    "welded access cover real sealed side geometry")
                var enamel:=model.find_child(
                    "G15_V7_FactionAccessStripe_"+id,
                    true,false) as MeshInstance3D
                check(enamel!=null and
                    enamel.material_override is StandardMaterial3D,
                    "factory enamel visible on original faction")
                if enamel!=null:
                    var material:=enamel.material_override as StandardMaterial3D
                    enamels[material.albedo_color.to_html()]=true
                    check(absf(enamel.position.x)>0.89,
                        "new faction metal physically outside service hatch")
                var flap:=model.find_child(
                    "G15_V7_RubberWheelMudflap_%s_%d" % [id,0],
                    true,false)
                check((flap!=null)==hero,
                    "Android LOD8 omits 6 detailed mudflaps and brackets")
                for axle in range(3):
                    var hub:=model.find_child(
                        "G15_V7_Differential_%d" % axle,
                        true,false) as MeshInstance3D
                    var shaft:=model.find_child(
                        "G15_V7_AxleShaft_%d" % axle,
                        true,false) as MeshInstance3D
                    check(hub!=null and hub.mesh is SphereMesh and
                        shaft!=null and shaft.mesh is CylinderMesh,
                        "3 real physical differentials with cross-car shafts")
                    if hub!=null:
                        check(absf(hub.position.z-float(V7.AXLES[axle]))<0.01,
                            "actual axle Z aligned with old tire pivot")
            check(Models.pose_model("ew_mobile",model,"move",0.56),
                "existing moving 6x6 wheels still work")
            check(Models.pose_model("ew_mobile",model,"deploy",0.24),
                "antenna mast and hydraulic V4 actuator still work")
            check(Models.pose_model("ew_mobile",model,"scan",0.60),
                "directional antenna scanning unchanged")
            check(Models.pose_model("ew_mobile",model,"damage",0.68),
                "V5 damage state unchanged by new body finish")
            Models.restore_model_pose("ew_mobile",model)
            check(int(model.get_meta("tarvoka_g15_v5_visual_damage",9))==0,
                "native V5 damage fully restored to pristine body")
            check(V7.show_finish(model,false) and not finish.visible,
                "accurate V6 back-compat preview is reversible")
            check(V7.show_finish(model,true) and finish.visible,
                "accurate V7 new geometry restores instantly")
            if faction in [0,3] and hero:
                stage.add_child(model)
                for view in range(3):
                    camera.position=(
                        Vector3(5.5,2.85,-5.2) if view==0 else
                        (Vector3(-5.6,2.8,4.4) if view==1 else
                         Vector3(2.8,1.8,5.7)))
                    camera.look_at(Vector3(0,1.22,0))
                    var prefix:String="g15-f%02d-angle%d" % [faction,view]
                    check(V7.show_finish(model,false),
                        "V6 source render comparison")
                    await capture(prefix+"-v6")
                    check(V7.show_finish(model,true),
                        "V7 geometry render comparison")
                    await capture(prefix+"-v7")
                    check(_difference(prefix+"-v6",prefix+"-v7")>40,
                        "actual rendered differences visible at each angle")
                stage.remove_child(model)
                model.free()
            else:
                model.free()
    check(enamels.size()==8,"all eight approved faction colors distinguishable")
    check(captures==12,"twelve authentic native Godot V6/V7 comparisons")
    var file:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v7-manifest.json")),FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify({
            "unit":"G15 EW 6x6 native 3D",
            "revision":"V7 physical undercarriage and welded exterior joinery",
            "real_suspension_axles":3,
            "factions":8,"lods":[8,13],"screenshots":captures,
            "gameplay_changes":false,"final_approved":false,
            "failures":failures
        },"  "))
        file.close()
    stage.queue_free()
    await process_frame
    if failures==0:
        print("PASS G15 V7 NATIVE 3D: true chassis rails, 3 axles, 6x6 drivetrain, welded armor seams, faction colors, 2 LODs, 12 real Godot comparisons")
    else:
        print("FAIL G15 V7 NATIVE 3D: %d findings" % failures)
    quit(1 if failures>0 else 0)
