extends RefCounted
class_name TarvokaTankProduction3D

# G09 final mechanical detailing pass. Only cosmetic Godot geometry is added.
# This stays separate from tactical stats and never replaces any of the 14
# official faction paint zones, cannon pivot, wheels or five wreck stages.
const Finish = preload("res://scripts/ui/TankFinish3D.gd")
const ROOT := "G09ComponentesDeProduccion"
const STEEL := Color("#526268")
const PALE := Color("#77868B")
const BLACK := Color("#202A30")
const OPTIC := Color("#315F73")
const DIRT := Color("#5E625B")

static func _mat(color: Color, rough: float = 0.69, metallic: float = 0.30) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = rough
    material.metallic = metallic
    return material

static func _rod(parent: Node3D, name: String, start: Vector3, finish: Vector3,
        r: float = 0.018, color: Color = STEEL) -> MeshInstance3D:
    return Finish._rod(parent,name,start,finish,r,color,8)

static func _box(parent: Node3D, name: String, center: Vector3,
        size: Vector3, color: Color = STEEL,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return Finish._box(parent,name,center,size,color,rotation)

static func _tube(parent: Node3D, name: String, center: Vector3,
        outer: float, inner: float, rotation: Vector3) -> MeshInstance3D:
    var result := MeshInstance3D.new()
    result.name = name
    var ring := TorusMesh.new()
    ring.inner_radius = inner
    ring.outer_radius = outer
    ring.rings = 8
    ring.ring_segments = 18
    result.mesh = ring
    result.material_override = _mat(PALE,0.53,0.47)
    result.position = center
    result.rotation_degrees = rotation
    parent.add_child(result)
    return result

static func _batched(parent: Node3D, name: String, shapes: Array,
        base_size: Vector3, color: Color) -> MultiMeshInstance3D:
    var component := MultiMeshInstance3D.new()
    component.name = name
    var brick := BoxMesh.new()
    brick.size = base_size
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = brick
    batch.instance_count = shapes.size()
    for i in range(shapes.size()):
        batch.set_instance_transform(i,shapes[i])
    component.multimesh = batch
    component.material_override = _mat(color,0.81,0.18)
    parent.add_child(component)
    return component

static func apply(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var cannon: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    if hull == null or turret == null or cannon == null:
        return false
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)

    # Existing flat side ERA blocks appear like toy bricks from the Android
    # turntable. Replace their visible shapes with chamfered armor plates, but
    # retain the original nodes for migration/animation compatibility.
    for side in [-1,1]:
        var sign: float = float(side)
        for n in range(3):
            var original: MeshInstance3D = turret.find_child(
                "ProteccionERA%s_%d" % [side,n],true,false) as MeshInstance3D
            if original != null:
                original.visible = false
            var plate := Finish._bevel(turret,
                "ERACompuestaBiselada%s_%d" % [side,n],
                Vector3(sign*0.686,0.245,-0.45+float(n)*0.39),
                Vector3(0.112,0.233,0.292),0.041,STEEL)
            plate.rotation_degrees.z = sign*5.0

        # Solid armored track covers: sunken guide rollers, drive sprocket
        # teeth and heavy steel side rail, all anchored to the static chassis.
        _rod(hull,"CanalSuspension%s" % side,
            Vector3(sign*1.31,0.44,-1.08),
            Vector3(sign*1.31,0.44,1.12),0.018,BLACK)
        for n in range(2):
            var z: float = -1.24 if n == 0 else 1.24
            _tube(hull,"AroRuedaMotriz%s_%d" % [side,n],
                Vector3(sign*1.335,0.305,z),
                0.232,0.206,Vector3(0,0,90))
        _rod(hull,"PestanaGuardafangos%s" % side,
            Vector3(sign*1.26,0.89,-1.38),
            Vector3(sign*1.26,0.87,1.39),0.023,BLACK)

        # Folded steel rear storage cage rather than a closed cuboid box.
        _rod(turret,"BarraCestaSuperior%s" % side,
            Vector3(sign*0.73,0.52,0.65),
            Vector3(sign*0.75,0.52,1.06),0.027,PALE)
        _rod(turret,"BarraCestaInferior%s" % side,
            Vector3(sign*0.72,0.15,0.66),
            Vector3(sign*0.75,0.15,1.06),0.027,PALE)
        _rod(turret,"CruzCestaPosterior%s" % side,
            Vector3(sign*0.74,0.15,1.06),
            Vector3(sign*0.75,0.52,1.06),0.027,PALE)
        _box(turret,"BolsaLonaEstiba%s" % side,
            Vector3(sign*0.63,0.20,0.83),
            Vector3(0.19,0.19,0.28),DIRT,Vector3(0,sign*12,0))

        # Front mudguard brackets and physical towing hook loops.
        _rod(hull,"BarraProtegeFaro%s" % side,
            Vector3(sign*0.83,0.94,-1.52),
            Vector3(sign*0.83,0.76,-1.52),0.023,BLACK)
        _rod(hull,"SoporteGuardabarros%s" % side,
            Vector3(sign*1.05,0.74,-1.45),
            Vector3(sign*1.18,0.62,-1.50),0.024,STEEL)
        # Sculpted commander's and gunner's side optics.
        _box(turret,"ModuloLASERBlindado%s" % side,
            Vector3(sign*0.43,0.58,-0.52),
            Vector3(0.16,0.18,0.19),BLACK)
        _box(turret,"CristalTelescopio%s" % side,
            Vector3(sign*0.43,0.59,-0.623),
            Vector3(0.12,0.11,0.014),OPTIC)

    # Breech and barrel realism: replace the toy-like uninterrupted tube with
    # an internal black bore, clamping collars and a slim dark reference mark.
    # The whole assembly belongs to ElevacionCanon so recoil/elevation is real.
    _tube(cannon,"AroBocaPrincipal",Vector3(0,0,-2.514),0.154,0.122,
        Vector3(90,0,0))
    var bore := MeshInstance3D.new()
    bore.name = "InteriorOscuroCanon"
    var bore_mesh := CylinderMesh.new()
    bore_mesh.top_radius = 0.069
    bore_mesh.bottom_radius = 0.069
    bore_mesh.height = 0.012
    bore_mesh.radial_segments = 16
    bore.mesh = bore_mesh
    bore.material_override = _mat(Color("#0E171C"),0.97,0.05)
    bore.position = Vector3(0,0,-2.522)
    bore.rotation_degrees.x = 90.0
    cannon.add_child(bore)
    for idx in range(2):
        _tube(cannon,"AbrazaderaManguitoCanon%d" % idx,
            Vector3(0,0,-0.47-float(idx)*0.53),0.157,0.143,
            Vector3(90,0,0))
    _box(cannon,"IndiceAlzaCanon",Vector3(0,0.126,-0.68),
        Vector3(0.036,0.018,0.16),BLACK)

    # Roof hatch suspension and asymmetric panoramic targeting cameras.
    _tube(turret,"AnilloEscotilla",Vector3(-0.37,0.640,0.12),0.278,0.241,
        Vector3.ZERO)
    _rod(turret,"TiradorEscotillaA",Vector3(-0.53,0.704,0.03),
        Vector3(-0.53,0.704,0.23),0.017,STEEL)
    _rod(turret,"TiradorEscotillaB",Vector3(-0.51,0.705,0.03),
        Vector3(-0.51,0.705,0.23),0.017,STEEL)
    _box(turret,"VisorTermicoProtegido",Vector3(0.49,0.72,-0.42),
        Vector3(0.22,0.17,0.19),BLACK)
    _box(turret,"LenteTermicoPrincipal",Vector3(0.49,0.72,-0.523),
        Vector3(0.15,0.10,0.013),OPTIC)
    _rod(turret,"CableSensorPanoramico",Vector3(0.45,0.73,0.24),
        Vector3(0.60,0.56,0.41),0.015,BLACK)

    # Vertical tool stowage, handholds and rear exhaust/chamber treatment.
    _box(hull,"TapasMantenimientoMotor",Vector3(0.0,1.069,1.17),
        Vector3(0.79,0.015,0.22),BLACK)
    for side in [-1,1]:
        var sign: float = float(side)
        _rod(hull,"AgarraderaMotor%s_A" % side,
            Vector3(sign*0.48,1.12,1.22),
            Vector3(sign*0.32,1.12,1.22),0.018,PALE)
        _rod(hull,"AgarraderaMotor%s_B" % side,
            Vector3(sign*0.48,1.12,1.22),
            Vector3(sign*0.48,1.09,1.10),0.018,PALE)

    # Cheap depth detail: three physically instanced batched arrays instead
    # of over one hundred independent objects/draw submissions on a phone.
    var nonslip: Array = []
    for side in [-1,1]:
        for z_index in range(12):
            for row in range(2):
                var x: float = float(side)*(0.64+float(row)*0.14)
                var z: float = -0.95+float(z_index)*0.185
                nonslip.append(Transform3D(Basis.IDENTITY,
                    Vector3(x,1.092,z)))
    _batched(hull,"RelieveAntideslizanteCasco",nonslip,
        Vector3(0.08,0.013,0.045),BLACK)

    var grille: Array = []
    for x_index in range(4):
        for z_index in range(7):
            grille.append(Transform3D(Basis.IDENTITY,
                Vector3(-0.49+float(x_index)*0.33,1.074,
                    0.53+float(z_index)*0.104)))
    _batched(hull,"AletasRejillaMotor",grille,
        Vector3(0.21,0.022,0.014),STEEL)

    var bolts: Array = []
    for side in [-1,1]:
        for wheel in range(7):
            for screw in range(3):
                var angle: float = TAU*float(screw)/3.0
                bolts.append(Transform3D(Basis.IDENTITY,
                    Vector3(float(side)*1.22,
                        0.29+sin(angle)*0.082,
                        -1.13+float(wheel)*0.38+cos(angle)*0.082)))
    _batched(hull,"RemachesBujesRodaje",bolts,
        Vector3(0.023,0.032,0.032),PALE)

    model.set_meta("tarvoka_mbt_production_v4",true)
    return true
