extends SceneTree

const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/APCFinishV3.gd")
const Armor=preload("res://scripts/ui/APCArmorV2.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
const Studio=preload("res://scripts/ui/UnitArtStudioWeb.gd")
const FRAME_SIZE=Vector2i(750,510)

func _initialize() -> void:
    call_deferred("_run")

func _shot(vp: SubViewport,camera: Camera3D,pos: Vector3,
        focus: Vector3,path: String) -> void:
    camera.position=pos
    camera.look_at(focus,Vector3.UP)
    for i in range(7):
        await process_frame
    var img: Image=vp.get_texture().get_image()
    assert(img!=null and not img.is_empty())
    assert(img.save_png(path)==OK)

func _run() -> void:
    var previous: Node3D=Models.build("apc",2,true,12)
    var modern: Node3D=Models.build("apc",2,true,13)
    var other: Node3D=Models.build("apc",1,true,13)
    assert(previous!=null and modern!=null and other!=null)
    assert(not previous.get_meta("tarvoka_apc_finish_v3",false))
    assert(modern.get_meta("tarvoka_apc_finish_v3",false))
    assert(modern.get_meta("tarvoka_apc_armor_v2",false))
    assert(modern.get_meta("tarvoka_apc_v2_tread_count",0)==288)
    assert(not Finish.apply(modern,Models.faction_paint_color(2)))
    assert(Finish.stage_for_hp(10,10)==0)
    assert(Finish.stage_for_hp(7,10)==1)
    assert(Finish.stage_for_hp(4,10)==2)
    assert(Finish.stage_for_hp(2,10)==3)
    assert(Finish.stage_for_hp(0,10)==4)

    var roof: MeshInstance3D=modern.find_child(
        "TechoBlindadoContinuoV3",true,false) as MeshInstance3D
    var side: MeshInstance3D=modern.find_child(
        "HombroTechoInclinadoV3_1",true,false) as MeshInstance3D
    var seam: MeshInstance3D=modern.find_child(
        "JuntaFlancoV3_1_4",true,false) as MeshInstance3D
    var turret: Node3D=modern.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    var turret_trim: MeshInstance3D=modern.find_child(
        "CarrilleraTorretaV3_1",true,false) as MeshInstance3D
    assert(roof!=null and roof.mesh is ArrayMesh)
    assert(side!=null and side.mesh is ArrayMesh)
    assert(seam!=null and turret!=null and turret_trim!=null)
    assert(turret_trim.get_parent().get_parent()==turret)
    assert(turret_trim.mesh is ArrayMesh)
    var hatch: MeshInstance3D=modern.find_child(
        "BlindajeRegistroSuperiorV3",true,false) as MeshInstance3D
    assert(hatch!=null and hatch.has_meta(Finish.PAINT))
    var base_count: int=Models.inspect_meshes(previous)
    var modern_count: int=Models.inspect_meshes(modern)
    assert(modern_count>base_count+12)
    assert(modern_count<base_count+70)

    var hatch_mat: StandardMaterial3D=hatch.material_override as StandardMaterial3D
    assert(hatch_mat!=null and hatch_mat.normal_enabled)
    var original_paint: Color=hatch_mat.albedo_color
    var paints: Array[Color]=[]
    for faction in range(8):
        assert(Models.apply_faction_palette(modern,faction)>15)
        var h: StandardMaterial3D=hatch.material_override
        var t: StandardMaterial3D=turret_trim.material_override
        var c: MeshInstance3D=modern.find_child(
            "CascoBlindadoEsculpidoP06",true,false) as MeshInstance3D
        assert(h.albedo_color==t.albedo_color)
        assert(h.albedo_color==(
            c.material_override as StandardMaterial3D).albedo_color)
        paints.append(h.albedo_color)
        assert(Models.inspect_meshes(modern)==modern_count)
    assert(paints[0]!=paints[1] and paints[2]!=paints[4])
    assert(Models.apply_faction_palette(modern,2)>15)
    assert((hatch.material_override as StandardMaterial3D).albedo_color==original_paint)
    var other_hatch: MeshInstance3D=other.find_child(
        "BlindajeRegistroSuperiorV3",true,false) as MeshInstance3D
    assert(other_hatch!=null and (
        other_hatch.material_override as StandardMaterial3D).albedo_color!=(
        hatch.material_override as StandardMaterial3D).albedo_color)

    var stage_parent: Node3D=modern.find_child(
        Finish.STAGES,true,false) as Node3D
    assert(stage_parent!=null)
    var smoke: MeshInstance3D=modern.find_child(
        "HumoMotorMedio",true,false) as MeshInstance3D
    var flame: MeshInstance3D=modern.find_child(
        "FuegoDestruccionP06",true,false) as MeshInstance3D
    assert(smoke!=null and flame!=null)
    var smoke_origin: Vector3=smoke.position
    var destroyed_wheel: Node3D=modern.find_child(
        "RuedaMotorizadaP06_1_0",true,false) as Node3D
    assert(destroyed_wheel!=null)
    var damaged_hub: MeshInstance3D=modern.find_child(
        "BujeRotoP06",true,false) as MeshInstance3D
    var torn_flank: MeshInstance3D=modern.find_child(
        "CostadoDerrumbadoP06",true,false) as MeshInstance3D
    assert(damaged_hub!=null and torn_flank!=null)
    for stage in range(5):
        assert(Finish.apply_stage(modern,stage))
        assert(int(modern.get_meta("tarvoka_apc_v3_damage_stage",-1))==stage)
        for i in range(1,5):
            var group: Node3D=stage_parent.find_child(
                "DanoP06Etapa_%d" % i,false,false) as Node3D
            assert(group!=null and group.visible==(stage>=i))
        assert(destroyed_wheel.visible==(stage<4))
        Finish.animate_damage(modern,1.9+float(stage))
        if stage>=2:
            assert(smoke.position.distance_to(smoke_origin)>0.004)
        assert(Models.inspect_meshes(modern)==modern_count)
    assert(Finish.apply_stage(modern,0))
    assert(destroyed_wheel.visible)
    Finish.animate_damage(modern,4.0)
    for i in range(1,5):
        assert(not stage_parent.find_child(
            "DanoP06Etapa_%d" % i,false,false).visible)
    assert(Models.inspect_meshes(modern)==modern_count)

    # Native base animation must remain usable at every injury stage.
    var ramp: Node3D=modern.find_child(
        "BisagraRampaP06",true,false) as Node3D
    var weapon: MeshInstance3D=modern.find_child(
        "FogonazoArmaP06",true,false) as MeshInstance3D
    assert(ramp!=null and weapon!=null)
    for stage in range(5):
        assert(Finish.apply_stage(modern,stage))
        assert(Rig.pose(modern,"move",0.38))
        assert(Rig.pose(modern,"attack",0.44))
        assert(weapon.visible)
        Rig.restore(modern)
        assert(not weapon.visible)
        assert(Rig.pose(modern,"open_ramp",1.0))
        assert(absf(ramp.rotation_degrees.x-78.0)<0.001)
        Rig.restore(modern)
        assert(Rig.pose(modern,"close_ramp",1.0))
        Rig.restore(modern)
        assert(absf(ramp.rotation_degrees.x-8.0)<0.001)
        assert(int(modern.get_meta("tarvoka_apc_v3_damage_stage",-1))==stage)
    assert(Finish.apply_stage(modern,0))

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var viewport:=SubViewport.new()
    viewport.size=FRAME_SIZE
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.own_world_3d=true
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#1A2C36")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#C8D8DE")
    env.ambient_light_energy=0.89
    world.environment=env
    viewport.add_child(world)
    var sunlight:=DirectionalLight3D.new()
    sunlight.rotation_degrees=Vector3(-46,-36,0)
    sunlight.light_energy=1.45
    viewport.add_child(sunlight)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-20,128,0)
    fill.light_energy=0.55
    viewport.add_child(fill)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=3.8
    viewport.add_child(cam)
    cam.current=true
    viewport.add_child(modern)
    await _shot(viewport,cam,Vector3(4.4,2.3,-5.4),
        Vector3(0,0.53,0),
        "res://artifacts/tarvoka_apc_p06_v3_frente_techo.png")
    await _shot(viewport,cam,Vector3(4.9,3.6,3.4),
        Vector3(0,0.74,0),
        "res://artifacts/tarvoka_apc_p06_v3_superior_torreta.png")
    await _shot(viewport,cam,Vector3(6.5,2.2,-0.6),
        Vector3(0,0.50,0),
        "res://artifacts/tarvoka_apc_p06_v3_juntas_laterales.png")
    var damage_sheet:=Image.create(5*FRAME_SIZE.x,FRAME_SIZE.y,
        false,Image.FORMAT_RGBA8)
    for stage in range(5):
        assert(Finish.apply_stage(modern,stage))
        Finish.animate_damage(modern,0.55+float(stage)*0.44)
        cam.position=Vector3(4.3,2.3,4.7)
        cam.look_at(Vector3(0,0.53,0),Vector3.UP)
        for frame in range(7):
            await process_frame
        var img: Image=viewport.get_texture().get_image()
        damage_sheet.blit_rect(img,Rect2i(Vector2i.ZERO,FRAME_SIZE),
            Vector2i(stage*FRAME_SIZE.x,0))
    assert(damage_sheet.save_png(
        "res://artifacts/tarvoka_apc_p06_v3_cinco_niveles_dano.png")==OK)
    assert(Finish.apply_stage(modern,0))
    viewport.remove_child(modern)
    viewport.add_child(previous)
    await _shot(viewport,cam,Vector3(4.4,2.3,-5.4),
        Vector3(0,0.53,0),
        "res://artifacts/tarvoka_apc_p06_v2_antes.png")
    viewport.remove_child(previous)
    modern.free()
    previous.free()
    other.free()
    viewport.free()
    await process_frame
    print("PASS APC P06 V3: roof sculpt, continuous weld seams, pivot-attached turret, five progressive smoke/fire/fragment damage states, 8 palettes and 6x6/ramp/firing regression, engine renders")
    quit(0)
