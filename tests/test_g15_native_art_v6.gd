extends SceneTree

# G15 V6 native Godot artwork audit. Verifies real closed steel surfaces,
# polished sealed window panes, faction enamel visibility and nonbreaking
# V1..V5 animations at both hero and Android LOD without combat changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const V5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const OUT="res://build/qa/g15-v6"
var faults:int=0
var frames:int=0
var paints:Dictionary={}

func check(condition:bool,label:String)->void:
    if not condition:
        faults+=1
        push_error("G15 V6 REAL 3D: "+label)

func _initialize()->void:
    call_deferred("_run")

func _capture(filename:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var shot:Image=root.get_texture().get_image()
    check(shot!=null and shot.get_width()>=800 and
        shot.get_height()>=600,"Godot camera render "+filename)
    if shot!=null:
        check(shot.save_png(ProjectSettings.globalize_path(
            OUT.path_join(filename+".png")))==OK,
            "native G15 PNG saved "+filename)
        frames+=1

func _changed(name_old:String,name_new:String)->int:
    var older:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(name_old+".png")))
    var newer:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(name_new+".png")))
    if older==null or newer==null or older.get_size()!=newer.get_size():
        return -1
    var changed:int=0
    for y in range(0,older.get_height(),3):
        for x in range(0,older.get_width(),3):
            var a:Color=older.get_pixel(x,y)
            var b:Color=newer.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.14:
                changed+=1
    return changed

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"QA capture path")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.7
    stage.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-47,-32,0)
    sun.light_energy=1.85
    stage.add_child(sun)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-31,130,0)
    light.light_energy=0.89
    light.light_color=Color("#b6d0e3")
    stage.add_child(light)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#28343e")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#a9bdc9")
    env.ambient_light_energy=0.71
    world.environment=env
    stage.add_child(world)

    for faction in range(8):
        for art_level in [8,13]:
            var hero:bool=art_level==13
            var vehicle:Node3D=Models.build("ew_mobile",faction,true,art_level)
            check(vehicle!=null,"faction %d LOD%d is native G15" % [
                faction,art_level])
            if vehicle==null:
                continue
            check(V1.has_model(vehicle) and
                bool(vehicle.get_meta(V3.FLAG,false)) and
                bool(vehicle.get_meta(V4.FLAG,false)) and
                bool(vehicle.get_meta(V5.FLAG,false)) and
                bool(vehicle.get_meta(V6.FLAG,false)),
                "V1 V3 V4 V5 and new V6 all coexist")
            check(bool(vehicle.get_meta("tarvoka_g15_v6_no_gameplay_changes",false)),
                "visual-only PBR finish never touches combat")
            var assembly:=vehicle.find_child(V6.ASSEMBLY,
                true,false) as Node3D
            check(assembly!=null and assembly.get_parent()==
                vehicle.find_child(V1.CHASSIS,true,false),
                "true 3D exterior bolts to original vehicle chassis")
            for group in [V6.GLASS_GROUP,V6.SIDE_GROUP,V6.REAR_GROUP]:
                check(vehicle.find_child(group,true,false) is Node3D,
                    "real separated inspection assembly "+group)
            for side in [-1,1]:
                var id:String=str(side)
                var steel:=vehicle.find_child(
                    "G15_V6_SculptedSideArmor_"+id,true,false) as MeshInstance3D
                var aft:=vehicle.find_child(
                    "G15_V6_RearCornerArmor_"+id,true,false) as MeshInstance3D
                check(steel!=null and aft!=null and
                    steel.mesh is ArrayMesh and aft.mesh is ArrayMesh,
                    "closed chamfered sculpted side armor and rear corner")
                if steel!=null and aft!=null:
                    check(steel.mesh.get_faces().size()==84 and
                        aft.mesh.get_faces().size()==84,
                        "real 28-triangle sealed armored shell sides")
                var glass:=vehicle.find_child(
                    "G15_V6_SpecularGlass_"+id,true,false) as MeshInstance3D
                var glass_side:=vehicle.find_child(
                    "G15_V6_SideSpecularGlass_"+id,true,false) as MeshInstance3D
                check(glass!=null and glass_side!=null,
                    "separate true 3D windshield and lateral glazing")
                if glass!=null:
                    var spec:=glass.material_override as StandardMaterial3D
                    check(spec!=null and spec.clearcoat_enabled and
                        spec.roughness<0.10,
                        "glazing is genuinely polished reflective PBR material")
                    check(glass.mesh is ArrayMesh and
                        glass.mesh.get_faces().size()==84,
                        "glass is an eight-sided solid bevel, not a flat card")
                var faction_panel:=vehicle.find_child(
                    "G15_V6_FactionMainStripe_"+id,true,false) as MeshInstance3D
                check(faction_panel!=null and
                    faction_panel.material_override is StandardMaterial3D,
                    "faction paint remains on outside of steel")
                if faction_panel!=null:
                    var tint:=faction_panel.material_override as StandardMaterial3D
                    paints[tint.albedo_color.to_html()]=true
                    check(absf(faction_panel.position.x)>0.82,
                        "faction strip deliberately outside armor volume")
                var vent:=vehicle.find_child(
                    "G15_V6_CoolingRecess_"+id,true,false) as MeshInstance3D
                check(vent!=null and absf(vent.position.x)>0.82,
                    "side cooling hardware sits outside armored flank")
                var mirrors:=vehicle.find_child(
                    "G15_V6_MirrorHousing_"+id,true,false)
                check((mirrors!=null)==hero,
                    "Android LOD8 omits costly hero mirror assemblies")
            check(vehicle.find_child("G15_V6_RearExtractorHousing",
                true,false)!=null,"rear electronics cooling has actual geometry")
            var old:=vehicle.find_child("G15_FrontWindow_-1",
                true,false) as MeshInstance3D
            check(old!=null and not old.visible,
                "old block glass hidden when new polished geometry active")
            check(Models.pose_model("ew_mobile",vehicle,"move",0.46),
                "six-wheel movement preserved with V6 exterior")
            check(Models.pose_model("ew_mobile",vehicle,"deploy",0.52),
                "antenna fold hydraulic still physically follows mount")
            check(Models.pose_model("ew_mobile",vehicle,"scan",0.52),
                "antenna sweep preserved with V6 shell")
            check(V5.set_damage(vehicle,4),
                "broken EW head still exists above new armor")
            Models.restore_model_pose("ew_mobile",vehicle)
            check(int(vehicle.get_meta("tarvoka_g15_v5_visual_damage",-1))==0,
                "V1..V5 physical damage fully resets with V6")
            check(V6.show_finish(vehicle,false) and
                not assembly.visible and old.visible,
                "V5 historic body shows when V6 disabled")
            check(V6.show_finish(vehicle,true) and
                assembly.visible and not old.visible,
                "V6 restores all real 3D exterior meshes")
            if faction in [0,3] and hero:
                stage.add_child(vehicle)
                for view in range(3):
                    camera.position=(
                        Vector3(4.85,3.75,-5.5) if view==0 else
                        (Vector3(-5.4,3.75,4.6) if view==1 else
                        Vector3(1.3,3.2,6.9)))
                    camera.look_at(Vector3(0,1.52,0))
                    var prefix:String="g15-f%02d-v%d" % [faction,view]
                    check(V6.show_finish(vehicle,false),
                        "capture V5 before new native surface")
                    await _capture(prefix+"-v5")
                    check(V6.show_finish(vehicle,true),
                        "capture V6 after native surface")
                    await _capture(prefix+"-v6")
                    check(_changed(prefix+"-v5",prefix+"-v6")>35,
                        "new armor and glazing visibly alter genuine camera pixels")
                stage.remove_child(vehicle)
                vehicle.free()
            else:
                vehicle.free()
    check(paints.size()==8,"eight approved distinct G15 faction enamels")
    check(frames==12,"12 original Godot before and after render images")
    var result:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v6-manifest.json")),FileAccess.WRITE)
    if result!=null:
        result.store_string(JSON.stringify({
            "unit":"G15 native war electronic carrier",
            "art_revision":"V6 chamfered steel and specular sealed cab glazing",
            "factions":8,"lods":[8,13],
            "camera_pngs":frames,
            "new_abilities":false,"approved_final":false,
            "errors":faults
        },"  "))
        result.close()
    stage.queue_free()
    await process_frame
    if faults==0:
        print("PASS G15 V6 NATIVE 3D: true chamfered electronic armor, PBR cab windows, rear vent system, 8 faction paints, original rigs, 12 real Godot screenshots")
    else:
        print("FAIL G15 V6 NATIVE 3D: %d findings" % faults)
    quit(1 if faults>0 else 0)
