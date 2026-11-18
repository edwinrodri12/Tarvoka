extends SceneTree

# Verifies actual 3D meshes, not AI concept art or 2D mockups.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G16=preload("res://scripts/ui/G16Logistics3DV1.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const Logistics=preload("res://scripts/core/Logistics.gd")
var failures: int=0

func _check(ok: bool,message: String)->void:
    if not ok:
        failures+=1
        push_error("G16 V1 MODEL: "+message)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    _check("logistics" in Models.ROLES,"native role registered in visual catalogue")
    _check(str(Arsenal.PROFILES["logistics"]["code"])=="G16",
        "existing logistics unit ID remains G16")
    _check(int(Arsenal.PROFILES["logistics"]["attack"])==0,
        "unarmed logistics role was not replaced by a combat vehicle")
    var state:Dictionary={"role":"logistics"}
    Logistics.equip(state)
    var stock_before:Dictionary=state.duplicate(true)
    var stage:=Node3D.new()
    root.add_child(stage)
    root.size=Vector2i(1024,768)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.7
    camera.position=Vector3(5.2,4.2,5.7)
    stage.add_child(camera)
    camera.look_at(Vector3(0,1.5,0))
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-45,-33,0)
    sun.light_energy=2.0
    stage.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,130,0)
    fill.light_color=Color("#bfd0e0")
    fill.light_energy=0.81
    stage.add_child(fill)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#27343d")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#b3c2ca")
    env.ambient_light_energy=0.72
    environment.environment=env
    stage.add_child(environment)
    var output_dir:String=ProjectSettings.globalize_path("res://build/qa/g16-v1")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var colors:Dictionary={}
    for faction in range(8):
        var unit:Node3D=Models.build("logistics",faction,true,13)
        _check(unit!=null,"faction %d real native unit built" % faction)
        if unit==null:
            continue
        stage.add_child(unit)
        _check(G16.has_model(unit),"genuine G16 rig installed")
        _check(bool(unit.get_meta("tarvoka_g16_art_only",false)),
            "art V1 does not supply resources or change game logic")
        var shell:=unit.find_child("G16_ArmoredCab",true,false) as MeshInstance3D
        _check(shell!=null and shell.mesh!=null and shell.mesh.get_faces().size()>50,
            "beveled native closed cab contains actual triangles")
        var wheel_group:=unit.find_child(G16.WHEELS,true,false) as Node3D
        _check(wheel_group!=null and wheel_group.get_child_count()==6,
            "exactly six independently articulated wheels")
        var rubber:=unit.find_child("G16_VulcanizedRubber_-1_0",true,false) as MeshInstance3D
        var rim:=unit.find_child("G16_MachinedRim_-1_0",true,false) as MeshInstance3D
        var paint:=unit.find_child("G16_FactionDoor_-1",true,false) as MeshInstance3D
        _check(rubber!=null and rim!=null and paint!=null,
            "tire, machined rim and faction paint are real 3D meshes")
        if rubber!=null and rubber.material_override is StandardMaterial3D:
            var m:=rubber.material_override as StandardMaterial3D
            _check(m.metallic==0.0 and m.roughness>=0.90,
                "non-metallic vulcanized rubber has matte PBR")
        if rim!=null and rim.material_override is StandardMaterial3D:
            var m:=rim.material_override as StandardMaterial3D
            _check(m.metallic>=0.75,"machined rim uses metallic PBR")
        if paint!=null and paint.material_override is StandardMaterial3D:
            var m:=paint.material_override as StandardMaterial3D
            _check(m.clearcoat_enabled,"faction enamel has clearcoat")
            colors[m.albedo_color.to_html()]=true
        for label in [G16.CRANE,G16.BOOM,G16.PALLET,G16.HOSE]:
            _check(unit.find_child(label,true,false)!=null,
                "genuine pivot or cargo assembly exists: "+label)
        for pose_name in ["move","crane","supply","hit","destroy"]:
            _check(Models.pose_model("logistics",unit,pose_name,0.55),
                "visual pose works: "+pose_name)
            if pose_name=="move" and wheel_group!=null:
                var first:Node3D=(wheel_group.get_child(0) as Node3D).get_child(0) as Node3D
                _check(absf(first.rotation.x)>0.1,"wheel actually rotates in movement")
            if pose_name=="crane":
                var boom:=unit.find_child(G16.BOOM,true,false) as Node3D
                _check(absf(boom.rotation.x)>0.1,"hydraulic crane boom is animated")
            if pose_name=="supply":
                var hose:=unit.find_child(G16.HOSE,true,false) as Node3D
                var pallet:=unit.find_child(G16.PALLET,true,false) as Node3D
                _check(absf(hose.rotation.y)>0.1 and pallet.position.y>1.23,
                    "real fuel hose and physical load respond to pose")
        Models.restore_model_pose("logistics",unit)
        _check(str(unit.get_meta("tarvoka_g16_preview_pose",""))=="idle",
            "restore returns to exactly idle")
        var crane:=unit.find_child(G16.CRANE,true,false) as Node3D
        var pallet:=unit.find_child(G16.PALLET,true,false) as Node3D
        _check(crane.rotation==Vector3.ZERO and
            pallet.position.distance_to(Vector3(0,1.23,1.35))<0.001,
            "crane and supply pallet restore exact original transform")
        for view in range(2):
            camera.position=(
                Vector3(5.2,4.2,5.7) if view==0 else
                Vector3(-5.4,2.2,-4.5))
            camera.look_at(Vector3(0,1.5,0))
            await process_frame
            await RenderingServer.frame_post_draw
            var pic:Image=root.get_texture().get_image()
            var target:String=output_dir.path_join(
                "g16_f%02d_angle%d.png" % [faction,view])
            _check(pic!=null and pic.get_width()>511 and pic.save_png(target)==OK,
                "Godot 4.3 rendered original PNG: "+target)
        stage.remove_child(unit)
        unit.free()
    _check(colors.size()==8,"all 8 factions use different enamel colors")
    var tactical:Node3D=Models.build("logistics",0,false,8)
    _check(tactical!=null and G16.has_model(tactical),
        "tactical LOD8 uses native G16 mesh and same silhouette")
    if tactical!=null:
        var wheels:Node3D=tactical.find_child(G16.WHEELS,true,false) as Node3D
        _check(wheels!=null and wheels.get_child_count()==6,
            "LOD8 retains six correct physical tires")
        _check(tactical.find_child(G16.PALLET,true,false)!=null and
            tactical.find_child(G16.CRANE,true,false)!=null,
            "LOD8 retains visible supply and crane silhouette")
        tactical.free()
    _check(state==stock_before,
        "art animation must NEVER mutate real existing logistics inventory")
    stage.queue_free()
    await process_frame
    if failures>0:
        print("FAIL G16 V1: %d assertions" % failures)
        quit(1)
    else:
        print("PASS G16 V1 NATIVE 3D: eight factions, 16 renders, PBR and reversible real load rig")
        quit(0)
