extends SceneTree

# Real Godot GPU regression: test all 8 official palettes, 3 tiers and
# 5 physical states. Studio screens are rendered by the same web scene.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const StudioScene = preload("res://scenes/UnitArtStudioWeb.tscn")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int = 6) -> void:
    for _i in range(n):
        await process_frame

func _shot(studio: Control,name: String) -> void:
    var view: Image = studio.preview.get_texture().get_image()
    assert(view != null and view.get_width()>400 and view.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(view.save_png("res://artifacts/"+name)==OK)

func _run() -> void:
    assert(Airbase.build(0,0,0)==null)
    assert(Airbase.build(2,8,0)==null)
    assert(Airbase.build(2,0,5)==null)
    var mesh_budget := 0
    for faction in range(8):
        for tier in range(1,4):
            for stage in range(5):
                var building: Node3D = Airbase.build(tier,faction,stage)
                assert(building != null)
                assert(building.get_meta("visual_faction",-1)==faction)
                assert(building.get_meta("visual_level",-1)==tier)
                assert(building.get_meta("visual_damage_stage",-1)==stage)
                var count: int = Airbase.mesh_count(building)
                assert(count>20 and count<250)
                mesh_budget = maxi(mesh_budget,count)
                assert(building.find_child("BaseCompacta",true,false)!=null)
                if stage<4:
                    assert(building.find_child("MuroTraseroCerrado",true,false)!=null)
                    assert(building.find_child("MuroLateralCerrado_-1",true,false)!=null)
                    assert(building.find_child("MuroLateralCerrado_1",true,false)!=null)
                    assert(building.find_child("TorreControlAereoV1",true,false)!=null)
                    assert(building.find_child("HelipuertoDespliegue",true,false)!=null)
                    assert(building.find_child("CompuertaPrincipal_0",true,false)!=null)
                    assert(building.find_child("EmblemaOficialAtlasBaseAerea",true,false)!=null)
                    assert(Airbase.count_faction_panels(building)>0)
                    assert(int(building.find_child("EmblemaOficialAtlasBaseAerea",
                        true,false).get_meta("tarvoka_official_emblem_index",-1))==faction)
                else:
                    assert(building.find_child("HangarPrincipalV1",true,false)==null)
                    assert(building.find_child("TorreControlAereoV1",true,false)==null)
                    assert(building.find_child("TorreDerribada",true,false)!=null)
                if stage==0:
                    assert(building.find_child("CubiertaCurva3D_06",true,false)!=null)
                if stage==2:
                    assert(building.find_child("CubiertaCurva3D_06",true,false)==null)
                if stage==3:
                    assert(building.find_child("CabinaControlColapsada",true,false)!=null)
                    assert(building.find_child("CubiertaCurva3D_04",true,false)==null)
                building.free()
    var root: Control = StudioScene.instantiate()
    self.root.content_scale_size = Vector2i(1280,800)
    self.root.add_child(root)
    await _frames(8)
    root._switch_category(1)
    await _frames(6)
    assert(root.building_picker.item_count==2)
    assert(root._role=="headquarters")
    root._change_selected_building(1)
    await _frames(9)
    assert(root._role=="airbase")
    assert(root.model_root.get_meta("tarvoka_airbase_v1",false))
    assert(root.building_controls.visible and root.airbase_controls.visible)
    assert(root.hq_v15_mode_picker.visible==false)
    _shot(root,"tarvoka_airbase_v1_level1_day.png")
    root.airbase_level_picker.select(2)
    root._change_airbase_level(2)
    await _frames(8)
    assert(root.model_root.get_meta("visual_level",-1)==3)
    _shot(root,"tarvoka_airbase_v1_level3_day.png")
    root._on_faction(6)
    root._refresh_building_faction(6)
    await _frames(8)
    assert(root.model_root.get_meta("visual_faction",-1)==6)
    _shot(root,"tarvoka_airbase_v1_turquoise_faction.png")
    root.airbase_damage_picker.select(2)
    root._change_airbase_damage(2)
    await _frames(8)
    assert(root.model_root.get_meta("visual_damage_stage",-1)==2)
    _shot(root,"tarvoka_airbase_v1_medium_damage.png")
    root.airbase_damage_picker.select(3)
    root._change_airbase_damage(3)
    await _frames(8)
    _shot(root,"tarvoka_airbase_v1_critical_damage.png")
    root.airbase_damage_picker.select(4)
    root._change_airbase_damage(4)
    await _frames(8)
    assert(root.model_root.find_child("HangarPrincipalV1",true,false)==null)
    _shot(root,"tarvoka_airbase_v1_destroyed.png")
    root.airbase_damage_picker.select(0)
    root._change_airbase_damage(0)
    root.airbase_weather_picker.select(1)
    root._change_airbase_weather(1)
    await _frames(8)
    assert(root.model_root.get_meta("weather_coating",{}).get("mode","")=="rain")
    _shot(root,"tarvoka_airbase_v1_rain.png")
    root.airbase_weather_picker.select(2)
    root._change_airbase_weather(2)
    await _frames(8)
    assert(root.model_root.get_meta("weather_coating",{}).get("mode","")=="snow")
    _shot(root,"tarvoka_airbase_v1_snow.png")
    root._change_selected_building(0)
    await _frames(6)
    assert(root._role=="headquarters")
    assert(root.model_root.get_meta("tarvoka_hq_visual_v12",false))
    root._change_selected_building(1)
    await _frames(6)
    assert(root._role=="airbase")
    root.queue_free()
    await _frames(5)
    print("PASS AIRBASE V1: 8 official factions x 3 levels x 5 damage stages, %d meshes budget, genuine closed hangar, 3D roof, Godot GPU studio views, rain, snow, HQ preserved" % mesh_budget)
    quit(0)
