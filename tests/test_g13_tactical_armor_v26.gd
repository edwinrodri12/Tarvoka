extends SceneTree

# G13 V26: native Godot sculpture verification and same-view visual dossier.
# Three existing mobile LOD8 meshes change 12->48 faces each. Zero new
# render nodes; full detailed V24 mesh and all weapon poses remain intact.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V25=preload("res://scripts/ui/G13TacticalSilhouetteV25.gd")
const V26=preload("res://scripts/ui/G13TacticalArmorV26.gd")
const RadarV27=preload("res://scripts/ui/G13ElevatedRadarV27.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V24=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const TOTAL:=19
var failures:int=0
var captures:int=0
var comparisons:Dictionary={}

func verify(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V26 native armor QA: "+message)

func allocated_draw_nodes(node:Node)->int:
    # Count ALLOCATED MeshInstance/MultiMesh nodes, not visible instances:
    # a legitimate firing pose briefly reveals muzzle-flash and smoke
    # objects that already exist in the V1 rig; no new nodes are created.
    var count:int=1 if node is MeshInstance3D or (
        node is MultiMeshInstance3D) else 0
    for child in node.get_children():
        count+=allocated_draw_nodes(child)
    return count

func photo(view:SubViewport,folder:String,name:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var png:Image=view.get_texture().get_image()
    verify(png!=null and not png.is_empty(),"render native "+name)
    if png==null or png.is_empty():
        return null
    var ok:bool=png.save_png(folder.path_join(name+".png"))==OK
    verify(ok,"write native PNG "+name)
    if ok:
        captures+=1
    return png

func difference(a:Image,b:Image)->Dictionary:
    if a==null or b==null or a.get_size()!=b.get_size():
        return {"pixels_changed":0,"sample_count":0,"mean_delta":0.0}
    var changed:int=0
    var samples:int=0
    var total:float=0.0
    for y in range(0,a.get_height(),4):
        for x in range(0,a.get_width(),4):
            var c0:Color=a.get_pixel(x,y)
            var c1:Color=b.get_pixel(x,y)
            var delta:float=(
                absf(c1.r-c0.r)+absf(c1.g-c0.g)+absf(c1.b-c0.b))/3.0
            if delta>0.033:
                changed+=1
            total+=delta
            samples+=1
    return {"pixels_changed":changed,
        "sample_count":samples,
        "mean_delta":total/float(maxi(samples,1))}

func camera_at(cam:Camera3D,position:Vector3,target:Vector3,
        ortho_size:float)->void:
    cam.position=position
    cam.size=ortho_size
    cam.look_at(target,Vector3.UP)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:String=OS.get_environment("G13_V26_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v26-native"
    verify(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create output gallery")
    var view:=SubViewport.new()
    view.size=Vector2i(1080,720)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#253641")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#c4d2dc")
    environment.ambient_light_energy=0.72
    var world:=WorldEnvironment.new()
    world.environment=environment
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-46,-31,0)
    sun.light_energy=1.39
    view.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,142,0)
    fill.light_energy=0.36
    view.add_child(fill)
    var floor:=MeshInstance3D.new()
    var ground:=PlaneMesh.new()
    ground.size=Vector2(8.0,8.0)
    floor.mesh=ground
    var ground_mat:=StandardMaterial3D.new()
    ground_mat.albedo_color=Color("#485951")
    floor.material_override=ground_mat
    view.add_child(floor)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.current=true
    view.add_child(cam)
    var faction_colors:Dictionary={}
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,8)
        verify(model!=null,"native G13 LOD8 for faction "+str(faction))
        if model==null:
            continue
        verify(RadarV27.show_v26_reference(model,true),
            "historic V26 faction captures have original V26 radar geometry")
        verify(bool(model.get_meta(V25.FLAG,false)) and
            bool(model.get_meta(V26.FLAG,false)),
            "both optical V25 and faceted V26 mobile finishes applied")
        verify(int(model.get_meta("tarvoka_g13_v26_new_draw_nodes",-1))==0,
            "no new MeshInstance3D draw nodes on Android")
        verify(int(model.get_meta("tarvoka_g13_v26_extra_triangles",-1))==
            V26.ADDED_TRIANGLES and V26.ADDED_TRIANGLES==108,
            "explicit small geometry cost: only 108 extra triangles")
        var before_nodes:int=allocated_draw_nodes(model)
        for entry in V26._shape_spec():
            var name:String=entry["name"]
            var mesh:=model.find_child(name,true,false) as MeshInstance3D
            verify(mesh!=null and mesh.mesh is ArrayMesh,
                "real faceted native ArrayMesh in "+name)
            if mesh!=null and mesh.mesh is ArrayMesh:
                var geometry:=mesh.mesh as ArrayMesh
                var vertex:Array=geometry.surface_get_arrays(0)
                var verts:PackedVector3Array=vertex[Mesh.ARRAY_VERTEX]
                verify(geometry.get_surface_count()==1 and verts.size()==144,
                    "closed chamfered 48-triangle sculpt, not a fake decal")
                var dims:AABB=geometry.get_aabb()
                var original:Vector3=entry["size"]
                verify(absf(dims.size.x-original.x)<0.10 and
                    absf(dims.size.y-original.y)<0.10 and
                    absf(dims.size.z-original.z)<0.10,
                    "facets retain original collision-free envelope")
                verify(mesh.position.is_equal_approx(entry["position"]),
                    "original 3D mount pivot stays unchanged")
        verify(not V26.apply(model),"cannot duplicate an installed sculpt")
        verify(allocated_draw_nodes(model)==before_nodes,
            "zero added visible nodes after reapply attempt")
        verify(V26.show_v25_reference(model,true),
            "reveal authentic previous V25 rectangular armor")
        for entry in V26._shape_spec():
            var ref:=model.find_child(str(entry["name"]),
                true,false) as MeshInstance3D
            verify(ref.mesh is BoxMesh,"V25 original mesh actually restored")
        verify(V26.show_v25_reference(model,false),
            "return exactly the newly sculpted V26 polygon armor")
        for pose in ["idle","move","scan","aim_air","attack_air",
                "aim_ground","attack_ground"]:
            verify(Models.pose_model("aa_mobile",model,pose,0.41),
                pose+" still moves original 4x4 radar/gun pivots")
            verify(allocated_draw_nodes(model)==before_nodes,
                "no new draw nodes during any pose")
        Models.restore_model_pose("aa_mobile",model)
        verify(model.find_child(G13.WHEELS,true,false)
            is MultiMeshInstance3D,"four tires still a single 3D batch")
        var tint:=model.find_child("G13_SideEnamel_1",
            true,false) as MeshInstance3D
        var mat:=tint.material_override as StandardMaterial3D
        verify(mat!=null and mat.albedo_color.is_equal_approx(
            Models.faction_paint_color(faction).darkened(0.10)),
            "faction paint identical to approved colors")
        if mat!=null:
            faction_colors[mat.albedo_color.to_html()]=true
        view.add_child(model)
        camera_at(cam,Vector3(3.4,2.8,-3.2),
            Vector3(0,1.07,0),4.25)
        await photo(view,folder,"g13_v26_faction_%02d" % faction)
        view.remove_child(model)
        model.free()
    verify(faction_colors.size()==8,"eight unique official paint identities")

    var subject:=Models.build("aa_mobile",0,true,8)
    verify(subject!=null,"V26 model for controlled camera comparison")
    if subject==null:
        quit(1)
        return
    verify(RadarV27.show_v26_reference(subject,true),
        "V25/V26 3D comparisons exclude later V27 radar raise")
    view.add_child(subject)
    for zoom in ["close","medium","far"]:
        var ortho:float=({"close":4.6,"medium":8.0,"far":14.0})[zoom]
        camera_at(cam,Vector3(3.4,2.8,-3.2),
            Vector3(0,1.07,0),ortho)
        verify(V26.show_v25_reference(subject,true),
            "V25 real geometry matched camera "+zoom)
        var before:Image=await photo(view,folder,
            "same_zoom_%s_v25" % zoom)
        verify(V26.show_v25_reference(subject,false),
            "V26 real geometry matched camera "+zoom)
        var after:Image=await photo(view,folder,
            "same_zoom_%s_v26" % zoom)
        var delta:Dictionary=difference(before,after)
        comparisons[zoom]=delta
        if zoom=="close":
            verify(int(delta["pixels_changed"])>40,
                "true V26 bevel improvement is visible at tactical scale")
        verify(float(delta["mean_delta"])<0.15,
            "same camera and paint: localized geometric edit")

    camera_at(cam,Vector3(0,1.50,-4.0),
        Vector3(0,1.15,0),3.7)
    await photo(view,folder,"g13_v26_front_armor_macro")
    camera_at(cam,Vector3(3.0,2.65,0.3),
        Vector3(0,1.60,0),3.45)
    await photo(view,folder,"g13_v26_turret_cheek_and_cradle")
    camera_at(cam,Vector3(3.4,2.8,-3.2),
        Vector3(0,1.07,0),4.25)
    verify(Models.pose_model("aa_mobile",subject,"attack_air",0.42),
        "dual cannon air fire without changing silhouette")
    await photo(view,folder,"g13_v26_attack_air")
    verify(Models.pose_model("aa_mobile",subject,"attack_ground",0.42),
        "dual cannon ground fire without changing silhouette")
    await photo(view,folder,"g13_v26_attack_ground")
    view.remove_child(subject)
    subject.free()

    var hero:=Models.build("aa_mobile",0,true,13)
    verify(hero!=null,"preserve approved full LOD13 V24 hero")
    if hero!=null:
        verify(bool(hero.get_meta(V24.FLAG,false)) and
            not bool(hero.get_meta(V26.FLAG,false)),
            "V24 full-detail geometry never overwritten by tactical V26")
        view.add_child(hero)
        camera_at(cam,Vector3(3.4,2.8,-3.2),
            Vector3(0,1.07,0),4.25)
        await photo(view,folder,"g13_v24_hero_untouched")
        view.remove_child(hero)
        hero.free()

    verify(captures==TOTAL,"19 authentic Godot renders saved")
    var report:Dictionary={
        "art_revision":"G13 V26 tactical armor",
        "screenshot_count":captures,
        "factions":8,
        "modified_existing_meshes":3,
        "new_draw_nodes":0,
        "extra_triangles_per_mobile_unit":108,
        "no_additional_weapons":true,
        "android_device_fps_measured":false,
        "same_camera_zooms":comparisons,
        "failures":failures
    }
    var file:=FileAccess.open(folder.path_join(
        "g13-v26-geometry-report.json"),FileAccess.WRITE)
    verify(file!=null,"save 3D evidence JSON")
    if file!=null:
        file.store_string(JSON.stringify(report,"  ")+"\n")
        file.close()
    if failures>0:
        print("FAIL G13 V26 FACETED 3D ARMOR: ",failures,
            " / real camera delta ",JSON.stringify(comparisons))
        quit(1)
        return
    print("PASS G13 V26 FACETED 3D ARMOR: 19 real Godot PNGs, ",
        "8 factions, 3 replaced sculpt meshes, 0 added draw nodes, ",
        "108 extra triangles per LOD8 vehicle, 7 preserved animations")
    quit(0)
