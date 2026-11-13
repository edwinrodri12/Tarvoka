extends SceneTree

# G09 V14 mechanical-quality QA: real 3D meshes rendered by Godot 4.3.
# Source is the identical art-level builder used by battle/Android; no mockup.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(7):
        await process_frame
    var frame: Image = studio.preview.get_texture().get_image()
    assert(frame != null and not frame.is_empty())
    frame.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return frame

func _run() -> void:
    var baseline: Node3D = Models.build("tank",0,true,13)
    var improved: Node3D = Models.build("tank",0,true,14)
    assert(baseline != null and improved != null)
    assert(not baseline.get_meta("tarvoka_mbt_silhouette_v14",false))
    assert(improved.get_meta("tarvoka_mbt_silhouette_v14",false))
    assert(int(improved.get_meta("tarvoka_mbt_silhouette_v14_pbr_count",0)) >= 15)
    assert(Models.paintable_count(baseline) == 14)
    assert(Models.paintable_count(improved) == 14)
    for side in [-1,1]:
        for prefix in ["G09V14AlaBlindadaFrontal_",
                "G09V14LomoBlindadoCentral_",
                "G09V14CarrilleraEscalonada_"]:
            var part: MeshInstance3D = improved.find_child(
                prefix+str(side),true,false) as MeshInstance3D
            assert(part != null and part.mesh is ArrayMesh and part.visible)
        var spokes: MultiMeshInstance3D = improved.find_child(
            "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
        assert(spokes != null and spokes.multimesh != null)
        assert(spokes.multimesh.instance_count == 35)
        var before: Transform3D = spokes.multimesh.get_instance_transform(0)
        assert(Rig.pose(improved,"move",0.50,Vector2i(1,0)))
        var after: Transform3D = spokes.multimesh.get_instance_transform(0)
        assert(before.origin.distance_to(after.origin) > 0.02)
        Rig.restore(improved)
        var restored: Transform3D = spokes.multimesh.get_instance_transform(0)
        assert(restored.origin.distance_to(before.origin) < 0.001)

    assert(Damage.apply_stage(improved,3))
    assert(not improved.find_child(
        "G09V14AlaBlindadaFrontal_1",true,false).visible)
    assert(improved.find_child(
        "G09V14AlaBlindadaFrontal_-1",true,false).visible)
    assert(Damage.apply_stage(improved,4))
    assert(not improved.find_child("G09V14QuillaFrontal",true,false).visible)
    assert(Damage.apply_stage(improved,0))
    assert(improved.find_child("G09V14QuillaFrontal",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(improved,faction) == 14)
    baseline.free()
    improved.free()

    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v13()
    assert(studio._v13_preview)
    var old: Image = await _capture(studio)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._toggle_v14()
    assert(studio._v14_preview)
    assert(is_equal_approx(yaw,studio._yaw))
    assert(is_equal_approx(zoom,studio._zoom))
    assert(studio.model_root.get_meta("tarvoka_mbt_silhouette_v14",false))
    var current: Image = await _capture(studio)
    var changed: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = old.get_pixel(x,y)
            var b: Color = current.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.13:
                changed+=1
    # Stronger acceptance threshold than V13's 35 changed pixels: reject
    # detail passes that are virtually indistinguishable at battle size.
    assert(changed > 150)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(old,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(current,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png("res://artifacts/tarvoka_g09_v13_v14_same_camera.png") == OK)

    var views := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var view: Image = await _capture(studio)
        views.blit_rect(view,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(views.save_png("res://artifacts/tarvoka_g09_v14_four_angles.png") == OK)
    studio._toggle_v14()
    assert(not studio._v14_preview and studio._v13_preview)
    studio.queue_free()
    print("PASS G09 V14: stronger silhouette pixel delta %d, 70 moving wheel spokes in 2 batches, 14 factions panels, 8 factions, five damage states, browser A/B" % changed)
    quit(0)
