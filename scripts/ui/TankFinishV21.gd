extends RefCounted
class_name TarvokaTankFinishV21

# TARVOKA G09 V21: credible hull/turret load path, coherent bow and
# mechanically substantial running gear. Operates on the original meshes
# and MultiMeshes: not a second tank, not more decals or billboard FX.
# This opt-in art revision does not change Android's default art_level=10.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const V20 = preload("res://scripts/ui/TankIntegrationV20.gd")
const ROOT := "G09V21BarbetaProaRodaje"
const ARMOR := Color("#4D626D")
const CERAMIC := Color("#697C87")
const STEEL := Color("#647680")
const GASKET := Color("#253841")
const RUBBER := Color("#29343B")
const WHEEL_COUNT := 14
const TREADS_PER_SIDE := 84
const CHANGED_PRIMARY_MESHES := 18
const LEGACY_FRONT := ["RampaBlindajeProaV8","NarizInferiorV7"]
static var _shared_wheel: ArrayMesh
static var _shared_tread: ArrayMesh

static func _strip(material_color: Color,metal: float,
        rough: float) -> StandardMaterial3D:
    var m: StandardMaterial3D = Hero._army_material(material_color,false)
    m.metallic = metal
    m.roughness = rough
    return m

static func _profile_revolve(st: SurfaceTool,profile: Array,
        segments: int = 28) -> void:
    # Axial Y / radial section in local wheel space. The existing G09
    # MeshInstance is rotated around Z by 90 degrees by the original rig.
    var rings: Array = []
    for section in profile:
        var ring: Array = []
        for i in range(segments):
            var a: float = TAU*float(i)/float(segments)
            ring.append(Vector3(float(section.y)*cos(a),
                float(section.x),float(section.y)*sin(a)))
        rings.append(ring)
    for layer in range(rings.size()-1):
        var near: Array = rings[layer]
        var far: Array = rings[layer+1]
        for i in range(segments):
            var nxt: int = (i+1)%segments
            Hero._tri(st,near[i],near[nxt],far[nxt])
            Hero._tri(st,near[i],far[nxt],far[i])

static func _wheel_mesh() -> ArrayMesh:
    if _shared_wheel != null:
        return _shared_wheel
    # One watertight low-profile rubber tire and two physically recessed
    # steel wheel dishes in two genuine sub-surfaces. Original rotating
    # spoke batches and outer hub assemblies stay animated unchanged.
    var tire := SurfaceTool.new()
    tire.begin(Mesh.PRIMITIVE_TRIANGLES)
    _profile_revolve(tire,[
        Vector2(-0.075,0.131),Vector2(-0.070,0.177),
        Vector2(-0.048,0.192),Vector2(0.048,0.192),
        Vector2(0.070,0.177),Vector2(0.075,0.131)
    ])
    _shared_wheel = tire.commit()
    _shared_wheel.surface_set_material(0,_strip(RUBBER,0.09,0.91))

    var face := SurfaceTool.new()
    face.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1,1]:
        var sign: float = float(side)
        _profile_revolve(face,[
            Vector2(sign*0.075,0.135),
            Vector2(sign*0.068,0.122),
            Vector2(sign*0.041,0.082),
            Vector2(sign*0.056,0.045),
            Vector2(sign*0.058,0.001)
        ])
    face.commit(_shared_wheel)
    _shared_wheel.surface_set_material(1,_strip(STEEL,0.34,0.76))
    return _shared_wheel

static func _raised_rib(st: SurfaceTool,side: int,z: float) -> void:
    # Integral split tread cleat on the existing 84 pads. Four ribs are
    # added to the SAME single pad mesh, two on its exposed outside face
    # and two on its opposite face for inverted bottom travel.
    var sy: float = float(side)
    var x0: float = -0.067
    var x1: float = 0.067
    var z0: float = z-0.008
    var z1: float = z+0.008
    var y0: float = sy*0.035
    var y1: float = sy*0.052
    var verts := [
        Vector3(x0,y0,z0),Vector3(x1,y0,z0),
        Vector3(x1,y0,z1),Vector3(x0,y0,z1),
        Vector3(x0+0.010,y1,z0+0.002),
        Vector3(x1-0.010,y1,z0+0.002),
        Vector3(x1-0.010,y1,z1-0.002),
        Vector3(x0+0.010,y1,z1-0.002)
    ]
    for i in range(4):
        var nxt: int = (i+1)%4
        Hero._tri(st,verts[i],verts[nxt],verts[nxt+4])
        Hero._tri(st,verts[i],verts[nxt+4],verts[i+4])
    Hero._tri(st,verts[4],verts[5],verts[6])
    Hero._tri(st,verts[4],verts[6],verts[7])

