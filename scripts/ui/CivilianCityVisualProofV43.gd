extends SceneTree

# TARVOKA V43 — off-game visual proof capture for GitHub Actions.
# Renders the REAL native Godot 4.3 / GL Compatibility SubViewport.
# Produces 15 PNGs: Villa/Ciudad/Metropoli × intact D0..ruins D4.
# No gameplay scenes, input simulation, damage balancing or approval.
const Studio=preload("res://scenes/CivilianCityDesignStudioV43.tscn")
const EVIDENCE_DIR="res://build/city-v43-evidence"

# A nonempty PNG is not sufficient: reject sky-only/flat-color viewport
# results using a sampled RGB variance and actual backdrop coverage.
static func _image_diagnostics(img: Image) -> Dictionary:
    var w: int=img.get_width()
    var h: int=img.get_height()
    var n: int=0
    var total: float=0.0
    var squares: float=0.0
    var changed: int=0
    var bg: Color=Color("#374e5c")
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
        push_error("V43: cannot create evidence directory")
        quit(2)
        return
    var studio: TarvokaCivilianCityDesignStudioV43=(
        Studio.instantiate() as TarvokaCivilianCityDesignStudioV43)
    if studio==null:
        push_error("V43: native studio failed to instantiate")
        quit(2)
        return
    root.add_child(studio)
    await process_frame
    await RenderingServer.frame_post_draw
    var errors: int=0
    var captured: int=0
    var records: Array[Dictionary]=[]
    var report: PackedStringArray=[
        "TARVOKA V43 | Godot 4.3 | native visual art screenshots",
        "No automatic final approval; each screenshot requires visual inspection."
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
            var record: Dictionary={
                "tier":variant,"damage":damage,
                "png":"%s_D%d.png" % [variant,damage],
                "width":result.get_width(),"height":result.get_height(),
                "variance":float(optics["variance"]),
                "coverage":float(optics["coverage"]),
                "nonempty":bool(optics["nonempty"]),
                "v42_geometry_findings":material_warnings,
                "v43_art_findings":review_v43,
                "approved":false
            }
            records.append(record)
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
        "version":"V43",
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
    print("V43 captures=%d expected=15 errors=%d" % [
        captured,errors])
    studio.queue_free()
    quit(0 if errors==0 and captured==15 else 2)
