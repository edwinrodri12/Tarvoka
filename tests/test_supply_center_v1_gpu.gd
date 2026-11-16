extends SceneTree

# Native Godot 4.3 supply-center architectural acceptance.
# This tests VISUALS ONLY; does not create gameplay depots or change balance.
const Depot=preload("res://scripts/ui/SupplyCenter3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var found: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        found+=_count(child,label)
    return found

func _capture(studio: Control,label: String) -> void:
    await _frames(7)
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png(
        "res://artifacts/tarvoka_supply_center_v1_"+label+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(Depot.DAMAGE_STAGES.size()==5)
    assert(not Depot.valid_spec(4,0,0))
    assert(not Depot.valid_spec(2,8,0))
    assert(not Depot.valid_spec(2,0,5))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Depot.build(2,faction,damage)
            assert(model!=null)
            assert(bool(model.get_meta("tarvoka_supply_center_v1",false)))
            assert(bool(model.get_meta("visual_only",false)))
            assert(str(model.get_meta("tarvoka_building_kind",""))=="supply_center_visual")
            assert(int(model.get_meta("visual_faction",-1))==faction)
            assert(int(model.get_meta("visual_level",-1))==2)
            assert(int(model.get_meta("visual_damage_stage",-1))==damage)
            assert(_count(model,"PlataformaBaseSuministros")==1)
            assert(_count(model,"CalzadaCamionesLogisticos")==1)
            assert(_count(model,"MuroPosteriorCerrado")==(0 if damage==4 else 1))
            assert(_count(model,"TanqueVerticalCombustible_0")==(0 if damage==4 else 1))
            assert(_count(model,"TanqueVerticalCombustible_1")==(0 if damage>=3 else 1))
            assert(_count(model,"BunkerMunicionesSegregado")==1)
            assert(_count(model,"TechoReforzadoBunker")==(1 if damage<=2 else 0))
            assert(_count(model,"PortonEnrolladoCarga_0_0")==(1 if damage<=2 else 0))
            assert(_count(model,"PortonEnrolladoCarga_1_0")==(1 if damage<=1 else 0))
            assert(_count(model,"PuenteGruaDistribucion")==0)
            assert(_count(model,"OficinaControlLogistico")==(1 if damage<=2 else 0))
            assert(_count(model,"MarcaFaccionPatio")==(0 if damage==4 else 1))
            if damage<=1:
                assert(_count(model,"PanelTechoDeposito_00")==1)
                assert(_count(model,"PortonBlindadoBunker")==1)
                assert(_count(model,"BandaFaccionTanque_0")==1)
                assert(_count(model,"PosteProteccionTanques_3")==1)
            if damage==2:
                assert(_count(model,"PanelTechoDeposito_01")==0)
                assert(_count(model,"PanelTechoDeposito_03")==0)
                assert(_count(model,"PortonEnrolladoCaido_1")==1)
                assert(_count(model,"BandaFaccionTanque_0")==0)
                assert(_count(model,"TuberiaDistribucionPrincipal")==1)
            if damage==3:
                assert(_count(model,"MuroDerechoFragmentado")==1)
                assert(_count(model,"PortonEnrolladoCaido_0")==1)
                assert(_count(model,"RestosTanqueCombustible_1")==1)
                assert(_count(model,"MuroBunkerRoto")==1)
                assert(_count(model,"PanelTechoDeposito_00")==0)
                assert(_count(model,"PanelTechoDeposito_03")==1)
                assert(_count(model,"TuberiaDistribucionPrincipal")==0)
            if damage==4:
                assert(_count(model,"EscombrosDeposito_00")==1)
                assert(_count(model,"CilindroDepositoRoto")==1)
                assert(_count(model,"EscombrosBunkerMuniciones")==1)
                assert(_count(model,"MuroLateralIzquierdo")==0)
                assert(_count(model,"PortonBlindadoBunker")==0)
                assert(_count(model,"PanelTechoDeposito_03")==0)
            assert(Depot.count_meshes(model)>=9)
            model.free()
            variants+=1
    assert(variants==40)
    for level in range(1,4):
        var model: Node3D=Depot.build(level,6,0)
        assert(model!=null)
        assert(_count(model,"OficinaControlLogistico")==(0 if level==1 else 1))
        assert(_count(model,"PuenteGruaDistribucion")==(1 if level==3 else 0))
        assert(_count(model,"ExtractorSuperior_0")==(1 if level==3 else 0))
        assert(_count(model,"MaquinaLecturaCargamentos")==(0 if level==1 else 1))
        assert(_count(model,"TanqueVerticalCombustible_0")==1)
        assert(_count(model,"PortonEnrolladoCarga_0_0")==1)
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(5)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(10)
    assert(studio._role=="supply_center")
    assert(studio.supply_controls.visible)
    assert(not studio.naval_controls.visible)
    assert(not studio.airbase_controls.visible)
    assert(studio.supply_level_picker.item_count==3)
    assert(studio.supply_damage_picker.item_count==5)
    assert(studio.supply_camera_picker.item_count==4)
    for view in range(4):
        studio.supply_camera_picker.select(view)
        studio._change_supply_camera(view)
        await _frames(6)
        assert(studio._supply_camera_view==view)
        await _capture(studio,["overview","loading_docks",
            "fuel_ammo","rooftop"][view])
    for level in [2,3]:
        studio.supply_level_picker.select(level-1)
        studio._change_supply_setting(level-1)
        await _frames(6)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        await _capture(studio,"level_%d" % level)
    for damage in [1,2,3,4]:
        studio.supply_damage_picker.select(damage)
        studio._change_supply_setting(damage)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _capture(studio,"damage_%d" % damage)
    studio.supply_damage_picker.select(0)
    studio._change_supply_setting(0)
    await _frames(6)
    studio._select_faction_view(6)
    await _frames(6)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    assert(_count(studio.model_root,"LetreroIdentidadFaccion")==1)
    await _capture(studio,"faction_6")
    # Regression: original approved three buildings are still selectable.
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
    assert(studio._role=="supply_center")
    studio.queue_free()
    await _frames(3)
    print("PASS SUPPLY CENTER V1: 40 faction/damage models, 3 levels, separate fuel and ammo, two truck loading bays, four native 3D Studio cameras, 11 captures, previous three buildings preserved")
    quit(0)
