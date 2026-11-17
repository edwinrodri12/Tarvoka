extends SceneTree

# V13 visual-stage, impact, crash and original-geometry regression in Godot 4.3.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V7=preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
const V12=preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
var failures: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V13: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var mobile: Node3D=Models.build("attack_heli",0,true,10)
    _check(mobile!=null and not V13.has_model(mobile),
        "battle LOD10 remains unchanged and allocates no V13 effects")
    if mobile!=null: mobile.free()
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and V12.has_model(model) and V13.has_model(model),
            "V12.1 geometry and V13 damage built for faction %d" % faction)
        if model==null or not V13.has_model(model):
            if model!=null: model.free()
            continue
        root.add_child(model)
        var count: int=Models.inspect_meshes(model)
        _check(V13.apply(model,Models.faction_paint_color(faction)) and
            Models.inspect_meshes(model)==count,
            "V13 apply is idempotent; does not duplicate original or effects")
        var rotor: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var tail: Node3D=model.find_child(V1.TAIL_ROTOR,true,false) as Node3D
        var scratches: Node3D=model.find_child(V13.SCRATCH,true,false) as Node3D
        var burn: Node3D=model.find_child(V13.BURN,true,false) as Node3D
        var smoke: Node3D=model.find_child(V13.SMOKE,true,false) as Node3D
        var fire: Node3D=model.find_child(V13.FIRE,true,false) as Node3D
        var burst: Node3D=model.find_child(V13.IMPACT,true,false) as Node3D
        var wreck: Node3D=model.find_child(V13.WRECK,true,false) as Node3D
        var wreck_body: Node3D=model.find_child(V13.WRECK_BODY,true,false) as Node3D
        var original_glass: Node3D=model.find_child(V2.GLASS,true,false) as Node3D
        var original_guard: Node3D=model.find_child(V3.GUARD,true,false) as Node3D
        var intact_guard_mark: Node3D=model.find_child(
            V7.TAIL_MARK+"0",true,false) as Node3D
        var intact_canopy_rail: Node3D=model.find_child(
            "A01_V2_MarcoLong_2_0",true,false) as Node3D
        var crash_finish: Node3D=model.find_child(
            "A01V13_AcabadoMetalRoto",true,false) as Node3D
        var detonation: Node3D=model.find_child(V13.DETONATION,true,false) as Node3D
        var ground_dust: Node3D=model.find_child(V13.LANDING_DUST,true,false) as Node3D
        _check(detonation!=null and not detonation.visible
            and ground_dust!=null and not ground_dust.visible,
            "V13.2 explosion and landing dust begin hidden on a pristine A01")
        _check(wreck_body!=null and not wreck_body.visible
            and original_glass!=null and original_glass.visible
            and original_guard!=null and original_guard.visible
            and intact_canopy_rail!=null and intact_canopy_rail.visible
            and crash_finish!=null and not wreck_body.visible,
            "V13.4 leaves original canopy/rail and complete tail guard untouched until wreck")
        _check(rotor!=null and rotor.visible and tail!=null and tail.visible
            and scratches!=null and not scratches.visible
            and burn!=null and not burn.visible
            and smoke!=null and not smoke.visible
            and fire!=null and not fire.visible
            and wreck!=null and not wreck.visible,
            "pristine art has intact rotors and zero damage overlays")
        _check(V13.set_stage(model,1) and scratches.visible and not burn.visible,
            "stage1 bullet scars appear without engine fire")
        _check(V13.pose(model,"hit_bullet",0.31) and burst.visible,
            "stage1 bullet hit has real emissive spark burst")
        _check(not detonation.visible and not ground_dust.visible,
            "bullet impact does not accidentally trigger full detonation")
        var shock: MeshInstance3D=model.find_child(
            "A01V13_OndaChoqueLateral",true,false) as MeshInstance3D
        _check(shock!=null and shock.mesh is TorusMesh
            and shock.scale.x>1.20,
            "3D radial impact ring visibly expands on hit")
        V13.restore(model)
        _check(not burst.visible and scratches.visible,
            "temporary impact flashes disappear while scars persist")
        _check(V13.set_stage(model,2) and burn.visible and smoke.visible
            and not fire.visible and rotor.visible,
            "stage2 scorched armor and smoke, no flames")
        var smoke_puff: MeshInstance3D=model.find_child(
            "A01V13_ColumnaHumo_0",true,false) as MeshInstance3D
        var smoke_mat: StandardMaterial3D=(
            smoke_puff.material_override as StandardMaterial3D
            if smoke_puff!=null else null)
        _check(smoke.get_child_count()==8 and smoke_puff!=null
            and smoke_puff.mesh is QuadMesh and smoke_mat!=null
            and smoke_mat.billboard_mode==BaseMaterial3D.BILLBOARD_ENABLED
            and smoke_mat.albedo_texture is ImageTexture,
            "V13.1 medium smoke uses eight soft alpha 3D billboards, not rigid balls")
        var smoke_start: Vector3=smoke_puff.position if smoke_puff!=null else Vector3.ZERO
        _check(V13.animate_ambient(model,2.7) and smoke_puff!=null
            and smoke_puff.position.distance_to(smoke_start)>0.07,
            "stage2 smoke plumes rise even without impact playback")

        _check(V13.pose(model,"hit_explosive",0.18)
            and detonation.visible,
            "V13.2 explosion opens with fast primary ignition")
        var first: Node3D=model.find_child(
            "A01V13_ExplosionPrimaria",true,false) as Node3D
        var second: Node3D=model.find_child(
            "A01V13_ExplosionSecundaria",true,false) as Node3D
        var pressure: MeshInstance3D=model.find_child(
            "A01V13_AnilloExpansivo",true,false) as MeshInstance3D
        _check(first!=null and first.visible and second!=null
            and not second.visible,
            "secondary fire pulse follows primary; they do not appear together")
        var early_ring: Vector3=pressure.scale if pressure!=null else Vector3.ZERO
        _check(V13.pose(model,"hit_explosive",0.34)
            and detonation.visible and burst.visible
            and first.visible and second.visible,
            "explosive hit adds distinct second 3D ignition over original shake")
        _check(pressure!=null and pressure.mesh is TorusMesh
            and pressure.scale.x>early_ring.x,
            "V13.2 physical shock ring expands between two blast phases")
        V13.restore(model)
        _check(not detonation.visible and not ground_dust.visible,
            "transient explosion disappears on idle without erasing scorch")
        _check(V13.set_stage(model,3) and fire.visible and smoke.visible
            and rotor.visible and tail.visible,
            "stage3 critical burning damage before final destruction")
        var flame: MeshInstance3D=model.find_child(
            "A01V13_LlamaMotor_0",true,false) as MeshInstance3D
        var flame_mat: StandardMaterial3D=(
            flame.material_override as StandardMaterial3D if flame!=null else null)
        _check(fire.get_child_count()==6 and flame!=null
            and flame.mesh is ArrayMesh and flame_mat!=null
            and flame_mat.vertex_color_use_as_albedo
            and flame_mat.emission_enabled,
            "V13.1 critical fire consists of six tapered solid gradient tongues")
        var flame_start: Vector3=flame.scale if flame!=null else Vector3.ZERO
        _check(V13.animate_ambient(model,0.84) and flame!=null
            and flame.scale.distance_to(flame_start)>0.01,
            "stage3 flames flicker independently while helicopter remains still")
        _check(V13.pose(model,"move",0.43),
            "original mobile motion still animates with critical visual damage")
        V13.restore(model)
        _check(V13.set_stage(model,4) and wreck.visible
            and not rotor.visible and not tail.visible
            and wreck.top_level and ground_dust.top_level,
            "stage4 world-anchors detached debris AND later ground-impact dust")
        var charred: MeshInstance3D=model.find_child(
            "A01V13_CarbonizacionFijaMotor",true,false) as MeshInstance3D
        var chip: MeshInstance3D=model.find_child(
            "A01V13_VidrioAstillado_0",true,false) as MeshInstance3D
        var bent_rim: MeshInstance3D=model.find_child(
            "A01V13_AroColaTorcido_01",true,false) as MeshInstance3D
        _check(wreck_body.visible and not wreck_body.top_level
            and not original_glass.visible and not original_guard.visible
            and intact_guard_mark!=null and not intact_guard_mark.visible,
            "V13.3 hides intact canopy, complete guard and floating tail markers")
        _check(charred!=null and charred.get_parent()==wreck_body
            and chip!=null and chip.mesh is ArrayMesh
            and bent_rim!=null and bent_rim.get_parent()==wreck_body
            and model.find_child("A01V13_CarbonizacionFinal",true,false)==null,
            "V13.3 soot follows fuselage, with real shattered glass and severed rim")
        var exposed_engine: MeshInstance3D=model.find_child(
            "A01V13_AberturaMotorOscura",true,false) as MeshInstance3D
        var roof_flap: MeshInstance3D=model.find_child(
            "A01V13_TapaMotorLevantada_1",true,false) as MeshInstance3D
        var bent_canopy: MeshInstance3D=model.find_child(
            "A01V13_MarcoTorcidoDelantero_1",true,false) as MeshInstance3D
        _check(exposed_engine!=null and exposed_engine.mesh is BoxMesh
            and roof_flap!=null and bent_canopy!=null
            and not intact_canopy_rail.visible and crash_finish.visible,
            "V13.4 reveals torn engine, lifted metal and interrupted wreck canopy instead of pristine rails")
        var rest_position: Vector3=model.position
        var rest_rotation: Vector3=model.rotation_degrees
        var detached_origin: Vector3=wreck.global_position
        var debris: Node3D=model.find_child(
            "A01V13_FragmentoRotor_0",true,false) as Node3D
        var rest_debris: Vector3=debris.position if debris!=null else Vector3.ZERO
        var tail_shard: MeshInstance3D=model.find_child(
            "A01V13_FragmentoRotorCola",true,false) as MeshInstance3D
        _check(debris is MeshInstance3D and (debris as MeshInstance3D).mesh is ArrayMesh
            and tail_shard!=null and tail_shard.mesh is ArrayMesh,
            "main and tail rotor now have actual closed irregular blade shards")
        _check(debris!=null and debris.has_meta("a01_v13_launch")
            and (debris.get_meta("a01_v13_launch") as Vector3).y>1.9
            and tail_shard.has_meta("a01_v13_launch")
            and (tail_shard.get_meta("a01_v13_launch") as Vector3).z>2.5,
            "blade launch points match V1 main and tail rotor hubs")
        _check(V13.pose(model,"destroy",0.03)
            and debris.position.y>1.80,
            "new rotor shards begin in the air, not already on the ground")
        _check(V13.pose(model,"destroy",0.75)
            and model.position.y<rest_position.y-0.09
            and absf(model.rotation_degrees.z-rest_rotation.z)>15.0,
            "stage4 real crash animation falls and banks dramatically")
        _check(wreck.top_level
            and wreck.global_position.distance_to(detached_origin)<0.001,
            "broken rotor shards DO NOT fall or bank with helicopter fuselage")
        _check(debris!=null and debris.position.distance_to(rest_debris)>0.05
            and fire.visible and smoke.visible and ground_dust.visible,
            "wreckage, ground dust and burning engine overlap in crash interval")
        var dust_quad: MeshInstance3D=model.find_child(
            "A01V13_NubePolvo_0",true,false) as MeshInstance3D
        var dust_material: StandardMaterial3D=(
            dust_quad.material_override as StandardMaterial3D
            if dust_quad!=null else null)
        var dust_texture: ImageTexture=(
            dust_material.albedo_texture as ImageTexture
            if dust_material!=null else null)
        _check(ground_dust.get_child_count()==5 and dust_quad!=null
            and dust_quad.mesh is QuadMesh
            and dust_texture!=null
            and dust_texture.get_image().get_pixel(32,32).a>0.65,
            "contact dust uses a dense feathered independent native texture")
        _check(V13.pose(model,"destroy",1.0) and not ground_dust.visible
            and not detonation.visible,
            "final wreck leaves only sustained engine fire; blast/dust expire")
        _check(debris!=null and debris.global_position.y<0.23,
            "main rotor fragment rests near terrain instead of hovering")
        _check(debris!=null and debris.position.distance_to(rest_debris)<0.001,
            "ballistic rotor fragment settles at pre-authored wreck position")
        var stable_world_origin: Vector3=wreck.global_position
        model.rotation_degrees.y+=37.0
        _check(wreck.top_level and
            wreck.global_position.distance_to(stable_world_origin)<0.001,
            "wreck pieces keep ground anchor when preview model rotates")
        model.rotation_degrees.y-=37.0
        V13.restore(model)
        _check(model.position.distance_to(rest_position)<0.001
            and model.rotation_degrees.distance_to(rest_rotation)<0.001
            and wreck.visible and not rotor.visible,
            "restore resets transforms without repairing permanent stage4 wreck")
        _check(V13.set_stage(model,0) and rotor.visible and tail.visible
            and not wreck.visible and not wreck.top_level
            and not wreck_body.visible and original_glass.visible
            and intact_canopy_rail.visible and original_guard.visible
            and intact_guard_mark.visible
            and not ground_dust.top_level and not ground_dust.visible
            and not detonation.visible and not smoke.visible
            and not scratches.visible and not fire.visible,
            "repair restores original canopy, complete tail guard and both rotors")
        _check(V13.pose(model,"attack",0.34)
            and V12.has_model(model),
            "approved V12 cannon and original muzzle flash still function")
        V13.restore(model)
        _check(Models.inspect_meshes(model)==count,
            "all original approved V12.1 geometry and mesh count preserved")
        model.queue_free()
        await process_frame
    if failures>0:
        push_error("A01 V13 native QA failed %d checks" % failures)
        quit(1)
        return
    print("PASS A01 V13: 8 factions, 5 reversible visual stages, sparks/scorch/smoke/fire, moving wreckage, original animation and Android LOD preserved")
    quit(0)
