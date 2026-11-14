extends SceneTree

# G09 V29 acceptance: real native 3D track geometry and animations.
# Reject "looks fixed in a picture" shortcuts. Prove removal of the square
# undercarriage and exact alignment/synchronized track geometry on both sides.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Tracks = preload("res://scripts/ui/TankFinalTracksV29.gd")
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const Wear = preload("res://scripts/ui/TankWearV25.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _near(a: float,b: float,epsilon: float = 0.0008) -> bool:
    return absf(a-b)<=epsilon

func _axis(model: Node3D,side: int,end: int) -> void:
    var wheel: MeshInstance3D = model.find_child(
        "RuedaG09V7_%s_%02d" % [side,0 if end<0 else 6],
        true,false) as MeshInstance3D
    var gear: MeshInstance3D = model.find_child(
        "RuedaMotrizG09_%s_%s" % [side,end],
        true,false) as MeshInstance3D
    var hub: MeshInstance3D = model.find_child(
        "EjeMotrizG09_%s_%s" % [side,end],
        true,false) as MeshInstance3D
    assert(wheel!=null and gear!=null and hub!=null)
    assert(_near(wheel.position.y,Tracks.CENTER_Y))
    assert(_near(gear.position.y,wheel.position.y))
    assert(_near(hub.position.y,wheel.position.y))
    assert(_near(gear.position.x,wheel.position.x,0.005))
    assert(_near(gear.position.z,float(end)*Tracks.SPROCKET_Z))
    assert(_near(hub.position.z,gear.position.z))
    assert(gear.mesh is CylinderMesh)
    assert(_near((gear.mesh as CylinderMesh).top_radius,
        Tracks.SPROCKET_RADIUS))

func _no_rectangular_track(model: Node3D) -> int:
    var count := 0
    for side in [-1,1]:
        for prefix in ["BandaOruga","GuiaOruga","CintaSuperiorOruga",
                "CintaInferiorOruga"]:
            var mesh: Node3D = model.find_child(
                "%s%s" % [prefix,side],true,false) as Node3D
            assert(mesh!=null)
            assert(not mesh.visible)
            count += 1
        for end in [-1,1]:
            var cap: Node3D = model.find_child(
                "ExtremoCinta%s_%s" % [side,end],true,false) as Node3D
            assert(cap!=null and not cap.visible)
            count += 1
        for i in range(10):
            var tile: Node3D = model.find_child(
                "ZapataOruga%s_%02d" % [side,i],true,false) as Node3D
            assert(tile!=null and not tile.visible)
            count += 1
        for i in range(15):
            for prefix in ["EslabonTreadSuperior","EslabonTreadInferior"]:
                var tile: Node3D = model.find_child(
                    "%s%s_%02d" % [prefix,side,i],true,false) as Node3D
                assert(tile!=null and not tile.visible)
                count += 1
    return count

func _check_belt(model: Node3D,side: int) -> void:
    var belt: MultiMeshInstance3D = model.find_child(
        "OrugaArticuladaG09V7_%s" % side,
        true,false) as MultiMeshInstance3D
    assert(belt!=null and belt.visible and belt.multimesh!=null)
    assert(belt.multimesh.instance_count==Tracks.SHOE_COUNT)
    assert(belt.multimesh.mesh.get_surface_count()==2)
    var front: Transform3D = belt.multimesh.get_instance_transform(0)
    assert(_near(front.origin.y,Tracks.CENTER_Y+Tracks.PATH_RADIUS))
    assert(_near(front.origin.z,-Tracks.SPROCKET_Z))
    assert(_near(front.origin.x,float(side)*Tracks.CENTER_X))
    var advance: Transform3D = belt.multimesh.get_instance_transform(1)
    assert(front.origin.distance_to(advance.origin)>0.04)
    assert(front.origin.distance_to(advance.origin)<0.11)
    for i in range(Tracks.SHOE_COUNT):
        var t: Transform3D = belt.multimesh.get_instance_transform(i)
        assert(_near(t.origin.x,float(side)*Tracks.CENTER_X))
        assert(t.origin.y>=Tracks.CENTER_Y-Tracks.PATH_RADIUS-0.0001)
        assert(t.origin.y<=Tracks.CENTER_Y+Tracks.PATH_RADIUS+0.0001)
        assert(t.origin.z>=-Tracks.SPROCKET_Z-Tracks.PATH_RADIUS-0.0001)
        assert(t.origin.z<=Tracks.SPROCKET_Z+Tracks.PATH_RADIUS+0.0001)

func _capture(model: Node3D,cam: Camera3D,
        position: Vector3,target: Vector3) -> Image:
    cam.position = position
    cam.look_at(target,Vector3.UP)
    for i in range(9):
        await process_frame
    var vp: SubViewport = cam.get_parent() as SubViewport
    var image: Image = vp.get_texture().get_image()
    assert(image!=null and not image.is_empty())
    return image

func _run() -> void:
    # A V24 baseline and V29 finished V25 have identical mesh draw counts.
    var v24: Node3D = Models.build("tank",0,true,24)
    var final: Node3D = Models.build("tank",0,true,25)
    assert(v24!=null and final!=null)
    assert(final.get_meta("tarvoka_mbt_track_final_v29",false))
    assert(int(final.get_meta("tarvoka_mbt_track_final_v29_hidden",0))==92)
    assert(Models.inspect_meshes(final)==Models.inspect_meshes(v24))
    assert(Models.paintable_count(final)==14)
    assert(Wear._targets().size()==17)
    assert(not Tracks.apply(final)) # Idempotent: never rebuild a second belt.
    var removed: int = _no_rectangular_track(final)
    assert(removed==92)
    for side in [-1,1]:
        for end in [-1,1]:
            _axis(final,side,end)
        _check_belt(final,side)
    var teeth: MultiMeshInstance3D = final.find_child(
        "DientesCoronasMotricesG09",true,false) as MultiMeshInstance3D
    assert(teeth!=null and teeth.multimesh!=null)
    assert(teeth.multimesh.instance_count==48)
    for side_index in range(2):
        for end_index in range(2):
            for i in range(12):
                var idx: int = side_index*24+end_index*12+i
                var transform: Transform3D = teeth.multimesh.get_instance_transform(idx)
                assert(_near(transform.origin.y-Tracks.CENTER_Y,
                    Tracks.TOOTH_RADIUS*cos(TAU*float(i)/12.0)))
    var old: Transform3D = (
        final.find_child("OrugaArticuladaG09V7_1",true,false)
        as MultiMeshInstance3D).multimesh.get_instance_transform(0)
    assert(Rig.pose(final,"move",0.45,Vector2i(1,-1)))
    var moved: Transform3D = (
        final.find_child("OrugaArticuladaG09V7_1",true,false)
        as MultiMeshInstance3D).multimesh.get_instance_transform(0)
    assert(old.origin.distance_to(moved.origin)>0.05)
    Rig.restore(final)
    var restored: Transform3D = (
        final.find_child("OrugaArticuladaG09V7_1",true,false)
        as MultiMeshInstance3D).multimesh.get_instance_transform(0)
    assert(old.origin.distance_to(restored.origin)<0.0008)
    for stage in range(5):
        assert(Damage.apply_stage(final,stage))
    Damage.apply_stage(final,0)
    for faction in range(8):
        assert(Models.apply_faction_palette(final,faction)==14)
        assert(final.get_meta("tarvoka_mbt_track_final_v29",false))
        assert(_no_rectangular_track(final)==92)

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var scene := SubViewport.new()
    scene.size = Vector2i(720,500)
    scene.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    scene.own_world_3d = true
    root.add_child(scene)
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#182A33")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#C3D6DF")
    environment.ambient_light_energy = 0.8
    env.environment = environment
    scene.add_child(env)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48,-38,0)
    key.light_energy = 1.45
    scene.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20,124,0)
    fill.light_energy = 0.75
    scene.add_child(fill)
    v24.free()
    Models.apply_faction_palette(final,2)
    scene.add_child(final)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.65
    camera.position = Vector3(5.0,2.4,2.1)
    scene.add_child(camera)
    camera.look_at(Vector3(0,0.33,0),Vector3.UP)
    camera.current = true
    var side_view: Image = await _capture(final,camera,
        Vector3(6.0,1.3,0.10),Vector3(0,0.30,0))
    assert(side_view.save_png(
        "res://artifacts/tarvoka_g09_v29_rodaje_lateral_real.png")==OK)
    var underside: Image = await _capture(final,camera,
        Vector3(5.5,-0.55,-0.75),Vector3(0,0.28,0))
    assert(underside.save_png(
        "res://artifacts/tarvoka_g09_v29_rodaje_inferior_real.png")==OK)
    var rear: Image = await _capture(final,camera,
        Vector3(3.3,1.2,5.0),Vector3(0,0.35,0))
    assert(rear.save_png(
        "res://artifacts/tarvoka_g09_v29_rodaje_posterior_real.png")==OK)
    var front: Image = await _capture(final,camera,
        Vector3(3.3,1.2,-5.0),Vector3(0,0.35,0))
    assert(front.save_png(
        "res://artifacts/tarvoka_g09_v29_rodaje_frontal_real.png")==OK)
    scene.queue_free()
    print("PASS G09 V29: 92 legacy rectangular track pieces retired; 4 aligned sprockets, 168 articulated tread shoes, 48 synchronized teeth, animated travel, 14 paint zones, unchanged mesh count, 4 real angles")
    quit(0)
