extends SceneTree

# G09 V24 QA: validate original-roof faction readability in the actual
# Godot Web Studio at tactical distance, not only at hero model zoom.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const V24 = preload("res://scripts/ui/TankTacticalV24.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(9):
        await process_frame
    var img: Image = studio.preview.get_texture().get_image()
    assert(img != null and not img.is_empty())
    img.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return img

func _diff(a: Image,b: Image) -> int:
    var changed := 0
    for y in range(0,330,3):
        for x in range(0,480,3):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.12:
                changed += 1
    return changed

func _pair(a: Image,b: Image,filename: String) -> void:
    var result := Image.create(960,330,false,Image.FORMAT_RGBA8)
    result.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    result.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(result.save_png("res://artifacts/"+filename)==OK)

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,23)
    var new: Node3D = Models.build("tank",0,true,24)
    var android: Node3D = Models.build("tank",0,true)
    assert(old!=null and new!=null and android!=null)
    assert(old.get_meta("tarvoka_mbt_faction_v23",false))
    assert(not old.get_meta("tarvoka_mbt_tactical_v24",false))
    assert(new.get_meta("tarvoka_mbt_tactical_v24",false))
    assert(int(new.get_meta("tarvoka_mbt_tactical_v24_roof_count",0))==6)
    assert(not android.get_meta("tarvoka_mbt_tactical_v24",false))
    assert(V24._targets().size()==V24.TOP_PAINT_COUNT)
    assert(Models.paintable_count(old)==14)
    assert(Models.paintable_count(new)==14)
    assert(Models.paintable_count(android)==14)
    assert(Models.inspect_meshes(old)==Models.inspect_meshes(new))
    for row in V24._targets():
        var name: String = str(row[0])
        var before: MeshInstance3D = old.find_child(name,true,false) as MeshInstance3D
        var after: MeshInstance3D = new.find_child(name,true,false) as MeshInstance3D
        assert(before!=null and after!=null)
        assert(before.mesh.get_aabb()==after.mesh.get_aabb())
        assert(before.mesh.get_surface_count()==after.mesh.get_surface_count())
        assert(before.get_parent().name==after.get_parent().name)
        assert(after.material_override is StandardMaterial3D)
        assert(before.material_override is StandardMaterial3D)
        assert((before.material_override as StandardMaterial3D).albedo_color!=
            (after.material_override as StandardMaterial3D).albedo_color)
    var roof: MeshInstance3D = new.find_child(
        "G09V14LomoBlindadoCentral_-1",true,false) as MeshInstance3D
    var first_color: Color = (roof.material_override as StandardMaterial3D).albedo_color
    for faction in range(8):
        assert(Models.apply_faction_palette(new,faction)==14)
        assert(new.get_meta("tarvoka_mbt_tactical_v24",false))
        assert(V24.recolor(new,Models.faction_paint_color(faction))==6)
        assert(Models.paintable_count(new)==14)
    assert(Models.apply_faction_palette(new,0)==14)
    assert((roof.material_override as StandardMaterial3D).albedo_color.is_equal_approx(first_color))
    assert(Rig.has_rig(new))
    assert(Rig.pose(new,"attack",0.38,Vector2i(0,-1)))
    Rig.restore(new)
    for stage in range(5):
        assert(Damage.apply_stage(new,stage))
    assert(Damage.apply_stage(new,0))
    old.free()
    new.free()
    android.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v23()
    studio._on_faction(1)
    studio._toggle_tactical_camera()
    assert(studio._tactical_view)
    assert(studio.camera.position.y>8.0)
    studio._set_damage(1)
    studio._rotate(35.0)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    var shot_v23: Image = await _capture(studio)
    studio._toggle_v24()
    assert(studio._v24_preview and not studio._v23_preview)
    assert(studio._tactical_view and studio.camera.position.y>8.0)
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(Damage.current_stage(studio.model_root)==1)
    var shot_v24: Image = await _capture(studio)
    var delta: int = _diff(shot_v23,shot_v24)
    assert(delta>12)
    _pair(shot_v23,shot_v24,"tarvoka_g09_v23_v24_tactical_same_camera.png")

    studio._toggle_clay()
    assert(Clay.is_enabled(studio.model_root))
    var clay_new: Image = await _capture(studio)
    studio._toggle_v24()
    assert(studio._v23_preview and studio._clay_review and studio._tactical_view)
    var clay_old: Image = await _capture(studio)
    assert(_diff(clay_old,clay_new)<55)
    studio._toggle_v24()
    studio._toggle_clay()
    studio._set_damage(0)
    var overview := Image.create(1920,660,false,Image.FORMAT_RGBA8)
    for faction in range(8):
        studio._on_faction(faction)
        assert(studio.model_root.get_meta("tarvoka_mbt_tactical_v24",false))
        var capture: Image = await _capture(studio)
        overview.blit_rect(capture,Rect2i(0,0,480,330),
            Vector2i((faction%4)*480,(faction/4)*330))
    assert(overview.save_png(
        "res://artifacts/tarvoka_g09_v24_eight_factions_tactical.png")==OK)
    studio._toggle_tactical_camera()
    assert(not studio._tactical_view)
    assert(studio.camera.position.y<6.0)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root)==0)
    studio.queue_free()
    print("PASS G09 V24: 6 true top armor color panels, zero new meshes, 14 original zones, 8 factions, 5 damage states, rig and tactical camera V23/V24 delta=%d" % delta)
    quit(0)
