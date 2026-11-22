extends RefCounted
class_name TarvokaInfantryEngineerDorsalV12

# TARVOKA Engineer V12: physical dorsal-tool modules and press-formed exterior
# of the EXISTING foldable inspection shield. Art only. No defense bonus,
# cover, hitbox, new camp, repair, resource or tactical-unit changes.
const MechanicsV11 = preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const FLAG := "tarvoka_engineer_dorsal_shield_v12"
const VISIBLE := "tarvoka_engineer_dorsal_shield_v12_visible"
const ROLE := "infantry_engineer"
const CASE := "V12_EstucheDorsalContorneado"
const OUTER := "V12_CorazaExteriorBarreraCerrada"
const ACCENT := "V12_InsigniaFisicaBarrera"
const STRUT := "V12_RefuerzoPerimetralEscudo"
const RACK := "V12_SoporteEstucheFijo"

static func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color=Color(color.r,color.g,color.b,1.0)
    m.metallic=metallic
    m.roughness=roughness
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    return m

static func _part(parent: Node3D, label: String, mesh: Mesh,
        at: Vector3, paint: Material) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name=label
    part.mesh=mesh
    part.position=at
    part.material_override=paint
    parent.add_child(part)
    return part

static func _ellipsoid(parent: Node3D, label: String, at: Vector3,
        size: Vector3, paint: Material, hero: bool) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius=0.5
    shape.height=1.0
    shape.radial_segments=16 if hero else 10
    shape.rings=9 if hero else 6
    var node: MeshInstance3D=_part(parent,label,shape,at,paint)
    node.scale=size
    return node

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, paint: Material) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size=size
    return _part(parent,label,shape,at,paint)

static func _tube(parent: Node3D, label: String, start: Vector3,
        finish: Vector3, radius: float, paint: Material, hero: bool) -> MeshInstance3D:
    var delta: Vector3=finish-start
    var shape := CylinderMesh.new()
    shape.height=delta.length()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.radial_segments=12 if hero else 8
    var node: MeshInstance3D=_part(parent,label,shape,(start+finish)*0.5,paint)
    node.quaternion=Quaternion(Vector3.UP,delta.normalized())
    return node

static func _pressed(parent: Node3D, label: String, at: Vector3,
        size: Vector2, mat: Material, bulge: float=0.022) -> MeshInstance3D:
    # V11's native solid octagonal pressing closes front/back/all eight sides.
    # The exterior of the rear shield faces +Z; rotate the bulged face toward
    # the rear camera, never use a transparent or one-sided texture plane.
    var node: MeshInstance3D=MechanicsV11._pressed_plate(parent,label,at,
        size.x,size.y,0.035,0.035,bulge,mat)
    node.rotation_degrees.y=180.0
    return node

static func _find(model: Node3D, part: String) -> Node3D:
    return model.find_child(part,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _find(model,CASE+"_1")!=null and _find(model,CASE+"_-1")!=null and
        _find(model,OUTER+"_1")!=null and _find(model,OUTER+"_-1")!=null)

static func is_visible(model: Node3D) -> bool:
    return has_model(model) and bool(model.get_meta(VISIBLE,false))

# Allows a true V11/V12 comparison on the same live 3D Godot model.
# V9 tool pouches reappear when the contoured V12 pouches are hidden.
static func show_finish(model: Node3D, enabled: bool) -> bool:
    if not has_model(model):
        return false
    for node in model.find_children("V12_*","",true,false):
        if node is Node3D:
            (node as Node3D).visible=enabled
    for side in [-1,1]:
        for old in ["V9_BolsaHerramientasRig_%d"%side,
                "V9_TapaBolsaHerramientas_%d"%side,
                "V9_CierreBolsaFaccion_%d"%side,
                "V9_RemacheBolsa_%d"%side]:
            var item: Node3D=_find(model,old)
            if item!=null:
                item.visible=not enabled
    model.set_meta(VISIBLE,enabled)
    return true