static func _tread_mesh() -> ArrayMesh:
    if _shared_tread != null:
        return _shared_tread
    var perimeter := [
        Vector2(-0.074,-0.050),Vector2(0.074,-0.050),
        Vector2(0.080,-0.037),Vector2(0.080,0.037),
        Vector2(0.074,0.050),Vector2(-0.074,0.050),
        Vector2(-0.080,0.037),Vector2(-0.080,-0.037)
    ]
    var rings: Array = []
    for section in [[-0.035,0.85],[-0.025,1.0],
            [0.025,1.0],[0.035,0.85]]:
        var ring: Array = []
        for p in perimeter:
            ring.append(Vector3(p.x*float(section[1]),
                float(section[0]),p.y*float(section[1])))
        rings.append(ring)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for section in range(rings.size()-1):
        var bottom: Array = rings[section]
        var top: Array = rings[section+1]
        for i in range(perimeter.size()):
            var nxt: int = (i+1)%perimeter.size()
            Hero._tri(st,bottom[i],bottom[nxt],top[nxt])
            Hero._tri(st,bottom[i],top[nxt],top[i])
    for i in range(perimeter.size()):
        var nxt: int = (i+1)%perimeter.size()
        Hero._tri(st,Vector3(0,-0.035,0),rings[0][nxt],rings[0][i])
        Hero._tri(st,Vector3(0,0.035,0),rings[3][i],rings[3][nxt])
    _shared_tread = st.commit()
    _shared_tread.surface_set_material(0,_strip(RUBBER,0.21,0.86))
    var cleats := SurfaceTool.new()
    cleats.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1,1]:
        for groove in [-1,1]:
            _raised_rib(cleats,side,float(groove)*0.025)
    cleats.commit(_shared_tread)
    _shared_tread.surface_set_material(1,_strip(GASKET,0.38,0.71))
    return _shared_tread

static func _barbette_mesh() -> ArrayMesh:
    # Welded armored annulus directly ON the original hull deck, beneath
    # the turret yaw pivot. The overlap hides the formerly airborne seam.
    # No second dummy turret or extra pivot; only the static bearing rim.
    var rings: Array = []
    var sections := [
        Vector2(0.474,1.096),Vector2(0.571,1.096),
        Vector2(0.595,1.116),Vector2(0.595,1.148),
        Vector2(0.553,1.166),Vector2(0.493,1.166),
        Vector2(0.475,1.145)
    ]
    const SEGMENTS := 40
    for p in sections:
        var ring: Array = []
        for index in range(SEGMENTS):
            var theta: float = TAU*float(index)/float(SEGMENTS)
            ring.append(Vector3(p.x*cos(theta),p.y,p.x*sin(theta)))
        rings.append(ring)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for step in range(rings.size()):
        var ring: Array = rings[step]
        var following: Array = rings[(step+1)%rings.size()]
        for i in range(SEGMENTS):
            var nxt: int = (i+1)%SEGMENTS
            Hero._tri(st,ring[i],ring[nxt],following[nxt])
            Hero._tri(st,ring[i],following[nxt],following[i])
    return st.commit()

