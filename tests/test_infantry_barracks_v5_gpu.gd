extends SceneTree

# TARVOKA V5 Godot 4.3 native 3D geometry acceptance, NOT illustration.
# Covers 8 factions * 3 tiers * 5 damage states, compares real V4/V5 meshes
# and verifies repaired collision-clearance at western/eastern tower, training
# board and east-side maintenance ladder.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V4=preload("res://scripts/ui/InfantryBarracksFacadeV4.gd")
const V5=preload("res://scripts/ui/InfantryBarracksFinishV5.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const SHOTS=["level_1","level_2","level_3",
    "rear_1","rear_2","rear_3",
    "right_2","right_3","left_3","training_3",
    "contact_3","compare_v4","compare_v5",
    "damage_1","damage_2","damage_3","damage_4","faction_6"]

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=7) -> void:
    for _i in range(count):
        await process_frame

func _count(node: Node,label: String) -> int:
    var n: int=1 if str(node.name)==label else 0
    for c in node.get_children():
        n+=_count(c,label)
    return n

func _prefix(node: Node,needle: String) -> int:
    var n: int=1 if str(node.name).begins_with(needle) else 0
    for c in node.get_children():
        n+=_prefix(c,needle)
    return n

func _shot(studio: Control,name: String) -> void:
    await _frames(8)
    var frame: Image=studio.preview.get_texture().get_image()
    assert(frame!=null and frame.get_width()>=640 and frame.get_height()>=400)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(frame.save_png(
        "res://artifacts/tarvoka_infantry_v5_"+name+".png")==OK)

