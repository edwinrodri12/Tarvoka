extends SceneTree

# TARVOKA G16 V2: native, inspectable Godot geometry and real OpenGL pixels.
# Eight factions x two LODs, physical hydraulic travel, 16 comparison
# screenshots and 8 full-orbit images. No tactical economy changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/g16-v2"
var failed:int=0
var shots:int=0
var signatures:Dictionary={}

func assert_true(valid:bool,what:String)->void:
    if not valid:
        failed+=1
        push_error("G16 V2 GODOT QA: "+what)

func real_image(viewport:SubViewport,file:String)->Image:
    var img:Image=viewport.get_texture().get_image()
    assert_true(img!=null and not img.is_empty(),"Godot image: "+file)
    if img!=null and not img.is_empty():
        var bright:int=0
        for y in range(70,img.get_height()-65,21):
            for x in range(100,img.get_width()-95,21):
                if img.get_pixel(x,y).get_luminance()>0.28:
                    bright+=1
        assert_true(bright>12,"real illuminated 3D pixels: "+file)
        assert_true(img.save_png(OUT+"/"+file)==OK,
            "save native Godot PNG: "+file)
        shots+=1
    return img

func pixel_change(a:Image,b:Image)->int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    var count:int=0
    for y in range(70,a.get_height()-65,15):
        for x in range(100,a.get_width()-95,15):
            var x0:Color=a.get_pixel(x,y)
            var x1:Color=b.get_pixel(x,y)
            if absf(x0.r-x1.r)+absf(x0.g-x1.g)+absf(x0.b-x1.b)>0.18:
                count+=1
    return count

func _initialize()->void:
    call_deferred("_test")

