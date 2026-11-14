extends RefCounted
class_name TarvokaTankIntegrationV20

# G09 V20: unify *existing* V13 skirt / V14 shoulder / V18 suspension
# pieces into one coherent manufactured silhouette. This is real 3D mesh
# replacement, not additional trim glued to the previous armor plates.
# Opt-in art_level=20 only. Does not touch paint zones or animation pivots.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V20BlindajeMonocasco"
const ARMOR := Color("#536974")
const COMPOSITE := Color("#617581")
const JOINT := Color("#354750")
const STEEL := Color("#465963")
const RETIRED := [
    "EstibaBlindadaTraseraV7",
    "G09V15SoldaduraHombro_-1","G09V15SoldaduraHombro_1",
    "G09V15CosturaCarrillera_-1","G09V15CosturaCarrillera_1"
]
const REFITTED_MESHES := 19
const FENDER_SEGMENTS := 5
const SUSPENSION_ARMS := 14
static var _beam_cache: ArrayMesh

static func _mirrored(side: int,positive: Array) -> Array:
    var result: Array = []
    for vertex in positive:
        result.append(Vector2(float(side)*vertex.x,vertex.y))
    if side<0:
        result.reverse()
    return result

static func _swap_loft(model: Node3D,label: String,
        polygon: Array,sections: Array) -> bool:
    var original: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if original == null or original.mesh == null:
        return false
    var parent: Node3D = original.get_parent() as Node3D
    if parent == null:
        return false
    var proxy: MeshInstance3D = Hero._loft(
        parent,"__V20_TEMP_MESH",polygon,sections)
    original.mesh = proxy.mesh
    proxy.free()
    return true

static func _material(model: Node3D,label: String,
        color: Color,ceramic: bool) -> void:
    var part: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if part == null:
        return
    var mat: StandardMaterial3D = Hero._army_material(color,true)
    mat.normal_scale = 0.13
    mat.roughness = 0.91 if ceramic else 0.85
    mat.metallic = 0.12 if ceramic else 0.22
    part.material_override = mat

static func _segment_shape(side: int,index: int) -> Array:
    # Continuous, almost gapless silhouette along the hull. Individual
    # panels retain their ORIGINAL names to preserve right-side damage
    # detachment at HP stage 3, while the upper lip meets the monocoque
    # armor shoulder rather than hanging at x=1.3 in mid-air.
    var front: float = -1.50+float(index)*0.585
    var back: float = front+0.578
    var taper: float = 0.028 if index==0 else (
        -0.015 if index==4 else 0.0)
    return _mirrored(side,[
        Vector2(1.027,front+0.005),
        Vector2(1.190,front-0.006),
        Vector2(1.269+taper,front+0.042),
        Vector2(1.275+taper,back-0.038),
        Vector2(1.174,back+0.006),
        Vector2(1.028,back-0.005)
    ])

static func _suspension_mesh() -> ArrayMesh:
    if _beam_cache != null:
        return _beam_cache
    # A solid chamfered arm with a broader welded root and a narrower
    # dished-wheel tip. Four axial rings share ONE vertex mesh used by all
    # fourteen suspension instances; no fourteen separate draw calls.
    var profile := [
        Vector2(-0.036,-0.061),Vector2(0.036,-0.061),
        Vector2(0.060,-0.028),Vector2(0.060,0.028),
        Vector2(0.036,0.061),Vector2(-0.036,0.061),
        Vector2(-0.060,0.028),Vector2(-0.060,-0.028)
    ]
    var stations := [
        Vector2(-0.207,0.58),Vector2(-0.164,1.0),
        Vector2(0.083,0.90),Vector2(0.197,0.51)
    ]
    var rings: Array = []
    for station in stations:
        var ring: Array = []
        for pt in profile:
            ring.append(Vector3(station.x,
                pt.x*station.y,pt.y*station.y))
        rings.append(ring)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size()-1):
        var previous: Array = rings[layer]
        var next_ring: Array = rings[layer+1]
        for i in range(profile.size()):
            var j: int = (i+1)%profile.size()
            Hero._tri(st,previous[i],previous[j],next_ring[j])
            Hero._tri(st,previous[i],next_ring[j],next_ring[i])
    var first: Array = rings[0]
    var last: Array = rings[rings.size()-1]
    for i in range(profile.size()):
        var j: int = (i+1)%profile.size()
        Hero._tri(st,Vector3(-0.207,0,0),first[j],first[i])
        Hero._tri(st,Vector3(0.197,0,0),last[i],last[j])
    _beam_cache = st.commit()
    return _beam_cache

