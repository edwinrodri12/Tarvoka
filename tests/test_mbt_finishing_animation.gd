extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Materials = preload("res://scripts/ui/TankSurface3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Captures = preload("res://scripts/ui/UnitRender3D.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tank: Node3D = Models.build("tank",0)
    assert(tank != null)
    assert(Models.inspect_meshes(tank) >= 100)
    assert(Models.paintable_count(tank) == 14)
    assert(tank.get_meta("tarvoka_pbr_applied",false))
    assert(Rig.has_rig(tank))
    var armor: MeshInstance3D = tank.find_child("MonocascoBlindajeCompuesto",true,false) as MeshInstance3D
    var tracks: MeshInstance3D = tank.find_child("BandaOruga-1",true,false) as MeshInstance3D
    var painted: MeshInstance3D = tank.find_child("FaccionFaldon-1_00",true,false) as MeshInstance3D
    var sensor: MeshInstance3D = tank.find_child("CristalTermico",true,false) as MeshInstance3D
    assert(armor != null and tracks != null and painted != null and sensor != null)
    for element in [armor,tracks,painted,sensor]:
        var material: StandardMaterial3D = element.material_override as StandardMaterial3D
        assert(material != null and material.albedo_texture != null)
        assert(material.normal_enabled and material.normal_texture != null)
        assert(material.roughness > 0.0 and material.roughness < 1.0)
    assert(armor.material_override.roughness > sensor.material_override.roughness)
    assert(tracks.material_override.roughness > armor.material_override.roughness)
    assert(Models.apply_faction_palette(tank,4) == 14)
    assert(painted.material_override.albedo_texture != null)
    assert(painted.material_override.albedo_color == Models.faction_paint_color(4))
    assert(armor.material_override.albedo_color != painted.material_override.albedo_color)

    var turret: Node3D = tank.find_child(Models.TANK_TURRET,true,false) as Node3D
    var gun: Node3D = tank.find_child(Models.TANK_BARREL_PIVOT,true,false) as Node3D
    var wheel: MeshInstance3D = tank.find_child("Rodillo-1_00",true,false) as MeshInstance3D
    assert(turret != null and gun != null and wheel != null)
    var flash_fx: Node3D = tank.find_child("EfectoFogonazoCanon",true,false) as Node3D
    var smoke_fx: Node3D = tank.find_child("EfectoHumoCanon",true,false) as Node3D
    var dust_fx: Node3D = tank.find_child("EfectoPolvoOrugas",true,false) as Node3D
    var impact_fx: Node3D = tank.find_child("EfectoImpactoBlindaje",true,false) as Node3D
    assert(flash_fx != null and smoke_fx != null and dust_fx != null and impact_fx != null)
    assert(not flash_fx.visible and not smoke_fx.visible and not dust_fx.visible and not impact_fx.visible)
    var light_mesh: MeshInstance3D = tank.find_child("NucleoLuminoso",true,false) as MeshInstance3D
    var smoke_mesh: MeshInstance3D = tank.find_child("NubeHumo",true,false) as MeshInstance3D
    assert(light_mesh.material_override.emission_enabled)
    assert(smoke_mesh.material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
    var rest_y: float = tank.position.y
    var wheel_at_rest: Basis = wheel.transform.basis
    assert(Rig.pose(tank,"move",0.18,Vector2i(1,0)))
    assert(tank.position.y < rest_y)
    assert(not wheel.transform.basis.is_equal_approx(wheel_at_rest))
    assert(tracks.material_override.uv1_offset.y > 0.0)
    assert(dust_fx.visible and not flash_fx.visible)
    assert(Rig.pose(tank,"attack",0.15,Vector2i(1,0)))
    assert(absf(turret.rotation_degrees.y) > 15.0)
    assert(gun.rotation_degrees.x >= 4.0)
    assert(gun.position.z > -0.56)
    assert(flash_fx.visible and smoke_fx.visible and not dust_fx.visible)
    assert(Rig.pose(tank,"damaged",0.35))
    assert(not is_zero_approx(tank.rotation_degrees.z))
    assert(impact_fx.visible and not flash_fx.visible)
    Rig.restore(tank)
    assert(not impact_fx.visible and not smoke_fx.visible)
    assert(is_equal_approx(tank.position.y,rest_y))
    assert(is_zero_approx(turret.rotation_degrees.y))
    assert(is_zero_approx(gun.rotation_degrees.x))
    tank.free()

    # Real OpenGL: a battle must show animated 3D action frames only for
    # units currently visible to the human; no stale hidden enemy contacts.
    var capture: Node = Captures.new()
    root.add_child(capture)
    capture.call("prepare")
    for i in range(8):
        await process_frame
    assert(capture.captures_completed)
    var own_pos := Vector2i(2,3)
    var enemy_pos := Vector2i(7,3)
    var units: Array = [
        {"id":"T-01","role":"tank","faction":0,"pos":own_pos,"hp":14},
        {"id":"T-02","role":"tank","faction":1,"pos":enemy_pos,"hp":14}
    ]
    var vision: Dictionary = {own_pos:true}
    var movement: Array = [
        {"id":"T-01","from":Vector2i(1,3),"to":own_pos,"elapsed":0.09},
        {"id":"T-02","from":Vector2i(8,3),"to":enemy_pos,"elapsed":0.09}
    ]
    capture.call("update_tank_actions",units,movement,[],true,vision,false)
    assert(capture.call("live_tank_count") == 1)
    assert(capture.live_tank_models.has("T-01"))
    assert(not capture.live_tank_models.has("T-02"))
    assert(capture.call("texture_for","tank",0,"T-01") != null)
    var rendered := Image.create(Captures.LIVE_CAPTURE_SIZE.x*3,
        Captures.LIVE_CAPTURE_SIZE.y,false,Image.FORMAT_RGBA8)
    rendered.fill(Color("#152734"))
    var signatures: Dictionary = {}
    for frame in range(3):
        if frame == 1:
            capture.call("update_tank_actions",units,[
                {"id":"T-01","from":Vector2i(1,3),"to":own_pos,"elapsed":0.20}
            ],[],true,vision,false)
        elif frame == 2:
            capture.call("update_tank_actions",units,[],[
                {"attacker_role":"tank","origin":own_pos,
                "target":Vector2i(5,2),"elapsed":0.09}
            ],true,vision,false)
        for tick in range(3):
            await process_frame
        var tex: Texture2D = capture.call("texture_for","tank",0,"T-01") as Texture2D
        assert(tex != null)
        var img: Image = tex.get_image()
        assert(img != null and img.get_size() == Captures.LIVE_CAPTURE_SIZE)
        var has_pixels := false
        for y in range(0,img.get_height(),9):
            for x in range(0,img.get_width(),9):
                if img.get_pixel(x,y).a > 0.1:
                    has_pixels = true
                    break
            if has_pixels:
                break
        assert(has_pixels)
        signatures[hash(img.get_data())] = true
        rendered.blit_rect(img,Rect2i(Vector2i.ZERO,Captures.LIVE_CAPTURE_SIZE),
            Vector2i(frame*Captures.LIVE_CAPTURE_SIZE.x,0))
    assert(signatures.size() >= 2) # Actual model transforms change rendered pixels.
    var model: Node3D = capture.live_tank_models["T-01"] as Node3D
    assert(model != null)
    var live_turret: Node3D = model.find_child(Models.TANK_TURRET,true,false) as Node3D
    assert(live_turret != null and absf(live_turret.rotation_degrees.y) > 1.0)
    assert(capture.live_tank_render_updates >= 3)
    assert(capture.call("live_tank_count") <= Captures.MAX_LIVE_TANKS)
    var both_visible: Dictionary = {own_pos:true,enemy_pos:true}
    capture.call("update_tank_actions",units,[],[
        {"attacker_role":"tank","defender_role":"tank",
        "origin":own_pos,"target":enemy_pos,"elapsed":0.20}
    ],true,both_visible,false)
    assert(capture.call("live_tank_count") == 2)
    var defender: Node3D = capture.live_tank_models["T-02"] as Node3D
    var impact: Node3D = defender.find_child("EfectoImpactoBlindaje",true,false) as Node3D
    assert(impact != null and impact.visible)
    capture.call("update_tank_actions",units,[],[
        {"attacker_role":"tank","defender_role":"tank",
        "origin":own_pos,"target":enemy_pos,"elapsed":0.20}
    ],true,vision,false)
    assert(capture.call("live_tank_count") == 1) # Hidden enemy is never animated.
    capture.call("update_tank_actions",units,[],[],true,vision,false)
    assert(capture.call("live_tank_count") == 0)
    assert(capture.call("parked_tank_count") == 1)
    var frozen: Texture2D = capture.call("texture_for","tank",0,"T-01") as Texture2D
    assert(frozen != null and frozen != capture.call("texture_for","tank",0))
    for settle in range(3):
        await process_frame
    var parked_model: Node3D = capture.parked_tank_models["T-01"] as Node3D
    var previous_viewport: SubViewport = capture.parked_tank_viewports["T-01"] as SubViewport
    assert(parked_model != null and Rig.has_rig(parked_model))
    assert(capture.parked_tank_viewports["T-01"].render_target_update_mode != SubViewport.UPDATE_ALWAYS)
    # A new move reuses the same viewport and its expensive 3D mesh.
    capture.call("update_tank_actions",units,movement,[],true,vision,false)
    assert(capture.call("live_tank_count") == 1)
    assert(capture.live_tank_viewports["T-01"] == previous_viewport)
    capture.call("update_tank_actions",units,movement,[],true,vision,true)
    assert(capture.call("live_tank_count") == 0)
    assert(capture.call("parked_tank_count") == 0)
    assert(capture.call("texture_for","tank",0,"T-01") == capture.call("texture_for","tank",0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(rendered.save_png("res://artifacts/tarvoka_mbt_live_animation_frames.png") == OK)
    capture.queue_free()

    # Materials are deterministic, reproducible and small enough to ship
    # without an external service or an expensive texture download.
    var color_tex: ImageTexture = Materials.make_albedo(Materials.SURFACE_ARMOR)
    var normal_tex: ImageTexture = Materials.make_normal(Materials.SURFACE_ARMOR)
    assert(color_tex.get_size() == Vector2(Materials.TILE_SIZE,Materials.TILE_SIZE))
    assert(normal_tex.get_size() == color_tex.get_size())
    assert(Materials.make_albedo(Materials.SURFACE_ARMOR).get_image().get_data()
        == color_tex.get_image().get_data())
    assert(VisualStyle.FACTIONS.size() == 8)
    print("PASS MBT finish: UV/PBR surfaces, modular paint, turret/recoil, tracked motion and real fog-safe Android combat captures")
    print("MBT animated frames: " + str(signatures.size()) + " unique frames, " + str(capture.live_tank_render_updates) + " updates")
    quit(0)
