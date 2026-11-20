extends SceneTree

# TARVOKA G16 V4 — 22 authentic Godot PNGs / eight original factions.
# Checks sealed ArrayMesh front/roof/bulkhead and mechanical destruction.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/g16-v4"
const SHAPES=[
    "G16_V4_ClosedBevelRoof","G16_V4_ClosedFrontArmorLower",
    "G16_V4_DeepFrontBumper","G16_V4_OverheadCabBrow",
    "G16_V4_ForwardUnderbodySkid","G16_V4_ClosedCabRearBulkhead",
    "G16_V4_CargoBedUpperBrace","G16_V4_FleetColorTopBrace",
    "G16_V4_DoorFactionShoulder_-1","G16_V4_DoorFactionShoulder_1",
    "G16_V4_RearFactionShield_-1","G16_V4_RearFactionShield_1"]
var failures:int=0
var captures:int=0
var unique_factions:Dictionary={}

func check(ok:bool,what:String)->void:
    if not ok:
        failures+=1
        push_error("G16 V4 NATIVE SCULPT QA: "+what)

func photograph(v:SubViewport,name:String)->Image:
    var img:Image=v.get_texture().get_image()
    check(img!=null and not img.is_empty(),"actual 3D rendered image "+name)
    if img!=null and not img.is_empty():
        var bright:int=0
        for y in range(70,img.get_height()-60,21):
            for x in range(90,img.get_width()-90,21):
                if img.get_pixel(x,y).get_luminance()>0.30:
                    bright+=1
        check(bright>10,"visible real 3D pixels "+name)
        check(img.save_png(OUT+"/"+name)==OK,"Godot saved "+name)
        captures+=1
    return img

