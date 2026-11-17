extends SceneTree

# Native Godot 4.3 3D QA for the SINGLE existing TARVOKA art studio.
# The model is Godot MeshInstance3D, not an image or separate web viewer.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V4=preload("res://scripts/ui/InfantryBarracksRearFacadeV4.gd")
const V5=preload("res://scripts/ui/InfantryBarracksEntranceYardV5.gd")
const V6=preload("res://scripts/ui/InfantryBarracksRoofCommandV6.gd")
const V7=preload("res://scripts/ui/InfantryBarracksSideTowersV7.gd")
const V8=preload("res://scripts/ui/InfantryBarracksTowerFinishV8.gd")
const V9=preload("res://scripts/ui/InfantryBarracksFinalAccessV9.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const PREFIX="res://artifacts/tarvoka_infantry_v9_"

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=8) -> void:
    for _i in range(count):
        await process_frame

func _count_name(parent: Node,needle: String) -> int:
    var count: int=1 if str(parent.name)==needle else 0
    for child in parent.get_children():
        count+=_count_name(child,needle)
    return count

func _build(level: int,faction: int,damage: int) -> Node3D:
    var model: Node3D=V1.build(level,faction,damage)
    assert(model!=null)
    assert(V2.apply(model,level,faction,damage))
    assert(V3.apply(model,level,faction,damage))
    assert(V4.apply(model,level,faction,damage))
    assert(V5.apply(model,level,faction,damage))
    assert(V6.apply(model,level,faction,damage))
    assert(V7.apply(model,level,faction,damage))
    assert(V8.apply(model,level,faction,damage))
    return model

func _audit(level: int,faction: int,damage: int) -> void:
    var model: Node3D=_build(level,faction,damage)
    var before: int=V1.mesh_count(model)
    assert(not V9.apply(null,level,faction,damage))
    assert(not V9.apply(model,level,faction,(damage+1)%5))
    assert(V9.apply(model,level,faction,damage))
    assert(not V9.apply(model,level,faction,damage))
    var stage: Node3D=model.get_node(V9.STAGE_NAME) as Node3D
    assert(stage!=null)
    assert(int(stage.get_meta("detail_version",0))==9)
    assert(int(stage.get_meta("tier",0))==level)
    assert(int(stage.get_meta("damage",-1))==damage)
    assert(bool(stage.get_meta("visual_only",false)))
    assert(bool(stage.get_meta("no_gameplay_changes",false)))
    if damage==4:
        assert(V1.mesh_count(stage)==0)
        assert(V1.mesh_count(model)==before)
    elif damage==3:
        assert(_count_name(stage,"CristalMirillaAccesoV9")==0)
        assert(_count_name(stage,"RestosMarcoEntradaV9_"+
            str(V2._modules(level)[0]["tag"]))==1)
        assert(_count_name(stage,"BandaAntideslizanteAltaV9")==0)
        assert(V1.mesh_count(stage)==level)
    elif damage==2:
        assert(_count_name(stage,"BisagraDanadaV9")==level)
        assert(_count_name(stage,"CristalMirillaAccesoV9")==0)
        assert(_count_name(stage,"GoteronSuperiorVentanaV9_"+
            str(V2._modules(level)[0]["tag"])+"_0")==0)
    else:
        assert(_count_name(stage,"JuntaCentralPuertaV9")==level)
        assert(_count_name(stage,"CristalMirillaAccesoV9")==level)
        assert(_count_name(stage,"BandaAntideslizanteBajaV9")==level)
        assert(_count_name(stage,"BandaAntideslizanteAltaV9")==level)
        assert(_count_name(stage,"MarcaAccesoFaccionV9")==
            (level if damage==0 else 0))
        assert(_count_name(stage,"RasponAccesoV9")==
            (level if damage==1 else 0))
        assert(int(stage.get_meta("pbr_meshes",0))>0)
        var expected_drip: int=4 if level==1 else 6 if level==2 else 8
        var caps: int=0
        for child in stage.get_children():
            if str(child.name).begins_with("GoteronSuperiorVentanaV9_"):
                caps+=1
        assert(caps==expected_drip)
        var pane: MeshInstance3D=model.find_child(
            "CristalMirillaAccesoV9",true,false) as MeshInstance3D
        assert(pane!=null)
        var mat: StandardMaterial3D=pane.material_override as StandardMaterial3D
        assert(mat.albedo_texture!=null)
        var step: MeshInstance3D=model.find_child(
            "BandaAntideslizanteAltaV9",true,false) as MeshInstance3D
        assert(step!=null and step.position.y>=0.245)
        assert(step.position.z<0.8)
        if damage==0:
            var code: MeshInstance3D=model.find_child(
                "MarcaAccesoFaccionV9",true,false) as MeshInstance3D
            assert(code!=null)
            var faction_mat: StandardMaterial3D=code.material_override as StandardMaterial3D
            assert(faction_mat.albedo_color.is_equal_approx(
                Style.faction_color(faction)))
            assert(faction_mat.albedo_texture==null)
        assert(V1.mesh_count(model)>before)
    model.free()

