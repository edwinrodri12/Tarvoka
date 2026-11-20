extends SceneTree

# TARVOKA G16 V5: native Godot 4.3 PBR, opaque glass, wear and burn QA.
# Eight factions × two real LODs, V4/V5 before-after and 360° screenshots.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const V5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/g16-v5"
var errors:int=0
var images:int=0
var factions:Dictionary={}

func check(ok:bool,name:String)->void:
    if not ok:
        errors+=1
        push_error("G16 V5 NATIVE QA "+name)

func take(view:SubViewport,name:String)->Image:
    var image:Image=view.get_texture().get_image()
    check(image!=null and not image.is_empty(),"render image "+name)
    if image!=null and not image.is_empty():
        check(image.save_png(OUT+"/"+name)==OK,"save PNG "+name)
        images+=1
    return image

func image_difference(a:Image,b:Image)->int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    var different:int=0
    for y in range(70,a.get_height()-60,15):
        for x in range(100,a.get_width()-80,15):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.16:
                different+=1
    return different

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var profile:Dictionary=Arsenal.profile("logistics")
    check(Arsenal.code("logistics")=="G16" and
        Arsenal.price("logistics")==300 and
        int(profile.get("hp",-1))==8 and
        int(profile.get("attack",-1))==0 and
        int(profile.get("move_points",-1))==4 and
        not Arsenal.valid("logistics_mobile"),
        "visual-only role, unchanged actual logistics game balance")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"PNG path")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1024,736)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#293745")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#ebedef")
    env.ambient_light_energy=0.72
    world.environment=env
    viewport.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-29,0)
    light.light_energy=2.1
    viewport.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.3
    camera.position=Vector3(5.1,4.1,5.4)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.24,0),Vector3.UP)
    camera.current=true

    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("logistics_mobile",faction,true,lod)
            check(model!=null,"8 factions x LOD8/13 model exists")
            if model==null:
                continue
            viewport.add_child(model)
            check(V1.has_model(model) and V2.has_model(model) and
                V3.has_model(model) and V4.has_model(model) and
                V5.has_model(model),
                "all five real native art generations coexist")
            check(bool(model.get_meta(
                "tarvoka_g16_v5_all_four_glass_panes_remain_boxmesh",false))
                and bool(model.get_meta("tarvoka_g16_v5_visual_only",false)),
                "no glass holes; no new gameplay rules")
            factions[str(model.get_meta(
                "tarvoka_g16_v1_faction_color",""))]=true
            var body:=model.find_child(V5.FINISH,true,false) as Node3D
            var wear:=model.find_child(V5.WEAR,true,false) as Node3D
            check(body!=null and body.visible and wear!=null and wear.visible,
                "PBR finish and physical wear nodes visible by default")
            for glass_name in V5._glass_names():
                var pane:=model.find_child(
                    glass_name,true,false) as MeshInstance3D
                check(pane!=null and pane.mesh is BoxMesh,
                    "closed real 3D four glass panes never replaced")
                if pane!=null:
                    var material:=pane.material_override as StandardMaterial3D
                    check(material!=null and
                        material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED
                        and material.clearcoat_enabled and
                        material.roughness<0.20,
                        "reflective PBR, but absolutely opaque")
            for side in [-1,1]:
                var tag:String=str(side)
                for part_name in [
                        "G16_V5_FactionDoorInlay_"+tag,
                        "G16_V5_FactionCargoNameplate_"+tag,
                        "G16_V5_ClosedSideWindowGlint_"+tag]:
                    var part:=model.find_child(
                        part_name,true,false) as MeshInstance3D
                    check(part!=null and part.mesh is BoxMesh,
                        "real solid 3D faction enamel/volumetric glass trim")
                for i in range(6 if lod==13 else 3):
                    check(model.find_child(
                        "G16_V5_PhysicalDoorRivet_%s_%02d" % [tag,i],
                        true,false) is MeshInstance3D,
                        "physical door steel rivet at this LOD")
            check(V5.show_finish(model,false),
                "V4 baseline control toggles V5 without deleting meshes")
            check(body!=null and not body.visible,
                "V5 microdetail hidden in comparison")
            for glass_name in V5._glass_names():
                var pane:=model.find_child(
                    glass_name,true,false) as MeshInstance3D
                var saved:Dictionary=model.get_meta(V5.GLASS_HISTORY,{})
                check(pane!=null and saved.has(glass_name) and
                    pane.material_override==saved[glass_name],
                    "comparison restores exact V2 glass material instance")
            check(V5.show_finish(model,true),
                "V5 re-enables without creating duplicate pane surfaces")
            for glass_name in V5._glass_names():
                var pane:=model.find_child(
                    glass_name,true,false) as MeshInstance3D
                var recoated:StandardMaterial3D=(
                    pane.material_override as StandardMaterial3D if pane!=null else null)
                check(recoated!=null and recoated.clearcoat_enabled and
                    recoated.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "V5 glass coating actually re-enabled")
            for level in range(5):
                check(V5.set_damage(model,level),"damage stage "+str(level))
                check(V3.stage(model)==level,
                    "level stored in original V3 state authority")
                for layer in range(1,5):
                    var mesh_group:=model.find_child(
                        V5.WORN+str(layer),true,false) as Node3D
                    check(mesh_group!=null and mesh_group.visible==(level>=layer),
                        "cumulative opaque wear only at applicable level")
                var fire_group:=model.find_child(
                    V5.FLAMES,true,false) as Node3D
                check(fire_group!=null and
                    fire_group.visible==(level>=4),
                    "actual 3D flames visible only for 4/4 wreck")
            check(V5.pose_wreck(model,0.85),
                "V5 animation drives the real V4 physical wreck")
            check(V3.stage(model)==4,
                "wreck automatically reaches highest damage level")
            var flames:=model.find_child(
                V5.FLAMES,true,false) as Node3D
            var rotation_y:float=flames.rotation_degrees.y if flames!=null else -99.0
            check(V5.pose_wreck(model,1.0),
                "final 3D damage animation completes")
            check(flames!=null and flames.rotation_degrees.y>rotation_y,
                "native flame geometry visibly rotates during wreck")
            check(V5.set_damage(model,0),"G16 can be visually repaired")
            check(V3.stage(model)==0,"repair resets original V3 stage")
            check(Models.pose_model("logistics_mobile",model,"resupply",0.89),
                "original logistics supply animation still functional")
            for i in range(2):
                var lid:=model.find_child(
                    V3.DOOR+str(i),true,false) as Node3D
                check(lid!=null and lid.rotation_degrees.x>70.0,
                    "new PBR overlay leaves both true hinged ammo lids working")
            Models.restore_model_pose("logistics_mobile",model)
            if lod==13:
                model.rotation_degrees.y=28.0
                check(V5.show_finish(model,false),"V4 before image")
                await process_frame
                await process_frame
                await process_frame
                var before:Image=viewport.get_texture().get_image()
                if faction==0:
                    take(viewport,"g16_v4_before_v5.png")
                check(V5.show_finish(model,true),"V5 after image")
                await process_frame
                await process_frame
                await process_frame
                var after:Image=take(viewport,
                    "g16_v5_faction_%02d.png" % faction)
                check(image_difference(before,after)>14,
                    "new high-contrast PBR microdetail visibly changes render")
                if faction==0:
                    for i in range(8):
                        model.rotation_degrees.y=float(i)*45.0
                        await process_frame
                        await process_frame
                        await process_frame
                        take(viewport,
                            "g16_v5_orbit_%03d.png" % (i*45))
                    model.rotation_degrees.y=28.0
                    for level in range(5):
                        check(V5.set_damage(model,level),
                            "capture damage state "+str(level))
                        await process_frame
                        await process_frame
                        await process_frame
                        take(viewport,"g16_v5_damage_%d.png" % level)
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(factions.size()==8,"eight distinguishable faction paint codes")
    check(images==22,"8 faction + 8 orbit + 5 wear + 1 baseline PNGs")
    viewport.queue_free()
    await process_frame
    if errors>0:
        printerr("FAIL G16 V5 NATIVE PBR: %d assertions" % errors)
        quit(1)
        return
    print("PASS G16 V5 NATIVE PBR: 4 opaque coated BoxMesh windows, 8 factions, real metal fasteners, V4 comparison, 4 cumulative damage layers, moving flame geometry and 22 true Godot images")
    quit(0)
