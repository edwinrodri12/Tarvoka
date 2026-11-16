extends SceneTree

# TARVOKA Infantry Barracks V1: native Godot 4.3/OpenGL, NOT reference images.
# QA verifies three truly different building masses across 8 factions,
# five damage stages, UI, four cameras and 11 genuine GPU screenshots.
const Barracks=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,name: String) -> int:
    var result: int=1 if str(node.name)==name else 0
    for c in node.get_children():
        result+=_count(c,name)
    return result

func _picture(studio: Control,label: String) -> void:
    await _frames(8)
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png("res://artifacts/tarvoka_infantry_v1_"+label+".png")==OK)

func _audit_model(level: int,faction: int,damage: int) -> void:
    var model: Node3D=Barracks.build(level,faction,damage)
    assert(model!=null)
    assert(bool(model.get_meta("tarvoka_infantry_barracks_v1",false)))
    assert(bool(model.get_meta("visual_only",false)))
    assert(model.get_meta("tarvoka_building_kind","")=="infantry_barracks_visual")
    assert(int(model.get_meta("visual_level",-1))==level)
    assert(int(model.get_meta("visual_faction",-1))==faction)
    assert(int(model.get_meta("visual_damage_stage",-1))==damage)
    assert(_count(model,"CimentacionGeneral")==1)
    assert(_count(model,"PatioFormacion")==1)
    if damage==4:
        assert(_count(model,"FragmentoRuina_00")==1)
        assert(_count(model,"BarracaUnPisoN1")==0)
        assert(_count(model,"BarracaPrincipalDosPisosN2")==0)
        assert(_count(model,"ComandoCentralTresPisosN3")==0)
        assert(_count(model,"CampoEntrenamientoInfanteria")==0)
        assert(_count(model,"MastilYBanderaFaccion")==0)
        assert(_count(model,"PanelTecho_0")==0)
        assert(_count(model,"CristalVentana_0_-1")==0)
    else:
        assert(_count(model,"CampoEntrenamientoInfanteria")==1)
        assert(_count(model,"BarricadaDePractica_0")==1)
        assert(_count(model,"LineaFormacion_0")==1)
        assert(_count(model,"FranjaFaccionPatio")==1)
        if damage<=1:
            assert(_count(model,"MastilYBanderaFaccion")==1)
        else:
            assert(_count(model,"MastilYBanderaFaccion")==0)
        if level==1:
            assert(_count(model,"Nivel1_BarracaUnPisoCompacta")==1)
            assert(_count(model,"Nivel2_BarracasL_DosPlantas")==0)
            assert(_count(model,"Nivel3_ComplejoEnU_TresPlantas")==0)
            assert(_count(model,"BarracaUnPisoN1")==1)
            assert(_count(model,"TorreSupervisionNivel2")==0)
            assert(_count(model,"TorreOesteNivel3")==0)
            assert(_count(model,"BarricadaDePractica_3")==0)
        elif level==2:
            assert(_count(model,"Nivel1_BarracaUnPisoCompacta")==0)
            assert(_count(model,"Nivel2_BarracasL_DosPlantas")==1)
            assert(_count(model,"Nivel3_ComplejoEnU_TresPlantas")==0)
            assert(_count(model,"BarracaPrincipalDosPisosN2")==1)
            assert(_count(model,"AlaInstruccionN2")==1)
            assert(_count(model,"TorreSupervisionNivel2")==(1 if damage<=2 else 0))
            assert(_count(model,"TorreOesteNivel3")==0)
            assert(_count(model,"BarricadaDePractica_3")==1)
            assert(_count(model,"BarricadaDePractica_5")==0)
        else:
            assert(_count(model,"Nivel1_BarracaUnPisoCompacta")==0)
            assert(_count(model,"Nivel2_BarracasL_DosPlantas")==0)
            assert(_count(model,"Nivel3_ComplejoEnU_TresPlantas")==1)
            assert(_count(model,"ComandoCentralTresPisosN3")==1)
            assert(_count(model,"AlaOesteDosPisosN3")==1)
            assert(_count(model,"AlaEsteDosPisosN3")==1)
            assert(_count(model,"TorreOesteNivel3")==(1 if damage<=2 else 0))
            assert(_count(model,"TorreEsteNivel3")==(1 if damage<=2 else 0))
            assert(_count(model,"BarricadaDePractica_5")==1)
        if damage==1:
            # Roof panel 1 is physically missing on every room.
            assert(_count(model,"PanelTecho_1")==0)
        if damage==2:
            assert(_count(model,"PanelTecho_0")==0)
            assert(_count(model,"PanelTecho_2")==0)
        if damage==3:
            assert(_count(model,"PanelTecho_0")==0)
            assert(_count(model,"PanelTecho_3")==0)
            assert(_count(model,"CristalVentana_0_-1")==0)
        if damage<=2:
            assert(_count(model,"PanelTecho_3")>=1)
    assert(Barracks.mesh_count(model)>10)
    model.free()

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(Barracks.DAMAGE_STAGES.size()==5)
    assert(not Barracks.valid_spec(4,0,0))
    assert(not Barracks.valid_spec(2,8,0))
    assert(not Barracks.valid_spec(2,1,5))
    var models: int=0
    for faction in range(8):
        for damage in range(5):
            for level in range(1,4):
                _audit_model(level,faction,damage)
                models+=1
    assert(models==120)
    var sizes: Array[int]=[]
    for level in range(1,4):
        var model: Node3D=Barracks.build(level,6,0)
        sizes.append(Barracks.mesh_count(model))
        model.free()
    assert(sizes[0]<sizes[1] and sizes[1]<sizes[2])
    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(18)
    studio._switch_category(1)
    await _frames(6)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(10)
    assert(studio._role=="infantry_barracks")
    assert(studio.infantry_controls.visible)
    assert(not studio.naval_controls.visible)
    assert(not studio.airbase_controls.visible)
    assert(studio.infantry_level_picker.item_count==3)
    assert(studio.infantry_damage_picker.item_count==5)
    assert(studio.infantry_camera_picker.item_count==4)
    # Critically: native screenshots of *all three distinct levels*,
    # from the same camera and zoom, not hand-drawn or mockups.
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        await _picture(studio,"level_%d" % level)
    # L3 close-ups and roof audit.
    for view in [1,2,3]:
        studio.infantry_camera_picker.select(view)
        studio._change_infantry_camera(view)
        await _frames(7)
        assert(studio._infantry_camera_view==view)
        await _picture(studio,["overview","front_formation",
            "training_side","top"][view])
    studio.infantry_camera_picker.select(0)
    studio._change_infantry_camera(0)
    for damage in [1,2,3,4]:
        studio.infantry_damage_picker.select(damage)
        studio._change_infantry_setting(damage)
        await _frames(8)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _picture(studio,"damage_%d" % damage)
    studio.infantry_damage_picker.select(0)
    studio._change_infantry_setting(0)
    await _frames(6)
    studio._select_faction_view(6)
    await _frames(6)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    assert(_count(studio.model_root,"FranjaFaccionPatio")==1)
    await _picture(studio,"faction_6")
    studio._change_selected_building(2)
    await _frames(6)
    assert(studio._role=="naval_base")
    studio._change_selected_building(1)
    await _frames(6)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio._change_selected_building(3)
    await _frames(6)
    assert(studio._role=="infantry_barracks")
    studio.queue_free()
    await _frames(3)
    print("PASS INFANTRY BARRACKS V1: 120 combinations, 3 architecturally distinct tiers, 8 factions, five damage stages, four cameras, eleven real Godot captures, existing HQ/Airbase/Naval intact")
    quit(0)
