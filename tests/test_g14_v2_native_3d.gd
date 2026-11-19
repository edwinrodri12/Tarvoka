extends SceneTree

# TARVOKA G14 V2: actual engine 3D evidence, no generated illustration.
# Ensures both sides, closed volume, opaque specular glazing and tyre rigs.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G14MobileSAMV1.gd")
const V2=preload("res://scripts/ui/G14MobileSAMExteriorV2.gd")
const Factions=preload("res://scripts/ui/VisualStyle.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var failures:int=0

func check(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G14 V2 NATIVE QA: "+reason)

# Detect empty/black-only captures, not just successful PNG writes.
# Material/lighting may exist in the scene tree but be culled in the viewport.
func _has_lit_geometry(picture:Image)->bool:
    if picture==null or picture.is_empty():
        return false
    var lit:int=0
    for y in range(80,picture.get_height()-60,25):
        for x in range(150,picture.get_width()-130,25):
            if picture.get_pixel(x,y).get_luminance()>0.34:
                lit+=1
                if lit>=12:
                    return true
    return false

func _frame_difference(before:Image,after:Image)->int:
    if before==null or after==null or before.is_empty() or after.is_empty():
        return 0
    var count:int=0
    for y in range(70,after.get_height()-65,18):
        for x in range(140,after.get_width()-120,18):
            var a:Color=before.get_pixel(x,y)
            var b:Color=after.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.30:
                count+=1
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(Arsenal.valid("sam") and not Arsenal.valid("sam_mobile"),
        "art-only role does not affect playable SAM")
    var profile:Dictionary=Arsenal.profile("sam")
    check(int(profile.get("cost",-1))==900 and
        int(profile.get("attack_min_range",-1))==2 and
        int(profile.get("attack_range",-1))==5 and
        str(profile.get("site",""))=="artillery_depot",
        "original G14 production price, range and site remain intact")
    var viewport:=SubViewport.new()
    viewport.name="G14V2Closed3DQualityReview"
    viewport.size=Vector2i(940,680)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#263542")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#d5e5e9")
    env.ambient_light_energy=0.58
    environment.environment=env
    viewport.add_child(environment)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-30,0)
    light.light_energy=1.7
    viewport.add_child(light)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-25,120,0)
    fill.light_energy=0.5
    viewport.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=6.1
    camera.position=Vector3(5.3,3.9,5.9)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.35,0),Vector3.UP)
    camera.current=true
    const OUT_DIR="res://build/qa/g14-v2"
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT_DIR))==OK,
        "native screenshot evidence directory")
    var shots:int=0
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("sam_mobile",faction,true,lod)
            check(model!=null,"faction %d LOD %d original engine model" % [
                faction,lod])
            if model==null:
                continue
            viewport.add_child(model)
            check(V1.has_model(model) and V2.has_model(model),
                "V2 extends actual G14 V1 model, no second fake viewer")
            check(bool(model.get_meta("tarvoka_g14_v2_glazing_is_opaque",false)),
                "optical 3D is nontransparent")
            check(int(model.get_meta("tarvoka_g14_v2_native_tread_wheels",-1))==8,
                "eight real 3D tyre modules")
            var cab:=model.find_child(V2.CAB,true,false) as MeshInstance3D
            check(cab!=null and cab.mesh is ArrayMesh,
                "closed armored cab is a native triangulated mesh")
            if cab!=null and cab.mesh is ArrayMesh:
                var arrays: Array=(cab.mesh as ArrayMesh).surface_get_arrays(0)
                var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
                check(vertices.size()==36 and normals.size()==36,
                    "watertight six faces: exactly twelve triangles")
                var cab_center:=Vector3(0,1.34,-1.25)
                var normals_ok:bool=true
                var clockwise_ok:bool=true
                for triangle in range(int(vertices.size()/3)):
                    var k:int=triangle*3
                    var mid:Vector3=(vertices[k]+vertices[k+1]+vertices[k+2])/3.0
                    if normals[k].dot(mid-cab_center)<=0.01:
                        normals_ok=false
                    var crossed:Vector3=(vertices[k+1]-vertices[k]).cross(
                        vertices[k+2]-vertices[k])
                    if crossed.dot(normals[k])>=0.0:
                        clockwise_ok=false
                check(normals_ok,"all 12 cab triangles have outward normals")
                check(clockwise_ok,"all exterior faces use Godot 4.3 clockwise winding")
            for side in [-1,1]:
                var front:=model.find_child(
                    V2.GLASS_FRONT+str(side),true,false) as MeshInstance3D
                var lateral:=model.find_child(
                    V2.GLASS_SIDE+str(side),true,false) as MeshInstance3D
                check(front!=null and lateral!=null and
                    front.mesh is BoxMesh and lateral.mesh is BoxMesh,
                    "solid extruded glass on front and side %d" % side)
                if front!=null:
                    var finish:=front.material_override as StandardMaterial3D
                    check(finish!=null and
                        finish.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                        finish.clearcoat_enabled and finish.roughness<0.16,
                        "specular nontransparent PBR glass not invisible")
            var hero:bool=lod>=13
            for side in [-1,1]:
                for axle in range(4):
                    var key:String="%d_%d" % [side,axle]
                    var wheel:=model.find_child(
                        V2.WHEEL_PREFIX+key,true,false) as Node3D
                    check(wheel!=null,
                        "real wheel pivot %s in LOD%d" % [key,lod])
                    if wheel!=null:
                        var tread:MultiMeshInstance3D=wheel.find_child(
                            "G14_V2_RealRubberTread_"+key,false,false
                        ) as MultiMeshInstance3D
                        check(tread!=null and tread.multimesh!=null,
                            "each wheel has actual tread geometry "+key)
                        if tread!=null:
                            check(tread.multimesh.instance_count==(
                                40 if hero else 20),
                                "LOD tread count balanced for "+key)
            var marker:=model.find_child(
                "G14_V2_ExteriorProduction",true,false) as Node3D
            check(marker!=null and marker.visible,"V2 exterior is displayed")
            check(V2.show_finish(model,false),"disable native V2 for comparison")
            check(marker!=null and not marker.visible,
                "V1 screenshot hides complete V2 assembly")
            for side in [-1,1]:
                var old_glass:=model.find_child(
                    "G14_Parabrisas_%d" % side,true,false) as MeshInstance3D
                check(old_glass!=null and old_glass.visible,
                    "both V1 windscreens restored for comparison")
            var previous_frame:Image=null
            if lod==13:
                model.rotation_degrees.y=32.0
                await process_frame
                await process_frame
                await process_frame
                var picture:Image=viewport.get_texture().get_image()
                check(picture!=null and not picture.is_empty() and
                    picture.save_png("%s/g14_v1_faction_%02d.png" % [
                        OUT_DIR,faction])==OK,
                    "V1 true Godot comparison capture")
                check(_has_lit_geometry(picture),
                    "the V1 screenshot actually displays illuminated model geometry")
                previous_frame=picture
                shots+=1
            check(V2.show_finish(model,true),"reactivate real V2 panels")
            check(marker!=null and marker.visible,"V2 overlay restored")
            for side in [-1,1]:
                var original:=model.find_child(
                    "G14_Parabrisas_%d" % side,true,false) as MeshInstance3D
                check(original!=null and not original.visible,
                    "no Z-fighting with earlier V1 windscreen")
            check(Models.pose_model("sam_mobile",model,"move",0.31),
                "native rotating V1 tyre and V2 tread synchronously")
            for side in [-1,1]:
                for axle in range(4):
                    var wheel:=model.find_child(
                        V2.WHEEL_PREFIX+"%d_%d" % [side,axle],
                        true,false) as Node3D
                    check(wheel!=null and absf(wheel.rotation_degrees.x)>90.0,
                        "treads spin with wheel %d/%d" % [side,axle])
            Models.restore_model_pose("sam_mobile",model)
            var rest_wheel:=model.find_child(
                V2.WHEEL_PREFIX+"1_0",true,false) as Node3D
            check(rest_wheel!=null and absf(rest_wheel.rotation_degrees.x)<0.01,
                "original pose is reversible without drift")
            if lod==13:
                check(Models.pose_model("sam_mobile",model,"deploy",1.0),
                    "full armored deployed native pose")
                model.rotation_degrees.y=32.0
                await process_frame
                await process_frame
                await process_frame
                var capture:Image=viewport.get_texture().get_image()
                check(capture!=null and not capture.is_empty() and
                    capture.save_png("%s/g14_v2_faction_%02d.png" % [
                        OUT_DIR,faction])==OK,
                    "V2 true Godot 8-faction inspection capture")
                check(_has_lit_geometry(capture),
                    "the V2 screenshot actually displays the full 3D vehicle")
                check(_frame_difference(previous_frame,capture)>16,
                    "G14 V2 really changes the viewport, not only invisible metadata")
                shots+=1
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(shots==16,"16 authentic Godot V1/V2 screenshots")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G14 V2 NATIVE 3D: %d failed checks" % failures)
        quit(1)
        return
    print("PASS G14 V2 NATIVE 3D: closed 12-face shell, opaque PBR glass, 8 tread wheels, 8 factions, 16 captures")
    quit(0)
