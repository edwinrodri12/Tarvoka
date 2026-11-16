extends SceneTree

# G13 V11 art acceptance: true multi-ring 3D sculpture, closed glazing,
# unchanged V10 contracts, mobile LOD and ground/air pose compatibility.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Finish = preload("res://scripts/ui/G13BodyFinishV11.gd")
const V10 = preload("res://scripts/ui/G13SilhouetteV10.gd")
var errors := 0

func check(value: bool, why: String) -> void:
    if not value:
        errors += 1
        push_error("G13 V11: " + why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary = {}
    for faction in range(8):
        var hero := Models.build("aa_mobile", faction, true, 13)
        check(hero != null, "hero faction %d exists" % faction)
        if hero == null:
            continue
        check(bool(hero.get_meta(V10.FLAG, false)), "V10 still installed")
        check(bool(hero.get_meta(Finish.FLAG, false)), "V11 sculpt installed")
        check(bool(hero.get_meta("tarvoka_g13_body_finish_v11_art_only", false)),
            "G13 V11 is visual only")
        var cab := hero.find_child(Finish.CAB_SHELL, true, false) as MeshInstance3D
        var turret := hero.find_child(Finish.TURRET_SHELL, true, false) as MeshInstance3D
        var roof := hero.find_child(Finish.ROOF, true, false) as MeshInstance3D
        var left := hero.find_child(Finish.GLASS_LEFT, true, false) as MeshInstance3D
        var right := hero.find_child(Finish.GLASS_RIGHT, true, false) as MeshInstance3D
        check(cab != null and turret != null and roof != null
            and left != null and right != null,
            "cab, turret, solid roof and paired side glazing")
        if cab != null and turret != null and roof != null:
            check(cab.mesh is ArrayMesh and turret.mesh is ArrayMesh
                and roof.mesh is ArrayMesh, "closed custom polygonal armor")
            check(cab.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 200,
                "cab is a detailed five-ring real 3D shell")
            check(turret.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 200,
                "turret is a detailed five-ring real 3D shell")
            check(cab.mesh.get_aabb().size.x <= V10.CAB_ENVELOPE.x + 0.001
                and cab.mesh.get_aabb().size.z <= V10.CAB_ENVELOPE.z + 0.001,
                "cab does not exceed approved wheel clearance")
            check(turret.mesh.get_aabb().size.x <= V10.TURRET_ENVELOPE.x + 0.001,
                "turret retains original width")
            var roof_material := roof.material_override as StandardMaterial3D
            check(roof_material != null and roof_material.roughness > 0.4,
                "roof keeps original physical PBR steel")
        for window in [left, right]:
            if window != null:
                check(window.mesh is ArrayMesh
                    and window.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 24,
                    "side glazing has geometric thickness")
                var m := window.material_override as StandardMaterial3D
                check(m != null and m.roughness < 0.35,
                    "side windows have optical surface finish")
        var original_core := hero.find_child("G13_SealedCab", true, false) as MeshInstance3D
        check(original_core != null and original_core.mesh is BoxMesh
            and not original_core.visible,
            "historical cab pivot/core remains but no longer clips the roof slope")
        for side in [-1, 1]:
            var cheek := hero.find_child("G13_V11_TurretCheek_%d" % side,
                true, false) as MeshInstance3D
            check(cheek != null and cheek.mesh is ArrayMesh,
                "beveled turret cheek sculpt %d" % side)
            var front := hero.find_child("G13_FrontGlass_%d" % side,
                true, false) as MeshInstance3D
            check(front != null and absf(front.position.z + 1.101) < 0.001,
                "front glass follows inclined cab face")
        var faction_panel := hero.find_child("G13_SideEnamel_1",
            true, false) as MeshInstance3D
        if faction_panel != null:
            var faction_material := faction_panel.material_override as StandardMaterial3D
            if faction_material != null:
                paints[faction_material.albedo_color.to_html()] = true
        var old_count: int = Models.inspect_meshes(hero)
        check(not Finish.apply(hero), "V11 cannot be installed twice")
        check(Models.inspect_meshes(hero) == old_count,
            "idempotent mesh tree")
        for pose_name in ["move", "scan", "attack_air", "attack_ground"]:
            check(Models.pose_model("aa_mobile", hero, pose_name, 0.45),
                "V11 keeps animation: " + pose_name)
        Models.restore_model_pose("aa_mobile", hero)
        check(Models.inspect_meshes(hero) == old_count,
            "restoring the pose does not create geometry")
        hero.free()
        var mobile := Models.build("aa_mobile", faction, true, 8)
        check(mobile != null, "lightweight mobile unit remains available")
        if mobile != null:
            check(not bool(mobile.get_meta(Finish.FLAG, false)),
                "V11 hero art never leaks into Android LOD8")
            check(mobile.find_child(Finish.ROOF, true, false) == null,
                "Android model has no V11 roof mesh")
            mobile.free()
    check(paints.size() == 8, "8 faction colors remain distinct")
    if errors != 0:
        quit(1)
        return
    print("PASS G13 V11: sealed five-ring 3D armor, real side glazing, 8 factions, dual attacks and LOD8 protected")
    quit(0)
