extends SceneTree

# V22 real native OpenGL regression and screenshot acceptance.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const D21 = preload("res://scripts/ui/HeadquartersDamageV21.gd")
const D22 = preload("res://scripts/ui/HeadquartersDamageV22.gd")
const Fire = preload("res://scripts/ui/HeadquartersFireV22.gd")
const Impact = preload("res://scripts/ui/HeadquartersImpactV21.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int = 7) -> void:
    for _i in range(n):
        await process_frame

func _save(studio: Control,name: String) -> Image:
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and image.get_width()>500)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts")) == OK)
    assert(image.save_png("res://artifacts/"+name)==OK)
    return image

func _diff(a: Image,b: Image) -> int:
    var size: Vector2i = Vector2i(160,105)
    var first: Image = a.duplicate()
    var second: Image = b.duplicate()
    first.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
    second.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
    var changed := 0
    for y in range(0,size.y,2):
        for x in range(0,size.x,2):
            var p: Color = first.get_pixel(x,y)
            var q: Color = second.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.12:
                changed += 1
    return changed

func _model(level: int,stage: int,faction: int = 0) -> Node3D:
    var building: Node3D = HQ.build(level,faction,
        "destruido" if stage==4 else "operativo")
    assert(building!=null)
    assert(D21.apply(building,stage,level))
    assert(D22.apply(building,stage,level))
    return building

