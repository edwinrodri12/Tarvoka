extends SceneTree

# The G09 V20 review compares actual source geometry, not rendered decals:
# 19 reworked existing mesh nodes, same draw submission for 14 suspension
# arms, 15 retired floating trims, 14 faction slots, eight palettes,
# five damage stages, working gun rig, studio clay A/B and real PNG outputs.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const V20 = preload("res://scripts/ui/TankIntegrationV20.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(8):
        await process_frame
    var result: Image = studio.preview.get_texture().get_image()
    assert(result != null and not result.is_empty())
    result.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return result

func _delta(a: Image,b: Image) -> int:
    var changed := 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var old: Color = a.get_pixel(x,y)
            var new: Color = b.get_pixel(x,y)
            if absf(old.r-new.r)+absf(old.g-new.g)+absf(old.b-new.b)>0.13:
                changed+=1
    return changed

func _pair(a: Image,b: Image,target: String) -> void:
    var sheet: Image = Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png(target)==OK)

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,19)
    var new: Node3D = Models.build("tank",0,true,20)
    var stable: Node3D = Models.build("tank",0,true)
    assert(old!=null and new!=null and stable!=null)
    assert(not old.get_meta("tarvoka_mbt_integrated_v20",false))
    assert(not stable.get_meta("tarvoka_mbt_integrated_v20",false))
    assert(new.get_meta("tarvoka_mbt_integrated_v20",false))
    assert(int(new.get_meta("tarvoka_mbt_integrated_v20_replaced",0))==19)
    assert(Models.paintable_count(old)==14)
    assert(Models.paintable_count(new)==14)
    assert(Models.paintable_count(stable)==14)

    var required := ["G09V13BastionMunicionesContinuo"]
    for side in [-1,1]:
        for index in range(5):
            required.append("G09V13FaldonSegmentado_%s_%02d" % [side,index])
        for prefix in ["FaldonBlindadoIntegradoV7_",
                "G09V14LomoBlindadoCentral_",
                "G09V14HombroMotorPosterior_",
                "G09V14CarrilleraEscalonada_"]:
            required.append(prefix+str(side))
    assert(required.size()==19)
    var different_geometry := 0
    for label in required:
        var prev: MeshInstance3D = old.find_child(
            label,true,false) as MeshInstance3D
        var current: MeshInstance3D = new.find_child(
            label,true,false) as MeshInstance3D
        assert(prev!=null and current!=null)
        assert(prev.name==current.name)
        assert(prev.get_parent().name==current.get_parent().name)
        assert(current.mesh is ArrayMesh)
        assert(current.mesh!=prev.mesh)
        var pa: Array = prev.mesh.surface_get_arrays(0)
        var na: Array = current.mesh.surface_get_arrays(0)
        var v0: PackedVector3Array = pa[Mesh.ARRAY_VERTEX]
        var v1: PackedVector3Array = na[Mesh.ARRAY_VERTEX]
        if v0.size()!=v1.size() or current.mesh.get_aabb()!=prev.mesh.get_aabb():
            different_geometry+=1
    print("G09 V20 genuinely different old mesh surface topology/AABB count: ",different_geometry)
    assert(different_geometry>=15)

    var prev_arms: MultiMeshInstance3D = old.find_child(
        "G09V18BrazosSuspension",true,false) as MultiMeshInstance3D
    var arms: MultiMeshInstance3D = new.find_child(
        "G09V18BrazosSuspension",true,false) as MultiMeshInstance3D
    assert(arms!=null and prev_arms!=null)
    assert(arms.multimesh.instance_count==14)
    assert(arms.multimesh.mesh is ArrayMesh)
    assert(arms.multimesh.mesh!=prev_arms.multimesh.mesh)
    for side in [-1,1]:
        var treads: MultiMeshInstance3D = new.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(treads!=null and treads.multimesh.instance_count==84)
    assert(Rig.has_rig(new))
    assert(Rig.pose(new,"move",0.60,Vector2i(1,0)))
    assert(Rig.pose(new,"attack",0.42,Vector2i(0,1)))
    Rig.restore(new)

    var retired := V20.RETIRED.duplicate()
    for side in [-1,1]:
        for segment in range(5):
            retired.append("G09V13RibeteFaldon_%s_%02d" % [side,segment])
    assert(retired.size()==15)
    for stage in range(5):
        assert(Damage.apply_stage(new,stage))
        for label in retired:
            var obsolete: Node3D = new.find_child(
                label,true,false) as Node3D
            assert(obsolete!=null and not obsolete.visible)
    assert(Damage.apply_stage(new,3))
    assert(not new.find_child("G09V13FaldonSegmentado_1_03",true,false).visible)
    assert(new.find_child("G09V13FaldonSegmentado_-1_03",true,false).visible)
    assert(Damage.apply_stage(new,0))
    assert(new.find_child("G09V13FaldonSegmentado_1_03",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(new,faction)==14)
    var skirt: MeshInstance3D = new.find_child(
        "G09V13FaldonSegmentado_1_02",true,false) as MeshInstance3D
    var mat: Material = skirt.material_override
    assert(Clay.set_enabled(new,true))
    assert(skirt.material_override!=mat)
    assert(Clay.set_enabled(new,false))
    assert(skirt.material_override==mat)
    old.free()
    new.free()
    stable.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v19()
    assert(studio._v19_preview and not studio._v20_preview)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    var before: Image = await _capture(studio)
    studio._toggle_v20()
    assert(studio._v20_preview and not studio._v19_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_integrated_v20",false))
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    var after: Image = await _capture(studio)
    var difference: int = _delta(before,after)
    assert(difference>20)
    _pair(before,after,
        "res://artifacts/tarvoka_g09_v19_v20_same_camera.png")
    studio._toggle_clay()
    assert(studio._clay_review and Clay.is_enabled(studio.model_root))
    var clay_20: Image = await _capture(studio)
    studio._toggle_v20()
    assert(studio._v19_preview and studio._clay_review)
    assert(Clay.is_enabled(studio.model_root))
    var clay_19: Image = await _capture(studio)
    var clay_difference: int = _delta(clay_19,clay_20)
    assert(clay_difference>18)
    _pair(clay_19,clay_20,
        "res://artifacts/tarvoka_g09_v19_v20_clay_same_camera.png")
    studio._toggle_v20()
    assert(studio._v20_preview and Clay.is_enabled(studio.model_root))
    studio._toggle_clay()
    assert(not Clay.is_enabled(studio.model_root))
    var views := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var view: Image = await _capture(studio)
        views.blit_rect(view,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(views.save_png("res://artifacts/tarvoka_g09_v20_four_angles.png")==OK)
    studio._reset_camera()
    studio._change_zoom(1)
    studio._change_zoom(1)
    var side_front: Image = await _capture(studio)
    studio._rotate(180.0)
    var side_rear: Image = await _capture(studio)
    _pair(side_front,side_rear,
        "res://artifacts/tarvoka_g09_v20_side_closeup.png")
    studio._set_damage(3)
    assert(Damage.current_stage(studio.model_root)==3)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root)==0)
    studio.queue_free()
    print("PASS G09 V20: 19 existing armor meshes replaced, %d different geometries, 14 shared sculpted suspension arms, 15 permanently retired floating trims, 14 paint zones, 8 faction palettes, 5 reversible stages, rig and clay, normal delta=%d clay delta=%d" % [
        different_geometry,difference,clay_difference])
    quit(0)
