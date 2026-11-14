extends SceneTree

# Real GPU snapshot comparison of the same approved Headquarters, V1 vs V2.
# Tests run in Godot 4.3 OpenGL Compatibility under xvfb, not dummy headless.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const FINISH = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _meshes(child)
    return count

func _color_average(img: Image) -> float:
    var total := 0.0
    for y in range(30,330,9):
        for x in range(40,460,9):
            var p: Color = img.get_pixel(x,y)
            total += p.r+p.g+p.b
    return total

func _run() -> void:
    for level in [1,2,3]:
        var basic: Node3D = HQ.build(level,0,"operativo",false)
        var premium: Node3D = HQ.build(level,0,"operativo",true,false,false)
        assert(basic != null and premium != null)
        assert(not basic.has_meta("tarvoka_hq_visual_v2"))
        assert(premium.get_meta("tarvoka_hq_visual_v2",false))
        assert(_meshes(premium) > _meshes(basic)+75)
        assert(premium.find_child("MandoBiseladoPrincipal",true,false) != null)
        assert(premium.find_child("PlatoParabolicoConcavo",true,false) != null)
        assert(premium.find_child("PistaBiseladaDeDespegue",true,false) != null)
        assert(int(premium.get_meta("tarvoka_hq_v2_extra_meshes",0)) > 75)
        var core: MeshInstance3D = premium.find_child("MandoBiseladoPrincipal",true,false) as MeshInstance3D
        assert(core.mesh is ArrayMesh)
        var surface: StandardMaterial3D = core.material_override as StandardMaterial3D
        assert(surface != null and surface.albedo_texture != null)
        assert(surface.roughness > 0.60)
        assert(HQ.paintable_count(premium) >= HQ.paintable_count(basic))
        if level == 1:
            assert(premium.find_child("SoporteRadomoOctogonal",true,false) == null)
        if level == 3:
            assert(premium.find_child("SoporteRadomoOctogonal",true,false) != null)
        basic.free()
        premium.free()

    # Same architectural finishes must exist in all faction palettes.
    for faction in range(8):
        var hq: Node3D = HQ.build(1,faction,"operativo",true,false,false)
        assert(hq.get_meta("visual_faction") == faction)
        assert(hq.get_meta("tarvoka_hq_visual_v2"))
        hq.free()
    var damaged: Node3D = HQ.build(3,1,"danado",true,false,false)
    assert(damaged.find_child("DesgasteEstructuralPremium",true,false) != null)
    assert(damaged.find_child("AntenaColapsada",true,false) != null)
    damaged.free()
    var ruins: Node3D = HQ.build(3,2,"destruido",true,false,false)
    assert(ruins.find_child("RuinasDeMandoPremium",true,false) != null)
    assert(ruins.find_child("VigaRetorcida_00",true,false) != null)
    assert(ruins.find_child("MandoBiseladoPrincipal",true,false) == null)
    ruins.free()
    # Four surface families share color/normal/roughness maps, even across 8 factions.
    assert(FINISH._textures.size() <= 15)

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(5):
        await process_frame
    studio._hq_show_v3 = false
    studio._hq_show_v4 = false
    studio._switch_category(1)
    studio._reset_camera()
    for i in range(8):
        await process_frame
    assert(studio._hq_show_v2)
    var new_image: Image = studio.preview.get_texture().get_image()
    assert(new_image != null and not new_image.is_empty())
    assert(studio.model_root.find_child("MandoBiseladoPrincipal",true,false) != null)
    studio._toggle_hq_finish()
    assert(not studio._hq_show_v2)
    assert(studio.hq_compare_button.text.contains("V2"))
    for i in range(8):
        await process_frame
    var old_image: Image = studio.preview.get_texture().get_image()
    assert(old_image != null and not old_image.is_empty())
    assert(studio.model_root.find_child("MandoBiseladoPrincipal",true,false) == null)
    var prev := old_image.duplicate()
    var next := new_image.duplicate()
    prev.resize(480,330,Image.INTERPOLATE_LANCZOS)
    next.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var changed: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = prev.get_pixel(x,y)
            var b: Color = next.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.12:
                changed += 1
    assert(changed > 140)
    assert(_color_average(next) > 50.0)
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(prev,Rect2i(0,0,480,330),Vector2i(0,0))
    sheet.blit_rect(next,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sheet.save_png("res://artifacts/tarvoka_headquarters_v1_v2_comparison.png") == OK)
    studio._toggle_hq_finish()
    assert(studio._hq_show_v2)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v2"))
    studio.queue_free()
    print("PASS headquarters premium V2: chamfered 3D, real curved radar, textured materials, all levels/factions/damage and same-camera comparison")
    quit(0)
