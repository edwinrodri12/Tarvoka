extends SceneTree

const Studio=preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Rig=preload("res://scripts/ui/APCBoardingV4.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Models=preload("res://scripts/ui/UnitModels3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size=Vector2i(1250,770)
    var studio:=Studio.new()
    root.add_child(studio)
    for frame in range(3):
        await process_frame
    studio._display_role("apc")
    for frame in range(3):
        await process_frame
    assert(studio._role=="apc")
    assert(studio.model_root.get_meta("tarvoka_apc_finish_v3",false))
    assert(studio.model_root.get_meta("tarvoka_apc_boarding_v4",false))
    assert(studio.apc_controls.visible)
    assert(studio.apc_embark_button!=null)
    assert(studio.apc_disembark_button!=null)
    assert(studio.apc_occupancy_label!=null)
    assert(studio.apc_occupancy_label.text.contains("0/2"))
    assert(not studio.apc_embark_button.disabled)
    assert(studio.apc_disembark_button.disabled)
    assert(Rig.occupants(studio.model_root)==0)

    studio.apc_embark_button.pressed.emit()
    assert(studio._animation=="embark")
    studio._process(Rig.DURATION*0.50)
    var ramp: Node3D=studio.model_root.find_child(Rig.HINGE,true,false) as Node3D
    assert(ramp!=null and ramp.rotation_degrees.x>70.0)
    studio._process(Rig.DURATION*0.55)
    assert(studio._animation.is_empty())
    assert(Rig.occupants(studio.model_root)==1)
    assert(studio.apc_occupancy_label.text.contains("1/2"))
    assert(not studio.apc_disembark_button.disabled)

    studio.apc_embark_button.pressed.emit()
    studio._process(Rig.DURATION)
    assert(Rig.occupants(studio.model_root)==2)
    assert(studio.apc_embark_button.disabled and not studio.apc_disembark_button.disabled)
    studio._play("embark") # Cannot load an impossible third soldier.
    assert(studio._animation.is_empty())

    # Switch faction while soldiers are on board: repaint vehicle and the
    # 3D troop uniform without changing the occupant count or geometry.
    var before_geometry: int=Models.inspect_meshes(studio.model_root)
    studio._on_faction(7)
    assert(Rig.occupants(studio.model_root)==2)
    assert(Models.inspect_meshes(studio.model_root)==before_geometry)
    var troop_root: Node3D=studio.model_root.find_child(Rig.RIG_ROOT,true,false) as Node3D
    assert(troop_root!=null)
    var uniform: StandardMaterial3D=troop_root.get_meta("tarvoka_p06_v4_uniform_material",null) as StandardMaterial3D
    assert(uniform!=null)
    var expected: Color=Color("#899A8F").lerp(Style.faction_color(7),0.22)
    assert(absf(uniform.albedo_color.r-expected.r)<0.015)
    assert(absf(uniform.albedo_color.g-expected.g)<0.015)
    assert(absf(uniform.albedo_color.b-expected.b)<0.015)

    studio.apc_disembark_button.pressed.emit()
    studio._process(Rig.DURATION)
    assert(Rig.occupants(studio.model_root)==1)
    assert(studio.apc_occupancy_label.text.contains("1/2"))
    # Destroying the carrier must remove any remaining internal troop rig
    # marker, preventing ghosts / extra lives in the 3D preview.
    studio._set_apc_damage(4)
    assert(Rig.occupants(studio.model_root)==0)
    assert(studio.apc_occupancy_label.text.contains("0/2"))
    assert(studio.apc_embark_button.disabled and studio.apc_disembark_button.disabled)
    studio._play("embark")
    assert(studio._animation.is_empty())
    studio._set_apc_damage(0)
    assert(not studio.apc_embark_button.disabled)
    assert(studio.apc_disembark_button.disabled)

    # V1/V2/V3 comparisons remain functional and show the correct version;
    # the V4 soldier rig exists ONLY atop the finished V3 chassis.
    studio._toggle_apc_v3()
    assert(not studio._apc_v3_preview)
    assert(not studio.model_root.get_meta("tarvoka_apc_boarding_v4",false))
    assert(studio.apc_embark_button.disabled)
    studio._toggle_apc_v3()
    assert(studio._apc_v3_preview)
    assert(studio.model_root.get_meta("tarvoka_apc_boarding_v4",false))
    assert(Rig.occupants(studio.model_root)==0)
    assert(not studio.apc_embark_button.disabled)
    assert(studio.apc_disembark_button.disabled)
    studio.queue_free()
    print("PASS APC P06 V4 studio: real interactive 3D embark/deploy buttons, 2 seats, eight-faction repaint, destruction, comparisons and previews")
    quit(0)
