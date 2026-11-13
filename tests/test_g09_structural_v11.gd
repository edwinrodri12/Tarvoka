extends SceneTree

# Physical, pixel-visible V11 silhouette QA in the SAME Godot renderer as
# TARVOKA Android and the no-install browser studio. No concept paintings.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(6):
        await process_frame
    var texture: Texture2D = studio.preview.get_texture()
    assert(texture != null)
    var result: Image = texture.get_image()
    assert(result != null and not result.is_empty())
    result.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return result

func _run() -> void:
    var v10: Node3D = Models.build("tank",0,true,10)
    var v11: Node3D = Models.build("tank",0,true,11)
    assert(v10 != null and v11 != null)
    assert(v10.get_meta("tarvoka_mbt_sculpted_v10",false))
    assert(not v10.get_meta("tarvoka_mbt_structural_v11",false))
    assert(v11.get_meta("tarvoka_mbt_structural_v11",false))
    assert(int(v11.get_meta("tarvoka_mbt_structural_v11_pbr_count",0)) >= 9)
    assert(Models.paintable_count(v10)==14 and Models.paintable_count(v11)==14)
    var old_body: MeshInstance3D = v10.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var new_body: MeshInstance3D = v11.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var old_turret: MeshInstance3D = v10.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    var new_turret: MeshInstance3D = v11.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    assert(old_body!=null and new_body!=null and old_turret!=null and new_turret!=null)
    assert(new_body.mesh.get_aabb().size.z > old_body.mesh.get_aabb().size.z+0.15)
    assert(new_turret.mesh.get_aabb().size.x > old_turret.mesh.get_aabb().size.x+0.24)
    assert(new_body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >
        old_body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size())
    assert(new_turret.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >
        old_turret.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size())
    for side in [-1,1]:
        var cheek: MeshInstance3D = v11.find_child(
            "G09V11MordazaAngular_%s" % side,true,false) as MeshInstance3D
        var glacis: MeshInstance3D = v11.find_child(
            "G09V11PuntaGlacis_%s" % side,true,false) as MeshInstance3D
        assert(cheek != null and glacis != null)
        assert(cheek.visible and glacis.visible)
        assert(cheek.mesh is ArrayMesh and glacis.mesh is ArrayMesh)
        var coat: StandardMaterial3D = cheek.material_override as StandardMaterial3D
        assert(coat != null and coat.normal_enabled and coat.albedo_texture != null)
    assert(not v11.find_child("G09V10MejillaCompuesta_1",true,false).visible)
    assert(Damage.apply_stage(v11,3))
    assert(not v11.find_child("G09V11MordazaAngular_1",true,false).visible)
    assert(Damage.apply_stage(v11,4))
    assert(not v11.find_child("G09V11BastionPosterior_-1",true,false).visible)
    assert(Damage.apply_stage(v11,0))
    assert(v11.find_child("G09V11MordazaAngular_1",true,false).visible)
    assert(v11.find_child("G09V11BastionPosterior_-1",true,false).visible)
    v10.free()
    v11.free()

    var studio := Studio.new()
    root.add_child(studio)
    assert(studio.model_root != null)
    assert(not studio._v11_preview)
    var old: Image = await _capture(studio)
    studio._toggle_v11()
    assert(studio._v11_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_structural_v11",false))
    var new_model: Image = await _capture(studio)
    var changed: int = 0
    for y in range(0,330,3):
        for x in range(0,480,3):
            var a: Color = old.get_pixel(x,y)
            var b: Color = new_model.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.13:
                changed+=1
    assert(changed>170)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(old,Rect2i(0,0,480,330),Vector2i(0,0))
    comparison.blit_rect(new_model,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(comparison.save_png("res://artifacts/tarvoka_g09_v10_vs_v11_same_camera.png")==OK)

    var turntable := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    turntable.fill(Color("#14232D"))
    for angle in range(4):
        studio._reset_camera()
        studio._rotate(float(angle)*90.0)
        var view: Image = await _capture(studio)
        turntable.blit_rect(view,Rect2i(0,0,480,330),Vector2i(angle*480,0))
    assert(turntable.save_png("res://artifacts/tarvoka_g09_v11_four_angles.png")==OK)
    studio.queue_free()
    print("PASS G09 V11: new physical closed shells, wide arrow cheeks, 14 faction paint zones, reversible damage, same-camera visible 3D delta, 4-angle Godot turntable")
    quit(0)
