extends RefCounted
class_name TarvokaTankSilhouetteV5

# Actual structural redesign of G09. This is NOT a collection of extra
# cosmetic cubes: continuous, capped armored volumes close the exposed
# interior, replace the former turret/body silhouette and retain the native
# aiming, recoil, tracks, faction paint and independent damage graph.
const ROOT := "G09EstructuraBlindadaV5"
const DECK := Color("#626F72")
const FACE := Color("#677478")
const TURRET := Color("#59676C")
const CHEEK := Color("#78868A")
const EDGE := Color("#28363B")
const DARK := Color("#29373C")
const SHIELD := Color("#46565C")
const GASKET := Color("#1E2D32")
const DUST := Color("#666B65")

static func _material(color: Color, roughness: float = 0.71) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = 0.30
    # All armor volumes are physically capped; disabling backface removal
    # additionally prevents thin angled shell facets vanishing under WebGL.
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b-a).cross(c-a)
    if normal.length_squared() < 0.000001:
        return
    normal = normal.normalized()
    for p in [a,b,c]:
        st.set_normal(normal)
        st.set_uv(Vector2(p.x*0.46+p.z*0.18+0.5,p.y*0.65+p.z*0.25+0.5))
        st.add_vertex(p)

# Full closed shell with physical upper/lower faces and continuous sides.
# The earlier prototype sometimes appeared to reveal its interior from
# steep rear angles; these volumes have a real deck and rear bulkheads.
static func _solid_ring(parent: Node3D, label: String, bottom: Array,
        top: Array, tint: Color) -> MeshInstance3D:
    assert(bottom.size() == top.size() and bottom.size() >= 6)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center_top := Vector3.ZERO
    var center_bottom := Vector3.ZERO
    for i in range(top.size()):
        center_top += top[i]
        center_bottom += bottom[i]
    center_top /= float(top.size())
    center_bottom /= float(bottom.size())
    for i in range(top.size()):
        var next: int = (i+1) % top.size()
        _tri(st,bottom[i],top[i],top[next])
        _tri(st,bottom[i],top[next],bottom[next])
        _tri(st,center_top,top[next],top[i])
        _tri(st,center_bottom,bottom[i],bottom[next])
    var shape := MeshInstance3D.new()
    shape.name = label
    shape.mesh = st.commit()
    shape.material_override = _material(tint)
    parent.add_child(shape)
    return shape

static func _bevel(parent: Node3D, label: String, position: Vector3,
        dimensions: Vector3, bevel: float, tint: Color,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var obj: MeshInstance3D = TarvokaTankFinish3D._bevel(
        parent,label,position,dimensions,bevel,tint)
    obj.rotation_degrees = rotation
    return obj

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, tint: Color) -> MeshInstance3D:
    return TarvokaTankFinish3D._box(parent,label,at,size,tint)

static func _rod(parent: Node3D, label: String, start: Vector3,
        finish: Vector3, radius: float, tint: Color) -> MeshInstance3D:
    return TarvokaTankFinish3D._rod(parent,label,start,finish,radius,tint)

static func _hide(parent: Node3D, names: Array) -> void:
    for name in names:
        var node: Node3D = parent.find_child(str(name),true,false) as Node3D
        if node != null:
            node.visible = false

static func _raise_grille(model: Node3D) -> void:
    # Relocate (do not duplicate) the existing batched engine louvers to
    # the now truly closed roof so they remain visible from the rear.
    var grille: MultiMeshInstance3D = model.find_child(
        "AletasRejillaMotor",true,false) as MultiMeshInstance3D
    if grille == null or grille.multimesh == null:
        return
    var mesh: MultiMesh = grille.multimesh
    for i in range(mesh.instance_count):
        var original: Transform3D = mesh.get_instance_transform(i)
        original.origin.y = 1.116
        mesh.set_instance_transform(i,original)

