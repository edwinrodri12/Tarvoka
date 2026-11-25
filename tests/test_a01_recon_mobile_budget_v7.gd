extends SceneTree

# A01 V7 — real Godot 4.3 Android LOD8 *proxy* workload, not device FPS.
# Inspect all 8 factions, all 5 visual stages and a 12-airframe native scene.
# Neither its rendering workload nor its damage art changes gameplay stats.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v7"
## V30: regression ceilings based on V29 native measured workload.
const MOBILE_MESH_LIMIT=60
const HERO_MESH_LIMIT=70
const MOBILE_TRIANGLE_LIMIT=4000
const HERO_TRIANGLE_LIMIT=7000
const MOBILE_MATERIAL_LIMIT=48
const HERO_MATERIAL_LIMIT=50
const STRESS_COUNT=12
var failures:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V7 MOBILE BUDGET: "+description)

func _stats(model:Node3D)->Dictionary:
    var meshes:int=0
    var tris:int=0
    var materials:Dictionary={}
    for child in model.find_children("*","MeshInstance3D",true,false):
        var m:=child as MeshInstance3D
        if m==null or not m.is_visible_in_tree():
            continue
        check(m.mesh!=null,"visible art never has an empty mesh")
        if m.mesh==null:
            continue
        meshes+=1
        tris+=m.mesh.get_faces().size()/3
        var material:=m.material_override as StandardMaterial3D
        check(material!=null and
            material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
            "all visible A01 surfaces are solid and opaque")
        if material!=null:
            materials[material.get_instance_id()]=true
    return {"meshes":meshes,"triangles":tris,"materials":materials.size()}

