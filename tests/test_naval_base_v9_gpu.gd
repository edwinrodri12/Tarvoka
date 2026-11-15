extends SceneTree

# Native Godot 4.3 V9 acceptance: procedural ribbed ArrayMesh rubber,
# restrained PBR scuffs, five damage stages, eight factions and studio
# comparison V8/V9. Visual QA ONLY, no Android frame-rate claim.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const V7=preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const V8=preload("res://scripts/ui/NavalFendersV8.gd")
const V9=preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(root: Node,label: String) -> int:
    var n: int=1 if str(root.name)==label else 0
    for child in root.get_children():
        n+=_count(child,label)
    return n

func _capture(studio: Control,name: String) -> void:
    await _frames(7)
    var im: Image=studio.preview.get_texture().get_image()
    assert(im!=null and im.get_width()>400 and im.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(im.save_png("res://artifacts/tarvoka_naval_v9_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V8.apply(null,2,0,0))
    assert(not V9.apply(null,2,0,0))
    assert(not V9.set_detail(null,true))
    assert(not V8.set_night(null,true))
    assert(not V8.set_detail(null,true))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null)
            assert(not V8.apply(model,2,faction,damage))
            assert(V2.apply(model,2,faction,damage))
            assert(V3.apply(model,2,faction,damage))
            assert(V4.apply(model,2,faction,damage))
            assert(V5.apply(model,2,faction,damage))
            assert(V6.apply(model,2,faction,damage))
            assert(not V8.apply(model,2,faction,damage))
            assert(V7.apply(model,2,faction,damage))
            var previous: int=Base.count_meshes(model)
            assert(V8.apply(model,2,faction,damage))
            assert(not V8.apply(model,2,faction,damage))
            assert(Base.count_meshes(model)>previous+4)
            assert(V9.apply(model,2,faction,damage))
            assert(not V9.apply(model,2,faction,damage))
            var sculpt: Node3D=model.get_node(V9.STAGE_NAME)
            assert(sculpt!=null)
            assert(bool(sculpt.get_meta("naval_v9_pbr_rubber",false)))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            assert(V9.set_detail(model,false))
            assert(not (sculpt.get_node("DefensasEsculpidasCercaV9") as Node3D).visible)
            assert((sculpt.get_node("DefensasSiluetaLejosV9") as Node3D).visible)
            assert(V9.set_detail(model,true))
            assert((sculpt.get_node("DefensasEsculpidasCercaV9") as Node3D).visible)
            if damage<4:
                var sculpt_body: MeshInstance3D=model.find_child(
                    "MuelleEste_00_SculptedShell",true,false) as MeshInstance3D
                assert(sculpt_body!=null)
                assert(sculpt_body.mesh is ArrayMesh)
                assert(sculpt_body.mesh.get_surface_count()==1)
                var vtx: PackedVector3Array=sculpt_body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                assert(vtx.size()>=250)
                assert(sculpt_body.material_override is ShaderMaterial)
                var pbr: ShaderMaterial=sculpt_body.material_override as ShaderMaterial
                assert(pbr.shader.code.contains("salt_scuff"))
                assert(pbr.shader.code.contains("ROUGHNESS"))
            if damage<=2:
                var old_fender: MeshInstance3D=model.find_child(
                    "FenderVerticalMuelleEste_00",true,false) as MeshInstance3D
                assert(old_fender!=null and not old_fender.visible)
            if damage<=1:
                assert(_count(model,"MuelleEste_00_Collar_-1")==1)
                assert(_count(model,"MuelleEste_00_ClampingBolt_1_1")==1)
                assert(_count(model,"Espigon_1_0_SculptedShell")==1)
                assert(_count(model,"MuelleEste_00_FactionMountingMark")==1)
            if damage==2:
                assert(_count(model,"MuelleEste_00_Collar_1")==0)
                assert(_count(model,"MuelleEste_02_SculptedShell")==0)
                assert(_count(model,"MuelleEste_00_BentMount")==1)
            if damage==3:
                assert(_count(model,"MuelleEste_00_TornLip")==1)
                assert(_count(model,"Espigon_1_0_SculptedShell")==0)
                assert(_count(model,"Espigon_-1_0_DamagedDistanceProfile")==1)
            if damage==4:
                assert(_count(model,"MuelleEste_00_SculptedShell")==0)
                assert(_count(model,"Espigon_-1_0_SculptedShell")==0)
                assert(_count(model,"RestosDefensaEspigonDestruido")==1)
            var stage: Node3D=model.get_node(V8.STAGE_NAME)
            assert(int(stage.get_meta("naval_v8_damage",-1))==damage)
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            assert(_count(model,"EspumaContactoCercanaV8")==1)
            assert(_count(model,"EspumaContactoLejanaV8")==1)
            var material: ShaderMaterial=stage.get_meta("naval_v8_foam_material") as ShaderMaterial
            assert(material!=null)
            assert(material.shader.code.contains("foam_opacity"))
            assert(material.shader.code.contains("TIME"))
            assert(_count(model,"EspumaContactMuelleEste_00")==1)
            var foam: MeshInstance3D=model.find_child(
                "EspumaContactMuelleEste_00",true,false) as MeshInstance3D
            assert(foam!=null and foam.mesh is PlaneMesh)
            assert(foam.material_override==material)
            assert(foam.position.y>0.046 and foam.position.y<0.075)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            assert(V8.set_detail(model,false))
            assert(not (stage.get_node("DetallesCercanosDefensasV8") as Node3D).visible)
            assert((stage.get_node("PerfilesLejanosDefensasV8") as Node3D).visible)
            assert(not (stage.get_node("EspumaContactoCercanaV8") as Node3D).visible)
            assert(V8.set_detail(model,true))
            assert((stage.get_node("DetallesCercanosDefensasV8") as Node3D).visible)
            assert(V8.set_night(model,true))
            assert((stage.get_node("GuiasNocturnasMuellesV8") as Node3D).visible)
            assert(is_equal_approx(float(material.get_shader_parameter("night_factor")),0.42))
            assert(V8.set_night(model,false))
            assert(not (stage.get_node("GuiasNocturnasMuellesV8") as Node3D).visible)
            assert(is_equal_approx(float(material.get_shader_parameter("night_factor")),1.0))

            if damage<=1:
                assert(_count(model,"FenderVerticalMuelleEste_00")==1)
                assert(_count(model,"FenderVerticalMuelleEste_02")==1)
                assert(_count(model,"DefensaNeumaticaEspigon_1_0")==1)
                assert(_count(model,"CadenaDefensa_-1_0")==1)
                assert(_count(model,"CanalDrenajeAstillero_04")==1)
                assert(_count(model,"ConductorServicioPasarela_0")==1)
                assert(_count(model,"ProtectorConexionFaccion")==1)
                assert(_count(model,"EspumaInteriorEspigon_1_00")==1)
            if damage==2:
                assert(_count(model,"FenderVerticalMuelleEste_00")==1)
                assert(_count(model,"FenderVerticalMuelleEste_02")==0)
                assert(_count(model,"DefensaNeumaticaEspigon_-1_1")==0)
                assert(_count(model,"CanalDrenajeAstillero_04")==1)
                assert(_count(model,"ProtectorConexionDañado")==1)
                assert(_count(model,"ProtectorConexionFaccion")==0)
            if damage==3:
                assert(_count(model,"FenderVerticalMuelleEste_00")==0)
                assert(_count(model,"GomaMuelleEsteRota_00")==1)
                assert(_count(model,"DefensaEspigonRota_-1_0")==1)
                assert(_count(model,"DefensaNeumaticaEspigon_1_0")==0)
                assert(_count(model,"EspumaInteriorEspigon_1_00")==0)
                assert(_count(model,"CanalDrenajeAstillero_02")==0)
                assert(_count(model,"CoronacionEspigon_1")==0)
            if damage==4:
                assert(_count(model,"FenderVerticalMuelleEste_00")==0)
                assert(_count(model,"DefensaNeumaticaEspigon_-1_0")==0)
                assert(_count(model,"RestosDefensaEspigonDestruido")==1)
                assert(_count(model,"CunetaAstilleroDemolida")==1)
                assert(_count(model,"CanalDrenajeAstillero_00")==0)
                assert(_count(model,"ConductorServicioPasarela_0")==0)
                assert(_count(model,"ParedPosteriorHangar")==0)
            model.free()
            variants+=1
    assert(variants==40)
    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(V2.apply(model,level,6,0))
        assert(V3.apply(model,level,6,0))
        assert(V4.apply(model,level,6,0))
        assert(V5.apply(model,level,6,0))
        assert(V6.apply(model,level,6,0))
        assert(V7.apply(model,level,6,0))
        assert(V8.apply(model,level,6,0))
        assert(V9.apply(model,level,6,0))
        assert(_count(model,"MuelleEste_00_SculptedShell")==1)
        assert(_count(model,"FenderVerticalMuelleEste_00")==1)
        assert(_count(model,"ConductorServicioPasarela_0")==(
            0 if level==1 else 1))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(6)
    studio._change_selected_building(2)
    await _frames(10)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v7_toggle.button_pressed)
    assert(studio.naval_detail_v8_toggle.button_pressed)
    assert(studio.naval_detail_v9_toggle.button_pressed)
    assert(studio.model_root.has_node(V8.STAGE_NAME))
    assert(studio.model_root.has_node(V9.STAGE_NAME))
    await _capture(studio,"overview")
    studio.naval_camera_picker.select(4)
    studio._change_naval_camera(4)
    studio._zoom=1.30
    studio._update_camera()
    await _frames(8)
    assert(studio._naval_camera_view==4)
    assert(studio.camera.size<9.0)
    assert(bool(studio.model_root.get_node(V8.STAGE_NAME)
        .get_meta("naval_v8_close_mode",false)))
    assert(_count(studio.model_root,"MuelleEste_00_SculptedShell")==1)
    await _capture(studio,"fenders_close")
    studio.naval_camera_picker.select(1)
    studio._change_naval_camera(1)
    await _frames(8)
    await _capture(studio,"quay_water")
    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio._zoom=0.62
    studio._update_camera()
    await _frames(7)
    assert(not bool(studio.model_root.get_node(V8.STAGE_NAME)
        .get_meta("naval_v8_close_mode",true)))
    assert(not bool(studio.model_root.get_node(V9.STAGE_NAME)
        .get_meta("naval_v9_close_mode",true)))
    await _capture(studio,"tactical_far")
    studio._zoom=1.0
    studio._update_camera()
    studio.naval_night_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_night_v6(true)
    await _frames(8)
    assert(bool(studio.model_root.get_node(V8.STAGE_NAME)
        .get_meta("naval_v8_night_enabled",false)))
    await _capture(studio,"night_fenders")
    studio.naval_night_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_night_v6(false)
    studio.naval_detail_v9_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v9(false)
    await _frames(7)
    assert(studio.model_root.has_node(V8.STAGE_NAME))
    assert(not studio.model_root.has_node(V9.STAGE_NAME))
    var old_shape: MeshInstance3D=studio.model_root.find_child(
        "FenderVerticalMuelleEste_00",true,false) as MeshInstance3D
    assert(old_shape!=null and old_shape.visible)
    await _capture(studio,"compare_v8")
    studio.naval_detail_v9_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v9(true)
    studio.naval_level_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(8)
    assert(studio.model_root.has_node(V9.STAGE_NAME))
    await _capture(studio,"shipyard_level3")
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(_count(studio.model_root,"DefensaNeumaticaEspigon_1_0")==0)
    await _capture(studio,"critical_damage")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V9: 40 faction/damage variants, three levels, procedural ribbed ArrayMesh rubber and PBR weathering, damage-correct silhouettes, V8-V9 Studio comparison, 8 real Godot captures")
    quit(0)
