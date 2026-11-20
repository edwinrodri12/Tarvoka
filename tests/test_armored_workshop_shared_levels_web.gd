extends SceneTree

# Runs ONLY inside the exact multi-branch assembled Pages export source.
# The standalone workshop scene cannot detect missing / hidden LEVEL controls
# in the real EDIFICIOS picker, nor a blank Web native SubViewport.
const OUT="res://build/qa/"
const WORKSHOP_INDEX:int=6

func _initialize() -> void:
    call_deferred("_run")

func _frames(n:int=8) -> void:
    for _i in range(n):
        await process_frame

func _visible_meshes(root:Node) -> int:
    var count:int=0
    var stack:Array[Node]=[root]
    while not stack.is_empty():
        var node:Node=stack.pop_back()
        if node is MeshInstance3D and (node as MeshInstance3D).visible:
            count+=1
        elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).visible:
            count+=1
        for child in node.get_children():
            stack.append(child)
    return count

func _nonblank_pixels(viewport:SubViewport,model:Node3D) -> int:
    await _frames(12)
    var visible:Image=viewport.get_texture().get_image()
    assert(visible!=null and visible.get_width()>200)
    model.visible=false
    await _frames(10)
    var hidden:Image=viewport.get_texture().get_image()
    model.visible=true
    await _frames(2)
    assert(visible.get_size()==hidden.get_size())
    var changed:int=0
    for y in range(3,visible.get_height(),7):
        for x in range(3,visible.get_width(),7):
            var a:Color=visible.get_pixel(x,y)
            var b:Color=hidden.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.12:
                changed+=1
    return changed

func _check_level(studio:Variant,level:int,
        profile:int,tag:String) -> void:
    studio.workshop_level.select(level-1)
    studio.workshop_level.item_selected.emit(level-1)
    await _frames(6)
    var model:Node3D=studio.model_root as Node3D
    assert(model!=null,"Selected N%d produced NO workshop model" % level)
    assert(model.is_inside_tree() and model.visible)
    assert(studio._role=="armored_workshop")
    assert(int(model.get_meta("workshop_level",0))==level)
    assert(int(model.get_meta("workshop_bays",0))==level)
    assert(int(model.get_meta("workshop_damage",-1))==0)
    assert(int(model.get_meta("workshop_art_version",0))==2)
    assert(_visible_meshes(model)>=8,
        "N%d loaded an empty 3D model" % level)
    if profile==0:
        assert(not model.name.begins_with("PruebaTactica"))
        assert(_visible_meshes(model)>70,
            "N%d HERO level has no actual detailed sculpture" % level)
    else:
        assert(bool(model.get_meta("visual_preview_only",false)))
        assert(model.get_node_or_null("Terreno3DRealNueveCasillas")!=null)
    assert(studio.camera.current)
    var colored:int=await _nonblank_pixels(studio.preview,model)
    assert(colored>55,
        "N%d %s is not visible in actual shared Web camera" % [level,tag])
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    var img:Image=studio.preview.get_texture().get_image()
    assert(img.save_png(OUT+"workshop-shared-%s-n%d.png" % [tag,level])==OK)
    assert(studio.workshop_info.text.contains("N%d" % level))
    print("PASS WORKSHOP LEVEL %s N%d: %d drawable children, %d visible pixel samples" % [
        tag,level,_visible_meshes(model),colored])

func _run() -> void:
    root.size=Vector2i(1280,720)
    var scene:PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    assert(scene!=null)
    var studio:Variant=scene.instantiate()
    assert(studio!=null)
    root.add_child(studio)
    await _frames(16)
    assert(studio.building_picker.item_count>=7)
    assert(studio.building_picker.get_item_text(
        WORKSHOP_INDEX).contains("Taller de Blindados"))
    studio.category_picker.select(1)
    studio.category_picker.item_selected.emit(1)
    studio.building_picker.select(WORKSHOP_INDEX)
    studio.building_picker.item_selected.emit(WORKSHOP_INDEX)
    await _frames(10)
    assert(studio.workshop_controls!=null and
        studio.workshop_controls.is_visible_in_tree(),
        "Workshop settings must be visible, not hidden below old controls")
    assert(studio.workshop_controls.get_index()==2,
        "N1/N2/N3 selectors need to be immediately below building dropdown")
    assert(studio.workshop_level.is_visible_in_tree() and
        studio.workshop_level.item_count==3)
    assert(studio.workshop_version.selected==1)
    assert(studio.workshop_view.selected==0)
    var level_buttons:Control=studio.workshop_controls.find_child(
        "TallerBlindadosAccesoRapidoNiveles",true,false)
    assert(level_buttons!=null and level_buttons.get_child_count()==3)
    assert(level_buttons.is_visible_in_tree())
    # Exercise real dropdown emission, not just direct geometry construction.
    for level in [1,2,3]:
        await _check_level(studio,level,0,"HERO")
    # Exercise actual prominent shortcut button for N1 and restore N3.
    (level_buttons.get_child(0) as Button).pressed.emit()
    await _frames(5)
    assert(int(studio.model_root.get_meta("workshop_level",-1))==1)
    (level_buttons.get_child(2) as Button).pressed.emit()
    await _frames(5)
    assert(int(studio.model_root.get_meta("workshop_level",-1))==3)
    # Android automatic zoom tile mode must still show EACH architectural
    # size and preserve all nine pieces of 2.4m terrain.
    studio.workshop_version.select(4)
    studio.workshop_version.item_selected.emit(4)
    await _frames(5)
    assert(studio.workshop_view.selected==1)
    for level in [1,2,3]:
        await _check_level(studio,level,1,"MAP")
    # Return to Civilian City and preserve its approved controls at index2.
    studio.building_picker.select(4)
    studio.building_picker.item_selected.emit(4)
    await _frames(6)
    assert(studio._role=="civilian_city")
    assert(studio.civilian_city_controls.get_index()==2)
    assert(studio.model_root!=null)
    # Returning to workshop must not leave the model hidden or stale.
    studio.building_picker.select(WORKSHOP_INDEX)
    studio.building_picker.item_selected.emit(WORKSHOP_INDEX)
    await _frames(6)
    assert(studio.workshop_controls.get_index()==2)
    assert(studio.workshop_controls.is_visible_in_tree())
    assert(studio.model_root!=null)
    assert(int(studio.model_root.get_meta("workshop_level",0))==3)
    print("PASS WORKSHOP SHARED LEVELS: actual published Godot EDIFICIOS scene; ",
        "N1/N2/N3 HERO+MAP; visible buttons and real frame pixels; ",
        "city selector and return preserved")
    studio.queue_free()
    await _frames(2)
    quit(0)
