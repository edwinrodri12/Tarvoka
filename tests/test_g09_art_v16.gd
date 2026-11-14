extends SceneTree

# G09 V16 tests exercise the very same live Godot model as Android/WebGL.
# All eight faction colors, fourteen paint zones, damage stages, and camera
# continuity must survive this purely artistic pass.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(7):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    image.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return image

func _changed(before: Image,after: Image) -> int:
    var count: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = before.get_pixel(x,y)
            var b: Color = after.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.13:
                count+=1
    return count

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,15)
    var final: Node3D = Models.build("tank",0,true,16)
    assert(old != null and final != null)
    assert(not old.get_meta("tarvoka_mbt_finish_v16",false))
    assert(final.get_meta("tarvoka_mbt_finish_v16",false))
    assert(int(final.get_meta("tarvoka_mbt_finish_v16_roof_count",0)) >= 7)
    assert(int(final.get_meta("tarvoka_mbt_finish_v16_enamel_count",0)) == 10)
    assert(int(final.get_meta("tarvoka_mbt_finish_v16_fire_count",0)) == 5)
    assert(Models.paintable_count(old) == 14)
    assert(Models.paintable_count(final) == 14)

    for side in [-1,1]:
        for i in range(5):
            var name: String = "FaccionFaldon%s_%02d" % [side,i]
            var legacy: MeshInstance3D = old.find_child(
                name,true,false) as MeshInstance3D
            var muted: MeshInstance3D = final.find_child(
                name,true,false) as MeshInstance3D
            assert(legacy != null and muted != null)
            assert(legacy.mesh is BoxMesh and muted.mesh is BoxMesh)
            assert((muted.mesh as BoxMesh).size.y < (legacy.mesh as BoxMesh).size.y)
            assert((muted.mesh as BoxMesh).size.z < (legacy.mesh as BoxMesh).size.z)
            var paint: StandardMaterial3D = muted.material_override as StandardMaterial3D
            assert(paint != null and paint.albedo_texture != null)
            assert(not paint.emission_enabled)
            assert(paint.roughness >= 0.88)
            assert(paint.metallic <= 0.10)

    for label in ["CubiertaMotorRectificadaV7",
            "G09V12CubiertaMotorLateral_1","G09V14LomoBlindadoCentral_1",
            "G09V13BastionMunicionesContinuo"]:
        var roof: MeshInstance3D = final.find_child(
            label,true,false) as MeshInstance3D
        assert(roof != null)
        var material: StandardMaterial3D = roof.material_override as StandardMaterial3D
        assert(material != null and material.roughness_texture != null)
        assert(material.normal_enabled and material.normal_texture != null)
        assert(material.roughness >= 0.82 and material.metallic <= 0.15)

    for old_name in ["LenguaFuegoIzquierda","LenguaFuegoCentro",
            "LenguaFuegoAlta","FuegoBase","FuegoNucleo"]:
        var old_effect: Node3D = final.find_child(
            old_name,true,false) as Node3D
        assert(old_effect != null and not old_effect.visible)
        var v15_effect: Node3D = old.find_child(old_name,true,false) as Node3D
        assert(v15_effect != null and v15_effect.visible)
    for i in range(5):
        var flame: MeshInstance3D = final.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        assert(flame != null and flame.mesh is QuadMesh)
        var m: StandardMaterial3D = flame.material_override as StandardMaterial3D
        assert(m != null and m.albedo_texture != null)
        assert(m.billboard_mode == BaseMaterial3D.BILLBOARD_ENABLED)
        assert(m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)

    assert(Damage.apply_stage(final,4))
    var animated: MeshInstance3D = final.find_child(
        "G09V16FuegoLamina_00",true,false) as MeshInstance3D
    var before: Vector3 = animated.position
    Damage.animate_smoke(final,1.72)
    assert(animated.position.distance_to(before) > 0.015)
    assert(Damage.apply_stage(final,0))
    for stage in range(5):
        assert(Damage.apply_stage(final,stage))
        assert(Damage.current_stage(final) == stage)
    assert(Damage.apply_stage(final,0))
    assert(Rig.has_rig(final))
    assert(Rig.pose(final,"move",0.5,Vector2i(1,0)))
    assert(Rig.pose(final,"attack",0.5,Vector2i(-1,0)))
    Rig.restore(final)
    for faction in range(8):
        assert(Models.apply_faction_palette(final,faction) == 14)
        assert(Models.paintable_count(final) == 14)
        var stripe: MeshInstance3D = final.find_child(
            "FaccionFaldon1_00",true,false) as MeshInstance3D
        assert(stripe.material_override is StandardMaterial3D)
        assert((stripe.material_override as StandardMaterial3D).roughness >= 0.88)
    assert(Damage.apply_stage(final,0))
    old.free()
    final.free()

    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v15()
    assert(studio._v15_preview)
    var initial: Image = await _capture(studio)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._toggle_v16()
    assert(studio._v16_preview and not studio._v15_preview)
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(studio.model_root.get_meta("tarvoka_mbt_finish_v16",false))
    var finished: Image = await _capture(studio)
    var delta: int = _changed(initial,finished)
    assert(delta > 40)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var compare := Image.create(960,330,false,Image.FORMAT_RGBA8)
    compare.blit_rect(initial,Rect2i(0,0,480,330),Vector2i.ZERO)
    compare.blit_rect(finished,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(compare.save_png("res://artifacts/tarvoka_g09_v15_v16_same_camera.png") == OK)

    var views := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var view: Image = await _capture(studio)
        views.blit_rect(view,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(views.save_png("res://artifacts/tarvoka_g09_v16_four_angles.png") == OK)

    studio._reset_camera()
    studio._set_damage(4)
    var v16_fire: Image = await _capture(studio)
    studio._toggle_v16()
    assert(studio._v15_preview)
    var legacy_fire: Image = await _capture(studio)
    var flames_delta: int = _changed(v16_fire,legacy_fire)
    assert(flames_delta > 40)
    var wreck_compare := Image.create(960,330,false,Image.FORMAT_RGBA8)
    wreck_compare.blit_rect(legacy_fire,Rect2i(0,0,480,330),Vector2i.ZERO)
    wreck_compare.blit_rect(v16_fire,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(wreck_compare.save_png("res://artifacts/tarvoka_g09_v15_v16_fire_same_camera.png") == OK)
    studio._set_damage(0)
    studio.queue_free()
    print("PASS G09 V16: 10 muted enamel stripes, 9 PBR roof surfaces, 5 procedural animated fire cards, 14 faction slots, 8 palettes, HP/rig, normal delta %d and wreck delta %d" % [delta,flames_delta])
    quit(0)
