extends SceneTree

# TARVOKA V44 — expanded off-game visual proof capture for GitHub Actions.
# Renders the REAL native Godot 4.3 / GL Compatibility SubViewport.
# Produces 24 PNGs: 15 tactical + 9 reverse-angle views for D0/D2/D4.
# No gameplay scenes, input simulation, damage balancing or approval.
const Studio=preload("res://scenes/CivilianCityDesignStudioV43.tscn")
const EVIDENCE_DIR="res://build/city-v44-evidence"

# A nonempty PNG is not sufficient: reject sky-only/flat-color viewport
# results using a sampled RGB variance and actual backdrop coverage.
static func _image_diagnostics(img: Image) -> Dictionary:
    var w: int=img.get_width()
    var h: int=img.get_height()
    var n: int=0
    var total: float=0.0
    var squares: float=0.0
    var changed: int=0
    # Measure against the real render's corner rather than assuming a
    # fixed sRGB value for the Godot WorldEnvironment background.
    var bg: Color=img.get_pixel(0,0)
    for y in range(0,h,maxi(1,int(float(h)/30.0))):
        for x in range(0,w,maxi(1,int(float(w)/48.0))):
            var c: Color=img.get_pixel(x,y)
            var lum: float=0.2126*c.r+0.7152*c.g+0.0722*c.b
            total+=lum
            squares+=lum*lum
            n+=1
            var delta: float=absf(c.r-bg.r)+absf(c.g-bg.g)+absf(c.b-bg.b)
            if delta>0.19:
                changed+=1
    var avg: float=total/maxf(1.0,float(n))
    var variance: float=maxf(0.0,squares/maxf(1.0,float(n))-avg*avg)
    var coverage: float=float(changed)/maxf(1.0,float(n))
    return {"variance":variance,"coverage":coverage,
        "nonempty":variance>=0.0004 and coverage>=0.025}


func _initialize() -> void:
    call_deferred("_capture_all")

