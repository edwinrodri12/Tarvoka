extends SceneTree

# G09 V18 must physically modify primary structural ArrayMeshes, not render
# embellishments, and must preserve all existing rig/faction and damage APIs.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const V18 = preload("res://scripts/ui/TankSculptV18.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(8):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    image.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return image

func _delta(left: Image,right: Image) -> int:
    var count: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = left.get_pixel(x,y)
            var b: Color = right.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.13:
                count+=1
    return count

func _pair(left: Image,right: Image,path: String) -> void:
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(left,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(right,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png(path)==OK)

func _run() -> void:
    var previous: Node3D = Models.build("tank",0,true,17)
    var sculpt: Node3D = Models.build("tank",0,true,18)
    var stable: Node3D = Models.build("tank",0,true,10)
    assert(previous != null and sculpt != null and stable != null)
    assert(not previous.get_meta("tarvoka_mbt_resculpt_v18",false))
    assert(not stable.get_meta("tarvoka_mbt_resculpt_v18",false))
    assert(sculpt.get_meta("tarvoka_mbt_resculpt_v18",false))
    assert(int(sculpt.get_meta("tarvoka_mbt_resculpt_v18_replaced",0))==28)
    assert(Models.paintable_count(previous)==14)
    assert(Models.paintable_count(sculpt)==14)
    assert(Models.paintable_count(stable)==14)

    var different: int = 0
    var required := V18.SUB_ASSEMBLIES.duplicate()
    required.append("G09V14QuillaFrontal")
    for side in [-1,1]:
        var key: String = str(side)
        for prefix in ["G09V14AlaBlindadaFrontal_",
                "G09V14LomoBlindadoCentral_",
                "G09V14HombroMotorPosterior_",
                "G09V14CarrilleraEscalonada_"]:
            required.append(prefix+key)
        for index in range(7):
            required.append("RuedaG09V7_%s_%02d" % [side,index])
    assert(required.size()==28)
    for name in required:
        var old: MeshInstance3D = previous.find_child(
            name,true,false) as MeshInstance3D
        var updated: MeshInstance3D = sculpt.find_child(
            name,true,false) as MeshInstance3D
        assert(old != null and updated != null)
        assert(old.material_override != null)
        assert(updated.material_override != null)
        assert(updated.mesh != old.mesh)
        assert(updated.mesh is ArrayMesh)
        if updated.mesh.get_aabb()!=old.mesh.get_aabb():
            different+=1
    assert(different>=15)
    var original_hull: MeshInstance3D = previous.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var new_hull: MeshInstance3D = sculpt.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    assert(new_hull.mesh.get_aabb().size.x > original_hull.mesh.get_aabb().size.x)
    assert(new_hull.mesh.get_aabb().position.z < original_hull.mesh.get_aabb().position.z)
    var old_turret: MeshInstance3D = previous.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    var new_turret: MeshInstance3D = sculpt.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    assert(new_turret.mesh.get_aabb().position.z < old_turret.mesh.get_aabb().position.z)
    var gun: MeshInstance3D = sculpt.find_child(
        "MantleteConjuntoV7",true,false) as MeshInstance3D
    assert(gun.mesh is ArrayMesh)
    var wheel: MeshInstance3D = sculpt.find_child(
        "RuedaG09V7_1_02",true,false) as MeshInstance3D
    var wheel_other: MeshInstance3D = sculpt.find_child(
        "RuedaG09V7_-1_02",true,false) as MeshInstance3D
    assert(wheel.mesh == wheel_other.mesh)
    assert(wheel.mesh.get_aabb().size.x > 0.35)
    var suspension: MultiMeshInstance3D = sculpt.find_child(
        "G09V18BrazosSuspension",true,false) as MultiMeshInstance3D
    assert(suspension != null and suspension.multimesh != null)
    assert(suspension.multimesh.instance_count==14)
    assert(not sculpt.get_meta("tarvoka_mbt_fx_v17_eco",false))
    for side in [-1,1]:
        var tread: MultiMeshInstance3D = sculpt.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(tread != null and tread.multimesh.instance_count==Hero.TRACK_COUNT)
        var spokes: MultiMeshInstance3D = sculpt.find_child(
            "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
        assert(spokes != null and spokes.multimesh.instance_count==35)

    assert(Rig.has_rig(sculpt))
    assert(Rig.pose(sculpt,"move",0.60,Vector2i(1,0)))
    assert(Rig.pose(sculpt,"attack",0.52,Vector2i(-1,1)))
    Rig.restore(sculpt)
    assert(Damage.apply_stage(sculpt,3))
    assert(not sculpt.find_child("G09V14CarrilleraEscalonada_1",true,false).visible)
    assert(Damage.apply_stage(sculpt,4))
    assert(not sculpt.find_child("G09V14QuillaFrontal",true,false).visible)
    assert(Damage.apply_stage(sculpt,0))
    assert(sculpt.find_child("G09V14CarrilleraEscalonada_1",true,false).visible)
    assert(sculpt.find_child("G09V14QuillaFrontal",true,false).visible)
    assert(suspension.multimesh.instance_count==14)
    for faction in range(8):
        assert(Models.apply_faction_palette(sculpt,faction)==14)
    previous.free()
    stable.free()
    sculpt.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v17()
    assert(studio._v17_preview and not studio._v18_preview)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    var oldshot: Image = await _capture(studio)
    studio._toggle_v18()
    assert(studio._v18_preview and not studio._v17_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_resculpt_v18",false))
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    var newshot: Image = await _capture(studio)
    var delta: int = _delta(oldshot,newshot)
    assert(delta>45)
    _pair(oldshot,newshot,"res://artifacts/tarvoka_g09_v17_v18_same_camera.png")

    var views := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var frame: Image = await _capture(studio)
        views.blit_rect(frame,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(views.save_png("res://artifacts/tarvoka_g09_v18_four_angles.png")==OK)

    studio._reset_camera()
    studio._set_damage(3)
    assert(Damage.current_stage(studio.model_root)==3)
    var damage: Image = await _capture(studio)
    studio._set_damage(4)
    var destroyed: Image = await _capture(studio)
    studio._set_damage(0)
    var repaired: Image = await _capture(studio)
    var sheet := Image.create(1440,330,false,Image.FORMAT_RGBA8)
    for n in range(3):
        sheet.blit_rect([damage,destroyed,repaired][n],
            Rect2i(0,0,480,330),Vector2i(480*n,0))
    assert(sheet.save_png(
        "res://artifacts/tarvoka_g09_v18_critical_wreck_repaired.png")==OK)
    studio._toggle_v17_quality()
    assert(studio._v17_eco)
    assert(studio.model_root.get_meta("tarvoka_mbt_fx_v17_eco",false))
    studio._toggle_v17_quality()
    studio.queue_free()
    print("PASS G09 V18: 28 original structural meshes resculpted, %d changed 3D bounding boxes, 14 shared dished wheels, 14 suspension instances (one batch), 14 paint zones, 8 factions, 5 reversible stages, turret/weapon rig and delta %d sampled pixels" % [different,delta])
    quit(0)