static func apply(model: Node3D, faction_color: Color, hero: bool) -> bool:
    if model==null or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!=ROLE or not (
            bool(model.get_meta(MechanicsV11.FLAG,false))):
        return false
    var torso: Node3D=_find(model,"TorsoRig")
    var shield: Node3D=_find(model,"V6_BarreraArticuladaRig")
    var left: Node3D=_find(model,"V6_AlaIzquierdaRig")
    var right: Node3D=_find(model,"V6_AlaDerechaRig")
    if torso==null or shield==null or left==null or right==null:
        return false
    if shield.get_parent()!=torso or left.get_parent()!=shield or right.get_parent()!=shield:
        return false
    var ceramic := _mat(Color("#7d9598"),0.41,0.43)
    var sidewall := _mat(Color("#344548"),0.15,0.80)
    var fabric := _mat(Color("#56685d"),0.02,0.91)
    var fastener := _mat(Color("#a8babc"),0.63,0.30)
    var faction := _mat(faction_color,0.17,0.37)

    # Outer left/right armor volumes flank the existing central latch and
    # leave the horizontal V6 faction identifier at the top unobstructed.
    for side in [-1,1]:
        var x: float=float(side)
        _pressed(shield,OUTER+"_%d"%side,
            Vector3(x*0.255,-0.113,0.264),
            Vector2(0.390,0.274),ceramic,0.030)
        _pressed(shield,ACCENT+"_%d"%side,
            Vector3(x*0.280,-0.119,0.312),
            Vector2(0.162,0.090),faction,0.008)
        _ellipsoid(shield,STRUT+"_%d"%side,
            Vector3(x*0.491,-0.120,0.255),
            Vector3(0.056,0.465,0.087),sidewall,hero)
        _ellipsoid(shield,"V12_AmortiguadorAla_%d"%side,
            Vector3(x*0.538,-0.262,0.206),
            Vector3(0.089,0.084,0.102),fabric,hero)

        # Torso-fixed carrier: remains still while the independent shield
        # swivels. Side pods are rounded 3D shells, not stacked square crates.
        _ellipsoid(torso,RACK+"_%d"%side,
            Vector3(x*0.408,-0.150,0.337),
            Vector3(0.175,0.455,0.160),sidewall,hero)
        _ellipsoid(torso,CASE+"_%d"%side,
            Vector3(x*0.482,-0.224,0.339),
            Vector3(0.216,0.350,0.249),fabric,hero)
        _pressed(torso,"V12_TapaEstucheBiselada_%d"%side,
            Vector3(x*0.476,-0.099,0.185),
            Vector2(0.170,0.110),ceramic,0.012)
        _ellipsoid(torso,"V12_IdentificadorEstuche_%d"%side,
            Vector3(x*0.478,-0.138,0.117),
            Vector3(0.122,0.040,0.029),faction,hero)
        _tube(torso,"V12_CinchaCargaDorsal_%d"%side,
            Vector3(x*0.326,0.171,0.432),
            Vector3(x*0.467,-0.070,0.438),
            0.030 if hero else 0.038,fabric,hero)
        if hero:
            # Physical seams, latch heads and subtle chamfer-like guards
            # exist only at hero LOD to keep the Android profile efficient.
            for i in range(2):
                _ellipsoid(shield,"V12_RemacheExterior_%d_%d"%[side,i],
                    Vector3(x*(0.135+float(i)*0.208),-0.244,0.303),
                    Vector3(0.041,0.041,0.031),fastener,hero)
            _tube(shield,"V12_CostillaExterior_%d"%side,
                Vector3(x*0.146,-0.210,0.319),
                Vector3(x*0.374,-0.210,0.319),
                0.014,fastener,hero)
            _ellipsoid(torso,"V12_CierrePouchMetalico_%d"%side,
                Vector3(x*0.480,-0.096,0.108),
                Vector3(0.073,0.039,0.029),fastener,hero)
            for i in range(2):
                _tube(torso,"V12_CosturaEstuche_%d_%d"%[side,i],
                    Vector3(x*0.584,-0.282+float(i)*0.11,0.300),
                    Vector3(x*0.584,-0.271+float(i)*0.11,0.366),
                    0.008,sidewall,hero)

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v12_visual_only",true)
    model.set_meta("tarvoka_engineer_v12_hero",hero)
    return show_finish(model,true)
