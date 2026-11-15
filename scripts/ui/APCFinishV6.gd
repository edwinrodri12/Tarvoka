extends RefCounted
class_name TarvokaAPCFinishV6

# P06 BASTION V6: deliberate exterior/interior finish on top of the approved
# V1/V2/V3/V5 sculpt. No replacement art, HP mutation, tactics or collision.
# Lightweight mesh batches, coherent hinges and native Godot 4.3 materials.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V3 = preload("res://scripts/ui/APCFinishV3.gd")
const V5 = preload("res://scripts/ui/APCDetailV5.gd")
const ROOT := "P06V6_Remates3DIntegrados"
const FLAG := "tarvoka_apc_finish_v6"
const ROOF := "P06V6_TechoYProa"
const SIDES := "P06V6_CorazaYGuardabarros"
const INTERIOR := "P06V6_InteriorTropas"
const RAMP := "P06V6_RampaArticulada"
const TURRET := "P06V6_OpticaTorreta"
const DAMAGE := "P06V6_DanosDeSuperficie"
const STAGE := "tarvoka_apc_v6_stage"

static func _mat(color: Color, metal: float=0.30,
        roughness: float=0.74, glow: bool=false) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = metal
    result.roughness = roughness
    if glow:
        result.emission_enabled = true
        result.emission = color.darkened(0.28)
        result.emission_energy_multiplier = 0.27
    return result

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, material: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.material_override = material
    part.position = at
    part.rotation_degrees = rotation
    parent.add_child(part)
    return part

static func _node(parent: Node3D, name: String) -> Node3D:
    var n := Node3D.new()
    n.name = name
    parent.add_child(n)
    return n

static func _batch(parent: Node3D, name: String, material: Material,
        shape: Vector3, positions: Array[Vector3],
        rotations: Array[Vector3]=[]) -> int:
    if positions.is_empty():
        return 0
    var box := BoxMesh.new()
    box.size = shape
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = box
    mm.instance_count = positions.size()
    for i in range(positions.size()):
        var basis := Basis.IDENTITY
        if i < rotations.size():
            var angles: Vector3 = rotations[i] * PI/180.0
            basis = Basis.from_euler(angles)
        mm.set_instance_transform(i,Transform3D(basis,positions[i]))
    var group := MultiMeshInstance3D.new()
    group.name = name
    group.multimesh = mm
    group.material_override = material
    parent.add_child(group)
    return positions.size()

static func _front(root: Node3D, armor: Material, dark: Material,
        glass: Material, metal: Material) -> void:
    var stage := _node(root,ROOF)
    # Low-profile intake and its framing: closed on the vehicle front, not
    # floating well ahead of the wedge; 5 vanes are one draw call.
    _box(stage,"MarcoTomaRefrigeracion",Vector3(0.0,0.76,-1.484),
        Vector3(0.56,0.20,0.052),metal)
    _box(stage,"FondoTomaAire",Vector3(0.0,0.762,-1.518),
        Vector3(0.48,0.145,0.014),dark)
    var vanes: Array[Vector3] = []
    for i in range(5):
        vanes.append(Vector3(0,0.716+float(i)*0.024,-1.530))
    _batch(stage,"CincoAletasVentilacion",metal,
        Vector3(0.45,0.009,0.012),vanes)
    # Protect both driver optical ports with steel brows; the lenses remain
    # visible between the solid body and the armored thin hood.
    var eyebrows: Array[Vector3] = []
    for side in [-1,1]:
        var x: float = float(side)*0.255
        eyebrows.append(Vector3(x,1.320,-1.020))
        _box(stage,"CristalVisorLaminado_%d" % side,
            Vector3(x,1.233,-1.039),Vector3(0.258,0.059,0.014),
            glass,Vector3(-26,0,0))
    _batch(stage,"ViserasBlindadasConductores",armor,
        Vector3(0.34,0.028,0.12),eyebrows)
    # External recovery points are low, symmetrical and visibly reinforced.
    for side in [-1,1]:
        _box(stage,"SoporteArrastre_%d" % side,
            Vector3(float(side)*0.52,0.49,-1.405),
            Vector3(0.13,0.15,0.21),dark)
        _box(stage,"ArgollaArrastre_%d" % side,
            Vector3(float(side)*0.52,0.48,-1.552),
            Vector3(0.098,0.049,0.12),metal)
    _box(stage,"RegistroMantenimientoTecho",
        Vector3(0.0,1.535,0.64),Vector3(0.42,0.022,0.37),armor)
    var roof_latches: Array[Vector3] = []
    for z in [0.47,0.77]:
        for x in [-0.155,0.155]:
            roof_latches.append(Vector3(x,1.558,z))
    _batch(stage,"CuatroCierresRegistroTecho",dark,
        Vector3(0.052,0.025,0.07),roof_latches)

