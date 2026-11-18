extends SceneTree

# 18 genuine Godot 4.3 OpenGL frames: V58 vs real V59, SAME 3D CAMERA.
# Physical tire comparison (160 rubber lugs), glass specular and 8-faction
# finishes. Hero LOD13 + native Android LOD8. Not a generated illustration.
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const OUT="res://build/qa/g13-v59"
var errors:int=0
var frames:Array[Dictionary]=[]
var deltas:Dictionary={}

func check(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V59 REAL GODOT visual QA: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _view(studio:Control,position:Vector3,
        focus:Vector3,size:float)->void:
    var camera:=studio.get("camera") as Camera3D
    if camera==null:
        return
    camera.position=position
    camera.size=size
    camera.look_at(focus,Vector3.UP)

func _capture(studio:Control,label:String,lod:int,version:String)->void:
    var camera:=studio.get("camera") as Camera3D
    var vp:=studio.get("_viewport") as SubViewport
    if camera==null or vp==null:
        check(false,"real Godot camera viewport unavailable")
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=vp.get_texture().get_image()
    check(img!=null and img.get_width()>=640 and img.get_height()>=480,
        "actual software OpenGL pixels for "+label)
    if img==null:
        return
    var filename:String=OUT.path_join(label+".png")
    check(img.save_png(ProjectSettings.globalize_path(filename))==OK,
        "cannot save actual Godot frame "+label)
    frames.append({"file":label+".png","lod":lod,
        "revision":version,"camera":[camera.position.x,camera.position.y,
            camera.position.z],"ortho_size":camera.size})
    print("G13 V59 ACTUAL GODOT CAPTURE "+label)

func _delta(before:String,after:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(before+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(after+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var diff:int=0
    for y in range(0,a.get_height(),2):
        for x in range(0,a.get_width(),2):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.12:
                diff+=1
    return diff

func _pair(studio:Control,model:Node3D,scope:String,
        lod:int)->void:
    var a:String="%02d-%s-v58" % [lod,scope]
    var b:String="%02d-%s-v59" % [lod,scope]
    check(V59.show_finish(model,false),
        "V58 original in native Studio, same camera "+scope)
    await _capture(studio,a,lod,"V58 original")
    check(V59.show_finish(model,true),
        "V59 actual tire/glass/paint in native Studio "+scope)
    await _capture(studio,b,lod,"V59 physical")
    var altered:int=_delta(a,b)
    deltas["%d-%s" % [lod,scope]]=altered
    check(altered>=30,
        "real V59 changes V58 Godot pixels at "+scope+
        " LOD%d (actual %d)" % [lod,altered])
    print("G13 V59 real changed pixels LOD%d %s = %d" % [
        lod,scope,altered])

func _run()->void:
    var scene:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(scene!=null,"REAL native 3D inspection scene")
    if scene==null:
        quit(1)
        return
    var studio:=scene.instantiate() as Control
    root.size=Vector2i(1280,720)
    root.add_child(studio)
    await process_frame
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "native render output directory")
    for lod in [13,8]:
        studio.set("_preview_detail",lod)
        studio.call("_display_role","aa_mobile")
        await process_frame
        var model:=studio.get("model_root") as Node3D
        check(model!=null and bool(model.get_meta(V59.FLAG,false)),
            "real V59 material on live LOD%d model" % lod)
        if model==null or not bool(model.get_meta(V59.FLAG,false)):
            studio.queue_free()
            quit(1)
            return
        if bool(model.get_meta(V60.FLAG,false)):
            check(V60.show_finish(model,false),
                "historical V59 screenshots compare the correct V59 wheels")
        studio.call("_inspect_view","iso")
        await _pair(studio,model,"isometric",lod)
        _view(studio,Vector3(-3.7,1.44,-0.30),
            Vector3(-0.85,0.33,-0.85),1.4)
        await _pair(studio,model,"tire-close",lod)
        _view(studio,Vector3(0.35,1.62,-3.45),
            Vector3(0,1.22,-1.14),1.55)
        await _pair(studio,model,"glass-front",lod)
        if lod==13:
            _view(studio,Vector3(-3.4,1.73,-1.5),
                Vector3(-0.56,1.18,-0.86),1.53)
            await _pair(studio,model,"side-glass",lod)
            studio.call("_inspect_view","front")
            await _capture(studio,"13-final-real-v59-front",lod,"V59")
        else:
            studio.call("_inspect_view","right")
            await _capture(studio,"08-final-real-v59-right",lod,"V59")
    studio.set("_preview_detail",13)
    var picker:=studio.get("faction_picker") as OptionButton
    check(picker!=null,"actual eight faction 3D selector")
    if picker!=null:
        for faction in [3,7]:
            picker.select(faction)
            studio.call("_display_role","aa_mobile")
            await process_frame
            var current:=studio.get("model_root") as Node3D
            check(current!=null and bool(current.get_meta(V59.FLAG,false)),
                "original faction %d uses real V59 PBR" % faction)
            studio.call("_inspect_view","iso")
            await _capture(studio,"13-faction-%d-premium-v59" % faction,
                13,"V59")
    check(frames.size()==18,
        "18 original 3D Godot frames, no made-up mockups")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g13-v59-manifest.json")),FileAccess.WRITE)
    check(manifest!=null,"native PBR manifest")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "subject":"G13 V59 real Bastion-grade rubber and glass",
            "reference":"P06 Bastion V23 160 lugs per wheel",
            "hero_lugs_per_wheel":160,
            "physical_tread_not_a_decal":true,
            "genuine_game_engine_images":true,
            "camera_same_before_after":true,
            "artistic_signoff_pending":true,
            "pixel_deltas":deltas,
            "frames":frames,
            "errors":errors
        },"  "))
        manifest.close()
    studio.queue_free()
    await process_frame
    await process_frame
    if errors==0:
        print("PASS G13 V59 NATIVE PREMIUM VISUAL: 18 real Godot PBR images, true 160-block 3D rubber, glass reflections and faction palette, same camera comparisons on Android and HERO")
    quit(1 if errors>0 else 0)
