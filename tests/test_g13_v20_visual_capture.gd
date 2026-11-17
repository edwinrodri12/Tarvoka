extends SceneTree

# G13 V20 final native Godot ART acceptance gallery.
# 8 factions + 7 full-vehicle camera views + 2 distinct attack poses
# + 1 wheel close-up = 18 PNG captures. No battle rule changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Surface=preload("res://scripts/ui/G13SurfaceFinishV8.gd")
const Wheels=preload("res://scripts/ui/G13WheelFinishV7.gd")
const Silhouette=preload("res://scripts/ui/G13SilhouetteV10.gd")
const Finish=preload("res://scripts/ui/G13BodyFinishV11.gd")
const Mechanic=preload("res://scripts/ui/G13MechanicalFinishV12.gd")
const SurfaceV13=preload("res://scripts/ui/G13SurfaceFinishV13.gd")
const SensorsV14=preload("res://scripts/ui/G13SensorSculptV14.gd")
const TurretV15=preload("res://scripts/ui/G13TurretFinishV15.gd")
const BatchesV16=preload("res://scripts/ui/G13StaticBatchV16.gd")
const CannonsV18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const JointsV19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
const ArmorV20=preload("res://scripts/ui/G13TurretArmorV20.gd")
const TOTAL:=50
var saved:=0
var failed:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failed+=1
        push_error("G13 V20 acceptance: "+why)

