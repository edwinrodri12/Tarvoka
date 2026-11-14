extends SceneTree

# Final production animation acceptance for the actual Godot G09 V31 model.
# Tests smooth keyframes, persistent track/wheel phase, stable inboard X,
# non-mutation of faction materials, both hit families, all 5 damage stages.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Hit = preload("res://scripts/ui/TankHitReactionV30.gd")
const Tracks = preload("res://scripts/ui/TankFinalTracksV29.gd")
const Alignment = preload("res://scripts/ui/TankTrackAlignmentV31.gd")

func _initialize() -> void:
    call_deferred("_run")

func _near(a: float,b: float,eps: float=0.0006) -> bool:
    return absf(a-b)<=eps

func _assert_axles(model: Node3D) -> void:
    for side in [-1,1]:
        var belt: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(belt!=null and belt.multimesh.instance_count==84)
        for i in [0,9,25,42,63,83]:
            var transform: Transform3D = belt.multimesh.get_instance_transform(i)
            assert(_near(transform.origin.x,float(side)*Alignment.TRACK_CENTER_X))
        var spokes: MultiMeshInstance3D = model.find_child(
            "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
        assert(spokes!=null)
        assert(_near(spokes.multimesh.get_instance_transform(0).origin.x,
            float(side)*Alignment.SPOKE_X))

func _run() -> void:
    var model: Node3D = Models.build("tank",2,true,31)
    var other: Node3D = Models.build("tank",2,true,31)
    assert(model!=null and other!=null)
    assert(model.get_meta("tarvoka_mbt_tracks_inboard_v31",false))
    assert(model.get_meta("tarvoka_damage_polished_v30",false))
    assert(model.get_meta("tarvoka_hit_v30",false))
    assert(Models.paintable_count(model)==14)
    var count: int = Models.inspect_meshes(model)
    var cached: Dictionary = model.get_meta("tarvoka_v32_hit_nodes",{})
    assert(cached.size()==20)
    var belt: MultiMeshInstance3D = model.find_child(
        "OrugaArticuladaG09V7_1",true,false) as MultiMeshInstance3D
    var second: MultiMeshInstance3D = other.find_child(
        "OrugaArticuladaG09V7_1",true,false) as MultiMeshInstance3D
    assert(belt!=null and second!=null)
    assert(belt.multimesh.mesh==second.multimesh.mesh)
    var material: StandardMaterial3D = belt.multimesh.mesh.surface_get_material(0) as StandardMaterial3D
    assert(material!=null)
    var original_uv: Vector3 = material.uv1_offset
    var rest: Vector3 = model.position
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    assert(turret!=null and gun!=null and hull!=null)

    # First movement begins and ends with no fake hull tilt, no jump.
    assert(Rig.pose(model,"move",0.0,Vector2i(1,0)))
    assert(model.position.distance_to(rest)<0.0001)
    assert(_near(hull.rotation_degrees.x,0.0))
    assert(Rig.pose(model,"move",0.50,Vector2i(1,0)))
    _assert_axles(model)
    assert(Rig.pose(model,"move",1.0,Vector2i(1,0)))
    assert(model.position.distance_to(rest)<0.0001)
    assert(_near(model.rotation_degrees.z,0.0))
    assert(_near(hull.rotation_degrees.x,0.0))
    var progressed: float = float(model.get_meta(Rig.TRACK_PHASE_META,0.0))
    assert(_near(progressed,Rig.MOVE_BELT_ADVANCE))
    var last_link: Transform3D = belt.multimesh.get_instance_transform(0)
    Rig.restore(model)
    var resting_link: Transform3D = belt.multimesh.get_instance_transform(0)
    assert(last_link.origin.distance_to(resting_link.origin)<0.0001)
    assert(_near(float(model.get_meta(Rig.TRACK_PHASE_META,0.0)),progressed))
    for kind in ["idle",Hit.BULLET,Hit.EXPLOSIVE,"damaged"]:
        for frame in [0.0,0.08,0.25,0.53,0.82,1.0]:
            assert(Rig.pose(model,kind,frame,Vector2i(1,0)))
            _assert_axles(model)
        Rig.restore(model)
        assert(last_link.origin.distance_to(
            belt.multimesh.get_instance_transform(0).origin)<0.0001)
    assert(Rig.pose(model,"move",0.0))
    assert(_near(float(model.get_meta(Rig.TRACK_PHASE_META,0.0)),progressed))
    assert(Rig.pose(model,"move",1.0))
    assert(_near(float(model.get_meta(Rig.TRACK_PHASE_META,0.0)),
        fposmod(2.0*Rig.MOVE_BELT_ADVANCE,1.0)))

    # Aim, then fire; the muzzle and recoil MUST NOT appear at frame zero.
    var muzzle: Node3D = model.find_child("EfectoFogonazoCanon",true,false) as Node3D
    var smoke: Node3D = model.find_child("EfectoHumoCanon",true,false) as Node3D
    assert(muzzle!=null and smoke!=null)
    Rig.restore(model)
    assert(Rig.pose(model,"attack",0.0,Vector2i(1,0)))
    assert(_near(gun.position.z,-0.56))
    assert(_near(turret.rotation_degrees.y,0.0))
    assert(not muzzle.visible and not smoke.visible)
    assert(Rig.pose(model,"attack",0.30,Vector2i(1,0)))
    assert(absf(turret.rotation_degrees.y)>25.0)
    assert(not muzzle.visible and _near(gun.position.z,-0.56))
    assert(Rig.pose(model,"attack",0.44,Vector2i(1,0)))
    assert(muzzle.visible and gun.position.z>-0.40)
    assert(Rig.pose(model,"attack",0.72,Vector2i(1,0)))
    assert(not muzzle.visible and smoke.visible)
    assert(Rig.pose(model,"attack",1.0,Vector2i(1,0)))
    assert(not muzzle.visible and not smoke.visible)
    assert(_near(turret.rotation_degrees.y,0.0))
    assert(_near(gun.position.z,-0.56))
    Rig.restore(model)

    # Bullet and explosive both start clean, both shut off completely, and
    # no temporary geometry remains visible after an interrupted reaction.
    for kind in [Hit.BULLET,Hit.EXPLOSIVE]:
        for i in range(17):
            var progress: float = float(i)/16.0
            assert(Rig.pose(model,kind,progress))
            _assert_axles(model)
        Rig.restore(model)
        for fx in cached.values():
            assert(fx is MeshInstance3D and not (fx as MeshInstance3D).visible)
    assert(material.uv1_offset==original_uv)
    assert(belt.multimesh.mesh==second.multimesh.mesh)
    assert(Models.inspect_meshes(model)==count)

    # Damage overlays and constant FX never revive obsolete square tread
    # parts and never change the 0.422-wide, inboard track geometry.
    for stage in range(5):
        assert(Damage.apply_stage(model,stage))
        Damage.animate_smoke(model,0.73+float(stage))
        assert(Damage.current_stage(model)==stage)
        for side in [-1,1]:
            var old: Node3D = model.find_child(
                "BandaOruga%s" % side,true,false) as Node3D
            assert(old!=null and not old.visible)
        _assert_axles(model)
    assert(Damage.apply_stage(model,0))
    for faction in range(8):
        assert(Models.apply_faction_palette(model,faction)==14)
        assert(Rig.pose(model,"attack",0.43,Vector2i(-1,0)))
        Rig.restore(model)
        _assert_axles(model)
    assert(Models.paintable_count(model)==14)
    assert(Models.inspect_meshes(model)==count)
    model.free()
    other.free()
    print("PASS G09 V32: smooth move/aim/fire/recoil, persistent inboard track phase, 28 wheels+spokes, 5 damage stages, bullet and blast FX, 8 factions, no shared-material mutation or new meshes")
    quit(0)
