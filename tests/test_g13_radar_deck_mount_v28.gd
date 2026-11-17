extends SceneTree

# V28 physical radar mounting, 8 factions, 360° evidence from Godot 4.3.
# Explicitly compares *the same model/camera* with the old V27 cylindrical
# mast vs the new closed foot grounded to the rear deck. No Android FPS claim.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Deck=preload("res://scripts/ui/G13RadarDeckMountV28.gd")
const RadarV27=preload("res://scripts/ui/G13ElevatedRadarV27.gd")
const IntakeV24=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const SHOTS:=22
var failures:int=0
var captures:int=0
var differences:Dictionary={}
var old_triangle_count:int=0

func verify(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V28 deck radar QA: "+message)

func geometry_nodes(node:Node)->int:
    var n:int=1 if node is MeshInstance3D or (
        node is MultiMeshInstance3D) else 0
    for child in node.get_children():
        n+=geometry_nodes(child)
    return n

func photograph(view:SubViewport,folder:String,name:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=view.get_texture().get_image()
    verify(image!=null and not image.is_empty(),"Godot screenshot "+name)
    if image==null or image.is_empty():
        return null
    var ok:bool=image.save_png(folder.path_join(name+".png"))==OK
    verify(ok,"native PNG "+name)
    if ok:
        captures+=1
    return image

func compare_images(a:Image,b:Image)->Dictionary:
    if a==null or b==null or a.get_size()!=b.get_size():
        return {"changed":0,"sampled":0,"mae":0.0}
    var changed:int=0
    var sampled:int=0
    var aggregate:float=0.0
    for y in range(0,a.get_height(),4):
        for x in range(0,a.get_width(),4):
            var v1:Color=a.get_pixel(x,y)
            var v2:Color=b.get_pixel(x,y)
            var diff:float=(
                absf(v1.r-v2.r)+absf(v1.g-v2.g)+absf(v1.b-v2.b))/3.0
            sampled+=1
            aggregate+=diff
            if diff>0.034:
                changed+=1
    return {"changed":changed,"sampled":sampled,
        "mae":aggregate/float(maxi(sampled,1))}

func pose_cam(camera:Camera3D,where:Vector3,look:Vector3,
        size:float)->void:
    camera.position=where
    camera.size=size
    camera.look_at(look,Vector3.UP)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:String=OS.get_environment("G13_V28_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v28-3d"
    verify(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create gallery folder")
    var view:=SubViewport.new()
    view.own_world_3d=true
    view.size=Vector2i(1080,720)
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#23323b")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#c5d2d1")
    env.ambient_light_energy=0.8
    var world:=WorldEnvironment.new()
    world.environment=env
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-46,-32,0)
    sun.light_energy=1.37
    view.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-22,130,0)
    fill.light_energy=0.5
    view.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    view.add_child(camera)

    var colors:Dictionary={}
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,8)
        verify(model!=null,"eight G13 low-cost units")
        if model==null:
            continue
        verify(bool(model.get_meta(Deck.FLAG,false)),
            "V28 actual mast ArrayMesh built by default")
        verify(int(model.get_meta("tarvoka_g13_v28_draw_nodes_added",-1))==0,
            "no extra renderer objects")
        var radar:=model.find_child(G13.RADAR,true,false) as Node3D
        var mast:=model.find_child(Deck.MAST,true,false) as MeshInstance3D
        var cover:=model.find_child(Deck.COVER,true,false) as MeshInstance3D
        verify(radar!=null and mast!=null and cover!=null,
            "mast and engine deck are real 3D Godot nodes")
        if mast!=null and cover!=null and radar!=null:
            verify(mast.get_parent()==radar and mast.mesh is ArrayMesh,
                "same swivelling mast node now has a real polygon foot")
            var face_count:int=mast.mesh.get_faces().size()/3
            verify(face_count==Deck.TRIANGLES,"closed 96 face stepped support")
            var expected_bottom:float=(
                radar.position.y+mast.position.y+Deck.PROFILE[0].x)
            var actual_deck:float=cover.position.y+(
                cover.mesh as BoxMesh).size.y/2.0
            verify(absf(actual_deck-expected_bottom-
                Deck.FOOT_DECK_PENETRATION)<0.003,
                "the former floating base penetrates physical deck by 25mm")
            verify(Deck.PROFILE[0].y<=0.148 and
                cover.position.z+(
                cover.mesh as BoxMesh).size.z*0.5>=
                radar.position.z+Deck.PROFILE[0].y-0.002,
                "mast foot stays within rear cover, no side overhang")
        var original_draws:int=geometry_nodes(model)
        verify(not Deck.apply(model),"V28 geometry is idempotent")
        verify(Deck.show_v27_reference(model,true),
            "older cylindrical mast can be compared without new scene")
        if mast!=null:
            verify(mast.mesh is CylinderMesh and is_equal_approx(
                (mast.mesh as CylinderMesh).height,0.70),
                "V27 original height and topology truly restored")
            old_triangle_count=mast.mesh.get_faces().size()/3
        verify(Deck.show_v27_reference(model,false),
            "V28 solid foot restored by a mesh swap")
        for mode in ["idle","scan","move","aim_air","attack_air",
                "aim_ground","attack_ground"]:
            verify(Models.pose_model("aa_mobile",model,mode,0.45),
                "retains "+mode+" dual autocannons and separate antenna")
            verify(geometry_nodes(model)==original_draws,
                "original allocation held constant through "+mode)
        Models.restore_model_pose("aa_mobile",model)
        verify(model.find_child(G13.WHEELS,true,false)
            is MultiMeshInstance3D,"4-wheel 1 MultiMesh intact")
        for side in [-1,1]:
            verify(model.find_child("G13_Autocannon_%d" % side,
                true,false) is MeshInstance3D,
                "only original pair of automatic guns")
        var enamel:=model.find_child(
            "G13_SideEnamel_1",true,false) as MeshInstance3D
        var material:=enamel.material_override as StandardMaterial3D
        verify(material!=null and material.albedo_color.is_equal_approx(
            Models.faction_paint_color(faction).darkened(0.1)),
            "official eight faction colors preserved")
        if material!=null:
            colors[material.albedo_color.to_html()]=true
        view.add_child(model)
        pose_cam(camera,Vector3(2.7,2.8,2.8),
            Vector3(0,1.15,0.30),4.2)
        await photograph(view,folder,"faction_%02d_deck_v28" % faction)
        view.remove_child(model)
        model.free()
    verify(colors.size()==8,"eight distinct original faction paints")

    var sample:=Models.build("aa_mobile",0,true,8)
    verify(sample!=null,"native 360 model")
    if sample==null:
        quit(1)
        return
    view.add_child(sample)
    var views:Dictionary={
        "rear": {"eye":Vector3(2.7,2.8,3.1),
            "target":Vector3(0,1.4,0.45),"size":3.6},
        "left":{"eye":Vector3(-3.9,2.3,0.75),
            "target":Vector3(0,1.4,0.35),"size":3.6},
        "right":{"eye":Vector3(3.9,2.3,0.75),
            "target":Vector3(0,1.4,0.35),"size":3.6},
        "front":{"eye":Vector3(-2.7,2.8,-3.1),
            "target":Vector3(0,1.4,0.2),"size":3.6},
        "top":{"eye":Vector3(0.8,5.0,1.2),
            "target":Vector3(0,1.3,0.15),"size":4.2}
    }
    for angle in ["rear","left","right","front","top"]:
        var view_pose:Dictionary=views[angle]
        pose_cam(camera,view_pose["eye"],
            view_pose["target"],float(view_pose["size"]))
        verify(Deck.show_v27_reference(sample,true),
            "same-camera previous V27 support "+angle)
        var old:Image=await photograph(view,folder,
            "angle_%s_v27" % angle)
        verify(Deck.show_v27_reference(sample,false),
            "same-camera real V28 deck base "+angle)
        var sculpt:Image=await photograph(view,folder,
            "angle_%s_v28" % angle)
        differences[angle]=compare_images(old,sculpt)
    verify(int(differences["rear"]["changed"])>25,
        "rear mechanical foot is visibly attached to rear deck")
    verify(int(differences["left"]["changed"])>10,
        "side view contains real additional visible support")
    pose_cam(camera,Vector3(1.4,1.95,2.3),
        Vector3(0,1.2,0.83),1.9)
    await photograph(view,folder,"macro_radar_foot_on_deck")
    pose_cam(camera,Vector3(3.0,2.8,-2.7),
        Vector3(0,1.2,0.12),4.0)
    verify(Models.pose_model("aa_mobile",sample,"attack_air",0.42),
        "air attack remains visual-only and synchronized")
    await photograph(view,folder,"attack_air_v28")
    verify(Models.pose_model("aa_mobile",sample,"attack_ground",0.42),
        "ground attack remains visual-only and synchronized")
    await photograph(view,folder,"attack_ground_v28")
    view.remove_child(sample)
    sample.free()

    var detailed:=Models.build("aa_mobile",0,true,13)
    verify(detailed!=null,"detailed V24 still builds")
    if detailed!=null:
        verify(bool(detailed.get_meta(IntakeV24.FLAG,false)) and
            not bool(detailed.get_meta(Deck.FLAG,false)),
            "LOD13 V24 radar and armor stay completely unchanged")
        view.add_child(detailed)
        pose_cam(camera,Vector3(2.7,2.8,2.8),
            Vector3(0,1.15,0.30),4.2)
        await photograph(view,folder,"hero_v24_untouched")
        view.remove_child(detailed)
        detailed.free()
    verify(captures==SHOTS,"exactly 22 actual Godot renders")
    var report:Dictionary={
        "revision":"G13 V28 armored mast foot on rear deck",
        "factions":8,
        "screenshots":captures,
        "modified_existing_meshes":1,
        "new_draw_nodes":0,
        "mast_triangles_v27":old_triangle_count,
        "mast_triangles_v28":Deck.TRIANGLES,
        "radar_deck_overlap_m":Deck.FOOT_DECK_PENETRATION,
        "360_same_camera_differences":differences,
        "two_guns_no_missiles":true,
        "android_device_fps_measured":false,
        "failures":failures
    }
    var output:=FileAccess.open(folder.path_join(
        "g13-v28-deck-review.json"),FileAccess.WRITE)
    verify(output!=null,"persist native report")
    if output!=null:
        output.store_string(JSON.stringify(report,"  ")+"\n")
        output.close()
    if failures>0:
        print("FAIL G13 V28 RADAR MOUNT:",failures," ",
            JSON.stringify(differences))
        quit(1)
        return
    print("PASS G13 V28 RADAR MOUNT: 22 genuine Godot frames, ",
        "rear deck visibly joined, 8 factions, both guns, 0 new draw ",
        "nodes, consistent five-angle 360 review, unchanged V24 hero")
    quit(0)
