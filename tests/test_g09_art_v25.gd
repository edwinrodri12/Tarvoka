extends SceneTree

# Real mesh and renderer acceptance for G09 V25 weathered PBR armor.
# 17 existing plates, same geometry, unchanged official color selection,
# current material must survive 5 visual damage stages and tactical camera.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Wear = preload("res://scripts/ui/TankWearV25.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(9):
        await process_frame
    var img: Image = studio.preview.get_texture().get_image()
    assert(img != null and not img.is_empty())
    img.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return img

func _delta(a: Image,b: Image) -> int:
    var changed := 0
    for y in range(0,330,3):
        for x in range(0,480,3):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.13:
                changed += 1
    return changed

func _pair(a: Image,b: Image,path: String) -> void:
    var img := Image.create(960,330,false,Image.FORMAT_RGBA8)
    img.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    img.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(img.save_png("res://artifacts/"+path)==OK)

func _run() -> void:
    var prior: Node3D = Models.build("tank",0,true,24)
    var current: Node3D = Models.build("tank",0,true,25)
    var android: Node3D = Models.build("tank",0,true)
    assert(prior!=null and current!=null and android!=null)
    assert(prior.get_meta("tarvoka_mbt_tactical_v24",false))
    assert(not prior.get_meta("tarvoka_mbt_wear_v25",false))
    assert(current.get_meta("tarvoka_mbt_wear_v25",false))
    assert(int(current.get_meta("tarvoka_mbt_wear_v25_count",0))==17)
    assert(not android.get_meta("tarvoka_mbt_wear_v25",false))
    assert(Wear._targets().size()==Wear.TREATED_PANELS)
    assert(Models.paintable_count(current)==14)
    assert(Models.paintable_count(prior)==14)
    assert(Models.paintable_count(android)==14)
    assert(Models.inspect_meshes(current)==Models.inspect_meshes(prior))
    for label in Wear._targets():
        var before: MeshInstance3D = prior.find_child(label,true,false) as MeshInstance3D
        var after: MeshInstance3D = current.find_child(label,true,false) as MeshInstance3D
        assert(before!=null and after!=null)
        assert(after.mesh.get_aabb()==before.mesh.get_aabb())
        assert(after.mesh.get_surface_count()==before.mesh.get_surface_count())
        assert(after.get_parent().name==before.get_parent().name)
        var mat: StandardMaterial3D = after.material_override as StandardMaterial3D
        assert(mat!=null and mat.albedo_texture!=null)
        assert(mat.roughness_texture!=null and mat.normal_texture!=null)
        assert(mat.albedo_color.is_equal_approx(Color.WHITE))
        assert(mat.metallic<0.30 and mat.roughness>=0.90)
    var sample: MeshInstance3D = current.find_child(
        "G09V13FaldonSegmentado_-1_02",true,false) as MeshInstance3D
    var surface: StandardMaterial3D = sample.material_override as StandardMaterial3D
    var tex: Image = surface.albedo_texture.get_image()
    var rough: Image = surface.roughness_texture.get_image()
    assert(tex.get_width()==Wear.SIZE and rough.get_width()==Wear.SIZE)
    assert(tex.get_pixel(0,0)!=tex.get_pixel(47,47))
    assert(rough.get_pixel(0,0)!=rough.get_pixel(47,47))
    var first_texture: int = surface.albedo_texture.get_instance_id()
    for faction in range(8):
        assert(Models.apply_faction_palette(current,faction)==14)
        assert(Models.paintable_count(current)==14)
        assert(Wear.refinish(current)==17)
        var mat: StandardMaterial3D = sample.material_override as StandardMaterial3D
        assert(mat.albedo_texture!=null and mat.roughness_texture!=null)
        assert(mat.albedo_color==Color.WHITE)
    assert(Models.apply_faction_palette(current,0)==14)
    assert((sample.material_override as StandardMaterial3D).albedo_texture.get_instance_id()==first_texture)
    assert(Rig.has_rig(current))
    assert(Rig.pose(current,"attack",0.38,Vector2i(1,-1)))
    Rig.restore(current)
    for stage in range(5):
        assert(Damage.apply_stage(current,stage))
    assert(Damage.apply_stage(current,0))
    prior.free()
    current.free()
    android.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v24()
    studio._on_faction(2)
    studio._rotate(27.0)
    studio._change_zoom(1)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._set_damage(1)
    var v24: Image = await _capture(studio)
    studio._toggle_v25()
    assert(studio._v25_preview and not studio._v24_preview)
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(Damage.current_stage(studio.model_root)==1)
    var v25: Image = await _capture(studio)
    var studio_delta: int = _delta(v24,v25)
    assert(studio_delta>14)
    _pair(v24,v25,"tarvoka_g09_v24_v25_pbr_same_camera.png")
    studio._toggle_clay()
    assert(Clay.is_enabled(studio.model_root))
    var clay_new: Image = await _capture(studio)
    studio._toggle_v25()
    assert(studio._v24_preview and studio._clay_review)
    var clay_old: Image = await _capture(studio)
    assert(_delta(clay_old,clay_new)<55)
    studio._toggle_v25()
    studio._toggle_clay()
    studio._toggle_tactical_camera()
    assert(studio._tactical_view)
    var tactical_v25: Image = await _capture(studio)
    studio._toggle_v25()
    var tactical_v24: Image = await _capture(studio)
    assert(studio._tactical_view)
    _pair(tactical_v24,tactical_v25,"tarvoka_g09_v24_v25_tactical.png")
    studio._toggle_v25()
    studio._toggle_tactical_camera()
    studio._set_damage(0)
    var overview := Image.create(1920,660,false,Image.FORMAT_RGBA8)
    for faction in range(8):
        studio._on_faction(faction)
        assert(studio.model_root.get_meta("tarvoka_mbt_wear_v25",false))
        var shot: Image = await _capture(studio)
        overview.blit_rect(shot,Rect2i(0,0,480,330),
            Vector2i((faction%4)*480,int(faction/4)*330))
    assert(overview.save_png(
        "res://artifacts/tarvoka_g09_v25_eight_factions_weathered.png")==OK)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root)==0)
    studio.queue_free()
    print("PASS G09 V25: 17 weathered original armor parts, 14 zones, 8 faction coats, unchanged mesh count, PBR roughness and stable camera; pixel delta=%d" % studio_delta)
    quit(0)
