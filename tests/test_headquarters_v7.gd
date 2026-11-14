extends SceneTree

# TARVOKA HQ V7 real-geometry / same-camera regression in Godot 4.3.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _mesh_count(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _mesh_count(child)
    return count

func _difference(a: Image,b: Image) -> int:
    var first: Image = a.duplicate()
    var second: Image = b.duplicate()
    first.resize(480,330,Image.INTERPOLATE_LANCZOS)
    second.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var pixels: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var p: Color = first.get_pixel(x,y)
            var q: Color = second.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b) > 0.15:
                pixels += 1
    return pixels

func _pair(left: Image,right: Image,path: String) -> void:
    var a: Image = left.duplicate()
    var b: Image = right.duplicate()
    a.resize(480,330,Image.INTERPOLATE_LANCZOS)
    b.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png(path)==OK)

func _run() -> void:
    var counts: Array[int] = []
    for level in [1,2,3]:
        var earlier: Node3D = HQ.build(level,0,"operativo",true,true,true,false)
        var sculpted: Node3D = HQ.build(level,0,"operativo",true,true,true,true)
        assert(earlier != null and sculpted != null)
        assert(earlier.get_meta("tarvoka_hq_visual_v4",false))
        assert(not earlier.get_meta("tarvoka_hq_visual_v7",false))
        assert(sculpted.get_meta("tarvoka_hq_visual_v7",false))
        var increase: int = _mesh_count(sculpted)-_mesh_count(earlier)
        assert(increase >= 65)
        counts.append(increase)
        assert(sculpted.find_child("MarquesinaAerodinamicaCurvaV7",true,false) != null)
        var canopy: MeshInstance3D = sculpted.find_child(
            "MarquesinaAerodinamicaCurvaV7",true,false) as MeshInstance3D
        assert(canopy.mesh is ArrayMesh and canopy.mesh.get_surface_count() == 1)
        assert((canopy.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 250)
        assert(sculpted.find_child("CristalPanoramicoComando_-1",true,false) != null)
        assert(sculpted.find_child("CristalPanoramicoComando_1",true,false) != null)
        assert(sculpted.find_child("ExtractorAzotea_1",true,false) != null)
        assert(sculpted.find_child("MecanismoDeRadarArticuladoV7",true,false) != null)
        assert(sculpted.find_child("BalizamientoHelipuertoV7",true,false) != null)
        assert(sculpted.find_child("EscudoOficialFaccion3D",true,false) != null)
        assert(sculpted.find_child("DetalleCercanoV4",true,false) != null)
        var fine: Node3D = sculpted.find_child("MicrodetalleConstructivoV7",true,false) as Node3D
        assert(fine != null and not fine.visible)
        HQ.set_render_detail(sculpted,true)
        assert(fine.visible)
        HQ.set_render_detail(sculpted,false)
        assert(not fine.visible)
        earlier.free()
        sculpted.free()
    for faction in range(8):
        var hq: Node3D = HQ.build(1,faction,"capturado")
        assert(hq.get_meta("tarvoka_hq_visual_v7",false))
        var emblem: MeshInstance3D = hq.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(emblem != null and emblem.get_meta("tarvoka_official_emblem_index")==faction)
        var faction_panel: MeshInstance3D = hq.find_child(
            "RibeteFaccionEnAleron",true,false) as MeshInstance3D
        assert(faction_panel != null and faction_panel.has_meta("tarvoka_faction_panel"))
        var col: Color = Style.faction_color(faction)
        assert(col.a > 0.95)
        hq.free()
    var damaged: Node3D = HQ.build(2,3,"danado")
    assert(damaged.find_child("FracturaMaterialArquitectonicaV7",true,false) != null)
    assert(damaged.find_child("ImpactosHeroV4",true,false) != null)
    damaged.free()
    var destroyed: Node3D = HQ.build(3,5,"destruido")
    assert(destroyed.get_meta("tarvoka_hq_visual_v7",false))
    assert(destroyed.find_child("RestosDeFachadaV7",true,false) != null)
    assert(destroyed.find_child("MarquesinaAerodinamicaCurvaV7",true,false) == null)
    assert(destroyed.find_child("EscudoOficialFaccion3D",true,false) != null)
    destroyed.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(7):
        await process_frame
    studio._switch_category(1)
    studio._reset_camera()
    assert(studio.hq_v7_toggle.button_pressed)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v7",false))
    for i in range(10):
        await process_frame
    var front_v7: Image = studio.preview.get_texture().get_image()
    assert(not front_v7.is_empty())
    studio.hq_v7_toggle.set_pressed_no_signal(false)
    studio._change_hq_sculpt(false)
    assert(not studio.model_root.get_meta("tarvoka_hq_visual_v7",false))
    for i in range(10):
        await process_frame
    var front_v4: Image = studio.preview.get_texture().get_image()
    assert(not front_v4.is_empty())
    assert(_difference(front_v4,front_v7) > 80)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    _pair(front_v4,front_v7,"res://artifacts/tarvoka_hq_v4_vs_v7_sculpted_front.png")

    studio.hq_v7_toggle.set_pressed_no_signal(true)
    studio._change_hq_sculpt(true)
    studio.level_picker.select(2)
    studio._change_building_variant(2)
    for i in range(8):
        await process_frame
    var advanced: Image = studio.preview.get_texture().get_image()
    assert(not advanced.is_empty())
    assert(advanced.save_png("res://artifacts/tarvoka_hq_v7_level3.png")==OK)

    studio.building_state_picker.select(2)
    studio._change_building_variant(2)
    for i in range(8):
        await process_frame
    var wounded: Image = studio.preview.get_texture().get_image()
    assert(not wounded.is_empty())
    assert(wounded.save_png("res://artifacts/tarvoka_hq_v7_damaged.png")==OK)

    studio._switch_category(0)
    assert(studio._role == "tank" and studio.model_root != null)
    studio.queue_free()
    print("PASS HQ V7: substantial curved 3D architecture, physical gateway, tower, HVAC, radar, helipad, eight emblems, damage and GPU V4/V7 same-camera comparison; extra meshes: ",counts)
    quit(0)
