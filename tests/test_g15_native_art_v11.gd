extends SceneTree

# G15 V11 actual Godot 4.3 QA: multi-angle HERO13/L0D8,
# original 6x6 pivots, PBR nonmetal rubber, reversible optical trim.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V10=preload("res://scripts/ui/G15OpticalGlazingV10.gd")
const V11=preload("res://scripts/ui/G15Detail360V11.gd")
const OUT="res://build/qa/g15-v11"
var failures:int=0
var captures:int=0

func check(ok:bool,why:String)->void:
    if not ok:
        failures+=1
        push_error("G15 V11 360 REAL 3D QA: "+why)

# A real closed mesh must use every undirected triangle edge exactly twice.
# Culling is separately checked because Godot WebGL can discard a correctly
# manifold rear-facing surface when a material is accidentally CULL_BACK.
func _is_watertight(mesh:Mesh)->bool:
    if not mesh is ArrayMesh:
        return false
    var faces:PackedVector3Array=mesh.get_faces()
    if faces.size()!=84:
        return false
    var edges:Dictionary={}
    for n in range(0,faces.size(),3):
        var v:Array[String]=[
            str(faces[n].snapped(Vector3.ONE*0.00001)),
            str(faces[n+1].snapped(Vector3.ONE*0.00001)),
            str(faces[n+2].snapped(Vector3.ONE*0.00001))]
        for k in range(3):
            var a:String=v[k]
            var b:String=v[(k+1)%3]
            var key:String=(a+"|"+b) if a<b else (b+"|"+a)
            edges[key]=int(edges.get(key,0))+1
    for amount in edges.values():
        if int(amount)!=2:
            return false
    return edges.size()>0

# Inspect actual Godot pixels: an intentionally saturated magenta probe sits
# INSIDE the EW shelter. No exterior angle should reveal that marker if
# the cab, side panels, roof and rear are truly opaque.
func _leaking_probe_pixels()->int:
    var image:Image=root.get_texture().get_image()
    if image==null:
        return -1
    var exposed:int=0
    for y in range(0,image.get_height(),2):
        for x in range(0,image.get_width(),2):
            var color:Color=image.get_pixel(x,y)
            if color.r>0.76 and color.b>0.52 and color.g<0.22:
                exposed+=1
    return exposed

func _initialize()->void:
    call_deferred("_run")

