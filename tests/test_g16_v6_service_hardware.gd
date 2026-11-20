extends SceneTree

# G16 V6: native 3D hardware QA, eight factions, Android LOD8 and hero LOD13.
# The existing G16 moves real 3D hoses; no ammo/fuel/turn mutations by art.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const MaterialsV5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const V6=preload("res://scripts/ui/G16DeployableSupplyHardwareV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/g16-v6"
var failures:int=0
var shots:int=0

func check(ok:bool,label:String)->void:
    if not ok:
        failures+=1
        push_error("G16 V6 SUPPLY 3D QA: "+label)

func _initialize()->void:
    call_deferred("_run")

func _capture(viewport:SubViewport,label:String)->Image:
    await process_frame
    await process_frame
    await process_frame
    var photo:Image=viewport.get_texture().get_image()
    check(photo!=null and not photo.is_empty(),"real rendered view "+label)
    if photo!=null and not photo.is_empty():
        check(photo.save_png(OUT+"/"+label+".png")==OK,
            "actual Godot screenshot "+label)
        shots+=1
    return photo

func _delta(a:Image,b:Image)->int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    var change:int=0
    for y in range(80,a.get_height()-80,8):
        for x in range(90,a.get_width()-90,8):
            var first:Color=a.get_pixel(x,y)
            var second:Color=b.get_pixel(x,y)
            if absf(first.r-second.r)+absf(first.g-second.g)+absf(first.b-second.b)>0.20:
                change+=1
    return change