func _capture(studio: Control,label: String) -> void:
    await _frames(9)
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>=640 and image.get_height()>=400)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png(PREFIX+label+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    var cases: int=0
    for faction in range(8):
        for damage in range(5):
            for level in range(1,4):
                _audit(level,faction,damage)
                cases+=1
    assert(cases==120)
    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(18)
    studio._switch_category(1)
    await _frames(4)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(7)
    assert(studio._role=="infantry_barracks")
    assert(studio.infantry_access_v9_toggle.button_pressed)
    assert(studio.model_root.has_node(V9.STAGE_NAME))
    assert(studio.infantry_camera_picker.item_count==7)
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        await _frames(7)
        assert(studio.model_root.has_node(V9.STAGE_NAME))
        assert(int(studio.model_root.get_meta("visual_level",0))==level)
        await _capture(studio,"level_%d" % level)
    studio.infantry_camera_picker.select(6)
    studio._change_infantry_camera(6)
    await _capture(studio,"door_close")
    studio.infantry_camera_picker.select(5)
    studio._change_infantry_camera(5)
    await _capture(studio,"tower_n3")
    studio.infantry_camera_picker.select(4)
    studio._change_infantry_camera(4)
    await _capture(studio,"courtyard_n3")
    studio.infantry_camera_picker.select(6)
    studio._change_infantry_camera(6)
    var original_eye: Vector3=studio.camera.position
    studio.infantry_access_v9_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_access_v9(false)
    await _frames(7)
    assert(not studio.model_root.has_node(V9.STAGE_NAME))
    assert(studio.model_root.has_node(V8.STAGE_NAME))
    studio.camera.position=original_eye
    studio.camera.look_at(Vector3(0,1.16,0.88),Vector3.UP)
    await _capture(studio,"compare_v8_no_v9")
    studio.infantry_access_v9_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_access_v9(true)
    await _frames(7)
    assert(studio.model_root.has_node(V9.STAGE_NAME))
    studio.camera.position=original_eye
    studio.camera.look_at(Vector3(0,1.16,0.88),Vector3.UP)
    await _capture(studio,"compare_v9_detail")
    for damage in [1,2,3,4]:
        studio.infantry_damage_picker.select(damage)
        studio._change_infantry_setting(damage)
        await _frames(6)
        assert(studio.model_root.has_node(V9.STAGE_NAME))
        await _capture(studio,"damage_%d" % damage)
    studio.infantry_damage_picker.select(0)
    studio._change_infantry_setting(0)
    await _frames(6)
    studio._select_faction_view(7)
    await _frames(5)
    await _capture(studio,"faction_7")
    studio.infantry_tower_v8_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_tower_v8(false)
    await _frames(5)
    assert(not studio.model_root.has_node(V9.STAGE_NAME))
    assert(not studio.model_root.has_node(V8.STAGE_NAME))
    assert(studio.model_root.has_node(V7.STAGE_NAME))
    assert(studio.infantry_access_v9_toggle.disabled)
    studio.infantry_tower_v8_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_tower_v8(true)
    await _frames(5)
    assert(studio.model_root.has_node(V8.STAGE_NAME))
    assert(studio.model_root.has_node(V9.STAGE_NAME))
    for target in [2,1,0]:
        studio._change_selected_building(target)
        await _frames(4)
        assert(studio._role==(
            "naval_base" if target==2 else
            "airbase" if target==1 else "headquarters"))
    studio.queue_free()
    await _frames(3)
    print("PASS INFANTRY BARRACKS V9: 120 native Godot variants, 12 shared-studio comparison captures, three levels, eight factions, five damages, original HQ/Airbase/Naval unchanged")
    quit(0)
