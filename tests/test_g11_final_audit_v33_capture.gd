extends SceneTree

# Six actual GL snapshots from the corrected Android stress scene:
# tactical G11 LOD8/LOD10 x 8/32/64 visible models. No FPS claims from CI.
const Lab=preload("res://scripts/ui/G11AndroidPerfLab.gd")
const Audit=preload("res://scripts/ui/G11FinalAuditV33.gd")
var saved: int=0
var errors: int=0

func _check(ok: bool,label: String)->void:
    if not ok:
        errors+=1
        push_error("G11 V33 native fleet capture: "+label)

func _capture(view: SubViewport,out: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:=view.get_texture().get_image()
    if image!=null and not image.is_empty() and (
            image.save_png(out.path_join(name))==OK):
        saved+=1
    else:
        _check(false,"could not render native fleet "+name)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder: String=OS.get_environment("G11_V33_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g11-v33-actual-tactical-lods"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create artifact folder")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,640)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d=Viewport.MSAA_2X
    root.add_child(viewport)
    var lab:=Lab.new()
    viewport.add_child(lab)
    await process_frame
    for amount in [8,32,64]:
        for level in [8,10]:
            lab.set_scenario(amount,level)
            await process_frame
            _check(lab._models.size()==amount and lab._lod_validated and (
                    lab._units_validated==amount),
                "%d real tactical models LOD%d, not hero" % [amount,level])
            for model in lab._models:
                _check(Audit.verify_tactical_model(model,level),
                    "all six renderings pass source-model audit")
            await _capture(viewport,folder,"g11_v33_%02d_real_units_lod%d.png" % [
                amount,level])
    _check(saved==6,"six actual 3D fleet frames, no render mockups")
    lab.queue_free()
    if errors>0:
        push_error("G11 V33 tactical Android LOD render FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V33 CAPTURE: six native Godot GL fleet views of 8/32/64 actual tactical LOD8/10 G11s, no hero models and no invented phone FPS")
    quit(0)