func pixel_delta(a:Image,b:Image)->int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    var amount:int=0
    for y in range(80,a.get_height()-70,15):
        for x in range(90,a.get_width()-90,15):
            var x1:Color=a.get_pixel(x,y)
            var x2:Color=b.get_pixel(x,y)
            if absf(x1.r-x2.r)+absf(x1.g-x2.g)+absf(x1.b-x2.b)>0.21:
                amount+=1
    return amount

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var playable:Dictionary=Arsenal.profile("logistics")
    check(Arsenal.code("logistics")=="G16" and
        int(playable.get("hp",-1))==8 and
        int(playable.get("attack",-1))==0 and
        int(playable.get("move_points",-1))==4 and
        Arsenal.price("logistics")==300 and
        str(playable.get("site",""))=="factory" and
        not Arsenal.valid("logistics_mobile"),
        "tactical G16 cost/damage/HP unchanged; V4 only sculpt")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"output directory")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1024,736)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#213645")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce9ef")
    env.ambient_light_energy=0.75
    world.environment=env
    viewport.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-30,0)
    light.light_energy=2.2
    viewport.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.4
    camera.position=Vector3(5.1,3.8,5.3)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.20,0),Vector3.UP)
    camera.current=true
    var previous:Image
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("logistics_mobile",faction,true,lod)
            check(model!=null,"V4 exists on faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            viewport.add_child(model)
            check(V1.has_model(model) and V2.has_model(model) and
                V3.has_model(model) and V4.has_model(model),
                "original V1 V2 V3 and V4 coexist on same native 3D rig")
            for meta_key in [
                "tarvoka_g16_v4_closed_bevelled_shells",
                "tarvoka_g16_v4_solid_side_faction_panels",
                "tarvoka_g16_v4_physical_damage",
                "tarvoka_g16_v4_visual_only",
                "tarvoka_g16_v4_original_cab_unmodified"]:
                check(bool(model.get_meta(meta_key,false)),
                    "asset integrity metadata "+meta_key)
            unique_factions[str(model.get_meta(
                "tarvoka_g16_v1_faction_color",""))]=true
            var cab:=model.find_child("G16_V1_ClosedCabin",
                true,false) as MeshInstance3D
            check(cab!=null and cab.mesh is BoxMesh,
                "real V1 six-face sealed original cabin retained")
            for side in [-1,1]:
                for pane_name in [
                    V2.GLASS+str(side),
                    "G16_V2_ClosedSideGlass_%d" % side]:
                    var pane:=model.find_child(pane_name,
                        true,false) as MeshInstance3D
                    var mat:StandardMaterial3D=(
                        pane.material_override as StandardMaterial3D if pane!=null else null)
                    check(pane!=null and pane.mesh is BoxMesh and
                        mat!=null and
                        mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "four true 3D reflective windows stay opaque")
            for name in SHAPES:
                var part:=model.find_child(name,true,false) as MeshInstance3D
                check(part!=null and part.mesh is ArrayMesh,
                    "closed original octagonal hard-surface sculpt "+name)
                if part!=null and part.mesh is ArrayMesh:
                    var geometry:=part.mesh as ArrayMesh
                    var coating:=part.material_override as StandardMaterial3D
                    check(geometry.surface_get_array_len(0)==84,
                        "28 actual triangles enclose 2 caps and 8 sidewalls")
                    check(coating!=null and
                        coating.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "no holes / no alpha / opaque metal "+name)
            for side in [-1,1]:
                var accent:=model.find_child(
                    "G16_V4_RearFactionShield_%d" % side,
                    true,false) as MeshInstance3D
                var original:=model.find_child(
                    "G16_V2_HeavyCabRoofArmor",true,false) as MeshInstance3D
                check(accent!=null and original!=null,
                    "faction coat and original roof coexist")
                if accent!=null:
                    var coat:=accent.material_override as StandardMaterial3D
                    check(coat!=null and coat.albedo_color.a==1.0,
                        "fully opaque faction enamel on each side")
            check(V3.stage(model)==0,"default undamaged vehicle")
            var body:=model.find_child(V4.BODY,true,false) as Node3D
            check(body!=null and body.visible,
                "V4 is visible by default in the same Studio scene")
            check(V4.show_finish(model,false),"compare previous V3")
            check(body!=null and not body.visible,"V4 off hides visual overlay")
            check(V4.show_finish(model,true),"re-enable premium V4")
            check(body!=null and body.visible,"V4 restored after comparison")
            check(V4.pose_wreck(model,0.43),"begin genuine damaged panel animation")
            check(V3.stage(model)==2,"damage stage smoothly changes by progress")
            var loose:=model.find_child(V4.LOOSE_LEFT,true,false) as Node3D
            check(loose!=null and loose.visible and
                absf(loose.rotation_degrees.z)>15,
                "left armoured shard physically tips away")
            check(V4.pose_wreck(model,0.84),"enter 3D damage stage four")
            check(V3.stage(model)==4,"damage reaches true wreck stage")
            var fumes:=model.find_child(V4.SMOKE,true,false) as Node3D
            var sparks:=model.find_child(V4.SPARKS,true,false) as Node3D
            check(fumes!=null and fumes.visible and
                sparks!=null and sparks.visible,
                "dense emissive native wreck smoke + sparks")
            var taper:=model.find_child(
                "G16_V4_TaperedSmokeWisp_00",true,false) as MeshInstance3D
            var wisp_mesh: CylinderMesh=(taper.mesh as CylinderMesh if taper!=null else null)
            check(wisp_mesh!=null and
                wisp_mesh.bottom_radius>wisp_mesh.top_radius and
                wisp_mesh.radial_segments>=7,
                "wreck smoke uses real tapered opaque volume, never giant floating spheres")
            var smoke_position:float=fumes.position.y if fumes!=null else -99.0
            check(V4.pose_wreck(model,1.0),"complete wreck sequence")
            check(fumes!=null and fumes.position.y>smoke_position,
                "smoke cluster moves upward with progress")
            check(V4.set_damage(model,0) and V3.stage(model)==0,
                "V4 wreck is repairable with no tactical HP changes")
            check(fumes!=null and not fumes.visible,
                "repaired truck no longer displays smoke")
            check(Models.pose_model("logistics_mobile",model,"resupply",0.95),
                "V4 retains original functional visual supply animation")
            for i in range(2):
                var lid:=model.find_child(V3.DOOR+str(i),
                    true,false) as Node3D
                check(lid!=null and lid.rotation_degrees.x>70,
                    "both original cargo lids remain animated in V4")
            Models.restore_model_pose("logistics_mobile",model)
            if lod==13:
                model.rotation_degrees.y=29.0
                check(V4.show_finish(model,false),
                    "take true native before image for only V4 additions")
                await process_frame
                await process_frame
                await process_frame
                var baseline:Image=viewport.get_texture().get_image()
                if faction==0:
                    previous=photograph(viewport,"g16_v3_baseline.png")
                check(V4.show_finish(model,true),
                    "take true native after image with V4 details")
                await process_frame
                await process_frame
                await process_frame
                var latest:Image=photograph(viewport,
                    "g16_v4_faction_%02d.png" % faction)
                check(pixel_delta(baseline,latest)>20,
                    "real PBR sculpt is materially different in Godot image")
                if faction==0:
                    check(pixel_delta(previous,latest)>20,
                        "approved V3 baseline differs from V4")
                    for view in range(8):
                        model.rotation_degrees.y=float(view)*45.0
                        await process_frame
                        await process_frame
                        await process_frame
                        photograph(viewport,"g16_v4_orbit_%03d.png" % (view*45))
                    model.rotation_degrees.y=25
                    for level in range(5):
                        check(V4.set_damage(model,level),
                            "select real wreck stage "+str(level))
                        await process_frame
                        await process_frame
                        await process_frame
                        photograph(viewport,"g16_v4_damage_%d.png" % level)
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(unique_factions.size()==8,"eight real unique faction colors")
    check(captures==22,"8 factions + 8 orbit + 5 damage + 1 original")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V4 NATIVE 3D: %d problems" % failures)
        quit(1)
        return
    print("PASS G16 V4 NATIVE 3D: 12 closed 84-vertex bevels, 4 opaque windows, 8 factions, physical wreck movement and 22 Godot captures")
    quit(0)
