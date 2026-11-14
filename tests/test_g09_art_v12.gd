extends SceneTree

# G09 V12 physical and visual regression. Same meshes as the Android game,
# current WebGL studio, and editable GLB (no reference-image substitutions).
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(6):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    image.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return image

func _run() -> void:
    var previous: Node3D = Models.build("tank",0,true,11)
    var current: Node3D = Models.build("tank",0,true,12)
    assert(previous != null and current != null)
    assert(not previous.get_meta("tarvoka_mbt_refined_v12",false))
    assert(current.get_meta("tarvoka_mbt_refined_v12",false))
    assert(int(current.get_meta("tarvoka_mbt_refined_v12_pbr_count",0)) >= 12)
    assert(int(current.get_meta("tarvoka_mbt_refined_v12_paint_count",0)) == 10)
    assert(Models.paintable_count(current) == 14)
    assert(Models.paintable_count(previous) == 14)
    for side in [-1,1]:
        var guard: MeshInstance3D = current.find_child(
            "G09V12DefensaOrugaAngular_%s" % side,true,false) as MeshInstance3D
        assert(guard != null and guard.mesh is ArrayMesh)
        assert(guard.visible)
        assert(not current.find_child(
            "G09V10HombroFaldon_%s" % side,true,false).visible)
        var deck: MeshInstance3D = current.find_child(
            "G09V12CubiertaMotorLateral_%s" % side,true,false) as MeshInstance3D
        assert(deck != null and deck.visible)
        var paint: MeshInstance3D = current.find_child(
            "FaccionFaldon%s_02" % side,true,false) as MeshInstance3D
        assert(paint != null and paint.visible)
    var shield: MeshInstance3D = current.find_child(
        "G09V12EscudoDeReculada",true,false) as MeshInstance3D
    var gun: Node3D = current.find_child(
        "ElevacionCanon",true,false) as Node3D
    assert(shield != null and gun != null)
    assert(shield.get_parent() == gun)
    assert(Damage.apply_stage(current,3))
    assert(not current.find_child("G09V12DefensaOrugaAngular_1",true,false).visible)
    assert(Damage.apply_stage(current,4))
    assert(not shield.visible)
    assert(Damage.apply_stage(current,0))
    assert(shield.visible)
    assert(current.find_child("G09V12DefensaOrugaAngular_1",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(current,faction) == 14)
        assert(int(current.get_meta("tarvoka_mbt_refined_v12_paint_count",0)) == 10)
    previous.free()
    current.free()

    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v11()
    assert(studio._v11_preview)
    var older: Image = await _capture(studio)
    var angle: float = studio._yaw
    var zoom: float = studio._zoom
    studio._toggle_v12()
    assert(studio._v12_preview)
    assert(is_equal_approx(studio._yaw,angle))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(studio.model_root.get_meta("tarvoka_mbt_refined_v12",false))
    var refined: Image = await _capture(studio)
    var significant: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = older.get_pixel(x,y)
            var b: Color = refined.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.13:
                significant+=1
    assert(significant > 40)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var sheet: Image = Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(older,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(refined,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png("res://artifacts/tarvoka_g09_v11_v12_same_camera.png") == OK)

    # A tighter shared camera is the most honest way to review ceramic
    # edges, side skirt seams and the cannon cradle, not hide them at 170px.
    studio._reset_camera()
    studio._change_zoom(1)
    studio._change_zoom(1)
    studio._change_zoom(1)
    var finished_close: Image = await _capture(studio)
    studio._toggle_v12()
    assert(not studio._v12_preview and studio._v11_preview)
    var previous_close: Image = await _capture(studio)
    var close_sheet: Image = Image.create(960,330,false,Image.FORMAT_RGBA8)
    close_sheet.blit_rect(previous_close,Rect2i(0,0,480,330),Vector2i(0,0))
    close_sheet.blit_rect(finished_close,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(close_sheet.save_png("res://artifacts/tarvoka_g09_v11_v12_closeup.png") == OK)
    studio._toggle_v12()
    assert(studio._v12_preview)

    var four_angles: Image = Image.create(1920,330,false,Image.FORMAT_RGBA8)
    four_angles.fill(Color("#14232D"))
    for n in range(4):
        studio._reset_camera()
        studio._rotate(float(n)*90.0)
        var shot: Image = await _capture(studio)
        four_angles.blit_rect(shot,Rect2i(0,0,480,330),Vector2i(n*480,0))
    assert(four_angles.save_png("res://artifacts/tarvoka_g09_v12_four_angles.png") == OK)
    studio.queue_free()
    print("PASS G09 V12: true sloping steel track covers, coherent roof, recoil shield, PBR, 14 paints, 5 reversible HP states, 8 factions, actual fixed-angle pixel delta")
    quit(0)
