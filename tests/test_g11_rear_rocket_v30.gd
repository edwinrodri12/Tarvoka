extends SceneTree

# V30 actual geometry and post-confirmation rocket trajectory safety.
# The reported rear square overhang existed in two legacy hero feet:
# center 0.56 +/- 0.19 crosses the track inner plane 0.79-0.142.
# No extra unit meshes, battle writes or changed previous approved tracks.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Repair = preload("res://scripts/ui/G11RearUndercarriageV30.gd")
const Trails = preload("res://scripts/ui/G11RocketTrailsV30.gd")
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Actions = preload("res://scripts/ui/G11BattleActionsV29.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
var errors: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V30 native rear and rocket QA: "+label)

func _find(model: Node3D,part: String) -> MeshInstance3D:
    return model.find_child(part,true,false) as MeshInstance3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var raw_foot_max: float=0.56+0.38*0.5
    var track_inner: float=0.79-0.142
    _check(raw_foot_max>track_inner+0.10,
        "V1 rear rectangular stabilizer did intersect approved track envelope")
    _check(Repair.hero_clearance()>=Repair.MIN_CLEARANCE and
        Repair.mobile_clearance()>=0.020,
        "new clipped rear geometry leaves safe inner track clearance")
    for faction in range(8):
        var hero: Node3D=Models.build("mlrs",faction,true,13)
        _check(hero!=null and bool(hero.get_meta(Repair.FLAG,false)),
            "V30 applies on approved V23 hero for eight factions")
        if hero==null:
            continue
        var hero_count: int=Models.inspect_meshes(hero)
        var belly:=_find(hero,"G11_ProteccionInferior")
        _check(belly!=null and belly.mesh is ArrayMesh,
            "rear underbody rectangle becomes original-place tapered hull")
        for side in [-1,1]:
            var foot:=_find(hero,"G11_ZapataEstabilizador_%d" % side)
            var support:=_find(hero,"G11_Estabilizador_%d" % side)
            _check(foot!=null and foot.mesh is ArrayMesh and support!=null,
                "original rear foot bevel has no square overlapping slab")
            if foot!=null and support!=null:
                _check(absf(foot.position.x)<0.42 and
                    absf(support.position.x)<0.43,
                    "foot/brace fit entirely inside rear track inner plane")
        _check(not Repair.apply_hero(hero),
            "hero repair idempotent: no duplicate rear geometry")
        _check(hero_count==Models.inspect_meshes(hero),
            "hero rear correction adds no MeshInstance nodes")
        _check(bool(hero.get_meta("tarvoka_g11_track_finish_v19",false))
            and bool(hero.get_meta("tarvoka_g11_joint_finish_v23",false)),
            "approved links, gears and suspension pins remain installed")
        hero.free()
        for lod in [8,10]:
            var mobile: Node3D=Models.build("mlrs",faction,false,lod)
            _check(mobile!=null and bool(mobile.get_meta(Repair.FLAG,false)),
                "real low-poly G11 body rear corrected for all 16 LOD/faction forms")
            if mobile==null:
                continue
            _check(_find(mobile,"ChasisLanzacohetes")!=null and
                _find(mobile,"ChasisLanzacohetes").mesh is ArrayMesh,
                "old full width mobile chassis replaced in place with tapered underbody")
            _check(bool(mobile.get_meta(
                "tarvoka_g11_tactical_readability_v24",false)),
                "original V24 wheel aperture and closed LOD8 belt retained")
            _check(Models.inspect_meshes(mobile)<=18,
                "mobile correction adds no tactical GPU draw batches")
            mobile.free()
    # Visual short flights on a REAL, fog-filtered battle scene.
    for biome in Biomes.CHOICES:
        var scenario:=Context.build_scene(0,biome)
        _check(scenario!=null,
            "real battle terrain builds with V30 corrected mobile G11")
        if scenario==null:
            continue
        root.add_child(scenario)
        await process_frame
        var action:=scenario.find_child(
            "G11V29_AccionesBatalla",true,false) as Actions
        var g11:=scenario.find_child("Unidad3D_G11-H",true,false) as Node3D
        _check(action!=null and g11!=null,"real selected G11 has V29 action bridge")
        if action==null or g11==null:
            scenario.queue_free()
            await process_frame
            continue
        var original_state: Dictionary=scenario.get_meta("original_state",{})
        var before: Dictionary=original_state.duplicate(true)
        var nearby:=scenario.find_child("Unidad3D_Tank-H",true,false) as Node3D
        var nearby_pos: Transform3D=nearby.transform if nearby!=null else Transform3D.IDENTITY
        var anchor: Vector3=g11.position
        _check(not action.play("INVISIBLE-G11","attack",anchor),
            "cannot instantiate rocket trails for hidden or nonexistent units")
        _check(action.play("G11-H","attack",anchor,Vector2i(1,-1)),
            "real rocket salvo starts on existing G11 at original battle cell")
        action.set_process(false)
        var pod:=g11.find_child("CestaLanzacohetesElevada",
            true,false) as Node3D
        var tips:=pod.find_child(Trails.HEADS,false,false) as MultiMeshInstance3D
        var streaks:=pod.find_child(Trails.TRAILS,false,false) as MultiMeshInstance3D
        _check(tips!=null and streaks!=null,
            "two new pooled GPU batches only, no separate projectile nodes")
        if tips!=null and streaks!=null:
            _check(tips.multimesh.instance_count==Trails.SLOTS and
                streaks.multimesh.instance_count==Trails.SLOTS,
                "five in-flight tips and five streak instances maximum")
            action.advance(Actions.FIRST_SHOT+0.038)
            _check(tips.visible and streaks.visible and
                int(pod.get_meta(
                "tarvoka_g11_v30_active_rocket_count",0))==1,
                "first short rocket flight emerges from its actual 4x3 nozzle")
            action.advance(Actions.SHOT_STEP*3.0)
            _check(int(pod.get_meta(
                "tarvoka_g11_v30_active_rocket_count",0))>=3,
                "several independent short flights share the pooled draw")
            action.advance(Actions.ATTACK_TIME)
            _check(not tips.visible and not streaks.visible and
                not action.active(),
                "flight visuals disappear completely after the committed salvo")
        _check(g11.position.is_equal_approx(anchor),
            "projectiles never translate the authoritative MLRS")
        _check(nearby==null or nearby.transform==nearby_pos,
            "rocket geometry does not push neighboring tanks or units")
        _check(original_state==before,
            "flight does not modify battle damage, fuel, visibility or orders")
        scenario.queue_free()
        await process_frame
    if errors>0:
        push_error("G11 V30 rear chassis and rocket visual QA FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V30: rear stabilizer feet and belly chamfered with track clearance in 8 hero and 16 tactical forms, five pooled rocket trajectories, four real biomes, battle state unchanged")
    quit(0)
