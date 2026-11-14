extends SceneTree

# Regression: true tactical-scale silhouette, visible operational nighttime,
# all eight approved crest views, and independent legacy V11 toggle.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _count_meshes(root3d: Node) -> int:
    var result: int = 1 if root3d is MeshInstance3D else 0
    for child in root3d.get_children():
        result += _count_meshes(child)
    return result

func _diff_pixels(first: Image,second: Image) -> int:
    var a: Image = first.duplicate()
    var b: Image = second.duplicate()
    a.resize(480,320,Image.INTERPOLATE_LANCZOS)
    b.resize(480,320,Image.INTERPOLATE_LANCZOS)
    var changed: int = 0
    for y in range(0,320,4):
        for x in range(0,480,4):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.13:
                changed += 1
    return changed

func _avg_luma(img: Image) -> float:
    var sum: float = 0.0
    var count: int = 0
    for y in range(0,img.get_height(),8):
        for x in range(0,img.get_width(),8):
            var c: Color = img.get_pixel(x,y)
            sum += c.r*0.2126+c.g*0.7152+c.b*0.0722
            count += 1
    return sum/float(maxi(count,1))

func _save_pair(a: Image,b: Image,path: String) -> void:
    var x: Image = a.duplicate()
    var y: Image = b.duplicate()
    x.resize(480,320,Image.INTERPOLATE_LANCZOS)
    y.resize(480,320,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(960,320,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(x,Rect2i(0,0,480,320),Vector2i.ZERO)
    sheet.blit_rect(y,Rect2i(0,0,480,320),Vector2i(480,0))
    assert(sheet.save_png(path)==OK)

func _run() -> void:
    for level in [1,2,3]:
        var v11: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true,true,true,false)
        var v12: Node3D = HQ.build(level,0,"operativo",
            true,true,true,true,true,true,true,true,true)
        assert(v11 != null and v12 != null)
        assert(v11.get_meta("tarvoka_hq_visual_v11",false))
        assert(not v11.get_meta("tarvoka_hq_visual_v12",false))
        assert(v12.get_meta("tarvoka_hq_visual_v12",false))
        assert(v12.get_meta("tarvoka_hq_v12_visual_only",false))
        assert(_count_meshes(v12)>_count_meshes(v11)+35)
        var arch: MeshInstance3D = v12.find_child(
            "PetoCurvoDeAlaV12_1",true,false) as MeshInstance3D
        assert(arch != null and arch.mesh is ArrayMesh)
        assert((arch.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>400)
        assert(v12.find_child("PetoCurvoDeAlaV12_-1",true,false)!=null)
        assert(v12.find_child("BandaFaccionDeArcoV12_1",true,false)!=null)
        assert(v12.find_child("CoronacionDeMandoDeLejosV12",true,false)!=null)
        assert(v12.find_child("VivoCrestaDeFaccionMandoV12",true,false)!=null)
        assert(v12.find_child("CerchaArquitectonicaTejado_1_0",true,false)!=null)
        assert(v12.find_child("BalizamientoArquitectonicoV12",true,false)!=null)
        assert(v12.find_child("EscudoOficialFaccion3D",true,false)!=null)
        v11.free()
        v12.free()

    var damaged: Node3D = HQ.build(2,3,"danado")
    assert(damaged != null and damaged.get_meta("tarvoka_hq_visual_v12",false))
    var intact: MeshInstance3D = damaged.find_child(
        "PetoCurvoDeAlaV12_-1",true,false) as MeshInstance3D
    assert(intact != null and not intact.visible)
    assert(damaged.find_child("ArcoDeAlaV12Quebrado",true,false)!=null)
    damaged.free()
    var ruined: Node3D = HQ.build(3,7,"destruido")
    assert(ruined != null and ruined.get_meta("tarvoka_hq_visual_v12",false))
    assert(ruined.find_child("RestosCurvaturaTacticaV12",true,false)!=null)
    assert(ruined.find_child("CubiertasArquitectonicasPerfilTacticoV12",true,false)==null)
    ruined.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio.get_script()==Studio)
    root.add_child(studio)
    for i in range(8):
        await process_frame
    studio._switch_category(1)
    assert(studio.hq_v12_toggle.button_pressed)
    assert(studio.hq_camera_picker.item_count==2)
    studio.hq_camera_picker.select(1)
    studio._change_hq_camera(1)
    assert(studio._hq_camera_preset==1)
    assert(studio._zoom<0.75 and studio._zoom>0.65)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))

    var faction_sheet := Image.create(1280,480,false,Image.FORMAT_RGBA8)
    assert(studio.faction_view_buttons.size()==8)
    for f in range(8):
        studio._select_faction_view(f)
        assert(studio._faction==f)
        assert(studio.faction_picker.selected==f)
        assert(studio.faction_view_buttons[f].button_pressed)
        assert(studio.faction_view_buttons[f].icon==Emblems.emblem_texture(f))
        assert(studio.faction_view_label.text.find(
            str(Style.FACTIONS[f]["name"]))>=0)
        assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
        var crest: MeshInstance3D = studio.model_root.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(crest != null and crest.get_meta("tarvoka_official_emblem_index",-1)==f)
        for frame in range(4):
            await process_frame
        var small: Image = studio.preview.get_texture().get_image()
        small.resize(320,240,Image.INTERPOLATE_LANCZOS)
        faction_sheet.blit_rect(small,Rect2i(0,0,320,240),
            Vector2i((f%4)*320,int(f/4)*240))
    assert(faction_sheet.save_png(
        "res://artifacts/tarvoka_hq_v12_eight_tactical_factions.png")==OK)

    studio._select_faction_view(0)
    studio.hq_v12_toggle.set_pressed_no_signal(false)
    studio._change_hq_silhouette_v12(false)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v11",false))
    assert(not studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    for i in range(9):
        await process_frame
    var before: Image = studio.preview.get_texture().get_image()
    studio.hq_v12_toggle.set_pressed_no_signal(true)
    studio._change_hq_silhouette_v12(true)
    for i in range(9):
        await process_frame
    var after: Image = studio.preview.get_texture().get_image()
    assert(_diff_pixels(before,after)>80)
    _save_pair(before,after,
        "res://artifacts/tarvoka_hq_v11_vs_v12_tactical_same_camera.png")
    assert(after.save_png(
        "res://artifacts/tarvoka_hq_v12_tactical_day.png")==OK)

    studio.hq_lighting_picker.select(2)
    studio._change_hq_lighting(2)
    assert(studio.hq_night_lamps[0].visible)
    assert(studio.hq_key_light.light_energy > 0.65)
    assert(studio.hq_environment.environment.ambient_light_energy > 0.95)
    for i in range(12):
        await process_frame
    var night: Image = studio.preview.get_texture().get_image()
    assert(night != null and not night.is_empty())
    var luma: float = _avg_luma(night)
    # Bright enough to inspect, but visibly night (not a blue daytime sky).
    assert(luma>0.12)
    assert(luma<0.31)
    assert(_diff_pixels(after,night)>150)
    assert(night.save_png(
        "res://artifacts/tarvoka_hq_v12_readable_night.png")==OK)

    studio.hq_camera_picker.select(0)
    studio._change_hq_camera(0)
    assert(studio._zoom==1.0)
    for i in range(9):
        await process_frame
    var night_close: Image = studio.preview.get_texture().get_image()
    assert(night_close.save_png(
        "res://artifacts/tarvoka_hq_v12_night_detail.png")==OK)

    studio._switch_category(0)
    assert(studio._role=="tank")
    assert(studio.faction_view_grid.visible)
    assert(not studio.hq_night_lamps[0].visible)
    studio._select_faction_view(7)
    studio._switch_category(1)
    assert(studio._faction==7)
    assert(studio.model_root.get_meta("visual_faction",-1)==7)
    assert(studio.hq_night_lamps[0].visible)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    studio.queue_free()
    print("PASS HQ V12: actual tactical-size curved roof, readable night luminance, 8 official faction views, 3 levels, 4 damage states and same-camera V11/V12")
    quit(0)
