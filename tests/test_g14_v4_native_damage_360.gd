extends SceneTree

# G14 V4 — native Godot 4.3 360-degree and progressive wreck QA.
# No fake generated screenshots, no changes to tactical HP or damage.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G14MobileSAMV1.gd")
const V2=preload("res://scripts/ui/G14MobileSAMExteriorV2.gd")
const V3=preload("res://scripts/ui/G14MobileSAMLauncherV3.gd")
const V4=preload("res://scripts/ui/G14MobileSAMDamageV4.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUTPUT="res://build/qa/g14-v4"
var problems:int=0
var rendered:int=0

func check(ok:bool,issue:String)->void:
    if not ok:
        problems+=1
        push_error("G14 V4 QA "+issue)

func lit_content(img:Image)->bool:
    if img==null or img.is_empty():
        return false
    var seen:int=0
    for y in range(100,img.get_height()-80,24):
        for x in range(125,img.get_width()-125,24):
            if img.get_pixel(x,y).get_luminance()>0.31:
                seen+=1
                if seen>=10:
                    return true
    return false

func image_change(a:Image,b:Image)->int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    var changed:int=0
    for y in range(100,a.get_height()-80,18):
        for x in range(125,a.get_width()-125,18):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.20:
                changed+=1
    return changed

func capture(view:SubViewport,filename:String)->Image:
    var photo:Image=view.get_texture().get_image()
    var okay:bool=photo!=null and not photo.is_empty()
    check(okay,"native viewport has actual pixels: "+filename)
    if okay:
        check(lit_content(photo),"visible lit 3D geometry: "+filename)
        check(photo.save_png(OUTPUT+"/"+filename)==OK,
            "PNG save from real Godot viewport: "+filename)
        rendered+=1
    return photo

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(Arsenal.valid("sam") and not Arsenal.valid("sam_mobile"),
        "studio model is NOT playable tactical class")
    var stats:Dictionary=Arsenal.profile("sam")
    check(Arsenal.code("sam")=="G14" and
        int(stats.get("cost",-1))==900 and
        int(stats.get("attack",-1))==8 and
        int(stats.get("attack_min_range",-1))==2 and
        int(stats.get("attack_range",-1))==5,
        "G14 original SAM damage/cost/range preserved")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK,"evidence folder")
    var viewport:=SubViewport.new()
    viewport.name="G14_V4_TrueGodot360Inspection"
    viewport.size=Vector2i(960,680)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var env_node:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#273746")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e2e9eb")
    env.ambient_light_energy=0.60
    env_node.environment=env
    viewport.add_child(env_node)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-46,-27,0)
    light.light_energy=1.80
    viewport.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=6.8
    camera.position=Vector3(5.8,4.4,6.0)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.26,0),Vector3.UP)
    camera.current=true
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("sam_mobile",faction,true,lod)
            check(model!=null,"full 3D native G14 faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            viewport.add_child(model)
            check(V1.has_model(model) and V2.has_model(model) and
                V3.has_model(model) and V4.has_model(model),
                "V4 layers added onto same G14 V1/V2/V3 model")
            check(int(model.get_meta("tarvoka_g14_v4_stages",-1))==4 and
                bool(model.get_meta("tarvoka_g14_v4_native_opaque_hull",false)),
                "four real mesh stages, chassis remains closed and opaque")
            var sealed:=model.find_child(V2.CAB,true,false) as MeshInstance3D
            check(sealed!=null and sealed.mesh is ArrayMesh and sealed.visible,
                "V4 never deletes or hides the V2 fully enclosed cabin volume")
            if sealed!=null and sealed.mesh is ArrayMesh:
                var face_data:Array=(sealed.mesh as ArrayMesh).surface_get_arrays(0)
                check((face_data[Mesh.ARRAY_VERTEX] as PackedVector3Array
                    ).size()==36,"twelve closed convex shell faces persist in wreck")
                var cab_mat:=sealed.material_override as StandardMaterial3D
                check(cab_mat!=null and
                    cab_mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "the original armor remains genuinely opaque at all levels")
            for side in [-1,1]:
                for prefix in [V2.GLASS_FRONT,V2.GLASS_SIDE]:
                    var pane:=model.find_child(prefix+str(side),true,false
                        ) as MeshInstance3D
                    check(pane!=null and pane.visible,
                        "all four solid windows survive wreck without missing parts")
                    if pane!=null:
                        var optical:=pane.material_override as StandardMaterial3D
                        check(optical!=null and
                            optical.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                            "every V4 glazing surface remains nontransparent")
            check(V4.stage(model)==0,"new G14 starts pristine")
            for step in range(1,5):
                check(V4.set_damage(model,step),"set G14 damage stage %d" % step)
                check(V4.stage(model)==step,"damage state persists on model")
                for i in range(1,5):
                    var overlay:=model.find_child(V4.STAGES+str(i),true,false) as Node3D
                    check(overlay!=null and overlay.visible==(i<=step),
                        "cumulative damage overlays stage %d/%d" % [step,i])
                var radar_damage:=model.find_child(
                    V4.RADAR_FRACTURE,true,false) as Node3D
                var launcher_damage:=model.find_child(
                    V4.POD_BURN+"3",true,false) as Node3D
                check(radar_damage!=null and
                    radar_damage.visible==(step>=3),
                    "severe radar fracture is pivot-attached")
                check(launcher_damage!=null and
                    launcher_damage.visible==(step>=3),
                    "burned missiles follow actual elevation pivot")
                var turret:=model.find_child(V1.LAUNCHER,true,false) as Node3D
                var radar:=model.find_child(V1.RADAR,true,false) as Node3D
                check(turret!=null and radar!=null,"physical turret and radar remain")
                if turret!=null and radar!=null:
                    check(absf(turret.rotation_degrees.z-(9.0 if step==4 else 0.0))<0.01,
                        "only wrecked launcher has a 9-degree mechanical cant")
                    check(absf(radar.rotation_degrees.z-(
                        13.0 if step>=3 else 0.0))<0.01,
                        "fractured radar becomes mechanically skewed")
            check(Models.pose_model("sam_mobile",model,"aim",1.0,
                Vector2i(1,-1)),
                "wreck stages survive real turret yaw and reload pose")
            check(V4.stage(model)==4,"damage is preserved after animation")
            check(Models.pose_model("sam_mobile",model,"hit",0.33),
                "native impact physical kick triggers art")
            var flash:=model.find_child(V4.FX,true,false) as Node3D
            check(flash!=null and flash.visible,
                "impact FX is actual visible 3D geometry")
            Models.restore_model_pose("sam_mobile",model)
            check(V4.stage(model)==4 and flash!=null and not flash.visible,
                "restore pose does not erase physical wreck, only transient FX")
            check(V4.show_finish(model,false),"V4 comparison off")
            var scorched:=model.find_child(V4.STAGES+"4",true,false) as Node3D
            check(scorched!=null and not scorched.visible,
                "V3 comparison fully hides V4 mesh, not just labels")
            check(V4.show_finish(model,true),"V4 comparison back on")
            check(scorched!=null and scorched.visible,
                "damage visuals return from existing metadata")
            check(V4.reset_damage(model) and V4.stage(model)==0,
                "restorable to the sealed intact V3 model")
            for i in range(1,5):
                var stage_node:=model.find_child(
                    V4.STAGES+str(i),true,false) as Node3D
                check(stage_node!=null and not stage_node.visible,
                    "restore leaves no wreck geometry stage %d" % i)
            # Test the actual FOUR-GEOMETRY stage from all 8 compass angles,
            # not just a scene tree count or an imagined render.
            if faction==0 and lod==13:
                var intact_images:Array[Image]=[]
                for angle in range(8):
                    model.rotation_degrees.y=float(angle)*45.0
                    await process_frame
                    await process_frame
                    await process_frame
                    intact_images.append(capture(viewport,
                        "g14_v4_360_intact_%03d.png" % [angle*45]))
                check(V4.set_damage(model,4),"360-degree wreck view")
                for angle in range(8):
                    model.rotation_degrees.y=float(angle)*45.0
                    await process_frame
                    await process_frame
                    await process_frame
                    var wreck:Image=capture(viewport,
                        "g14_v4_360_destroyed_%03d.png" % [angle*45])
                    check(image_change(intact_images[angle],wreck)>12,
                        "real wreck changes 3D pixels at %d degrees" % [angle*45])
                for step in range(1,5):
                    check(V4.set_damage(model,step),"intermediate visual stage "+str(step))
                    model.rotation_degrees.y=30.0
                    await process_frame
                    await process_frame
                    await process_frame
                    capture(viewport,"g14_v4_damage_stage_%d.png" % step)
            if lod==13:
                check(V4.set_damage(model,4),"eight faction wreck colors")
                model.rotation_degrees.y=25.0
                await process_frame
                await process_frame
                await process_frame
                capture(viewport,"g14_v4_wreck_faction_%02d.png" % faction)
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(rendered==28,"28 native Godot screenshots: 16 orbit + 4 levels + 8 factions")
    viewport.queue_free()
    await process_frame
    if problems>0:
        printerr("FAIL G14 V4 GODOT 360 QA: %d failed assertions" % problems)
        quit(1)
        return
    print("PASS G14 V4 GODOT 360 QA: 4 progressive opaque stages, eight compass angles, 8 factions, LOD8/13, 28 true captures")
    quit(0)
