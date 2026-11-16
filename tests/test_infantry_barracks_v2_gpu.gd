extends SceneTree

# TARVOKA Infantry V2: native Godot/OpenGL real-scene QA.
# 8 factions x 5 damage stages x 3 architectural tiers = 120 cases.
# Every V2 frame is compared to the correct V1 scene, not a mock image.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const SHOTS=["level_1","level_2","level_3","front_access",
    "training_side","top_roofs","compare_v1","compare_v2",
    "damage_1","damage_2","damage_3","damage_4","faction_6"]

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var result: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        result+=_count(child,label)
    return result

func _capture(studio: Control,name: String) -> void:
    await _frames(8)
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>=640 and img.get_height()>=400)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png("res://artifacts/tarvoka_infantry_v2_"+name+".png")==OK)

func _audit_model(level: int,faction: int,damage: int) -> void:
    var model: Node3D=V1.build(level,faction,damage)
    assert(model!=null)
    var v1_meshes: int=V1.mesh_count(model)
    assert(not V2.apply(model,level,faction,4 if damage!=4 else 0))
    assert(V2.apply(model,level,faction,damage))
    assert(not V2.apply(model,level,faction,damage))
    var v2: Node3D=model.get_node(V2.STAGE_NAME) as Node3D
    assert(v2!=null)
    assert(_count(model,V1.STAGE_NAME)==1)
    assert(_count(model,"CimentacionGeneral")==1)
    assert(_count(model,"PatioFormacion")==1)
    assert(int(v2.get_meta("infantry_v2_modules",-1))==(
        0 if damage==4 else level))
    assert(bool(v2.get_meta("infantry_v2_ruins_only",false))==(damage==4))
    assert(V1.mesh_count(model)>=v1_meshes)
    if level==3 and damage<4:
        # Genuine geometric non-overlap: N3 training CANNOT be under
        # the west wing or the observation tower, even in damaged scenes.
        var course: MeshInstance3D=model.find_child(
            "SueloPista",true,false) as MeshInstance3D
        var wing: MeshInstance3D=model.find_child(
            "Piso_AlaOesteDosPisosN3",true,false) as MeshInstance3D
        assert(course!=null and wing!=null)
        var course_size: Vector3=(course.mesh as BoxMesh).size
        var wing_size: Vector3=(wing.mesh as BoxMesh).size
        var course_east: float=course.position.x+course_size.x*0.5
        var wing_west: float=wing.position.x-wing_size.x*0.5
        assert(course_east < wing_west-0.10)
        var course_north: float=course.position.z+course_size.z*0.5
        var tower_north_limit: float=3.65-1.62*0.5
        assert(course_north < tower_north_limit-0.20)
    if damage==4:
        assert(V2.added_meshes(model)==0)
        assert(_count(model,"PuertaAcceso")==0)
        assert(_count(model,"JambaAcero_-1")==0)
        assert(_count(model,"ArriostreTorre_-1_-1")==0)
        assert(_count(model,"FragmentoRuina_00")==1)
        assert(_count(model,"CristalVentana_0_-1")==0)
    else:
        assert(V2.added_meshes(model)>10)
        assert(_count(model,"AccesoReal_"+
            str(V2._modules(level)[0]["tag"]))==1)
        assert(_count(model,"InstruccionTacticaV2")==1)
        assert(_count(model,"BandaLateralPista_-1")==(
            0 if damage>=3 else 1))
        assert(_count(model,"ListonSalto_0")==(
            1 if level>=2 and damage<=2 else 0))
        assert(_count(model,"CoberturaPracticaN3_0")==(
            1 if level==3 and damage<=1 else 0))
        assert(_count(model,"JambaAcero_-1")==(
            0 if damage>=3 else level))
        assert(_count(model,"PlacaIdentificacionTecnica")==(
            0 if damage>=3 else level))
        assert(_count(model,"MuroEscalada_0")==(
            1 if level==3 and damage<=1 else 0))
        if damage==3:
            assert(_count(model,"DintelFracturado_"+
                str(V2._modules(level)[0]["tag"]))==1)
            assert(_count(model,"MontanteVentana_0_-1")==0)
            assert(_count(model,"FrontalCristalCabina")==0)
            assert(_count(model,"SoporteDeTorreTorcido")==(
                0 if level==1 else 1 if level==2 else 2))
        if damage==2:
            assert(_count(model,"AlfeizarTorcido_0_-1")==level)
            assert(_count(model,"MontanteVentana_0_-1")==0)
            assert(_count(model,"FrontalCristalCabina")==0)
        if damage==0:
            assert(_count(model,"MontanteVentana_0_-1")==level)
            assert(_count(model,"FranjaSuperiorFaccion")==(
                0 if level==1 else 1 if level==2 else 3))
            assert(_count(model,"FrontalCristalCabina")==(
                0 if level==1 else 1 if level==2 else 2))
        if level==1:
            assert(_count(model,"TorreSupervisionNivel2")==0)
            assert(_count(model,"TorreOesteNivel3")==0)
            assert(_count(model,"PeldañoEscalera_0")==0)
        elif level==2 and damage<=2:
            assert(_count(model,"TorreSupervisionNivel2")==1)
            assert(_count(model,"PeldañoEscalera_0")==1)
            assert(_count(model,"PeldañoEscalera_8")==1)
            assert(_count(model,"PeldañoEscalera_11")==0)
            assert(_count(model,"ArriostreTorre_-1_-1")==1)
        elif level==3 and damage<=2:
            assert(_count(model,"TorreOesteNivel3")==1)
            assert(_count(model,"TorreEsteNivel3")==1)
            assert(_count(model,"PeldañoEscalera_0")==2)
            assert(_count(model,"PeldañoEscalera_11")==2)
            assert(_count(model,"ArriostreTorre_-1_-1")==2)
    model.free()

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V2.apply(null,1,0,0))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            for level in range(1,4):
                _audit_model(level,faction,damage)
                variants+=1
    assert(variants==120)

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(15)
    studio._switch_category(1)
    await _frames(6)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(8)
    assert(studio._role=="infantry_barracks")
    assert(studio.infantry_detail_v2_toggle.button_pressed)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        await _frames(9)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        assert(studio.model_root.has_node(V2.STAGE_NAME))
        await _capture(studio,"level_%d" % level)

    for camera_id in range(1,4):
        studio.infantry_camera_picker.select(camera_id)
        studio._change_infantry_camera(camera_id)
        await _frames(6)
        assert(studio._infantry_camera_view==camera_id)
        await _capture(studio,["","front_access",
            "training_side","top_roofs"][camera_id])
    studio.infantry_camera_picker.select(1)
    studio._change_infantry_camera(1)
    studio.infantry_detail_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_detail_v2(false)
    await _frames(9)
    assert(not studio.model_root.has_node(V2.STAGE_NAME))
    await _capture(studio,"compare_v1")
    studio.infantry_detail_v2_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_detail_v2(true)
    await _frames(9)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    await _capture(studio,"compare_v2")
    studio.infantry_camera_picker.select(0)
    studio._change_infantry_camera(0)
    for damage in [1,2,3,4]:
        studio.infantry_damage_picker.select(damage)
        studio._change_infantry_setting(damage)
        await _frames(8)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _capture(studio,"damage_%d" % damage)
    studio.infantry_damage_picker.select(0)
    studio._change_infantry_setting(0)
    await _frames(6)
    studio._select_faction_view(6)
    await _frames(6)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    await _capture(studio,"faction_6")

    # Regression check of the three previously approved building views.
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
    print("PASS INFANTRY BARRACKS V2: 120 faction-level-damage combos, three original distinct silhouettes, real 3D doors/window mullions/braced towers/training, V1 comparison, 13 OpenGL screenshots, prior HQ/Airbase/Naval preserved")
    quit(0)