static func _rebuild_shell(model: Node3D) -> int:
    var count := 0
    # Lower turret ring is taper-matched to the barrel, cheek guards, and
    # steel barbette. The primary *existing* turret is resculpted in-place.
    if V20._swap_loft(model,"TorreBajaSoldadaV7",[
        Vector2(-0.195,-1.785),Vector2(0.195,-1.785),
        Vector2(0.531,-1.498),Vector2(0.877,-0.934),
        Vector2(1.003,-0.397),Vector2(0.975,0.442),
        Vector2(0.821,0.975),Vector2(0.553,1.255),
        Vector2(-0.553,1.255),Vector2(-0.821,0.975),
        Vector2(-0.975,0.442),Vector2(-1.003,-0.397),
        Vector2(-0.877,-0.934),Vector2(-0.531,-1.498)
    ],[[0.022,0.68,0.009],[0.089,0.864,0.018],
        [0.174,0.990,0.034],[0.381,1.003,0.047],
        [0.608,0.902,0.063],[0.668,0.782,0.070]]):
        count+=1
    # Center-line glacis and shoulders are materially continuous with the
    # primary V18 hull and V20 flanks. Replace the old nose in-place.
    if V20._swap_loft(model,"G09V14QuillaFrontal",[
        Vector2(-0.158,-2.080),Vector2(0.158,-2.080),
        Vector2(0.410,-1.746),Vector2(-0.410,-1.746)
    ],[[0.664,0.871,0.025],[0.841,1.000,0.061],
        [1.014,0.851,0.105]]):
        count+=1
    for side in [-1,1]:
        if V20._swap_loft(model,
                "G09V14AlaBlindadaFrontal_%s" % side,
                V20._mirrored(side,[
            Vector2(0.413,-1.753),Vector2(0.747,-1.851),
            Vector2(1.020,-1.670),Vector2(1.309,-1.312),
            Vector2(1.320,-0.815),Vector2(1.093,-0.729),
            Vector2(0.636,-1.109)
        ]),[[0.799,0.911,0.025],[0.963,1.001,0.053],
            [1.073,0.892,0.093]]):
            count+=1
        var panel: MeshInstance3D = model.find_child(
            "G09V14AlaBlindadaFrontal_%s" % side,true,false) as MeshInstance3D
        panel.material_override = Hero._army_material(CERAMIC,true)
    return count

static func hide_legacy(model: Node3D) -> void:
    if model == null or not model.get_meta("tarvoka_mbt_finish_v21",false):
        return
    # Retire only V7's separate raised prototype bumper/ramp, never the
    # V14/V21 replaced original nose parts or faction enamel surfaces.
    for label in LEGACY_FRONT:
        var old: Node3D = model.find_child(label,true,false) as Node3D
        if old != null:
            old.visible = false

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta(
            "tarvoka_mbt_integrated_v20",false):
        return false
    if model.find_child(ROOT,true,false)!=null:
        return false
    var hull: Node3D = model.find_child(
        "ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child(
        "TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    for label in ["TorreBajaSoldadaV7","G09V14QuillaFrontal",
            "G09V14AlaBlindadaFrontal_-1",
            "G09V14AlaBlindadaFrontal_1"]:
        if not (model.find_child(label,true,false) is MeshInstance3D):
            return false
    for side in [-1,1]:
        for i in range(7):
            if not (model.find_child(
                    "RuedaG09V7_%s_%02d" % [side,i],
                    true,false) is MeshInstance3D):
                return false
        var tread: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,
            true,false) as MultiMeshInstance3D
        if tread == null or tread.multimesh == null or (
                tread.multimesh.instance_count!=TREADS_PER_SIDE):
            return false
    var changed: int = _rebuild_shell(model)
    var wheel_mesh: ArrayMesh = _wheel_mesh()
    for side in [-1,1]:
        for i in range(7):
            var wheel: MeshInstance3D = model.find_child(
                "RuedaG09V7_%s_%02d" % [side,i],
                true,false) as MeshInstance3D
            wheel.mesh = wheel_mesh
            # Two distinct surface materials, not a single dark override.
            wheel.material_override = null
            changed+=1
        var belt: MultiMeshInstance3D = model.find_child(
            "OrugaArticuladaG09V7_%s" % side,
            true,false) as MultiMeshInstance3D
        belt.multimesh.mesh = _tread_mesh()
        belt.material_override = null
    var rim := MeshInstance3D.new()
    rim.name = "G09V21CoronaBarbeta"
    rim.mesh = _barbette_mesh()
    rim.material_override = _strip(GASKET,0.41,0.74)
    hull.add_child(rim)
    if changed!=CHANGED_PRIMARY_MESHES:
        rim.free()
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_finish_v21",true)
    model.set_meta("tarvoka_mbt_finish_v21_meshes",changed)
    model.set_meta("tarvoka_mbt_finish_v21_tread_instances",TREADS_PER_SIDE*2)
    hide_legacy(model)
    return true
