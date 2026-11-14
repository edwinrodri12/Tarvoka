extends RefCounted
class_name TarvokaTankFinalTracksV29

# G09 V29 — final mechanically aligned running gear, applied IN PLACE to the
# real V25 mesh. Suppress the obsolete BLOCK belt under the articulated
# links; align both end sprockets, hubs and teeth with the seven road axles.
# Keep 84 shoes per side, two GPU MultiMesh batches, original 14 paint zones,
# 17 PBR enamel plates, turret, weapon and HP/damage rig unchanged.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V29RodajeFinalCorregido"
const SHOE_COUNT := Hero.TRACK_COUNT
const CENTER_Y := 0.290 # Exactly the V7/V14/V21 road-wheel axis
const CENTER_X := 1.335
const SPROCKET_Z := Hero.TRACK_HALF_STRAIGHT
const PATH_RADIUS := 0.250
const SPROCKET_RADIUS := 0.208
const TOOTH_RADIUS := 0.214
const RING_TOOTH_COUNT := 12
const PERIMETER := 4.0*SPROCKET_Z+TAU*PATH_RADIUS
const TRACK_WIDTH_V30 := 0.422
const OLD_TRACK_WIDTH := 0.160
static var _wide_mesh: ArrayMesh

static func _wide_shoe_mesh(original: Mesh) -> ArrayMesh:
    # Preserve the EXACT V21 two-surface PBR tread shape and cross ribs.
    # Widen ONLY the lateral x dimension, not shoe length or belt arc path.
    # Both sides share one GPU mesh + the existing 2 MultiMesh draw batches.
    if _wide_mesh!=null:
        return _wide_mesh
    var output := ArrayMesh.new()
    var factor: float = TRACK_WIDTH_V30/OLD_TRACK_WIDTH
    for surface in range(original.get_surface_count()):
        var arrays: Array = original.surface_get_arrays(surface)
        var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        for i in range(points.size()):
            var p: Vector3 = points[i]
            p.x *= factor
            points[i] = p
        arrays[Mesh.ARRAY_VERTEX] = points
        output.add_surface_from_arrays(
            original.surface_get_primitive_type(surface),arrays)
        output.surface_set_material(
            surface,original.surface_get_material(surface))
    _wide_mesh = output
    return output

static func _widen_links(model: Node3D) -> bool:
    for side in [-1,1]:
        var belt: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        if belt==null or belt.multimesh==null or belt.multimesh.mesh==null:
            return false
        belt.multimesh.mesh = _wide_shoe_mesh(belt.multimesh.mesh)
    return true

const LEGACY_PATTERNS := [
    "BandaOruga%s",
    "GuiaOruga%s",
    "CintaSuperiorOruga%s",
    "CintaInferiorOruga%s",
    "ExtremoCinta%s_%s",
    "ZapataOruga%s_%02d",
    "EslabonTreadSuperior%s_%02d",
    "EslabonTreadInferior%s_%02d"
]

static func _shoe_transform(side: int,phase: float) -> Transform3D:
    # Four sections: upper straight, rear half circle, lower straight,
    # front half circle. Exact arc lengths and C1-continuous tangent.
    var dist: float = fposmod(phase,1.0)*PERIMETER
    var straight: float = 2.0*SPROCKET_Z
    var arc: float = PI*PATH_RADIUS
    var z: float = 0.0
    var y: float = CENTER_Y
    var theta: float = 0.0
    if dist<straight:
        z = -SPROCKET_Z+dist
        y = CENTER_Y+PATH_RADIUS
    elif dist<straight+arc:
        theta = (dist-straight)/PATH_RADIUS
        z = SPROCKET_Z+PATH_RADIUS*sin(theta)
        y = CENTER_Y+PATH_RADIUS*cos(theta)
    elif dist<2.0*straight+arc:
        theta = PI
        z = SPROCKET_Z-(dist-straight-arc)
        y = CENTER_Y-PATH_RADIUS
    else:
        theta = PI+(dist-2.0*straight-arc)/PATH_RADIUS
        z = -SPROCKET_Z+PATH_RADIUS*sin(theta)
        y = CENTER_Y+PATH_RADIUS*cos(theta)
    return Transform3D(Basis(Vector3.RIGHT,theta),
        Vector3(float(side)*CENTER_X,y,z))

static func _teeth(model: Node3D,phase: float) -> bool:
    var rig: MultiMeshInstance3D = model.find_child(
        "DientesCoronasMotricesG09",true,false) as MultiMeshInstance3D
    if rig==null or rig.multimesh==null or (
            rig.multimesh.instance_count!=4*RING_TOOTH_COUNT):
        return false
    var matrix: int = 0
    # Angular speed matches the actual displacement along the belt.
    var rotation: float = phase*PERIMETER/PATH_RADIUS
    for side in [-1,1]:
        for end in [-1,1]:
            for index in range(RING_TOOTH_COUNT):
                var angle: float = TAU*float(index)/float(RING_TOOTH_COUNT)+rotation
                var center := Vector3(float(side)*1.357,
                    CENTER_Y+TOOTH_RADIUS*cos(angle),
                    float(end)*SPROCKET_Z+TOOTH_RADIUS*sin(angle))
                rig.multimesh.set_instance_transform(matrix,
                    Transform3D(Basis(Vector3.RIGHT,angle),center))
                matrix += 1
    return true

