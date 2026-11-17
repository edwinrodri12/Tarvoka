extends RefCounted
class_name TarvokaG13RadarStowageV30

# G13 V30: physical stowage cradle for the existing V29 retractable radar.
# LOD8 visual-only sculpt; retains the approved twin-autocannon loadout.
# One instanced mesh, two deck feet and two slanted guide rails.
const FLAG := "tarvoka_g13_v30_radar_stowage_cradle"
const NAME := "G13_RadarStowageV30"
const V29_FLAG := "tarvoka_g13_v29_rear_folding_radar"

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(V29_FLAG, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    if bool(root.get_meta("tarvoka_g13_v1_high_detail", true)):
        return false
    var body := root.find_child("G13_Casco4x4", true, false) as Node3D
    var radar := root.find_child("G13_RadarAzimut", true, false) as Node3D
    if body == null or radar == null:
        return false
    if not is_equal_approx(radar.position.z, 1.135):
        return false
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.07, 0.11, 0.28)
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color(0.18, 0.22, 0.25)
    paint.metallic = 0.42
    paint.roughness = 0.61
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = mesh
    multi.instance_count = 4
    # Brackets on the rear deck, mirrored around mast axis.
    # The supports remain stationary while the mast folds.
    for side in [-1, 1]:
        var s := float(side)
        var foot := Transform3D(Basis.IDENTITY, Vector3(
            0.19 * s, 1.10, 1.13))
        multi.set_instance_transform(0 if side == -1 else 1, foot)
        var guide := Transform3D(
            Basis(Vector3(0, 0, 1), deg_to_rad(24.0 * s)),
            Vector3(0.18 * s, 1.18, 1.23))
        multi.set_instance_transform(2 if side == -1 else 3, guide)
    var instance := MultiMeshInstance3D.new()
    instance.name = NAME
    instance.multimesh = multi
    instance.material_override = paint
    body.add_child(instance)
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v30_visual_only", true)
    root.set_meta("tarvoka_g13_v30_extra_draw_nodes", 1)
    root.set_meta("tarvoka_g13_v30_armament", "twin_autocannon_only")
    return true
