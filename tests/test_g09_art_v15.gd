extends SceneTree

# Actual Godot visual regression: in-place G09 V15 sculpt compared with V14.
# Faction slots, 5 reversible HP states, same rig and Android default remain.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(7):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    image.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return image

func _run() -> void:
    var base: Node3D = Models.build("tank",0,true,14)
    var refined: Node3D = Models.build("tank",0,true,15)
    assert(base != null and refined != null)
    assert(not base.get_meta("tarvoka_mbt_integrated_v15",false))
    assert(refined.get_meta("tarvoka_mbt_integrated_v15",false))
    assert(int(refined.get_meta("tarvoka_mbt_integrated_v15_pbr_count",0)) == 9)
    assert(Models.paintable_count(base) == 14)
    assert(Models.paintable_count(refined) == 14)

    for side in [-1,1]:
        for prefix in ["G09V14AlaBlindadaFrontal_",
                "G09V14LomoBlindadoCentral_",
                "G09V14HombroMotorPosterior_",
                "G09V14CarrilleraEscalonada_"]:
            var old: MeshInstance3D = base.find_child(
                prefix+str(side),true,false) as MeshInstance3D
            var new: MeshInstance3D = refined.find_child(
                prefix+str(side),true,false) as MeshInstance3D
            assert(old != null and new != null)
            assert(old.mesh is ArrayMesh and new.mesh is ArrayMesh)
            assert(old.get_parent().name == new.get_parent().name)
            assert(old.material_override != new.material_override)
            assert(new.visible)
        var old_wing: MeshInstance3D = base.find_child(
            "G09V14AlaBlindadaFrontal_"+str(side),true,false) as MeshInstance3D
        var new_wing: MeshInstance3D = refined.find_child(
            "G09V14AlaBlindadaFrontal_"+str(side),true,false) as MeshInstance3D
        assert(new_wing.mesh.get_aabb().size.x < old_wing.mesh.get_aabb().size.x-0.11)
        var old_roof: float = old_wing.mesh.get_aabb().end.y
        var new_roof: float = new_wing.mesh.get_aabb().end.y
        assert(new_roof < old_roof-0.05)
        for prefix in ["G09V14CantoProa_","G09V14NervioLongitudinal_",
                "G09V14JuntaCarrillera_"]:
            var retired: Node3D = refined.find_child(
                prefix+str(side),true,false) as Node3D
            assert(retired != null and not retired.visible)
        var active: MeshInstance3D = refined.find_child(
            "G09V15CosturaCarrillera_"+str(side),true,false) as MeshInstance3D
        assert(active != null and active.visible)

    assert(Rig.has_rig(refined))
    assert(Rig.pose(refined,"move",0.50,Vector2i(1,0)))
    assert(Rig.pose(refined,"attack",0.50,Vector2i(-1,0)))
    Rig.restore(refined)
    assert(Damage.apply_stage(refined,3))
    assert(not refined.find_child("G09V14AlaBlindadaFrontal_1",true,false).visible)
    assert(refined.find_child("G09V14AlaBlindadaFrontal_-1",true,false).visible)
    assert(not refined.find_child("G09V15SoldaduraHombro_1",true,false).visible)
    assert(Damage.apply_stage(refined,4))
    assert(not refined.find_child("G09V14QuillaFrontal",true,false).visible)
    assert(Damage.apply_stage(refined,0))
    assert(refined.find_child("G09V14QuillaFrontal",true,false).visible)
    assert(refined.find_child("G09V15SoldaduraHombro_1",true,false).visible)
    assert(not refined.find_child("G09V14CantoProa_1",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(refined,faction) == 14)
    base.free()
    refined.free()

    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v14()
    assert(studio._v14_preview)
    var original: Image = await _capture(studio)
    var angle: float = studio._yaw
    var zoom: float = studio._zoom
    studio._toggle_v15()
    assert(studio._v15_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_integrated_v15",false))
    assert(is_equal_approx(angle,studio._yaw))
    assert(is_equal_approx(zoom,studio._zoom))
    var proposed: Image = await _capture(studio)
    var delta: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = original.get_pixel(x,y)
            var b: Color = proposed.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.13:
                delta += 1
    assert(delta > 75)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var compare := Image.create(960,330,false,Image.FORMAT_RGBA8)
    compare.blit_rect(original,Rect2i(0,0,480,330),Vector2i.ZERO)
    compare.blit_rect(proposed,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(compare.save_png("res://artifacts/tarvoka_g09_v14_v15_same_camera.png") == OK)

    var angles: Image = Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for n in range(4):
        studio._reset_camera()
        studio._rotate(float(n)*90.0)
        var shot: Image = await _capture(studio)
        angles.blit_rect(shot,Rect2i(0,0,480,330),Vector2i(n*480,0))
    assert(angles.save_png("res://artifacts/tarvoka_g09_v15_four_angles.png") == OK)

    var damage: Image = Image.create(1440,330,false,Image.FORMAT_RGBA8)
    for n in range(3):
        studio._reset_camera()
        studio._set_damage([0,3,4][n])
        var shot: Image = await _capture(studio)
        damage.blit_rect(shot,Rect2i(0,0,480,330),Vector2i(n*480,0))
    assert(damage.save_png("res://artifacts/tarvoka_g09_v15_three_damage_states.png") == OK)
    studio._set_damage(0)
    studio._toggle_v15()
    assert(not studio._v15_preview and studio._v14_preview)
    studio.queue_free()
    print("PASS G09 V15: 9 in-place integrated shells, silhouette delta %d, no retired seams, 14 colors, 8 factions, 5 reversible HP stages and 3 render sheets" % delta)
    quit(0)
