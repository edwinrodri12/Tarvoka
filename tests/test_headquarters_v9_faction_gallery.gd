extends SceneTree

# Native GPU regression for TARVOKA HQ V9 and the restored eight faction views.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _difference(a: Image,b: Image) -> int:
    var first: Image = a.duplicate()
    var second: Image = b.duplicate()
    first.resize(460,320,Image.INTERPOLATE_LANCZOS)
    second.resize(460,320,Image.INTERPOLATE_LANCZOS)
    var count: int = 0
    for y in range(0,320,4):
        for x in range(0,460,4):
            var p: Color = first.get_pixel(x,y)
            var q: Color = second.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b) > 0.13:
                count += 1
    return count

func _side_by_side(first: Image,second: Image,path: String) -> void:
    var a: Image = first.duplicate()
    var b: Image = second.duplicate()
    a.resize(480,330,Image.INTERPOLATE_LANCZOS)
    b.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png(path)==OK)

func _run() -> void:
    for level in [1,2,3]:
        var older: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,false)
        var newer: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true)
        assert(older != null and newer != null)
        assert(older.get_meta("tarvoka_hq_visual_v8",false))
        assert(not older.get_meta("tarvoka_hq_visual_v9",false))
        assert(newer.get_meta("tarvoka_hq_visual_v9",false))
        assert(newer.get_meta("tarvoka_hq_v9_architecture_only",false))
        assert(newer.find_child("ArmazonesLegiblesDeFachadaV9",true,false)!=null)
        assert(newer.find_child("MachonVerticalFaccion_-1",true,false)!=null)
        assert(newer.find_child("MachonVerticalFaccion_1",true,false)!=null)
        assert(newer.find_child("AletaAltaPuenteComando_1",true,false)!=null)
        assert(newer.find_child("InstalacionYAccesoLecturaV9",true,false)!=null)
        var fine: Node3D = newer.find_child("DetalleCercanoV9",true,false) as Node3D
        assert(fine != null and not fine.visible)
        HQ.set_render_detail(newer,true)
        assert(fine.visible)
        HQ.set_render_detail(newer,false)
        assert(not fine.visible)
        older.free()
        newer.free()
    var wounded: Node3D = HQ.build(2,4,"danado")
    var fin: MeshInstance3D = wounded.find_child(
        "AletaAltaPuenteComando_-1",true,false) as MeshInstance3D
    assert(fin != null and not fin.visible)
    assert(wounded.find_child("FallasEstructuralesVisiblesV9",true,false)!=null)
    wounded.free()
    var ruined: Node3D = HQ.build(3,2,"destruido")
    assert(ruined.get_meta("tarvoka_hq_visual_v9",false))
    assert(ruined.find_child("RestosDeSiluetaComandoV9",true,false)!=null)
    assert(ruined.find_child("ArmazonesLegiblesDeFachadaV9",true,false)==null)
    ruined.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == preload("res://scripts/ui/EnvironmentArtStudioWeb.gd"))
    root.add_child(studio)
    for i in range(6):
        await process_frame
    assert(studio.faction_view_grid != null)
    assert(studio.faction_view_grid.columns == 2)
    assert(studio.faction_view_buttons.size() == 8)
    assert(studio.faction_picker.item_count == 8)
    for faction in range(8):
        var card: Button = studio.faction_view_buttons[faction]
        assert(card.icon != null)
        assert(card.icon == Emblems.emblem_texture(faction))
        assert(card.tooltip_text == str(Style.FACTIONS[faction]["name"]))
    studio._switch_category(1)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v9",false))
    assert(studio.hq_v9_toggle.button_pressed)
    assert(studio.faction_view_grid.visible)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var atlas := Image.create(1280,480,false,Image.FORMAT_RGBA8)
    for faction in range(8):
        # One tap of the official crest regenerates the actual 3D faction HQ.
        studio._select_faction_view(faction)
        assert(studio.faction_picker.selected == faction)
        assert(studio._faction == faction)
        assert(studio.faction_view_buttons[faction].button_pressed)
        assert(studio.faction_view_label.text.find(
            str(Style.FACTIONS[faction]["name"])) >= 0)
        assert(studio.model_root.get_meta("visual_faction",-1)==faction)
        var crest: MeshInstance3D = studio.model_root.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(crest != null and crest.get_meta("tarvoka_official_emblem_index",-1)==faction)
        var cladding: MeshInstance3D = studio.model_root.find_child(
            "MachonVerticalFaccion_1",true,false) as MeshInstance3D
        assert(cladding != null and cladding.has_meta("tarvoka_faction_panel"))
        for frame in range(4):
            await process_frame
        var render: Image = studio.preview.get_texture().get_image()
        assert(render != null and not render.is_empty())
        render.resize(320,240,Image.INTERPOLATE_LANCZOS)
        atlas.blit_rect(render,Rect2i(0,0,320,240),
            Vector2i((faction%4)*320,int(faction/4)*240))
    assert(atlas.save_png("res://artifacts/tarvoka_hq_v9_eight_faction_views.png")==OK)

    studio._select_faction_view(0)
    studio.hq_v9_toggle.set_pressed_no_signal(false)
    studio._change_hq_readability_v9(false)
    assert(not studio.model_root.get_meta("tarvoka_hq_visual_v9",false))
    for frame in range(7):
        await process_frame
    var v8_image: Image = studio.preview.get_texture().get_image()
    studio.hq_v9_toggle.set_pressed_no_signal(true)
    studio._change_hq_readability_v9(true)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v9",false))
    for frame in range(7):
        await process_frame
    var v9_image: Image = studio.preview.get_texture().get_image()
    assert(_difference(v8_image,v9_image)>60)
    _side_by_side(v8_image,v9_image,
        "res://artifacts/tarvoka_hq_v8_vs_v9_distance_architecture.png")
    studio._change_zoom(-1)
    for frame in range(7):
        await process_frame
    var tactical_image: Image = studio.preview.get_texture().get_image()
    assert(tactical_image.save_png(
        "res://artifacts/tarvoka_hq_v9_tactical_scale.png")==OK)

    studio._switch_category(0)
    assert(studio.faction_view_grid.visible)
    studio._select_faction_view(7)
    assert(studio._faction == 7)
    assert(studio.faction_picker.selected == 7)
    assert(studio._role == "tank" and studio.model_root != null)
    studio._switch_category(1)
    assert(studio._faction == 7)
    assert(studio.model_root.get_meta("visual_faction",-1)==7)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v9",false))
    studio.queue_free()
    print("PASS HQ V9: physical silhouette for 3 levels, damage, eight official clickable faction gallery views on units/buildings, GPU montage and same-camera V8/V9")
    quit(0)
