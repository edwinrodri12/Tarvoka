extends SceneTree

# G13 V13: inspect real surfaces and mid-body plate clearance on all
# 8 faction hero models while preserving Android LOD8 and V12 cannon rig.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Finish = preload("res://scripts/ui/G13SurfaceFinishV13.gd")
const V12 = preload("res://scripts/ui/G13MechanicalFinishV12.gd")
var errors: int = 0

func check(ok: bool, why: String) -> void:
    if not ok:
        errors += 1
        push_error("G13 V13: " + why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var enamel_colors: Dictionary = {}
    var noise_texture: Texture2D
    for faction in range(8):
        var hero := Models.build("aa_mobile", faction, true, 13)
        check(hero != null, "hero exists faction %d" % faction)
        if hero == null:
            continue
        check(bool(hero.get_meta(V12.FLAG, false)) and
            bool(hero.get_meta(Finish.FLAG, false)),
            "V12 guns and V13 PBR detailing apply")
        check(int(hero.get_meta("tarvoka_g13_v13_pbr_coats", -1)) == 17,
            "17 existing surfaces received non-destructive coats")
        check(bool(hero.get_meta("tarvoka_g13_v13_visual_only", false)),
            "new finish is explicitly art-only")
        var bolts := hero.find_child(Finish.FASTENERS, true, false) as MultiMeshInstance3D
        check(bolts != null and bolts.multimesh != null and
            bolts.multimesh.instance_count == 8,
            "eight side panel fasteners are one GPU instance batch")
        for side in [-1, 1]:
            var panel := hero.find_child(Finish.SIDE_PLATE % side,
                true, false) as MeshInstance3D
            check(panel != null and panel.mesh is ArrayMesh,
                "beveled physical side plate exists %d" % side)
            if panel != null and panel.mesh is ArrayMesh:
                var bounds: AABB = panel.mesh.get_aabb()
                check(bounds.size.z < 0.80 and
                    bounds.position.y > 0.74 and
                    absf(bounds.position.x) <= 0.717,
                    "side panel stays between fenders, above wheels")
                var mat := panel.material_override as StandardMaterial3D
                check(mat != null and mat.metallic > 0.30 and mat.roughness > 0.60,
                    "physical side panel has authored PBR")
            for i in range(3):
                var vent := hero.find_child(Finish.SLOTS % [side, i],
                    true, false) as MeshInstance3D
                check(vent != null and vent.mesh is BoxMesh,
                    "vent slot %d / %d has real 3D geometry" % [side, i])
        var engine := hero.find_child("G13_EngineCover", true, false) as MeshInstance3D
        check(engine != null, "existing engine top remains")
        if engine != null:
            var mat := engine.material_override as StandardMaterial3D
            check(mat != null and mat.roughness_texture != null,
                "original box UVs hold subtle deterministic wear map")
            if mat != null:
                if noise_texture == null:
                    noise_texture = mat.roughness_texture
                else:
                    check(mat.roughness_texture == noise_texture,
                        "one shared roughness texture avoids duplicating allocations")
        var roof_paint := hero.find_child("G13_V2_RoofFaction",
            true, false) as MeshInstance3D
        var paint := hero.find_child("G13_SideEnamel_1", true, false) as MeshInstance3D
        if paint != null:
            var enamel := paint.material_override as StandardMaterial3D
            if enamel != null:
                enamel_colors[enamel.albedo_color.to_html()] = true
        if roof_paint != null and paint != null:
            var top_color := (roof_paint.material_override as StandardMaterial3D).albedo_color
            var original_color := (paint.material_override as StandardMaterial3D).albedo_color
            check(top_color.is_equal_approx(original_color),
                "V13 retains original faction enamel across roof and flank")
        var count: int = Models.inspect_meshes(hero)
        check(not Finish.apply(hero), "reapplying V13 cannot create duplicates")
        check(Models.inspect_meshes(hero) == count, "idempotent geometry")
        for mode in ["move", "scan", "attack_ground", "attack_air"]:
            check(Models.pose_model("aa_mobile", hero, mode, 0.42),
                "G13 dual-domain pose continues: " + mode)
        Models.restore_model_pose("aa_mobile", hero)
        check(Models.inspect_meshes(hero) == count,
            "no meshes appear during shots or reset")
        hero.free()
        var mobile := Models.build("aa_mobile", faction, true, 8)
        check(mobile != null and not bool(mobile.get_meta(Finish.FLAG, false)),
            "Android LOD8 never installs V13")
        if mobile != null:
            check(mobile.find_child(Finish.SIDE_PLATE % 1, true, false) == null,
                "mobile mesh count has no V13 side armor")
            mobile.free()
    check(enamel_colors.size() == 8,
        "eight distinct faction colors remain")
    if errors > 0:
        quit(1)
        return
    print("PASS G13 V13: original faction enamel preserved, 17 PBR coats, physical chamfered mid-body plates, six vents, eight batched fasteners, 8 factions, both attacks and isolated Android LOD8")
    quit(0)
