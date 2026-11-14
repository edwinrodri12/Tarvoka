extends SceneTree

# Acceptance on native G09 geometry, not an image-generation mockup.
# V30: 0.422-wide tread pads centered x=±1.335, protruding to ±1.546.
# V31: SAME PBR pads centered x=±1.145, now inside ±1.365
# and aligned to road-wheel/drive-gear axles on BOTH sides, even in motion.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Tracks = preload("res://scripts/ui/TankFinalTracksV29.gd")
const Alignment = preload("res://scripts/ui/TankTrackAlignmentV31.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _check(model: Node3D,side: int) -> void:
    var sign: float = float(side)
    var chain: MultiMeshInstance3D = model.find_child(
        "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
    assert(chain!=null and chain.multimesh!=null)
    assert(chain.multimesh.instance_count==Tracks.SHOE_COUNT)
    assert(chain.multimesh.mesh.get_surface_count()==2)
    var cross: AABB = chain.multimesh.mesh.get_aabb()
    assert(absf(cross.size.x-Tracks.TRACK_WIDTH_V30)<0.005)
    var farthest: float = 0.0
    for i in range(chain.multimesh.instance_count):
        var t: Transform3D = chain.multimesh.get_instance_transform(i)
        assert(absf(t.origin.x-sign*Alignment.TRACK_CENTER_X)<0.0003)
        farthest=maxf(farthest,absf(t.origin.x)+cross.size.x*0.5)
    assert(farthest<=Alignment.MAX_TRACK_OUTER_X)
    assert(absf(farthest-Alignment.EXPECTED_OUTER_X)<0.003)
    for end in [-1,1]:
        var drive: MeshInstance3D = model.find_child(
            "RuedaMotrizG09_%s_%s" % [side,end],
            true,false) as MeshInstance3D
        var hub: MeshInstance3D = model.find_child(
            "EjeMotrizG09_%s_%s" % [side,end],
            true,false) as MeshInstance3D
        assert(drive!=null and hub!=null)
        assert(absf(drive.position.x-sign*Alignment.TRACK_CENTER_X)<0.0002)
        assert(absf(hub.position.x-sign*Alignment.HUB_X)<0.0002)
    for index in range(7):
        var wheel: MeshInstance3D = model.find_child(
            "RuedaG09V7_%s_%02d" % [side,index],
            true,false) as MeshInstance3D
        var hub: MeshInstance3D = model.find_child(
            "BujeG09V7_%s_%02d" % [side,index],
            true,false) as MeshInstance3D
        assert(wheel!=null and hub!=null)
        assert(absf(wheel.position.x-sign*Alignment.TRACK_CENTER_X)<0.0002)
        assert(absf(hub.position.x-sign*Alignment.HUB_X)<0.0002)
    var spokes: MultiMeshInstance3D = model.find_child(
        "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
    assert(spokes!=null and spokes.multimesh!=null)
    assert(spokes.multimesh.instance_count==35)
    for i in range(spokes.multimesh.instance_count):
        var v: Vector3 = spokes.multimesh.get_instance_transform(i).origin
        assert(absf(v.x-sign*Alignment.SPOKE_X)<0.0002)

func _capture(view: SubViewport,cam: Camera3D,unit: Node3D,
        filename: String,position: Vector3) -> void:
    cam.position=position
    cam.look_at(Vector3(0.0,0.30,0.0),Vector3.UP)
    for i in range(7):
        await process_frame
    var img: Image=view.get_texture().get_image()
    assert(img!=null and not img.is_empty())
    assert(img.save_png("res://artifacts/"+filename)==OK)

func _run() -> void:
    var baseline: Node3D = Models.build("tank",0,true,30)
    var model: Node3D = Models.build("tank",0,true,31)
    assert(baseline!=null and model!=null)
    assert(not baseline.get_meta("tarvoka_mbt_tracks_inboard_v31",false))
    assert(model.get_meta("tarvoka_mbt_tracks_inboard_v31",false))
    assert(model.get_meta("tarvoka_mbt_track_wide_v30",false))
    assert(model.get_meta("tarvoka_hit_v30",false))
    assert(model.get_meta("tarvoka_damage_polished_v30",false))
    assert(Models.paintable_count(model)==14)
    assert(Models.inspect_meshes(baseline)==Models.inspect_meshes(model))
    assert(Alignment.EXPECTED_OUTER_X<=Alignment.MAX_TRACK_OUTER_X)
    var outer_old: float = Tracks.CENTER_X+Tracks.TRACK_WIDTH_V30*0.5
    assert(outer_old>Alignment.MAX_TRACK_OUTER_X+0.15)
    assert(outer_old-Alignment.EXPECTED_OUTER_X>0.18)
    assert(not Alignment.apply(model))
    for side in [-1,1]:
        _check(model,side)

    var teeth: MultiMeshInstance3D = model.find_child(
        "DientesCoronasMotricesG09",true,false) as MultiMeshInstance3D
    assert(teeth!=null and teeth.multimesh.instance_count==48)
    for i in range(teeth.multimesh.instance_count):
        var t: Vector3 = teeth.multimesh.get_instance_transform(i).origin
        assert(absf(absf(t.x)-Alignment.TOOTH_X)<0.0002)

    # Motion, weapon impact, explosion, and rig reset cannot snap inboard
    # links or spokes back to the old outboard x positions.
    for kind in ["move","attack","hit_bullet","hit_explosion","idle"]:
        for frame in [0.0,0.12,0.37,0.75,1.0]:
            assert(Rig.pose(model,kind,frame,Vector2i(1,0)))
            for side in [-1,1]:
                _check(model,side)
        Rig.restore(model)
    for hp_stage in range(5):
        assert(Damage.apply_stage(model,hp_stage))
        for side in [-1,1]:
            _check(model,side)
    assert(Damage.apply_stage(model,0))
    for faction in range(8):
        assert(Models.apply_faction_palette(model,faction)==14)
        for side in [-1,1]:
            _check(model,side)
    Models.apply_faction_palette(model,0)

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var vp:=SubViewport.new()
    vp.size=Vector2i(750,500)
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    vp.own_world_3d=true
    root.add_child(vp)
    var environment:=WorldEnvironment.new()
    var bg:=Environment.new()
    bg.background_mode=Environment.BG_COLOR
    bg.background_color=Color("#1B2D36")
    bg.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    bg.ambient_light_color=Color("#C6D3DC")
    bg.ambient_light_energy=0.9
    environment.environment=bg
    vp.add_child(environment)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-43,0)
    light.light_energy=1.5
    vp.add_child(light)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=3.60
    vp.add_child(cam)
    cam.current=true
    vp.add_child(model)
    await _capture(vp,cam,model,
        "tarvoka_g09_v31_cadenas_ambos_lados.png",Vector3(4.0,2.0,-4.4))
    await _capture(vp,cam,model,
        "tarvoka_g09_v31_ejes_alineados_frente.png",Vector3(0.0,1.0,-6.5))
    await _capture(vp,cam,model,
        "tarvoka_g09_v31_ejes_alineados_posterior.png",Vector3(0.0,1.0,6.5))
    vp.remove_child(model)
    vp.add_child(baseline)
    await _capture(vp,cam,baseline,
        "tarvoka_g09_v30_cadenas_sobresalientes_referencia.png",
        Vector3(0.0,1.0,-6.5))
    vp.queue_free()
    print("PASS G09 V31: wide 0.422 tracks fully inboard; both gear/wheel axles aligned; 168 links, 48 teeth, 70 spoke transforms, 8 factions, 5 damage stages, 4 motion types, no draw calls added")
    quit(0)