static func _flanks(root: Node3D, enamel: Material,
        steel: Material, dark: Material) -> int:
    var flank := _node(root,SIDES)
    # Integrated per-axle fender lips follow the actual six-wheel geometry,
    # with a 5 cm clearance above the 0.35 m tires.
    var fender_boxes: Array[Vector3] = []
    var fender_angles: Array[Vector3] = []
    var armor_fasteners: Array[Vector3] = []
    var seam_marks: Array[Vector3] = []
    for side in [-1,1]:
        var sign: float = float(side)
        for axle in range(3):
            var z: float = float(V1.WHEEL_Z[axle])
            fender_boxes.append(Vector3(sign*0.831,0.830,z))
            fender_angles.append(Vector3(0,0,sign*6.5))
            for height in [1.248,1.112]:
                for end in [-1,1]:
                    armor_fasteners.append(Vector3(sign*0.856,height,
                        z+float(end)*0.215))
        for seam_z in [-0.66,0.03,0.69]:
            seam_marks.append(Vector3(sign*0.858,1.055,seam_z))
        # Both rear service latches are at the physical edge of the troop door.
        _box(flank,"CierreRear_%d" % side,
            Vector3(sign*0.605,0.91,1.396),
            Vector3(0.070,0.13,0.08),steel)
        _box(flank,"EscaleraLateral_%d" % side,
            Vector3(sign*0.780,0.61,1.18),
            Vector3(0.11,0.035,0.27),dark)
    _batch(flank,"SeisBordesGuardabarro",enamel,
        Vector3(0.115,0.071,0.69),fender_boxes,fender_angles)
    # In the eight-faction renderer these plated fasteners are a single
    # MultiMesh; they do not make dozens of MeshInstance3D draw calls.
    var n: int = _batch(flank,"VeinticuatroPernosBlindaje",steel,
        Vector3(0.028,0.033,0.028),armor_fasteners)
    _batch(flank,"MarcasUnionesModulares",dark,
        Vector3(0.025,0.27,0.027),seam_marks)
    return n

static func _troop_bay(root: Node3D, steel: Material,
        dark: Material, caution: Material) -> void:
    var bay := _node(root,INTERIOR)
    # Visible through the opened rear ramp. Group all floor anti-slip bars.
    var strips: Array[Vector3] = []
    for i in range(8):
        strips.append(Vector3(0,0.554,0.27+float(i)*0.117))
    _batch(bay,"OchoFranjasAntideslizantes",steel,
        Vector3(0.84,0.008,0.026),strips)
    for side in [-1,1]:
        var x: float = float(side)*0.36
        _box(bay,"AsientoAcolchado_%d" % side,
            Vector3(x,0.691,0.75),Vector3(0.20,0.041,0.69),dark)
        _box(bay,"AsideroTropas_%d" % side,
            Vector3(float(side)*0.48,1.02,1.04),
            Vector3(0.028,0.025,0.39),steel)
        _box(bay,"LuzInteriorSeguridad_%d" % side,
            Vector3(float(side)*0.44,1.119,1.17),
            Vector3(0.17,0.032,0.045),caution)

static func _ramp(model: Node3D, steel: Material, dark: Material,
        enamel: Material) -> bool:
    var hinge: Node3D = model.find_child(
        "BisagraRampaP06",true,false) as Node3D
    if hinge == null:
        return false
    var stage := _node(hinge,RAMP)
    # These tracks and latches live under the rotating hinge; unlike the
    # legacy static rear strip they actually open with the hatch.
    _box(stage,"PanelRampaInterior",
        Vector3(0,0.39,0.052),Vector3(0.87,0.63,0.018),dark)
    var grip: Array[Vector3] = []
    for i in range(9):
        grip.append(Vector3(0,0.13+float(i)*0.060,0.065))
    _batch(stage,"NuevePeldañosRampa",steel,
        Vector3(0.68,0.012,0.011),grip)
    for side in [-1,1]:
        var x: float=float(side)*0.41
        _box(stage,"RefuerzoBordeRampa_%d" % side,
            Vector3(x,0.39,0.042),
            Vector3(0.055,0.62,0.052),enamel)
        _box(stage,"CerrojoGiratorioRampa_%d" % side,
            Vector3(float(side)*0.36,0.665,0.073),
            Vector3(0.065,0.084,0.064),steel)
    return true

