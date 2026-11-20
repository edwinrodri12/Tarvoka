extends SceneTree

# QA against the EXACT Pages-native combined Godot Studio scene; the V1/V2
# buttons must swap real Godot meshes inside the existing SubViewport.
const UNITS := ["line","infantry_urban","infantry_defense",
    "scout","infantry_antitank","infantry_engineer"]
var errors: int=0

func must(ok: bool, description: String) -> void:
    if not ok:
        errors+=1
        push_error("INFANTRY SAME STUDIO V2: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size=Vector2i(1280,720)
    var scene: PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    must(scene!=null,"actual published unit-building studio exists")
    if scene==null:
        quit(1)
        return
    var studio: Control=scene.instantiate() as Control
    root.add_child(studio)
    await process_frame
    studio.call("_studio_jump_category",0)
    studio.call("_studio_select_tab",1)
    var original_viewport: SubViewport=studio.get("preview_viewport") as SubViewport
    var original_preview: Node3D=studio.get("preview") as Node3D
    var role_picker: OptionButton=studio.get("role_picker") as OptionButton
    var faction_picker: OptionButton=studio.get("faction_picker") as OptionButton
    var camera_panel: VBoxContainer=studio.get("infantry_360_panel") as VBoxContainer
    must(camera_panel!=null,"camera tab includes native V1/V2 controls")
    must(original_preview!=null,"same preview root exists")
    must(role_picker!=null and faction_picker!=null,
        "same role and faction selectors remain available")
    for role in UNITS:
        studio.call("_display_role",role)
        await process_frame
        var mesh: Node3D=studio.get("model_root") as Node3D
        must(mesh!=null and bool(mesh.get_meta(
            "tarvoka_infantry_sculpt_finish_v2",false)),
            role+" starts from genuine V2 closed sculpt")
        must(studio.get("preview")==original_preview,
            role+" remains in same viewport tree")
        must(mesh!=null and mesh.get_parent()==original_preview,
            role+" model belongs to native viewport")
        must(camera_panel!=null and camera_panel.is_visible_in_tree(),
            role+" comparison controls visible on CAMERA tab")
        studio.call("_infantry_review_look",180.0,"frente")
        must(is_equal_approx(
            (studio.get("model_root") as Node3D).rotation_degrees.y,180.0),
            role+" actual front camera transform")
        studio.call("_infantry_review_version",false)
        var v1: Node3D=studio.get("model_root") as Node3D
        must(v1!=null and bool(v1.get_meta(
            "tarvoka_infantry_family_v1",false))
            and not bool(v1.get_meta("tarvoka_infantry_sculpt_finish_v2",false)),
            role+" uses genuine native V1 mesh rather than fake overlay")
        must(v1!=null and v1.get_parent()==original_preview,
            role+" V1 comparison remains in same 3D viewport")
        studio.call("_infantry_review_version",true)
        var v2: Node3D=studio.get("model_root") as Node3D
        must(v2!=null and bool(v2.get_meta(
            "tarvoka_infantry_sculpt_finish_v2",false)),
            role+" restores real improved V2 sculpt")
        must(v2!=null and v2.get_parent()==original_preview,
            role+" V2 comparison remains in same 3D viewport")
        studio.call("_infantry_review_spin")
        await process_frame
        var tween: Tween=studio.get("infantry_360_tween") as Tween
        must(tween!=null and tween.is_running(),
            role+" native Godot mesh spins at 360°")
        studio.call("_infantry_review_look",0.0,"espalda")
        must(is_equal_approx(
            (studio.get("model_root") as Node3D).rotation_degrees.y,0.0),
            role+" rear view")
    studio.call("_studio_jump_category",1)
    await process_frame
    must(camera_panel!=null and not camera_panel.is_visible_in_tree(),
        "infantry comparison correctly hides in the buildings gallery")
    must(studio.get("preview")==original_preview,
        "studio viewport is never replaced by another viewer")
    studio.queue_free()
    await process_frame
    if errors>0:
        push_error("FAIL INFANTRY V2 SAME STUDIO: %d errors"%errors)
        quit(1)
    else:
        print("PASS INFANTRY V2 SAME STUDIO: 6 roles, V1/V2 toggle, 3 views, 360 orbit, unchanged shared scene")
        quit(0)
