extends RefCounted
class_name TarvokaG11SuspensionJointsV22

# Native V22 mechanical link completion. Adds only fork hinges and their
# through-pins to the ALREADY EXISTING V21 support and V5 moving wheel.
# The lower clevis is parented to chassis, NOT to the spinning wheel pivot:
# it follows wheel bounce via update_pose() without rotating with the tire.
# Cutaway is opt-in and only intended for the Studio inspection UI.
const FLAG := "tarvoka_g11_suspension_joints_v22"
const REQUIRED := "tarvoka_g11_shock_mount_finish_v21"
const CUTAWAY := "tarvoka_g11_v22_studio_cutaway_side"
const ROOT := "G11_CascoRaiz"
const AXLES := 6
const SIDE_X := 0.115
const LOWER_OFFSET_Y := 0.105
const UPPER_Y := -0.053
const EAR_X := 0.020
const EAR_WIDTH := 0.010
const PIN_LENGTH := 0.060
const PIN_RADIUS := 0.010
const LOWER_PIN_LENGTH := 0.048
const LOWER_PIN_RADIUS := 0.011
const SIDE_PARTS := ["G11_Faldon_","G11V2_ProteccionLateral_",
    "G11V2_BandaFaccion_","G11V2_BisagraFaldon_",
    "G11V18_PernosGuardabarros_","G11V12_GuardaLodoTrasera_"]
const VIS_META := "tarvoka_g11_v22_original_visibility"
static var _ear: ArrayMesh
static var _upper_pin: CylinderMesh
static var _lower_pin: CylinderMesh

static func _material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    for p in [a,b,c,a,c,d]:
        st.add_vertex(p)

static func _ear_mesh() -> ArrayMesh:
    if _ear != null:
        return _ear
    # A small, chamfered forged fork ear in YZ, extruded along X. Both
    # faces and all eight edges are actual mesh geometry, not decals.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var profile: Array[Vector2] = [
        Vector2(-0.034,-0.025),Vector2(-0.025,-0.037),
        Vector2(0.025,-0.037),Vector2(0.034,-0.025),
        Vector2(0.034,0.025),Vector2(0.025,0.037),
        Vector2(-0.025,0.037),Vector2(-0.034,0.025)
    ]
    for i in range(profile.size()):
        var p: Vector2 = profile[i]
        var q: Vector2 = profile[(i+1)%profile.size()]
        _quad(st,
            Vector3(-EAR_WIDTH*0.5,p.x,p.y),
            Vector3(-EAR_WIDTH*0.5,q.x,q.y),
            Vector3(EAR_WIDTH*0.5,q.x,q.y),
            Vector3(EAR_WIDTH*0.5,p.x,p.y))
    for k in range(1,profile.size()-1):
        for x in [-EAR_WIDTH*0.5,EAR_WIDTH*0.5]:
            var a: Vector2 = profile[0]
            var b: Vector2 = profile[k]
            var c: Vector2 = profile[k+1]
            st.add_vertex(Vector3(x,a.x,a.y))
            st.add_vertex(Vector3(x,b.x,b.y))
            st.add_vertex(Vector3(x,c.x,c.y))
    st.generate_normals()
    st.set_material(_material(Color("#72827e"),0.64,0.59))
    _ear = st.commit()
    return _ear

static func _pin(upper: bool) -> CylinderMesh:
    if upper and _upper_pin != null:
        return _upper_pin
    if not upper and _lower_pin != null:
        return _lower_pin
    var mesh := CylinderMesh.new()
    mesh.top_radius = PIN_RADIUS if upper else LOWER_PIN_RADIUS
    mesh.bottom_radius = mesh.top_radius
    mesh.height = PIN_LENGTH if upper else LOWER_PIN_LENGTH
    mesh.radial_segments = 12
    mesh.material = _material(Color("#a8b6b1"),0.82,0.39)
    if upper:
        _upper_pin = mesh
    else:
        _lower_pin = mesh
    return mesh

