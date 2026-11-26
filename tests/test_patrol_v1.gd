extends SceneTree
const Art = preload("res://scripts/ui/UnitModels3D.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
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
func triangles_of(model: Node3D) -> int:
    var count: int = 0
    for piece in model.find_children("*","MeshInstance3D",true,false):
        count += int(float((piece as MeshInstance3D).mesh.get_faces().size())/3.0)
    return count

func check_live_battle() -> void:
    var parent := Node3D.new()
    var state: Dictionary = {"units":[]}
    state[Identity.STATE_FIELD] = {"0":"dominio_turquesa","1":"orden_onix"}
    var cells: Dictionary = {}
    for i in range(12):
        var cell := Vector2i(i,0)
        var unit: Dictionary = Roles.make_unit("M01-%d" % i,0,cell,"patrol")
        if i == 10:
            unit["hp"] = 2
        state["units"].append(unit)
        cells[cell] = {"kind":"water","seen":true,"visible":true}
    var hidden_cell := Vector2i(12,0)
    state["units"].append(Roles.make_unit("M01-hidden",1,hidden_cell,"patrol"))
    cells[hidden_cell] = {"kind":"water","seen":true,"visible":false}
    var original: Dictionary = state.duplicate(true)
    var stats: Dictionary = Terrain._make_units(parent,state,cells,"M01-0",0)
    check(int(stats.get("patrol_visible",0)) == 12,"All twelve visible patrols retain native model")
    check(int(stats.get("patrol_lod8",0)) == 8,"Eight LOD8 and four LOD6")
    check(int(stats.get("hidden_enemies",0)) == 1,"Hidden enemy not exposed")
    var detailed: Node3D = parent.get_node_or_null("Unidad3D_M01-0") as Node3D
    var light: Node3D = parent.get_node_or_null("Unidad3D_M01-10") as Node3D
    check(detailed != null and light != null,"Both LODs present in battle renderer")
    if detailed != null and light != null:
        check(int(detailed.get_meta("patrol_lod",0)) == 8 and int(light.get_meta("patrol_lod",0)) == 6,"Correct battle LODs")
        check(triangles_of(light) < triangles_of(detailed),"Real LOD6 triangle reduction")
        check(int(light.get_meta("patrol_damage",-1)) == 3,"HP visual damage only")
        check(int(detailed.get_meta("tarvoka_patrol_visual_faction",-1)) == 6,"Chosen art faction")
        check(int(detailed.get_meta("faction",-1)) == 0,"Logical side preserved")
        check(detailed.scale.is_equal_approx(Vector3.ONE*0.64),"Fits grid cell")
        check(detailed.position.is_equal_approx(Terrain.world_at(Vector2i.ZERO)+Vector3(0,Terrain.height_at(cells,Vector2i.ZERO)-0.07,0)),"Waterline placement")
        print("M01 battle LOD6 triangles=",triangles_of(light)," LOD8 triangles=",triangles_of(detailed))
    check(not parent.has_node("Unidad3D_M01-hidden"),"Fog does not instantiate hidden enemy")
    check(state == original,"Battle state never mutated")
    parent.free()

func _run() -> void:
    check_live_battle()
    for faction in range(-1,8):
        var low_meshes: int = 0
        var low_triangles: int = 0
        for lod in [8,13]:
            var model: Node3D = Art.build("patrol",faction,true,lod)
            check(model != null,"Factory")
            if model == null:
                continue
            check(model.get_meta("patrol_art_revision","") == "1.6","Correct revision")
            for path in ["CascoNaval","CubiertaPatrulla","CabinaPatrulla/CarcasaCabina","CabinaPatrulla/FaccionTechoCabina"]:
                var part: MeshInstance3D = model.get_node_or_null(path) as MeshInstance3D
                check(part != null and closed(part.mesh),"Closed "+path)
            var roof: MeshInstance3D = model.get_node("CabinaPatrulla/FaccionTechoCabina") as MeshInstance3D
            if faction >= 0:
                check((roof.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Art.faction_paint_color(faction)),"Faction")
            check(model.has_node("BarandaPatrulla_1") == (lod >= 13),"LOD")
            var hull: Node3D = model.get_node("CascoNaval") as Node3D
            var rest: Transform3D = hull.transform
            var bounds: AABB = (hull as MeshInstance3D).mesh.get_aabb()
            check(bounds.position.z < -1.70 and bounds.end.z > 1.19,"Longer bow and unchanged stern")
            check(model.has_node("BordePatrulla_1_0") == (lod >= 13),"Deck relief LOD")
            check(model.has_node("RefuerzoCasco_1_0") == (lod >= 13),"Hull trim LOD")
            var cabin_panel: MeshInstance3D = model.get_node_or_null("CabinaPatrulla/FaccionPanelCabina_1") as MeshInstance3D
            check((cabin_panel != null) == (lod >= 13),"Cabin identity LOD")
            if cabin_panel != null and faction >= 0:
                check((cabin_panel.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Art.faction_paint_color(faction)),"Cabin panel faction")
            var meshes: int = Art.inspect_meshes(model)
            var triangles: int = 0
            for piece in model.find_children("*","MeshInstance3D",true,false):
                triangles += int(float((piece as MeshInstance3D).mesh.get_faces().size())/3.0)
            if lod == 8:
                low_meshes = meshes
                low_triangles = triangles
            else:
                check(low_meshes < meshes and low_triangles < triangles,"Reduced geometry in LOD8")
            if faction == 0:
                print("M01 LOD",lod,": meshes=",meshes," triangles=",triangles)
            var hatch: Node3D = model.get_node("RegistroPopaPatrulla") as Node3D
            var hatch_rest: Transform3D = hatch.transform
            check(model.has_node("CabinaPatrulla/PuertaTrasera"),"Aft cabin service relief")
            check(model.has_node("RotorPatrulla_1/CentroRotor"),"Visible underbody rotor")
            check(model.has_node("UnionRotor_1"),"Rotor shaft joins stern")
            check(model.has_node("MastilPatrulla/AntenaVisual_1") == (lod >= 13),"Mast detail LOD")
            var tongue: MeshInstance3D = model.get_node("DanoPatrulla/Fuego/FuegoLengua_0") as MeshInstance3D
            check((tongue.mesh as CylinderMesh).top_radius < (tongue.mesh as CylinderMesh).bottom_radius,"Tapered flame, not sphere")
            for part in model.find_children("*","MeshInstance3D",true,false):
                var mat: StandardMaterial3D = (part as MeshInstance3D).material_override as StandardMaterial3D
                check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,"Opaque material")
            var origin: Vector3 = model.position
            for stage in range(5):
                check(Art.set_patrol_damage(model,stage,0.7),"Damage")
                check(model.position == origin,"Tactical origin unchanged")
                check(int(model.get_meta("patrol_damage",-1)) == stage,"Damage state")
                if stage in [2,3]:
                    check(absf(hatch.rotation_degrees.z)>10,"Physical hatch damage")
                    var smoke: Node3D = model.get_node("DanoPatrulla/Humo") as Node3D
                    var rest_fx: Transform3D = smoke.transform
                    check(Art.animate_patrol_damage(model,0.25),"Persistent damage motion")
                    var moved: Transform3D = smoke.transform
                    check(not moved.is_equal_approx(rest_fx),"Smoke visibly moves")
                    Art.animate_patrol_damage(model,0.25)
                    check(smoke.transform.is_equal_approx(moved),"No cumulative effect drift")
                if stage == 3:
                    check(Art.pose_patrol(model,"move",0.25),"Critical cosmetic state does not disable gameplay pose")
                    check(int(model.get_meta("patrol_damage",-1)) == 3,"Motion preserves critical damage")
                if stage == 4:
                    check(hull.position.y < -1.0,"Sinking")
                    check(not Art.pose_patrol(model,"move",0.25),"No resurrection")
            Art.set_patrol_damage(model,0)
            check(hull.transform.is_equal_approx(rest),"Restore")
            check(hatch.transform.is_equal_approx(hatch_rest),"Hatch restored")
            check(not Art.animate_patrol_damage(model,0.25),"No effect animation after repair")
            check(Art.pose_model("patrol",model,"move",0.25),"Motion dispatch")
            check(absf((model.get_node("RotorPatrulla_1") as Node3D).rotation.z)>0.5,"Rotor movement")
            check(Art.pose_model("patrol",model,"attack",0.1,Vector2i(1,0)),"Action dispatch")
            var flash: Node3D = model.get_node("ModuloVisualPatrulla/DestelloVisual") as Node3D
            check(flash.visible,"Transient visual flash")
            Art.restore_model_pose("patrol",model)
            check(not flash.visible,"Flash cleared")
            check(Art.pose_model("patrol",model,"hit",0.12),"Impact pose dispatch")
            var hit: Node3D = model.get_node("DanoPatrulla/ImpactoVisualPatrulla") as Node3D
            check(hit.visible,"Transient impact")
            Art.restore_model_pose("patrol",model)
            check(not hit.visible,"Impact cleared")
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
    env.environment.ambient_light_color = Color("#C8D9E4")
    env.environment.ambient_light_energy = 0.85
    view.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55,-35,0)
    light.light_energy = 1.3
    view.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.3
    view.add_child(camera)
    camera.current = true
    var model: Node3D = Art.build("patrol",0,true,13)
    view.add_child(model)
    for i in range(16):
        camera.position = Vector3(4,3,-5) if i<5 else Vector3(-4,3,5)
        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
        Art.set_patrol_damage(model,i if i<5 else 0,0.55 if i==4 else 0.0)
        if i == 6:
            Art.pose_patrol(model,"move",0.25)
        if i >= 9:
            camera.size = 1.6
            camera.position = Vector3(2.5,1.7,3.0) if i != 11 else Vector3(2.2,-1.8,3.0)
            camera.look_at(Vector3(0,0.75,0.25) if i != 11 else Vector3(0,0.12,1.0),Vector3.UP)
            Art.set_patrol_damage(model,3 if i == 10 else 0)
        if i == 14 or i == 15:
            camera.size = 1.8
            camera.position = Vector3(2.4,2.1,3.4)
            camera.look_at(Vector3(0,0.88,0.22),Vector3.UP)
            if i == 14:
                Art.set_patrol_damage(model,3)
            else:
                Art.pose_patrol(model,"hit",0.12)
        if i == 12 or i == 13:
            camera.size = 1.7
            camera.position = Vector3(2.4,1.9,-3.5) if i == 12 else Vector3(-2.4,1.9,-3.5)
            camera.look_at(Vector3(0,0.55,-0.85),Vector3.UP)
        if i == 8:
            Art.pose_patrol(model,"attack",0.10)
            camera.size = 1.7
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
    Art.set_patrol_damage(model,0)
    camera.size = 2.8
    camera.position = Vector3(4,3,-5)
    camera.look_at(Vector3(0,0.35,0),Vector3.UP)
    var sea := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(14,14)
    sea.mesh = plane
    var water := StandardMaterial3D.new()
    water.albedo_color = Color("#315D72")
    sea.material_override = water
    sea.position.y = 0.03
    view.add_child(sea)
    model.hide()
    await process_frame
    await process_frame
    await process_frame
    var empty: Image = view.get_texture().get_image()
    model.show()
    for i in range(4):
        Art.set_patrol_damage(model,0 if i == 0 else 4,float(i)/3.0)
        await process_frame
        await process_frame
        await process_frame
        var frame: Image = view.get_texture().get_image()
        check(frame != null and not frame.is_empty(),"Waterline frame")
        if frame != null and not frame.is_empty():
            check(frame.save_png(output+"/patrol_sink_%d.png" % i)==OK,"Waterline saved")
            if empty != null and empty.get_size() == frame.get_size():
                var changed: int = 0
                for y in range(0,frame.get_height(),8):
                    for x in range(0,frame.get_width(),8):
                        var p: Color = empty.get_pixel(x,y)
                        var r: Color = frame.get_pixel(x,y)
                        if absf(p.r-r.r)+absf(p.g-r.g)+absf(p.b-r.b)>0.12:
                            changed += 1
                if i == 0:
                    check(changed>50,"Visible above sea")
                elif i == 3:
                    check(changed<10,"Complete submersion")
    view.queue_free()
    if issues > 0:
        quit(1)
    else:
        print("PASS M01 PATROL V1.6: 18 variants, 20 PNGs")
        quit(0)
