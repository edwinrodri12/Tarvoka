extends SceneTree

# Verify V13 as actual Godot mesh geometry, not a still picture. In-game
# tank build, battle damage, eight official palettes and browser 3D camera
# all share the same production sources. V10 Android default is unchanged.
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

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,12)
    var candidate: Node3D = Models.build("tank",0,true,13)
    assert(old != null and candidate != null)
    assert(not old.get_meta("tarvoka_mbt_segmented_v13",false))
    assert(candidate.get_meta("tarvoka_mbt_segmented_v13",false))
    assert(int(candidate.get_meta("tarvoka_mbt_segmented_v13_pbr_count",0)) >= 20)
    assert(Models.paintable_count(candidate) == 14)
    assert(Models.paintable_count(old) == 14)
    for side in [-1,1]:
        var original: Node3D = candidate.find_child(
            "G09V12DefensaOrugaAngular_%s" % side,true,false) as Node3D
        assert(original != null and not original.visible)
        for index in range(5):
            var name: String = "G09V13FaldonSegmentado_%s_%02d" % [side,index]
            var armor: MeshInstance3D = candidate.find_child(name,true,false) as MeshInstance3D
            assert(armor != null and armor.mesh is ArrayMesh and armor.visible)
            assert(armor.material_override is StandardMaterial3D)
    var aft: MeshInstance3D = candidate.find_child(
        "G09V13BastionMunicionesContinuo",true,false) as MeshInstance3D
    var turret: Node3D = candidate.find_child("TorretaGiratoria",true,false) as Node3D
    assert(aft != null and aft.mesh is ArrayMesh and aft.get_parent() == turret)
    assert(not candidate.find_child(
        "G09V12AlmacenBlindadoPosterior",true,false).visible)
    assert(Damage.apply_stage(candidate,3))
    assert(not candidate.find_child(
        "G09V13FaldonSegmentado_1_03",true,false).visible)
    assert(candidate.find_child(
        "G09V13FaldonSegmentado_-1_03",true,false).visible)
    assert(Damage.apply_stage(candidate,4))
    assert(not aft.visible)
    assert(Damage.apply_stage(candidate,0))
    assert(aft.visible)
    assert(not candidate.find_child(
        "G09V12AlmacenBlindadoPosterior",true,false).visible)
    assert(not candidate.find_child(
        "G09V12DefensaOrugaAngular_1",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(candidate,faction) == 14)
    assert(Rig.has_rig(candidate))
    assert(Rig.pose(candidate,"attack",0.6,Vector2i(1,0)))
    Rig.restore(candidate)
    old.free()
    candidate.free()

    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v12()
    assert(studio._v12_preview)
    var previous: Image = await _capture(studio)
    var angle: float = studio._yaw
    var zoom: float = studio._zoom
    studio._toggle_v13()
    assert(studio._v13_preview)
    assert(is_equal_approx(studio._yaw,angle))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(studio.model_root.get_meta("tarvoka_mbt_segmented_v13",false))
    var updated: Image = await _capture(studio)

    var changed: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = previous.get_pixel(x,y)
            var b: Color = updated.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.13:
                changed += 1
    assert(changed > 35)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(previous,Rect2i(0,0,480,330),Vector2i(0,0))
    comparison.blit_rect(updated,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(comparison.save_png("res://artifacts/tarvoka_g09_v12_v13_same_camera.png") == OK)

    # Four directional views to catch geometry collisions, exposed gaps and
    # clipped armor before a user needs to reinstall the Android package.
    var angles: Image = Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var shot: Image = await _capture(studio)
        angles.blit_rect(shot,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(angles.save_png("res://artifacts/tarvoka_g09_v13_four_angles.png") == OK)
    studio._toggle_v13()
    assert(not studio._v13_preview and studio._v12_preview)
    assert(not studio.model_root.get_meta("tarvoka_mbt_segmented_v13",false))
    studio.queue_free()
    print("PASS G09 V13: 10 new armor cells, PBR, reversible HP, 14 paint zones, 8 factions, articulated gun, native browser comparison")
    quit(0)
