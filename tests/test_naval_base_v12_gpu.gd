extends SceneTree

# TARVOKA naval V12 — native Godot 4.3 / OpenGL final visual audit.
# No game rules, ship collisions, shipping economics or Android FPS claims.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const V7=preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const V8=preload("res://scripts/ui/NavalFendersV8.gd")
const V9=preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const V10=preload("res://scripts/ui/NavalMooringAlignmentV10.gd")
const V11=preload("res://scripts/ui/NavalContactFinishV11.gd")
const V12=preload("res://scripts/ui/NavalFinalContactV12.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=8) -> void:
    for _i in range(count):
        await process_frame

func _count(node: Node,label: String) -> int:
    var n: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        n+=_count(child,label)
    return n

func _capture(studio: Control,name: String) -> void:
    await _frames(8)
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null)
    assert(image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png(
        "res://artifacts/tarvoka_naval_v12_"+name+".png")==OK)

func _build(level: int,faction: int,damage: int) -> Node3D:
    var model: Node3D=Base.build(level,faction,damage)
    assert(model!=null)
    assert(V2.apply(model,level,faction,damage))
    assert(V3.apply(model,level,faction,damage))
    assert(V4.apply(model,level,faction,damage))
    assert(V5.apply(model,level,faction,damage))
    assert(V6.apply(model,level,faction,damage))
    assert(V7.apply(model,level,faction,damage))
    assert(V8.apply(model,level,faction,damage))
    assert(V9.apply(model,level,faction,damage))
    assert(V10.apply(model,level,faction,damage))
    assert(V11.apply(model,level,faction,damage))
    assert(V12.apply(model,level,faction,damage))
    return model

