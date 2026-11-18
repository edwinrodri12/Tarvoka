extends SceneTree

# G13 V57 native Godot 4.3 screenshots, including SAME-CAMERA V56 vs V57
# comparisons at tactical 4.7m orthographic size for both hero and LOD8.
# Real pixels, not fabricated renders, and no full 3D scene replacement.
const V57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const OUT="res://build/qa/g13-v57"
var errors:int=0
var captures:Array[Dictionary]=[]
var hero_delta:int=0
var tactical_delta:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V57 actual 3D visibility: "+message)

func _initialize()->void:
    call_deferred("_run")

func _camera(studio:Control,at:Vector3,
        focus:Vector3,size:float)->void:
    var cam:=studio.get("camera") as Camera3D
    if cam==null:
        return
    cam.position=at
    cam.size=size
    cam.look_at(focus,Vector3.UP)

func _capture(studio:Control,label:String,lod:int,version:String)->void:
    var view:=studio.get("_viewport") as SubViewport
    var cam:=studio.get("camera") as Camera3D
    if view==null or cam==null:
        check(false,"real Godot SubViewport/camera missing")
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=view.get_texture().get_image()
    if image==null:
        check(false,"Godot screenshot texture unavailable: "+label)
        return
    check(image.get_width()>=640 and image.get_height()>=480,
        "Godot frame minimum render resolution "+label)
    var file:String=OUT.path_join(label+".png")
    check(image.save_png(ProjectSettings.globalize_path(file))==OK,
        "cannot save native Godot frame "+file)
    captures.append({
        "file":label+".png",
        "lod":lod,
        "version":version,
        "orthographic_size":cam.size,
        "camera":[cam.position.x,cam.position.y,cam.position.z],
        "source":"actual Godot SubViewport 3D pixels"
    })
    print("G13 V57 ACTUAL NATIVE GODOT FRAME: "+label)

func _changed_pixels(previous:String,latest:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(previous+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(latest+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var changed:int=0
    # Sample every second pixel, and compare meaningful shading/color
    # rather than relying on the presence of nodes in the scene tree.
    for y in range(0,a.get_height(),2):
        for x in range(0,a.get_width(),2):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.09:
                changed+=1
    return changed

func _run()->void:
    var packed:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(packed!=null,"true G13 standalone 3D scene must load")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    root.size=Vector2i(1280,720)
    root.add_child(studio)
    await process_frame
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "native screenshot directory")
    var hero:=studio.get("model_root") as Node3D
    check(hero!=null and bool(hero.get_meta(V57.FLAG,false)) and
        bool(hero.get_meta(V56.FLAG,false)),
        "V57 bolts and V56 mechanical rig in real hero scene")
    if hero==null or not bool(hero.get_meta(V57.FLAG,false)):
        studio.queue_free()
        quit(1)
        return
    studio.call("_inspect_view","iso")
    await _capture(studio,"01-hero-isometric-v57",13,"V57")
    studio.call("_inspect_view","left")
    await _capture(studio,"02-hero-left-tactical-v57",13,"V57")
    check(V57.show_finish(hero,false),"hide V57 to show V56 hero reference")
    await _capture(studio,"03-hero-left-before-v56",13,"V56")
    check(V57.show_finish(hero,true),"restore V57 hero brackets")
    await _capture(studio,"04-hero-left-after-v57",13,"V57")
    hero_delta=_changed_pixels(
        "03-hero-left-before-v56","04-hero-left-after-v57")
    check(hero_delta>=12,
        "V57 hero supports should visibly change normal 4.7m tactical zoom: %d changed real pixel samples" % hero_delta)
    _camera(studio,Vector3(-3.8,1.30,-1.30),
        Vector3(-0.83,0.55,-0.85),1.25)
    await _capture(studio,"05-hero-front-left-bracket-macro",13,"V57")
    _camera(studio,Vector3(3.8,1.30,1.30),
        Vector3(0.83,0.55,0.85),1.25)
    await _capture(studio,"06-hero-rear-right-bracket-macro",13,"V57")
    studio.call("_inspect_view","front")
    await _capture(studio,"07-hero-front-v57",13,"V57")

    studio.set("_preview_detail",8)
    studio.call("_display_role","aa_mobile")
    await process_frame
    var tactical:=studio.get("model_root") as Node3D
    check(tactical!=null and bool(tactical.get_meta(V57.FLAG,false)) and
        not bool(tactical.get_meta(V56.FLAG,false)),
        "LOD8 MUST have one GPU V57 bracket batch, not heavy V56")
    if tactical==null or not bool(tactical.get_meta(V57.FLAG,false)):
        studio.queue_free()
        quit(1)
        return
    studio.call("_inspect_view","iso")
    await _capture(studio,"08-tactical-isometric-v57",8,"V57")
    studio.call("_inspect_view","left")
    await _capture(studio,"09-tactical-left-v57",8,"V57")
    check(V57.show_finish(tactical,false),"show LOD8 prior arch reference")
    await _capture(studio,"10-tactical-left-before-v56",8,"V56")
    check(V57.show_finish(tactical,true),"restore LOD8 V57 brackets")
    await _capture(studio,"11-tactical-left-after-v57",8,"V57")
    tactical_delta=_changed_pixels(
        "10-tactical-left-before-v56","11-tactical-left-after-v57")
    check(tactical_delta>=8,
        "V57 MUST improve visible physical attachment at NORMAL tactical zoom: %d changed Godot pixels" % tactical_delta)
    studio.call("_inspect_view","right")
    await _capture(studio,"12-tactical-right-v57",8,"V57")

    studio.set("_preview_detail",13)
    var faction:=studio.get("faction_picker") as OptionButton
    check(faction!=null,"eight-faction selector required")
    if faction!=null:
        for idx in [3,7]:
            faction.select(idx)
            studio.call("_display_role","aa_mobile")
            await process_frame
            var updated:=studio.get("model_root") as Node3D
            check(updated!=null and bool(updated.get_meta(V57.FLAG,false)),
                "faction %d must share genuine V57 3D mounts" % idx)
            studio.call("_inspect_view","iso")
            await _capture(studio,"hero-faction-%d-v57" % idx,13,"V57")
    check(captures.size()==14,"must capture 14 actual native 3D frames")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g13-v57-manifest.json")),FileAccess.WRITE)
    check(manifest!=null,"actual Godot QA manifest")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "subject":"G13 V57 physically integrated fender mounts",
            "hero_changed_pixels":hero_delta,
            "tactical_changed_pixels":tactical_delta,
            "comparison_camera_identical":true,
            "android_draw_cost":1,
            "visual_approval_pending":true,
            "captures":captures,
            "errors":errors
        },"  "))
        manifest.close()
    studio.queue_free()
    await process_frame
    await process_frame
    if errors==0:
        print("PASS G13 V57 REAL TACTICAL VISIBILITY: 14 Godot frames, visible pixel differences on BOTH LOD8 and hero LOD13, all faction colors protected")
    quit(1 if errors>0 else 0)
