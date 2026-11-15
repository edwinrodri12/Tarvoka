extends RefCounted
class_name TarvokaG11AftPodFinishV15

# V15 is real native Godot geometry on the existing G11 rocket pod.
# Adds rear silhouettes and material depth only; does not replace V13 sprockets,
# V14 hoses, V11 open launch apertures, or any combat/economy values.
const FLAG := "tarvoka_g11_aft_pod_finish_v15"
const ELEVATION := "G11_ElevacionLanzador"
const FRAME_Y := 0.493
const REAR_Z := 0.927
const _SIDES := [-1,1]
const _DAMAGE_MODERATE := "G11V15_DesgasteCostados"
const _DAMAGE_CRITICAL := "G11V15_PanelDoblado"

static func _mat(tint: Color, metal: float, rough: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = tint
    result.metallic = metal
    result.roughness = rough
    result.cull_mode = BaseMaterial3D.CULL_DISABLED
    return result

static func _tri(tool: SurfaceTool, a: Vector3,b: Vector3,c: Vector3) -> void:
    tool.add_vertex(a)
    tool.add_vertex(b)
    tool.add_vertex(c)

static func _quad(tool: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    _tri(tool,a,b,c)
    _tri(tool,a,c,d)

static func _mesh(parent: Node3D, name: String, shape: Mesh,
        position: Vector3, material: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = name
    item.mesh = shape
    item.position = position
    item.material_override = material
    parent.add_child(item)
    return item

static func _box(parent: Node3D, name: String, position: Vector3,
        size: Vector3, material: Material) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size = size
    return _mesh(parent,name,shape,position,material)

static func _cyl(parent: Node3D, name: String, position: Vector3,
        radius: float, length: float, material: Material,
        orient: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = length
    shape.radial_segments = 10
    var item := _mesh(parent,name,shape,position,material)
    item.rotation_degrees = orient
    return item

static func _extrude_x(outline: PackedVector2Array, thickness: float) -> ArrayMesh:
    # A fully closed seven-sided armor shell across real X thickness.
    # Outline coordinates are Y/Z, so panels can retain angular, sloped
    # silhouettes rather than stacking square cubes against the pod.
    var out := SurfaceTool.new()
    out.begin(Mesh.PRIMITIVE_TRIANGLES)
    var centroid := Vector2.ZERO
    for p in outline:
        centroid += p
    centroid /= float(outline.size())
    var half: float = thickness*0.5
    for i in range(outline.size()):
        var j: int = (i+1)%outline.size()
        var a: Vector2 = outline[i]
        var b: Vector2 = outline[j]
        _tri(out,Vector3(half,centroid.x,centroid.y),
            Vector3(half,a.x,a.y),Vector3(half,b.x,b.y))
        _tri(out,Vector3(-half,centroid.x,centroid.y),
            Vector3(-half,b.x,b.y),Vector3(-half,a.x,a.y))
        _quad(out,Vector3(-half,a.x,a.y),Vector3(-half,b.x,b.y),
            Vector3(half,b.x,b.y),Vector3(half,a.x,a.y))
    out.generate_normals()
    return out.commit()

static func _octagonal_beam(width: float, height: float,
        depth: float, bevel: float) -> ArrayMesh:
    # Eight physical corners, not a normal-map illusion; longitudinal Z
    # extrusion is rotated on the X axis for rear cross-members.
    var hx: float = width*0.5
    var hy: float = height*0.5
    var bevel_size: float = minf(bevel,minf(hx*0.48,hy*0.48))
    var profile: PackedVector2Array = PackedVector2Array([
        Vector2(-hx+bevel_size,-hy),
        Vector2(hx-bevel_size,-hy),
        Vector2(hx,-hy+bevel_size),
        Vector2(hx,hy-bevel_size),
        Vector2(hx-bevel_size,hy),
        Vector2(-hx+bevel_size,hy),
        Vector2(-hx,hy-bevel_size),
        Vector2(-hx,-hy+bevel_size)])
    var out := SurfaceTool.new()
    out.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(profile.size()):
        var j: int = (i+1)%profile.size()
        var a: Vector2 = profile[i]
        var b: Vector2 = profile[j]
        _quad(out,Vector3(a.x,a.y,-depth*0.5),
            Vector3(b.x,b.y,-depth*0.5),
            Vector3(b.x,b.y,depth*0.5),
            Vector3(a.x,a.y,depth*0.5))
        _tri(out,Vector3(0,0,-depth*0.5),
            Vector3(b.x,b.y,-depth*0.5),
            Vector3(a.x,a.y,-depth*0.5))
        _tri(out,Vector3(0,0,depth*0.5),
            Vector3(a.x,a.y,depth*0.5),
            Vector3(b.x,b.y,depth*0.5))
    out.generate_normals()
    return out.commit()

static func apply(model: Node3D, faction: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_mechanical_detail_v14",false)):
        return false
    var pod := model.find_child(ELEVATION,true,false) as Node3D
    var roof := model.find_child("G11_TapaSuperior",true,false) as MeshInstance3D
    if pod == null or roof == null or not roof.material_override is StandardMaterial3D:
        return false
    # V15 finishes the back half only. The 4x3 rocket mouths, the V14
    # maintenance door, and all V13 faction-colored roof meshes are untouched.
    for part_name in ["G11_Tubo_0_0","G11_Tubo_3_2",
            "G11V14_PuertaRegistro","G11V14_Manguera_-1_0_00",
            "G11V13_PanelFaccionLanzador_1"]:
        if model.find_child(part_name,true,false) == null:
            return false
    var slate := _mat(Color("#536663"),0.61,0.57)
    var edge := _mat(Color("#263234"),0.37,0.77)
    var metal := _mat(Color("#82928e"),0.72,0.49)
    var shade := _mat(Color("#1a2527"),0.25,0.86)
    var bright := _mat(Color("#b2bfb8"),0.78,0.43)
    var paint := _mat(faction.darkened(0.10),0.38,0.55)

    # Beveled cross-members make the afterbody read as a real armored
    # mechanism. The center of the aft face remains free for the V14 door.
    var beam := _octagonal_beam(0.113,0.087,1.235,0.023)
    for tier in [0,1]:
        var y: float = FRAME_Y if tier == 0 else -0.456
        var bar := _mesh(pod,"G11V15_TravesanoTrasero_%d" % tier,
            beam,Vector3(0,y,REAR_Z),slate if tier == 0 else edge)
        bar.rotation_degrees.y = 90.0
    var vertical := _octagonal_beam(0.083,0.095,0.895,0.021)
    for side in _SIDES:
        var sign: float = float(side)
        # Rotated Z extrusion follows Y, forming two real upright braces.
        var upright := _mesh(pod,"G11V15_MontanteTrasero_%d" % side,
            vertical,Vector3(sign*0.608,0.020,REAR_Z),slate)
        upright.rotation_degrees.x = 90.0

    # Closed tapered cheeks at the rear, elevated above the V14 hose ports
    # and above its separately hinged lower service access.
    var cheeks := _extrude_x(PackedVector2Array([
        Vector2(0.170,0.240),
        Vector2(0.317,0.240),
        Vector2(0.455,0.355),
        Vector2(0.455,0.640),
        Vector2(0.340,0.802),
        Vector2(0.207,0.802),
        Vector2(0.160,0.690)]),0.059)
    var inset := _extrude_x(PackedVector2Array([
        Vector2(0.279,0.382),
        Vector2(0.364,0.399),
        Vector2(0.381,0.588),
        Vector2(0.305,0.660)]),0.016)
    for side in _SIDES:
        var sign: float = float(side)
        _mesh(pod,"G11V15_CacheteAftBiselado_%d" % side,
            cheeks,Vector3(sign*0.750,0,0),slate)
        _mesh(pod,"G11V15_RecesoSuperior_%d" % side,
            inset,Vector3(sign*0.787,0,0),edge)
        # A restrained faction accent sits flush on this REAL side surface.
        # Unlike the old V1 side cubes it is framed by chamfered armor.
        _box(pod,"G11V15_FraccionCostado_%d" % side,
            Vector3(sign*0.800,0.341,0.524),
            Vector3(0.012,0.046,0.172),paint)
        # Side depth: isolated rib and bolt bosses keep the new panel from
        # looking like a flat painted plastic slab.
        _box(pod,"G11V15_NervioBajo_%d" % side,
            Vector3(sign*0.794,0.198,0.538),
            Vector3(0.026,0.025,0.425),metal)
        for bolt_id in range(3):
            _cyl(pod,"G11V15_TornilloCachete_%d_%d" % [side,bolt_id],
                Vector3(sign*0.805,0.234,0.311+float(bolt_id)*0.200),
                0.019,0.013,bright,Vector3(0,0,90))

    # Deep aft ventilation. The black recess is behind six distinct 3D
    # louvers, below the cross-member and clear of the central service hatch.
    _box(pod,"G11V15_RespiraderoTrasero",
        Vector3(0,0.347,0.981),Vector3(0.470,0.104,0.029),shade)
    for slot in range(6):
        _box(pod,"G11V15_LamaRespiradero_%02d" % slot,
            Vector3(-0.187+float(slot)*0.075,0.346,1.001),
            Vector3(0.019,0.076,0.016),metal)
    # Recessed red optical marker on the rear to distinguish the vehicle's
    # orientation in the tactical isometric camera. No light source allocated.
    _box(pod,"G11V15_SenalPanelPosterior",
        Vector3(0,0.417,1.004),Vector3(0.097,0.018,0.014),
        _mat(Color("#a64e3b"),0.28,0.47))

    var moderate := Node3D.new()
    moderate.name = _DAMAGE_MODERATE
    moderate.visible = false
    pod.add_child(moderate)
    for side in _SIDES:
        var sign: float = float(side)
        var scuff := _box(moderate,"G11V15_MarcaRaspado_%d" % side,
            Vector3(sign*0.814,0.352,0.575),
            Vector3(0.015,0.019,0.173),shade)
        scuff.rotation_degrees.x = 24.0
    var critical := Node3D.new()
    critical.name = _DAMAGE_CRITICAL
    critical.visible = false
    pod.add_child(critical)
    var broken := _box(critical,"G11V15_BordeTorcido",
        Vector3(0.105,0.507,0.930),
        Vector3(0.33,0.062,0.080),edge)
    broken.rotation_degrees = Vector3(19,12,14)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v15_chamfered_cheeks",2)
    model.set_meta("tarvoka_g11_v15_rear_louvers",6)
    return set_stage(model,0)

static func set_stage(model: Node3D, stage: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var moderate := model.find_child(
        _DAMAGE_MODERATE,true,false) as Node3D
    var critical := model.find_child(
        _DAMAGE_CRITICAL,true,false) as Node3D
    if moderate == null or critical == null:
        return false
    moderate.visible = stage >= 2 and stage < 4
    critical.visible = stage >= 3 and stage < 4
    return true
