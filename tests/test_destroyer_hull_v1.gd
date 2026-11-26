extends SceneTree
const Art = preload("res://scripts/ui/UnitModels3D.gd")
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, label: String) -> void:
    if not value:
        failures += 1
        push_error(label)

func _closed(mesh: Mesh) -> bool:
    var edges: Dictionary = {}
    var vertices: PackedVector3Array = mesh.get_faces()
    for i in range(0, vertices.size(), 3):
        for j in range(3):
            var a: String = str(vertices[i + j])
            var b: String = str(vertices[i + (j + 1) % 3])
            var key: String = a + "|" + b if a < b else b + "|" + a
            edges[key] = int(edges.get(key, 0)) + 1
    if edges.is_empty():
        return false
    for n in edges.values():
        if n != 2:
            return false
    return true

# Godot uses clockwise front faces. A closed outward-wound volume
# therefore has negative signed volume under the mathematical convention.
func _outward(mesh: Mesh) -> bool:
    var v: PackedVector3Array = mesh.get_faces()
    var volume: float = 0.0
    for i in range(0,v.size(),3):
        volume += v[i].dot(v[i+1].cross(v[i+2])) / 6.0
    return volume < -0.0000001

func _check_surface(node: Node) -> void:
    if node is MeshInstance3D:
        var part: MeshInstance3D = node as MeshInstance3D
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        check(part.get_meta("destroyer_surface_v15",false), "Naval surface finish: " + str(part.name))
        check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque material: " + str(part.name))
    for child in node.get_children():
        _check_surface(child)

