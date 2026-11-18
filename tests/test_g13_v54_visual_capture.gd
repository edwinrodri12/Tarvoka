extends SceneTree

# Real Godot native offscreen 3D frames (not synthesized mockup).
# Captures identical wheel cameras before/after V54 rubber sculpture.
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
const V53=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const OUT="res://build/qa/g13-v54"
var failures:int=0
var shots:Array[Dictionary]=[]

func verify(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V54 native visual: "+message)

func _initialize()->void:
    call_deferred("_run")

func _capture(studio:Control,name:String,mode:String)->void:
    var view:=studio.get("_viewport") as SubViewport
    var cam:=studio.get("camera") as Camera3D
    verify(view!=null and cam!=null,"offscreen camera needed for "+name)
    if view==null or cam==null:
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=view.get_texture().get_image()
    verify(img!=null and img.get_width()>=640 and img.get_height()>=480,
        "real Godot 3D frame missing: "+name)
    if img==null:
        return
    var file:String=OUT.path_join(name+".png")
    verify(img.save_png(ProjectSettings.globalize_path(file))==OK,
        "failed to save real Godot screenshot: "+file)
    shots.append({
        "file":name+".png",
        "mode":mode,
        "width":img.get_width(),
        "height":img.get_height(),
        "camera_position":[cam.position.x,cam.position.y,cam.position.z],
        "orthographic_size":cam.size
    })
    print("G13 V54 ACTUAL GODOT FRAME: "+file)

func _camera(studio:Control,cam_pos:Vector3,where:Vector3,
        size:float)->void:
    var cam:=studio.get("camera") as Camera3D
    if cam==null:
        return
    cam.position=cam_pos
    cam.size=size
    cam.look_at(where,Vector3.UP)

func _run()->void:
    var packed:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    verify(packed!=null,"standalone G13 Godot inspection scene missing")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    verify(studio!=null,"cannot instantiate actual G13 Studio")
    if studio==null:
        quit(1)
        return
    root.size=Vector2i(1280,720)
    root.add_child(studio)
    await process_frame
    var directory:String=ProjectSettings.globalize_path(OUT)
    verify(DirAccess.make_dir_recursive_absolute(directory)==OK,
        "cannot create native screenshot directory")
    var model:=studio.get("model_root") as Node3D
    verify(model!=null and bool(model.get_meta(V54.FLAG,false)),
        "full V54 native tyre model did not load")
    if model==null or not bool(model.get_meta(V54.FLAG,false)):
        studio.queue_free()
        quit(1)
        return
    verify(bool(model.get_meta(V53.FLAG,false)),
        "V53 physically based coating should remain installed")
    studio.call("_inspect_view","iso")
    await _capture(studio,"hero-isometric","V54")
    studio.call("_inspect_view","left")
    await _capture(studio,"hero-side","V54")
    studio.call("_inspect_view","front")
    await _capture(studio,"hero-front","V54")
    # Exact physical wheel closeups, no image crop/paint fakery.
    _camera(studio,Vector3(-3.2,0.94,1.67),
        Vector3(-0.85,0.33,0.85),1.10)
    await _capture(studio,"rear-left-tyre-close","V54")
    verify(V54.show_finish(model,false),
        "cannot display V53 tire geometry for exact reference")
    await _capture(studio,"rear-left-tyre-before-v53","V53")
    verify(V54.show_finish(model,true),
        "cannot restore V54 tire mesh after reference")
    await _capture(studio,"rear-left-tyre-after-v54","V54")
    _camera(studio,Vector3(-3.2,1.16,-1.60),
        Vector3(-0.85,0.33,-0.85),1.10)
    await _capture(studio,"front-left-tyre-close","V54")
    _camera(studio,Vector3(3.2,0.94,1.67),
        Vector3(0.85,0.33,0.85),1.10)
    await _capture(studio,"rear-right-tyre-close","V54")
    studio.call("_inspect_view","under")
    await _capture(studio,"undercarriage","V54")
    # Confirm paint of other factions on same genuine 3D chassis.
    var faction:=studio.get("faction_picker") as OptionButton
    verify(faction!=null,"eight-faction selector absent")
    if faction!=null:
        for i in [3,7]:
            faction.select(i)
            studio.call("_display_role","aa_mobile")
            await process_frame
            model=studio.get("model_root") as Node3D
            verify(model!=null and bool(model.get_meta(V54.FLAG,false)),
                "faction %d must use identical V54 tire sculpture" % i)
            studio.call("_inspect_view","iso")
            await _capture(studio,"hero-faction-%d" % i,"V54")
    var manifest:=FileAccess.open(
        directory.path_join("g13-v54-manifest.json"),FileAccess.WRITE)
    verify(manifest!=null,"cannot write native model screenshot manifest")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "model":"G13 V54 native 3D rubber sculpt",
            "renderer":"Godot 4.3 GL compatibility",
            "material_version":"V53 physically based rubber and metal",
            "hero_only":true,
            "visual_approval_pending":true,
            "shots":shots,
            "failures":failures
        },"  "))
        manifest.close()
    verify(shots.size()==11,"expected eleven real rendered frames")
    studio.queue_free()
    await process_frame
    await process_frame
    if failures==0:
        print("PASS G13 V54 NATIVE VISUAL: 11 genuine Godot shots, before/after tires, 3 factions")
    quit(1 if failures>0 else 0)
