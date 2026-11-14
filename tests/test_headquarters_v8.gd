extends SceneTree

# Godot GPU assurance: the V8 material pass exists as true Godot geometry
# and surface resources, preserving factions and old sculpt versions.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _meshes(child)
    return count

func _diff(a: Image,b: Image) -> int:
    var first := a.duplicate()
    var second := b.duplicate()
    first.resize(480,330,Image.INTERPOLATE_LANCZOS)
    second.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var different := 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var u: Color = first.get_pixel(x,y)
            var v: Color = second.get_pixel(x,y)
            if absf(u.r-v.r)+absf(u.g-v.g)+absf(u.b-v.b) > 0.14:
                different += 1
    return different

func _save_comparison(before: Image,after: Image) -> void:
    var old := before.duplicate()
    var fresh := after.duplicate()
    old.resize(480,330,Image.INTERPOLATE_LANCZOS)
    fresh.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(old,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(fresh,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sheet.save_png("res://artifacts/tarvoka_hq_v7_vs_v8_pbr.png") == OK)

func _run() -> void:
    for level in [1,2,3]:
        var v7: Node3D = HQ.build(level,0,"operativo",true,true,true,true,false)
        var v8: Node3D = HQ.build(level,0,"operativo",true,true,true,true,true)
        assert(v7 != null and v8 != null)
        assert(v7.get_meta("tarvoka_hq_visual_v7",false))
        assert(not v7.get_meta("tarvoka_hq_visual_v8",false))
        assert(v8.get_meta("tarvoka_hq_visual_v8",false))
        assert(int(v8.get_meta("tarvoka_hq_v8_pbr_overrides",0)) >= 15)
        assert(_meshes(v8) > _meshes(v7)+30)
        assert(v8.find_child("UnionesEstructuralesV8",true,false) != null)
        assert(v8.find_child("JuntaExpansionFachada_-1",true,false) != null)
        assert(v8.find_child("JuntaExpansionFachada_1",true,false) != null)
        assert(v8.find_child("CanalDeDrenajeAcceso",true,false) != null)
        assert(v8.find_child("RemachesFachadaPBRV8",true,false) != null)
        var near: Node3D = v8.find_child("MicroAcabadosV8",true,false) as Node3D
        assert(near != null and not near.visible)
        HQ.set_render_detail(v8,true)
        assert(near.visible)
        HQ.set_render_detail(v8,false)
        assert(not near.visible)
        var sheet: MeshInstance3D = v8.find_child(
            "CubiertaConvexaAla_1",true,false) as MeshInstance3D
        assert(sheet != null)
        var pbr: StandardMaterial3D = sheet.material_override as StandardMaterial3D
        assert(pbr != null and pbr.normal_enabled)
        assert(pbr.albedo_texture != null)
        assert(pbr.normal_texture != null)
        assert(pbr.roughness_texture != null)
        assert(v8.find_child("EscudoOficialFaccion3D",true,false) != null)
        v7.free()
        v8.free()

    for faction in range(8):
        var hq: Node3D = HQ.build(1,faction,"capturado")
        assert(hq != null and hq.get_meta("tarvoka_hq_visual_v8",false))
        var crest: MeshInstance3D = hq.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(crest != null)
        assert(crest.get_meta("tarvoka_official_emblem_index",-1)==faction)
        hq.free()
    var damage: Node3D = HQ.build(2,1,"danado")
    assert(damage != null)
    var whole: MeshInstance3D = damage.find_child(
        "HojaCristalBlindado_-1",true,false) as MeshInstance3D
    assert(whole != null and not whole.visible)
    var fragments: MeshInstance3D = damage.find_child(
        "FragmentosDeVidrioConVacioV8",true,false) as MeshInstance3D
    assert(fragments != null and fragments.mesh is ArrayMesh)
    assert((fragments.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > 18)
    assert(damage.find_child("QuemadurasFísicasV8",true,false) != null)
    damage.free()
    var ruined: Node3D = HQ.build(3,7,"destruido")
    assert(ruined != null and ruined.get_meta("tarvoka_hq_visual_v8",false))
    assert(ruined.find_child("RuinaMetalicaDeMaterialesV8",true,false) != null)
    assert(ruined.find_child("UnionesEstructuralesV8",true,false) == null)
    assert(ruined.find_child("EscudoOficialFaccion3D",true,false) != null)
    ruined.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == preload("res://scripts/ui/EnvironmentArtStudioWeb.gd"))
    root.add_child(studio)
    for i in range(8):
        await process_frame
    studio._switch_category(1)
    assert(studio.hq_v8_toggle.button_pressed)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v8",false))
    studio.hq_v8_toggle.set_pressed_no_signal(false)
    studio._change_hq_materials_v8(false)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v7",false))
    assert(not studio.model_root.get_meta("tarvoka_hq_visual_v8",false))
    for i in range(10):
        await process_frame
    var old: Image = studio.preview.get_texture().get_image()
    studio.hq_v8_toggle.set_pressed_no_signal(true)
    studio._change_hq_materials_v8(true)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v8",false))
    for i in range(10):
        await process_frame
    var fresh: Image = studio.preview.get_texture().get_image()
    assert(not old.is_empty() and not fresh.is_empty())
    assert(_diff(old,fresh) > 60)
    _save_comparison(old,fresh)
    studio._change_zoom(1)
    studio._change_zoom(1)
    for i in range(8):
        await process_frame
    var close: Image = studio.preview.get_texture().get_image()
    assert(close.save_png("res://artifacts/tarvoka_hq_v8_pbr_closeup.png")==OK)
    studio._reset_camera()
    studio.building_state_picker.select(2)
    studio._change_building_variant(2)
    for i in range(8):
        await process_frame
    var damage_image: Image = studio.preview.get_texture().get_image()
    assert(damage_image.save_png("res://artifacts/tarvoka_hq_v8_fractured_glass.png")==OK)
    studio._switch_category(0)
    assert(studio._role == "tank" and studio.model_root != null)
    studio.queue_free()
    print("PASS HQ V8: original PBR textures, 8 approved crests, construction joints, broken glass and same-camera V7/V8 GPU comparison")
    quit(0)
