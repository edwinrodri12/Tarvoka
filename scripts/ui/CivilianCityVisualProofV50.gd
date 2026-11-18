extends SceneTree

# TARVOKA V50: native Godot 4.3 city capture without any UI containers.
# FIX CONFIRMED BY V49 LOGS: the older studio SubViewport was resized below
# 300x200 by SubViewportContainer under --script mode. Keep the native
# procedural city builder, PBR materials, D0-D4 and all damage meshes.
# This produces 24 Godot images, not replacement artwork.
const Cities=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const EVIDENCE_DIR="res://build/city-v44-evidence"
const LEVELS=["Villa","Ciudad","Metropoli"]
const CAPTURE_SIZE=Vector2i(960,540)

func _initialize() -> void:
    call_deferred("_capture_all")

static func _image_diagnostics(img: Image) -> Dictionary:
    var width: int=img.get_width()
    var height: int=img.get_height()
    if width<1 or height<1:
        return {"nonempty":false,"coverage":0.0,"center_coverage":0.0,
            "variance":0.0,"framing_warning":true,
            "occupied_bbox":[0.0,0.0,0.0,0.0]}
    var base: Color=img.get_pixel(0,0)
    var samples: int=0
    var changed: int=0
    var center_samples: int=0
    var center_changed: int=0
    var brightness: float=0.0
    var brightness_sq: float=0.0
    var left: int=width
    var right: int=0
    var top: int=height
    var bottom: int=0
    for y in range(0,height,maxi(1,int(float(height)/30.0))):
        for x in range(0,width,maxi(1,int(float(width)/48.0))):
            var pixel: Color=img.get_pixel(x,y)
            var lum: float=0.2126*pixel.r+0.7152*pixel.g+0.0722*pixel.b
            brightness+=lum
            brightness_sq+=lum*lum
            samples+=1
            var center: bool=(
                x>=int(float(width)*0.20) and x<=int(float(width)*0.80)
                and y>=int(float(height)*0.15)
                and y<=int(float(height)*0.85))
            if center:
                center_samples+=1
            var difference: float=(
                absf(pixel.r-base.r)+absf(pixel.g-base.g)
                +absf(pixel.b-base.b))
            if difference>0.19:
                changed+=1
                left=mini(left,x)
                right=maxi(right,x)
                top=mini(top,y)
                bottom=maxi(bottom,y)
                if center:
                    center_changed+=1
    var average: float=brightness/maxf(1.0,float(samples))
    var variation: float=maxf(0.0,
        brightness_sq/maxf(1.0,float(samples))-average*average)
    var fraction: float=float(changed)/maxf(1.0,float(samples))
    var centered: float=float(center_changed)/maxf(
        1.0,float(center_samples))
    return {
        "nonempty":variation>=0.0004 and fraction>=0.025,
        "coverage":fraction,"center_coverage":centered,
        "variance":variation,"framing_warning":centered<0.02,
        "occupied_bbox":[
            float(left)/float(width) if changed>0 else 0.0,
            float(top)/float(height) if changed>0 else 0.0,
            float(right)/float(width) if changed>0 else 0.0,
            float(bottom)/float(height) if changed>0 else 0.0
        ]
    }

static func _camera_for(camera: Camera3D,
        tier: int,damage: int,reverse: bool) -> void:
    var low: bool=damage>=3
    var building_height: float=2.31 if tier==0 else (
        6.51 if tier==1 else 10.71)
    var target: Vector3=Vector3(0.0,
        0.90 if low else building_height*0.43,0.0)
    var azimuth: float=deg_to_rad(147.0 if reverse else 39.0)
    var elevation: float=deg_to_rad(39.0 if reverse else 45.0)
    var distance: float=34.0 if tier==2 else (
        29.0 if tier==1 else 26.0)
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=27.0 if tier==0 else 30.0 if tier==1 else 34.0
    var flat: float=cos(elevation)*distance
    camera.position=target+Vector3(
        sin(azimuth)*flat,sin(elevation)*distance,
        cos(azimuth)*flat)
    camera.look_at(target,Vector3.UP)

