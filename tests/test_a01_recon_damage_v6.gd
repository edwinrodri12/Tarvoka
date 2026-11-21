extends SceneTree

# Native Godot V6 art regression: five damage stages, repair, propeller
# suspension and no gameplay changes to the A01 reconnaissance UAV.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v6"
var failures:int=0
var images:int=0

func verify(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V6 DAMAGE QA: "+reason)

func _changed_render_pixels(a:Image,b:Image)->int:
    if a==null or b==null or a.get_size()!=b.get_size():
        return 0
    var count:int=0
    for y in range(24,a.get_height()-24,4):
        for x in range(24,a.get_width()-24,4):
            var before:Color=a.get_pixel(x,y)
            var after:Color=b.get_pixel(x,y)
            if absf(before.r-after.r)+absf(before.g-after.g)+absf(before.b-after.b)>0.14:
                count+=1
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    verify(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))==OK,
        "create damage preview folder")
    var original:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    verify(int(original.get("attack",-1))==0 and int(original.get("vision",-1))==7 and
        int(original.get("cost",-1))==250 and str(original.get("domain",""))=="air",
        "catalog uses existing unarmed, vision-7, cost-250 air unit")

    var vp:=SubViewport.new()
    vp.size=Vector2i(960,680)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e9f2fa")
    env.ambient_light_energy=0.70
    environment.environment=env
    vp.add_child(environment)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-48,-35,0)
    light.light_energy=2.0
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.75
    camera.position=Vector3(4.7,3.9,5.6)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.90,0),Vector3.UP)
    camera.current=true

    var colors:Dictionary={}
    for team in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",team,true,lod)
            verify(model!=null,"recon V6 model exists team %d LOD%d" % [team,lod])
            if model==null:
                continue
            vp.add_child(model)
            verify(Damage.has_model(model),"V6 true native damage rig team %d LOD%d" % [
                team,lod])
            verify(Damage.stage(model)==0,"new UAV is intact")
            verify(bool(model.get_meta("tarvoka_a01_v6_visual_only",false)),
                "damage artwork contains no tactical hooks")
            verify(int(model.get_meta("tarvoka_a01_v6_lod",0))==lod,
                "both hero and Android geometry supported")
            var paint:=model.find_child("A01_V5_VtailFactionPanel_L",
                true,false) as MeshInstance3D
            if paint!=null and paint.material_override is StandardMaterial3D:
                var tint:Color=(paint.material_override as StandardMaterial3D).albedo_color
                colors[tint.to_html()]=true
                verify(tint.is_equal_approx(Models.faction_paint_color(team)),
                    "tail paint retains official team %d" % team)
            else:
                verify(false,"V5 faction tail panel remains visible under damage")

            var last_damage_render:Image=null
            for damage_level in range(5):
                verify(Damage.set_stage(model,damage_level),
                    "set physical damage stage %d" % damage_level)
                verify(Damage.stage(model)==damage_level,
                    "damage selection is deterministic")
                for layer_id in range(1,5):
                    var layer:=model.find_child("A01_V6_DamageLayer_"+str(layer_id),
                        true,false) as Node3D
                    verify(layer!=null and layer.visible==(damage_level>=layer_id),
                        "damage layer D%d cumulative in stage %d" % [
                        layer_id,damage_level])
                var prop:=model.find_child(Drone.PROPELLER,true,false) as Node3D
                if prop!=null:
                    for blade in range(3):
                        var pivot:=prop.find_child(
                            "A01_V3_PusherBladePivot_"+str(blade),true,false) as Node3D
                        verify(pivot!=null and pivot.visible==(damage_level<4),
                            "three physical blades disappear only at D4")
                var airframe:=model.find_child(Drone.BODY,true,false) as Node3D
                verify(airframe!=null and (airframe.position.y<0)==(damage_level==4),
                    "wreck settles while previous stages retain aligned body")
                verify(not Damage.set_stage(model,-1) and
                    not Damage.set_stage(model,5) and
                    Damage.stage(model)==damage_level,
                    "out-of-range damage requests never corrupt state")
                if damage_level>=2:
                    verify(Damage.animate(model,0.35),"real smoke follows native clock")
                    for smoke_idx in range(2):
                        var wisp:=model.find_child("A01_V6_SmokePlume_"+str(smoke_idx),
                            true,false) as MeshInstance3D
                        var cone:=wisp.mesh as CylinderMesh if wisp!=null else null
                        verify(cone!=null and cone.top_radius<cone.bottom_radius,
                            "D2-D4 tapered opaque smoke replaces unrealistic balloons")
                else:
                    verify(not Damage.animate(model,0.35),
                        "intact and scratched UAV do not emit smoke")
                var active_meshes:int=0
                for candidate in model.find_children("*","MeshInstance3D",true,false):
                    var visual:=candidate as MeshInstance3D
                    if visual!=null and visual.visible and visual.is_visible_in_tree():
                        active_meshes+=1
                verify(active_meshes<=(70 if lod==8 else 95),
                    "even destroyed UAV remains under Android/hero mesh budget")
                for node in model.find_children("A01_V6_*","MeshInstance3D",true,false):
                    var part:=node as MeshInstance3D
                    verify(part!=null and part.mesh!=null and
                        part.material_override is StandardMaterial3D and
                        (part.material_override as StandardMaterial3D).transparency==
                            BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "physical damage never uses alpha or empty meshes")
                if team==0 and lod==13:
                    await process_frame
                    await process_frame
                    await process_frame
                    var screenshot:Image=vp.get_texture().get_image()
                    verify(screenshot!=null and not screenshot.is_empty(),
                        "native 3D screenshot at stage %d" % damage_level)
                    if screenshot!=null and not screenshot.is_empty():
                        if last_damage_render!=null:
                            verify(_changed_render_pixels(last_damage_render,screenshot)>=5,
                                "damage D%d produces observable new physical pixels" % damage_level)
                        last_damage_render=screenshot
                        verify(screenshot.save_png("%s/a01-v6-d%d.png" % [
                            OUT,damage_level])==OK,
                            "record actual native damage stage %d" % damage_level)
                        images+=1
            # Return from D4 while keeping the identical scene and faction.
            verify(Damage.repair(model),"visual repair returns from wreck to D0")
            verify(Damage.stage(model)==0,
                "repair restores intact 3D geometry and original paint")
            var prop_fixed:=model.find_child(Drone.PROPELLER,true,false) as Node3D
            if prop_fixed!=null:
                for blade in range(3):
                    var pivot_fixed:=prop_fixed.find_child(
                        "A01_V3_PusherBladePivot_"+str(blade),true,false) as Node3D
                    verify(pivot_fixed!=null and pivot_fixed.visible,
                        "repair restores all three spinning rotor blades")
            verify(Models.pose_model("uav_recon",model,"scan",0.25),
                "repaired camera can move again")
            verify(not Models.pose_model("uav_recon",model,"attack",0.4),
                "unarmed recon UAV cannot attack even in damage art tests")
            Models.restore_model_pose("uav_recon",model)
            vp.remove_child(model)
            model.free()

    verify(colors.size()==8,"all eight official faction colors retained")
    verify(images==5,"five native Godot damage stages captured")
    verify(Arsenal.profile("uav_recon")==original,
        "damage subsystem does not mutate tactical profile")
    vp.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 V6 NATIVE DAMAGE: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 V6 NATIVE DAMAGE: 8 factions, 2 LODs, D0-D4 cumulative opaque art, 5 Godot captures, repair and no weapons")
        quit(0)