static func _part(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _hinge(parent: Node3D,name: String,
        upper: bool,position: Vector3) -> Node3D:
    var hinge := Node3D.new()
    hinge.name = name
    hinge.position = position
    parent.add_child(hinge)
    var ears: ArrayMesh = _ear_mesh()
    for i in range(2):
        var sign: float = -1.0 if i == 0 else 1.0
        var ear := MeshInstance3D.new()
        ear.name = "OrejaForjada_%d" % i
        ear.mesh = ears
        ear.position.x = sign*EAR_X
        hinge.add_child(ear)
    var shaft := MeshInstance3D.new()
    shaft.name = "EjeArticulacion"
    shaft.mesh = _pin(upper)
    shaft.rotation_degrees.z = 90.0
    hinge.add_child(shaft)
    return hinge

static func update_pose(model: Node3D) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var root := _part(model,ROOT)
    if root == null:
        return false
    for side in [-1,1]:
        for axle in range(AXLES):
            var key: String = "%d_%d" % [side,axle]
            var pivot := _part(root,"G11_RuedaPivot_"+key)
            var lower := _part(root,"G11V22_BisagraInferior_"+key)
            if pivot == null or lower == null:
                return false
            lower.position = pivot.position+Vector3(
                float(side)*SIDE_X,LOWER_OFFSET_Y,0.0)
            # IMPORTANT: no wheel rotation applied to this stationary pin.
            lower.rotation = Vector3.ZERO
    return true

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta(REQUIRED,false))):
        return false
    var root := _part(model,ROOT)
    if root == null:
        return false
    for side in [-1,1]:
        for axle in range(AXLES):
            var key: String = "%d_%d" % [side,axle]
            var bracket := _part(root,"G11V5_SoporteSuspension_"+key)
            var pivot := _part(root,"G11_RuedaPivot_"+key)
            var shock := _part(root,"G11V5_Amortiguador_"+key)
            var rod := _part(root,"G11V5_VastagoSuspension_"+key)
            if bracket == null or pivot == null or shock == null or rod == null:
                return false
            if _part(root,"G11V21_AsientoMuelleSuperior_"+key)==null:
                return false
            if _part(root,"G11V22_BisagraInferior_"+key)!=null:
                return false
    for side in [-1,1]:
        for axle in range(AXLES):
            var key: String = "%d_%d" % [side,axle]
            var bracket := _part(root,"G11V5_SoporteSuspension_"+key)
            _hinge(bracket,"G11V22_BisagraSuperior_"+key,true,
                Vector3(0,UPPER_Y,0))
            _hinge(root,"G11V22_BisagraInferior_"+key,false,Vector3.ZERO)
    model.set_meta(FLAG,true)
    model.set_meta(CUTAWAY,0)
    model.set_meta("tarvoka_g11_v22_genuine_fork_joints",24)
    model.set_meta("tarvoka_g11_v22_nonspinning_lower_pins",12)
    return update_pose(model)

static func set_inspection(model: Node3D,side: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    if side != -1 and side != 0 and side != 1:
        return false
    var root := _part(model,ROOT)
    if root == null:
        return false
    # Store original status only once. Never modify materials, delete
    # nodes, or touch the actual game-state/damage system.
    for actual_side in [-1,1]:
        for prefix in SIDE_PARTS:
            var panel := _part(root,prefix+str(actual_side))
            if panel == null:
                continue
            if not panel.has_meta(VIS_META):
                panel.set_meta(VIS_META,panel.visible)
            var was_visible: bool = bool(panel.get_meta(VIS_META,true))
            panel.visible = was_visible and not (
                side != 0 and actual_side == side)
        for seam in range(3):
            var seam_part := _part(root,
                "G11V2_JuntaCostado_%d_%d" % [actual_side,seam])
            if seam_part != null:
                if not seam_part.has_meta(VIS_META):
                    seam_part.set_meta(VIS_META,seam_part.visible)
                seam_part.visible = bool(seam_part.get_meta(VIS_META,true)) and (
                    side==0 or actual_side!=side)

    # V3 batched side bolts are in a 28-instance MultiMesh, not children
    # of the shields. Only 0..15 belong to the lower flank panels.
    # Preserve rear and roof hardware 16..27. Restore all original
    # transforms rather than removing actual art or adding fake rivets.
    var batch := _part(root,"G11V3_TornillosMantenimientoLote") as MultiMeshInstance3D
    if batch != null and batch.multimesh != null and (
            batch.multimesh.instance_count >= 28):
        for i in range(16):
            var key: String = "tarvoka_g11_v22_original_v3_bolt_%d" % i
            if not batch.has_meta(key):
                batch.set_meta(key,batch.multimesh.get_instance_transform(i))
            var restored: Transform3D = batch.get_meta(key)
            var bolt_side: int = -1 if i < 8 else 1
            if side!=0 and bolt_side==side:
                var suppressed: Transform3D = restored
                suppressed.basis = Basis().scaled(Vector3.ONE*0.00001)
                batch.multimesh.set_instance_transform(i,suppressed)
            else:
                batch.multimesh.set_instance_transform(i,restored)
    model.set_meta(CUTAWAY,side)
    return true