func _capture(label:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=root.get_texture().get_image()
    check(img!=null and img.get_size()==Vector2i(1024,768),
        "real Godot 1024x768 render "+label)
    if img!=null:
        check(img.save_png(ProjectSettings.globalize_path(
            OUT.path_join(label+".png")))==OK,
            "save native actual-frame "+label)
        captures+=1

func _difference(a:String,b:String)->int:
    var first:=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a+".png")))
    var second:=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b+".png")))
    if first==null or second==null or first.get_size()!=second.get_size():
        return -1
    var count:int=0
    for y in range(0,first.get_height(),3):
        for x in range(0,first.get_width(),3):
            var c:Color=first.get_pixel(x,y)
            var d:Color=second.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.12:
                count+=1
    return count

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"QA capture directory")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.70
    stage.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-28,0)
    sun.light_energy=2.1
    stage.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-25,145,0)
    fill.light_energy=0.96
    stage.add_child(fill)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#25333e")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#b6cbd5")
    env.ambient_light_energy=0.86
    var world:=WorldEnvironment.new()
    world.environment=env
    stage.add_child(world)

    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod>=13
            var model:Node3D=Models.build("ew_mobile",faction,true,lod)
            check(model!=null,"G15 8 factions and two native LODs")
            if model==null:
                continue
            check(bool(model.get_meta(V10.FLAG,false)) and
                bool(model.get_meta(V11.FLAG,false)) and
                bool(model.get_meta("tarvoka_g15_v11_no_gameplay_changes",false)),
                "V10 intact plus native V11 solely visual")
            # Structural hull QA: closed physical shells, opaque double-sided
            # materials on 11 existing exterior panels, zero transparent
            # steel, independent of faction color or mobile HERO quality.
            var wall_names:Array=V11.HULL_LIST
            check(wall_names.size()==11,
                "eleven physical armored walls defined in 360 closure")
            var previous:Dictionary=model.get_meta(V11.HULL_MATERIAL_OLD,{})
            var current:Dictionary=model.get_meta(V11.HULL_MATERIAL_NEW,{})
            check(previous.size()==11 and current.size()==11,
                "exact historic wall PBR materials saved for comparison")
            for label in wall_names:
                var wall:=model.find_child(str(label),true,false) as MeshInstance3D
                check(wall!=null,"original physical wall "+str(label))
                if wall==null:
                    continue
                var mat:=wall.material_override as StandardMaterial3D
                check(mat!=null and
                    mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                    mat.cull_mode==BaseMaterial3D.CULL_DISABLED and
                    is_equal_approx(mat.albedo_color.a,1.0),
                    "opaque double-sided no-see-through PBR wall "+str(label))
                check(wall.mesh.get_faces().size()>=12,
                    "real solid triangulated wall not a transparent decal "+str(label))
                if str(label) in [V3.SHELTER,V3.CAB,V3.ROOF]:
                    check(_is_watertight(wall.mesh),
                        "closed manifold front/rear/roof octagonal shell "+str(label))
            for name in ["G15_V11_CabShelterSealedBulkhead",
                    "G15_V11_UpperCabSeamBridge"]:
                var seal:=model.find_child(name,true,false) as MeshInstance3D
                check(seal!=null and seal.mesh is BoxMesh,
                    "closed physical thickness bridging 8cm cab gap "+name)
            # V11B must physically back the formerly see-through contours.
            # Every seal is a six-sided closed BoxMesh, never a decal.
            var contour:=model.find_child(V11.SEALED_GROUP,true,false) as Node3D
            check(contour!=null and
                contour.get_child_count()==V11.SEALED_PARTS.size(),
                "V11B 13 physical contour closures in each faction/LOD")
            check(int(model.get_meta(
                "tarvoka_g15_v11b_physical_contour_seals",0))==13,
                "native thirteen structural backings installed")
            for plate_name in V11.SEALED_PARTS:
                var panel:=model.find_child(str(plate_name),
                    true,false) as MeshInstance3D
                check(panel!=null,"physical 3D no-hole plate "+str(plate_name))
                if panel!=null:
                    var geometry:=panel.mesh as BoxMesh
                    var surface:=panel.material_override as StandardMaterial3D
                    check(geometry!=null and
                        geometry.size.x>=0.05 and
                        geometry.size.y>=0.16 and
                        geometry.size.z>=0.12,
                        "real six-face body panel thickness "+str(plate_name))
                    check(surface!=null and
                        surface.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                        surface.cull_mode==BaseMaterial3D.CULL_DISABLED and
                        surface.depth_draw_mode==BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY and
                        is_equal_approx(surface.albedo_color.a,1.0),
                        "completely opaque contour backing "+str(plate_name))
            var assembly:=model.find_child(V11.ASSEMBLY,true,false) as Node3D
            var wheels:=model.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            check(assembly!=null,"front cab sculpt is native node")
            check(wheels!=null and wheels.get_child_count()==6,
                "six original moving pivots preserved")
            if wheels==null:
                model.free()
                continue
            for side in [-1,1]:
                var wipe:=model.find_child(V11.WIPER+str(side),
                    true,false) as MeshInstance3D
                check(wipe!=null and wipe.mesh is CylinderMesh,
                    "physical 3D windshield blade on both panes")
            var ring_count:int=0
            for wheel in wheels.get_children():
                var token:String=str(wheel.name).trim_prefix("G15_Wheel_")
                var rubber:=wheel.find_child(V11.TIRE+token,
                    false,false) as MeshInstance3D
                var bead:=wheel.find_child(V11.BEAD+token,
                    false,false) as MeshInstance3D
                var marks:=wheel.find_child(V11.MARK+token,
                    false,false) as MultiMeshInstance3D
                check(rubber!=null and bead!=null and marks!=null,
                    "native sidewall shoulders on original wheel "+token)
                if rubber!=null:
                    ring_count+=1
                    var mat:=rubber.material_override as StandardMaterial3D
                    check(rubber.mesh is TorusMesh and mat!=null and
                        mat.metallic==0.0 and mat.roughness>0.85,
                        "matte non-metallic sculpted rubber "+token)
                if marks!=null:
                    check(marks.multimesh.instance_count==(12 if hero else 6),
                        "LOD-aware shoulder embossed marks "+token)
            check(ring_count==6,"six complete 3D tyre shoulder rigs")
            check(V11.show_finish(model,false),"V11 reversible old finish")
            # V11B panels inherit visibility from their V11 assembly.
            # The children correctly remain visible locally for quick
            # reactivation; an invisible parent hides the entire subtree.
            check(contour!=null and assembly!=null and
                contour.get_parent()==assembly and not assembly.visible,
                "V11B solid contours hidden through V11 parent in historical V10")

            for label in wall_names:
                var old_wall:=model.find_child(str(label),true,false) as MeshInstance3D
                check(old_wall!=null and old_wall.material_override==previous[label],
                    "V10 historic wall original material preserved "+str(label))
            for wheel in wheels.get_children():
                var token:String=str(wheel.name).trim_prefix("G15_Wheel_")
                var part:=wheel.find_child(V11.TIRE+token,
                    false,false) as Node3D
                check(part!=null and not part.visible,
                    "V11 wheel shoulder hides for previous comparison")
            # Regression: turning V10 glazing ON must NOT silently enable
            # V11 repaired armor when user intentionally selected V11 OFF.
            check(V10.show_finish(model,true),
                "V10 glazing restored while user keeps V11 OFF")
            check(not (assembly as Node3D).visible,
                "V11 cab details remain hidden in explicit V10 comparison")
            for label in wall_names:
                var old_after_toggle:=model.find_child(
                    str(label),true,false) as MeshInstance3D
                check(old_after_toggle!=null and
                    old_after_toggle.material_override==previous[label],
                    "explicit V11-off persists when switching V10 optics "+
                    str(label))
            check(V11.show_finish(model,true),"V11 restored")
            check(contour!=null and contour.visible,
                "V11B solid contour closures restored")
            for label in wall_names:
                var latest_wall:=model.find_child(str(label),true,false) as MeshInstance3D
                check(latest_wall!=null and latest_wall.material_override==current[label],
                    "V11 repaired opaque material restored "+str(label))
            check(V10.show_finish(model,false),
                "V10 old glazing comparator still operates")
            var shield:=model.find_child(V11.ASSEMBLY,true,false) as Node3D
            check(shield!=null and not shield.visible,
                "historical V10 comparison hides added V11 cab")
            for wheel in wheels.get_children():
                var token:String=str(wheel.name).trim_prefix("G15_Wheel_")
                var shoulder:=wheel.find_child(V11.TIRE+token,
                    false,false) as Node3D
                check(shoulder!=null and not shoulder.visible,
                    "V10 historical comparator hides newer V11 tyre shoulder")
            check(V10.show_finish(model,true),
                "new optical geometry restored without losing 6x6")
            for label in wall_names:
                var restored_wall:=model.find_child(str(label),true,false) as MeshInstance3D
                check(restored_wall!=null and restored_wall.material_override==current[label],
                    "V10 toggle restores all eleven solid V11 walls "+str(label))
            check(Models.pose_model("ew_mobile",model,"move",0.52),
                "six wheels still move")
            check(Models.pose_model("ew_mobile",model,"deploy",0.5),
                "original hydraulic EW mast still deploys")
            check(Models.pose_model("ew_mobile",model,"scan",0.45),
                "original EW arrays still scan")
            check(Models.pose_model("ew_mobile",model,"damage",0.5),
                "original damage rig unchanged")
            Models.restore_model_pose("ew_mobile",model)
            if hero and faction in [0,3]:
                stage.add_child(model)
                # This high-chroma reference is geometrically inside the
                # original V3 closed EW housing, not in its wall surfaces.
                var leak_probe:=MeshInstance3D.new()
                leak_probe.name="G15_QA_INTERNAL_ONLY_MAGENTA_PROBE"
                var sphere:=SphereMesh.new()
                sphere.radius=0.30
                sphere.height=0.60
                leak_probe.mesh=sphere
                var marker:=StandardMaterial3D.new()
                marker.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
                marker.albedo_color=Color(1.0,0.0,0.70)
                leak_probe.material_override=marker
                leak_probe.position=Vector3(0.0,1.49,0.62)
                model.add_child(leak_probe)
                # Genuine 360° orbit at every 22.5°: thin corner gaps are
                # most visible between the older 45° QA viewpoints.
                for view in range(16):
                    var theta:float=TAU*float(view)/16.0
                    camera.position=Vector3(
                        6.2*sin(theta),3.15,-6.2*cos(theta))
                    camera.look_at(Vector3(0,1.38,-0.15))
                    var key:String="g15-f%02d-a%d" % [faction,view]
                    check(V11.show_finish(model,false),
                        "capture earlier 360 finish")
                    await _capture(key+"-v10")
                    check(V11.show_finish(model,true),
                        "capture refined 360 finish")
                    await _capture(key+"-v11")
                    check(_leaking_probe_pixels()==0,
                        "solid walls fully occlude interior probe from 360° "+key)
                    var changed:int=_difference(key+"-v10",key+"-v11")
                    check(changed>=0,"both real 3D captures exist "+key)
                    if view in [1,2,3,4,12,13,14,15]:
                        check(changed>8,
                            "V11 wheel-sidewall detail visible in oblique view "+key)
                stage.remove_child(model)
                model.free()
            else:
                model.free()
    check(captures==64,"64 authentic V10/V11B Godot renders covering 360° every 22.5°")
    var file:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v11-manifest.json")),FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify({
            "version":"G15 V11B","real_3d":true,"factions":8,
            "backing_plates":13,"angle_step_degrees":22.5,
            "lods":[8,13],"original_wheels":6,"captures":captures,
            "no_gameplay_changes":true,"errors":failures
        },"  "))
        file.close()
    stage.queue_free()
    await process_frame
    if failures==0:
        print("PASS G15 V11B 360 NATIVE: 13 true solid contour backing plates, 11 existing opaque armor walls, 3 watertight octagons, 6 original wheel pivots, eight factions/two LODs and 64 native Godot renders at 22.5-degree steps")
    else:
        print("FAIL G15 V11 360 NATIVE: %d problems" % failures)
    quit(1 if failures>0 else 0)
