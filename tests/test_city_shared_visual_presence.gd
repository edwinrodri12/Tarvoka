extends SceneTree

# Regression for the actual Pages scene after the pipeline overlays city V43.
# A successful .wasm export alone does not prove that selecting City builds
# any visible geometry. This exercises the same native picker as end users.
func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=6) -> void:
    for _i in range(n):
        await process_frame

func _run() -> void:
    root.content_scale_size=Vector2i(1280,720)
    var packed: PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    assert(packed!=null,"Unified Studio scene unavailable")
    var studio=packed.instantiate()
    root.add_child(studio)
    await _frames(12)
    assert(studio.category_picker!=null)
    assert(studio.building_picker!=null and studio.building_picker.item_count>=5)
    assert(studio.building_picker.get_item_text(4).contains("Ciudades civiles"))
    studio.category_picker.select(1)
    studio.category_picker.item_selected.emit(1)
    studio.building_picker.select(4)
    studio.building_picker.item_selected.emit(4)
    await _frames(12)
    assert(studio._role=="civilian_city","City picker did not switch the model")
    assert(studio.civilian_city_controls!=null and studio.civilian_city_controls.visible)
    assert(studio.civilian_city_controls.get_index()==2,
        "City controls should follow building selector directly")
    assert(studio.model_root!=null,"Selected city did not create a scene")
    assert(studio.model_root.has_node("CiudadCivilV43ComprobacionEvidenciasArtisticas"),
        "City V43 art stages were not built")
    assert(int(studio.model_root.get_meta("city_art_work_in_progress",0))>=43)
    assert(studio.camera!=null and studio.camera.current)
    var stack: Array[Node]=[studio.model_root]
    var visible: int=0
    while not stack.is_empty():
        var n: Node=stack.pop_back()
        if n is MeshInstance3D and (n as MeshInstance3D).visible:
            visible+=1
        for child in n.get_children():
            stack.append(child)
    assert(visible>50,"City model has no visible meshes")
    # An attached mesh tree is insufficient: a wrong camera or blank
    # SubViewport can still leave the public Studio completely empty.
    await _frames(18)
    var render: Image=studio.preview.get_texture().get_image()
    assert(render!=null and not render.is_empty(),"City viewport has no render")
    var samples: Dictionary={}
    for y in range(0,render.get_height(),maxi(1,render.get_height()/15)):
        for x in range(0,render.get_width(),maxi(1,render.get_width()/21)):
            samples[render.get_pixel(x,y).to_html()]=true
    assert(samples.size()>8,"City viewport is effectively a blank canvas")
    # Verify that city geometry, not simply the viewport background/ground,
    # actually produces pixels. Previous color-diversity QA could pass even
    # when no visible city was projected into the live camera.
    var city_on: Image=studio.preview.get_texture().get_image()
    studio.model_root.visible=false
    await _frames(12)
    var city_off: Image=studio.preview.get_texture().get_image()
    assert(city_on.get_size()==city_off.get_size(),
        "City visual render comparison has mismatched viewport dimensions")
    var changed_pixels:int=0
    for py in range(0,city_on.get_height(),7):
        for px in range(0,city_on.get_width(),7):
            var before:Color=city_on.get_pixel(px,py)
            var after:Color=city_off.get_pixel(px,py)
            if (absf(before.r-after.r)+absf(before.g-after.g)+
                    absf(before.b-after.b))>0.14:
                changed_pixels+=1
    studio.model_root.visible=true
    await _frames(4)
    print("CITY V43 real canvas city-vs-empty pixel delta: ",changed_pixels,
        " viewport=",city_on.get_size(),
        " meshes=",visible)
    assert(changed_pixels>150,
        "Native City V43 geometry produces no visible pixels in the viewport")
    # Camera UX regression: replacing ninety-three buttons must not lose
    # any approved V1-V42 view or alter the original camera/damage behavior.
    assert(studio.civilian_city_view_group!=null and
        studio.civilian_city_view_group.item_count==5,
        "City camera groups are missing")
    assert(studio.civilian_city_view_preset!=null,
        "City camera preset selector is missing")
    var quick: Node=studio.civilian_city_controls.find_child(
        "Ciudades_Camaras_Acceso_Rapido_V43",true,false)
    assert(quick!=null and quick.get_child_count()==8,
        "Compact quick cameras and rotation buttons must stay accessible")
    assert(studio.civilian_city_controls.find_child(
        "Ciudades_Camaras_3D",true,false)==null,
        "Legacy 93-button sidebar should be replaced, not duplicated")
    var visited: Dictionary={}
    for group_index in range(studio.civilian_city_view_group.item_count):
        studio.civilian_city_view_group.select(group_index)
        studio.civilian_city_view_group.item_selected.emit(group_index)
        for preset_index in range(studio.civilian_city_view_preset.item_count):
            var original_id: int=studio.civilian_city_view_preset.get_item_id(
                preset_index)
            assert(original_id>=0 and original_id<=92,
                "An original city camera ID was replaced")
            assert(not visited.has(original_id),
                "City camera group contains a duplicate original view")
            visited[original_id]=true
    assert(visited.size()==93,"All 93 original camera views must survive")
    studio.civilian_city_view_preset.select(3)
    studio.civilian_city_view_preset.item_selected.emit(3)
    assert(studio._city_view==90,
        "V42 fine-detail camera was not reached from the dropdown")
    assert(studio.civilian_city_damage.selected==2,
        "V42 damaged-roof preset no longer selects D2")
    studio._city_camera_preset(5)
    assert(studio.civilian_city_view_group.selected==0 and
        studio.civilian_city_view_preset.get_selected_id()==5,
        "Quick-view camera did not synchronize the grouped selectors")
    assert(studio.model_root!=null and studio.camera.current,
        "City camera switching lost the live Godot viewport")
    for tier in [0,1,2]:
        studio.civilian_city_tier.select(tier)
        studio.civilian_city_tier.item_selected.emit(tier)
        await _frames(3)
        assert(studio.model_root!=null,"City tier returned empty model")
        assert(int(studio.model_root.get_meta("visual_level",-1))==tier+1)
    studio.civilian_city_damage.select(4)
    studio.civilian_city_damage.item_selected.emit(4)
    await _frames(3)
    assert(studio.model_root!=null,"Destroyed city returned empty model")
    assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==4)
    studio.building_picker.select(0)
    studio.building_picker.item_selected.emit(0)
    await _frames(3)
    assert(studio._role=="headquarters","Existing HQ regressed")
    studio.building_picker.select(4)
    studio.building_picker.item_selected.emit(4)
    await _frames(4)
    assert(studio.model_root!=null,"City disappeared after switching buildings")
    print("PASS CITY V43 SHARED STUDIO VISIBLE: tier, damage, return, camera, meshes")
    studio.queue_free()
    await _frames(2)
    quit(0)
