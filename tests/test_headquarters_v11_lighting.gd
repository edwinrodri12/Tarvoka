extends SceneTree

# HQ V11 QA: true curved mesh + 3 stable lighting rigs, no code/render
# regression in eight approved faction views or tank studio mode.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")

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
    first.resize(440,320,Image.INTERPOLATE_LANCZOS)
    second.resize(440,320,Image.INTERPOLATE_LANCZOS)
    var pixels: int = 0
    for y in range(0,320,4):
        for x in range(0,440,4):
            var u: Color = first.get_pixel(x,y)
            var v: Color = second.get_pixel(x,y)
            if absf(u.r-v.r)+absf(u.g-v.g)+absf(u.b-v.b)>0.15:
                pixels += 1
    return pixels

func _pair(before: Image,after: Image) -> void:
    var a: Image = before.duplicate()
    var b: Image = after.duplicate()
    a.resize(480,330,Image.INTERPOLATE_LANCZOS)
    b.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var together := Image.create(960,330,false,Image.FORMAT_RGBA8)
    together.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    together.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(together.save_png(
        "res://artifacts/tarvoka_hq_v10_vs_v11_curved_real_mesh.png")==OK)

func _grab(studio: Control) -> Image:
    return studio.preview.get_texture().get_image()

func _frames() -> void:
    pass

func _run() -> void:
    for level in [1,2,3]:
        var previous: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true,true,false)
        var polished: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true,true,true)
        assert(previous != null and polished != null)
        assert(previous.get_meta("tarvoka_hq_visual_v10",false))
        assert(not previous.get_meta("tarvoka_hq_visual_v11",false))
        assert(polished.get_meta("tarvoka_hq_visual_v11",false))
        assert(polished.get_meta("tarvoka_hq_v11_visual_only",false))
        assert(_mesh_count(polished)>_mesh_count(previous)+30)
        var cast: MeshInstance3D = polished.find_child(
            "CornisaCurvadaHormigonAla_1",true,false) as MeshInstance3D
        assert(cast != null and cast.mesh is ArrayMesh)
        assert((cast.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>420)
        assert(polished.find_child("RemateCascaraCurvaDelPuente",true,false)!=null)
        assert(polished.find_child("ArcoMetalBlindadoPuerta",true,false)!=null)
        assert(polished.find_child("BranquiaAdmisiónHVAC_1_01",true,false)!=null)
        assert(polished.find_child("TuberíaDeDrenajeVertical_-1",true,false)!=null)
        var fine: Node3D = polished.find_child("MicrodetalleCurvasV11",true,false) as Node3D
        assert(fine != null and not fine.visible)
        HQ.set_render_detail(polished,true)
        assert(fine.visible)
        HQ.set_render_detail(polished,false)
        assert(not fine.visible)
        previous.free()
        polished.free()
    var broken: Node3D = HQ.build(3,2,"danado")
    var intact: MeshInstance3D = broken.find_child(
        "CornisaCurvadaHormigonAla_-1",true,false) as MeshInstance3D
    assert(intact != null and not intact.visible)
    assert(broken.find_child("CornisaFisicamenteFracturadaV11",true,false)!=null)
    assert(broken.find_child("AceroArmadoExpuesto_00",true,false)!=null)
    broken.free()
    var rubble: Node3D = HQ.build(3,4,"destruido")
    assert(rubble.get_meta("tarvoka_hq_visual_v11",false))
    assert(rubble.find_child("EscombrosCurvasOriginalesV11",true,false)!=null)
    assert(rubble.find_child("CantonerasRedondeadasDeHormigonV11",true,false)==null)
    rubble.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(8):
        await process_frame
    studio._switch_category(1)
    assert(studio.hq_v11_toggle.button_pressed)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v11",false))
    assert(studio.hq_lighting_picker.item_count==3)
    assert(studio.faction_view_buttons.size()==8)
    for f in range(8):
        studio._select_faction_view(f)
        var shield: MeshInstance3D = studio.model_root.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(shield != null)
        assert(shield.get_meta("tarvoka_official_emblem_index",-1)==f)
        assert(studio.faction_view_buttons[f].icon==Emblems.emblem_texture(f))
        assert(studio.faction_view_label.text.find(
            str(Factions.FACTIONS[f]["name"]))>=0)
    studio._select_faction_view(0)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))

    # Version 10 vs V11 must differ with the same neutral studio camera.
    studio.hq_v11_toggle.set_pressed_no_signal(false)
    studio._change_hq_refinement_v11(false)
    for i in range(9):
        await process_frame
    var old: Image = _grab(studio)
    studio.hq_v11_toggle.set_pressed_no_signal(true)
    studio._change_hq_refinement_v11(true)
    for i in range(9):
        await process_frame
    var polished_img: Image = _grab(studio)
    assert(_difference(old,polished_img)>65)
    _pair(old,polished_img)

    var views: Array[Image] = []
    for preset in range(3):
        studio.hq_lighting_picker.select(preset)
        studio._change_hq_lighting(preset)
        assert(studio._hq_light_preset==preset)
        assert(studio.hq_night_lamps[0].visible == (preset==2))
        for i in range(10):
            await process_frame
        var img: Image = _grab(studio)
        assert(img != null and not img.is_empty())
        views.append(img)
        var suffix: String = ["day","sunset","night"][preset]
        assert(img.save_png("res://artifacts/tarvoka_hq_v11_%s_godot.png" % suffix)==OK)
    assert(_difference(views[0],views[1])>80)
    assert(_difference(views[0],views[2])>120)

    studio.building_state_picker.select(2)
    studio._change_building_variant(2)
    for i in range(9):
        await process_frame
    assert(_grab(studio).save_png(
        "res://artifacts/tarvoka_hq_v11_curved_damage.png")==OK)
    studio._switch_category(0)
    assert(studio._role=="tank")
    assert(not studio.hq_night_lamps[0].visible)
    assert(studio.faction_view_grid.visible)
    studio._select_faction_view(7)
    studio._switch_category(1)
    assert(studio.hq_night_lamps[0].visible)
    assert(studio._faction==7)
    assert(studio.model_root.get_meta("visual_faction",-1)==7)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v11",false))
    studio.queue_free()
    print("PASS HQ V11: three curved geometry levels, eight official faction gallery views, night/day/sunset GPU frames, fractured arcade and V10 comparison")
    quit(0)
