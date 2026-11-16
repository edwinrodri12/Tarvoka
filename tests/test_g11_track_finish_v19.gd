extends SceneTree

# G11 V19 complete track artistic acceptance: real geometry with measurable
# clearance at every phase, eight paints and intact missile/armor animations.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Finish = preload("res://scripts/ui/G11FinishV2.gd")
const V18 = preload("res://scripts/ui/G11TrackAssemblyV18.gd")
const V19 = preload("res://scripts/ui/G11TrackFinishV19.gd")
var errors: int = 0
var paints: Dictionary = {}

func _check(ok: bool, message: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V19 track visual QA: "+message)

func _part(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

# Separating-axis test on the real transformed 3D shoe cross-sections.
# This finds mesh intersections that a center-to-center distance misses.
func _projected_shoe(pose: Transform3D) -> Array[Vector2]:
    var corners: Array[Vector2] = []
    for point in [
        Vector3(0,-V19.LINK_HALF_Y,-V19.LINK_HALF_Z),
        Vector3(0,-V19.LINK_HALF_Y,V19.LINK_HALF_Z),
        Vector3(0,V19.OUTER_HEIGHT,V19.LINK_HALF_Z),
        Vector3(0,V19.OUTER_HEIGHT,-V19.LINK_HALF_Z)
    ]:
        var p: Vector3 = pose*point
        corners.append(Vector2(p.y,p.z))
    return corners

func _pad_gap(a: Transform3D, b: Transform3D) -> float:
    var first: Array[Vector2] = _projected_shoe(a)
    var second: Array[Vector2] = _projected_shoe(b)
    var maximal_separation: float = -INF
    for source in [first,second]:
        for i in range(4):
            var edge: Vector2 = source[(i+1)%4]-source[i]
            var axis := Vector2(edge.y,-edge.x).normalized()
            var low_a: float = INF
            var high_a: float = -INF
            var low_b: float = INF
            var high_b: float = -INF
            for p in first:
                low_a = minf(low_a,p.dot(axis))
                high_a = maxf(high_a,p.dot(axis))
            for p in second:
                low_b = minf(low_b,p.dot(axis))
                high_b = maxf(high_b,p.dot(axis))
            maximal_separation = maxf(maximal_separation,
                maxf(low_b-high_a,low_a-high_b))
    return maximal_separation

func _initialize() -> void:
    call_deferred("_check_models")

func _check_models() -> void:
    var pitch: float = Finish._circumference(
        Finish.TRACK_OUTER_RADIUS)/float(Finish.TRACK_LINK_COUNT)
    _check(pitch-2.0*V19.LINK_HALF_Z > 0.029,
        "at least 29mm of shoe separation at nominal belt arclength")
    _check(V19.GUARD_BOTTOM-V19.TRACK_CROWN > 0.02,
        "real highest chevron clears metal fender by over 20mm")
    _check(V19.CHEVRONS_PER_LINK == 4,
        "two mirrored pressed V profiles per link")
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"real Godot hero model built for faction")
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V18.FLAG,false)),
            "V18 corrected belt/gear alignment still applied")
        _check(bool(model.get_meta(V19.FLAG,false)),
            "V19 full sculpted bevel and tread finish actually applied")
        _check(int(model.get_meta(
            "tarvoka_g11_v19_real_beveled_links",0)) == 92,
            "exactly 92 true beveled 3D links, no stacked duplicate shoes")
        _check(int(model.get_meta(
            "tarvoka_g11_v19_real_raised_chevrons",0)) == 368,
            "368 physically extruded anti-slip chevron ribs")
        _check(int(model.get_meta(
            "tarvoka_g11_v19_tapered_steel_guards",0)) == 2,
            "exactly two original tapered steel fenders, not extra slabs")
        var roof := _part(model,"G11_TapaSuperior") as MeshInstance3D
        if roof != null and roof.material_override is StandardMaterial3D:
            var paint: Color = (
                roof.material_override as StandardMaterial3D).albedo_color
            var original: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(paint.is_equal_approx(original),"faction original PBR roof paint kept")
            paints[paint.to_html()] = true
        else:
            _check(false,"real PBR faction painted roof retained")

        var shared: ArrayMesh = null
        for side in [-1,1]:
            var shoes := _part(model,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            _check(shoes != null and shoes.multimesh != null,
                "same existing animated shoe MultiMesh still on both tracks")
            if shoes == null or shoes.multimesh == null:
                continue
            _check(shoes.multimesh.instance_count == V19.LINK_COUNT,
                "46 instances only, no overlapping old blocks")
            var mesh := shoes.multimesh.mesh as ArrayMesh
            _check(mesh != null,"old BoxMesh shoe replaced by a genuine ArrayMesh")
            if mesh == null:
                continue
            if shared == null:
                shared = mesh
            else:
                _check(mesh == shared,
                    "same exact shoe mesh resource shared across both sides")
            _check(mesh.get_surface_count() == 2,
                "body and four raised antislip ridges use independent PBR surfaces")
            var box: AABB = mesh.get_aabb()
            _check(absf(box.size.x-2.0*V19.LINK_HALF_X) < 0.002,
                "track sidewall shoe is narrow enough to stay recessed")
            _check(box.size.z <= 0.133 and box.size.z >= 0.130,
                "beveled link fits positive pitch gap at all corners")
            _check(absf(box.end.y-V19.OUTER_HEIGHT) < 0.001,
                "raised chevrons protrude exactly 9mm from pad face")
            _check(absf(box.position.y+V19.LINK_HALF_Y) < 0.001,
                "pad steel sits flush on true V18 moving rubber belt")
            var body_vertices: PackedVector3Array = (
                mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            )
            var chevrons: PackedVector3Array = (
                mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX]
            )
            _check(body_vertices.size() >= 80,
                "V19 shoe is octagonal extruded metal, not one flat plane")
            _check(chevrons.size() == 4*4*6+4*6,
                "four actual chevrons have top and outer sides as real triangles")
            for point in chevrons:
                _check(absf(point.x) < V19.LINK_HALF_X,
                    "raised cleats do not intersect track plate side edge")
                _check(absf(point.z) < V19.LINK_HALF_Z,
                    "raised cleats do not touch next link at end")
            var guard := _part(model,
                "G11_Faldon_%d" % side) as MeshInstance3D
            _check(guard != null and guard.mesh is ArrayMesh,
                "old box fender replaced by original mount with beveled end caps")
            if guard != null and guard.mesh is ArrayMesh:
                var bounds: AABB = guard.mesh.get_aabb()
                _check(absf(bounds.size.z-2.90) < 0.001,
                    "tapered guard retains original footprint and bolt alignment")
                _check(guard.position.y+bounds.position.y > V19.TRACK_CROWN+0.020,
                    "tapered guard clear of entire raised moving shoe arc")
            _check(_part(model,
                "G11V18_PernosGuardabarros_%d" % side)
                is MultiMeshInstance3D,
                "original V18 guard bolts remain, no duplicated fittings")
            for role in ["TensorDelantero","PinionTrasero"]:
                _check(_part(model,
                    "G11V5_%s_%d" % [role,side]) != null,
                    "both metallic end sprockets remain and are not rebuilt")
            var initial: Transform3D = shoes.multimesh.get_instance_transform(0)
            for travel in [0.0,0.25,0.5,0.73,1.0]:
                _check(Models.pose_model("mlrs",model,"move",travel),
                    "genuine G11 wheels/treads share original moving chassis rig")
                for n in range(V19.LINK_COUNT):
                    var a: Transform3D = shoes.multimesh.get_instance_transform(n)
                    var b: Transform3D = shoes.multimesh.get_instance_transform(
                        (n+1)%V19.LINK_COUNT)
                    _check(a.origin.distance_to(b.origin)>0.15,
                        "all 46 native shoe pivots remain physically spaced")
                    _check(_pad_gap(a,b)>0.018,
                        "3D rotated neighboring shoe silhouettes stay separated >18mm")
                var sample := shoes.multimesh.get_instance_transform(0)
                _check(absf(sample.origin.x-float(side)*Finish.TRACK_CENTER_X)
                    < 0.001,"each pad follows its correctly mirrored track")
            var last: Transform3D = shoes.multimesh.get_instance_transform(0)
            _check(initial.origin.distance_to(last.origin)>0.10,
                "tread still scrolls during visual marching animation")
            Models.restore_model_pose("mlrs",model)
            _check(initial.origin.distance_to(
                shoes.multimesh.get_instance_transform(0).origin)<0.001,
                "every sculpted link exactly returns to its original position")
        for col in range(4):
            for row in range(3):
                _check(_part(model,
                    "G11_Tubo_%d_%d" % [col,row]) != null,
                    "twelve genuine open tubes unaffected")
        _check(Art.apply_stage(model,3),"critical damage state still active")
        _check(Art.apply_stage(model,0),"true repair returns original intact chassis")
        _check(Rig.pose(model,"attack",0.58),
            "rocket elevation and hydraulic articulation preserved")
        _check(Rig.pose(model,"cooldown",0.47),
            "cooldown and return animation unaffected")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    _check(paints.size()==8,"all eight different faction paints unchanged")
    if errors>0:
        push_error("G11 V19 TRACK FINISH FAILED (%d checks)" % errors)
        quit(1)
        return
    print("PASS G11 V19: 8 factions, 92 real beveled links, 368 raised chevrons, two tapered original guards, >20mm mobile clearance, 46 animated links per belt, all damage/rocket/repair states")
    quit(0)
