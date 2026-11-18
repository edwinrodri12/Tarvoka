extends SceneTree

# Real Godot native offscreen 3D frames (not synthesized mockup).
# Captures identical wheel cameras before/after V55 metal sculpture.
const V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const V54=preload("res://scripts/ui/G13MaterialRealismV54.gd")
const OUT="res://build/qa/g13-v55"
var failures:int=0
var shots:Array[Dictionary]=[]

func verify(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V55 native visual: "+message)

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
    print("G13 V55 ACTUAL GODOT FRAME: "+file)

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
    verify(model!=null and bool(model.get_meta(V55.FLAG,false)),
        "full V55 native panel model did not load")
    if model==null or not bool(model.get_meta(V55.FLAG,false)):
        studio.queue_free()
        quit(1)
        return
    verify(bool(model.get_meta(V54.FLAG,false)),
        "V54 physically based coating should remain installed")
    studio.call("_inspect_view","iso")
    await _capture(studio,"hero-isometric","V55")
    studio.call("_inspect_view","left")
    await _capture(studio,"hero-side","V55")
    studio.call("_inspect_view","front")
    await _capture(studio,"hero-front","V55")
    # Exact physical wheel closeups, no image crop/paint fakery.
    _camera(studio,Vector3(-2.40,1.05,0.40),
        Vector3(-0.72,0.80,0.06),1.10)
    await _capture(studio,"rear-left-panel-close","V55")
    verify(V55.show_finish(model,false),
        "cannot display V54 panel microfinish for exact reference")
    await _capture(studio,"rear-left-panel-before-v53","V54")
    verify(V55.show_finish(model,true),
        "cannot restore V55 tire mesh after reference")
    await _capture(studio,"rear-left-panel-after-v55","V55")
    _camera(studio,Vector3(-2.40,1.07,-0.60),
        Vector3(-0.72,0.80,-0.15),1.10)
    await _capture(studio,"front-left-panel-close","V55")
    _camera(studio,Vector3(2.40,1.05,0.40),
        Vector3(0.72,0.80,0.06),1.10)
    await _capture(studio,"rear-right-panel-close","V55")
    studio.call("_inspect_view","under")
    await _capture(studio,"undercarriage","V55")
    # Confirm paint of other factions on same genuine 3D chassis.
    var faction:=studio.get("faction_picker") as OptionButton
    verify(faction!=null,"eight-faction selector absent")
    if faction!=null:
        for i in [3,7]:
            faction.select(i)
            studio.call("_display_role","aa_mobile")
            await process_frame
            model=studio.get("model_root") as Node3D
            verify(model!=null and bool(model.get_meta(V55.FLAG,false)),
                "faction %d must use identical V55 tire sculpture" % i)
            studio.call("_inspect_view","iso")
            await _capture(studio,"hero-faction-%d" % i,"V55")
    var manifest:=FileAccess.open(
        directory.path_join("g13-v55-manifest.json"),FileAccess.WRITE)
    verify(manifest!=null,"cannot write native model screenshot manifest")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "model":"G13 V55 native 3D metal sculpt",
            "renderer":"Godot 4.3 GL compatibility",
            "material_version":"V54 physically based metal and metal",
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
        print("PASS G13 V55 NATIVE VISUAL: 11 genuine Godot shots, before/after tires, 3 factions")
    quit(1 if failures>0 else 0)
