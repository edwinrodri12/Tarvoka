extends SceneTree

# Godot 4.3 native GL screenshots for V56 mechanical connections.
# 12 genuine scene frames: suspension and azimuth with identical cameras
# before/after, no edited images or synthetic 3D proxy.
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const OUTPUT="res://build/qa/g13-v56"
var errors:int=0
var captures:Array[Dictionary]=[]

func check(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V56 actual Godot frame: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _frame(studio:Control,title:String,version:String)->void:
    var viewport:=studio.get("_viewport") as SubViewport
    var cam:=studio.get("camera") as Camera3D
    if viewport==null or cam==null:
        check(false,"no actual 3D viewport or camera")
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=viewport.get_texture().get_image()
    check(img!=null and img.get_width()>=640 and
        img.get_height()>=480,"real rendered pixels for "+title)
    if img==null:
        return
    var filename:String=ProjectSettings.globalize_path(
        OUTPUT.path_join(title+".png"))
    check(img.save_png(filename)==OK,"cannot save "+title)
    captures.append({"file":title+".png","version":version,
        "camera":[cam.position.x,cam.position.y,cam.position.z],
        "orthographic_size":cam.size})
    print("G13 V56 REAL GODOT FRAME: "+title)

func _view(studio:Control,at:Vector3,
        target:Vector3,zoom:float)->void:
    var cam:=studio.get("camera") as Camera3D
    if cam==null:
        return
    cam.position=at
    cam.size=zoom
    cam.look_at(target,Vector3.UP)

func _run()->void:
    var scene:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(scene!=null,"native G13 studio scene absent")
    if scene==null:
        quit(1)
        return
    var studio:=scene.instantiate() as Control
    root.size=Vector2i(1280,720)
    root.add_child(studio)
    await process_frame
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK,
        "capture folder missing")
    var model:=studio.get("model_root") as Node3D
    check(model!=null and bool(model.get_meta(V56.FLAG,false)) and
        bool(model.get_meta(V55.FLAG,false)),
        "native V56 and V55 model must exist in actual 3D scene")
    if model==null or not bool(model.get_meta(V56.FLAG,false)):
        studio.queue_free()
        quit(1)
        return
    studio.call("_inspect_view","iso")
    await _frame(studio,"hero-isometric","V56")
    studio.call("_inspect_view","left")
    await _frame(studio,"hero-left","V56")
    studio.call("_inspect_view","under")
    await _frame(studio,"hero-undercarriage","V56")

    # Suspension from underneath; shock ends fixed to V6 and V22 brackets.
    _view(studio,Vector3(-2.6,0.25,-1.15),
        Vector3(-0.57,0.34,-0.86),1.15)
    await _frame(studio,"front-left-damper-v56","V56")
    check(V56.show_finish(model,false),"V55 before compare")
    await _frame(studio,"front-left-damper-before-v55","V55")
    check(V56.show_finish(model,true),"V56 restore after compare")
    await _frame(studio,"front-left-damper-after-v56","V56")
    _view(studio,Vector3(2.65,0.18,1.45),
        Vector3(0.57,0.34,0.86),1.10)
    await _frame(studio,"rear-right-hydraulics-v56","V56")

    # Original turret azimuth ring, separate from original gun pitch.
    _view(studio,Vector3(2.45,2.33,1.90),
        Vector3(0,1.45,0.35),1.35)
    await _frame(studio,"turret-bearing-v56","V56")
    check(V56.show_finish(model,false),"V55 turret reference")
    await _frame(studio,"turret-bearing-before-v55","V55")
    check(V56.show_finish(model,true),"V56 turret band restoration")
    await _frame(studio,"turret-bearing-after-v56","V56")

    var faction:=studio.get("faction_picker") as OptionButton
    check(faction!=null,"eight faction dropdown missing")
    if faction!=null:
        for idx in [3,7]:
            faction.select(idx)
            studio.call("_display_role","aa_mobile")
            await process_frame
            var updated:=studio.get("model_root") as Node3D
            check(updated!=null and bool(updated.get_meta(V56.FLAG,false)),
                "faction %d must preserve V56 mechanical detail" % idx)
            studio.call("_inspect_view","iso")
            await _frame(studio,"hero-faction-%d" % idx,"V56")
    check(captures.size()==12,"expect 12 native 3D frames")
    var path:String=ProjectSettings.globalize_path(OUTPUT)
    var manifest:=FileAccess.open(path.path_join("g13-v56-manifest.json"),
        FileAccess.WRITE)
    check(manifest!=null,"native frame manifest unavailable")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "subject":"G13 V56 genuine Godot 4.3 suspension and turret 3D",
            "renderer":"Godot 4.3 Compatibility OpenGL",
            "source":"actual native G13InspectionStudio.tscn",
            "no_gameplay_changes":true,
            "visual_approval_pending":true,
            "captures":captures,
            "errors":errors
        },"  "))
        manifest.close()
    studio.queue_free()
    await process_frame
    await process_frame
    if errors==0:
        print("PASS G13 V56 NATIVE VISUAL: 12 real native Godot frames, suspension and turret same-camera references, factions 0/3/7")
    quit(1 if errors>0 else 0)