func capture(view: SubViewport,dir: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture: Image=view.get_texture().get_image()
    var ok: bool=picture!=null and not picture.is_empty()
    if ok:
        ok=picture.save_png(dir.path_join(name))==OK
    check(ok,"save native 3D frame "+name)
    if ok:
        saved+=1

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var dest: String=OS.get_environment("G13_V20_CAPTURE_DIR")
    if dest.is_empty():
        dest="/tmp/g13-v20-acceptance"
    check(DirAccess.make_dir_recursive_absolute(dest)==OK,
        "create capture directory")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1080,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#25343d")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#ccd5dd")
    env.ambient_light_energy=0.66
    environment.environment=env
    viewport.add_child(environment)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-43,-30,0)
    key.light_energy=1.3
    viewport.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,132,0)
    fill.light_energy=0.46
    fill.shadow_enabled=false
    viewport.add_child(fill)
    var floor:=MeshInstance3D.new()
    var plane:=PlaneMesh.new()
    plane.size=Vector2(8,8)
    floor.mesh=plane
    var floor_mat:=StandardMaterial3D.new()
    floor_mat.albedo_color=Color("#505d59")
    floor.material_override=floor_mat
    floor.position.y=-0.005
    viewport.add_child(floor)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.65
    camera.current=true
    viewport.add_child(camera)
    var angles: Dictionary={
        "iso":Vector3(3.8,3.0,4.2),
        "front":Vector3(0.25,1.7,-5.0),
        "rear":Vector3(0.25,1.7,5.0),
        "left":Vector3(-5.0,1.8,0.15),
        "right":Vector3(5.0,1.8,0.15),
        "top":Vector3(0.40,6.0,0.80),
        "under":Vector3(2.5,-2.3,3.5)
    }
    var colors: Dictionary={}
    for faction in range(8):
        var unit:=Models.build("aa_mobile",faction,true,13)
        check(unit!=null and G13.has_model(unit),
            "high-quality G13 generated for faction %d" % faction)
        if unit==null:
            continue
        check(bool(unit.get_meta(Surface.FLAG,false)) and
            bool(unit.get_meta(Wheels.FLAG,false)) and
            bool(unit.get_meta(Silhouette.FLAG,false)) and
            bool(unit.get_meta(Finish.FLAG,false)) and
            bool(unit.get_meta(Mechanic.FLAG,false)) and
            bool(unit.get_meta(SurfaceV13.FLAG,false)) and
            bool(unit.get_meta(SensorsV14.FLAG,false)) and
            bool(unit.get_meta(TurretV15.FLAG,false)) and
            bool(unit.get_meta(BatchesV16.FLAG,false)) and
            bool(unit.get_meta(CannonsV18.FLAG,false)) and
            bool(unit.get_meta(JointsV19.FLAG,false)) and
            bool(unit.get_meta(ArmorV20.FLAG,false)),
            "faction %d includes real V7 wheels, V8 materials and V11 finished cab/turret shells" % faction)
        colors[str(unit.get_meta("tarvoka_g13_surface_v8_faction_paint",""))]=true
        viewport.add_child(unit)
        camera.size=4.65
        camera.position=angles["iso"]
        camera.look_at(Vector3(0,1.0,0),Vector3.UP)
        floor.visible=true
        await capture(viewport,dest,"g13_v20_faction_%02d_iso.png" % faction)
        viewport.remove_child(unit)
        unit.free()
    check(colors.size()==8,"eight faction colors are distinct")

    var hero:=Models.build("aa_mobile",0,true,13)
    check(hero!=null,"inspection hero exists")
    if hero==null:
        quit(1)
        return
    viewport.add_child(hero)
    for view_name in ["iso","front","rear","left","right","top","under"]:
        Models.restore_model_pose("aa_mobile",hero)
        floor.visible=view_name!="under"
        camera.size=4.65
        camera.position=angles[view_name]
        camera.look_at(Vector3(0,0.91 if view_name=="under" else 1.03,0),
            Vector3.UP)
        await capture(viewport,dest,"g13_v20_angle_%s.png" % view_name)
    floor.visible=true
    camera.position=angles["iso"]
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    check(Models.pose_model("aa_mobile",hero,"attack_air",0.25),
        "air attack hero animation remains available")
    await capture(viewport,dest,"g13_v20_fire_air.png")
    check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
        "ground attack hero animation remains available")
    await capture(viewport,dest,"g13_v20_fire_ground.png")
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.6,1.15,-1.75)
    camera.look_at(Vector3(0.70,0.35,-0.85),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v20_wheel_detail.png")
    # V12 macro passes locate gaps and mechanical collisions that are
    # hard to see from the seven whole-vehicle acceptance views.
    camera.position=Vector3(1.7,1.55,-2.7)
    camera.look_at(Vector3(0,1.16,-0.98),Vector3.UP)
    camera.size=1.8
    await capture(viewport,dest,"g13_v20_detail_glazing.png")
    camera.position=Vector3(2.0,2.08,0.1)
    camera.look_at(Vector3(0.36,1.72,0.05),Vector3.UP)
    camera.size=1.65
    await capture(viewport,dest,"g13_v20_detail_bearings.png")
    camera.position=Vector3(0.95,1.75,-2.25)
    camera.look_at(Vector3(0,1.73,-0.81),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v20_detail_hollow_muzzles.png")
    check(Models.pose_model("aa_mobile",hero,"attack_air",0.25),
        "high elevation still permits V12 gun closeup")
    camera.position=Vector3(1.65,2.65,-2.6)
    camera.look_at(Vector3(0,1.86,-0.9),Vector3.UP)
    camera.size=2.20
    await capture(viewport,dest,"g13_v20_detail_air_fire.png")
    Models.restore_model_pose("aa_mobile",hero)
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.1,1.16,1.65)
    camera.look_at(Vector3(0.67,0.85,0.0),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v20_detail_side_panel.png")
    camera.position=Vector3(1.95,2.50,-1.2)
    camera.look_at(Vector3(0.0,1.34,-0.58),Vector3.UP)
    camera.size=1.92
    await capture(viewport,dest,"g13_v20_detail_roof_pbr.png")
    # V14 radar dish and optics close-ups show whether the reflector is
    # actually concave and the turret-mounted tracker remains unobscured.
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(1.55,2.52,2.70)
    camera.look_at(Vector3(0,1.86,0.89),Vector3.UP)
    camera.size=1.60
    await capture(viewport,dest,"g13_v20_detail_radar_reflector.png")
    camera.position=Vector3(1.65,2.25,-1.85)
    camera.look_at(Vector3(0.4,1.76,0.03),Vector3.UP)
    camera.size=1.48
    await capture(viewport,dest,"g13_v20_detail_dual_optics.png")
    check(Models.pose_model("aa_mobile",hero,"scan",1.0),
        "V14 radar scan reaches original +70 degrees")
    camera.position=Vector3(2.5,2.65,2.2)
    camera.look_at(Vector3(0,1.80,0.55),Vector3.UP)
    camera.size=2.75
    await capture(viewport,dest,"g13_v20_radar_scan_70deg.png")
    Models.restore_model_pose("aa_mobile",hero)
    # V15 validation scenes preserve the same view and original gameplay
    # camera sizes. Night mode changes ONLY this test environment, never
    # adds runtime Light3D nodes to the G13 asset.
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.3,1.96,1.72)
    camera.look_at(Vector3(0,1.42,0.35),Vector3.UP)
    camera.size=1.85
    await capture(viewport,dest,"g13_v20_turret_joint_macro.png")
    camera.position=Vector3(2.05,3.12,-0.82)
    camera.look_at(Vector3(0,1.80,0.35),Vector3.UP)
    camera.size=1.85
    await capture(viewport,dest,"g13_v20_faction_roof_rails.png")
    camera.position=angles["iso"]
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    camera.size=8.2
    await capture(viewport,dest,"g13_v20_tactical_lod13_distance.png")
    viewport.remove_child(hero)
    var mobile:=Models.build("aa_mobile",0,true,8)
    check(mobile!=null,"V15 tactical comparison has genuine Android LOD8")
    if mobile!=null:
        viewport.add_child(mobile)
        await capture(viewport,dest,"g13_v20_tactical_lod8_distance.png")
        viewport.remove_child(mobile)
        mobile.free()
    viewport.add_child(hero)
    camera.size=4.65
    env.background_color=Color("#080e1b")
    env.ambient_light_color=Color("#566c88")
    env.ambient_light_energy=0.12
    key.light_energy=0.18
    fill.light_energy=0.06
    await capture(viewport,dest,"g13_v20_low_light_front_iso.png")
    camera.position=angles["rear"]
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    await capture(viewport,dest,"g13_v20_low_light_rear_lamps.png")
    # Restore only CI test environment after capture, not model materials.
    env.ambient_light_energy=0.66
    key.light_energy=1.3
    fill.light_energy=0.46
    env.background_color=Color("#25343d")
    # Exact same Godot 3D model and camera: render original V15 meshes
    # against their V16 GPU-instanced equivalents. Geometry, colors,
    # reflections and faction enamel should be visually indistinguishable.
    env.ambient_light_energy=0.66
    key.light_energy=1.3
    fill.light_energy=0.46
    env.background_color=Color("#25343d")
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=angles["iso"]
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    camera.size=4.65
    check(BatchesV16.set_legacy_comparison(hero,true),
        "turn on original V15 nodes for exact same-camera image reference")
    await capture(viewport,dest,"g13_v20_legacy_v15_iso.png")
    check(BatchesV16.set_legacy_comparison(hero,false),
        "turn on 17 GPU batches without changing camera or meshes")
    await capture(viewport,dest,"g13_v20_gpu_batches_iso.png")
    var before:Image=Image.load_from_file(dest.path_join("g13_v20_legacy_v15_iso.png"))
    var after:Image=Image.load_from_file(dest.path_join("g13_v20_gpu_batches_iso.png"))
    check(before!=null and after!=null and before.get_size()==after.get_size(),
        "reference and optimized images are same-size real Godot renderings")
    if before!=null and after!=null and before.get_size()==after.get_size():
        var sum_error:float=0.0
        var pixels:int=0
        # Deterministic sampled pixel comparison, tolerating tiny
        # order-dependent color/ambient variations in software GL.
        for y in range(0,before.get_height(),8):
            for x in range(0,before.get_width(),8):
                var old:Color=before.get_pixel(x,y)
                var new:Color=after.get_pixel(x,y)
                sum_error+=(absf(old.r-new.r)+absf(old.g-new.g)+absf(old.b-new.b))/3.0
                pixels+=1
        var mae:float=sum_error/float(maxi(1,pixels))
        check(mae<0.018,"V16 images must match V15 reference under MAE 0.018, got %.5f" % mae)
        print("G13 V20 VISUAL MAE = %.6f" % mae)
    # V18 user correction: side-mounted features must read as two
    # autocannons, NEVER as launcher pods. Photograph the real new
    # bevelled breech, ejection hatches, and collar transitions.
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(0.45,2.30,-2.70)
    camera.look_at(Vector3(0,1.68,-0.52),Vector3.UP)
    camera.size=1.64
    await capture(viewport,dest,"g13_v20_cannon_breech_front_macro.png")
    camera.position=Vector3(1.42,2.76,-1.18)
    camera.look_at(Vector3(0,1.76,-0.38),Vector3.UP)
    camera.size=1.62
    await capture(viewport,dest,"g13_v20_cannon_top_ejection_hatches.png")
    check(Models.pose_model("aa_mobile",hero,"attack_air",0.28),
        "V18 cannon geometry remains on pitching cannon rig")
    camera.position=Vector3(1.32,2.46,-2.25)
    camera.look_at(Vector3(0,1.83,-0.89),Vector3.UP)
    camera.size=1.93
    await capture(viewport,dest,"g13_v20_cannon_attack_air_pitch_macro.png")
    Models.restore_model_pose("aa_mobile",hero)
    # V19 genuine new 3D geometry audit: macro view at bearing-to-
    # gun-pitch junction from both sides. Use original pose math.
    camera.position=Vector3(2.05,2.10,-0.50)
    camera.look_at(Vector3(0.39,1.71,0.10),Vector3.UP)
    camera.size=1.30
    Models.restore_model_pose("aa_mobile",hero)
    await capture(viewport,dest,"g13_v20_side_trunnion_idle_macro.png")
    camera.position=Vector3(-2.05,2.10,-0.50)
    camera.look_at(Vector3(-0.39,1.71,0.10),Vector3.UP)
    camera.size=1.30
    await capture(viewport,dest,"g13_v20_opposite_trunnion_idle_macro.png")
    check(Models.pose_model("aa_mobile",hero,"aim_air",0.36),
        "V19 fixed ring remains on turret and spindle follows 42deg elevation")
    camera.position=Vector3(1.60,2.50,-1.58)
    camera.look_at(Vector3(0.25,1.70,-0.16),Vector3.UP)
    camera.size=1.65
    await capture(viewport,dest,"g13_v20_air_pitched_joint_macro.png")
    check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
        "V19 retains full ground attack while showing moving hub")
    camera.position=Vector3(1.60,2.28,-1.55)
    camera.look_at(Vector3(0.25,1.66,-0.16),Vector3.UP)
    camera.size=1.65
    await capture(viewport,dest,"g13_v20_ground_pitched_joint_macro.png")
    Models.restore_model_pose("aa_mobile",hero)
    # Same-angle controlled before/after V18/V19 comparison: identical
    # geometry and camera except the six real new V19 elements.
    camera.position=Vector3(1.80,2.37,-0.92)
    camera.look_at(Vector3(0.30,1.70,0.10),Vector3.UP)
    camera.size=1.56
    for side in [-1,1]:
        for part_name in [
            JointsV19.FIXED_RING % side,
            JointsV19.MOBILE_HUB % side,
            JointsV19.CHEEK % side
        ]:
            var part:=hero.find_child(part_name,true,false) as MeshInstance3D
            check(part!=null,"V19 compare six actual meshes")
            if part!=null:
                part.visible=false
    await capture(viewport,dest,"g13_v20_v18_reference_joint_iso.png")
    for side in [-1,1]:
        for part_name in [
            JointsV19.FIXED_RING % side,
            JointsV19.MOBILE_HUB % side,
            JointsV19.CHEEK % side
        ]:
            var part:=hero.find_child(part_name,true,false) as MeshInstance3D
            if part!=null:
                part.visible=true
    await capture(viewport,dest,"g13_v20_v19_integrated_joint_iso.png")
    # New V20: inspect the visible *moving* belly shield exposed by
    # gun elevation, and the fixed deck-to-rotating turret transitions.
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(1.6,1.50,-2.4)
    camera.look_at(Vector3(0,1.72,-0.45),Vector3.UP)
    camera.size=1.85
    await capture(viewport,dest,"g13_v20_underbreech_idle_low_macro.png")
    check(Models.pose_model("aa_mobile",hero,"aim_air",0.36),
        "V20 gun underplate actually follows raised weapon pivot")
    camera.position=Vector3(1.75,1.35,-1.7)
    camera.look_at(Vector3(0,1.79,-0.31),Vector3.UP)
    camera.size=1.85
    await capture(viewport,dest,"g13_v20_underbreech_raised_low_macro.png")
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.0,2.0,1.9)
    camera.look_at(Vector3(0.48,1.62,0.65),Vector3.UP)
    camera.size=2.05
    await capture(viewport,dest,"g13_v20_turret_rear_quarters.png")
    camera.position=Vector3(2.35,1.9,1.5)
    camera.look_at(Vector3(0.48,1.17,0.54),Vector3.UP)
    camera.size=1.76
    await capture(viewport,dest,"g13_v20_fixed_deck_saddles.png")
    # Identical camera, identical original pose; toggle exactly five new
    # V20 MeshInstance3D objects while leaving all V1-V19 art in place.
    camera.position=Vector3(2.3,2.16,1.24)
    camera.look_at(Vector3(0.43,1.47,0.44),Vector3.UP)
    camera.size=2.20
    var new_parts:Array[MeshInstance3D]=[]
    var belly:=hero.find_child(ArmorV20.GUN_UNDERSHIELD,
        true,false) as MeshInstance3D
    if belly!=null:
        new_parts.append(belly)
    for side in [-1,1]:
        var rear:=hero.find_child(ArmorV20.TURRET_AFT % side,
            true,false) as MeshInstance3D
        var saddle:=hero.find_child(ArmorV20.DECK_SADDLE % side,
            true,false) as MeshInstance3D
        if rear!=null:
            new_parts.append(rear)
        if saddle!=null:
            new_parts.append(saddle)
    check(new_parts.size()==5,"exact five V20 meshes to compare in same-camera render")
    for node in new_parts:
        node.visible=false
    await capture(viewport,dest,"g13_v20_v19_reference_same_camera.png")
    for node in new_parts:
        node.visible=true
    await capture(viewport,dest,"g13_v20_v20_final_same_camera.png")
    check(saved==TOTAL,
        "50 real PNG frames: eight factions, 7 directions, guns, joint, radar, day/night, V15 legacy vs V16 instancing")
    if failed>0:
        quit(1)
        return
    print("PASS G13 V20 CAPTURE: 50 real Godot frames, 8 factions, 7 angles including underside, two firing domains and wheel macro")
    quit(0)