func _capture_all() -> void:
    var absolute_dir: String=ProjectSettings.globalize_path(EVIDENCE_DIR)
    if DirAccess.make_dir_recursive_absolute(absolute_dir)!=OK:
        push_error("V44: cannot create evidence directory")
        quit(2)
        return
    var studio: TarvokaCivilianCityDesignStudioV43=(
        Studio.instantiate() as TarvokaCivilianCityDesignStudioV43)
    if studio==null:
        push_error("V44: native studio failed to instantiate")
        quit(2)
        return
    root.add_child(studio)
    await process_frame
    await RenderingServer.frame_post_draw
    var errors: int=0
    var captured: int=0
    var records: Array[Dictionary]=[]
    var report: PackedStringArray=[
        "TARVOKA V44 | Godot 4.3 | 15 tactical + 9 reverse-angle native images",
        "No automatic final approval. Render data is diagnostic only, not artistic signoff."
    ]
    for tier in range(3):
        for damage in range(5):
            studio._tier.select(tier)
            studio._damage.select(damage)
            studio._lod.select(0)
            studio._faction.select(0)
            studio._rebuild()
            # Match the camera to the tier/ruin height. Otherwise the
            # inherited camera can frame the sky instead of the city.
            var max_height: float=(
                2.31 if tier==0 else 6.51 if tier==1 else 10.71)
            var focus_height: float=(
                max_height*0.42 if damage<=2 else 0.85)
            var visual_distance: float=(
                29.0 if tier==0 else 33.0 if tier==1 else 38.0)
            studio._view_v19(Vector3(0.0,focus_height,0.0),
                38.0,46.0,visual_distance)
            await process_frame
            await RenderingServer.frame_post_draw
            await process_frame
            await RenderingServer.frame_post_draw
            var variant: String=["Villa","Ciudad","Metropoli"][tier]
            var output: String="%s/%s_D%d.png" % [
                EVIDENCE_DIR,variant,damage]
            if studio._model==null or studio.viewport==null:
                errors+=1
                report.append("%s D%d: MODEL_NOT_CONSTRUCTED" % [
                    variant,damage])
                continue
            var material_warnings: int=int(studio._model.get_meta(
                "city_v42_warning_count",-1))
            var result: Image=studio.viewport.get_texture().get_image()
            if result==null or result.is_empty():
                errors+=1
                report.append("%s D%d: EMPTY_VIEWPORT" % [
                    variant,damage])
                continue
            if result.get_width()<300 or result.get_height()<200:
                errors+=1
                report.append("%s D%d: BAD_VIEWPORT_RESOLUTION" % [
                    variant,damage])
                continue
            var optics: Dictionary=_image_diagnostics(result)
            var review_v43: int=int(studio._model.get_meta(
                "city_v43_issue_count",-1))
            var geometry_messages: PackedStringArray=studio._model.get_meta(
                "city_v42_visual_warnings",PackedStringArray())
            var art_messages: PackedStringArray=studio._model.get_meta(
                "city_v43_art_issues",PackedStringArray())
            var record: Dictionary={
                "tier":variant,"damage":damage,
                "png":"%s_D%d.png" % [variant,damage],
                "camera":"tactical",
                "width":result.get_width(),"height":result.get_height(),
                "variance":float(optics["variance"]),
                "coverage":float(optics["coverage"]),
                "nonempty":bool(optics["nonempty"]),
                "v42_geometry_findings":material_warnings,
                "v43_art_findings":review_v43,
                "geometry_messages":"; ".join(geometry_messages),
                "art_messages":"; ".join(art_messages),
                "approved":false
            }
            records.append(record)
            if int(studio._model.get_meta("city_drawable_count",0))<=0:
                errors+=1
                report.append("%s D%d: ZERO_VISIBLE_NATIVE_MESHES" % [
                    variant,damage])
            if not bool(optics["nonempty"]):
                errors+=1
                report.append("%s D%d: EMPTY_OR_UNIFORM_RENDER coverage=%.3f variance=%.6f" % [
                    variant,damage,float(optics["coverage"]),
                    float(optics["variance"])])
            var save_error: Error=result.save_png(output)
            if save_error!=OK:
                errors+=1
                report.append("%s D%d: PNG_ERROR_%d" % [
                    variant,damage,int(save_error)])
                continue
            captured+=1
            # Add a reverse-side shot of intact roofs, D2 openings and D4
            # wreckage. The same scene is used; no proxy geometry.
            if damage in [0,2,4]:
                studio._view_v19(Vector3(0.0,focus_height,0.0),
                    142.0,35.0,visual_distance+3.0)
                await process_frame
                await RenderingServer.frame_post_draw
                await process_frame
                await RenderingServer.frame_post_draw
                var reverse: Image=studio.viewport.get_texture().get_image()
                var second_name: String="%s_D%d_reverse.png" % [
                    variant,damage]
                if reverse!=null and not reverse.is_empty():
                    var secondary: Dictionary=_image_diagnostics(reverse)
                    var reverse_error: Error=reverse.save_png(
                        EVIDENCE_DIR+"/"+second_name)
                    if reverse_error==OK:
                        captured+=1
                        records.append({
                            "tier":variant,"damage":damage,
                            "camera":"reverse-angle",
                            "png":second_name,
                            "width":reverse.get_width(),
                            "height":reverse.get_height(),
                            "variance":float(secondary["variance"]),
                            "coverage":float(secondary["coverage"]),
                            "nonempty":bool(secondary["nonempty"]),
                            "v42_geometry_findings":material_warnings,
                            "v43_art_findings":review_v43,
                            "geometry_messages":"; ".join(geometry_messages),
                            "art_messages":"; ".join(art_messages),
                            "approved":false
                        })
                        if not bool(secondary["nonempty"]):
                            errors+=1
                            report.append("%s D%d REVERSE: EMPTY_OR_UNIFORM_RENDER" % [
                                variant,damage])
                    else:
                        errors+=1
                        report.append("%s D%d REVERSE: PNG_ERROR_%d" % [
                            variant,damage,int(reverse_error)])
                else:
                    errors+=1
                    report.append("%s D%d REVERSE: EMPTY_VIEWPORT" % [
                        variant,damage])
            report.append("%s D%d | %s | %d meshes | %d geometry findings" % [
                variant,damage,output,
                int(studio._model.get_meta("city_drawable_count",-1)),
                material_warnings])
            if review_v43>0:
                errors+=1
                var art_findings: PackedStringArray=studio._model.get_meta(
                    "city_v43_art_issues",PackedStringArray())
                report.append("  V43 ART: "+"; ".join(art_findings))
            if material_warnings>0:
                errors+=1
                var findings: PackedStringArray=studio._model.get_meta(
                    "city_v42_visual_warnings",PackedStringArray())
                report.append("  WARNINGS: "+"; ".join(findings))
    var manifest: Dictionary={
        "version":"V44",
        "engine":"Godot 4.3",
        "origin":"native-city-model",
        "count":captured,
        "errors":errors,
        "visual_approval":false,
        "screenshots":records
    }
    var data_file: FileAccess=FileAccess.open(
        EVIDENCE_DIR+"/manifest.json",FileAccess.WRITE)
    if data_file!=null:
        data_file.store_string(JSON.stringify(manifest,"  "))
        data_file.close()
    var evidence: FileAccess=FileAccess.open(
        EVIDENCE_DIR+"/review-log.txt",FileAccess.WRITE)
    if evidence!=null:
        evidence.store_string("\n".join(report)+"\n")
        evidence.close()
    print("\n".join(report))
    print("V44 captures=%d expected=24 errors=%d" % [
        captured,errors])
    studio.queue_free()
    quit(0 if errors==0 and captured==24 else 2)