static func apply(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    if hull == null or turret == null or gun == null:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)

    # Main change: the *complete* lower deck, front wedge and rear bulkhead
    # are one capped hull rather than two open-looking stacked trapezoids.
    var bottom := [
        Vector3(-0.51,0.32,-1.56),Vector3(0.51,0.32,-1.56),
        Vector3(0.78,0.36,-1.36),Vector3(0.91,0.36,-0.84),
        Vector3(0.91,0.36,0.88),Vector3(0.77,0.36,1.48),
        Vector3(-0.77,0.36,1.48),Vector3(-0.91,0.36,0.88),
        Vector3(-0.91,0.36,-0.84),Vector3(-0.78,0.36,-1.36)
    ]
    var upper := [
        Vector3(-0.45,0.89,-1.57),Vector3(0.45,0.89,-1.57),
        Vector3(0.66,1.02,-1.35),Vector3(0.76,1.085,-0.80),
        Vector3(0.76,1.075,0.96),Vector3(0.67,1.075,1.47),
        Vector3(-0.67,1.075,1.47),Vector3(-0.76,1.075,0.96),
        Vector3(-0.76,1.085,-0.80),Vector3(-0.66,1.02,-1.35)
    ]
    var chassis_shell := _solid_ring(hull,"CascoHermeticoV5",
        bottom,upper,DECK)

    # Permanent heavy glacis with continuous nose contour. These panels
    # overlap the deck intentionally; no open top is ever exposed.
    for side in [-1,1]:
        var sign: float = float(side)
        var plate := _bevel(hull,"CunaBlindajeFrontalV5_%s" % side,
            Vector3(sign*0.355,1.027,-1.24),
            Vector3(0.66,0.112,0.56),0.06,FACE,
            Vector3(-21.0,sign*4.0,0.0))
        _rod(hull,"SoldaduraFrontalV5_%s" % side,
            Vector3(sign*0.69,1.055,-0.99),
            Vector3(sign*0.66,1.004,-1.47),0.019,EDGE)

    # Side skirts become a continuous armoured band with a shaped upper
    # shoulder, eliminating the impression of two separate empty tracks.
    for side in [-1,1]:
        var sign: float = float(side)
        _bevel(hull,"FaldonContinuoV5_%s" % side,
            Vector3(sign*1.165,0.713,-0.015),
            Vector3(0.094,0.39,2.84),0.071,SHIELD)
        _rod(hull,"RemateSuperiorFaldonV5_%s" % side,
            Vector3(sign*1.204,0.929,-1.42),
            Vector3(sign*1.204,0.929,1.38),0.022,GASKET)
        _rod(hull,"RemateInferiorFaldonV5_%s" % side,
            Vector3(sign*1.222,0.503,-1.35),
            Vector3(sign*1.222,0.503,1.29),0.025,EDGE)

        # Low, sloping side composite armor replaces a row of tall gray
        # cuboids on the engine deck.
        for idx in range(4):
            var z: float = -0.99 + float(idx)*0.59
            _bevel(hull,"LomaBlindajeMotorV5_%s_%d" % [side,idx],
                Vector3(sign*0.666,1.121,z),
                Vector3(0.217,0.084,0.517),0.041,FACE,
                Vector3(0.0,0.0,-sign*7.0))
        _bevel(hull,"CubiertaPasadorFaroV5_%s" % side,
            Vector3(sign*0.61,0.838,-1.48),
            Vector3(0.26,0.22,0.12),0.047,EDGE)

    # A real bulkhead closes the rear. Its upper strip is below the engine
    # roof so it does not cover the new top ventilation slats.
    _bevel(hull,"PortonTraseroHermeticoV5",
        Vector3(0,0.72,1.476),
        Vector3(1.43,0.59,0.09),0.12,SHIELD)
    _bevel(hull,"CubiertaMotorSelladaV5",
        Vector3(0.0,1.084,1.08),
        Vector3(1.22,0.064,0.71),0.06,DARK)
    _raise_grille(model)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(hull,"CerrojoPortonV5_%s" % side,
            Vector3(sign*0.48,0.71,1.53),Vector3(0.16,0.15,0.038),EDGE)

    # The turret is substantially reshaped: lower, wider, capped, with a
    # pointed composite wedge nose and a long connected rear bustle.
    # The turret continues to rotate as one assembly with the cannon.
    var turret_low := [
        Vector3(-0.24,0.055,-1.075),Vector3(0.24,0.055,-1.075),
        Vector3(0.62,0.065,-0.94),Vector3(0.88,0.08,-0.45),
        Vector3(0.90,0.08,0.47),Vector3(0.69,0.10,1.04),
        Vector3(-0.69,0.10,1.04),Vector3(-0.90,0.08,0.47),
        Vector3(-0.88,0.08,-0.45),Vector3(-0.62,0.065,-0.94)
    ]
    var turret_top := [
        Vector3(-0.21,0.445,-1.075),Vector3(0.21,0.445,-1.075),
        Vector3(0.48,0.575,-0.84),Vector3(0.68,0.625,-0.38),
        Vector3(0.69,0.625,0.43),Vector3(0.56,0.55,1.06),
        Vector3(-0.56,0.55,1.06),Vector3(-0.69,0.625,0.43),
        Vector3(-0.68,0.625,-0.38),Vector3(-0.48,0.575,-0.84)
    ]
    var turret_shell := _solid_ring(turret,"TorreHermeticaV5",
        turret_low,turret_top,TURRET)
    _bevel(turret,"BastidorTraseroIntegradoV5",
        Vector3(0.0,0.31,0.96),Vector3(1.12,0.35,0.43),
        0.078,TURRET)
    _bevel(turret,"TapaCestaBlindadaV5",
        Vector3(0,0.53,0.96),Vector3(0.99,0.067,0.45),
        0.034,SHIELD)
    for side in [-1,1]:
        var sign: float = float(side)
        var cheek := _bevel(turret,"MejillaPrincipalV5_%s" % side,
            Vector3(sign*0.48,0.325,-0.81),
            Vector3(0.49,0.305,0.56),0.13,CHEEK,
            Vector3(-10.0,sign*24.0,-sign*6.0))
        _bevel(turret,"LaminaExteriorTorreV5_%s" % side,
            Vector3(sign*0.804,0.33,0.07),
            Vector3(0.088,0.25,0.62),0.038,SHIELD,
            Vector3(0,sign*5.0,0))
        _rod(turret,"CordoncilloRefuerzoV5_%s" % side,
            Vector3(sign*0.712,0.548,-0.63),
            Vector3(sign*0.764,0.556,0.45),0.022,EDGE)
        _bevel(turret,"ProteccionBastidorPosteriorV5_%s" % side,
            Vector3(sign*0.58,0.29,0.876),
            Vector3(0.26,0.29,0.39),0.07,SHIELD)

    # Remove prototyping cubes that sit above / float through the new roof.
    # All visual weapon pivots, emitter nodes and faction markings survive.
    _hide(hull,[
        "ModuloERAChasis-1_00","ModuloERAChasis-1_01",
        "ModuloERAChasis-1_02","ModuloERAChasis-1_03",
        "ModuloERAChasis1_00","ModuloERAChasis1_01",
        "ModuloERAChasis1_02","ModuloERAChasis1_03",
        "CubiertaMotor","RejillaMotor_00","RejillaMotor_01",
        "RejillaMotor_02","RejillaMotor_03","RejillaMotor_04",
        "RejillaMotor_05","RejillaMotor_06","RejillaMotor_07",
        "PlacaBasalFrontal","NervioProa"])
    _hide(turret,["CestaEquipamiento-1","CestaEquipamiento1",
        "MejillaCeramicaBiselada-1","MejillaCeramicaBiselada1",
        "ERACompuestaBiselada-1_0","ERACompuestaBiselada-1_1",
        "ERACompuestaBiselada-1_2","ERACompuestaBiselada1_0",
        "ERACompuestaBiselada1_1","ERACompuestaBiselada1_2",
        "ProteccionERA-1_0","ProteccionERA-1_1","ProteccionERA-1_2",
        "ProteccionERA1_0","ProteccionERA1_1","ProteccionERA1_2",
        "PanelServicioTorre"])
    # The old block mantlet is visibly disconnected. Replace it with a
    # chamfered bearing housing on the SAME ElevacionCanon pivot.
    _hide(gun,["EscudoMantlete"])
    _bevel(gun,"MantleteMonoliticoV5",Vector3(0,0.01,-0.30),
        Vector3(0.56,0.42,0.33),0.095,TURRET)
    _bevel(gun,"AroSelladoCanonV5",Vector3(0,0,-0.49),
        Vector3(0.37,0.31,0.105),0.07,EDGE)
    model.set_meta("tarvoka_mbt_silhouette_v5",true)
    return true
