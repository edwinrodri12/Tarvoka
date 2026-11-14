extends SceneTree

# Real Godot 4.3 OpenGL test: V2/V3 comparisons are rendered by the actual
# WebGL studio scene and saved without depending on concept images.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _count(node: Node) -> int:
    var n: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        n += _count(child)
    return n

func _same(a: Color, b: Color) -> bool:
    return absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) < 0.02

func _difference(a: Image, b: Image) -> int:
    var aa: Image = a.duplicate()
    var bb: Image = b.duplicate()
    aa.resize(480,330,Image.INTERPOLATE_LANCZOS)
    bb.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var changed: int = 0
    for y in range(0,330,5):
        for x in range(0,480,5):
            var first: Color = aa.get_pixel(x,y)
            var second: Color = bb.get_pixel(x,y)
            var delta: float = absf(first.r-second.r) + absf(first.g-second.g) + absf(first.b-second.b)
            if delta > 0.13:
                changed += 1
    return changed

func _run() -> void:
    for level in [1,2,3]:
        var v2: Node3D = HQ.build(level,0,"operativo",true,false)
        var v3: Node3D = HQ.build(level,0,"operativo",true,true)
        assert(v2 != null and v3 != null)
        assert(v2.get_meta("tarvoka_hq_visual_v2",false))
        assert(not v2.get_meta("tarvoka_hq_visual_v3",false))
        assert(v3.get_meta("tarvoka_hq_visual_v3",false))
        assert(_count(v3) > _count(v2)+60)
        assert(int(v3.get_meta("tarvoka_hq_v3_extra_meshes",0)) > 60)
        assert(v3.find_child("EscudoDeAccesoBiselado",true,false) != null)
        assert(v3.find_child("PabellonComandoElevado",true,false) != null)
        assert(v3.find_child("FaroCircular_0",true,false) != null)
        assert(v3.find_child("MarcaDeFaccionModular",true,false) != null)
        assert(v3.find_child("TorrecillaEsquina_-1",true,false) != null)
        assert(v3.find_child("TorrecillaEsquina_1",true,false) != null)
        assert(v3.find_child("PlatoParabolicoConcavo",true,false) != null)
        var lamp := v3.find_child("LuzVerticalPuertaDerecha",true,false) as MeshInstance3D
        assert(lamp != null)
        var mat := lamp.material_override as StandardMaterial3D
        assert(mat != null and mat.emission_enabled)
        assert(_same(mat.emission,Factions.faction_color(0)))
        assert(v3.find_child("MastilNuevo_1",true,false) != null if level>=2 else v3.find_child("MastilNuevo_1",true,false) == null)
        assert(v3.find_child("ArcoSuperiorNivel3_1",true,false) != null if level==3 else v3.find_child("ArcoSuperiorNivel3_1",true,false)==null)
        v2.free()
        v3.free()

    for faction in range(8):
        var model: Node3D = HQ.build(2,faction,"operativo",true,true)
        assert(int(model.get_meta("visual_faction",-1)) == faction)
        var marker := model.find_child("MarcaDeFaccionModular",true,false) as MeshInstance3D
        assert(marker != null)
        var m: StandardMaterial3D = marker.material_override as StandardMaterial3D
        assert(_same(m.albedo_color,Factions.faction_color(faction)))
        model.free()
    var wounded: Node3D = HQ.build(3,0,"danado")
    assert(wounded.find_child("ImpactosDeCombateV3",true,false) != null)
    assert(wounded.find_child("FisuraEnPortal_0",true,false) != null)
    wounded.free()
    var ruined: Node3D = HQ.build(3,2,"destruido")
    assert(ruined.find_child("RestosDeComandoV3",true,false) != null)
    assert(ruined.find_child("FachadaColapsadaHero",true,false) != null)
    assert(ruined.find_child("PabellonComandoElevado",true,false) == null)
    ruined.free()
    var captured: Node3D = HQ.build(2,4,"capturado")
    assert(captured.find_child("MarcaDeCaptura",true,false) != null)
    assert(captured.get_meta("tarvoka_hq_visual_v3",false))
    captured.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(6):
        await process_frame
    studio._switch_category(1)
    studio._reset_camera()
    for i in range(8):
        await process_frame
    assert(studio._hq_show_v3 and studio._hq_show_v2)
    var new_image: Image = studio.preview.get_texture().get_image()
    assert(new_image != null and not new_image.is_empty())
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v3",false))
    studio._toggle_hq_detail()
    assert(not studio._hq_show_v3)
    assert(studio._hq_show_v2)
    assert(studio.hq_v3_compare_button.text.contains("Volver"))
    for i in range(8):
        await process_frame
    var old_image: Image = studio.preview.get_texture().get_image()
    assert(old_image != null and not old_image.is_empty())
    assert(not studio.model_root.get_meta("tarvoka_hq_visual_v3",false))
    assert(_difference(new_image,old_image) > 90)
    var left: Image = old_image.duplicate()
    var right: Image = new_image.duplicate()
    left.resize(480,330,Image.INTERPOLATE_LANCZOS)
    right.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var side_by_side := Image.create(960,330,false,Image.FORMAT_RGBA8)
    side_by_side.blit_rect(left,Rect2i(0,0,480,330),Vector2i.ZERO)
    side_by_side.blit_rect(right,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(side_by_side.save_png("res://artifacts/tarvoka_headquarters_v2_v3_comparison.png")==OK)
    studio._toggle_hq_detail()
    assert(studio._hq_show_v3)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v3",false))
    studio._switch_category(0)
    assert(studio._role == "tank")
    assert(studio.model_root.get_meta("tarvoka_mbt_hero_v7",false))
    studio.queue_free()
    print("PASS headquarters V3: command architecture, eight factions, tiered roof, emissive navigation, damaged and destroyed, V2/V3 rendered screenshot")
    quit(0)
