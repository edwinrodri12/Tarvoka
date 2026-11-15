extends RefCounted
class_name TarvokaG11SurfaceV3

# G11 V3: deterministic shader-free weathering and maintenance details.
# Studio sculpt only (level 13+). Does not modify unit stats or battle LOD.
const FLAG := "tarvoka_g11_surface_v3"
const TEXTURE_SIZE := 96
const FASTENER_COUNT := 28
static var _materials: Dictionary = {}

static func _weathered(base: Color, seed: int, metal: float, rough: float) -> StandardMaterial3D:
    var key: String = "%d_%s_%s_%s" % [seed,str(base.to_html()),str(metal),str(rough)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var image := Image.create(TEXTURE_SIZE,TEXTURE_SIZE,false,Image.FORMAT_RGBA8)
    var dust := Color("#242a2a")
    var edge := Color("#afb5af")
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            var h: int = posmod(x*73+y*191+x*y*17+seed*977,1009)
            var noise: float = float(h)/1009.0
            var weather: float = 0.015+noise*0.065
            # Dirt follows panel seams, lower edges, and drainage streaks.
            if y > 67:
                weather += float(y-67)*0.0025
            if x < 3 or x > TEXTURE_SIZE-4:
                weather += 0.085
            if posmod(x*13+y*7+seed*31,139) == 0:
                weather += 0.11
            var color: Color = base.lerp(dust,clampf(weather,0.0,0.38))
            # Small chips concentrate on edges, never a grid of stripes.
            if (x < 3 or x > TEXTURE_SIZE-4 or y < 3) and h % 17 == 0:
                color = color.lerp(edge,0.38)
            image.set_pixel(x,y,color)
    var texture := ImageTexture.create_from_image(image)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.WHITE
    material.albedo_texture = texture
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    material.metallic = metal
    material.roughness = rough
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    _materials[key] = material
    return material

static func _simple_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material

static func _box(parent: Node3D, label: String, position: Vector3,
        size: Vector3, material: StandardMaterial3D,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.material_override = material
    node.position = position
    node.rotation_degrees = rotation
    parent.add_child(node)
    return node

static func _make_fasteners(root: Node3D, mat: StandardMaterial3D) -> int:
    # Hardware reused in one GPU batch. No 28 individual MeshInstances.
    var bolt := CylinderMesh.new()
    bolt.top_radius = 0.023
    bolt.bottom_radius = 0.023
    bolt.height = 0.015
    bolt.radial_segments = 8
    bolt.material = mat
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = bolt
    mm.instance_count = FASTENER_COUNT
    var i: int = 0
    var facing := Basis(Vector3.FORWARD,PI*0.5)
    # Rivets on lower armor panels; rotate cylindrical axes toward X.
    for side in [-1,1]:
        for row in range(2):
            for z in [-0.62,-0.14,0.33,0.81]:
                var position := Vector3(float(side)*0.823,0.83+float(row)*0.23,z)
                mm.set_instance_transform(i,Transform3D(facing,position))
                i += 1
    # Hinges and fasteners on rear service hatch, axes toward Z.
    var rear_basis := Basis(Vector3.RIGHT,PI*0.5)
    for side in [-1,1]:
        for row in range(3):
            var position := Vector3(float(side)*0.48,0.47+float(row)*0.14,1.51)
            mm.set_instance_transform(i,Transform3D(rear_basis,position))
            i += 1
    # Cab roof bolt pair at the hatch.
    for x in [-0.32,0.32]:
        for z in [-1.0,-0.65,-0.33]:
            var position := Vector3(x,1.597,z)
            mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,position))
            i += 1
    var node := MultiMeshInstance3D.new()
    node.name = "G11V3_TornillosMantenimientoLote"
    node.multimesh = mm
    root.add_child(node)
    return i

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_finish_v2",false)):
        return false
    var root := model.find_child("G11_CascoRaiz",true,false) as Node3D
    if root == null:
        return false
    var steel: StandardMaterial3D = _weathered(Color("#647277"),13,0.38,0.69)
    var armor: StandardMaterial3D = _weathered(Color("#89938e"),29,0.25,0.78)
    var dark: StandardMaterial3D = _weathered(Color("#454d4e"),47,0.22,0.88)
    for name in ["G11V2_CascoOctogonalCerrado","G11V2_NarizBlindada"]:
        var piece := root.find_child(name,true,false) as MeshInstance3D
        if piece != null:
            piece.material_override = steel
    var cabin := root.find_child("G11V2_CabinaBiselada",true,false) as MeshInstance3D
    if cabin != null:
        cabin.material_override = armor
    for side in [-1,1]:
        var shield := root.find_child("G11V2_ProteccionLateral_%d" % side,true,false) as MeshInstance3D
        if shield != null:
            shield.material_override = steel
        var skirt := root.find_child("G11_Faldon_%d" % side,true,false) as MeshInstance3D
        if skirt != null:
            skirt.material_override = dark
    var turret := root.find_child("G11_GiroPlataforma",true,false) as Node3D
    if turret != null:
        var launcher := turret.find_child("G11_ElevacionLanzador",true,false) as Node3D
        if launcher != null:
            for name in ["G11_ArmazonLanzador","G11_TapaSuperior"]:
                var part := launcher.find_child(name,true,false) as MeshInstance3D
                if part != null:
                    part.material_override = armor
            for side in [-1,1]:
                var reinforcement := launcher.find_child("G11V2_NervioLateral_%d" % side,true,false) as MeshInstance3D
                if reinforcement != null:
                    reinforcement.material_override = steel
    var bolts := _simple_material(Color("#b4b9b5"),0.70,0.44)
    if _make_fasteners(root,bolts) != FASTENER_COUNT:
        return false
    var joints := _simple_material(Color("#303938"),0.23,0.88)
    var paint := _simple_material(Color("#746b5b"),0.22,0.89)
    # Panels are distinct surface-mounted geometry; tread and wheels unaffected.
    _box(root,"G11V3_ServicioTrasero",Vector3(0,0.71,1.510),
        Vector3(0.72,0.31,0.025),joints)
    _box(root,"G11V3_RejillaServicio",Vector3(0,1.068,1.03),
        Vector3(0.65,0.027,0.24),dark)
    _box(root,"G11V3_MarcaDesgasteProa",Vector3(0,0.79,-1.496),
        Vector3(0.44,0.028,0.015),paint,Vector3(0,0,-2))
    for side in [-1,1]:
        _box(root,"G11V3_CantoneraDefensa_%d" % side,
            Vector3(float(side)*0.622,0.93,-1.27),
            Vector3(0.10,0.20,0.10),steel)
        _box(root,"G11V3_SujecionOruga_%d" % side,
            Vector3(float(side)*0.760,0.756,0.94),
            Vector3(0.055,0.09,0.22),joints)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_surface_texture_size",TEXTURE_SIZE)
    model.set_meta("tarvoka_g11_fastener_count",FASTENER_COUNT)
    return true
