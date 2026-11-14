extends SceneTree

# V17 is a true Godot model and destruction pass, not an illustration.
# Regression checks validate render changes and bound the visual-card budget.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const FX = preload("res://scripts/ui/TankFXV17.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(8):
        await process_frame
    var frame: Image = studio.preview.get_texture().get_image()
    assert(frame != null and not frame.is_empty())
    frame.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return frame

func _pixel_delta(before: Image,after: Image) -> int:
    var total: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = before.get_pixel(x,y)
            var b: Color = after.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.13:
                total+=1
    return total

func _pair(left: Image,right: Image,filename: String) -> void:
    var combined := Image.create(960,330,false,Image.FORMAT_RGBA8)
    combined.blit_rect(left,Rect2i(0,0,480,330),Vector2i.ZERO)
    combined.blit_rect(right,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(combined.save_png(filename)==OK)

func _run() -> void:
    var base: Node3D = Models.build("tank",0,true,16)
    var upgraded: Node3D = Models.build("tank",0,true,17)
    var stable: Node3D = Models.build("tank",0,true)
    assert(base != null and upgraded != null and stable != null)
    assert(not base.get_meta("tarvoka_mbt_fx_v17",false))
    assert(not stable.get_meta("tarvoka_mbt_fx_v17",false))
    assert(upgraded.get_meta("tarvoka_mbt_fx_v17",false))
    assert(int(upgraded.get_meta("tarvoka_mbt_fx_v17_smoke_count",0))==6)
    assert(int(upgraded.get_meta("tarvoka_mbt_fx_v17_fire_count",0))==5)
    assert(Models.paintable_count(upgraded)==14)
    assert(FX.count_transparent_cards(upgraded)==11)

    var texture: Texture2D = null
    for i in range(6):
        var name: String = "G09V17Humo_%02d" % i
        var smoke: MeshInstance3D = upgraded.find_child(
            name,true,false) as MeshInstance3D
        assert(smoke != null and smoke.mesh is QuadMesh)
        var original: Node3D = upgraded.find_child(
            FX.SMOKE_LABELS[i],true,false) as Node3D
        assert(original != null and not original.visible)
        var pbr: StandardMaterial3D = smoke.material_override as StandardMaterial3D
        assert(pbr != null and pbr.albedo_texture != null)
        assert(pbr.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
        assert(pbr.billboard_mode == BaseMaterial3D.BILLBOARD_ENABLED)
        assert(not pbr.emission_enabled)
        if texture == null:
            texture = pbr.albedo_texture
        else:
            assert(texture == pbr.albedo_texture)
    assert(texture.get_width()==96 and texture.get_height()==128)
    for i in range(5):
        var flame: MeshInstance3D = upgraded.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        var old: MeshInstance3D = base.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        assert(flame != null and old != null)
        var new_mat: StandardMaterial3D = flame.material_override as StandardMaterial3D
        var old_mat: StandardMaterial3D = old.material_override as StandardMaterial3D
        assert(new_mat.emission_energy_multiplier < old_mat.emission_energy_multiplier)

    assert(Damage.apply_stage(upgraded,4))
    var first: MeshInstance3D = upgraded.find_child(
        "G09V17Humo_00",true,false) as MeshInstance3D
    var origin: Vector3 = first.position
    Damage.animate_smoke(upgraded,2.14)
    assert(first.position.distance_to(origin)>0.02)
    var micros_start: int = Time.get_ticks_usec()
    for n in range(120):
        Damage.animate_smoke(upgraded,float(n)/30.0)
    var full_micros: int = Time.get_ticks_usec()-micros_start
    assert(FX.set_quality(upgraded,true))
    assert(FX.count_transparent_cards(upgraded)==6)
    var eco_start: int = Time.get_ticks_usec()
    for n in range(120):
        Damage.animate_smoke(upgraded,float(n)/30.0)
    var eco_micros: int = Time.get_ticks_usec()-eco_start
    assert(Damage.apply_stage(upgraded,0))
    for hp in range(5):
        assert(Damage.apply_stage(upgraded,hp))
    assert(Damage.apply_stage(upgraded,0))
    assert(Rig.has_rig(upgraded))
    assert(Rig.pose(upgraded,"move",0.45,Vector2i(1,0)))
    assert(Rig.pose(upgraded,"attack",0.45,Vector2i(1,0)))
    Rig.restore(upgraded)
    for faction in range(8):
        assert(Models.apply_faction_palette(upgraded,faction)==14)
    assert(FX.set_quality(upgraded,false))
    assert(FX.count_transparent_cards(upgraded)==11)
    base.free()
    stable.free()
    upgraded.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v16()
    assert(studio._v16_preview)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._set_damage(4)
    var v16_fire: Image = await _capture(studio)
    studio._toggle_v17()
    assert(studio._v17_preview and not studio._v16_preview)
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(Damage.current_stage(studio.model_root)==4)
    var v17_fire: Image = await _capture(studio)
    var delta_fire: int = _pixel_delta(v16_fire,v17_fire)
    assert(delta_fire>70)
    _pair(v16_fire,v17_fire,
        "res://artifacts/tarvoka_g09_v16_v17_fire_same_camera.png")

    studio._set_damage(3)
    var v17_critical: Image = await _capture(studio)
    studio._toggle_v17()
    assert(studio._v16_preview)
    var v16_critical: Image = await _capture(studio)
    var delta_smoke: int = _pixel_delta(v16_critical,v17_critical)
    assert(delta_smoke>50)
    _pair(v16_critical,v17_critical,
        "res://artifacts/tarvoka_g09_v16_v17_smoke_same_camera.png")

    studio._toggle_v17()
    assert(studio._v17_preview)
    studio._set_damage(4)
    var full: Image = await _capture(studio)
    studio._toggle_v17_quality()
    assert(studio._v17_eco)
    assert(FX.count_transparent_cards(studio.model_root)==6)
    var eco: Image = await _capture(studio)
    var delta_eco: int = _pixel_delta(full,eco)
    assert(delta_eco>15)
    _pair(full,eco,
        "res://artifacts/tarvoka_g09_v17_full_eco_same_camera.png")

    studio._toggle_v17_quality()
    studio._set_damage(0)
    var four := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for n in range(4):
        studio._reset_camera()
        studio._rotate(float(n)*90.0)
        var shot: Image = await _capture(studio)
        four.blit_rect(shot,Rect2i(0,0,480,330),Vector2i(n*480,0))
    assert(four.save_png("res://artifacts/tarvoka_g09_v17_four_angles.png")==OK)
    studio.queue_free()
    print("PASS G09 V17: 6 shared smoke sheets 96x128, 5 dimmed fire, full=11 eco=6 cards, 8 factions, 14 paint slots, 5 reversible damage stages; changed smoke=%d fire=%d eco=%d, CPU120 full=%dus eco=%dus (informational only)" % [delta_smoke,delta_fire,delta_eco,full_micros,eco_micros])
    quit(0)