func _audit(level: int,faction: int,damage: int) -> void:
    var model: Node3D=V1.build(level,faction,damage)
    assert(model!=null)
    assert(not V5.apply(model,level,faction,damage))
    assert(V2.apply(model,level,faction,damage))
    assert(not V5.apply(model,level,faction,damage))
    assert(V3.apply(model,level,faction,damage))
    assert(not V5.apply(model,level,faction,damage))
    assert(V4.apply(model,level,faction,damage))
    var baseline_count: int=V1.mesh_count(model)
    assert(not V5.apply(model,level,faction,4 if damage!=4 else 0))
    assert(V5.apply(model,level,faction,damage))
    assert(not V5.apply(model,level,faction,damage))
    var finish: Node3D=model.get_node(V5.STAGE_NAME) as Node3D
    assert(finish!=null and bool(finish.get_meta("visual_only",false)))
    assert(bool(finish.get_meta("three_architectures_preserved",false)))
    assert(bool(finish.get_meta("economy_unchanged",false)))
    assert(int(finish.get_meta("tier",-1))==level)
    assert(int(finish.get_meta("faction",-1))==faction)
    assert(int(finish.get_meta("damage",-1))==damage)
    assert(_count(model,V1.STAGE_NAME)==1)
    assert(_count(model,V2.STAGE_NAME)==1)
    assert(_count(model,V3.STAGE_NAME)==1)
    assert(_count(model,V4.STAGE_NAME)==1)
    assert(_count(model,V5.STAGE_NAME)==1)
    assert(_count(model,"CimentacionGeneral")==1)
    assert(V1.mesh_count(model)>=baseline_count)
    if damage==4:
        assert(bool(finish.get_meta("ruins_only",false)))
        assert(V5.mesh_count(model)==0)
        assert(_prefix(model,"UnionesEsquinaTerminadas_")==0)
        assert(_count(model,"FragmentoRuina_00")==1)
        assert(_count(model,"EscaleraExteriorMantenimientoN3")==0)
    elif damage==3:
        # A critically damaged model gets NO restored glass, ladders,
        # complete corner trims or intact roof parts.
        assert(V5.mesh_count(model)==0)
        assert(_prefix(model,"UnionesEsquinaTerminadas_")==0)
        assert(_prefix(model,"ServicioTechoTerminado_")==0)
        assert(_count(model,"EscaleraExteriorMantenimientoN3")==0)
    else:
        assert(int(finish.get_meta("rear_corner_groups",-1))==level)
        assert(_prefix(model,"UnionesEsquinaTerminadas_")==level)
        assert(_count(model,"ParedPosterior_"+
            str(V2._modules(level)[0]["tag"]))==1)
        assert(V5.mesh_count(model)>=10)
        for module in V2._modules(level):
            var tag: String=str(module["tag"])
            var trim: Node3D=model.get_node(
                V5.STAGE_NAME+"/UnionesEsquinaTerminadas_"+tag) as Node3D
            assert(trim!=null)
            assert(_count(trim,"JuntaEsquinaPosterior_-1")==1)
            assert(_count(trim,"JuntaEsquinaPosterior_1")==1)
            assert(_count(trim,"BajanteAguaPosterior_-1")==1)
            assert(_count(trim,"BajanteAguaPosterior_1")==1)
            assert(_count(trim,"AbrazaderaBajante_-1_0")==1)
            # Genuine V4 openings remain, the V5 finish does not fill them.
            var wall: MeshInstance3D=model.find_child(
                "ParedPosterior_"+tag,true,false) as MeshInstance3D
            assert(wall!=null and not wall.visible)
        if damage==0 and level>=2:
            var expected_modules: int=level
            assert(_prefix(model,"ServicioTechoTerminado_")==expected_modules)
            assert(_count(model,"MarcoRejillaVentilador_0")==level)
        else:
            assert(_prefix(model,"ServicioTechoTerminado_")==0)

    if level==3 and damage!=4:
        var expected_towers: int=2
        assert(int(finish.get_meta("moved_tower_count",-1))==expected_towers)
        var gap_roof: float=float(finish.get_meta(
            "tower_clearance_from_wing_m",-1.0))
        var gap_foot: float=float(finish.get_meta(
            "tower_footing_clearance_m",-1.0))
        var gap_sign: float=float(finish.get_meta(
            "board_clearance_from_tower_m",-1.0))
        assert(gap_roof>0.10 and gap_roof<0.20)
        assert(gap_foot>0.30)
        assert(gap_sign>0.20)
        # Verify actual mesh bounding boxes, not ONLY declared constants.
        for tower in ["TorreOesteNivel3","TorreEsteNivel3"]:
            var origin_name: String=(
                tower if damage<=2 else "BaseTorreCaida_"+tower)
            var tower_node: Node3D=model.find_child(
                origin_name,true,false) as Node3D
            var detail: Node3D=model.find_child(
                "Detalles_"+tower,true,false) as Node3D
            assert(tower_node!=null and detail!=null)
            var expected_tower_z: float=(
                V5.TOWER_BACK_SHIFT_Z if damage<=2 else
                V5.BEFORE_TOWER_Z+V5.TOWER_BACK_SHIFT_Z)
            assert(is_equal_approx(tower_node.position.z,expected_tower_z))
            assert(is_equal_approx(
                detail.position.z,V5.TOWER_BACK_SHIFT_Z))
            if damage<=1:
                var roof: MeshInstance3D=tower_node.find_child(
                    "CubiertaTorre",true,false) as MeshInstance3D
                assert(roof!=null)
                var footprint: Vector3=(roof.mesh as BoxMesh).size
                var front: float=tower_node.position.z+roof.position.z-                    footprint.z*0.5
                assert(front>V5.REAR_WING_END_Z+0.10)
                var field: MeshInstance3D=model.find_child(
                    "SueloPista",true,false) as MeshInstance3D
                assert(field!=null)
                var field_end: float=field.position.z+                    (field.mesh as BoxMesh).size.z*0.5
                assert(field_end<front-0.40)
        if damage<=1:
            var board: Node3D=model.find_child(
                "SenalizacionEntrenamientoV4",true,false) as Node3D
            assert(board!=null)
            assert(is_equal_approx(board.position.z,V5.ORDERS_BOARD_SHIFT_Z))
            assert(bool(board.get_meta("outside_training_course",false)))
        else:
            assert(_count(model,"SenalizacionEntrenamientoV4")==0)
    elif level<3:
        assert(_count(model,"EscaleraExteriorMantenimientoN3")==0)
        assert(_count(model,"TorreOesteNivel3")==0)
        assert(_prefix(model,"UnionesEsquinaTerminadas_")==(
            level if damage<=2 else 0))
    if level==3 and damage<=1:
        var ladder: Node3D=model.get_node(
            V5.STAGE_NAME+"/EscaleraExteriorMantenimientoN3") as Node3D
        assert(ladder!=null and bool(ladder.get_meta("glass_clearance",false)))
        assert(_count(ladder,"RailVerticalMantenimiento_-1")==1)
        assert(_count(ladder,"RailVerticalMantenimiento_1")==1)
        assert(_prefix(ladder,"PeldañoMantenimiento_")==(
            10 if damage==1 else 12))
        # Exposed side window ends before the service ladder's first rail.
        var eastern: Dictionary=V2._modules(3)[2]
        var d: float=float(eastern["d"])
        var z: float=float(eastern["z"])
        var pier: float=(d-3.0*0.66)/4.0
        var last_glass_end: float=z+d*0.5-pier
        var rail_center: float=z+d*0.5-0.37-0.60*0.5
        assert(rail_center-0.075*0.5>last_glass_end+0.12)
    else:
        assert(_count(model,"EscaleraExteriorMantenimientoN3")==0)
    model.free()

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V5.apply(null,3,0,0))
    var count: int=0
    for faction in range(8):
        for damage in range(5):
            for level in range(1,4):
                _audit(level,faction,damage)
                count+=1
    assert(count==120)
    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(6)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(9)
    assert(studio._role=="infantry_barracks")
    assert(studio.infantry_finish_v5_toggle.button_pressed)
    assert(studio.infantry_camera_picker.item_count==8)
    assert(studio.model_root.has_node(V5.STAGE_NAME))

    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        await _frames(5)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        await _shot(studio,"level_%d" % level)
    for level in range(1,4):
        studio.infantry_level_picker.select(level-1)
        studio._change_infantry_setting(level-1)
        studio.infantry_camera_picker.select(4)
        studio._change_infantry_camera(4)
        await _frames(6)
        await _shot(studio,"rear_%d" % level)
    studio.infantry_level_picker.select(2)
    studio._change_infantry_setting(2)
    studio.infantry_camera_picker.select(6)
    studio._change_infantry_camera(6)
    await _shot(studio,"right_3")
    studio.infantry_level_picker.select(1)
    studio._change_infantry_setting(1)
    await _shot(studio,"right_2")
    studio.infantry_level_picker.select(2)
    studio._change_infantry_setting(2)
    studio.infantry_camera_picker.select(5)
    studio._change_infantry_camera(5)
    await _shot(studio,"left_3")
    studio.infantry_camera_picker.select(2)
    studio._change_infantry_camera(2)
    await _shot(studio,"training_3")
    studio.infantry_camera_picker.select(7)
    studio._change_infantry_camera(7)
    await _frames(5)
    assert(studio._infantry_camera_view==7)
    await _shot(studio,"contact_3")
    studio.infantry_finish_v5_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_finish_v5(false)
    await _frames(7)
    assert(not studio.model_root.has_node(V5.STAGE_NAME))
    await _shot(studio,"compare_v4")
    studio.infantry_finish_v5_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_finish_v5(true)
    await _frames(7)
    assert(studio.model_root.has_node(V5.STAGE_NAME))
    await _shot(studio,"compare_v5")
    studio.infantry_camera_picker.select(0)
    studio._change_infantry_camera(0)
    for damage in [1,2,3,4]:
        studio.infantry_damage_picker.select(damage)
        studio._change_infantry_setting(damage)
        await _frames(5)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _shot(studio,"damage_%d" % damage)
    studio.infantry_damage_picker.select(0)
    studio._change_infantry_setting(0)
    await _frames(5)
    studio._select_faction_view(6)
    await _frames(5)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    await _shot(studio,"faction_6")
    studio.infantry_facade_v4_toggle.set_pressed_no_signal(false)
    studio._toggle_infantry_facade_v4(false)
    await _frames(5)
    assert(studio.infantry_finish_v5_toggle.disabled)
    assert(not studio.model_root.has_node(V5.STAGE_NAME))
    studio.infantry_facade_v4_toggle.set_pressed_no_signal(true)
    studio._toggle_infantry_facade_v4(true)
    await _frames(5)
    assert(not studio.infantry_finish_v5_toggle.disabled)
    assert(studio.model_root.has_node(V5.STAGE_NAME))

    # Architectural predecessors survive the whole 3D studio integration.
    studio._change_selected_building(2)
    await _frames(5)
    assert(studio._role=="naval_base")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS INFANTRY BARRACKS V5: 120 native Godot variants, tower/wing clearance, training signage displacement, corner finish and tier-3 ladder verified with 8 cameras and 18 original 3D GPU screenshots; HQ/Airbase/Naval intact")
    quit(0)
