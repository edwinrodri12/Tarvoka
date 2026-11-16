extends SceneTree

# Real Godot 4.3/OpenGL V4 acceptance: 120 combinations, 18 true GPU captures.
# No static illustration can satisfy this test: it inspects actual 3D nodes.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V4=preload("res://scripts/ui/InfantryBarracksFacadeV4.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

const SHOTS=["level_1","level_2","level_3",
    "front","training","roof","rear_1","rear_2","rear_3",
    "side_left","side_right","compare_v3","compare_v4",
    "damage_1","damage_2","damage_3","damage_4","faction_6"]

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _count(parent: Node,target: String) -> int:
    var result: int=1 if str(parent.name)==target else 0
    for child in parent.get_children():
        result+=_count(child,target)
    return result

func _count_prefix(parent: Node,prefix: String) -> int:
    var result: int=1 if str(parent.name).begins_with(prefix) else 0
    for child in parent.get_children():
        result+=_count_prefix(child,prefix)
    return result

func _capture(studio: Control,label: String) -> void:
    await _frames(7)
    var shot: Image=studio.preview.get_texture().get_image()
    assert(shot!=null and shot.get_width()>=640 and shot.get_height()>=400)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(shot.save_png(
        "res://artifacts/tarvoka_infantry_v4_"+label+".png")==OK)

