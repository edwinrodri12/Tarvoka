extends SceneTree

# G13 V12 inspection regression: geometry, safe barrel recoil, old contracts,
# 8 paints, LOD8 isolation and visible land/air aiming.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Finish = preload("res://scripts/ui/G13MechanicalFinishV12.gd")
const G13 = preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V4 = preload("res://scripts/ui/G13GroundAirFinishV4.gd")
var failures: int = 0

func check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error("G13 V12: " + why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary = {}
    for faction in range(8):
        var hero := Models.build("aa_mobile", faction, true, 13)
        check(hero != null, "hero built for faction %d" % faction)
        if hero == null:
            continue
        check(bool(hero.get_meta(Finish.FLAG, false)), "V12 finish installed")
        check(bool(hero.get_meta("tarvoka_g13_body_finish_v11", false)),
            "V11 approved sculpture remains installed")
        var pitch := hero.find_child(G13.GUNS, true, false) as Node3D
        var turret := hero.find_child(G13.TURRET, true, false) as Node3D
        var bolts := hero.find_child(Finish.FASTENERS,
            true, false) as MultiMeshInstance3D
        check(pitch != null and turret != null, "V1 weapon pivots retained")
        check(bolts != null and bolts.multimesh != null
            and bolts.multimesh.instance_count == 8,
            "eight roof fasteners are one GPU-instanced mesh")
        var center_seal := hero.find_child("G13_V12_FrontGlassCenterSeal",
            true, false) as MeshInstance3D
        check(center_seal != null and center_seal.mesh is CylinderMesh,
            "front glass has a physical central gasket")
        for side in [-1, 1]:
            var outer := hero.find_child("G13_V12_WindshieldPost_%d" % side,
                true, false) as MeshInstance3D
            var sill := hero.find_child("G13_V12_SillWeld_%d" % side,
                true, false) as MeshInstance3D
            var door := hero.find_child("G13_V12_RearDoorJoint_%d" % side,
                true, false) as MeshInstance3D
            check(outer != null and sill != null and door != null,
                "sealed A-pillar, sill and rear door joint %d" % side)
            var bearing := hero.find_child(Finish.BEARING % side,
                true, false) as MeshInstance3D
            var follower := hero.find_child(Finish.FOLLOWER % side,
                true, false) as MeshInstance3D
            var brace := hero.find_child(Finish.ARM % side,
                true, false) as MeshInstance3D
            var barrel := pitch.find_child("G13_Autocannon_%d" % side,
                false, false) as MeshInstance3D
            var muzzle := pitch.find_child(Finish.MOUTH % side,
                false, false) as MeshInstance3D
            check(bearing != null and follower != null and brace != null,
                "fixed/rotating trunnion assembly %d" % side)
            check(barrel != null and muzzle != null,
                "the same approved V1 gun and muzzle nodes remain")
            if bearing != null and follower != null:
                check(bearing.get_parent() == turret and
                    follower.get_parent() == pitch and brace.get_parent() == pitch,
                    "mechanical bearing spans real azimuth and pitch pivots")
            if barrel != null:
                var sleeve := barrel.find_child(Finish.SLEEVE % side,
                    false, false) as MeshInstance3D
                check(sleeve != null and sleeve.get_parent() == barrel,
                    "sleeve follows V4 original recoil rather than a duplicate rig")
                if sleeve != null:
                    check(absf(sleeve.position.y - 0.325) < 0.001 and
                        sleeve.rotation_degrees.is_zero_approx(),
                        "sleeve uses inherited barrel axis, without double rotation")
            if muzzle != null:
                check(muzzle.mesh is ArrayMesh,
                    "solid V1 muzzle cylinder replaced by open annular mesh")
                if muzzle.mesh is ArrayMesh:
                    var points: PackedVector3Array = muzzle.mesh.surface_get_arrays(
                        0)[Mesh.ARRAY_VERTEX]
                    check(points.size() >= 480, "real bore front, back and inner wall")
                    var open_hole: bool = true
                    for p in points:
                        if absf(p.y + 0.050) < 0.001 and (
                                Vector2(p.x, p.z).length() < 0.047):
                            open_hole = false
                    check(open_hole, "the frontal muzzle mouth has no solid center")
                    var forward: Vector3 = muzzle.basis * Vector3(0, -1, 0)
                    check(forward.dot(Vector3(0, 0, -1)) > 0.999,
                        "annular bore opens toward target along original -Z axis")
        var paint := hero.find_child("G13_SideEnamel_1",
            true, false) as MeshInstance3D
        if paint != null:
            var material := paint.material_override as StandardMaterial3D
            if material != null:
                paints[material.albedo_color.to_html()] = true
        var count: int = Models.inspect_meshes(hero)
        check(not Finish.install(hero), "V12 cannot duplicate its parts")
        check(Models.inspect_meshes(hero) == count,
            "one-time build of all physical parts")
        check(Models.pose_model("aa_mobile", hero, "aim_ground", 0.5),
            "ground aim works with new trunnions")
        var ground_basis: Basis = pitch.transform.basis if pitch != null else Basis.IDENTITY
        check(Models.pose_model("aa_mobile", hero, "aim_air", 0.5),
            "air aim works with new trunnions")
        if pitch != null:
            check(pitch.rotation_degrees.x >= 35.0 and
                ground_basis != pitch.transform.basis,
                "moving bearing followers rotate with actual cannon elevation")
        check(Models.pose_model("aa_mobile", hero, "attack_ground", 0.42),
            "ground firing and original 2.5 cm recoil work")
        check(float(hero.get_meta("tarvoka_g13_v4_recoil_m", 0.0)) > 0.0,
            "V4 recoil still active")
        check(Models.pose_model("aa_mobile", hero, "attack_air", 0.25),
            "air firing still works with perforated muzzles")
        check(Models.inspect_meshes(hero) == count,
            "air/ground animations do not create transient geometry")
        Models.restore_model_pose("aa_mobile", hero)
        if pitch != null:
            check(absf(pitch.rotation_degrees.x - 12.0) < 0.01,
                "restores old neutral cannon inclination")
            for side in [-1, 1]:
                var barrel := pitch.find_child("G13_Autocannon_%d" % side,
                    false, false) as Node3D
                if barrel != null:
                    check(absf(barrel.position.z + 0.66) < 0.001,
                        "recoil returns attached sleeve and barrel home")
        check(Models.inspect_meshes(hero) == count,
            "restore does not duplicate any mesh")
        hero.free()
        var mobile := Models.build("aa_mobile", faction, true, 8)
        check(mobile != null, "LOD8 present for all eight factions")
        if mobile != null:
            check(not bool(mobile.get_meta(Finish.FLAG, false)) and
                mobile.find_child(Finish.FASTENERS, true, false) == null,
                "V12 mesh cost excluded entirely from Android LOD8")
            var old_muzzle := mobile.find_child(Finish.MOUTH % -1,
                true, false) as MeshInstance3D
            check(old_muzzle != null and old_muzzle.mesh is CylinderMesh,
                "existing lightweight mobile muzzle remains untouched")
            mobile.free()
    check(paints.size() == 8, "all 8 official paints retained")
    if failures != 0:
        quit(1)
        return
    print("PASS G13 V12: real sealed panel joints, 8 batched bolts, hollow mouths, linked cannon trunnions, 8 faction colors and dual-domain recoil; LOD8 unchanged")
    quit(0)