func _run() -> void:
    # Structural state must be meaningful at all 3 building levels; no
    # wrongly collapsed main control center or overpainted faction emblems.
    for level in range(1,4):
        var intact: Node3D = _model(level,0)
        assert(intact.find_child("AntenaDeMandoMastil",true,false).visible)
        assert(intact.find_child("MuroPosteriorCentralContinuoV21",true,false).visible)
        assert(intact.find_child("MastilCaidoDeMandoV22",true,false)==null)
        assert(not intact.has_node(Fire.STAGE_NAME))
        intact.free()
        var light: Node3D = _model(level,1)
        assert(not light.find_child("AntenaDeMandoMastil",true,false).visible)
        assert(not light.find_child("AntenaDeMandoBaliza",true,false).visible)
        assert(light.find_child("MastilCaidoDeMandoV22",true,false)!=null)
        assert(light.find_child("BaseAntenaRasgadaV22",true,false)!=null)
        assert(not light.find_child("PlatoExterior",true,false).visible)
        assert(light.find_child("PlatoRadarCaidoV22",true,false)!=null)
        assert(light.find_child("MuroPosteriorCentralContinuoV21",true,false).visible)
        assert(not light.has_node(Fire.STAGE_NAME))
        if level>=2:
            assert(not light.find_child("AntenaSuperiorMastil",true,false).visible)
            assert(light.find_child("MastilCaidoDeTorreV22",true,false)!=null)
        light.free()
        var middle: Node3D = _model(level,2)
        assert(not middle.find_child("TechoAla1",true,false).visible)
        assert(not middle.find_child("CubiertaServidores",true,false).visible)
        assert(middle.find_child("TechoRotoYVariosPanelesDesprendidosV22",true,false)!=null)
        assert(middle.find_child("GaleriaLateralIzquierda",true,false).visible)
        assert(middle.find_child("MuroPosteriorCentralContinuoV21",true,false).visible)
        middle.free()
        var heavy: Node3D = _model(level,3)
        assert(not heavy.find_child("TechoAla-1",true,false).visible)
        assert(not heavy.find_child("GaleriaLateralIzquierda",true,false).visible)
        assert(heavy.find_child("AlaCompletamenteHundidaAntesDeDestruccionV22",true,false)!=null)
        assert(heavy.find_child("SueloInteriorExpuestoAlaV22",true,false)!=null)
        assert(heavy.find_child("MuroPosteriorCentralContinuoV21",true,false).visible)
        heavy.free()
        var rubble: Node3D = _model(level,4)
        assert(rubble.find_child("MuroPosteriorCentralContinuoV21",true,false)==null)
        assert(rubble.find_child("RestosMuroPosteriorHQV21_0",true,false)!=null)
        assert(rubble.find_child("MastilCaidoDeMandoV22",true,false)==null)
        rubble.free()

    root.content_scale_size = Vector2i(1280,800)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    await _frames(10)
    studio._switch_category(1)
    await _frames(8)
    assert(studio.hq_damage_stage_picker.item_count==5)
    # Inspect close enough for a fallen antenna to occupy multiple genuine
    # GPU pixels, instead of comparing distant 160px thumbnails.
    studio._zoom = 1.60
    studio._update_camera()
    await _frames(4)
    var intact_img: Image = _save(studio,"tarvoka_hq_v22_0_intact.png")
    studio._change_hq_damage_stage(1)
    await _frames(8)
    assert(studio.model_root.find_child("MastilCaidoDeMandoV22",true,false)!=null)
    assert(not studio.model_root.find_child("AntenaDeMandoMastil",true,false).visible)
    var light_img: Image = _save(studio,"tarvoka_hq_v22_1_fallen_antennas.png")
    assert(_diff(intact_img,light_img)>6)

    studio._change_hq_damage_stage(2)
    await _frames(10)
    var medium_fx: TarvokaHeadquartersFireV22 = studio.model_root.get_node(
        Fire.STAGE_NAME) as TarvokaHeadquartersFireV22
    assert(medium_fx != null and medium_fx.is_animating())
    assert(medium_fx.smoke_count()==3 and medium_fx.flame_batches()==0)
    assert(studio.model_root.find_child("TechoRotoYVariosPanelesDesprendidosV22",true,false)!=null)
    var smoke_before: Vector3 = medium_fx.get_node("HumoAnimadoV22_0").position
    medium_fx.advance(0.50)
    assert(medium_fx.get_node("HumoAnimadoV22_0").position!=smoke_before)
    var medium_img: Image = _save(studio,"tarvoka_hq_v22_2_smoke_broken_roof.png")
    assert(_diff(light_img,medium_img)>20)

    studio._change_hq_damage_stage(3)
    await _frames(10)
    var critical_fx: TarvokaHeadquartersFireV22 = studio.model_root.get_node(
        Fire.STAGE_NAME) as TarvokaHeadquartersFireV22
    assert(critical_fx != null and critical_fx.is_animating())
    assert(critical_fx.smoke_count()==5)
    assert(critical_fx.flame_batches()==1)
    var flames: MultiMeshInstance3D = critical_fx.get_node(
        "LlamasCriticasUnSoloLoteV22") as MultiMeshInstance3D
    assert(flames.multimesh.instance_count==Fire.MAX_FLAMES)
    var first: Transform3D = flames.multimesh.get_instance_transform(0)
    critical_fx.advance(0.22)
    var second: Transform3D = flames.multimesh.get_instance_transform(0)
    assert(first != second)
    assert(studio.model_root.find_child("ColumnaEstructuralDesgarradaCriticaV22_0",true,false)!=null)
    var critical_img: Image = _save(studio,"tarvoka_hq_v22_3_fire_collapsed_wing.png")
    assert(_diff(medium_img,critical_img)>30)
    # Bullet/explosive impact V21 remain callable on the BURNING V22 HQ.
    studio._play_hq_bullet_v21()
    var hit: TarvokaHeadquartersImpactV21 = studio.model_root.get_node(
        Impact.STAGE_NAME) as TarvokaHeadquartersImpactV21
    assert(hit.is_running() and hit.current_kind()==Impact.BULLET)
    hit.stop()
    studio._play_hq_explosion_v21()
    assert(hit.is_running() and hit.current_kind()==Impact.EXPLOSIVE)
    _save(studio,"tarvoka_hq_v22_3_fire_and_explosion.png")

    studio._set_hq_map_lod(true)
    assert(not critical_fx.visible and not critical_fx.is_animating())
    assert(not hit.visible and not hit.is_running())
    studio._set_hq_map_lod(false)
    assert(critical_fx.visible and critical_fx.is_animating())
    studio._change_hq_damage_stage(4)
    await _frames(8)
    assert(studio.model_root.get_node_or_null(Fire.STAGE_NAME)==null)
    assert(studio.model_root.find_child("MastilCaidoDeMandoV22",true,false)==null)
    var destroyed_img: Image = _save(studio,"tarvoka_hq_v22_4_destroyed.png")
    assert(_diff(critical_img,destroyed_img)>40)
    studio._change_hq_damage_stage(0)
    await _frames()
    assert(studio.model_root.get_node_or_null(Fire.STAGE_NAME)==null)
    assert(studio.model_root.find_child("AntenaDeMandoMastil",true,false).visible)
    studio.queue_free()
    await _frames(4)
    print("PASS HQ V22: level 1-3 fallen antennas, medium real broken roof and animated smoke, critical real wing collapse with animated GPU fire, 5 distinct stages, V21 hits and LOD")
    quit(0)
