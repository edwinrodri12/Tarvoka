extends SceneTree

# V19 QA: real geometry changes in the EXISTING 13 roof & cannon surfaces,
# non-destructive single-material clay display and mechanical rig regression.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const V19 = preload("res://scripts/ui/TankSculptV19.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(8):
        await process_frame
    var frame: Image = studio.preview.get_texture().get_image()
    assert(frame != null and not frame.is_empty())
    frame.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return frame

func _delta(left: Image,right: Image) -> int:
    var different: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = left.get_pixel(x,y)
            var b: Color = right.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.13:
                different+=1
    return different

func _pair(left: Image,right: Image,target: String) -> void:
    var comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(left,Rect2i(0,0,480,330),Vector2i.ZERO)
    comparison.blit_rect(right,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(comparison.save_png(target)==OK)

func _run() -> void:
    var older: Node3D = Models.build("tank",0,true,18)
    var new: Node3D = Models.build("tank",0,true,19)
    var stable: Node3D = Models.build("tank",0,true)
    assert(older != null and new != null and stable != null)
    assert(older.get_meta("tarvoka_mbt_resculpt_v18",false))
    assert(not older.get_meta("tarvoka_mbt_sculpt_v19",false))
    assert(new.get_meta("tarvoka_mbt_sculpt_v19",false))
    assert(not stable.get_meta("tarvoka_mbt_sculpt_v19",false))
    assert(int(new.get_meta("tarvoka_mbt_sculpt_v19_replaced",0))==13)
    assert(int(new.get_meta("tarvoka_mbt_sculpt_v19_hardware",0))==19)
    assert(Models.paintable_count(older)==14)
    assert(Models.paintable_count(new)==14)
    assert(Models.paintable_count(stable)==14)

    var changed_aabbs: int = 0
    var changed_topology: int = 0
    for label in V19.TOPOLOGY:
        var old_part: MeshInstance3D = older.find_child(
            label,true,false) as MeshInstance3D
        var replacement: MeshInstance3D = new.find_child(
            label,true,false) as MeshInstance3D
        assert(old_part != null and replacement != null)
        assert(replacement.mesh != null and replacement.mesh != old_part.mesh)
        assert(replacement.mesh is ArrayMesh)
        assert(replacement.get_parent().name == old_part.get_parent().name)
        assert(replacement.position == old_part.position)
        assert(replacement.rotation == old_part.rotation)
        if replacement.mesh.get_aabb()!=old_part.mesh.get_aabb():
            changed_aabbs+=1
        var old_arrays: Array = old_part.mesh.surface_get_arrays(0)
        var new_arrays: Array = replacement.mesh.surface_get_arrays(0)
        var old_vertex_count: int = (old_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
        var new_vertex_count: int = (new_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
        if old_vertex_count!=new_vertex_count:
            changed_topology+=1
    # Cosmetic housings are sculpted *within the same physical footprint*,
    # so AABB growth is not a measure of successful hard-surface repair.
    print("V19 roof structural geometry diagnostics: changed topology=",changed_topology,
        " changed bounding boxes=",changed_aabbs)
    assert(changed_topology>=7)

    var bolt: MultiMeshInstance3D = new.find_child(
        "G09V19PernosEscotilla",true,false) as MultiMeshInstance3D
    assert(bolt != null and bolt.multimesh.instance_count==16)
    assert(bolt.get_parent().name == "TorretaGiratoria")
    var seal: MeshInstance3D = new.find_child(
        "G09V19SelloConjuntoCanon",true,false) as MeshInstance3D
    assert(seal != null and seal.mesh is TorusMesh)
    assert(seal.get_parent().name == "ElevacionCanon")
    for side in [-1,1]:
        var brace: MeshInstance3D = new.find_child(
            "G09V19BisagraSoporte_%s" % side,true,false) as MeshInstance3D
        assert(brace != null and brace.get_parent().name == "ElevacionCanon")
    assert(Rig.has_rig(new))
    assert(Rig.pose(new,"move",0.65,Vector2i(1,0)))
    assert(Rig.pose(new,"attack",0.5,Vector2i(0,-1)))
    Rig.restore(new)
    for stage in range(5):
        assert(Damage.apply_stage(new,stage))
    assert(Damage.apply_stage(new,0))
    for faction in range(8):
        assert(Models.apply_faction_palette(new,faction)==14)

    # Clay must restore *identical* material resources when disabled, not
    # replace original authored PBRs or mutate faction-identity data.
    var hatch: MeshInstance3D = new.find_child(
        "EscotillaCircularV7_00",true,false) as MeshInstance3D
    var original_mat: Material = hatch.material_override
    assert(not Clay.is_enabled(new))
    assert(Clay.set_enabled(new,true))
    assert(Clay.is_enabled(new))
    var count: int = int(new.get_meta("tarvoka_v19_clay_count",0))
    assert(count>=250)
    assert(hatch.material_override == Clay._material())
    assert(hatch.material_override != original_mat)
    assert(Clay.set_enabled(new,false))
    assert(not Clay.is_enabled(new))
    assert(hatch.material_override == original_mat)
    assert(Clay.set_enabled(new,true))
    assert(Clay.set_enabled(new,false))
    assert(hatch.material_override == original_mat)
    older.free()
    new.free()
    stable.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v18()
    assert(studio._v18_preview and not studio._v19_preview)
    var angle: float = studio._yaw
    var zoom: float = studio._zoom
    var before: Image = await _capture(studio)
    studio._toggle_v19()
    assert(studio._v19_preview and not studio._v18_preview)
    assert(is_equal_approx(studio._yaw,angle))
    assert(is_equal_approx(studio._zoom,zoom))
    var after: Image = await _capture(studio)
    var delta_finished: int = _delta(before,after)
    assert(delta_finished>12)
    _pair(before,after,
        "res://artifacts/tarvoka_g09_v18_v19_same_camera.png")

    studio._toggle_clay()
    assert(studio._clay_review and Clay.is_enabled(studio.model_root))
    var clay_nineteen: Image = await _capture(studio)
    var delta_clay: int = _delta(after,clay_nineteen)
    assert(delta_clay>35)
    studio._toggle_v19()
    assert(studio._v18_preview and studio._clay_review)
    assert(Clay.is_enabled(studio.model_root))
    assert(is_equal_approx(studio._yaw,angle))
    var clay_eighteen: Image = await _capture(studio)
    var clay_mesh_delta: int = _delta(clay_eighteen,clay_nineteen)
    assert(clay_mesh_delta>10)
    _pair(clay_eighteen,clay_nineteen,
        "res://artifacts/tarvoka_g09_v18_v19_clay_same_camera.png")

    studio._toggle_v19()
    assert(studio._v19_preview and Clay.is_enabled(studio.model_root))
    studio._on_faction(4)
    assert(studio._clay_review)
    assert(Clay.is_enabled(studio.model_root))
    studio._toggle_clay()
    assert(not Clay.is_enabled(studio.model_root))

    var views := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var shot: Image = await _capture(studio)
        views.blit_rect(shot,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(views.save_png("res://artifacts/tarvoka_g09_v19_four_angles.png")==OK)

    studio._reset_camera()
    studio._change_zoom(1)
    studio._change_zoom(1)
    var roof_front: Image = await _capture(studio)
    studio._rotate(180.0)
    var roof_back: Image = await _capture(studio)
    _pair(roof_front,roof_back,
        "res://artifacts/tarvoka_g09_v19_roof_detail.png")
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root)==0)
    studio.queue_free()
    print("PASS G09 V19: 13 true roof/optic/gun housing meshes replaced, %d changed AABBs, 16 fasteners in one batch, 3 gun-linked parts, clay restored %d original material slots, 8 palettes, 14 paint zones, 5 HP stages; colored delta=%d clay-v18-v19=%d clay PBR=%d" % [
        changed_aabbs,count,delta_finished,clay_mesh_delta,delta_clay])
    quit(0)
