extends SceneTree
const Art = preload("res://scripts/ui/UnitModels3D.gd")
var issues: int = 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, message: String) -> void:
    if not ok:
        issues += 1
        push_error("M01: "+message)
func closed(mesh: Mesh) -> bool:
    var counts: Dictionary = {}
    var v: PackedVector3Array = mesh.get_faces()
    for i in range(0,v.size(),3):
        for j in range(3):
            var a: String = str(v[i+j])
            var b: String = str(v[i+(j+1)%3])
            var key: String = a+"|"+b if a<b else b+"|"+a
            counts[key] = int(counts.get(key,0))+1
    for n in counts.values():
        if n != 2:
            return false
    return not counts.is_empty()
func _run() -> void:
    for faction in range(-1,8):
        for lod in [8,13]:
            var model: Node3D = Art.build("patrol",faction,true,lod)
            check(model != null,"Factory")
            if model == null:
                continue
            check(model.get_meta("patrol_art_revision","") == "1.0","Correct revision")
            for path in ["CascoNaval","CubiertaPatrulla","CabinaPatrulla/CarcasaCabina","CabinaPatrulla/FaccionTechoCabina"]:
                var part: MeshInstance3D = model.get_node_or_null(path) as MeshInstance3D
                check(part != null and closed(part.mesh),"Closed "+path)
            var roof: MeshInstance3D = model.get_node("CabinaPatrulla/FaccionTechoCabina") as MeshInstance3D
            if faction >= 0:
                check((roof.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Art.faction_paint_color(faction)),"Faction")
            check(model.has_node("BarandaPatrulla_1") == (lod >= 13),"LOD")
            var hull: Node3D = model.get_node("CascoNaval") as Node3D
            var rest: Transform3D = hull.transform
            var origin: Vector3 = model.position
            for stage in range(5):
                check(Art.set_patrol_damage(model,stage,0.7),"Damage")
                check(model.position == origin,"Tactical origin unchanged")
                check(int(model.get_meta("patrol_damage",-1)) == stage,"Damage state")
                if stage == 4:
                    check(hull.position.y < -1.0,"Sinking")
                    check(not Art.pose_patrol(model,"move",0.25),"No resurrection")
            Art.set_patrol_damage(model,0)
            check(hull.transform.is_equal_approx(rest),"Restore")
            check(Art.pose_model("patrol",model,"move",0.25),"Motion dispatch")
            Art.restore_model_pose("patrol",model)
            model.free()
    var output: String = ProjectSettings.globalize_path("res://build/qa/patrol-v1")
    check(DirAccess.make_dir_recursive_absolute(output)==OK,"Output")
    var view := SubViewport.new()
    view.size = Vector2i(900,650)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#263A48")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_energy = 0.8
    view.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55,-35,0)
    light.light_energy = 1.3
    view.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.8
    view.add_child(camera)
    camera.current = true
    var model: Node3D = Art.build("patrol",0,true,13)
    view.add_child(model)
    for i in range(8):
        camera.position = Vector3(4,3,-5) if i<5 else Vector3(-4,3,5)
        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
        Art.set_patrol_damage(model,i if i<5 else 0,0.55 if i==4 else 0.0)
        if i == 6:
            Art.pose_patrol(model,"move",0.25)
        if i == 7:
            camera.position = Vector3(3,-2,4)
            camera.look_at(Vector3.ZERO,Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(),"Real image")
        if img != null and not img.is_empty():
            check(img.save_png(output+"/patrol_%d.png" % i)==OK,"Saved image")
    view.queue_free()
    if issues > 0:
        quit(1)
    else:
        print("PASS M01 PATROL V1: 18 variants, 8 PNGs")
        quit(0)
