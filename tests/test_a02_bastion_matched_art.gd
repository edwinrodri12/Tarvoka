extends SceneTree
# Optional art-review harness. No game state, physics, or production model changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const OUTPUT="res://build/qa/a02-bastion-matched"
const FRAME=Vector2i(960,680)
var failures:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("Matched art review: "+message)

func _initialize()->void:
    call_deferred("_run")

func _visible_bounds(model:Node3D)->AABB:
    var result:=AABB()
    var first:bool=true
    for node in model.find_children("*","MeshInstance3D",true,false):
        var piece:=node as MeshInstance3D
        if piece.mesh==null or not piece.is_visible_in_tree():
            continue
        var bounds:AABB=piece.global_transform*piece.mesh.get_aabb()
        result=bounds if first else result.merge(bounds)
        first=false
    return result

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))==OK,"output directory")
    var vp:=SubViewport.new()
    vp.size=FRAME
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#edf5fc")
    env.ambient_light_energy=0.72
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-30,0)
    light.light_energy=1.7
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.keep_aspect=Camera3D.KEEP_HEIGHT
    vp.add_child(camera)
    camera.current=true
    var entries:Array[Dictionary]=[]
    var views:Array=[
        ["front_iso",Vector3(3.3,2.25,-4.0),Vector3.UP],
        ["rear_iso",Vector3(-3.3,2.25,4.0),Vector3.UP],
        ["side",Vector3(4.0,0.75,0.0),Vector3.UP],
        ["top",Vector3(0.0,5.0,0.0),Vector3.FORWARD]]
    for faction in [0,3,7]:
        for role in ["apc","fpv"]:
            var model:Node3D=Models.build(role,faction,true,13)
            check(model!=null,"native factory "+role)
            if model==null:
                continue
            vp.add_child(model)
            await process_frame
            var bounds:AABB=_visible_bounds(model)
            check(bounds.has_volume(),"visible native bounds "+role)
            if not bounds.has_volume():
                vp.remove_child(model)
                model.free()
                continue
            var center:Vector3=bounds.get_center()
            for view in views:
                var direction:Vector3=view[1]
                camera.position=center+direction.normalized()*maxf(5.0,bounds.size.length()*3.0)
                camera.far=maxf(100.0,bounds.size.length()*10.0)
                camera.size=maxf(1.0,bounds.size.length())
                camera.look_at(center,view[2])
                # Fit projected world AABB into an 84% safe rectangle.
                # Use different orthographic scale for the two different
                # subjects; never change their scene geometry or transforms.
                var peak:float=0.0
                for i in range(8):
                    var pixel:Vector2=camera.unproject_position(bounds.get_endpoint(i))
                    peak=maxf(peak,absf(pixel.x-FRAME.x*0.5)/(FRAME.x*0.42))
                    peak=maxf(peak,absf(pixel.y-FRAME.y*0.5)/(FRAME.y*0.42))
                camera.size*=maxf(peak,0.01)
                for i in range(8):
                    var pixel:Vector2=camera.unproject_position(bounds.get_endpoint(i))
                    check(pixel.x>=FRAME.x*0.075 and pixel.x<=FRAME.x*0.925 and
                        pixel.y>=FRAME.y*0.075 and pixel.y<=FRAME.y*0.925,"full subject in frame "+role)
                await process_frame
                await process_frame
                await process_frame
                var image:Image=vp.get_texture().get_image()
                var filename:String="%s-f%d-%s.png"%[role,faction,str(view[0])]
                var path:String=OUTPUT+"/"+filename
                if image==null or image.is_empty():
                    check(false,"empty capture "+filename)
                    continue
                check(image.get_size()==FRAME,"capture resolution "+filename)
                var saved:bool=image.save_png(path)==OK
                check(saved,"save "+filename)
                if saved:
                    entries.append({"role":role,"faction":faction,"view":str(view[0]),
                        "file":filename,"sha256":FileAccess.get_sha256(path),
                        "camera_size":camera.size,"bounds_size":[bounds.size.x,bounds.size.y,bounds.size.z]})
            vp.remove_child(model)
            model.free()
    check(entries.size()==24,"24 matched studio views")
    var report:=FileAccess.open(OUTPUT+"/matched-review.json",FileAccess.WRITE)
    check(report!=null,"review report")
    if report!=null:
        report.store_string(JSON.stringify({"resolution":[FRAME.x,FRAME.y],
            "normalized_frame":true,"same_lighting":true,
            "purpose":"qualitative native art comparison; not physical size, FPS or aesthetic score",
            "frames":entries,"passed":failures==0},"  "))
        report.close()
    vp.queue_free()
    quit(0 if failures==0 else 1)
