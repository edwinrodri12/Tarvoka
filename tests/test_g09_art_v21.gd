extends SceneTree

# Source-based G09 V21 tests: verify 18 original mesh replacements,
# real dual-surface metal/rubber wheel/tread geometry and the hull-mounted
# turret bearing, while retaining paint / movement / five HP stages.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Finish = preload("res://scripts/ui/TankFinishV21.gd")
const Clay = preload("res://scripts/ui/TankClayV19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for n in range(8):
        await process_frame
    var shot: Image = studio.preview.get_texture().get_image()
    assert(shot != null and not shot.is_empty())
    shot.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return shot

func _delta(first: Image,last: Image) -> int:
    var changed := 0
    for y in range(0,330,4):
        for x in range(0,480,4):
            var a: Color = first.get_pixel(x,y)
            var b: Color = last.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.13:
                changed+=1
    return changed

func _pair(first: Image,last: Image,target: String) -> void:
    var sheet := Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(first,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(last,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(sheet.save_png(target)==OK)

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,20)
    var new: Node3D = Models.build("tank",0,true,21)
    var stable: Node3D = Models.build("tank",0,true)
    assert(old != null and new != null and stable != null)
    assert(old.get_meta("tarvoka_mbt_integrated_v20",false))
    assert(not old.get_meta("tarvoka_mbt_finish_v21",false))
    assert(not stable.get_meta("tarvoka_mbt_finish_v21",false))
    assert(new.get_meta("tarvoka_mbt_finish_v21",false))
    assert(int(new.get_meta("tarvoka_mbt_finish_v21_meshes",0))==18)
    assert(int(new.get_meta("tarvoka_mbt_finish_v21_tread_instances",0))==168)
    assert(Models.paintable_count(old)==14)
    assert(Models.paintable_count(new)==14)
    assert(Models.paintable_count(stable)==14)
    var changed_geometry := 0
    var required := ["TorreBajaSoldadaV7","G09V14QuillaFrontal",
        "G09V14AlaBlindadaFrontal_-1","G09V14AlaBlindadaFrontal_1"]
    for side in [-1,1]:
        for i in range(7):
            required.append("RuedaG09V7_%s_%02d" % [side,i])
    assert(required.size()==Finish.CHANGED_PRIMARY_MESHES)
    for label in required:
        var original: MeshInstance3D = old.find_child(
            label,true,false) as MeshInstance3D
        var updated: MeshInstance3D = new.find_child(
            label,true,false) as MeshInstance3D
        assert(original!=null and updated!=null)
        assert(original.name==updated.name)
        assert(original.get_parent().name==updated.get_parent().name)
        assert(original.position==updated.position)
        assert(original.rotation==updated.rotation)
        assert(updated.mesh is ArrayMesh)
        assert(updated.mesh!=original.mesh)
        var a: PackedVector3Array = original.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        var b: PackedVector3Array = updated.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        if a.size()!=b.size() or original.mesh.get_aabb()!=updated.mesh.get_aabb():
            changed_geometry+=1
    assert(changed_geometry>=16)
    var rim: MeshInstance3D = new.find_child(
        "G09V21CoronaBarbeta",true,false) as MeshInstance3D
    assert(rim!=null and rim.mesh is ArrayMesh)
    assert(rim.get_parent().name=="ChasisBlindado")
    assert(rim.mesh.get_aabb().position.y>1.0)
    assert(rim.mesh.get_aabb().size.x>1.1)
    var positive_wheel: MeshInstance3D = new.find_child(
        "RuedaG09V7_1_03",true,false) as MeshInstance3D
    var negative_wheel: MeshInstance3D = new.find_child(
        "RuedaG09V7_-1_03",true,false) as MeshInstance3D
    assert(positive_wheel.mesh==negative_wheel.mesh)
    assert(positive_wheel.mesh.get_surface_count()==2)
    assert(positive_wheel.mesh.surface_get_material(0)!=null)
    assert(positive_wheel.mesh.surface_get_material(1)!=null)
    assert(positive_wheel.material_override==null)

    for side in [-1,1]:
        var old_track: MultiMeshInstance3D = old.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        var new_track: MultiMeshInstance3D = new.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(new_track!=null and old_track!=null)
        assert(new_track.get_parent().name==old_track.get_parent().name)
        assert(new_track.multimesh.instance_count==Hero.TRACK_COUNT)
        assert(new_track.multimesh.mesh is ArrayMesh)
        assert(new_track.multimesh.mesh!=old_track.multimesh.mesh)
        assert(new_track.multimesh.mesh.get_surface_count()==2)
        assert(new_track.multimesh.mesh.surface_get_material(1)!=null)
        assert(new_track.material_override==null)
        var first: Transform3D = new_track.multimesh.get_instance_transform(0)
        Hero.slide_tracks(new,0.11)
        var moved: Transform3D = new_track.multimesh.get_instance_transform(0)
        assert(first.origin.distance_to(moved.origin)>0.02)
        Hero.slide_tracks(new,0.0)
        assert(new_track.multimesh.get_instance_transform(0).origin.distance_to(first.origin)<0.001)
    assert(Rig.has_rig(new))
    assert(Rig.pose(new,"move",0.63,Vector2i(1,0)))
    assert(Rig.pose(new,"attack",0.46,Vector2i(0,-1)))
    Rig.restore(new)
    for stage in range(5):
        assert(Damage.apply_stage(new,stage))
        for label in Finish.LEGACY_FRONT:
            var outdated: Node3D = new.find_child(
                label,true,false) as Node3D
            assert(outdated!=null and not outdated.visible)
    assert(Damage.apply_stage(new,0))
    assert(new.find_child("G09V14QuillaFrontal",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(new,faction)==14)
    var painted: MeshInstance3D = new.find_child(
        "G09V14AlaBlindadaFrontal_-1",true,false) as MeshInstance3D
    var original_mat: Material = painted.material_override
    assert(Clay.set_enabled(new,true))
    assert(Clay.is_enabled(new))
    assert(painted.material_override!=original_mat)
    assert(Clay.set_enabled(new,false))
    assert(painted.material_override==original_mat)
    old.free()
    new.free()
    stable.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v20()
    assert(studio._v20_preview and not studio._v21_preview)
    var before_yaw: float = studio._yaw
    var before_zoom: float = studio._zoom
    var before: Image = await _capture(studio)
    studio._toggle_v21()
    assert(studio._v21_preview and not studio._v20_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_finish_v21",false))
    assert(is_equal_approx(studio._yaw,before_yaw))
    assert(is_equal_approx(studio._zoom,before_zoom))
    var after: Image = await _capture(studio)
    var normal_delta: int = _delta(before,after)
    assert(normal_delta>25)
    _pair(before,after,
        "res://artifacts/tarvoka_g09_v20_v21_same_camera.png")

    studio._toggle_clay()
    assert(studio._clay_review and Clay.is_enabled(studio.model_root))
    var clay_new: Image = await _capture(studio)
    studio._toggle_v21()
    assert(studio._v20_preview and studio._clay_review)
    assert(Clay.is_enabled(studio.model_root))
    var clay_old: Image = await _capture(studio)
    var clay_delta: int = _delta(clay_old,clay_new)
    assert(clay_delta>25)
    _pair(clay_old,clay_new,
        "res://artifacts/tarvoka_g09_v20_v21_clay_same_camera.png")
    studio._toggle_v21()
    assert(studio._v21_preview and Clay.is_enabled(studio.model_root))
    studio._toggle_clay()
    assert(not Clay.is_enabled(studio.model_root))
    studio._on_faction(6)
    assert(Models.paintable_count(studio.model_root)==14)
    var angles := Image.create(1920,330,false,Image.FORMAT_RGBA8)
    for i in range(4):
        studio._reset_camera()
        studio._rotate(float(i)*90.0)
        var frame: Image = await _capture(studio)
        angles.blit_rect(frame,Rect2i(0,0,480,330),Vector2i(i*480,0))
    assert(angles.save_png("res://artifacts/tarvoka_g09_v21_four_angles.png")==OK)
    studio._reset_camera()
    studio._change_zoom(1)
    studio._change_zoom(1)
    var close_front: Image = await _capture(studio)
    studio._rotate(180.0)
    var close_rear: Image = await _capture(studio)
    _pair(close_front,close_rear,
        "res://artifacts/tarvoka_g09_v21_runninggear_closeup.png")
    studio._set_damage(3)
    assert(Damage.current_stage(studio.model_root)==3)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root)==4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root)==0)
    studio.queue_free()
    print("PASS G09 V21: 18 original 3D meshes, %d distinct mesh envelopes/topologies, 14 shared dual-material dished roadwheels, 168 articulated two-surface track pads, native turret ring, 2 permanently retired prototype bumpers, 14 paint zones, 8 palettes, 5 reversible HP states, gun and treads, clay; normal delta=%d clay delta=%d" % [changed_geometry,normal_delta,clay_delta])
    quit(0)
