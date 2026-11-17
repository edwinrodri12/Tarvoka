extends SceneTree

# G13 V29 - genuine native Godot visual review of rear-folding search radar.
# Native 360° gun envelopes at both ground/air pitch, 8 faction renderings,
# real V28->V29 same-camera pictures. 3D ART, NOT gameplay nor Android FPS.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Fold=preload("res://scripts/ui/G13FoldingRadarV29.gd")
const Deck=preload("res://scripts/ui/G13RadarDeckMountV28.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V24=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const TOTAL:=24
var fails:int=0
var pngs:int=0
var worst_mast:float=100.0
var worst_dish:float=100.0
var max_foot_deviation:float=0.0
var snapshots:Dictionary={}

func require(ok:bool,description:String)->void:
    if not ok:
        fails+=1
        push_error("G13 V29 radar fold: "+description)

func draw_count(node:Node)->int:
    var result:int=1 if node is MeshInstance3D or (
        node is MultiMeshInstance3D) else 0
    for child in node.get_children():
        result+=draw_count(child)
    return result

func screenshot(vp:SubViewport,folder:String,name:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var im:Image=vp.get_texture().get_image()
    require(im!=null and not im.is_empty(),"render "+name)
    if im==null or im.is_empty():
        return null
    var result:bool=im.save_png(folder.path_join(name+".png"))==OK
    require(result,"save "+name)
    if result:
        pngs+=1
    return im

func image_diff(a:Image,b:Image)->int:
    if a==null or b==null or a.get_size()!=b.get_size():
        return 0
    var changed:int=0
    for y in range(0,a.get_height(),4):
        for x in range(0,a.get_width(),4):
            var ca:Color=a.get_pixel(x,y)
            var cb:Color=b.get_pixel(x,y)
            if (absf(ca.r-cb.r)+absf(ca.g-cb.g)+
                    absf(ca.b-cb.b))/3.0>0.035:
                changed+=1
    return changed

func distance_point_segment(point:Vector3,a:Vector3,b:Vector3)->float:
    var direction:Vector3=b-a
    var t:float=clampf((point-a).dot(direction)/
        maxf(direction.length_squared(),0.000001),0.0,1.0)
    return point.distance_to(a+t*direction)

func weapon_clearances(model:Node3D)->Vector2:
    var mast:=model.find_child(
        Fold.MAST,true,false) as MeshInstance3D
    var dish:=model.find_child(
        Fold.DISH,true,false) as MeshInstance3D
    var gun_pivot:=model.find_child(
        "G13_ElevacionCanones",true,false) as Node3D
    var foot:Vector3=mast.to_global(
        Vector3(0,Deck.PROFILE[0].x,0))
    var top:Vector3=mast.to_global(
        Vector3(0,Deck.PROFILE[Deck.PROFILE.size()-1].x,0))
    var min_mast:float=100.0
    var min_dish:float=100.0
    for side in [-1,1]:
        for weapon in ["G13_Autocannon_%d" % side,
                "G13_RealMuzzle_%d" % side]:
            var part:=gun_pivot.find_child(
                weapon,false,false) as MeshInstance3D
            if part==null or not part.mesh is CylinderMesh:
                continue
            var tube:=part.mesh as CylinderMesh
            var radius:float=maxf(
                tube.top_radius,tube.bottom_radius)
            # The native cylinder has axis local Y after the +90 deg
            # rotation. Sample every 2.8..5cm across real 3D length.
            for step in range(41):
                var t:float=float(step)/40.0
                var location:Vector3=part.to_global(
                    Vector3(0,(t-0.5)*tube.height,0))
                min_mast=minf(min_mast,
                    distance_point_segment(location,foot,top)
                    -radius-Deck.PROFILE[0].y)
                var local:Vector3=dish.to_local(location)
                var dish_mesh:=dish.mesh as CylinderMesh
                var outside_radius:float=maxf(0.0,
                    Vector2(local.x,local.z).length()-
                    dish_mesh.top_radius)
                var outside_thickness:float=maxf(0.0,
                    absf(local.y)-dish_mesh.height*0.5)
                min_dish=minf(min_dish,
                    Vector2(outside_radius,outside_thickness).length()
                    -radius)
    return Vector2(min_mast,min_dish)

func camera(camera3d:Camera3D,where:Vector3,target:Vector3,
        size:float)->void:
    camera3d.position=where
    camera3d.size=size
    camera3d.look_at(target,Vector3.UP)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:String=OS.get_environment("G13_V29_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v29-native"
    require(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "screenshot output")
    var vp:=SubViewport.new()
    vp.own_world_3d=true
    vp.size=Vector2i(1080,720)
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#283a43")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#cdd6d4")
    environment.ambient_light_energy=0.74
    var world:=WorldEnvironment.new()
    world.environment=environment
    vp.add_child(world)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-42,-28,0)
    key.light_energy=1.34
    vp.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-22,134,0)
    fill.light_energy=0.44
    vp.add_child(fill)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.current=true
    vp.add_child(cam)

    var colors:Dictionary={}
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,8)
        require(model!=null,"LOD8 built for faction "+str(faction))
        if model==null:
            continue
        require(bool(model.get_meta(Fold.FLAG,false)) and
            bool(model.get_meta(Deck.FLAG,false)),
            "V28 deck and V29 fold coexist")
        require(int(model.get_meta(
            "tarvoka_g13_v29_new_draw_nodes",-1))==0,
            "no new draw nodes in mobile fold")
        var original:int=draw_count(model)
        require(not Fold.install(model),"cannot duplicate radar actuator")
        require(Models.pose_model("aa_mobile",model,"scan",0.60),
            "radar normal scan")
        require(is_zero_approx(float(model.get_meta(
            "tarvoka_g13_v29_fold_degrees",-1.0))),
            "scan keeps 3D mast upright")
        require(Models.pose_model("aa_mobile",model,
            "attack_ground",0.42,Vector2i(0,1)),
            "dual guns point rear at low ground elevation")
        var turret:=model.find_child(
            Fold.TURRET,true,false) as Node3D
        var radar:=model.find_child(Fold.RADAR,true,false) as Node3D
        var mast:=model.find_child(Fold.MAST,true,false) as MeshInstance3D
        require(absf(absf(turret.rotation_degrees.y)-180.0)<0.01,
            "true 180 degree rearward cannon swivel")
        require(absf(radar.rotation_degrees.x-Fold.MAX_FOLD_DEG)<0.01,
            "mast inclines from deck while guns aim backward")
        var foot:Vector3=mast.to_global(
            Vector3(0,Deck.PROFILE[0].x,0))
        require(absf(foot.y-1.095)<0.001 and
            absf(foot.z-Deck.RADAR_DECK_Z)<0.001,
            "folding joint is grounded to physical deck")
        require(draw_count(model)==original,
            "all seven animation geometries still allocated identically")
        require(Models.pose_model("aa_mobile",model,
            "attack_air",0.42,Vector2i(0,1)),
            "dual guns also fire rearward with air elevation")
        require(is_equal_approx(radar.rotation_degrees.x,
            Fold.MAX_FOLD_DEG),"same robust AA rear fold")
        var stripe:=model.find_child(
            "G13_SideEnamel_1",true,false) as MeshInstance3D
        var mat:=stripe.material_override as StandardMaterial3D
        require(mat!=null and mat.albedo_color.is_equal_approx(
            Models.faction_paint_color(faction).darkened(0.10)),
            "official faction paint untouched")
        if mat!=null:
            colors[mat.albedo_color.to_html()]=true
        vp.add_child(model)
        camera(cam,Vector3(3.2,2.9,3.4),
            Vector3(0,1.33,0.52),4.1)
        await screenshot(vp,folder,"faction_%02d_rear_aa" % faction)
        vp.remove_child(model)
        model.free()
    require(colors.size()==8,"eight distinct faction paints")

    var subject:=Models.build("aa_mobile",0,true,8)
    require(subject!=null,"native radar sweep hero")
    if subject==null:
        quit(1)
        return
    vp.add_child(subject)
    var original_count:int=draw_count(subject)
    for mode in ["aim_ground","aim_air"]:
        for angle in range(0,360,5):
            var rad:float=deg_to_rad(float(angle))
            var heading:=Vector2i(
                roundi(1000.0*sin(rad)),-roundi(1000.0*cos(rad)))
            require(Models.pose_model("aa_mobile",subject,
                mode,0.43,heading),
                "native two-domain sweep at yaw "+str(angle))
            var clear:Vector2=weapon_clearances(subject)
            worst_mast=minf(worst_mast,clear.x)
            worst_dish=minf(worst_dish,clear.y)
            require(draw_count(subject)==original_count,
                "zero new draw nodes during true 360 gun sweep")
            var mast:=subject.find_child(
                Fold.MAST,true,false) as MeshInstance3D
            var foot:Vector3=mast.to_global(
                Vector3(0,Deck.PROFILE[0].x,0))
            max_foot_deviation=maxf(max_foot_deviation,
                foot.distance_to(Vector3(0,1.095,Deck.RADAR_DECK_Z)))
    require(worst_mast>0.0,
        "real gun cylinder envelopes never hit rotating mast")
    require(worst_dish>0.0,
        "real gun cylinder envelopes never strike radar disc")
    require(max_foot_deviation<0.022,
        "foot stays planted within 22mm during full visual transition")

    for mode in ["attack_ground","attack_air"]:
        for heading in [Vector2i(0,1),Vector2i(1,1),
                Vector2i(-1,1),Vector2i(0,-1)]:
            require(Models.pose_model("aa_mobile",subject,
                mode,0.48,heading),"original dual-domain attack")
            camera(cam,Vector3(3.3,2.7,3.4),
                Vector3(0,1.33,0.44),4.1)
            await screenshot(vp,folder,"attack_%s_heading_%d_%d" %
                [mode,heading.x,heading.y])

    # Identical scene and camera; fold and deploy the very same Godot model.
    camera(cam,Vector3(2.8,2.6,3.1),
        Vector3(0,1.40,0.65),3.7)
    Models.pose_model("aa_mobile",subject,"aim_ground",0.42,
        Vector2i(0,1))
    var folded:Image=await screenshot(
        vp,folder,"comparison_rear_v29_folded")
    require(Fold.set_fold(subject,0.0),"manual visual comparison")
    var upright:Image=await screenshot(
        vp,folder,"comparison_rear_v28_upright")
    snapshots["same_camera_changed_pixels"]=image_diff(folded,upright)
    require(int(snapshots["same_camera_changed_pixels"])>100,
        "mechanical 3D retraction visible in studio at equal camera")
    require(Fold.set_fold(subject,0.5),
        "fold actuator supports physically smooth midpoint")
    await screenshot(vp,folder,"radar_hinge_midway")
    camera(cam,Vector3(0.95,2.22,2.65),
        Vector3(0,1.10,1.15),2.0)
    Fold.set_fold(subject,1.0)
    await screenshot(vp,folder,"radar_foot_hinge_closeup")
    for view_spec in [
            {"name":"folded_rear_side","eye":Vector3(-4.2,2.5,1.8),
                "target":Vector3(0,1.35,0.70),"size":3.8},
            {"name":"folded_rear_top","eye":Vector3(1.0,5.4,2.5),
                "target":Vector3(0,1.25,0.75),"size":4.4},
            {"name":"folded_rear_low","eye":Vector3(0.6,1.9,4.3),
                "target":Vector3(0,1.40,0.80),"size":3.8}
        ]:
        camera(cam,view_spec["eye"],view_spec["target"],
            float(view_spec["size"]))
        await screenshot(vp,folder,view_spec["name"])
    vp.remove_child(subject)
    subject.free()

    var detailed:=Models.build("aa_mobile",0,true,13)
    require(detailed!=null,"hero still built")
    if detailed!=null:
        require(bool(detailed.get_meta(V24.FLAG,false)) and
            not bool(detailed.get_meta(Fold.FLAG,false)),
            "V24 detailed hero radar unchanged")
        vp.add_child(detailed)
        camera(cam,Vector3(3.2,2.9,3.4),
            Vector3(0,1.33,0.52),4.1)
        await screenshot(vp,folder,"v24_detailed_unchanged")
        vp.remove_child(detailed)
        detailed.free()
    require(pngs==TOTAL,"24 real native Godot 3D PNGs")
    var report:Dictionary={
        "revision":"G13 V29 real folding radar with rear twin-gun sweep",
        "factions":8,
        "native_pngs":pngs,
        "new_draw_nodes":0,
        "sweep_heading_increment_degrees":5,
        "gun_domains_tested":2,
        "minimum_gun_to_mast_gap_m":worst_mast,
        "minimum_gun_to_dish_gap_m":worst_dish,
        "maximum_hinge_foot_deviation_m":max_foot_deviation,
        "same_camera_comparison":snapshots,
        "android_phone_fps_measured":false,
        "gameplay_integrated":false,
        "failures":fails
    }
    var file:=FileAccess.open(folder.path_join(
        "g13-v29-rear-gun-clearance.json"),FileAccess.WRITE)
    require(file!=null,"write sweep report")
    if file!=null:
        file.store_string(JSON.stringify(report,"  ")+"\n")
        file.close()
    if fails>0:
        print("FAIL G13 V29 FOLDING RADAR: ",fails,
            " mast=",worst_mast," dish=",worst_dish)
        quit(1)
        return
    print("PASS G13 V29 FOLDING RADAR: 24 Godot 3D frames, 8 factions, ",
        "full rear AA/ground 360 sweep, planted foot and no added nodes")
    quit(0)