static func _refit_suspension(model: Node3D) -> bool:
    var arms: MultiMeshInstance3D = model.find_child(
        "G09V18BrazosSuspension",true,false) as MultiMeshInstance3D
    if arms == null or arms.multimesh == null or (
            arms.multimesh.instance_count != SUSPENSION_ARMS):
        return false
    var mm: MultiMesh = arms.multimesh
    mm.mesh = _suspension_mesh()
    for axle in range(7):
        for side_index in range(2):
            var side: float = -1.0 if side_index==0 else 1.0
            var wheel_z: float = -1.13+float(axle)*0.377
            # Root at x~0.97, 14 visible beams terminate against actual
            # wheel center (x~1.30), not behind a floating fender.
            var angle: float = (0.07 if axle%2==0 else -0.06)*side
            mm.set_instance_transform(axle*2+side_index,
                Transform3D(Basis(Vector3.FORWARD,angle),
                    Vector3(side*1.145,0.322,wheel_z)))
    arms.material_override = Hero._army_material(JOINT,false)
    return true

static func hide_legacy(model: Node3D) -> void:
    if model == null or not model.get_meta(
            "tarvoka_mbt_integrated_v20",false):
        return
    for label in RETIRED:
        var part: Node3D = model.find_child(
            label,true,false) as Node3D
        if part != null:
            part.visible = false
    for side in [-1,1]:
        for segment in range(FENDER_SEGMENTS):
            var old: Node3D = model.find_child(
                "G09V13RibeteFaldon_%s_%02d" % [side,segment],
                true,false) as Node3D
            if old != null:
                old.visible = false

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta(
            "tarvoka_mbt_sculpt_v19",false):
        return false
    if model.find_child(ROOT,true,false)!=null:
        return false
    var turret: Node3D = model.find_child(
        "TorretaGiratoria",true,false) as Node3D
    var hull: Node3D = model.find_child(
        "ChasisBlindado",true,false) as Node3D
    if hull == null or turret == null:
        return false

    var requested: Array = ["G09V13BastionMunicionesContinuo"]
    for side in [-1,1]:
        for segment in range(FENDER_SEGMENTS):
            requested.append("G09V13FaldonSegmentado_%s_%02d" % [side,segment])
        for name in ["FaldonBlindadoIntegradoV7_",
                "G09V14LomoBlindadoCentral_",
                "G09V14HombroMotorPosterior_",
                "G09V14CarrilleraEscalonada_"]:
            requested.append(name+str(side))
    if requested.size()!=REFITTED_MESHES:
        return false
    for label in requested:
        if not (model.find_child(
                label,true,false) is MeshInstance3D):
            return false
    var arm: MultiMeshInstance3D = model.find_child(
        "G09V18BrazosSuspension",true,false) as MultiMeshInstance3D
    if arm == null or arm.multimesh == null:
        return false

    var swapped: int = 0
    for side in [-1,1]:
        var key: String = str(side)
        for index in range(FENDER_SEGMENTS):
            var label: String = "G09V13FaldonSegmentado_%s_%02d" % [
                side,index]
            if _swap_loft(model,label,_segment_shape(side,index),[
                    [0.704,0.964,0.0],[0.819,1.008,0.0],
                    [0.966,1.0,0.0],[1.045,0.902,0.0]]):
                swapped+=1
            _material(model,label,
                COMPOSITE if index==0 or index==4 else ARMOR,
                index==0 or index==4)

        # The original V7/V18 lower skirt is a reinforcing underframe,
        # correctly modeled around the original LOCAL mesh origin; this
        # replaces its upper projecting box with a flush belt support.
        if _swap_loft(model,"FaldonBlindadoIntegradoV7_"+key,[
                Vector2(-0.065,-1.34),Vector2(0.062,-1.34),
                Vector2(0.072,-1.21),Vector2(0.069,1.21),
                Vector2(0.039,1.33),Vector2(-0.064,1.33)
            ],[[-0.157,0.91,0.0],[-0.028,1.0,0.0],
                [0.133,0.904,0.0]]):
            swapped+=1
        _material(model,"FaldonBlindadoIntegradoV7_"+key,STEEL,false)

        # Replace shoulder shelf surfaces in place with shallower volumes
        # whose inside edges sink into the actual roof of the main hull.
        if _swap_loft(model,"G09V14LomoBlindadoCentral_"+key,
                _mirrored(side,[
            Vector2(0.897,-0.710),Vector2(1.235,-0.710),
            Vector2(1.318,0.620),Vector2(1.198,0.835),
            Vector2(0.869,0.805)
        ]),[[0.844,0.974,0.0],[0.987,1.0,0.0],
            [1.083,0.846,0.0]]):
            swapped+=1
        _material(model,"G09V14LomoBlindadoCentral_"+key,ARMOR,false)

        if _swap_loft(model,"G09V14HombroMotorPosterior_"+key,
                _mirrored(side,[
            Vector2(0.855,0.805),Vector2(1.226,0.802),
            Vector2(1.295,1.237),Vector2(1.105,1.517),
            Vector2(0.814,1.472)
        ]),[[0.852,0.962,0.0],[0.987,1.0,0.0],
            [1.087,0.838,0.0]]):
            swapped+=1
        _material(model,"G09V14HombroMotorPosterior_"+key,ARMOR,false)

        # Refit turret cheek to the low turret surface instead of exposing
        # an unsupported V14 saw-tooth beneath the roof.
        if _swap_loft(model,"G09V14CarrilleraEscalonada_"+key,
                _mirrored(side,[
            Vector2(0.232,-1.655),Vector2(0.555,-1.638),
            Vector2(0.967,-1.200),Vector2(1.005,-0.765),
            Vector2(0.813,-0.505),Vector2(0.386,-0.873)
        ]),[[0.195,0.889,0.014],[0.369,1.003,0.025],
            [0.545,0.943,0.051],[0.634,0.789,0.064]]):
            swapped+=1
        _material(model,"G09V14CarrilleraEscalonada_"+key,COMPOSITE,true)

    # One continuous ammo bustle replaces the formerly stacked rear V13
    # body + V7 box; that old V7 part is permanently retired for V20.
    if _swap_loft(model,"G09V13BastionMunicionesContinuo",[
        Vector2(-0.594,0.930),Vector2(0.594,0.930),
        Vector2(0.766,1.142),Vector2(0.753,1.473),
        Vector2(0.591,1.526),Vector2(-0.591,1.526),
        Vector2(-0.753,1.473),Vector2(-0.766,1.142)
    ],[[0.194,0.863,0.0],[0.347,1.008,0.0],
        [0.518,0.923,0.0],[0.553,0.818,0.0]]):
        swapped+=1
    _material(model,"G09V13BastionMunicionesContinuo",ARMOR,false)

    var rig_fixed: bool = _refit_suspension(model)
    if swapped!=REFITTED_MESHES or not rig_fixed:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_integrated_v20",true)
    model.set_meta("tarvoka_mbt_integrated_v20_replaced",swapped)
    hide_legacy(model)
    return true
