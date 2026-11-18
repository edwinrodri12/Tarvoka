extends SceneTree

# Real original Godot 4.3 V59/V60 same camera comparisons, 14 PNGs.
# Reveal what user sees at actual game zoom, plus closeups of 360-degree
# rubber mold: no generative mockups or external reference replacement.
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const OUT="res://build/qa/g13-v60"
var errors:int=0
var frames:Array[Dictionary]=[]
var deltas:Dictionary={}

func check(ok:bool,description:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V60 authentic Godot tire visibility: "+description)

func _initialize()->void:
    call_deferred("_run")

func _view(studio:Control,eye:Vector3,target:Vector3,size:float)->void:
    var cam:=studio.get("camera") as Camera3D
    if cam==null:
        return
    cam.position=eye
    cam.size=size
    cam.look_at(target,Vector3.UP)

func _capture(studio:Control,name:String,lod:int,ver:String)->void:
    var viewport:=studio.get("_viewport") as SubViewport
    var cam:=studio.get("camera") as Camera3D
    check(viewport!=null and cam!=null,"live 3D viewport and camera")
    if viewport==null or cam==null:
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture:Image=viewport.get_texture().get_image()
    check(picture!=null,"software GL texture should expose pixels")
    if picture==null:
        return
    var file:String=OUT.path_join(name+".png")
    check(picture.save_png(ProjectSettings.globalize_path(file))==OK,
        "persist actual native Godot image "+name)
    frames.append({
        "file":name+".png","lod":lod,"revision":ver,
        "ortho":cam.size,
        "cam":[cam.position.x,cam.position.y,cam.position.z]})
    print("G13 V60 ACTUAL 3D FRAME: "+name)

func _changed(first:String,second:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(first+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(second+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var hits:int=0
    for y in range(0,a.get_height(),2):
        for x in range(0,a.get_width(),2):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.10:
                hits+=1
    return hits

func _pair(studio:Control,model:Node3D,scope:String,lod:int)->void:
    var before:String="%02d-%s-old-v59" % [lod,scope]
    var after:String="%02d-%s-new-v60" % [lod,scope]
    check(V60.show_finish(model,false),"reveal OLD V59 scattered rubber "+scope)
    await _capture(studio,before,lod,"V59 segmented pads")
    check(V60.show_finish(model,true),"restore V60 closed tread "+scope)
    await _capture(studio,after,lod,"V60 continuous tire")
    var pixels:int=_changed(before,after)
    deltas["%d-%s" % [lod,scope]]=pixels
    check(pixels>=15,
        "changed REAL 3D wheel pixels at %s LOD%d: %d" % [
            scope,lod,pixels])
    print("G13 V60 REAL V59/V60 PIXELS %s LOD%d: %d" % [
        scope,lod,pixels])

func _run()->void:
    var scene:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(scene!=null,"actual existing G13InspectionStudio")
    if scene==null:
        quit(1)
        return
    var studio:=scene.instantiate() as Control
    root.size=Vector2i(1280,720)
    root.add_child(studio)
    await process_frame
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"capture folder")
    for lod in [13,8]:
        studio.set("_preview_detail",lod)
        studio.call("_display_role","aa_mobile")
        await process_frame
        var model:=studio.get("model_root") as Node3D
        check(model!=null and bool(model.get_meta(V60.FLAG,false)),
            "V60 installed in native original model LOD%d" % lod)
        if model==null or not bool(model.get_meta(V60.FLAG,false)):
            studio.queue_free()
            quit(1)
            return
        studio.call("_inspect_view","iso")
        await _pair(studio,model,"game-zoom",lod)
        _view(studio,Vector3(-3.7,1.44,-0.30),
            Vector3(-0.85,0.33,-0.85),1.40)
        await _pair(studio,model,"tread-close",lod)
        _view(studio,Vector3(3.75,2.10,1.90),
            Vector3(0.84,0.33,0.85),1.60)
        await _pair(studio,model,"rear-wheel-close",lod)
    var picker:=studio.get("faction_picker") as OptionButton
    check(picker!=null,"real faction dropdown")
    if picker!=null:
        studio.set("_preview_detail",13)
        for faction in [3,7]:
            picker.select(faction)
            studio.call("_display_role","aa_mobile")
            await process_frame
            var model:=studio.get("model_root") as Node3D
            check(model!=null and bool(model.get_meta(V60.FLAG,false)),
                "faction %d gets actual closed 3D tread" % faction)
            studio.call("_inspect_view","iso")
            await _capture(studio,"13-faction-%d-v60" % faction,
                13,"V60 color/tyre")
    check(frames.size()==14,"14 native Godot 3D frames")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g13-v60-manifest.json")),FileAccess.WRITE)
    check(manifest!=null,"native 3D QA manifest")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "revision":"V60 actual continuous rolling tire",
            "reference":"P06 Bastion 160 circumference lugs",
            "same_camera_comparison":true,
            "original_godot_renderer":true,
            "not_final_approved":true,
            "pixels_changed":deltas,
            "frames":frames,
            "errors":errors
        },"  "))
        manifest.close()
    studio.queue_free()
    await process_frame
    await process_frame
    if errors==0:
        print("PASS G13 V60 NATIVE 3D VISIBILITY: 14 real Godot frames, six same-camera P06-quality circumferential tread comparisons on LOD13 and LOD8")
    quit(1 if errors>0 else 0)
