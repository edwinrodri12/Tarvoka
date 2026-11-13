extends SceneTree

# Godot 4.3 GPU review of TARVOKA HQ V4, keeping V3 as a locked baseline.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _meshes(child)
    return count

func _material_color_match(a: Color,b: Color) -> bool:
    return absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) < 0.025

func _pixel_diff(a: Image,b: Image) -> int:
    var aa := a.duplicate()
    var bb := b.duplicate()
    aa.resize(480,330,Image.INTERPOLATE_LANCZOS)
    bb.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var difference: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var first: Color = aa.get_pixel(x,y)
            var second: Color = bb.get_pixel(x,y)
            if absf(first.r-second.r)+absf(first.g-second.g)+absf(first.b-second.b) > 0.14:
                difference += 1
    return difference

func _run() -> void:
    for level in [1,2,3]:
        var v3: Node3D = HQ.build(level,0,"operativo",true,true,false)
        var v4: Node3D = HQ.build(level,0,"operativo",true,true,true)
        assert(v3 != null and v4 != null)
        assert(v3.get_meta("tarvoka_hq_visual_v3",false))
        assert(not v3.get_meta("tarvoka_hq_visual_v4",false))
        assert(v4.get_meta("tarvoka_hq_visual_v4",false))
        assert(v4.get_meta("tarvoka_hq_reference") == "approved-hq-20261112")
        assert(_meshes(v4) > _meshes(v3)+100)
        assert(v4.find_child("NucleoVerticalDeMandoV4",true,false) != null)
        assert(v4.find_child("EscudoDeFaccionModular",true,false) != null)
        assert(v4.find_child("TorreDeRedesTrianguladaV4",true,false) != null)
        assert(v4.find_child("PlatoParabolicoConcavo",true,false) != null)
        var pad: Node3D = v4.find_child("Helipuerto",true,false) as Node3D
        assert(pad != null and pad.position.x > 3.5 and pad.position.z < -2.5)
        assert(pad.position.y < -1.0)
        var radar: Node3D = v4.find_child("RadarPremium3D",true,false) as Node3D
        assert(radar != null and radar.scale.x > 1.5)
        var reflector: MeshInstance3D = v4.find_child("PlatoParabolicoConcavo",true,false) as MeshInstance3D
        assert(reflector != null and reflector.get_meta("tarvoka_reflector_double_sided",false))
        assert((reflector.material_override as StandardMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED)
        var cloth: MeshInstance3D = v4.find_child("TelaBanderaOndulada",true,false) as MeshInstance3D
        assert(cloth != null and cloth.mesh is ArrayMesh)
        assert(cloth.has_meta("tarvoka_faction_panel"))
        var rivets: MultiMeshInstance3D = v4.find_child("RemachesDeBlindajeInstanciados",true,false) as MultiMeshInstance3D
        assert(rivets != null and rivets.multimesh.instance_count >= 40)
        var closeup: Node3D = v4.find_child("DetalleCercanoV4",true,false) as Node3D
        assert(closeup != null and not closeup.visible)
        HQ.set_render_detail(v4,true)
        assert(closeup.visible)
        HQ.set_render_detail(v4,false)
        assert(not closeup.visible)
        assert(HQ.paintable_count(v4) > HQ.paintable_count(v3))
        if level == 3:
            assert(v4.find_child("ArcoSuperiorNivel3_1",true,false) != null)
        v3.free()
        v4.free()
    for faction in range(8):
        var hq: Node3D = HQ.build(1,faction,"operativo")
        var badge: MeshInstance3D = hq.find_child("EscudoDeFaccionModular",true,false) as MeshInstance3D
        assert(badge != null and badge.mesh is ArrayMesh)
        assert(_material_color_match((badge.material_override as StandardMaterial3D).albedo_color,
            Style.faction_color(faction)))
        hq.free()
    var wounded: Node3D = HQ.build(2,1,"danado")
    assert(wounded.find_child("ImpactosHeroV4",true,false) != null)
    assert(wounded.find_child("CortaduraEnEmblema",true,false) != null)
    wounded.free()
    var captured: Node3D = HQ.build(1,3,"capturado")
    assert(captured.get_meta("tarvoka_hq_visual_v4",false))
    assert(captured.find_child("MarcaDeCaptura",true,false) != null)
    captured.free()
    var destroyed: Node3D = HQ.build(3,4,"destruido")
    assert(destroyed.get_meta("tarvoka_hq_visual_v4",false))
    assert(destroyed.find_child("EscombrosHeroV4",true,false) != null)
    assert(destroyed.find_child("NucleoVerticalDeMandoV4",true,false) == null)
    destroyed.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene != null)
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(6):
        await process_frame
    studio._switch_category(1)
    studio._reset_camera()
    for i in range(9):
        await process_frame
    assert(studio.camera.position.x < 0.0)
    assert(studio.hq_version_picker.item_count == 4)
    assert(studio.hq_version_picker.selected == 0)
    assert(studio._hq_show_v4)
    var improved: Image = studio.preview.get_texture().get_image()
    assert(improved != null and not improved.is_empty())
    studio._change_hq_version(1)
    assert(not studio._hq_show_v4 and studio._hq_show_v3)
    for i in range(9):
        await process_frame
    var old: Image = studio.preview.get_texture().get_image()
    assert(old != null and not old.is_empty())
    assert(_pixel_diff(old,improved) > 250)
    studio._change_hq_version(0)
    assert(studio._hq_show_v4 and studio.model_root.get_meta("tarvoka_hq_visual_v4",false))
    studio._change_zoom(1)
    studio._change_zoom(1)
    var closeup: Node3D = studio.model_root.find_child("DetalleCercanoV4",true,false) as Node3D
    assert(closeup != null and closeup.visible)
    studio._reset_camera()
    assert(not closeup.visible)

    var left := old.duplicate()
    var right := improved.duplicate()
    left.resize(480,330,Image.INTERPOLATE_LANCZOS)
    right.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(left,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(right,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sheet.save_png("res://artifacts/tarvoka_hq_v3_vs_v4_real_render.png")==OK)
    studio.level_picker.select(2)
    studio._change_building_variant(2)
    for i in range(8):
        await process_frame
    var upgraded: Image = studio.preview.get_texture().get_image()
    assert(upgraded != null and not upgraded.is_empty())
    assert(upgraded.save_png("res://artifacts/tarvoka_hq_v4_level3_render.png")==OK)
    studio._switch_category(0)
    assert(studio._role == "tank" and studio.model_root != null)
    studio.queue_free()
    print("PASS headquarters V4: heroic 3D silhouette, frontal helipad, command shield, radar, 8 factions, LOD, 4 conditions, V3/V4 GPU comparison")
    quit(0)
