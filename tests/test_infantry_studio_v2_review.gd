extends SceneTree

# QA against the EXACT Pages-native combined Godot Studio scene; the V1/V2
# buttons must swap real Godot meshes inside the existing SubViewport.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
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
    # The actual TARVOKA rendering parent is a SubViewport, not Node3D.
    # A Node3D cast silently returned null and caused 26 false QA failures.
    var original_preview: SubViewport=studio.get("preview") as SubViewport
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
        # Switch between genuine dense 3D hero and smaller tactical LOD8
        # without changing the original Godot SubViewport or controls.
        studio.call("_infantry_review_lod",8)
        var low: Node3D=studio.get("model_root") as Node3D
        var view_camera: Camera3D=studio.get("camera") as Camera3D
        must(low!=null and int(low.get_meta(
            "tarvoka_infantry_lod",0))==8 and bool(low.get_meta(
            "tarvoka_infantry_v3_tactical_identity",false)),
            role+" uses physical tactical LOD8 colors")
        must(low!=null and low.get_parent()==original_preview and
            studio.get("preview")==original_preview,
            role+" LOD8 shares SAME live unit/building 3D viewport")
        must(view_camera!=null and view_camera.size>7.0,
            role+" tactical distance preview actually moves camera out")
        studio.call("_on_faction",5)
        var recolored: Node3D=studio.get("model_root") as Node3D
        var badge: MeshInstance3D=recolored.find_child(
            "V3_IdentidadPechoMapa",true,false) as MeshInstance3D
        var mat: StandardMaterial3D=badge.material_override as StandardMaterial3D if badge!=null else null
        must(mat!=null and mat.albedo_color.is_equal_approx(
            Models.faction_paint_color(5)) and
            int(recolored.get_meta("tarvoka_infantry_lod",0))==8,
            role+" faction picker repaints actual LOD8 3D mesh, not only label")
        studio.call("_infantry_review_version",false)
        var lite_v1: Node3D=studio.get("model_root") as Node3D
        must(lite_v1!=null and int(lite_v1.get_meta(
            "tarvoka_infantry_lod",0))==8 and
            not bool(lite_v1.get_meta("tarvoka_infantry_sculpt_finish_v2",false)),
            role+" genuine V1 comparison also respects tactical LOD8")
        studio.call("_infantry_review_version",true)
        var lite_v2: Node3D=studio.get("model_root") as Node3D
        must(lite_v2!=null and bool(lite_v2.get_meta(
            "tarvoka_infantry_v3_tactical_identity",false)),
            role+" can restore V2 LOD8 after comparing V1")
        studio.call("_infantry_review_lod",13)
        var detailed: Node3D=studio.get("model_root") as Node3D
        must(detailed!=null and int(detailed.get_meta(
            "tarvoka_infantry_lod",0))==13 and not bool(
            detailed.get_meta("tarvoka_infantry_v3_tactical_identity",false)),
            role+" returns to original LOD13 detailed soldier")
        must(view_camera!=null and view_camera.size<5.5,
            role+" detail mode restores near camera")
        studio.call("_on_faction",0)
        var final_soldier: Node3D=studio.get("model_root") as Node3D
        var original_badge: MeshInstance3D=final_soldier.find_child(
            "V2_FaccionPechoArticulada",true,false) as MeshInstance3D
        var original_mat: StandardMaterial3D=(
            original_badge.material_override as StandardMaterial3D
            if original_badge!=null else null)
        must(original_mat!=null and original_mat.albedo_color.is_equal_approx(
            Models.faction_paint_color(0)),
            role+" hero colors restore exactly after switching factions")
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
        print("PASS INFANTRY V2 SAME STUDIO: 6 roles, 8-faction repaint, V1/V2, LOD8/13 camera, 360 orbit, original shared scene")
        quit(0)
