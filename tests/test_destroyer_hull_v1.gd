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

func _run() -> void:
    for faction in range(-1, 8):
        for lod in [8, 13]:
            var model: Node3D = Art.build("destroyer", faction, true, lod)
            check(model != null, "Destroyer builds")
            if model == null:
                continue
            check(model.get_meta("destroyer_art_revision", "") == "1.2", "V1.2 deck equipment active")
            for key in ["CascoNaval", "Cubierta", "Superestructura/ZocaloNaval", "Superestructura/CarcasaInferior", "Superestructura/Puente", "Superestructura/TechoPuente", "TorretaNavalPivot/CarcasaTorreta"]:
                var part: MeshInstance3D = model.get_node_or_null(key) as MeshInstance3D
                check(part != null, "Native " + key)
                if part != null:
                    check(_closed(part.mesh), "Closed shell " + key)
                    var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
                    check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque outward shell")
            for side in [-1, 1]:
                var badge: MeshInstance3D = model.get_node_or_null("FaccionIdentidadNaval_%d" % side) as MeshInstance3D
                check(badge != null, "Faction markings on both sides")
                if badge != null and faction >= 0:
                    check((badge.material_override as StandardMaterial3D).albedo_color == Art.faction_paint_color(faction), "Independent faction enamel")
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
            model.free()
    await _render()
    if failures != 0:
        quit(1)
        return
    print("PASS DESTROYER HULL V1.2: 18 variants, 6 PNGs")
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
    var angles: Array[Vector3] = [Vector3(5,4,-6),Vector3(-5,4,6),Vector3(3,2,-3),Vector3(-3,2,3),Vector3(2.6,2.8,-3.8),Vector3(-2.4,3.0,-2.0)]
    for i in range(6):
        camera.size = 5.1 if i < 2 else (2.0 if i < 4 else 1.85)
        camera.position = angles[i]
        camera.look_at(Vector3(0,0.7,0.15) if i < 2 else (Vector3(0,0.96,0.3) if i < 4 else Vector3(0,0.82,-0.78)),Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Real Godot image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v12_%d.png" % i) == OK, "Capture saved")
    view.queue_free()
