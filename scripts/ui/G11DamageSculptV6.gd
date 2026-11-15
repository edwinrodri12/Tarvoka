extends RefCounted
class_name TarvokaG11DamageSculptV6

# G11 V6 studio-only sculpt: genuine deformed armor, embedded impact craters,
# exposed engine bay, torn ribs and structural wreckage. Pure presentation.
# All damage layers are reversible; no game HP, ammo or statistics are touched.
const FLAG := "tarvoka_g11_damage_v6"
const ROOT := "G11_CascoRaiz"
const STAGES := 5
const CRATER_COUNT := 3
const BENT_PANEL := "G11V2_ProteccionLateral_1"
const REAR_ANTENNA := "G11_Antena_-1"
const WRECK_MODULE := "G11_GiroPlataforma"
const _REST := "tarvoka_g11_damage_v6_rest"

static func _material(tint: Color, metal: float, roughness: float,
        emissive: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.metallic = metal
    material.roughness = roughness
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if emissive:
        material.emission_enabled = true
        material.emission = tint
        material.emission_energy_multiplier = 1.6
    return material

static func _add(parent: Node3D, label: String, mesh: Mesh,
        position: Vector3, material: Material,
        euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.position = position
    part.rotation_degrees = euler
    part.material_override = material
    parent.add_child(part)
    return part

static func _box(parent: Node3D, label: String, position: Vector3,
        size: Vector3, material: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geometry := BoxMesh.new()
    geometry.size = size
    return _add(parent,label,geometry,position,material,angles)

static func _cylinder(parent: Node3D, label: String, position: Vector3,
        radius: float, height: float, material: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = height
    shape.radial_segments = 14
    return _add(parent,label,shape,position,material,angles)

static func _sphere(parent: Node3D, label: String, position: Vector3,
        size: Vector3, material: Material) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius = 0.5
    shape.height = 1.0
    shape.radial_segments = 10
    shape.rings = 5
    var part := _add(parent,label,shape,position,material)
    part.scale = size
    return part

static func _triangle(s: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3) -> void:
    s.add_vertex(a)
    s.add_vertex(b)
    s.add_vertex(c)

static func _quad(s: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    _triangle(s,a,b,c)
    _triangle(s,a,c,d)

static func _extruded_ragged(points: Array[Vector2],
        thickness: float) -> ArrayMesh:
    # Solid jagged armor polygon, side profile (Y/Z) extruded along X.
    # Triangulated from the center: these authored shapes are convex.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center := Vector2.ZERO
    for p in points:
        center += p
    center /= float(points.size())
    var h: float = thickness*0.5
    for i in range(points.size()):
        var j: int = (i+1)%points.size()
        _triangle(st,Vector3(h,center.x,center.y),
            Vector3(h,points[i].x,points[i].y),
            Vector3(h,points[j].x,points[j].y))
        _triangle(st,Vector3(-h,center.x,center.y),
            Vector3(-h,points[j].x,points[j].y),
            Vector3(-h,points[i].x,points[i].y))
        _quad(st,Vector3(-h,points[i].x,points[i].y),
            Vector3(-h,points[j].x,points[j].y),
            Vector3(h,points[j].x,points[j].y),
            Vector3(h,points[i].x,points[i].y))
    st.generate_normals()
    return st.commit()

static func _deformed_side_plate() -> ArrayMesh:
    # Right side x-positive. Kinked surface is a sealed six-edge volume,
    # not a flat texture or a permanently attached block.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var y0 := 0.76
    var y1 := 1.13
    var z0 := -0.69
    var z1 := 0.19
    var z2 := 0.96
    var x0 := 0.770
    var x1 := 0.867
    var x2 := 0.796
    var outer: Array[Vector3] = [
        Vector3(x0,y0,z0),Vector3(x0,y1,z0),
        Vector3(x1,y0-0.055,z1),Vector3(x1+0.024,y1-0.11,z1),
        Vector3(x2,y0+0.04,z2),Vector3(x2,y1,z2)
    ]
    for k in [0,2]:
        _quad(st,outer[k],outer[k+1],outer[k+3],outer[k+2])
    # Finite thickness on the exposed damaged shield.
    for i in [0,2,4]:
        var next_index: int = (i+2)%6
        _quad(st,outer[i]-Vector3(0.038,0,0),
            outer[next_index]-Vector3(0.038,0,0),
            outer[next_index],outer[i])
        _quad(st,outer[i+1],outer[next_index+1],
            outer[next_index+1]-Vector3(0.038,0,0),
            outer[i+1]-Vector3(0.038,0,0))
    _quad(st,outer[0],outer[1],outer[1]-Vector3(0.038,0,0),
        outer[0]-Vector3(0.038,0,0))
    _quad(st,outer[4]-Vector3(0.038,0,0),
        outer[5]-Vector3(0.038,0,0),outer[5],outer[4])
    st.generate_normals()
    return st.commit()

static func _crater_mesh() -> ArrayMesh:
    # Concentric recessed ring rather than a painted circle or a full sphere.
    # Its opening sits on the slanted front armor, with a dark recessed center.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 18
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        var oa := Vector3(cos(a)*0.065,sin(a)*0.065,0.0)
        var ob := Vector3(cos(b)*0.065,sin(b)*0.065,0.0)
        var ia := Vector3(cos(a)*0.030,sin(a)*0.030,0.022)
        var ib := Vector3(cos(b)*0.030,sin(b)*0.030,0.022)
        _quad(st,oa,ob,ib,ia)
    st.generate_normals()
    return st.commit()

static func _remove(root: Node, label: String) -> void:
    var node: Node = root.find_child(label,true,false)
    if node != null:
        node.get_parent().remove_child(node)
        node.free()

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_mechanics_v5",false)):
        return false
    var root: Node3D = model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    var mild := root.find_child("G11_Dano1",true,false) as Node3D
    var medium := root.find_child("G11_Dano2",true,false) as Node3D
    var severe := root.find_child("G11_Dano3",true,false) as Node3D
    var wreck := root.find_child("G11_Dano4",true,false) as Node3D
    var bullets := root.find_child("G11_ImpactoBalas",true,false) as Node3D
    var explosive := root.find_child("G11_ImpactoExplosivo",true,false) as Node3D
    if mild == null or medium == null or severe == null or wreck == null:
        return false
    if bullets == null or explosive == null:
        return false

    var steel := _material(Color("#788581"),0.48,0.68)
    var bright := _material(Color("#b0b8b1"),0.60,0.47)
    var charred := _material(Color("#202524"),0.15,0.92)
    var burned := _material(Color("#45342c"),0.24,0.95)
    var shadow := _material(Color("#151a1a"),0.02,0.97)
    var orange := _material(Color("#f18b36"),0.06,0.40,true)

    # Stage 1: three deformed front armor impact rims with different sizes,
    # chipped strips near the cabin glass, but no floating "damage box".
    _remove(mild,"G11_ArañazosFrontales")
    var crater_geometry: ArrayMesh = _crater_mesh()
    for i in range(CRATER_COUNT):
        var px: float = -0.27+float(i)*0.26
        var py: float = 0.83+float((i+1)%2)*0.15
        var crater := _add(mild,"G11V6_CraterBala_%d" % i,
            crater_geometry,Vector3(px,py,-1.502),
            burned,Vector3(-14,0,float(i-1)*11))
        crater.scale = Vector3.ONE*(1.0+float(i)*0.15)
        _sphere(mild,"G11V6_InteriorCrater_%d" % i,
            Vector3(px,py,-1.495),Vector3(0.042,0.036,0.012),shadow)
    for i in range(3):
        _box(mild,"G11V6_RozaduraCabina_%d" % i,
            Vector3(-0.33+float(i)*0.21,1.40,-1.350),
            Vector3(0.13,0.013,0.016),bright,
            Vector3(-10,0,10+float(i)*-18))

    # Stage 2: replace the old solid box with a bent, chamfered solid shield.
    # Dark support cavity remains visible behind the buckled outer armor.
    _remove(medium,"G11_BlindajeDoblado")
    _box(medium,"G11V6_SombraBlindajeArrugado",
        Vector3(0.754,0.934,0.10),Vector3(0.033,0.34,1.40),shadow)
    _add(medium,"G11V6_PanelCostadoDeformado",
        _deformed_side_plate(),Vector3.ZERO,steel)
    _box(medium,"G11V6_CostillaCostadoDoblada",
        Vector3(0.875,0.86,0.18),Vector3(0.045,0.09,0.53),
        bright,Vector3(-7,9,0))
    _box(medium,"G11V6_CubiertaMotorAplastada",
        Vector3(-0.19,1.145,1.05),Vector3(0.58,0.06,0.39),
        burned,Vector3(-8,0,7))

    # Stage 3: unhide exposed burned metal under a torn side panel, with
    # three actual pipes and angular edge. Geometry remains tied to chassis.
    _remove(severe,"G11_PlacaDesprendida")
    _box(severe,"G11V6_CamaraServicioExpuesta",
        Vector3(-0.751,0.78,0.63),
        Vector3(0.038,0.44,0.74),shadow)
    var torn: Array[Vector2] = [
        Vector2(-0.23,-0.35),Vector2(-0.20,0.19),
        Vector2(-0.07,0.32),Vector2(0.02,0.14),
        Vector2(0.15,0.27),Vector2(0.25,-0.32)]
    var torn_panel := _add(severe,"G11V6_BlindajeRasgado",
        _extruded_ragged(torn,0.047),Vector3(-0.804,0.79,0.62),
        steel,Vector3(0,0,-12))
    torn_panel.scale.z = 1.0
    for tube in range(3):
        _cylinder(severe,"G11V6_ConductoInterior_%d" % tube,
            Vector3(-0.797,0.71+float(tube)*0.085,0.65),
            0.019,0.48,bright,Vector3(90,0,0))
    _box(severe,"G11V6_MotorQuemado",
        Vector3(0.08,1.145,1.05),
        Vector3(0.48,0.055,0.27),charred,Vector3(0,8,-10))
    _box(severe,"G11V6_BrasaMotor",
        Vector3(0.07,1.181,1.04),
        Vector3(0.19,0.012,0.13),orange)

    # Stage 4: the original large undamaged rectangular 'fallen module' was
    # fake. Replace with a torn turret cradle and resting angular wreck pieces.
    _remove(wreck,"G11_ModuloDesprendido")
    _box(wreck,"G11V6_HuecoCoronaTorreta",
        Vector3(0,1.205,0.46),Vector3(0.95,0.085,0.86),shadow)
    for i in range(3):
        var shards: Array[Vector2] = [
            Vector2(-0.12,-0.28),Vector2(0.17,-0.13),
            Vector2(0.10,0.23),Vector2(-0.09,0.29)]
        _add(wreck,"G11V6_FragmentoArrancado_%d" % i,
            _extruded_ragged(shards,0.09),
            Vector3(-0.56+float(i)*0.54,1.26,0.30+float(i%2)*0.39),
            steel,Vector3(9+float(i)*12,-19+float(i)*28,float(i)*25))
    _box(wreck,"G11V6_TuberiaRota",
        Vector3(-0.22,1.30,0.63),
        Vector3(0.09,0.11,0.78),charred,Vector3(25,6,19))
    _cylinder(wreck,"G11V6_CuerpoCilindroRoto",
        Vector3(0.35,1.37,0.50),
        0.091,0.51,burned,Vector3(16,0,76))

    # Bullet versus blast: physical shards and heat flashes are separate from
    # legacy colored spherical particles, which continue to supply soft glow.
    for i in range(4):
        _box(bullets,"G11V6_EsquirlaBala_%d" % i,
            Vector3(0.51+0.065*sin(float(i)*1.8),
                1.12+0.08*cos(float(i)), -1.51-float(i)*0.025),
            Vector3(0.017,0.085,0.020),bright,
            Vector3(10+float(i)*23,float(i)*34,float(i)*49))
    var blast_ring := TorusMesh.new()
    blast_ring.inner_radius = 0.31
    blast_ring.outer_radius = 0.43
    blast_ring.rings = 8
    blast_ring.ring_segments = 20
    _add(explosive,"G11V6_OndaExplosiva",
        blast_ring,Vector3(-0.68,1.13,0.46),
        orange,Vector3(74,18,0))
    for shard in range(5):
        _box(explosive,"G11V6_FragmentoExplosion_%d" % shard,
            Vector3(-0.67+sin(float(shard)*1.8)*0.30,
                1.17+cos(float(shard)*2.1)*0.24,
                0.46+float(shard-2)*0.12),
            Vector3(0.04,0.14,0.07),steel,
            Vector3(float(shard)*37,15,float(shard)*48))
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v6_craters",CRATER_COUNT)
    model.set_meta(_REST,true)
    update_stage(model,0)
    return true

static func update_stage(model: Node3D, level: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int = clampi(level,0,4)
    var root: Node3D = model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    # Hide the undamaged right flank only once the folded shield is installed.
    # Rebuild pristine exterior exactly on repair; no permanent deformation.
    var original: Node3D = root.find_child(BENT_PANEL,true,false) as Node3D
    if original != null:
        original.visible = stage < 2
    var antenna: Node3D = root.find_child(REAR_ANTENNA,true,false) as Node3D
    if antenna != null:
        antenna.visible = stage < 3
    var hatch: Node3D = root.find_child("G11V5_TapaEscotilla",
        true,false) as Node3D
    if hatch != null:
        hatch.visible = stage < 4
    return true
