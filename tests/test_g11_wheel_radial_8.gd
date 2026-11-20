extends SceneTree

# Focused reversible geometry regression; no gameplay or device FPS claims.
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
var failures := 0
var measured_batches := 0
var triangles_before := 0
var triangles_after := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("G11 WHEEL LOD: " + description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        for level in [8, 10]:
            var model: Node3D = Models.build("mlrs", faction, true, level)
            check(model != null, "model exists")
            if model == null:
                continue
            root.add_child(model)
            var wheel := model.find_child("G11Mobile_Lote12Ruedas", true, false) as MultiMeshInstance3D
            if level == 8:
                check(wheel == null, "far LOD has no roadwheel batch")
            else:
                check(wheel != null, "near LOD has roadwheel batch")
                if wheel != null:
                    check(wheel.multimesh != null, "roadwheel multimesh exists")
                    if wheel.multimesh != null:
                        check(wheel.multimesh.instance_count == 12, "all twelve wheels retained")
                        var cylinder := wheel.multimesh.mesh as CylinderMesh
                        check(cylinder != null, "wheel geometry remains cylindrical")
                        if cylinder != null:
                            check(cylinder.radial_segments == 8, "eight radial segments")
                            check(is_equal_approx(cylinder.top_radius, 0.16), "wheel radius unchanged")
                            check(cylinder.height > 0.0, "wheel width is positive")
                            # Measure real generated faces, not only the radial_segments property.
                            var baseline := CylinderMesh.new()
                            baseline.top_radius = cylinder.top_radius
                            baseline.bottom_radius = cylinder.bottom_radius
                            baseline.height = cylinder.height
                            baseline.radial_segments = 10
                            var old_faces: int = baseline.get_faces().size()
                            var new_faces: int = cylinder.get_faces().size()
                            check(old_faces > 0 and old_faces % 3 == 0, "baseline mesh is triangulated")
                            check(new_faces > 0 and new_faces % 3 == 0, "optimized mesh is triangulated")
                            check(new_faces < old_faces, "wheel mesh has fewer generated triangles")
                            measured_batches += 1
                            triangles_before += int(old_faces / 3) * wheel.multimesh.instance_count
                            triangles_after += int(new_faces / 3) * wheel.multimesh.instance_count
            model.queue_free()
            await process_frame
    check(measured_batches == 8, "one near wheel batch measured per faction")
    check(triangles_after < triangles_before, "eight faction wheel batches save triangles")
    print("G11 WHEEL TRIANGLES baseline=%d optimized=%d saved=%d" % [
        triangles_before, triangles_after, triangles_before - triangles_after])
    if failures > 0:
        quit(1)
    else:
        print("PASS G11 WHEEL LOD: 8 factions, 2 LODs, 12 wheels, 8 radial segments")
        quit(0)
