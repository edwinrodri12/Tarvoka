extends SceneTree

# G13 V25: genuine Godot 4.3 tactical zoom / original-vs-finished QA.
# Never claim CI software render latency as physical Android FPS.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/G13TacticalSilhouetteV25.gd")
const RadarV27=preload("res://scripts/ui/G13ElevatedRadarV27.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Art24=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const TOTAL:=17
var failures:int=0
var screenshots:int=0
var evidence:Dictionary={}

func check(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V25 tactical zoom: "+reason)

func count_draws(node:Node,ancestor_visible:bool=true)->int:
    var visible:bool=ancestor_visible
    if node is Node3D:
        visible=visible and (node as Node3D).visible
    if not visible:
        return 0
    var total:int=1 if node is MeshInstance3D or (
        node is MultiMeshInstance3D) else 0
    for child in node.get_children():
        total+=count_draws(child,visible)
    return total

func take_image(view:SubViewport,dest:String,label:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=view.get_texture().get_image()
    check(image!=null and not image.is_empty(),
        "render actual 3D view "+label)
    if image==null or image.is_empty():
        return null
    if image.save_png(dest.path_join(label+".png"))==OK:
        screenshots+=1
    else:
        check(false,"save PNG "+label)
    return image

func pixel_delta(a:Image,b:Image)->Dictionary:
    var changed:int=0
    var sampled:int=0
    var difference:float=0.0
    if a==null or b==null or a.get_size()!=b.get_size():
        return {"changed":0,"mean_absolute_error":0.0,"sampled":0}
    for y in range(0,a.get_height(),4):
        for x in range(0,a.get_width(),4):
            var o:Color=a.get_pixel(x,y)
            var n:Color=b.get_pixel(x,y)
            var d:float=(absf(o.r-n.r)+absf(o.g-n.g)+absf(o.b-n.b))/3.0
            sampled+=1
            difference+=d
            if d>0.03:
                changed+=1
    return {"changed":changed,
        "mean_absolute_error":difference/float(maxi(1,sampled)),
        "sampled":sampled}

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var dest:String=OS.get_environment("G13_V25_CAPTURE_DIR")
    if dest.is_empty():
        dest="/tmp/g13-v25-tactical"
    check(DirAccess.make_dir_recursive_absolute(dest)==OK,
        "create capture directory")
    var view:=SubViewport.new()
    view.size=Vector2i(960,640)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#25343c")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#c6d5d8")
    environment.ambient_light_energy=0.74
    world.environment=environment
    view.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-47,-34,0)
    light.light_energy=1.38
    view.add_child(light)
    var camera:=Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    view.add_child(camera)

    var counts:Array[int]=[]
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,8)
        check(model!=null,"eight original faction G13 3D models")
        if model==null:
            continue
        check(bool(model.get_meta(Finish.FLAG,false)),
            "native tactical finish installed")
        check(int(model.get_meta("tarvoka_g13_v25_added_draw_nodes",-1))==0,
            "no new per-unit draw objects")
        var paint:=model.find_child("G13_SideEnamel_1",
            true,false) as MeshInstance3D
        var paint_material:=paint.material_override as StandardMaterial3D
        check(paint_material!=null and paint_material.albedo_color.is_equal_approx(
            Models.faction_paint_color(faction).darkened(0.10)),
            "official faction color remains EXACT across tactical LODs")
        var original_count:int=count_draws(model)
        counts.append(original_count)
        var pitch:=model.find_child(G13.GUNS,true,false) as Node3D
        var radar:=model.find_child(G13.RADAR,true,false) as Node3D
        var wheels:=model.find_child(G13.WHEELS,true,false) as MultiMeshInstance3D
        check(pitch!=null and radar!=null and wheels!=null,
            "same original twin pitch, radar, four-wheel drivetrain")
        if pitch!=null:
            for side in [-1,1]:
                var tube:=pitch.find_child("G13_Autocannon_%d" % side,
                    false,false) as MeshInstance3D
                var muzzle:=pitch.find_child("G13_RealMuzzle_%d" % side,
                    false,false) as MeshInstance3D
                check(tube!=null and muzzle!=null,
                    "two distinct barrels with live firing pivots")
                if tube!=null and muzzle!=null:
                    check(is_equal_approx(
                        (tube.mesh as CylinderMesh).top_radius,
                        Finish.ENLARGED_BARREL_RADIUS),
                        "existing 3D barrel cross section is enlarged")
                    check(is_equal_approx(
                        (muzzle.mesh as CylinderMesh).top_radius,
                        Finish.ENLARGED_MUZZLE_RADIUS),
                        "existing 3D muzzle cross section is enlarged")
        if radar!=null:
            var dish:=radar.find_child("G13_TiltedRadarDish",
                false,false) as MeshInstance3D
            check(dish!=null and is_equal_approx(
                (dish.mesh as CylinderMesh).top_radius,
                RadarV27.DISH_RADIUS),
                "current tactical radar is the wider V27 3D sculpture")
            check(RadarV27.show_v26_reference(model,true),
                "authentic earlier V25 3D dish and mast may be inspected")
            check(dish!=null and is_equal_approx(
                (dish.mesh as CylinderMesh).top_radius,
                Finish.ENLARGED_RADAR_RADIUS),
                "previous independent V25 search radar remains available")
        for action in ["idle","scan","move","aim_air","attack_air",
                "aim_ground","attack_ground"]:
            check(Models.pose_model("aa_mobile",model,action,0.43),
                "unchanged seven existing animations: "+action)
        Models.restore_model_pose("aa_mobile",model)
        check(count_draws(model)==original_count,
            "no draws allocated by firing/steering/animation")
        check(not Finish.apply(model),"idempotent art pass")
        check(Finish.show_v1_reference(model,true),
            "restore exact original cylinder/material resources")
        var tube:=pitch.find_child("G13_Autocannon_-1",
            false,false) as MeshInstance3D
        check(is_equal_approx(
            (tube.mesh as CylinderMesh).top_radius,0.057),
            "authentic baseline twin barrel recovered")
        check(Finish.show_v1_reference(model,false),
            "return V25 finished geometry")
        check(RadarV27.show_v26_reference(model,true),
            "historical V25 faction render excludes later raised V27 radar")
        check(count_draws(model)==original_count,
            "same count before and after 3D material/mesh swap")
        view.add_child(model)
        camera.position=Vector3(3.5,3.0,-3.6)
        camera.look_at(Vector3(0,1.1,0),Vector3.UP)
        camera.size=4.6
        await take_image(view,dest,"g13_v25_faction_%02d" % faction)
        view.remove_child(model)
        model.free()
    check(counts.size()==8,
        "eight faction native models provide draw counts")
    if counts.size()==8:
        for amount in counts:
            check(amount==counts[0],"same low-cost draw count for all factions")

    var subject:=Models.build("aa_mobile",0,true,8)
    check(subject!=null,"single G13 for tactical comparison")
    if subject==null:
        quit(1)
        return
    check(RadarV27.show_v26_reference(subject,true),
        "V1/V25 identical camera test uses original physical radar height")
    view.add_child(subject)
    camera.position=Vector3(3.5,3.0,-3.6)
    camera.look_at(Vector3(0,1.10,0),Vector3.UP)
    for zoom in ["close","medium","far"]:
        camera.size=({"close":4.6,"medium":8.0,"far":14.0})[zoom]
        check(Finish.show_v1_reference(subject,true),
            "original V1 silhouette same camera "+zoom)
        var original:Image=await take_image(view,dest,
            "same_zoom_%s_v1" % zoom)
        check(Finish.show_v1_reference(subject,false),
            "finished V25 silhouette same camera "+zoom)
        var finished:Image=await take_image(view,dest,
            "same_zoom_%s_v25" % zoom)
        evidence[zoom]=pixel_delta(original,finished)
    check(int(evidence["close"]["changed"])>8,
        "real low-cost silhouette improvement visibly rendered at close range")
    check(float(evidence["far"]["mean_absolute_error"])<0.10,
        "far view still preserves original faction/weather scene")

    camera.size=4.8
    check(Models.pose_model("aa_mobile",subject,"attack_air",0.41),
        "V25 guns still pitch upward to attack air")
    await take_image(view,dest,"g13_v25_attack_air")
    check(Models.pose_model("aa_mobile",subject,"attack_ground",0.41),
        "V25 guns still pitch low to attack ground")
    await take_image(view,dest,"g13_v25_attack_ground")
    view.remove_child(subject)
    subject.free()

    var hero:=Models.build("aa_mobile",0,true,13)
    check(hero!=null,"original V24 hero remains buildable")
    if hero!=null:
        check(bool(hero.get_meta(Art24.FLAG,false)),
            "V24 full exterior unchanged by low-cost V25")
        check(not bool(hero.get_meta(Finish.FLAG,false)),
            "V25 mobile finish never touches LOD13 hero meshes")
        var tube:=hero.find_child("G13_Autocannon_-1",
            true,false) as MeshInstance3D
        check(tube!=null and not is_equal_approx(
            (tube.mesh as CylinderMesh).top_radius,
            Finish.ENLARGED_BARREL_RADIUS),
            "approved full hero cannon is not replaced")
        view.add_child(hero)
        Models.restore_model_pose("aa_mobile",hero)
        camera.size=4.8
        await take_image(view,dest,"g13_v24_hero_unchanged")
        view.remove_child(hero)
        hero.free()

    check(screenshots==TOTAL,"exact 17 authentic Godot images")
    var result:Dictionary={
        "revision":"G13 V25 LOD8 only",
        "source":"Godot 4.3 Compatibility renderer / Linux software GL",
        "android_fps_measured":false,
        "factions":8,
        "new_render_nodes_per_unit":0,
        "shots":screenshots,
        "visual_delta":evidence,
        "failures":failures
    }
    var file:=FileAccess.open(dest.path_join(
        "g13-v25-tactical-summary.json"),FileAccess.WRITE)
    check(file!=null,"write inspectable metrics")
    if file!=null:
        file.store_string(JSON.stringify(result,"  ")+"\n")
        file.close()
    if failures>0:
        print("FAIL G13 V25 TACTICAL ZOOM: ",failures," ",JSON.stringify(result))
        quit(1)
        return
    print("PASS G13 V25 TACTICAL ZOOM: 17 native renders, eight factions, ",
        "seven animations, same draw node count, honest 3-zoom comparison, ",
        "unchanged V24 hero, 0 new mesh nodes, no Android FPS claims")
    quit(0)