func _difference(a:Image,b:Image)->int:
    if a==null or b==null or a.get_size()!=b.get_size():
        return 0
    var different:int=0
    for y in range(25,a.get_height()-25,10):
        for x in range(25,a.get_width()-25,10):
            var ca:Color=a.get_pixel(x,y)
            var cb:Color=b.get_pixel(x,y)
            if absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)>0.16:
                different+=1
    return different

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"create Android QA folder")
    var reference:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(reference.get("attack",-1))==0,
        "unarmed recon tactical profile remains unchanged")
    var vp:=SubViewport.new()
    vp.size=Vector2i(1024,720)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#f4f8fd")
    env.ambient_light_energy=0.66
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-48,-35,0)
    light.light_energy=1.8
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=20.0
    camera.position=Vector3(14,20,22)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.90,0),Vector3.UP)
    camera.current=true

    # 8 factions x 2 real LODs. Explicit geometry/material count at D0/D4.
    var mobile_tris:int=0
    var hero_tris:int=0
    var report_rows:Array=[]
    for team in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",team,true,lod)
            check(model!=null,"faction %d LOD%d builds" % [team,lod])
            if model==null:
                continue
            vp.add_child(model)
            check(Damage.has_model(model),"both LODs receive all V6 stages")
            var original:Dictionary=_stats(model)
            var triangle_limit:int=(
                MOBILE_TRIANGLE_LIMIT if lod==8 else HERO_TRIANGLE_LIMIT)
            var mesh_limit:int=MOBILE_MESH_LIMIT if lod==8 else HERO_MESH_LIMIT
            var material_limit:int=MOBILE_MATERIAL_LIMIT if lod==8 else HERO_MATERIAL_LIMIT
            check(int(original["materials"])<=material_limit,"D0 stays within material budget")
            report_rows.append({"faction":team,"lod":lod,"damage":0,"geometry":original})
            check(int(original["meshes"])<=mesh_limit,
                "undamaged visible mesh count stays under LOD budget")
            check(int(original["triangles"])<=triangle_limit,
                "undamaged triangle count stays under LOD budget")
            if team==0:
                if lod==8:
                    mobile_tris=int(original["triangles"])
                else:
                    hero_tris=int(original["triangles"])
                print("A01 V7 LOD%d D0: %d meshes / %d triangles / %d materials" % [
                    lod,original["meshes"],original["triangles"],original["materials"]])
            for stage in [1,2,3,4]:
                check(Damage.set_stage(model,stage),"D%d stage toggles" % stage)
                var metrics:Dictionary=_stats(model)
                report_rows.append({"faction":team,"lod":lod,"damage":stage,"geometry":metrics})
                check(int(metrics["materials"])<=material_limit,
                    "D%d remains under LOD%d material budget" % [stage,lod])
                check(int(metrics["meshes"])<=mesh_limit,
                    "D%d remains under LOD%d mesh budget" % [stage,lod])
                check(int(metrics["triangles"])<=triangle_limit,
                    "D%d remains under LOD%d triangle budget" % [stage,lod])
                if team==0 and stage==4:
                    print("A01 V7 LOD%d D4: %d meshes / %d triangles / %d materials" % [
                        lod,metrics["meshes"],metrics["triangles"],metrics["materials"]])
            check(Damage.repair(model),"repair leaves no damage meshes visible")
            var clean:Dictionary=_stats(model)
            check(clean["meshes"]==original["meshes"] and
                clean["triangles"]==original["triangles"] and
                clean["materials"]==original["materials"],
                "repair restores identical mesh and triangle budget")
            vp.remove_child(model)
            model.free()
    check(mobile_tris>0 and hero_tris>0 and float(mobile_tris)<=0.60*float(hero_tris),
        "V30 Android LOD saves at least 40 percent intact triangles")
    check(report_rows.size()==80,"V30 full 8 factions x 2 LODs x 5 states inventory")

    # 12 full UAVs, not fake icon billboards: an actual multi-unit scene.
    var fleet:Array[Node3D]=[]
    var build_started:int=Time.get_ticks_usec()
    for index in range(STRESS_COUNT):
        var aircraft:Node3D=Models.build("uav_recon",index%8,true,8)
        check(aircraft!=null,"multi-UAV Android prototype instance %d" % index)
        if aircraft==null:
            continue
        aircraft.position=Vector3(float(index%4)-1.5,0,
            float(index/4)-1.0)*4.2
        vp.add_child(aircraft)
        fleet.append(aircraft)
        check(Damage.has_model(aircraft),"fleet uses complete native model")
    var cold_build_us:int=Time.get_ticks_usec()-build_started
    print("A01 V7 LOD8 NATIVE PROXY: built %d models in %d ms (CI runner, NOT Android FPS)" % [
        fleet.size(),int(cold_build_us/1000.0)])
    check(fleet.size()==STRESS_COUNT,"12 separately rigged native UAVs exist")

    await process_frame
    await process_frame
    await process_frame
    var before:Image=vp.get_texture().get_image()
    check(before!=null and not before.is_empty(),
        "real multi-UAV Godot scene produces nonempty frame")
    if before!=null and not before.is_empty():
        check(before.save_png(OUT+"/a01-v7-12-android-lod8-d0.png")==OK,
            "save genuine twelve-A01 intact scene")
    var total_meshes:int=0
    var total_tris:int=0
    for aircraft in fleet:
        check(Damage.set_stage(aircraft,4),"D4 for each real unit")
        var metrics:Dictionary=_stats(aircraft)
        total_meshes+=int(metrics["meshes"])
        total_tris+=int(metrics["triangles"])
    check(total_meshes<=STRESS_COUNT*MOBILE_MESH_LIMIT,
        "12 destroyed UAVs remain under combined Android geometry budget")
    check(total_tris<=STRESS_COUNT*MOBILE_TRIANGLE_LIMIT,
        "12 damaged UAVs remain under combined triangle budget")
    await process_frame
    await process_frame
    await process_frame
    var after:Image=vp.get_texture().get_image()
    check(after!=null and not after.is_empty(),"12-UAV D4 visual renders")
    check(_difference(before,after)>=60,
        "multi-unit destruction visibly changes actual Godot framebuffer")
    if after!=null and not after.is_empty():
        check(after.save_png(OUT+"/a01-v7-12-android-lod8-d4.png")==OK,
            "save twelve-A01 destroyed scene")
    print("A01 V7 12 DRONES D4: %d native visible meshes / %d triangles" % [
        total_meshes,total_tris])
    for aircraft in fleet:
        check(Damage.repair(aircraft),"12 destroyed UAVs all restore")
        vp.remove_child(aircraft)
        aircraft.free()
    var report:Dictionary={
        "version":"V30","measurement":"Godot native CI visible mesh proxy; not Android FPS",
        "limits":{"lod8":{"meshes":MOBILE_MESH_LIMIT,"triangles":MOBILE_TRIANGLE_LIMIT,"materials":MOBILE_MATERIAL_LIMIT},
            "lod13":{"meshes":HERO_MESH_LIMIT,"triangles":HERO_TRIANGLE_LIMIT,"materials":HERO_MATERIAL_LIMIT}},
        "states":report_rows,
        "fleet_d4":{"count":fleet.size(),"meshes":total_meshes,"triangles":total_tris,"build_ms":float(cold_build_us)/1000.0}}
    var file:=FileAccess.open(OUT+"/a01-v30-workload.json",FileAccess.WRITE)
    check(file!=null,"V30 save machine-readable geometry inventory")
    if file!=null:
        file.store_string(JSON.stringify(report,"\t"))
        file.close()
    check(Arsenal.profile("uav_recon")==reference,
        "geometry stress test changed no combat values, vision or cost")
    vp.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 V7 MOBILE BUDGET: %d QA errors" % failures)
        quit(1)
    else:
        print("PASS A01 V7 MOBILE BUDGET: 8 factions x 2 LODs x D0-D4, triangle/mesh caps, twelve authentic UAVs with D4 and repair")
        quit(0)