func _check_sag(model: Node3D,label: String,
        legacy: String) -> void:
    var chain: MultiMeshInstance3D=model.find_child(
        label,true,false) as MultiMeshInstance3D
    assert(chain!=null)
    assert(chain.multimesh!=null)
    var count: int=chain.multimesh.instance_count
    assert(count>=3 and count<=9)
    assert(chain.multimesh.mesh is ArrayMesh)
    var sag: float=float(chain.get_meta("naval_v12_sag",0))
    assert(sag>0.0 and sag<=0.046)
    var start: Vector3=chain.get_meta("naval_v12_start",Vector3.ZERO)
    var finish: Vector3=chain.get_meta("naval_v12_end",Vector3.ZERO)
    assert(start.distance_to(finish)>0.034)
    assert(V12._curve_point(start,finish,0.0,sag).distance_to(start)<0.0001)
    assert(V12._curve_point(start,finish,1.0,sag).distance_to(finish)<0.0001)
    var mid: Vector3=V12._curve_point(start,finish,0.5,sag)
    assert(mid.y<=(start.y+finish.y)*0.5)
    for k in range(count):
        var transform: Transform3D=chain.multimesh.get_instance_transform(k)
        assert(transform.origin.y>=V12.MIN_CHAIN_Y)
        assert(transform.origin.distance_to(start)<1.5)
    var old:=model.find_child(legacy,true,false) as MultiMeshInstance3D
    assert(old!=null and not old.visible)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V12.apply(null,2,0,0))
    assert(not V12.set_detail(null,true))
    assert(not V12.set_night(null,true))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            var early: Node3D=Base.build(2,faction,damage)
            assert(not V12.apply(early,2,faction,damage))
            early.free()
            var model: Node3D=_build(2,faction,damage)
            assert(not V12.apply(model,2,faction,damage))
            var stage: Node3D=model.get_node(V12.STAGE_NAME)
            assert(int(stage.get_meta("naval_v12_faction",-1))==faction)
            assert(int(stage.get_meta("naval_v12_damage",-1))==damage)
            assert(int(stage.get_meta("naval_v12_level",-1))==2)
            assert(bool(stage.get_meta("naval_v12_preserves_original_moorings",false)))
            assert(bool(stage.get_meta("naval_v12_east_assembly_verified",false)))
            assert(bool(stage.get_meta("naval_v12_pier_assembly_verified",false)))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            var near: Node3D=stage.get_node("AcabadosCercanosV12")
            var far: Node3D=stage.get_node("AcabadosTacticosV12")
            assert(near.visible and not far.visible)
            assert(V12.set_detail(model,false))
            assert(not near.visible and far.visible)
            assert(V12.set_detail(model,true))
            assert(near.visible and not far.visible)
            assert(V12.set_night(model,true))
            assert(bool(stage.get_meta("naval_v12_night",false)))
            assert(V12.set_night(model,false))
            if damage<=1:
                assert(_count(model,"BordeCompresionEsteV12_00")==1)
                assert(_count(model,"PerfilCompresionEspigonV12_-1_0")==1)
                assert(_count(model,"PerfilCompresionEspigonV12_1_2")==1)
                assert(_count(model,"GuardacabosCadenaEsteV12_0")==1)
                assert(_count(model,"GuardacabosEspigonV12_-1_0")==1)
                assert(_count(model,"IndicadorFaccionDiscretoEsteV12_00")==1)
                assert(_count(model,"Bolardo_-1_0")==1)
                assert(_count(model,"ArgollaAmarre_0")==1)
                _check_sag(model,"CurvaCadenaEste_A_0","EslabonesCadenaEste_A_0")
                _check_sag(model,"CurvaCadenaEste_B_0","EslabonesCadenaEste_B_0")
                _check_sag(model,"CurvaCadenaEspigon_A_-1_0",
                    "EslabonesCadenaEspigon_A_-1_0")
                _check_sag(model,"CurvaCadenaEspigon_B_-1_0",
                    "EslabonesCadenaEspigon_B_-1_0")
            if damage==2:
                assert(_count(model,"BordeCompresionEsteV12_00")==1)
                assert(_count(model,"BordeCompresionEsteV12_02")==0)
                assert(_count(model,"PerfilCompresionEspigonV12_-1_1")==0)
                assert(_count(model,"IndicadorFaccionDiscretoEsteV12_00")==0)
                _check_sag(model,"CurvaCadenaEste_A_0","EslabonesCadenaEste_A_0")
                assert(_count(model,"CurvaCadenaEste_A_1")==0)
            if damage==3:
                assert(_count(model,"BordeCompresionEsteV12_00")==0)
                assert(_count(model,"CantoRotoMuelleEsteV12_00")==1)
                assert(_count(model,"UnionEspigonDesgarradaV12_-1_0")==1)
                assert(_count(model,"UnionEspigonDesgarradaV12_1_0")==0)
                assert(_count(model,"CurvaCadenaEste_A_0")==0)
                assert(_count(model,"CurvaCadenaEspigon_A_-1_0")==0)
                assert(_count(model,"CoronacionEspigon_1")==0)
            if damage==4:
                assert(_count(model,"RestoJuntaMaritimaV12")==1)
                assert(_count(model,"PlacaSeparadaDeEspigonV12")==1)
                assert(_count(model,"BordeCompresionEsteV12_00")==0)
                assert(_count(model,"CurvaCadenaEspigon_A_-1_0")==0)
                assert(_count(model,"ParedPosteriorHangar")==0)
            model.free()
            variants+=1
    assert(variants==40)
    for level in range(1,4):
        var model: Node3D=_build(level,6,0)
        assert(_count(model,"BordeCompresionEsteV12_00")==1)
        assert(_count(model,"PerfilCompresionEspigonV12_-1_0")==1)
        assert(_count(model,"TraviesaPuenteGruaAstillero")==(
            1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(6)
    studio._change_selected_building(2)
    await _frames(9)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v11_toggle.button_pressed)
    assert(studio.naval_detail_v12_toggle.button_pressed)
    assert(studio.model_root.has_node(V12.STAGE_NAME))
    assert(studio.naval_camera_picker.item_count==8)
    await _capture(studio,"overview")
    studio.naval_camera_picker.select(7)
    studio._change_naval_camera(7)
    await _frames(8)
    assert(studio._naval_camera_view==7)
    await _capture(studio,"low_seaward")
    studio.naval_camera_picker.select(6)
    studio._change_naval_camera(6)
    studio._zoom=1.45
    studio._update_camera()
    await _frames(8)
    assert(studio.camera.size<5.0)
    await _capture(studio,"chain_sag_close")
    studio.naval_camera_picker.select(5)
    studio._change_naval_camera(5)
    await _frames(8)
    await _capture(studio,"pier_contact")
    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio._zoom=0.62
    studio._update_camera()
    await _frames(7)
    assert(not bool(studio.model_root.get_node(V12.STAGE_NAME)
        .get_meta("naval_v12_near",true)))
    await _capture(studio,"tactical_far")
    studio._zoom=1.0
    studio._update_camera()
    studio.naval_night_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_night_v6(true)
    await _frames(7)
    assert(bool(studio.model_root.get_node(V12.STAGE_NAME)
        .get_meta("naval_v12_night",false)))
    await _capture(studio,"night_coast")
    studio.naval_night_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_night_v6(false)

    studio.naval_detail_v12_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v12(false)
    await _frames(8)
    assert(studio.model_root.has_node(V11.STAGE_NAME))
    assert(not studio.model_root.has_node(V12.STAGE_NAME))
    await _capture(studio,"compare_v11")
    studio.naval_detail_v12_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v12(true)
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(studio.model_root.has_node(V12.STAGE_NAME))
    assert(_count(studio.model_root,"UnionEspigonDesgarradaV12_1_0")==0)
    await _capture(studio,"critical_ruins")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V12: 40 faction/damage variants, 3 levels, sagged MultiMesh mooring chains and material-contact 360 audit, 8 studio cameras, night/zoom, V11 comparison and 8 actual Godot renders")
    quit(0)
