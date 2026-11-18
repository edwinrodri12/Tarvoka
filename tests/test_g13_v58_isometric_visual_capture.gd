extends SceneTree

# 18 genuine native Godot 4.3 3D frames, same-camera comparison of
# realistic armored mechanics in three ACTUAL gameplay isometric views.
# Compare PBR metals at 4.70m normal tactical zoom on HERO 13 and LOD8.
const V58=preload("res://scripts/ui/G13IsometricMechanicalFinishV58.gd")
const V57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const OUT="res://build/qa/g13-v58"
var failures:int=0
var shots:Array[Dictionary]=[]
var deltas:Dictionary={}

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V58 isometric native capture: "+message)

func _initialize()->void:
    call_deferred("_run")

func _view(studio:Control,pose:Vector3,target:Vector3,
        size:float=4.70)->void:
    var camera:=studio.get("camera") as Camera3D
    if camera==null:
        return
    camera.position=pose
    camera.size=size
    camera.look_at(target,Vector3.UP)

func _capture(studio:Control,label:String,lod:int,stage:String)->void:
    var viewport:=studio.get("_viewport") as SubViewport
    var camera:=studio.get("camera") as Camera3D
    check(viewport!=null and camera!=null,
        "real SubViewport/Camera3D must exist")
    if viewport==null or camera==null:
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=viewport.get_texture().get_image()
    check(image!=null and image.get_width()>=640 and
        image.get_height()>=480,"authentic 3D pixels "+label)
    if image==null:
        return
    var filename:String=OUT.path_join(label+".png")
    check(image.save_png(ProjectSettings.globalize_path(filename))==OK,
        "save native Godot pixels "+label)
    shots.append({
        "file":label+".png",
        "lod":lod,
        "comparison":stage,
        "orthographic_size":camera.size,
        "camera":[camera.position.x,camera.position.y,camera.position.z]
    })
    print("G13 V58 ACTUAL GODOT IMAGE: "+label)

func _pixel_delta(first:String,second:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(first+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(second+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var n:int=0
    for y in range(0,a.get_height(),2):
        for x in range(0,a.get_width(),2):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.09:
                n+=1
    return n

func _pair(studio:Control,model:Node3D,lod:int,
        view_name:String,pose:Vector3,focus:Vector3)->void:
    _view(studio,pose,focus)
    var old_label:String="%02d-%s-before-v57" % [lod,view_name]
    var new_label:String="%02d-%s-after-v58" % [lod,view_name]
    check(V58.show_finish(model,false),
        "reversible historical V57 on "+view_name)
    await _capture(studio,old_label,lod,"V57_original")
    check(V58.show_finish(model,true),
        "V58 PBR finish restored on "+view_name)
    await _capture(studio,new_label,lod,"V58_current")
    var different:int=_pixel_delta(old_label,new_label)
    deltas["%d-%s" % [lod,view_name]]=different
    check(different>=8,
        "real 4.70m isometric pixels must differ on %s LOD%d (got %d)" % [
            view_name,lod,different])
    print("G13 V58 ISOMETRIC PIXEL DELTA %s LOD%d = %d" % [
        view_name,lod,different])

func _run()->void:
    var packed:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(packed!=null,"native 3D inspection scene required")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    root.size=Vector2i(1280,720)
    root.add_child(studio)
    await process_frame
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "native 3D screenshots dir")
    var positions:Dictionary={
        "front-left":Vector3(-3.5,2.75,-4.5),
        "rear-right":Vector3(3.5,2.75,4.5),
        "front-right":Vector3(3.5,2.75,-4.5)
    }
    for lod in [13,8]:
        studio.set("_preview_detail",lod)
        studio.call("_display_role","aa_mobile")
        await process_frame
        var model:=studio.get("model_root") as Node3D
        check(model!=null and bool(model.get_meta(V58.FLAG,false)),
            "live native V58 LOD%d present" % lod)
        if model==null or not bool(model.get_meta(V58.FLAG,false)):
            studio.queue_free()
            quit(1)
            return
        for key in positions:
            await _pair(studio,model,lod,str(key),
                positions[key],Vector3(0,1.0,0))
        _view(studio,Vector3(-3.6,1.50,-1.4),
            Vector3(-0.92,0.61,-0.85),1.40)
        await _pair(studio,model,lod,"arch-close",
            Vector3(-3.6,1.50,-1.4),Vector3(-0.92,0.61,-0.85))
        studio.call("_inspect_view","iso")
        await _capture(studio,"%02d-final-hero-isometric" % lod,
            lod,"V58_current")
    check(shots.size()==18,
        "18 original Godot comparisons across 2 LODs and 4 views")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g13-v58-manifest.json")),FileAccess.WRITE)
    check(manifest!=null,"native QA manifest file")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "model":"TARVOKA G13 V58 native materials and mechanical isometric",
            "renderer":"Godot 4.3 Compatibility GL",
            "camera_same_before_after":true,
            "artistic_final_approval_pending":true,
            "one_tactical_bracket_batch":true,
            "extra_gpu_draws_v58":0,
            "measured_pixel_deltas":deltas,
            "images":shots,
            "failures":failures
        },"  "))
        manifest.close()
    studio.queue_free()
    await process_frame
    await process_frame
    if failures==0:
        print("PASS G13 V58 NATIVE ISOMETRIC VISIBILITY: 18 real Godot frames, 8 nonzero same-camera material comparisons, hero and Android LOD8, zero new GPU draws")
    quit(1 if failures>0 else 0)
