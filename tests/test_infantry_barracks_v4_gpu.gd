extends SceneTree

# Native Godot 4.3 / OpenGL acceptance for Infantry Barracks V3.
# Real procedural textures and geometry; never screenshot mockup art.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V4=preload("res://scripts/ui/InfantryBarracksRearFacadeV4.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const SHOTS=["level_1","level_2","level_3","front_access",
    "training_side","rooftop","rear_view","compare_v2","compare_v3",
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
    await _frames(9)
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>=640 and img.get_height()>=400)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png("res://artifacts/tarvoka_infantry_v4_"+name+".png")==OK)

func _audit(level: int,faction: int,damage: int) -> void:
    var model: Node3D=V1.build(level,faction,damage)
    assert(model!=null)
    assert(V2.apply(model,level,faction,damage))
    assert(not V3.apply(model,level,faction,4 if damage!=4 else 0))
    var mcount: int=V1.mesh_count(model)
    assert(V3.apply(model,level,faction,damage))
    assert(not V3.apply(model,level,faction,damage))
    var finish: Node3D=model.get_node(V3.STAGE_NAME) as Node3D
    assert(finish!=null)
    assert(bool(finish.get_meta("visual_only",false)))
    assert(bool(finish.get_meta("preserves_infantry_three_masses",false)))
    assert(int(finish.get_meta("tier",-1))==level)
    assert(int(finish.get_meta("damage",-1))==damage)
    var counted: Dictionary=finish.get_meta("surface_counts",{})
    assert(int(counted.get("faction_preserved",0))>=1 if damage<4 else int(counted.get("faction_preserved",0))==0)
    assert(int(counted.get("concrete",0))>=1 if damage<4 else int(counted.get("rubble",0))>=1)
    assert(V1.mesh_count(model)>=mcount)
    var before_v4: int=V1.mesh_count(model)
    assert(V4.apply(model,level,faction,damage))
    assert(not V4.apply(model,level,faction,damage))
    var rear: Node3D=model.get_node(V4.STAGE_NAME) as Node3D
    assert(rear!=null)
    assert(int(rear.get_meta("facade_version",-1))==4)
    assert(bool(rear.get_meta("visual_only",false)))
    if damage==4:
        assert(V1.mesh_count(rear)==0)
        assert(V1.mesh_count(model)==before_v4)
    elif damage>=3:
        assert(_count(rear,"PanelRegistroTecnico")==0)
        assert(_count(rear,"PerfilPosteriorQuebrado")==level)
    else:
        assert(_count(rear,"PanelRegistroTecnico")==level)
        assert(_count(rear,"BajantePosterior")==level)
        var expected_rear_windows: int=0
        for module in V2._modules(level):
            if float(module["w"])<4.0:
                continue
            var floors: int=int(module["floors"])
            var h: float=float(module["h"])
            for floor in range(floors):
                if 1.45+float(floor)*2.22+0.44<h-0.27:
                    expected_rear_windows+=2
        var actual_rear_windows: int=0
        for floor in range(3):
            for side in [-1,1]:
                actual_rear_windows+=_count(rear,
                    "CristalVentanaPosterior_%d_%d" % [floor,side])
        assert(actual_rear_windows==expected_rear_windows)
        if level==3:
            assert(_count(rear,"CristalVentanaLateral_0_0")==1)
        else:
            assert(_count(rear,"CristalVentanaLateral_0_0")==0)
    if damage<=2:
        var expected_roofs: int=(
            4 if damage==0 else 3 if damage==1 else 2)
        assert(_count(model,"CostillaPanel_0_0")==
            (level if damage==0 or damage==1 else 0))
        assert(_count(model,"CostillaPanel_1_0")==
            (level if damage in [0,2] else 0))
        assert(_count(model,"CostillaPanel_3_0")==level)
        assert(_count(model,"GoteronPosterior")==
            (level if damage<=1 else 0))
        var rib_count: int=0
        for i in range(4):
            rib_count+=_count(model,"CostillaPanel_%d_0" % i)
        assert(rib_count==level*expected_roofs)
        assert(_count(model,"ZocaloPosterior_"+
            str(V2._modules(level)[0]["tag"]))==1)
    else:
        assert(_count(model,"CostillaPanel_3_0")==0)
        assert(_count(model,"GoteronPosterior")==0)
    if damage==0:
        assert(_count(model,"RejillaVentilacion")==
            (0 if level==1 else 2 if level==2 else 6))
        assert(_count(model,"HuellaDesgasteV3_00")==0)
    if damage==2:
        assert(_count(model,"HuellaDesgasteV3_00")==1)
    if damage==3:
        assert(_count(model,"HuellaDesgasteV3_04")==1)
    if damage==4:
        assert(V1.mesh_count(finish)==0)
        assert(_count(model,"FragmentoRuina_00")==1)
        assert(_count(model,"CristalVentana_0_-1")==0)
        assert(_count(model,"PuertaAcceso")==0)
        assert(_count(model,"RejillaVentilacion")==0)
    # The official faction banner must be exactly the original colour
    # and must NOT receive the procedural greyscale texture.
    if damage<=1:
        var banner: MeshInstance3D=model.find_child(
            "BanderaTARVOKA",true,false) as MeshInstance3D
        assert(banner!=null)
        var paint: StandardMaterial3D=banner.material_override as StandardMaterial3D
        assert(paint.albedo_color.is_equal_approx(Style.faction_color(faction)))
        assert(paint.albedo_texture==null)
    # Check real textures are installed on building surfaces.
    if damage<=2:
        var wall: MeshInstance3D=model.find_child(
            "ParedPosterior_"+str(V2._modules(level)[0]["tag"]),
            true,false) as MeshInstance3D
        assert(wall!=null)
        var mat: StandardMaterial3D=wall.material_override as StandardMaterial3D
        assert(mat.albedo_texture!=null)
        assert(mat.roughness>=0.75)
    model.free()

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(V3.SURFACES.size()==7)
    assert(not V3.apply(null,1,0,0))
    var cases: int=0
    for faction in range(8):
        for damage in range(5):
            for level in range(1,4):
                _audit(level,faction,damage)
                cases+=1
    assert(cases==120)
    assert(V3.texture_count()>=5)
    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(18)
    studio._switch_category(1)
    await _frames(5)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(8)
    assert(studio._role=="infantry_barracks")
    assert(studio.infantry_detail_v2_toggle.button_pressed)
    assert(studio.infantry_material_v3_toggle.button_pressed)
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        await _frames(8)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        assert(studio.model_root.has_node(V3.STAGE_NAME))
        assert(studio.model_root.has_node(V4.STAGE_NAME))
        await _capture(studio,"level_%d" % level)
    for i in range(1,4):
        studio.infantry_camera_picker.select(i)
        studio._change_infantry_camera(i)
        await _frames(6)
        await _capture(studio,["","front_access",
            "training_side","rooftop"][i])
    studio.infantry_camera_picker.select(0)
    studio._change_infantry_camera(0)
    # Rotate ONLY the 3D model, keep the inspection camera fixed.
    # Rotating model AND camera together would incorrectly photograph
    # the identical FRONT elevation rather than the real rear geometry.
    var original_yaw: float=studio._yaw
    var camera_before: Vector3=studio.camera.position
    studio.model_root.rotation_degrees.y=fposmod(original_yaw+180.0,360.0)
    await _frames(7)
    assert(studio.camera.position.is_equal_approx(camera_before))
    await _capture(studio,"rear_view")
    await _capture(studio,"v4_rear_details")
    studio.model_root.rotation_degrees.y=original_yaw
    studio.infantry_camera_picker.select(1)
    studio._change_infantry_camera(1)
    studio.infantry_rear_v4_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_rear_v4(false)
    await _frames(6)
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    await _capture(studio,"compare_v3_without_v4")
    studio.infantry_rear_v4_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_rear_v4(true)
    await _frames(6)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    studio.infantry_material_v3_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_material_v3(false)
    await _frames(8)
    assert(not studio.model_root.has_node(V3.STAGE_NAME))
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    await _capture(studio,"compare_v2")
    studio.infantry_material_v3_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_material_v3(true)
    await _frames(8)
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    await _capture(studio,"compare_v3")
    studio.infantry_camera_picker.select(0)
    studio._change_infantry_camera(0)
    for damage in [1,2,3,4]:
        studio.infantry_damage_picker.select(damage)
        studio._change_infantry_setting(damage)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _capture(studio,"damage_%d" % damage)
    studio.infantry_damage_picker.select(0)
    studio._change_infantry_setting(0)
    await _frames(6)
    studio._select_faction_view(6)
    await _frames(6)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    await _capture(studio,"faction_6")
    studio.infantry_detail_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_detail_v2(false)
    await _frames(6)
    assert(studio.infantry_material_v3_toggle.disabled)
    assert(studio.infantry_rear_v4_toggle.disabled)
    assert(not studio.model_root.has_node(V2.STAGE_NAME))
    assert(not studio.model_root.has_node(V3.STAGE_NAME))
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    studio.infantry_detail_v2_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_detail_v2(true)
    await _frames(6)
    assert(not studio.infantry_material_v3_toggle.disabled)
    assert(not studio.infantry_rear_v4_toggle.disabled)
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    # Previous three art-studio building modes must remain available.
    studio._change_selected_building(2)
    await _frames(4)
    assert(studio._role=="naval_base")
    studio._change_selected_building(1)
    await _frames(4)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(4)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS INFANTRY BARRACKS V4: 120 Godot 4.3 variants, 7 native procedural surface classes, faction paint preserved, three masses and five damage stages, reversible V1/V2/V3 and 16 real OpenGL screenshots, previous HQ/Airbase/Naval safe")
    quit(0)