func _run()->void:
    var profile:Dictionary=Arsenal.profile("logistics")
    check(Arsenal.code("logistics")=="G16" and
        int(profile.get("hp",-1))==8 and
        int(profile.get("attack",-1))==0 and
        int(profile.get("move_points",-1))==4 and
        Arsenal.price("logistics")==300,
        "V6 does not change playable G16 HP, movement, attack or price")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"native QA folder")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1024,736)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#263744")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#dce7ee")
    environment.ambient_light_energy=0.90
    var world:=WorldEnvironment.new()
    world.environment=environment
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-38,-37,0)
    sun.light_energy=2.3
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.6
    camera.position=Vector3(-5.1,3.1,-4.5)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.30,0))
    camera.current=true
    var counted:int=0
    for faction in range(8):
        for lod in [8,13]:
            var truck:=Models.build("logistics_mobile",faction,true,lod)
            check(truck!=null,"G16 V6 faction %d LOD %d" % [faction,lod])
            if truck==null:
                continue
            counted+=1
            viewport.add_child(truck)
            check(V1.has_model(truck) and V3.has_model(truck) and
                V4.has_model(truck) and MaterialsV5.has_model(truck) and V6.has_model(truck),
                "V5 uses the actual same historical 6x6 model")
            check(bool(truck.get_meta(
                "tarvoka_g16_v6_original_tactical_rules_unchanged",false)),
                "all additions are 3D art only")
            var group:=truck.find_child(V6.ROOT,true,false) as Node3D
            var hinge:=truck.find_child(V6.HOSE,true,false) as Node3D
            var lid:=truck.find_child(V6.LID,true,false) as Node3D
            var nozzle:=truck.find_child(V6.COUPLING,true,false) as Node3D
            var gauge:=truck.find_child(V6.GAUGE,true,false) as MeshInstance3D
            check(group!=null and hinge!=null and lid!=null and
                nozzle!=null and gauge!=null,
                "service chassis, flexible hose, cover, coupling and PBR gauge")
            if group==null or hinge==null or lid==null:
                truck.free()
                continue
            check(not hinge.visible,"idle hose correctly stored")
            var metal_plates:int=0
            for name in [
                    "G16_V6_ClosedReelBackplate","G16_V6_ArmoredReelCase",
                    "G16_V6_RealRubberHoseSegment_00",
                    "G16_V6_ThickServiceCover",
                    "G16_V6_ColorCodedQuickConnect"]:
                var part:=truck.find_child(name,true,false) as MeshInstance3D
                check(part!=null,"physical 3D supply part "+name)
                if part!=null:
                    var mat:=part.material_override as StandardMaterial3D
                    check(mat!=null and mat.transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED and
                        mat.albedo_color.a==1.0 and mat.cull_mode==
                        BaseMaterial3D.CULL_DISABLED,
                        "opaque closed service hardware "+name)
                    metal_plates+=1
            check(metal_plates==5,"five main modelled 3D service components")
            var faction_mark:=truck.find_child(V6.MARK,
                true,false) as MeshInstance3D
            var coating:StandardMaterial3D=(
                faction_mark.material_override as StandardMaterial3D
                if faction_mark!=null else null)
            check(coating!=null and
                coating.albedo_color.is_equal_approx(
                    Models.faction_paint_color(faction)),
                "V5 uses original faction palette on actual quick-connect case")
            var step_count:int=int(truck.get_meta("tarvoka_g16_v6_hero_segments",-1))
            check(step_count==(6 if lod==13 else 3),
                "V5 real LOD-aware rubber-hose segmentation")
            check(Models.pose_model("logistics_mobile",truck,"resupply",0.90),
                "original G16 resupply drives external articulated hose")
            check(hinge.visible and hinge.rotation_degrees.y< -10 and
                lid.rotation_degrees.z< -40,
                "hose swivels outward with real articulated service cover")
            check(nozzle!=null and
                nozzle.global_position.x<hinge.global_position.x-0.85,
                "outboard coupling physically clears armoured chassis side")
            check(bool(truck.get_meta(
                "tarvoka_g16_v6_extended_hose_clears_chassis",false)),
                "extended tube is labelled as a separate visible 3D asset")
            for i in range(2):
                var ammo:=truck.find_child(V3.DOOR+str(i),true,false) as Node3D
                check(ammo!=null and ammo.rotation_degrees.x>65,
                    "both original ammunition lids still animate during supply")
            check(Models.pose_model("logistics_mobile",truck,"camp",0.90),
                "G16 temporary camp preview keeps real supply connection")
            check(hinge.visible,"service hose still accessible in deployed camp")
            check(Models.pose_model("logistics_mobile",truck,"pack",1.0),
                "G16 pack-up returns hose to actual stowed geometry")
            check(not hinge.visible,"hose fully retracted by pack animation")
            Models.restore_model_pose("logistics_mobile",truck)
            check(not hinge.visible and absf(lid.rotation_degrees.z)<0.01,
                "restoration re-closes both mechanical hose and cover")
            check(V6.show_finish(truck,false),"V5 compare to V4 works")
            check(not group.visible,"V4 historical comparison hides V5 hardware")
            check(V6.show_finish(truck,true),"V5 finish restores correctly")
            check(group.visible,"V5 hardware becomes visible after comparison")
            check(V4.has_model(truck) and V3.stage(truck)==0,
                "V5 doesn't damage old 3D asset")
            if lod==8:
                # Android mobile LOD must actually render the flexible hose,
                # not merely contain a Node3D that passes structural tests.
                truck.rotation_degrees.y=12.0
                var mobile_closed:Image=await _capture(viewport,
                    "g16-v6-lod8-f%02d-hose-stowed" % faction)
                check(Models.pose_model("logistics_mobile",truck,
                    "resupply",0.96),"Android LOD8 operates the supply hose")
                var mobile_deployed:Image=await _capture(viewport,
                    "g16-v6-lod8-f%02d-hose-deployed" % faction)
                check(_delta(mobile_closed,mobile_deployed)>12,
                    "Android LOD8 supply deployment is visually distinguishable")
                check(V6.show_finish(truck,false),
                    "Android LOD8 hides its hose independently of the crane")
                await process_frame
                await process_frame
                await process_frame
                var mobile_without:Image=viewport.get_texture().get_image()
                check(_delta(mobile_deployed,mobile_without)>6,
                    "Android LOD8 physical rubber hose makes its own real pixels")
                check(V6.show_finish(truck,true),
                    "restore mobile low detail without changing active unit")
            if lod==13:
                truck.rotation_degrees.y=12.0
                var closed:Image=await _capture(viewport,
                    "g16-v6-f%02d-hose-stowed" % faction)
                check(Models.pose_model("logistics_mobile",truck,
                    "resupply",0.96),"QA animate physical hose to 96%")
                var deployed:Image=await _capture(viewport,
                    "g16-v6-f%02d-hose-deployed" % faction)
                check(_delta(closed,deployed)>14,
                    "full supply deployment visibly changes real Godot frame")
                # Isolate V6 with an identical crane, lighting and resupply
                # pose. This cannot falsely pass on V1-V5 animation pixels.
                check(V6.show_finish(truck,false),
                    "hide ONLY V6 while maintaining V1-V5 resupply pose")
                await process_frame
                await process_frame
                await process_frame
                var without_v6:Image=viewport.get_texture().get_image()
                check(_delta(deployed,without_v6)>12,
                    "physical V6 hose alone is recognizable in 3D image")
                check(V6.show_finish(truck,true),
                    "restore V6 for next camera/faction")
                if faction==0:
                    for angle in range(8):
                        truck.rotation_degrees.y=float(angle)*45.0
                        await _capture(viewport,
                            "g16-v6-hose-orbit_%03d" % (angle*45))
            viewport.remove_child(truck)
            truck.free()
            await process_frame
    check(counted==16,"all eight faction paints and both native model LODs")
    check(shots==40,
        "8 factions × 2 LOD stowed/deployed + 8 true Godot 360-degree views")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V6 REAL 3D: %d issues" % failures)
        quit(1)
    else:
        print("PASS G16 V6 REAL 3D: 8 factions, 2 LODs, coupler outside chassis, 32 stowed/deployed renders, 8 orbit angles, 40 real Godot frames")
        quit(0)