func _run() -> void:
    for faction in range(-1, 8):
        for lod in [8, 13]:
            var model: Node3D = Art.build("destroyer", faction, true, lod)
            check(model != null, "Destroyer builds")
            if model == null:
                continue
            check(model.get_meta("destroyer_art_revision", "") == "1.9", "V1.9 painted hull active")
            for key in ["CascoNaval", "Cubierta", "Superestructura/ZocaloNaval", "Superestructura/CarcasaInferior", "Superestructura/Puente", "Superestructura/TechoPuente", "TorretaNavalPivot/CarcasaTorreta", "TorreMastil/CarcasaMastil", "TorreMastil/RadarPivot/Radar", "ConjuntoPopa/Helipuerto", "ConjuntoPopa/Propulsion_-1/TimonPivot/TimonVisual", "ConjuntoPopa/Propulsion_1/TimonPivot/TimonVisual"]:
                var part: MeshInstance3D = model.get_node_or_null(key) as MeshInstance3D
                check(part != null, "Native " + key)
                if part != null:
                    check(_closed(part.mesh), "Closed shell " + key)
                    check(_outward(part.mesh), "Outward winding " + key)
                    var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
                    check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque outward shell")
            _check_surface(model)
            var hull: MeshInstance3D = model.get_node_or_null("CascoNaval") as MeshInstance3D
            if hull != null:
                check(hull.mesh.get_faces().size() == 188*3, "Twelve-point chamfered hull profile")
            check(not model.has_node("FaccionFranjaNaval"), "No overlapping stripe shell")
            if hull != null:
                var hull_mat: StandardMaterial3D = hull.material_override as StandardMaterial3D
                check(hull_mat.vertex_color_use_as_albedo, "Paint integrated into one hull")
                var indices: PackedInt32Array = hull.get_meta("destroyer_stripe_vertices")
                var colors: PackedColorArray = hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
                check(indices.size() == 84, "Two continuous painted bevels")
                for index in indices:
                    check(colors[index].is_equal_approx(Art.faction_paint_color(faction)), "Exact faction paint")
            var bridge: Node3D = model.get_node_or_null("Superestructura") as Node3D
            check(bridge != null, "Bridge present")
            if bridge != null:
                for i in range(3):
                    var pane: MeshInstance3D = bridge.get_node_or_null("CristalFrontal_%d" % i) as MeshInstance3D
                    check(pane != null, "Front opaque window")
                    if pane != null:
                        check((pane.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "No alpha glass")
                for side in [-1, 1]:
                    check(bridge.has_node("CristalLateral_%d_0" % side) and bridge.has_node("CristalLateral_%d_1" % side), "Both lateral panes")
                    check(bridge.has_node("FaccionPuente_%d" % side), "Bridge faction panel")
            var turret: Node3D = model.get_node_or_null("TorretaNavalPivot") as Node3D
            var base: MeshInstance3D = model.get_node_or_null("BaseTorreProa") as MeshInstance3D
            var collar: MeshInstance3D = model.get_node_or_null("AnilloTorreProa") as MeshInstance3D
            check(turret != null and base != null and collar != null, "Turret seated on deck mount")
            if base != null and collar != null and turret != null:
                check(base.position.y - (base.mesh as CylinderMesh).height * 0.5 <= 0.802, "Base meets deck")
                check(collar.position.y - (collar.mesh as CylinderMesh).height * 0.5 <= base.position.y + (base.mesh as CylinderMesh).height * 0.5, "Collar meets base")
                var pivot: Node3D = turret.get_node_or_null("CanonNavalPivot") as Node3D
                check(pivot != null, "Dedicated visual articulation")
                if pivot != null:
                    var shape: MeshInstance3D = pivot.get_node_or_null("CanonNaval") as MeshInstance3D
                    check(shape != null, "Visual attachment")
                    if shape != null:
                        var local: Transform3D = shape.transform
                        turret.rotation_degrees.y = 45.0
                        pivot.rotation_degrees.x = 10.0
                        check(shape.transform == local and turret.scale == Vector3.ONE and pivot.scale == Vector3.ONE, "Rigid transforms preserve local shape")
                        pivot.rotation_degrees.x = 0.0
                        turret.rotation_degrees.y = 0.0
            var module: Node3D = model.get_node_or_null("ModuloCubierta") as Node3D
            check(module != null, "Deck module")
            if module != null:
                for x in range(4):
                    for z in range(3):
                        check(module.has_node("TapaModulo_%d_%d" % [x,z]), "Closed module lid")
                        check(module.has_node("BisagraTapa_%d_%d" % [x,z]) == (lod >= 13), "Hinge LOD")
            var mast: Node3D = model.get_node_or_null("TorreMastil") as Node3D
            var radar: Node3D = model.get_node_or_null("TorreMastil/RadarPivot") as Node3D
            check(mast != null and radar != null, "Native mast and navigation pivot")
            if mast != null and radar != null:
                var panel: MeshInstance3D = radar.get_node("Radar") as MeshInstance3D
                var local: Transform3D = panel.transform
                var fixed: Transform3D = mast.transform
                for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
                    check(Art.pose_destroyer_radar(model, phase), "Visual sensor rotation")
                    check(radar.basis.is_equal_approx(Basis(Vector3.UP, fposmod(phase,1.0)*TAU)), "Deterministic radar phase")
                    check(panel.transform == local and mast.transform == fixed and radar.scale.is_equal_approx(Vector3.ONE), "Rigid sensor, fixed mast")
                check(radar.has_node("DetalleSensor_0") == (lod >= 13), "Sensor LOD")
                for side in [-1,1]:
                    check(model.has_node("LenteNavegacion_%d" % side) and model.has_node("BaseAntena_%d" % side), "Both navigation sides")
            var aft: Node3D = model.get_node_or_null("ConjuntoPopa") as Node3D
            check(aft != null, "Aft assembly")
            if aft != null:
                for side in [-1,1]:
                    var group: Node3D = aft.get_node_or_null("Propulsion_%d" % side) as Node3D
                    check(group != null, "Mirrored visual propulsion")
                    if group == null:
                        continue
                    var rotor: Node3D = group.get_node("HelicePivot") as Node3D
                    var rudder: Node3D = group.get_node("TimonPivot") as Node3D
                    var fixed: Transform3D = group.transform
                    var blade: Node3D = rotor.get_node("Lobulo_0") as Node3D
                    var local: Transform3D = blade.transform
                    for phase in [0.0,0.25,0.5,0.75,1.0]:
                        check(Art.pose_destroyer_aft(model,phase,phase*2.0-1.0), "Aft visual pose")
                        check(rotor.basis.is_equal_approx(Basis(Vector3.BACK,float(side)*fposmod(phase,1.0)*TAU)), "Independent rotor phase")
                        check(rudder.basis.is_equal_approx(Basis(Vector3.UP,deg_to_rad((phase*2.0-1.0)*25.0))), "Visual rudder pose")
                        check(group.transform == fixed and blade.transform == local and rotor.scale.is_equal_approx(Vector3.ONE), "Rigid aft assemblies")
                    check(aft.has_node("PasamanosPopa_%d" % side) == (lod >= 13), "Aft LOD")
                Art.pose_destroyer_aft(model,0.0,0.0)
            var motion_turret: Node3D = model.get_node("TorretaNavalPivot") as Node3D
            var motion_barrel: Node3D = motion_turret.get_node("CanonNavalPivot/CanonNaval") as Node3D
            var flash: Node3D = motion_turret.get_node("CanonNavalPivot/DestelloVisual") as Node3D
            var wake: Node3D = model.get_node("EstelaEspuma") as Node3D
            var base_position: Vector3 = model.position
            var base_scale: Vector3 = model.scale
            model.rotation_degrees.y = 30.0
            check(Art.pose_model("destroyer",model,"attack",0.10,Vector2i(1,0)), "Action pose dispatch")
            check(flash.visible and motion_barrel.position.z > -0.30, "Temporary visual action")
            check(Art.pose_model("destroyer",model,"move",0.25), "Navigation pose dispatch")
            check(not flash.visible and is_equal_approx(motion_barrel.position.z,-0.30), "Action cleared during navigation")
            check(not wake is MeshInstance3D, "No rectangular solid wake")
            check(model.has_node("AcabadoNavalV18/BordeCubierta_1_0"), "Fitted deck edge")
            check(model.has_node("AcabadoNavalV18/BarandaPasillo_1") == (lod >= 13), "Deck detail LOD")
            check(wake.get_child_count() == (5 if lod >= 13 else 2), "Wake detail tier")
            for patch in wake.get_children():
                check(patch.visible, "Dynamic wake visible")
            check(model.position == base_position and model.scale.is_equal_approx(base_scale) and absf(model.rotation_degrees.y-30.0)<0.01, "World position, scale and heading preserved")
            Art.restore_model_pose("destroyer",model)
            check(not flash.visible and motion_turret.rotation.is_zero_approx(), "Restored turret and effect")
            check(absf(model.rotation_degrees.x)<0.01 and absf(model.rotation_degrees.z)<0.01, "Restored hull attitude")
            for patch in wake.get_children():
                check(not patch.visible, "Restored wake")
            var fx: Node3D = model.get_node("DanoNavalVisual") as Node3D
            var hull_rest: Transform3D = hull.transform
            var mast_rest: Transform3D = mast.transform
            var lid: Node3D = model.get_node("ModuloCubierta/TapaModulo_3_2") as Node3D
            var lid_rest: Transform3D = lid.transform
            for hit_kind in ["damage","damaged","hit","hit_bullet","hit_blast"]:
                check(Art.pose_model("destroyer",model,hit_kind,0.5), "Temporary hit reaction")
                check(int(model.get_meta("destroyer_damage_stage",-1)) == 0, "Hits never manufacture persistent damage")
                Art.restore_model_pose("destroyer",model)
            check(Art.pose_model("destroyer",model,"hit_blast",0.2), "Distinct transient blast")
            check((fx.get_node("ImpactoAmplio") as Node3D).visible, "Blast effect appears")
            Art.restore_model_pose("destroyer",model)
            check(not (fx.get_node("ImpactoAmplio") as Node3D).visible, "Blast effect clears")
            for damage in range(5):
                check(Art.set_destroyer_damage(model,damage,0.50), "Damage stage applied")
                check(int(model.get_meta("destroyer_damage_stage",-1)) == damage, "Damage revision")
                check((fx.get_node("Marca_0") as Node3D).visible == (damage>=1), "Surface wear")
                check((fx.get_node("Humo_0") as Node3D).visible == (damage>=2), "Smoke stage")
                check((fx.get_node("Fuego_0") as Node3D).visible == (damage>=3), "Fire stage")
                check((fx.get_node("FragmentoCubierta") as Node3D).visible == (damage>=3), "Physical deck fragment")
                if damage in [2,3]:
                    check(absf(mast.rotation_degrees.z)>10.0, "Visible mast damage")
                    check(absf(lid.rotation_degrees.z)>10.0, "Visible displaced deck lid")
                if damage == 4:
                    check(hull.position.y < -0.9, "Visual sinking")
                    var sunk: Transform3D = hull.transform
                    check(not Art.pose_model("destroyer",model,"move",0.25), "Destroyed model rejects navigation")
                    Art.restore_model_pose("destroyer",model)
                    check(hull.transform.is_equal_approx(sunk), "Restore cannot resurrect")
                    Art.set_destroyer_damage(model,4,0.5)
                    check(hull.transform.is_equal_approx(sunk), "No accumulated sinking")
                check(model.position == base_position and model.scale.is_equal_approx(base_scale), "Damage preserves tactical transform")
            check(Art.set_destroyer_damage(model,0), "Reset damage")
            check(hull.transform.is_equal_approx(hull_rest) and mast.transform.is_equal_approx(mast_rest), "Original geometry restored")
            check(lid.transform.is_equal_approx(lid_rest), "Deck detail restored")
            model.free()
    await _render()
    if failures != 0:
        quit(1)
        return
    print("PASS DESTROYER HULL V1.9: 18 variants, 23 PNGs")
    quit(0)

func _render() -> void:
    var output: String = ProjectSettings.globalize_path("res://build/qa/destroyer-v1")
    check(DirAccess.make_dir_recursive_absolute(output) == OK, "Render directory")
    var view := SubViewport.new()
    view.size = Vector2i(900, 650)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var stage := Node3D.new()
    view.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#263A48")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#DDE9EF")
    env.environment.ambient_light_energy = 0.75
    stage.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50,-35,0)
    light.light_energy = 1.4
    stage.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.current = true
    stage.add_child(camera)
    var model: Node3D = Art.build("destroyer", 0, true, 13)
    check(model != null, "Render model")
    if model == null:
        view.queue_free()
        return
    stage.add_child(model)
    var angles: Array[Vector3] = [Vector3(5,4,-6),Vector3(-5,4,6),Vector3(3,2,-3),Vector3(-3,2,3),Vector3(2.6,2.8,-3.8),Vector3(-2.4,3.0,-2.0),Vector3(2.4,2.6,-1.7),Vector3(-2.4,2.5,2.1),Vector3(2.8,2.7,3.8),Vector3(-2.2,-1.4,3.2),Vector3(3.0,0.45,-0.8),Vector3(-3.0,0.55,0.9),Vector3(5.0,3.6,6.0),Vector3(2.4,2.2,-3.5),Vector3(2.1,2.0,0.3),Vector3(-2.1,1.2,3.1)]
    for i in range(16):
        camera.size = 3.6 if i < 2 else (2.0 if i < 4 else (1.85 if i < 6 else 1.4))
        camera.position = angles[i]
        camera.look_at(Vector3(0,0.7,0.15) if i < 2 else (Vector3(0,0.96,0.3) if i < 4 else (Vector3(0,0.82,-0.78) if i < 6 else Vector3(0,1.45,0.22))),Vector3.UP)
        if i >= 14:
            Art.restore_model_pose("destroyer",model)
            camera.size = 1.7
            camera.look_at(Vector3(0.39,0.63,0.28) if i == 14 else Vector3(0,0.3,1.30),Vector3.UP)
        elif i >= 12:
            model.get_node("EstelaEspuma").show()
            camera.size = 3.8 if i == 12 else 2.0
            camera.look_at(Vector3(0,0.65,0.2) if i == 12 else Vector3(0,0.85,-1.0),Vector3.UP)
            Art.pose_model("destroyer",model,"move" if i == 12 else "attack",0.25 if i == 12 else 0.10)
        elif i >= 10:
            camera.size = 2.1
            camera.look_at(Vector3(0,0.44,0.02),Vector3.UP)
        elif i >= 8:
            camera.look_at(Vector3(0,0.55 if i == 8 else 0.04,1.03),Vector3.UP)
            model.get_node("EstelaEspuma").hide()
            Art.pose_destroyer_aft(model,0.25*float(i-8),0.5)
        elif i >= 6:
            Art.pose_destroyer_radar(model, 0.25 * float(i - 6))
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Real Godot image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v19_%d.png" % i) == OK, "Capture saved")
    Art.restore_model_pose("destroyer",model)
    for d in range(5):
        Art.set_destroyer_damage(model,d,0.52 if d == 4 else 0.0)
        camera.position = Vector3(5,3.5,-6)
        camera.size = 3.8
        camera.look_at(Vector3(0,0.4 if d < 4 else -0.35,0),Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Damage image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v19_D%d.png" % d) == OK, "Damage capture saved")
    for d in [2,3]:
        Art.set_destroyer_damage(model,d)
        camera.position = Vector3(3.0,2.7,3.1)
        camera.size = 2.3
        camera.look_at(Vector3(0,1.0,0.45),Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Close damage image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v19_detail_D%d.png" % d) == OK, "Close damage capture")
    view.queue_free()