static func _turret(model: Node3D, enamel: Material,
        dark: Material, glass: Material, steel: Material) -> bool:
    var remote: Node3D = model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    if remote == null:
        return false
    var stage := _node(remote,TURRET)
    _box(stage,"CarcasaSensorTermicoRemoto",
        Vector3(0.275,0.238,-0.247),
        Vector3(0.178,0.16,0.126),enamel)
    _box(stage,"LenteTermicaRemota",
        Vector3(0.275,0.238,-0.318),
        Vector3(0.096,0.075,0.012),glass)
    _box(stage,"SensorSecundarioZoom",
        Vector3(-0.239,0.288,-0.185),
        Vector3(0.096,0.075,0.10),dark)
    _box(stage,"VidrioSensorSecundario",
        Vector3(-0.239,0.287,-0.242),
        Vector3(0.059,0.047,0.013),glass)
    # Independent guards remain attached to the turret, not the chassis.
    for side in [-1,1]:
        _box(stage,"ProteccionEsquinasTorreta_%d" % side,
            Vector3(float(side)*0.236,0.20,0.067),
            Vector3(0.039,0.19,0.29),steel)
    return true

static func _surface_damage(root: Node3D, soot: Material,
        scratch: Material) -> void:
    var stage := _node(root,DAMAGE)
    var light := _node(stage,"P06V6_RayadurasLeves")
    light.visible = false
    _box(light,"RasponBlindajeIzquierdo",
        Vector3(-0.861,1.18,-0.34),
        Vector3(0.024,0.022,0.37),scratch,Vector3(0,0,9))
    var med := _node(stage,"P06V6_SuperficieGolpeada")
    med.visible = false
    _box(med,"ManchaImpactoFrontal",
        Vector3(-0.22,0.90,-1.506),
        Vector3(0.18,0.12,0.018),soot,Vector3(-16,0,-15))
    var heavy := _node(stage,"P06V6_ChamuscadoCritico")
    heavy.visible = false
    _box(heavy,"BlindajeQuemadoDerecha",
        Vector3(0.867,1.158,0.28),
        Vector3(0.026,0.20,0.38),soot,Vector3(0,0,9))
    # Stage 4 does not draw intact delicate details under the destroyed roof.

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model == null or not bool(model.get_meta(V5.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return false
    var root: Node3D = model.find_child(V5.ROOT,true,false) as Node3D
    if root == null:
        return false
    var v6 := _node(root,ROOT)
    var enamel := _mat(Color("#57676a").lerp(faction_color,0.49))
    var dark := _mat(Color("#202a2f"),0.10,0.95)
    var steel := _mat(Color("#68747b"),0.52,0.78)
    var glass := _mat(Color("#2e657b"),0.09,0.23)
    var signal := _mat(Color("#e0cba0"),0.09,0.39,true)
    var soot := _mat(Color("#222524"),0.08,0.95)
    var scratched := _mat(Color("#92999b"),0.54,0.81)
    _front(v6,enamel,dark,glass,steel)
    var rivets: int = _flanks(v6,enamel,steel,dark)
    _troop_bay(v6,steel,dark,signal)
    if not _ramp(model,steel,dark,enamel):
        v6.free()
        return false
    if not _turret(model,enamel,dark,glass,steel):
        v6.free()
        return false
    _surface_damage(v6,soot,scratched)
    # Existing V1 static grip strip otherwise floats at the rear when the
    # troop ramp rotates. Hide this redundant strip permanently in V6.
    var old: Node3D = model.find_child(
        "PeliculaAntideslizanteRampa",true,false) as Node3D
    if old != null:
        old.visible = false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_apc_v6_visible",true)
    model.set_meta("tarvoka_apc_v6_armored_rivets",rivets)
    model.set_meta(STAGE,0)
    return true

static func set_stage(model: Node3D, stage: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var value: int = clampi(stage,0,4)
    var level_nodes := [
        ["P06V6_RayadurasLeves",1],
        ["P06V6_SuperficieGolpeada",2],
        ["P06V6_ChamuscadoCritico",3]]
    for entry in level_nodes:
        var layer: Node3D = model.find_child(str(entry[0]),true,false) as Node3D
        if layer != null:
            layer.visible = value >= int(entry[1])
    # A destroyed APC cannot have a pristine sensor mast and roof panel.
    var enabled: bool = bool(model.get_meta("tarvoka_apc_v6_visible",true))
    for label in [ROOF,TURRET,"RegistroMantenimientoTecho"]:
        var part: Node3D = model.find_child(label,true,false) as Node3D
        if part != null:
            part.visible = enabled and value < 4
    model.set_meta(STAGE,value)
    return true

static func set_enabled(model: Node3D, show: bool) -> bool:
    if model == null or not model.get_meta(FLAG,false):
        return false
    for label in [ROOT,RAMP,TURRET]:
        var part: Node3D = model.find_child(label,true,false) as Node3D
        if part != null:
            part.visible = show
    model.set_meta("tarvoka_apc_v6_visible",show)
    if show:
        set_stage(model,int(model.get_meta(STAGE,0)))
    return true
