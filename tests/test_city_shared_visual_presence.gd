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
