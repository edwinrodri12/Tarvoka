extends SceneTree

# TARVOKA Naval Base V13: real Godot 4.3 / OpenGL 360-degree audit.
# All 8 cameras, rotated-faction world framing, 40 visual variants, 12
# native screenshots. Does NOT validate Android physics or FPS.
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
const V13=preload("res://scripts/ui/NavalInspectionV13.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const CAMERA_NAMES=["overview","seaward","rear","top","boarding",
    "bollards","east_contact","low_waterline"]
const CLOSE_CAMERA_LOCAL_TARGETS=[
    Vector3(1.06,0.40,1.36),
    Vector3(-3.27,0.40,-4.22),
    Vector3(1.06,0.34,-2.72),
    Vector3(-3.27,0.28,-4.19)]

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var amount: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        amount+=_count(child,label)
    return amount

func _capture(studio: Control,name: String) -> void:
    await _frames(8)
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png(
        "res://artifacts/tarvoka_naval_v13_"+name+".png")==OK)

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
    assert(V13.apply(model,level,faction,damage))
    return model

func _audit_view(studio: Control,index: int) -> void:
    # Camera focus must track world rotation, not use the old unrotated
    # coordinates that made V12 close-ups show mostly the warehouse.
    studio.naval_camera_picker.select(index)
    studio._change_naval_camera(index)
    assert(studio._naval_camera_view==index)
    if index<4:
        return
    var target: Vector3=CLOSE_CAMERA_LOCAL_TARGETS[index-4]
    for yaw in [26.0,71.0]:
        studio._yaw=yaw
        studio.model_root.rotation_degrees.y=yaw
        studio._apply_naval_camera()
        await _frames(4)
        var point: Vector3=studio.model_root.to_global(target)
        assert(not studio.camera.is_position_behind(point))
        var screen: Vector2=studio.camera.unproject_position(point)
        var half: Vector2=Vector2(studio.preview.size)*0.5
        assert(absf(screen.x-half.x)<half.x*0.21)
        assert(absf(screen.y-half.y)<half.y*0.21)
    studio._yaw=26.0
    studio.model_root.rotation_degrees.y=26.0
    studio._apply_naval_camera()

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V13.apply(null,2,0,0))
    var base_mesh: ArrayMesh=V11._chain_link_mesh()
    var thick_mesh: ArrayMesh=V13._legible_chain_mesh()
    assert(thick_mesh!=base_mesh)
    var orig: PackedVector3Array=base_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    var updated: PackedVector3Array=thick_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    assert(orig.size()==updated.size() and orig.size()>100)
    assert(absf((updated[0]-orig[0]).length()-V13.TUBE_CORRECTION)<0.0005)
    var tested: int=0
    for faction in range(8):
        for damage in range(5):
            var early: Node3D=Base.build(2,faction,damage)
            assert(not V13.apply(early,2,faction,damage))
            early.free()
            var model: Node3D=_build(2,faction,damage)
            assert(not V13.apply(model,2,faction,damage))
            var stage: Node3D=model.get_node(V13.STAGE_NAME)
            assert(int(stage.get_meta("naval_v13_faction",-1))==faction)
            assert(int(stage.get_meta("naval_v13_damage",-1))==damage)
            assert(bool(stage.get_meta("naval_v13_preserves_anchor_coordinates",false)))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            var chains: int=int(stage.get_meta("naval_v13_improved_chains",-1))
            if damage<=1:
                assert(chains==20)
            elif damage==2:
                assert(chains==14)
            else:
                assert(chains==0)
            if damage<=2:
                var chain: MultiMeshInstance3D=model.find_child(
                    "CurvaCadenaEste_A_0",true,false) as MultiMeshInstance3D
                assert(chain!=null and chain.multimesh.mesh==thick_mesh)
                var m:=chain.material_override as StandardMaterial3D
                assert(m!=null)
                assert(is_equal_approx(m.metallic,V13.METALLIC))
                assert(m.roughness>=V13.ROUGHNESS_INTACT)
                assert(chain.get_meta("naval_v12_start") is Vector3)
                assert(chain.get_meta("naval_v12_end") is Vector3)
                var original_rod: Node3D=model.find_child(
                    "EslabonesCadenaEste_A_0",true,false) as Node3D
                assert(original_rod!=null and not original_rod.visible)
            if damage>=3:
                assert(_count(model,"CurvaCadenaEste_A_0")==0)
                assert(_count(model,"CurvaCadenaEspigon_A_-1_0")==0)
            if damage==3:
                assert(_count(model,"CoronacionEspigon_1")==0)
            if damage==4:
                assert(_count(model,"ParedPosteriorHangar")==0)
                assert(_count(model,"PlacaSeparadaDeEspigonV12")==1)
            model.free()
            tested+=1
    assert(tested==40)
    for level in range(1,4):
        var model: Node3D=_build(level,6,0)
        assert(int(model.get_node(V13.STAGE_NAME)
            .get_meta("naval_v13_level",0))==level)
        assert(_count(model,"TraviesaPuenteGruaAstillero")==(
            1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(2)
    await _frames(10)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v12_toggle.button_pressed)
    assert(studio.naval_detail_v13_toggle.button_pressed)
    assert(studio.model_root.has_node(V13.STAGE_NAME))
    assert(studio.naval_camera_picker.item_count==8)
    for i in range(8):
        await _audit_view(studio,i)
        studio._zoom=1.45 if i>=4 else 1.0
        studio._update_camera()
        await _frames(7)
        await _capture(studio,CAMERA_NAMES[i])
    studio.naval_camera_picker.select(6)
    studio._change_naval_camera(6)
    studio._zoom=1.45
    studio._update_camera()
    await _frames(7)
    assert(studio.model_root.has_node(V13.STAGE_NAME))
    studio.naval_detail_v13_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v13(false)
    await _frames(9)
    assert(studio.model_root.has_node(V12.STAGE_NAME))
    assert(not studio.model_root.has_node(V13.STAGE_NAME))
    await _capture(studio,"compare_v12")
    studio.naval_detail_v13_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v13(true)
    await _frames(8)
    assert(studio.model_root.has_node(V13.STAGE_NAME))
    studio.naval_damage_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(8)
    assert(int(studio.model_root.get_node(V13.STAGE_NAME)
        .get_meta("naval_v13_improved_chains",-1))==14)
    await _capture(studio,"medium_damage")
    studio.naval_damage_picker.select(4)
    studio._change_naval_setting(4)
    await _frames(8)
    assert(int(studio.model_root.get_node(V13.STAGE_NAME)
        .get_meta("naval_v13_improved_chains",-1))==0)
    await _capture(studio,"destroyed")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V13: 40 models, 3 tiers, legible PBR chains, eight yaw-corrected real studio cameras, V12 comparison, damage validation, 11 native Godot screenshots")
    quit(0)