static func _move_links(model: Node3D,phase: float) -> bool:
    for side in [-1,1]:
        var belt: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        if belt==null or belt.multimesh==null or (
                belt.multimesh.instance_count!=SHOE_COUNT):
            return false
        for index in range(SHOE_COUNT):
            belt.multimesh.set_instance_transform(index,
                _shoe_transform(side,float(index)/float(SHOE_COUNT)+phase))
    return true

static func _sprockets(model: Node3D) -> int:
    var changed := 0
    for side in [-1,1]:
        var sign: float = float(side)
        for end in [-1,1]:
            var drum: MeshInstance3D = model.find_child(
                "RuedaMotrizG09_%s_%s" % [side,end],
                true,false) as MeshInstance3D
            var hub: MeshInstance3D = model.find_child(
                "EjeMotrizG09_%s_%s" % [side,end],
                true,false) as MeshInstance3D
            if drum==null or hub==null or not (drum.mesh is CylinderMesh):
                return changed
            # Share the material; duplicate the underlying CylinderMesh, so
            # changing its diameter doesn't alter any other mesh instances.
            var new_mesh: CylinderMesh = drum.mesh.duplicate() as CylinderMesh
            new_mesh.top_radius = SPROCKET_RADIUS
            new_mesh.bottom_radius = SPROCKET_RADIUS
            drum.mesh = new_mesh
            drum.position = Vector3(sign*1.303,CENTER_Y,float(end)*SPROCKET_Z)
            hub.position = Vector3(sign*1.355,CENTER_Y,float(end)*SPROCKET_Z)
            changed += 1
    return changed

static func _hide_rectangular_prototypes(model: Node3D) -> int:
    # The square outline reported by the player was genuinely still
    # present: an old opaque BandaOruga box BEHIND the articulated belt.
    # Retire all rectangular/placeholder track segments, not the hull,
    # suspension or any 14 original faction paint surfaces.
    var hidden := 0
    for side in [-1,1]:
        for pattern in ["BandaOruga%s","GuiaOruga%s",
                "CintaSuperiorOruga%s","CintaInferiorOruga%s"]:
            var piece: Node3D = model.find_child(
                pattern % side,true,false) as Node3D
            if piece!=null:
                piece.visible = false
                hidden += 1
        for end in [-1,1]:
            var old_end: Node3D = model.find_child(
                "ExtremoCinta%s_%s" % [side,end],true,false) as Node3D
            if old_end!=null:
                old_end.visible = false
                hidden += 1
        for index in range(10):
            var block: Node3D = model.find_child(
                "ZapataOruga%s_%02d" % [side,index],true,false) as Node3D
            if block!=null:
                block.visible = false
                hidden += 1
        for index in range(15):
            for prefix in ["EslabonTreadSuperior","EslabonTreadInferior"]:
                var old_link: Node3D = model.find_child(
                    "%s%s_%02d" % [prefix,side,index],
                    true,false) as Node3D
                if old_link!=null:
                    old_link.visible = false
                    hidden += 1
    return hidden

static func apply(model: Node3D) -> bool:
    if model==null or not model.get_meta("tarvoka_mbt_wear_v25",false):
        return false
    if model.get_meta("tarvoka_mbt_track_final_v29",false):
        return false
    # ALL four physical gears, both track loops and tooth batch must exist.
    for side in [-1,1]:
        var belt: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        if belt==null or belt.multimesh==null or (
                belt.multimesh.instance_count!=SHOE_COUNT):
            return false
        for end in [-1,1]:
            if not (model.find_child(
                    "RuedaMotrizG09_%s_%s" % [side,end],
                    true,false) is MeshInstance3D):
                return false
            if not (model.find_child(
                    "EjeMotrizG09_%s_%s" % [side,end],
                    true,false) is MeshInstance3D):
                return false
    var teeth: MultiMeshInstance3D = model.find_child(
        "DientesCoronasMotricesG09",true,false) as MultiMeshInstance3D
    if teeth==null or teeth.multimesh==null or (
            teeth.multimesh.instance_count!=4*RING_TOOTH_COUNT):
        return false
    if _sprockets(model)!=4:
        return false
    if not _move_links(model,0.0) or not _teeth(model,0.0):
        return false
    if not _widen_links(model):
        return false
    var hidden: int = _hide_rectangular_prototypes(model)
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_track_final_v29",true)
    model.set_meta("tarvoka_mbt_track_final_v29_hidden",hidden)
    model.set_meta("tarvoka_mbt_track_center_y_v29",CENTER_Y)
    model.set_meta("tarvoka_mbt_track_radius_v29",PATH_RADIUS)
    model.set_meta("tarvoka_mbt_track_width_v30",TRACK_WIDTH_V30)
    model.set_meta("tarvoka_mbt_track_wide_v30",true)
    return true

static func enforce_hidden_after_damage(model: Node3D) -> int:
    # Old V5 damage logic toggles CintaSuperiorOruga1 back on at HP stages.
    # Reassert the V29 final model after ANY five-stage damage transition.
    if model==null or not model.get_meta("tarvoka_mbt_track_final_v29",false):
        return 0
    return _hide_rectangular_prototypes(model)

static func slide_tracks(model: Node3D,phase: float) -> void:
    if model==null or not model.get_meta("tarvoka_mbt_track_final_v29",false):
        return
    _move_links(model,phase)
    _teeth(model,phase)
