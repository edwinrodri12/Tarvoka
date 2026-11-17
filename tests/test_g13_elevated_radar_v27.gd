extends SceneTree

# G13 V27 source-backed 3D art dossier. Native Godot Compatibility renderer,
# 8 faction models, same-camera V26/V27 zoom pairs, ground/air poses.
# This is NOT an Android-device FPS benchmark or a gameplay integration.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const RadarV27=preload("res://scripts/ui/G13ElevatedRadarV27.gd")
const DeckV28=preload("res://scripts/ui/G13RadarDeckMountV28.gd")
const ArmorV26=preload("res://scripts/ui/G13TacticalArmorV26.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const IntakeV24=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const PNG_COUNT:=19
var failures:int=0
var captured:int=0
var comparison:Dictionary={}

func verify(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V27 radar profile: "+reason)

func draw_nodes(parent:Node)->int:
    var total:int=1 if parent is MeshInstance3D or (
        parent is MultiMeshInstance3D) else 0
    for child in parent.get_children():
        total+=draw_nodes(child)
    return total

func _shot(v:SubViewport,folder:String,label:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=v.get_texture().get_image()
    verify(image!=null and not image.is_empty(),"native render "+label)
    if image==null or image.is_empty():
        return null
    var ok:bool=image.save_png(folder.path_join(label+".png"))==OK
    verify(ok,"PNG saved "+label)
    if ok:
        captured+=1
    return image

func _delta(old:Image,new:Image)->Dictionary:
    if old==null or new==null or old.get_size()!=new.get_size():
        return {"changed":0,"mean":0.0,"sampled":0}
    var changed:int=0
    var total:float=0.0
    var sampled:int=0
    for y in range(0,old.get_height(),4):
        for x in range(0,old.get_width(),4):
            var a:Color=old.get_pixel(x,y)
            var b:Color=new.get_pixel(x,y)
            var difference:float=(
                absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
            total+=difference
            sampled+=1
            if difference>0.035:
                changed+=1
    return {
        "changed":changed,
        "mean":total/float(maxi(1,sampled)),
        "sampled":sampled
    }

func _view(cam:Camera3D,where:Vector3,target:Vector3,size:float)->void:
    cam.position=where
    cam.size=size
    cam.look_at(target,Vector3.UP)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:String=OS.get_environment("G13_V27_GALLERY")
    if folder.is_empty():
        folder="/tmp/g13-v27-3d"
    verify(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create screenshot folder")
    var vp:=SubViewport.new()
    vp.own_world_3d=true
    vp.size=Vector2i(1080,720)
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var ambient:=Environment.new()
    ambient.background_mode=Environment.BG_COLOR
    ambient.background_color=Color("#263843")
    ambient.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    ambient.ambient_light_color=Color("#c2d4da")
    ambient.ambient_light_energy=0.77
    var world:=WorldEnvironment.new()
    world.environment=ambient
    vp.add_child(world)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-47,-30,0)
    key.light_energy=1.30
    vp.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,130,0)
    fill.light_energy=0.38
    vp.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    vp.add_child(camera)

    var tints:Dictionary={}
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,8)
        verify(model!=null,"LOD8 exists for faction "+str(faction))
        if model==null:
            continue
        verify(DeckV28.show_v27_reference(model,true),
            "V27 historical test restores native tall cylinder before inspection")
        verify(bool(model.get_meta(RadarV27.FLAG,false)) and
            bool(model.get_meta(ArmorV26.FLAG,false)),
            "V26 polygon armor and V27 real radar coexist")
        verify(int(model.get_meta(
            "tarvoka_g13_v27_added_draw_nodes",-1))==0 and
            int(model.get_meta(
                "tarvoka_g13_v27_added_triangles",-1))==0,
            "no new 3D nodes and no new triangles")
        var initial_count:int=draw_nodes(model)
        var mast:=model.find_child(
            RadarV27.MAST,true,false) as MeshInstance3D
        var dish:=model.find_child(
            RadarV27.DISH,true,false) as MeshInstance3D
        var receiver:=model.find_child(
            RadarV27.RECEIVER,true,false) as MeshInstance3D
        var radar:=model.find_child(G13.RADAR,true,false) as Node3D
        verify(mast!=null and dish!=null and receiver!=null and radar!=null,
            "reused original 3D search mast, dish, receiver, azimuth")
        if mast!=null and dish!=null and receiver!=null:
            verify(mast.get_parent()==radar and
                dish.get_parent()==radar and
                receiver.get_parent()==radar,
                "every radar part follows independent radar swivel")
            verify(is_equal_approx(
                (mast.mesh as CylinderMesh).height,RadarV27.MAST_HEIGHT),
                "actual taller polygon mast, not an icon")
            verify(is_equal_approx(
                (mast.mesh as CylinderMesh).bottom_radius,
                RadarV27.MAST_BASE_RADIUS) and
                is_equal_approx(
                (mast.mesh as CylinderMesh).top_radius,
                RadarV27.MAST_TOP_RADIUS),
                "true gently tapered 3D radar support")
            verify(is_equal_approx(
                (dish.mesh as CylinderMesh).top_radius,
                RadarV27.DISH_RADIUS),
                "search dish is actually wider at distance")
            verify(mast.position.is_equal_approx(
                RadarV27.MAST_CENTER) and
                dish.position.is_equal_approx(
                RadarV27.DISH_CENTER) and
                receiver.position.is_equal_approx(
                RadarV27.RECEIVER_CENTER),
                "elevated dish/receiver stay attached to original mast")
        verify(not RadarV27.apply(model),
            "idempotent: no second radar tower")
        verify(RadarV27.show_v26_reference(model,true),
            "authentic previous radar geometry is recoverable")
        if mast!=null and dish!=null:
            verify(is_equal_approx(
                (mast.mesh as CylinderMesh).height,0.47) and
                is_equal_approx(
                (dish.mesh as CylinderMesh).top_radius,0.338),
                "reference uses actual original V26 mesh resources")
        verify(RadarV27.show_v26_reference(model,false),
            "new V27 original parts restored without mesh additions")
        for animation in ["idle","move","scan","aim_air","attack_air",
                "aim_ground","attack_ground"]:
            verify(Models.pose_model("aa_mobile",model,animation,0.41),
                animation+" preserves original 4x4 and gun rigs")
            verify(draw_nodes(model)==initial_count,
                "no new draw nodes appear during animations")
        Models.restore_model_pose("aa_mobile",model)
        for side in [-1,1]:
            verify(model.find_child("G13_Autocannon_%d" % side,
                true,false) is MeshInstance3D,
                "exact twin automatic guns; no missile system")
        var stripe:=model.find_child("G13_SideEnamel_1",
            true,false) as MeshInstance3D
        var paint:=stripe.material_override as StandardMaterial3D
        verify(paint!=null and paint.albedo_color.is_equal_approx(
            Models.faction_paint_color(faction).darkened(0.10)),
            "eight original faction colors untouched")
        if paint!=null:
            tints[paint.albedo_color.to_html()]=true
        vp.add_child(model)
        _view(camera,Vector3(3.5,3.0,-3.6),Vector3(0,1.1,0),4.6)
        await _shot(vp,folder,"faction_%02d_v27" % faction)
        vp.remove_child(model)
        model.free()
    verify(tints.size()==8,"all eight distinct faction liveries")

    var hero:=Models.build("aa_mobile",0,true,8)
    verify(hero!=null,"same-camera V26 vs V27 tactical model")
    if hero==null:
        quit(1)
        return
    verify(DeckV28.show_v27_reference(hero,true),
        "historical V26/V27 images must not include later V28 deck foot")
    vp.add_child(hero)
    for level in ["close","medium","far"]:
        var scale:float=({"close":4.6,"medium":8.0,"far":14.0})[level]
        _view(camera,Vector3(3.5,3.0,-3.6),
            Vector3(0,1.1,0),scale)
        verify(RadarV27.show_v26_reference(hero,true),
            "same-camera authentic V26 radar "+level)
        var old:Image=await _shot(vp,folder,
            "zoom_%s_v26" % level)
        verify(RadarV27.show_v26_reference(hero,false),
            "same-camera new V27 radar "+level)
        var new:Image=await _shot(vp,folder,
            "zoom_%s_v27" % level)
        comparison[level]=_delta(old,new)
    verify(int(comparison["close"]["changed"])>40,
        "raised mast and dish visibly change close silhouette")
    verify(int(comparison["far"]["changed"])>10,
        "V27 physically discernible even at far tactical zoom")
    _view(camera,Vector3(3.0,2.8,1.6),
        Vector3(0,1.96,0.60),2.4)
    await _shot(vp,folder,"rear_radar_mast_macro")
    _view(camera,Vector3(-2.5,2.5,-1.0),
        Vector3(0,1.90,0.62),2.3)
    await _shot(vp,folder,"front_left_radar_macro")
    _view(camera,Vector3(3.5,3.0,-3.6),
        Vector3(0,1.1,0),4.6)
    verify(Models.pose_model("aa_mobile",hero,"attack_air",0.42),
        "dual guns attack air with tall radar independent")
    await _shot(vp,folder,"attack_air_v27")
    verify(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
        "dual guns attack ground with tall radar independent")
    await _shot(vp,folder,"attack_ground_v27")
    vp.remove_child(hero)
    hero.free()
    var full:=Models.build("aa_mobile",0,true,13)
    verify(full!=null,"full V24 details preserved")
    if full!=null:
        verify(bool(full.get_meta(IntakeV24.FLAG,false)) and
            not bool(full.get_meta(RadarV27.FLAG,false)),
            "approved LOD13 art is untouched by mobile radar variant")
        vp.add_child(full)
        _view(camera,Vector3(3.5,3.0,-3.6),
            Vector3(0,1.1,0),4.6)
        await _shot(vp,folder,"full_v24_studio_unchanged")
        vp.remove_child(full)
        full.free()

    verify(captured==PNG_COUNT,"exactly 19 real 3D renders")
    var report:Dictionary={
        "revision":"G13 V27 elevated search radar tactical silhouette",
        "factions":8,
        "native_godot_pngs":captured,
        "same_camera_comparison":comparison,
        "modified_original_3d_nodes":3,
        "new_draw_nodes":0,
        "extra_triangles":0,
        "weapons":"two original autocannons, no missiles",
        "android_fps_measured":false,
        "failed_checks":failures
    }
    var summary:=FileAccess.open(folder.path_join(
        "g13-v27-visual-report.json"),FileAccess.WRITE)
    verify(summary!=null,"save auditable 3D report")
    if summary!=null:
        summary.store_string(JSON.stringify(report,"  ")+"\n")
        summary.close()
    if failures>0:
        print("FAIL G13 V27 3D SEARCH RADAR: ",failures," ",
            JSON.stringify(comparison))
        quit(1)
        return
    print("PASS G13 V27 3D SEARCH RADAR: 19 real Godot views, 8 factions, ",
        "3 original radar nodes re-sculpted, no additional triangles or ",
        "draw objects, identical V26/V27 camera zooms, dual gun poses")
    quit(0)
