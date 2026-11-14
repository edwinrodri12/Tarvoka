extends SceneTree

# HQ V13 production delivery gate. Validates ALL 96 variants, consistent
# official crest texture and draw-call/mesh budgets. GPU checks real studio.
const Production = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _pixels_different(before: Image,after: Image) -> int:
    var a: Image = before.duplicate()
    var b: Image = after.duplicate()
    a.resize(360,240,Image.INTERPOLATE_LANCZOS)
    b.resize(360,240,Image.INTERPOLATE_LANCZOS)
    var count: int = 0
    for y in range(0,240,4):
        for x in range(0,360,4):
            var one: Color = a.get_pixel(x,y)
            var two: Color = b.get_pixel(x,y)
            if absf(one.r-two.r)+absf(one.g-two.g)+absf(one.b-two.b)>0.18:
                count+=1
    return count

func _pair(a: Image,b: Image) -> void:
    var left: Image = a.duplicate()
    var right: Image = b.duplicate()
    left.resize(480,340,Image.INTERPOLATE_LANCZOS)
    right.resize(480,340,Image.INTERPOLATE_LANCZOS)
    var result := Image.create(960,340,false,Image.FORMAT_RGBA8)
    result.blit_rect(left,Rect2i(0,0,480,340),Vector2i.ZERO)
    result.blit_rect(right,Rect2i(0,0,480,340),Vector2i(480,0))
    assert(result.save_png("res://artifacts/tarvoka_hq_v12_hero_vs_v13_tactical_runtime.png")==OK)

func _run() -> void:
    assert(Production.build(0,0)==null)
    assert(Production.build(4,0)==null)
    assert(Production.build(1,-1)==null)
    assert(Production.build(1,8)==null)
    assert(Production.build(1,0,"ficticio")==null)
    assert(Production.build(1,0,"operativo","unknown")==null)
    var cases: int = 0
    var same_mesh: ArrayMesh = null
    for level in [1,2,3]:
        for faction in range(8):
            for condition in Production.STATES:
                var model: Node3D = Production.build(
                    level,faction,condition,Production.QUALITY_TACTICAL,true)
                assert(model != null)
                assert(model.get_meta("tarvoka_hq_production_v13",false))
                assert(model.get_meta("visual_level",-1)==level)
                assert(model.get_meta("visual_faction",-1)==faction)
                assert(model.get_meta("visual_condition","")==condition)
                assert(not model.get_meta("tarvoka_hq_visual_v12",false))
                assert(model.find_child("ArquitecturaCompletaV4",true,false)==null)
                assert(model.find_child("CubiertasArquitectonicasPerfilTacticoV12",true,false)==null)
                var shell: MeshInstance3D = model.find_child(
                    "MallaTacticaConCurvasV13",true,false) as MeshInstance3D
                assert(shell != null and shell.mesh is ArrayMesh)
                assert(shell.mesh.get_surface_count()==9)
                var crest: MeshInstance3D = model.find_child(
                    "EscudoOficialFaccion3D",true,false) as MeshInstance3D
                assert(crest != null)
                assert(crest.get_meta("tarvoka_official_emblem_index",-1)==faction)
                var material: StandardMaterial3D = crest.material_override as StandardMaterial3D
                assert(material != null and material.albedo_texture==Emblems.emblem_texture(faction))
                var selection: Area3D = model.find_child(
                    "ProxySeleccionHQV13",true,false) as Area3D
                assert(selection != null and not selection.monitoring)
                assert(selection.collision_layer==Production.SELECTION_LAYER)
                assert(selection.collision_mask==0)
                assert(selection.get_child_count()==1)
                var collision: CollisionShape3D = selection.get_child(0) as CollisionShape3D
                assert(collision != null and collision.shape is BoxShape3D)
                var budget: Dictionary = Production.render_budget(model)
                assert(budget["meshes"]==2)
                assert(budget["surfaces"]==10)
                assert(budget["within_tactical_budget"])
                var shared: Node3D = Production.build(level,faction,condition)
                assert(shared != null)
                var other: MeshInstance3D = shared.find_child(
                    "MallaTacticaConCurvasV13",true,false) as MeshInstance3D
                assert(other.mesh==shell.mesh)
                shared.free()
                model.free()
                cases+=1
    assert(cases==96)
    assert(Production.cached_variant_count()==96)
    var hero: Node3D = Production.build(3,0,"operativo",Production.QUALITY_HERO)
    assert(hero != null and hero.get_meta("tarvoka_hq_visual_v12",false))
    var hero_metrics: Dictionary = Production.render_budget(hero)
    assert(hero_metrics["meshes"]>100)
    hero.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio != null and studio.has_method("_switch_category"))
    root.add_child(studio)
    for i in range(8):
        await process_frame
    studio._switch_category(1)
    assert(studio.hq_production_toggle != null)
    assert(not studio.hq_production_toggle.button_pressed)
    studio.hq_camera_picker.select(1)
    studio._change_hq_camera(1)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for i in range(10):
        await process_frame
    var full: Image = studio.preview.get_texture().get_image()
    studio.hq_production_toggle.set_pressed_no_signal(true)
    studio._change_hq_production_v13(true)
    for i in range(10):
        await process_frame
    assert(studio.model_root.get_meta("tarvoka_hq_production_v13",false))
    assert(studio.hq_production_metric_label.visible)
    assert(not studio.hq_map_lod_toggle.visible)
    var tactical: Image = studio.preview.get_texture().get_image()
    assert(_pixels_different(full,tactical)>60)
    _pair(full,tactical)
    assert(tactical.save_png("res://artifacts/tarvoka_hq_v13_optimized_tactical.png")==OK)
    var montage := Image.create(1280,480,false,Image.FORMAT_RGBA8)
    for faction in range(8):
        studio._select_faction_view(faction)
        assert(studio.faction_picker.selected==faction)
        assert(studio.faction_view_buttons[faction].button_pressed)
        assert(studio.faction_view_buttons[faction].icon==Emblems.emblem_texture(faction))
        assert(studio.faction_view_label.text.find(
            str(Style.FACTIONS[faction]["name"]))>=0)
        assert(studio.model_root.get_meta("tarvoka_hq_production_v13",false))
        assert(Production.render_budget(studio.model_root)["within_tactical_budget"])
        for frame in range(4):
            await process_frame
        var image: Image = studio.preview.get_texture().get_image()
        image.resize(320,240,Image.INTERPOLATE_LANCZOS)
        montage.blit_rect(image,Rect2i(0,0,320,240),
            Vector2i((faction%4)*320,int(faction/4)*240))
    assert(montage.save_png(
        "res://artifacts/tarvoka_hq_v13_eight_official_faction_lods.png")==OK)

    studio.building_state_picker.select(2)
    studio._change_building_variant(2)
    for i in range(10):
        await process_frame
    assert(studio.model_root.get_meta("visual_condition","")=="danado")
    assert(studio.preview.get_texture().get_image().save_png(
        "res://artifacts/tarvoka_hq_v13_tactical_damage.png")==OK)
    studio._switch_category(0)
    assert(studio._role=="tank" and studio.faction_view_grid.visible)
    studio._select_faction_view(7)
    studio._switch_category(1)
    assert(studio._faction==7)
    assert(studio.model_root.get_meta("tarvoka_hq_production_v13",false))
    studio.hq_production_toggle.set_pressed_no_signal(false)
    studio._change_hq_production_v13(false)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    studio.queue_free()

    print("PASS HQ V13: %d independent 3D production variants, 2 meshes/10 surfaces, official 8-faction art, selectable proxy and hero comparison" % cases)
    quit(0)
