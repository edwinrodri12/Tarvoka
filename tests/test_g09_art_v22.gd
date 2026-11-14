extends SceneTree

# Native-render regression for the genuinely resculpted G09 V22 cannon.
# Same Godot meshes as Android, but still opt-in until visual approval.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const V22 = preload("res://scripts/ui/TankGunV22.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(10):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    image.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return image

func _delta(old: Image, current: Image) -> int:
    var count := 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = old.get_pixel(x,y)
            var b: Color = current.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.12:
                count += 1
    return count

func _save_pair(before: Image, after: Image, name: String) -> void:
    var comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(before,Rect2i(0,0,480,330),Vector2i.ZERO)
    comparison.blit_rect(after,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(comparison.save_png("res://artifacts/"+name)==OK)

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,21)
    var upgraded: Node3D = Models.build("tank",0,true,22)
    var android_default: Node3D = Models.build("tank",0,true)
    assert(old != null and upgraded != null and android_default != null)
    assert(old.get_meta("tarvoka_mbt_finish_v21",false))
    assert(not old.get_meta("tarvoka_mbt_gun_v22",false))
    assert(not android_default.get_meta("tarvoka_mbt_gun_v22",false))
    assert(upgraded.get_meta("tarvoka_mbt_gun_v22",false))
    assert(int(upgraded.get_meta("tarvoka_mbt_gun_v22_replaced",0))==4)
    assert(int(upgraded.get_meta("tarvoka_mbt_gun_v22_recoil",0))==2)
    assert(Models.paintable_count(upgraded)==14)
    var turret: Node3D = upgraded.find_child("TorretaGiratoria",true,false) as Node3D
    var pivot: Node3D = upgraded.find_child("ElevacionCanon",true,false) as Node3D
    assert(turret != null and pivot != null and pivot.get_parent()==turret)
    var changed := 0
    for label in V22.PARTS:
        var earlier: MeshInstance3D = old.find_child(label,true,false) as MeshInstance3D
        var latest: MeshInstance3D = upgraded.find_child(label,true,false) as MeshInstance3D
        assert(earlier != null and latest != null)
        assert(latest.get_parent()==pivot)
        assert(latest.transform==earlier.transform)
        assert(latest.mesh is ArrayMesh)
        assert(latest.mesh!=earlier.mesh)
        assert(latest.material_override is StandardMaterial3D)
        if latest.mesh.get_aabb()!=earlier.mesh.get_aabb():
            changed += 1
    assert(changed>=3)
    for side in [-1,1]:
        var actuator: MeshInstance3D = upgraded.find_child(
            "G09V22Amortiguador_%s" % side,true,false) as MeshInstance3D
        assert(actuator != null and actuator.get_parent()==pivot)
        assert(actuator.mesh is ArrayMesh)
        assert(actuator.mesh.get_aabb().size.y>0.8)
    var bore: MeshInstance3D = upgraded.find_child(
        "G09V22AnimaOscura",true,false) as MeshInstance3D
    assert(bore != null and bore.get_parent()==pivot)
    assert(Rig.has_rig(upgraded))
    assert(Rig.pose(upgraded,"attack",0.45,Vector2i(0,-1)))
    Rig.restore(upgraded)
    for damage in range(5):
        assert(Damage.apply_stage(upgraded,damage))
        assert(bore.visible==(damage<4))
    assert(Damage.apply_stage(upgraded,0))
    for faction in range(8):
        assert(Models.apply_faction_palette(upgraded,faction)==14)
    old.free()
    upgraded.free()
    android_default.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v21()
    assert(studio._v21_preview and not studio._v22_preview)
    studio._rotate(180.0)
    studio._change_zoom(1)
    studio._change_zoom(1)
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._set_damage(1)
    var before: Image = await _capture(studio)
    studio._toggle_v22()
    assert(studio._v22_preview and not studio._v21_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_gun_v22",false))
    assert(is_equal_approx(studio._yaw,yaw))
    assert(is_equal_approx(studio._zoom,zoom))
    assert(Damage.current_stage(studio.model_root)==1)
    var after: Image = await _capture(studio)
    var changed_pixels: int = _delta(before,after)
    assert(changed_pixels>12)
    _save_pair(before,after,"tarvoka_g09_v21_v22_same_camera.png")

    studio._toggle_clay()
    assert(studio._clay_review and Clay.is_enabled(studio.model_root))
    studio._toggle_v22()
    assert(studio._v21_preview and studio._clay_review)
    var clay_before: Image = await _capture(studio)
    studio._toggle_v22()
    assert(studio._v22_preview and studio._clay_review)
    var clay_after: Image = await _capture(studio)
    assert(_delta(clay_before,clay_after)>12)
    _save_pair(clay_before,clay_after,"tarvoka_g09_v21_v22_clay.png")
    studio._toggle_clay()
    studio._on_faction(7)
    assert(Models.paintable_count(studio.model_root)==14)
    var turntable := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var view: Image = await _capture(studio)
        turntable.blit_rect(view,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(turntable.save_png(
        "res://artifacts/tarvoka_g09_v22_four_angles.png")==OK)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    assert(not studio.model_root.find_child("G09V22Amortiguador_1",true,false).visible)
    studio._set_damage(0)
    assert(studio.model_root.find_child("G09V22Amortiguador_1",true,false).visible)
    studio.queue_free()
    print("PASS G09 V22: four replaced cannon meshes, dual recoil rods, recessed bore, unchanged pivot, eight palettes, five HP states, same-camera V21/V22 real WebGL model, pixel delta=%d" % changed_pixels)
    quit(0)
