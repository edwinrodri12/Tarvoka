extends SceneTree

# V23 art acceptance: recognisable faction panels, preserving the real 3D
# silhouettes, eight official colors, 14 original paint zones and damage rig.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const PaintV23 = preload("res://scripts/ui/TankFactionV23.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(9):
        await process_frame
    var frame: Image = studio.preview.get_texture().get_image()
    assert(frame != null and not frame.is_empty())
    frame.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return frame

func _delta(first: Image,second: Image) -> int:
    var changed: int = 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = first.get_pixel(x,y)
            var b: Color = second.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.11:
                changed += 1
    return changed

func _pair(first: Image,second: Image,filename: String) -> void:
    var out := Image.create(960,330,false,Image.FORMAT_RGBA8)
    out.blit_rect(first,Rect2i(0,0,480,330),Vector2i.ZERO)
    out.blit_rect(second,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(out.save_png("res://artifacts/"+filename)==OK)

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,22)
    var updated: Node3D = Models.build("tank",0,true,23)
    var android: Node3D = Models.build("tank",0,true)
    assert(old!=null and updated!=null and android!=null)
    assert(updated.get_meta("tarvoka_mbt_faction_v23",false))
    assert(not old.get_meta("tarvoka_mbt_faction_v23",false))
    assert(not android.get_meta("tarvoka_mbt_faction_v23",false))
    assert(int(updated.get_meta("tarvoka_mbt_faction_v23_recolored",0))==11)
    assert(PaintV23._targets().size()==PaintV23.PAINTED_ARMOR_COUNT)
    assert(Models.paintable_count(old)==14)
    assert(Models.paintable_count(updated)==14)
    assert(Models.paintable_count(android)==14)
    # V23 paints existing armor; it does not increase draw calls through
    # duplicated mesh parts or change the underlying polygon boundaries.
    assert(Models.inspect_meshes(old)==Models.inspect_meshes(updated))
    for item in PaintV23._targets():
        var label: String = str(item[0])
        var before: MeshInstance3D = old.find_child(label,true,false) as MeshInstance3D
        var after: MeshInstance3D = updated.find_child(label,true,false) as MeshInstance3D
        assert(before!=null and after!=null)
        assert(after.mesh == before.mesh or
            (after.mesh.get_aabb()==before.mesh.get_aabb() and
             after.mesh.get_surface_count()==before.mesh.get_surface_count()))
        assert(after.material_override is StandardMaterial3D)
        assert(before.material_override is StandardMaterial3D)
        assert((after.material_override as StandardMaterial3D).albedo_color!=
            (before.material_override as StandardMaterial3D).albedo_color)
        assert(after.get_parent().name==before.get_parent().name)
    var side: MeshInstance3D = updated.find_child(
        "G09V13FaldonSegmentado_-1_02",true,false) as MeshInstance3D
    var first_color: Color = (side.material_override as StandardMaterial3D).albedo_color
    for faction in range(8):
        assert(Models.apply_faction_palette(updated,faction)==14)
        assert(Models.paintable_count(updated)==14)
        assert(PaintV23.recolor(updated,Models.faction_paint_color(faction))==11)
    assert(Models.apply_faction_palette(updated,0)==14)
    assert((side.material_override as StandardMaterial3D).albedo_color.is_equal_approx(first_color))
    assert(Rig.has_rig(updated))
    assert(Rig.pose(updated,"attack",0.43,Vector2i(0,-1)))
    Rig.restore(updated)
    for stage in range(5):
        assert(Damage.apply_stage(updated,stage))
        assert(updated.get_meta("tarvoka_mbt_faction_v23",false))
    assert(Damage.apply_stage(updated,0))
    old.free()
    updated.free()
    android.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v22()
    studio._on_faction(1)
    studio._rotate(90.0)
    studio._change_zoom(1)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._set_damage(1)
    var previous: Image = await _capture(studio)
    studio._toggle_v23()
    assert(studio._v23_preview and not studio._v22_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_faction_v23",false))
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(Damage.current_stage(studio.model_root)==1)
    var reinforced: Image = await _capture(studio)
    var changed: int = _delta(previous,reinforced)
    assert(changed>55)
    _pair(previous,reinforced,"tarvoka_g09_v22_v23_same_camera.png")
    studio._toggle_clay()
    var sculpt_v23: Image = await _capture(studio)
    assert(Clay.is_enabled(studio.model_root))
    studio._toggle_v23()
    assert(studio._v22_preview and studio._clay_review)
    var sculpt_v22: Image = await _capture(studio)
    assert(_delta(sculpt_v22,sculpt_v23)<35)
    studio._toggle_v23()
    studio._toggle_clay()
    studio._on_faction(6)
    assert(Models.paintable_count(studio.model_root)==14)
    var angles := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var image: Image = await _capture(studio)
        angles.blit_rect(image,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(angles.save_png("res://artifacts/tarvoka_g09_v23_four_angles.png")==OK)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root)==0)
    studio.queue_free()
    print("PASS G09 V23: 11 original armor panels faction-painted, 14 legacy zones unchanged, same mesh count, 8 palettes, 5 damage states and native studio render; colored pixel delta=%d" % changed)
    quit(0)