func _test()->void:
    var gameplay:Dictionary=Arsenal.profile("logistics")
    assert_true(Arsenal.code("logistics")=="G16" and
        int(gameplay.get("attack",-1))==0 and
        int(gameplay.get("cost",-1))==300 and
        int(gameplay.get("hp",-1))==8 and
        int(gameplay.get("move_points",-1))==4 and
        str(gameplay.get("site",""))=="factory" and
        not Arsenal.valid("logistics_mobile"),
        "no combat, price, factory or supply rule modifications")
    assert_true(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"screenshot folder")
    var preview:=SubViewport.new()
    preview.size=Vector2i(1024,736)
    preview.own_world_3d=true
    preview.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(preview)
    var environment:=WorldEnvironment.new()
    var scene:=Environment.new()
    scene.background_mode=Environment.BG_COLOR
    scene.background_color=Color("#263947")
    scene.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    scene.ambient_light_color=Color("#e4edf1")
    scene.ambient_light_energy=0.68
    environment.environment=scene
    preview.add_child(environment)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-42,-34,0)
    key.light_energy=2.25
    preview.add_child(key)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.4
    camera.position=Vector3(4.6,3.7,4.9)
    preview.add_child(camera)
    camera.look_at(Vector3(0,1.20,0),Vector3.UP)
    camera.current=true
    var real_views:int=0
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("logistics_mobile",faction,true,lod)
            assert_true(model!=null,
                "G16 V2 generated faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            preview.add_child(model)
            assert_true(V1.has_model(model) and V2.has_model(model),
                "V2 is added to real V1 truck, not independent proxy")
            assert_true(bool(model.get_meta("tarvoka_g16_v2_cab_sealed",false))
                and bool(model.get_meta("tarvoka_g16_v2_solid_pbr_glass",false))
                and bool(model.get_meta("tarvoka_g16_v2_visual_only",false)),
                "opaque closed body and art-only contract")
            assert_true(int(model.get_meta("tarvoka_g16_v2_wheels",-1))==6,
                "every real 3D truck has 6 improved wheel modules")
            var forward:=model.find_child("G16_V2_HeavyCabFrontBrow",
                true,false) as MeshInstance3D
            var roof:=model.find_child("G16_V2_HeavyCabRoofArmor",
                true,false) as MeshInstance3D
            var cab:=model.find_child("G16_V1_ClosedCabin",
                true,false) as MeshInstance3D
            assert_true(cab!=null and cab.mesh is BoxMesh and
                forward!=null and forward.mesh is BoxMesh and
                roof!=null and roof.mesh is BoxMesh,
                "six-face underlying cab stays sealed and overlay is solid")
            for side in [-1,1]:
                var new_wind:=model.find_child(V2.GLASS+str(side),
                    true,false) as MeshInstance3D
                var door_glass:=model.find_child(
                    "G16_V2_ClosedSideGlass_%d" % side,
                    true,false) as MeshInstance3D
                for pane in [new_wind,door_glass]:
                    assert_true(pane!=null and pane.mesh is BoxMesh,
                        "four fully volumetric windows, not flat transparent cards")
                    if pane!=null:
                        var mat:=pane.material_override as StandardMaterial3D
                        assert_true(mat!=null and
                            mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED
                            and mat.clearcoat_enabled and mat.roughness<0.2,
                            "reflective PBR glazing still physically opaque")
                for axle in range(3):
                    var tag:String="%d_%d" % [side,axle]
                    var wheel:=model.find_child(V1.WHEEL_PREFIX+tag,
                        true,false) as Node3D
                    var v2wheel:=model.find_child(V2.SIDEWALL+tag,
                        true,false) as Node3D
                    var rim:=model.find_child(V2.RIM+tag,
                        true,false) as MeshInstance3D
                    assert_true(wheel!=null and v2wheel!=null and
                        rim!=null and rim.mesh is TorusMesh,
                        "six physical rim+sidewall sculpt pieces")
                    if wheel!=null and v2wheel!=null:
                        assert_true(v2wheel.get_parent()==wheel,
                            "machined rim mechanically follows spinning tire")
                        for t in range(8 if lod>=13 else 5):
                            assert_true(model.find_child(
                                V2.ARCH_PREFIX+"%d_%d_%d" % [side,axle,t],
                                true,false) is MeshInstance3D,
                                "real protective sculpted wheel arch segment")
            signatures[str(model.get_meta(
                "tarvoka_g16_v1_faction_color",""))]=true
            var barrel:=model.find_child(V2.BOOM_SLEEVE,
                true,false) as MeshInstance3D
            var piston:=model.find_child(V2.RAM,true,false) as MeshInstance3D
            var endpin:=model.find_child(V2.END_PIN,
                true,false) as MeshInstance3D
            assert_true(barrel!=null and piston!=null and endpin!=null and
                barrel.mesh is CylinderMesh and piston.mesh is CylinderMesh,
                "crane has two true-length native hydraulic rods and pivot")
            var baseline:float=piston.scale.y if piston!=null else 0.0
            assert_true(Models.pose_model("logistics_mobile",model,
                "unload",0.55),"real crane from V1 is animating with V2 hydraulic")
            if piston!=null:
                assert_true(piston.scale.y>baseline+0.03,
                    "telescoping crane shaft physically grows as boom lifts")
            assert_true(Models.pose_model("logistics_mobile",model,
                "move",0.55),"V2 wheels spin with V1 vehicle movement")
            var selected_wheel:=model.find_child(
                V1.WHEEL_PREFIX+"1_0",true,false) as Node3D
            if selected_wheel!=null:
                assert_true(absf(selected_wheel.rotation_degrees.x)>45.0,
                    "rim/sidewall rig rotates under same real wheel parent")
            Models.restore_model_pose("logistics_mobile",model)
            if piston!=null:
                assert_true(absf(piston.scale.y-baseline)<0.01,
                    "hydraulic fully returns to its stored resting length")
            assert_true(V2.show_finish(model,false),"hide V2 for genuine comparison")
            var v2root:=model.find_child(V2.FINISH,true,false) as Node3D
            assert_true(v2root!=null and not v2root.visible,
                "V2 compare hides all physical added exterior parts")
            if lod==13:
                model.rotation_degrees.y=27.0
                await process_frame
                await process_frame
                await process_frame
                var old:Image=real_image(preview,
                    "g16_v1_faction_%02d.png" % faction)
                assert_true(V2.show_finish(model,true),"restore V2 for QA capture")
                await process_frame
                await process_frame
                await process_frame
                var advanced:Image=real_image(preview,
                    "g16_v2_faction_%02d.png" % faction)
                assert_true(pixel_change(old,advanced)>22,
                    "upgraded cab and 6 wheels change real Godot pixels")
                real_views+=2
                if faction==0:
                    # Native 360-degree geometry audit (8 distinct camera rays).
                    for view in range(8):
                        model.rotation_degrees.y=float(view)*45.0
                        await process_frame
                        await process_frame
                        await process_frame
                        var image:Image=real_image(preview,
                            "g16_v2_360_%03d.png" % [view*45])
                        assert_true(image!=null and not image.is_empty(),
                            "V2 geometry readable from all eight angles")
                        real_views+=1
            else:
                assert_true(V2.show_finish(model,true),"LOD8 detail restored")
            preview.remove_child(model)
            model.free()
            await process_frame
    assert_true(signatures.size()==8,"unique enamel for all eight factions")
    assert_true(real_views==24 and shots==24,
        "16 V1-V2 before/after plus eight authentic 360 Godot images")
    preview.queue_free()
    await process_frame
    if failed>0:
        printerr("FAIL G16 V2 NATIVE 3D: %d failed checks" % failed)
        quit(1)
        return
    print("PASS G16 V2 NATIVE 3D: six sculpted wheel shoulders, four solid PBR panes, moving telescopic crane, eight factions and 24 Godot PNG")
    quit(0)