func _capture_all() -> void:
    var dir: String=ProjectSettings.globalize_path(EVIDENCE_DIR)
    if DirAccess.make_dir_recursive_absolute(dir)!=OK:
        push_error("V50: evidence output directory unavailable")
        quit(2)
        return

    # Direct SubViewport: fixed texture resolution independent of
    # Control/SubViewportContainer/window layout. Native GL 3D renderer.
    var viewport:=SubViewport.new()
    viewport.name="V50_CiudadNativaSinContenedorUI"
    viewport.size=CAPTURE_SIZE
    viewport.size_2d_override=CAPTURE_SIZE
    viewport.own_world_3d=true
    viewport.disable_3d=false
    viewport.transparent_bg=false
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)

    var lighting:=WorldEnvironment.new()
    var atmosphere:=Environment.new()
    atmosphere.background_mode=Environment.BG_COLOR
    atmosphere.background_color=Color("#374e5c")
    atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color=Color("#dae4e4")
    atmosphere.ambient_light_energy=0.65
    lighting.environment=atmosphere
    viewport.add_child(lighting)

    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-49.0,-33.0,0.0)
    sun.light_energy=1.22
    sun.shadow_enabled=true
    viewport.add_child(sun)

    var camera:=Camera3D.new()
    camera.name="CamaraV50Nativa"
    camera.near=0.10
    camera.far=180.0
    viewport.add_child(camera)
    camera.current=true

    await process_frame
    await RenderingServer.frame_post_draw

    var warnings: PackedStringArray=[
        "TARVOKA V50: native Godot 4.3 direct SubViewport, no UI dependency",
        "The camera and mesh use the real engine; no artistic approval is implied"
    ]
    var records: Array[Dictionary]=[]
    var errors: int=0
    var saved: int=0
    var failures: int=0
    for tier in range(3):
        for damage in range(5):
            var level: int=tier+1
            var model: Node3D=Cities.build_tactical(level,-1,damage,0)
            if model==null:
                failures+=1
                errors+=1
                warnings.append("%s D%d: NATIVE_MODEL_CREATION_FAILED" % [
                    LEVELS[tier],damage])
                continue
            viewport.add_child(model)
            var warnings_v42: PackedStringArray=model.get_meta(
                "city_v42_visual_warnings",PackedStringArray())
            var warnings_v43: PackedStringArray=model.get_meta(
                "city_v43_art_issues",PackedStringArray())
            var geometry_count: int=int(model.get_meta(
                "city_v42_warning_count",0))
            var finish_count: int=int(model.get_meta(
                "city_v43_issue_count",0))
            var mesh_count: int=Cities.drawable_count(model)
            if mesh_count<=0:
                errors+=1
                warnings.append("%s D%d: NO_VISIBLE_MESHES" % [
                    LEVELS[tier],damage])
            for is_reverse in ([false,true] if damage in [0,2,4] else [false]):
                _camera_for(camera,tier,damage,is_reverse)
                await process_frame
                await RenderingServer.frame_post_draw
                await process_frame
                await RenderingServer.frame_post_draw
                var result: Image=viewport.get_texture().get_image()
                var suffix: String="_reverse" if is_reverse else ""
                var filename: String="%s_D%d%s.png" % [
                    LEVELS[tier],damage,suffix]
                if result==null or result.is_empty():
                    errors+=1
                    warnings.append(filename+": EMPTY_NATIVE_VIEWPORT")
                    continue
                var diagnosis: Dictionary=_image_diagnostics(result)
                if result.get_width()!=CAPTURE_SIZE.x or (
                        result.get_height()!=CAPTURE_SIZE.y):
                    errors+=1
                    warnings.append(filename+": INVALID_RENDER_TARGET_SIZE_%dx%d" % [
                        result.get_width(),result.get_height()])
                    continue
                var save_result: Error=result.save_png(
                    EVIDENCE_DIR+"/"+filename)
                if save_result!=OK:
                    errors+=1
                    warnings.append(filename+": PNG_SAVE_FAILED_%d" % [
                        int(save_result)])
                    continue
                saved+=1
                records.append({
                    "tier":LEVELS[tier],
                    "damage":damage,
                    "camera":"reverse-angle" if is_reverse else "tactical",
                    "png":filename,
                    "width":result.get_width(),
                    "height":result.get_height(),
                    "mesh_count":mesh_count,
                    "nonempty":bool(diagnosis["nonempty"]),
                    "coverage":float(diagnosis["coverage"]),
                    "center_coverage":float(diagnosis["center_coverage"]),
                    "variance":float(diagnosis["variance"]),
                    "occupied_bbox":diagnosis["occupied_bbox"],
                    "framing_warning":bool(diagnosis["framing_warning"]),
                    "v42_geometry_findings":geometry_count,
                    "v43_art_findings":finish_count,
                    "geometry_messages":"; ".join(warnings_v42),
                    "art_messages":"; ".join(warnings_v43),
                    "approved":false
                })
                if not bool(diagnosis["nonempty"]):
                    errors+=1
                    warnings.append(filename+": BLANK_OR_LOW_CONTRAST_RENDER")
                if bool(diagnosis["framing_warning"]):
                    warnings.append(filename+": POSSIBLE_FRAMING_ISSUE")
            if geometry_count>0:
                errors+=1
                warnings.append("%s D%d GEOMETRY: %s" % [
                    LEVELS[tier],damage,"; ".join(warnings_v42)])
            if finish_count>0:
                errors+=1
                warnings.append("%s D%d ART: %s" % [
                    LEVELS[tier],damage,"; ".join(warnings_v43)])
            viewport.remove_child(model)
            model.free()
    var manifest: Dictionary={
        "version":"V50-native-direct-viewport",
        "model_stage":"V43",
        "engine":"Godot 4.3",
        "origin":"native-city-model",
        "direct_subviewport":true,
        "target_size":[CAPTURE_SIZE.x,CAPTURE_SIZE.y],
        "count":saved,
        "errors":errors,
        "model_failures":failures,
        "visual_approval":false,
        "screenshots":records
    }
    var data_file: FileAccess=FileAccess.open(
        EVIDENCE_DIR+"/manifest.json",FileAccess.WRITE)
    if data_file!=null:
        data_file.store_string(JSON.stringify(manifest,"  ")+"\n")
        data_file.close()
    var log_file: FileAccess=FileAccess.open(
        EVIDENCE_DIR+"/review-log.txt",FileAccess.WRITE)
    if log_file!=null:
        log_file.store_string("\n".join(warnings)+"\n")
        log_file.close()
    for line in warnings:
        print(line)
    print("V50 native city renders=%d/24 issues=%d" % [saved,errors])
    viewport.queue_free()
    quit(0 if saved==24 and errors==0 else 2)
