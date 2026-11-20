extends SceneTree

# Real Godot UI smoke on the native standalone scene. Catches the failure
# mode where QA passes on geometry but the inspector never shows the asset.
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const TILE="PruebaTacticaNueveCasillas"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed:PackedScene=load(
        "res://scenes/ArmoredWorkshopDesignStudioV1.tscn") as PackedScene
    assert(packed!=null,"Native standalone studio scene not importable")
    var inspector:Control=packed.instantiate() as Control
    assert(inspector!=null)
    get_root().add_child(inspector)
    await process_frame
    var mode:OptionButton=inspector.get("_environment") as OptionButton
    var version:OptionButton=inspector.get("_version") as OptionButton
    var level:OptionButton=inspector.get("_level") as OptionButton
    var damage:OptionButton=inspector.get("_damage") as OptionButton
    var faction:OptionButton=inspector.get("_faction") as OptionButton
    var camera:Camera3D=inspector.get("_camera") as Camera3D
    var stage:Node3D=inspector.get("_stage") as Node3D
    assert(mode!=null and version!=null and level!=null and
        damage!=null and faction!=null and camera!=null and stage!=null)
    assert(mode.item_count==2)
    assert(version.item_count==5)
    assert(level.item_count==3)
    assert(damage.item_count==5)
    assert(faction.item_count==9)
    var initial:Node3D=inspector.get("_model") as Node3D
    assert(initial!=null and
        int(initial.get_meta("workshop_art_version",-1))==2)
    # Switch into the same real battle tile preview that Pages will load.
    mode.select(1)
    inspector.call("_on_environment_change",1)
    var fixture:Node3D=inspector.get("_model") as Node3D
    assert(fixture!=null and fixture.name==TILE)
    assert(fixture.get_meta("visual_preview_only",false))
    assert(int(fixture.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_TACTICAL)
    assert(fixture.get_node_or_null("Terreno3DRealNueveCasillas")!=null)
    assert(is_equal_approx(camera.size,9.60))
    # Dynamic selections must rebuild the real 3D node with no lost children.
    level.select(2)
    damage.select(3)
    faction.select(4)
    version.select(3)
    inspector.call("_on_change",3)
    var far:Node3D=inspector.get("_model") as Node3D
    assert(far!=null and far.name==TILE)
    assert(int(far.get_meta("workshop_level",0))==3)
    assert(int(far.get_meta("workshop_damage",-1))==3)
    assert(int(far.get_meta("workshop_faction",-2))==3)
    assert(int(far.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_DISTANT)
    # HERO choices in map mode must be forced back to a mobile LOD.
    version.select(1)
    inspector.call("_on_change",1)
    assert(version.selected==2)
    var light:Node3D=inspector.get("_model") as Node3D
    assert(light!=null and light.name==TILE)
    # Auto mode must use real camera-projected pixels and preserve the nine
    # physical map tiles without rebuilding the surrounding scene.
    version.select(4)
    inspector.call("_on_change",4)
    var automatic:Node3D=inspector.get("_model") as Node3D
    assert(automatic!=null and automatic.name==TILE)
    var terrain:Node3D=automatic.get_node(
        "Terreno3DRealNueveCasillas") as Node3D
    assert(terrain!=null and terrain.get_child_count()==12)
    var terrain_id:int=terrain.get_instance_id()
    var workshop_id:int=automatic.get_node(
        "TallerEnCasillaCentral").get_instance_id()
    var subviewport:SubViewport=inspector.get("_viewport") as SubViewport
    assert(subviewport!=null)
    subviewport.size=Vector2i(1024,720)
    inspector.set("_zoom",0.53)
    inspector.call("_update_camera")
    var close_px:float=Policy.projected_width(
        camera,Vector3(0,0.3,0),2.17)
    assert(close_px>=Policy.ENTER_TACTICAL_PX)
    assert(int(automatic.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_TACTICAL)
    inspector.set("_zoom",2.25)
    inspector.call("_update_camera")
    var far_px:float=Policy.projected_width(
        camera,Vector3(0,0.3,0),2.17)
    assert(far_px<=Policy.EXIT_TACTICAL_PX)
    assert(int(automatic.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_DISTANT)
    assert(terrain.get_instance_id()==terrain_id)
    assert(terrain.get_child_count()==12)
    assert(automatic.get_node(
        "TallerEnCasillaCentral").get_instance_id()==workshop_id)
    assert(inspector.get("_model")==automatic,
        "Zoom must not rebuild the full terrain scene")
    inspector.set("_zoom",0.53)
    inspector.call("_update_camera")
    assert(int(automatic.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_TACTICAL)
    assert(inspector.get("_model")==automatic)
    # Manual modes ignore automatic LOD switching.
    version.select(3)
    inspector.call("_on_change",3)
    var manual:Node3D=inspector.get("_model") as Node3D
    assert(int(manual.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_DISTANT)
    inspector.set("_zoom",0.53)
    inspector.call("_update_camera")
    assert(int(manual.get_meta("workshop_lod_profile",0))==
        Mobile.PROFILE_DISTANT)
    # Switching back restores the original full-scale building, not tiles.
    version.select(4)
    inspector.call("_on_change",4)
    mode.select(0)
    inspector.call("_on_environment_change",0)
    var hero:Node3D=inspector.get("_model") as Node3D
    assert(hero!=null and hero.name!=TILE)
    assert(hero.get_meta("workshop_art_version",-1)==2)
    assert(version.selected==1,
        "Leaving map mode must exit automatic mobile LOD")
    assert(is_equal_approx(camera.size,39.0))
    inspector.queue_free()
    print("PASS WORKSHOP STUDIO UI: native scene initialized, 9 factions, ",
        "5 art/LOD selectors, stable auto zoom changes and no terrain rebuild; ",
        "N3 D3 distant, no HERO on battlefield")
    quit(0)
