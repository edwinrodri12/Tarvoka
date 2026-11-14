extends SceneTree

# HQ V10 visual production gate: native GPU material/silhouette validation.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _count(node: Node) -> int:
    var result: int = 1 if node is MeshInstance3D else 0
    for c in node.get_children():
        result += _count(c)
    return result

func _difference(before: Image,after: Image) -> int:
    var a: Image = before.duplicate()
    var b: Image = after.duplicate()
    a.resize(440,330,Image.INTERPOLATE_LANCZOS)
    b.resize(440,330,Image.INTERPOLATE_LANCZOS)
    var different: int = 0
    for y in range(0,330,4):
        for x in range(0,440,4):
            var u: Color = a.get_pixel(x,y)
            var v: Color = b.get_pixel(x,y)
            if absf(u.r-v.r)+absf(u.g-v.g)+absf(u.b-v.b)>0.13:
                different += 1
    return different

func _comparison(before: Image,after: Image,path: String) -> void:
    var a: Image = before.duplicate()
    var b: Image = after.duplicate()
    a.resize(480,330,Image.INTERPOLATE_LANCZOS)
    b.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png(path)==OK)

func _run() -> void:
    for level in [1,2,3]:
        var v9: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true,false)
        var v10: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true,true)
        assert(v9.get_meta("tarvoka_hq_visual_v9",false))
        assert(not v9.get_meta("tarvoka_hq_visual_v10",false))
        assert(v10.get_meta("tarvoka_hq_visual_v10",false))
        assert(v10.get_meta("tarvoka_hq_v10_visual_only",false))
        assert(_count(v10)>_count(v9)+65)
        assert(v10.find_child("EncuentrosMaterialesArquitectonicosV10",true,false)!=null)
        assert(v10.find_child("PanelCementicioPrefabricado_-1_1",true,false)!=null)
        assert(v10.find_child("PanelCementicioPrefabricado_1_1",true,false)!=null)
        assert(v10.find_child("SelloElastomeroPilastro_1",true,false)!=null)
        assert(v10.find_child("PaqueteDobleVidrioComando_1",true,false)!=null)
        assert(v10.find_child("CubiertasDeMaterialesConUnionesV10",true,false)!=null)
        var panel: MeshInstance3D = v10.find_child(
            "PanelCementicioPrefabricado_1_1",true,false) as MeshInstance3D
        assert(panel != null and panel.mesh is ArrayMesh)
        var m: StandardMaterial3D = panel.material_override as StandardMaterial3D
        assert(m != null and m.normal_enabled and m.albedo_texture != null)
        assert(m.roughness_texture != null)
        var fine: Node3D = v10.find_child(
            "MicrojuntasYRemachesV10",true,false) as Node3D
        assert(fine != null and not fine.visible)
        HQ.set_render_detail(v10,true)
        assert(fine.visible)
        HQ.set_render_detail(v10,false)
        assert(not fine.visible)
        v9.free()
        v10.free()

    var damaged: Node3D = HQ.build(2,3,"danado")
    var whole: MeshInstance3D = damaged.find_child(
        "PanelCementicioPrefabricado_-1_1",true,false) as MeshInstance3D
    assert(whole != null and not whole.visible)
    assert(damaged.find_child("AceroArmadoExpuesto_00",true,false)!=null)
    assert(damaged.find_child("PanelDeHormigonFracturadoV10",true,false)!=null)
    assert(damaged.find_child("CristalRotoGeometricoV8",true,false)!=null)
    damaged.free()
    var ruined: Node3D = HQ.build(3,7,"destruido")
    assert(ruined.get_meta("tarvoka_hq_visual_v10",false))
    assert(ruined.find_child("RestosEncuentrosMaterialesV10",true,false)!=null)
    assert(ruined.find_child("EncuentrosMaterialesArquitectonicosV10",true,false)==null)
    ruined.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(8):
        await process_frame
    studio._switch_category(1)
    assert(studio.hq_v10_toggle != null and studio.hq_v10_toggle.button_pressed)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v10",false))
    assert(studio.faction_view_buttons.size()==8)
    for faction in range(8):
        studio._select_faction_view(faction)
        assert(studio.faction_picker.selected==faction)
        assert(studio.faction_view_buttons[faction].button_pressed)
        assert(studio.faction_view_buttons[faction].icon==Emblems.emblem_texture(faction))
        assert(studio.faction_view_label.text.find(
            str(Style.FACTIONS[faction]["name"]))>=0)
        assert(studio.model_root.get_meta("tarvoka_hq_visual_v10",false))
        var crest: MeshInstance3D = studio.model_root.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(crest != null and crest.get_meta("tarvoka_official_emblem_index",-1)==faction)
    studio._select_faction_view(0)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    studio.hq_v10_toggle.set_pressed_no_signal(false)
    studio._change_hq_surfaces_v10(false)
    assert(not studio.model_root.get_meta("tarvoka_hq_visual_v10",false))
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v9",false))
    for i in range(9):
        await process_frame
    var old: Image = studio.preview.get_texture().get_image()
    studio.hq_v10_toggle.set_pressed_no_signal(true)
    studio._change_hq_surfaces_v10(true)
    for i in range(9):
        await process_frame
    var fresh: Image = studio.preview.get_texture().get_image()
    assert(_difference(old,fresh)>65)
    _comparison(old,fresh,"res://artifacts/tarvoka_hq_v9_vs_v10_surface_realism.png")
    studio._change_zoom(1)
    studio._change_zoom(1)
    for i in range(9):
        await process_frame
    var close: Image = studio.preview.get_texture().get_image()
    assert(close.save_png("res://artifacts/tarvoka_hq_v10_material_junction_close.png")==OK)
    studio._reset_camera()
    studio.building_state_picker.select(2)
    studio._change_building_variant(2)
    for i in range(9):
        await process_frame
    var broken: Image = studio.preview.get_texture().get_image()
    assert(broken.save_png("res://artifacts/tarvoka_hq_v10_exposed_rebar_damage.png")==OK)
    studio._switch_category(0)
    assert(studio.faction_view_grid.visible)
    studio._select_faction_view(6)
    assert(studio._role=="tank" and studio.model_root!=null)
    studio._switch_category(1)
    assert(studio._faction==6 and studio.model_root.get_meta("visual_faction",-1)==6)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v10",false))
    studio.queue_free()
    print("PASS HQ V10: three levels, genuine surface junction PBR, fractured cladding, eight official faction gallery views and GPU V9/V10 comparison")
    quit(0)