func _audit(level: int,faction: int,damage: int) -> void:
    var model: Node3D=V1.build(level,faction,damage)
    assert(model!=null)
    assert(not V4.apply(model,level,faction,damage))
    assert(V2.apply(model,level,faction,damage))
    assert(not V4.apply(model,level,faction,damage))
    assert(V3.apply(model,level,faction,damage))
    var v3_mesh_count: int=V1.mesh_count(model)
    assert(not V4.apply(model,level,faction,4 if damage!=4 else 0))
    assert(V4.apply(model,level,faction,damage))
    assert(not V4.apply(model,level,faction,damage))
    var stage: Node3D=model.get_node(V4.STAGE_NAME) as Node3D
    assert(stage!=null)
    assert(bool(stage.get_meta("visual_only",false)))
    assert(bool(stage.get_meta("massing_unchanged",false)))
    assert(int(stage.get_meta("facade_version",-1))==4)
    assert(int(stage.get_meta("tier",-1))==level)
    assert(int(stage.get_meta("damage",-1))==damage)
    assert(_count(model,V1.STAGE_NAME)==1)
    assert(_count(model,V2.STAGE_NAME)==1)
    assert(_count(model,V3.STAGE_NAME)==1)
    assert(_count(model,V4.STAGE_NAME)==1)
    assert(_count(model,"CimentacionGeneral")==1)
    assert(_count(model,"PatioFormacion")==1)
    assert(V1.mesh_count(model)>=v3_mesh_count)
    if damage==4:
        assert(V4.mesh_count(model)==0)
        assert(bool(stage.get_meta("ruins_only",false)))
        assert(_count_prefix(model,"FachadaTraseraAbierta_")==0)
        assert(_count_prefix(model,"CristalTrasero_")==0)
        assert(_count_prefix(model,"FachadaLateralAbierta_")==0)
        assert(_count(model,"FragmentoRuina_00")==1)
    elif damage==3:
        assert(V4.mesh_count(model)==level)
        assert(_count_prefix(model,"FachadaTraseraAbierta_")==0)
        assert(_count_prefix(model,"HuecoVentanaPosterior_")==0)
        assert(_count_prefix(model,"CristalTrasero_")==0)
        assert(_count_prefix(model,"MarcaDerrumbePosterior_")==level)
        assert(_count_prefix(model,"GoteronPosterior")==0)
        for module in V2._modules(level):
            var rear: MeshInstance3D=model.find_child(
                "ParedPosterior_"+str(module["tag"]),true,false) as MeshInstance3D
            assert(rear!=null and rear.visible)
    else:
        assert(int(stage.get_meta("rear_open_facades",-1))==level)
        assert(int(stage.get_meta("outer_side_facades",-1))==2)
        assert(_count_prefix(model,"FachadaTraseraAbierta_")==level)
        assert(_count_prefix(model,"FachadaLateralAbierta_")==2)
        assert(_count_prefix(model,"HuecoVentanaPosterior_")>=level)
        assert(_count_prefix(model,"HuecoVentanaLateral_")>=2)
        assert(_count_prefix(model,"SenalizacionEntrenamientoV4")==(1 if damage<=1 else 0))
        for module in V2._modules(level):
            var tag: String=str(module["tag"])
            var original: MeshInstance3D=model.find_child(
                "ParedPosterior_"+tag,true,false) as MeshInstance3D
            assert(original!=null and not original.visible)
            var facade: Node3D=model.get_node(
                V4.STAGE_NAME+"/FachadaTraseraAbierta_"+tag) as Node3D
            assert(facade!=null)
            var columns: int=3 if float(module["w"])>6 else 1
            var floor_count: int=int(module["floors"])
            assert(_count_prefix(facade,"HuecoVentanaPosterior_")==
                columns*floor_count)
            assert(_count_prefix(facade,"MuroBaseTrasero_")==floor_count)
            assert(_count_prefix(facade,"DintelContinuoTrasero_")==floor_count)
            if damage==0:
                assert(_count_prefix(facade,"CristalTrasero_")==
                    columns*floor_count)
                assert(_count_prefix(facade,"PlacaUnidadPosterior_")==1)
                assert(_count_prefix(model,
                    "JuntaDilatacionCubierta_3")>=1)
            if damage==1:
                assert(_count_prefix(facade,"CristalTrasero_")==
                    columns*floor_count-1)
                assert(_count_prefix(facade,"CristalRotoEsquinaTrasera")==1)
                assert(_count_prefix(model,
                    "JuntaDilatacionCubierta_1")==0)
            if damage==2:
                var expected_panes: int=0
                for floor in range(floor_count):
                    for column in range(columns):
                        if (floor+column)%2==1:
                            expected_panes+=1
                assert(_count_prefix(facade,"CristalTrasero_")==expected_panes)
                assert(_count_prefix(model,
                    "JuntaDilatacionCubierta_3")==0)
        var exposed: Dictionary=V4._exterior_sides(level)
        for module in V2._modules(level):
            var tag: String=str(module["tag"])
            for side in exposed.get(tag,[]):
                var original_name: String=(
                    "ParedIzquierda_" if int(side)==-1 else
                    "ParedDerecha_")+tag
                var wall: MeshInstance3D=model.find_child(
                    original_name,true,false) as MeshInstance3D
                assert(wall!=null and not wall.visible)
                var face: Node3D=model.get_node(
                    V4.STAGE_NAME+"/FachadaLateralAbierta_"+
                    tag+"_"+str(side)) as Node3D
                assert(face!=null)
                assert(_count_prefix(face,"HuecoVentanaLateral_")==
                    int(face.get_meta("actual_openings",-1)))
        # Guarantee interior junction walls are unchanged; neither L
        # nor U receives windows between interconnected modules.
        if level==2:
            var join: MeshInstance3D=model.find_child(
                "ParedDerecha_BarracaPrincipalDosPisosN2",
                true,false) as MeshInstance3D
            assert(join!=null and join.visible)
        if level==3:
            var join: MeshInstance3D=model.find_child(
                "ParedDerecha_AlaOesteDosPisosN3",
                true,false) as MeshInstance3D
            assert(join!=null and join.visible)
        # Real apertures have physically ABSENT original solid wall.
        if damage==0:
            var glass: MeshInstance3D=model.find_child(
                "CristalTrasero_0_0",true,false) as MeshInstance3D
            assert(glass!=null)
            var mat: StandardMaterial3D=glass.material_override as StandardMaterial3D
            assert(mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA)
            assert(mat.albedo_color.a<0.75)
    model.free()

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V4.apply(null,1,0,0))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            for level in range(1,4):
                _audit(level,faction,damage)
                variants+=1
    assert(variants==120)
    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(5)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(8)
    assert(studio._role=="infantry_barracks")
    assert(studio.infantry_facade_v4_toggle.button_pressed)
    assert(studio.infantry_camera_picker.item_count==7)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        await _frames(6)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        await _capture(studio,"level_%d" % level)
    for view in [1,2,3]:
        studio.infantry_camera_picker.select(view)
        studio._change_infantry_camera(view)
        await _frames(5)
        await _capture(studio,["","front","training","roof"][view])
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        studio.infantry_camera_picker.select(4)
        studio._change_infantry_camera(4)
        await _frames(6)
        assert(studio._infantry_camera_view==4)
        # The REAR inspection camera must sit on model's actual +Z side.
        var local: Vector3=Basis(Vector3.UP,deg_to_rad(-studio._yaw))*studio.camera.position
        assert(local.z>8.0)
        await _capture(studio,"rear_%d" % level)
    for side in [5,6]:
        studio.infantry_camera_picker.select(side)
        studio._change_infantry_camera(side)
        await _frames(6)
        var relative: Vector3=Basis(Vector3.UP,deg_to_rad(-studio._yaw))*studio.camera.position
        assert(relative.x< -8.0 if side==5 else relative.x>8.0)
        await _capture(studio,"side_left" if side==5 else "side_right")
    studio.infantry_camera_picker.select(4)
    studio._change_infantry_camera(4)
    studio.infantry_facade_v4_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_facade_v4(false)
    await _frames(6)
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    var wall: MeshInstance3D=studio.model_root.find_child(
        "ParedPosterior_ComandoCentralTresPisosN3",
        true,false) as MeshInstance3D
    assert(wall!=null and wall.visible)
    await _capture(studio,"compare_v3")
    studio.infantry_facade_v4_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_facade_v4(true)
    await _frames(7)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    wall=studio.model_root.find_child(
        "ParedPosterior_ComandoCentralTresPisosN3",
        true,false) as MeshInstance3D
    assert(wall!=null and not wall.visible)
    await _capture(studio,"compare_v4")
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
    await _frames(5)
    studio._select_faction_view(6)
    await _frames(5)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    await _capture(studio,"faction_6")
    studio.infantry_material_v3_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_material_v3(false)
    await _frames(4)
    assert(studio.infantry_facade_v4_toggle.disabled)
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    studio.infantry_material_v3_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_material_v3(true)
    await _frames(4)
    assert(not studio.infantry_facade_v4_toggle.disabled)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
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
    print("PASS INFANTRY BARRACKS V4: 120 native Godot variants, real rear/outer side wall apertures, no junction openings, N1/N2/N3 unchanged, 7 inspection cameras, 18 authentic GPU screenshots, V3 comparison, HQ/Airbase/Naval intact")
    quit(0)
