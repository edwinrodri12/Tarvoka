extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Captures = preload("res://scripts/ui/UnitRender3D.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const IsoRenderer = preload("res://scripts/ui/IsoRenderer.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Models.ROLES.size()==8)
    assert(Models.ROLES.size() == Models.ROLES.duplicate().size())
    var labels: Dictionary = {}
    var geometry_counts: Dictionary = {}
    for role in Models.ROLES:
        assert(Roles.valid(str(role)))
        assert(Models.supports(str(role)))
        assert(Models.production_asset_path(str(role)) == "res://assets/units3d/" + str(role) + ".glb")
        var model: Node3D = Models.build(str(role))
        assert(model != null and model is Node3D)
        assert(model.name == "Modelo3D_" + str(role))
        var parts: int = Models.inspect_meshes(model)
        assert(parts >= 12) # Actual modelled solids; never 2D decals.
        geometry_counts[role] = parts
        labels[role] = Roles.label(str(role))
        var physical: Array = model.find_children("*","MeshInstance3D",true,false)
        assert(physical.size() >= 12)
        for shape in physical:
            assert(shape.mesh != null)
            # Run with real software OpenGL via xvfb; inspect geometry types.
            assert(shape.mesh is PrimitiveMesh or shape.mesh is ArrayMesh)
            assert(shape.material_override != null)
            assert(shape is MeshInstance3D)
        model.free()

    # Distinct authorized silhouettes, not 8 aliases of the same sprite.
    assert(int(geometry_counts["mlrs"]) != int(geometry_counts["line"]))
    assert(int(geometry_counts["tank"]) != int(geometry_counts["fighter"]))
    assert(labels["tank"] == "Tanque principal")
    assert(Models.build("nonexistent") == null)
    var tank_blue: Node3D = Models.build("tank",0)
    var tank_red: Node3D = Models.build("tank",1)
    assert(tank_blue != null and tank_red != null)
    assert(Models.inspect_meshes(tank_blue) >= 100)
    assert(Models.paintable_count(tank_blue) >= 12)
    assert(Models.paintable_count(tank_blue) == Models.paintable_count(tank_red))
    var blue_paint: MeshInstance3D = tank_blue.find_child("FaccionFaldon-1_00",true,false) as MeshInstance3D
    var red_paint: MeshInstance3D = tank_red.find_child("FaccionFaldon-1_00",true,false) as MeshInstance3D
    assert(blue_paint != null and red_paint != null)
    assert(blue_paint.material_override.albedo_color == Models.faction_paint_color(0))
    assert(red_paint.material_override.albedo_color == Models.faction_paint_color(1))
    var neutral_hull: MeshInstance3D = tank_blue.find_child("MonocascoBlindajeCompuesto",true,false) as MeshInstance3D
    var red_hull: MeshInstance3D = tank_red.find_child("MonocascoBlindajeCompuesto",true,false) as MeshInstance3D
    assert(neutral_hull != null and red_hull != null)
    assert(neutral_hull.material_override.albedo_color == red_hull.material_override.albedo_color)
    var turret: Node3D = tank_blue.find_child(Models.TANK_TURRET,true,false) as Node3D
    var gun: Node3D = tank_blue.find_child(Models.TANK_BARREL_PIVOT,true,false) as Node3D
    assert(turret != null and gun != null)
    assert(gun.get_parent() == turret)
    turret.rotation_degrees.y = 45.0
    gun.rotation_degrees.x = -6.0
    assert(is_equal_approx(turret.rotation_degrees.y,45.0))
    assert(is_equal_approx(gun.rotation_degrees.x,-6.0))
    var material_before: Color = blue_paint.material_override.albedo_color
    assert(Models.apply_faction_palette(tank_red,7) == Models.paintable_count(tank_red))
    assert(blue_paint.material_override.albedo_color == material_before) # No shared resource mutation.
    for faction in range(8):
        var tank_sample: Node3D = Models.build("tank",faction)
        assert(tank_sample != null)
        assert(Models.paintable_count(tank_sample) >= 12)
        tank_sample.free()
    tank_blue.free()
    tank_red.free()
    for role in Roles.ORDER + Arsenal.ORDER:
        if role not in Models.ROLES:
            assert(not Models.supports(str(role)))
    # The renderer is loaded and coupled to the same unit-role identifiers as
    # tactics; 24 other roles retain the original atlas until remodeled.
    assert(IsoRenderer != null)
    assert(Captures.SIZE == Vector2i(224,224))

    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(950,640)
    root.add_child(board)
    var original: Dictionary = board.state.duplicate(true)
    board.set_isometric(true)
    board.set_3d_models_enabled(false)
    assert(not board.models_3d_enabled)
    assert(board.state == original)
    board.set_3d_models_enabled(true)
    assert(board.models_3d_enabled)
    assert(board.state == original)
    var library: Node = board._models_3d
    assert(library != null) # Real software OpenGL, not Godot dummy headless.
    for i in range(5):
        await process_frame
    assert(bool(library.get("captures_completed")))
    assert(int(library.get("baked_static_captures")) == 15)
    assert((library.get("viewports") as Dictionary).is_empty())
    var sheet := Image.create(Captures.SIZE.x*4,Captures.SIZE.y*2,false,Image.FORMAT_RGBA8)
    sheet.fill(Color("#13212c"))
    var nonempty: int = 0
    for n in range(Models.ROLES.size()):
        var role: String = str(Models.ROLES[n])
        assert(library.call("is_ready_for",role))
        var tex: Texture2D = library.call("texture_for",role)
        assert(tex != null and tex.get_size() == Vector2(Captures.SIZE))
        var img: Image = tex.get_image()
        assert(img != null and img.get_size() == Captures.SIZE)
        var visible: int = 0
        for y in range(0,img.get_height(),8):
            for x in range(0,img.get_width(),8):
                if img.get_pixel(x,y).a > 0.1:
                    visible += 1
        nonempty += 1 if visible > 4 else 0
        var dst := Vector2i((n%4)*Captures.SIZE.x,int(n/4)*Captures.SIZE.y)
        sheet.blit_rect(img,Rect2i(Vector2i.ZERO,Captures.SIZE),dst)
    assert(nonempty == 8) # Every model really has visible 3D pixels.
    var paint_sheet := Image.create(Captures.SIZE.x*4,Captures.SIZE.y*2,false,Image.FORMAT_RGBA8)
    paint_sheet.fill(Color("#13212c"))
    var seen: Dictionary = {}
    for faction in range(8):
        assert(library.call("is_ready_for","tank",faction))
        var texture: Texture2D = library.call("texture_for","tank",faction) as Texture2D
        assert(texture != null)
        var visual: Image = texture.get_image()
        assert(visual != null and not visual.is_empty())
        var signature: int = hash(visual.get_data())
        assert(not seen.has(signature)) # Distinct genuine rendered materials for every faction.
        seen[signature] = faction
        paint_sheet.blit_rect(visual,Rect2i(Vector2i.ZERO,Captures.SIZE),
            Vector2i((faction%4)*Captures.SIZE.x,int(faction/4)*Captures.SIZE.y))
    assert(seen.size() == 8)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(paint_sheet.save_png("res://artifacts/tarvoka_mbt_8_faction_colors.png") == OK)
    assert(sheet.save_png("res://artifacts/tarvoka_3d_first8.png") == OK)
    board.queue_redraw()
    await process_frame
    assert(board.state == original)
    # The key release criterion: an actual modern-army battle consumes the
    # captured Godot 3D textures instead of silently falling back to 2D.
    board.new_game(0,true,false,false,true,false,true)
    board.set_isometric(true)
    board.queue_redraw()
    await process_frame
    assert(int(IsoRenderer.last_frame_stats.get("real_3d_units_drawn",0)) >= 2)
    var real_battle: Dictionary = board.state.duplicate(true)
    var battle_damaged: Dictionary = real_battle.duplicate(true)
    battle_damaged["units"][0]["hp"] = 2
    board.state = battle_damaged
    board.queue_redraw()
    await process_frame
    # Taking damage must never make 3D models turn back into old 2D frames.
    assert(int(IsoRenderer.last_frame_stats.get("real_3d_units_drawn",0)) >= 2)
    board.state = real_battle
    board.set_3d_models_enabled(false)
    board.queue_redraw()
    await process_frame
    assert(int(IsoRenderer.last_frame_stats.get("real_3d_units_drawn",0)) == 0)
    assert(board.state == real_battle)
    board.queue_free()

    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var app: Control = scene.instantiate()
    root.add_child(app)
    var ui_button: Button = app.get("models_3d_button")
    var live_board: Control = app.get("board")
    assert(ui_button != null)
    assert(live_board.models_3d_enabled)
    var save_state: Dictionary = live_board.state.duplicate(true)
    app._toggle_unit_models_3d()
    assert(not live_board.models_3d_enabled)
    assert(ui_button.text.contains("desactivados"))
    assert(live_board.state == save_state)
    app._toggle_unit_models_3d()
    assert(live_board.models_3d_enabled)
    assert(ui_button.text.contains("activados"))
    assert(live_board.state == save_state)
    var inspector = app.get("unit_3d_inspector")
    assert(inspector != null and app.get("unit_3d_inspector_button") != null)
    app._open_unit_3d_inspector()
    await process_frame
    assert(inspector.visible and inspector.model_root != null)
    assert(inspector._current_role == "line")
    inspector.rotate_model(45.0)
    assert(is_equal_approx(inspector.model_root.rotation_degrees.y,45.0))
    inspector.show_role("tank")
    assert(inspector._current_role == "tank")
    assert(Models.inspect_meshes(inspector.model_root) >= 100)
    assert(inspector.faction_paint_picker.visible)
    assert(inspector.faction_paint_picker.item_count == 8)
    inspector.set_faction_paint(4)
    assert(inspector._selected_faction == 4)
    var panel: MeshInstance3D = inspector.model_root.find_child("FaccionPlacaSuperior-1",true,false) as MeshInstance3D
    assert(panel != null and panel.material_override.albedo_color == Models.faction_paint_color(4))
    inspector.rotate_tank_turret(50.0)
    var live_turret: Node3D = inspector.model_root.find_child(Models.TANK_TURRET,true,false) as Node3D
    assert(live_turret != null and is_equal_approx(live_turret.rotation_degrees.y,50.0))
    assert(is_equal_approx(inspector.camera.size,Models.preview_frame_height("tank")))
    var before_zoom: float = inspector.camera.size
    inspector.change_zoom(1)
    assert(inspector.camera.size < before_zoom)
    inspector.rotate_model(30.0)
    assert(is_equal_approx(inspector.model_root.rotation_degrees.y,30.0))
    inspector.reset_rotation()
    assert(is_zero_approx(inspector.model_root.rotation_degrees.y))
    assert(is_equal_approx(inspector.camera.size,before_zoom))
    for i in range(3):
        await process_frame
    print("VISOR3D screen=",app.get_viewport().get_visible_rect().size,
        " dialog=",inspector.size," top=",inspector.position,
        " preview=",inspector.viewport_holder.size," camera=",inspector.camera.size)
    assert(inspector.viewport_holder.size.y >= 200.0)
    assert(inspector.viewport_holder.size.y <= 335.0)
    assert(inspector.position.y >= -2)
    assert(inspector.position.y + inspector.size.y <= app.get_viewport().get_visible_rect().size.y + 4)
    var inspector_image: Image = app.get_viewport().get_texture().get_image()
    assert(inspector_image != null and not inspector_image.is_empty())
    assert(inspector_image.save_png("res://artifacts/tarvoka_3d_inspector_android.png") == OK)
    print("VISOR3D: dialog=",inspector.size," preview=",inspector.viewport_holder.size,
        " model_camera=",inspector.camera.size)
    assert(live_board.state == save_state)
    inspector.hide()
    app.queue_free()

    print("PASS native 3D models: 8 editable unit meshes, role integration, 2D fallback, untouched battle/Android UI")
    print("3D geometry counts: " + str(geometry_counts))
    quit(0)
