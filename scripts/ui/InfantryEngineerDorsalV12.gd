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
const MAIN := "V12_EscudoCentralBiseladoCerrado"
const FRAME := "V12_MarcoOctagonalExterior"
const WING_SKIN := "V12_RevestimientoAlaArticulada"
const POUCH_ID := "V12_InsigniaLateralEstuche"
# V12.3 seals are all CLOSED VOLUMES on the existing animated human rigs.
# They cover genuinely exposed interior gaps, never draw fake 2-sided planes.
const SEAL := "V12_Sellado"
const SEAL_SKULL := SEAL+"CascoInterior"
const SEAL_FACE := SEAL+"FondoVisorFrontal"
const SEAL_NECK := SEAL+"CuelloContinuo"
const SEAL_TORSO := SEAL+"ToraxIntegral"
const SEAL_WAIST := SEAL+"CinturaTransicion"
const SEAL_SHOULDER := SEAL+"HombroInterno"
const SEAL_ARM := SEAL+"UniónAntebrazo"
const SEAL_HIP := SEAL+"UnionCaderaMuslo"
const SEAL_BOOT := SEAL+"UnionPantorrillaBota"
const SEAL_SHIELD := SEAL+"CantoBarrera"

static func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color=Color(color.r,color.g,color.b,1.0)
    m.metallic=metallic
    m.roughness=roughness
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    # A proper closed mesh needs exterior normals and single-sided culling.
    # Disabling backface culling would hide a topology error, not repair it.
    m.cull_mode=BaseMaterial3D.CULL_BACK
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

# A five-ring sealed tool pouch with ergonomic tapered ends and sculpted
# side walls. Unlike V9's stacked boxes and V12's first spheres, this forms
# one continuous closed 3D shell that is easy to read in profile.
static func _contoured_pouch(parent: Node3D, label: String, at: Vector3,
        paint: Material, hero: bool) -> MeshInstance3D:
    var rings: Array[Vector3]=[
        Vector3(0.062,-0.174,0.074),
        Vector3(0.099,-0.139,0.115),
        Vector3(0.116,-0.032,0.127),
        Vector3(0.106,0.107,0.115),
        Vector3(0.066,0.174,0.078)
    ]
    var segments: int=12 if hero else 8
    var mesh := SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(rings.size()-1):
        for n in range(segments):
            var a: float=TAU*float(n)/float(segments)
            var b: float=TAU*float(n+1)/float(segments)
            var low: Vector3=rings[i]
            var high: Vector3=rings[i+1]
            var a0 := Vector3(cos(a)*low.x,low.y,sin(a)*low.z)
            var b0 := Vector3(cos(b)*low.x,low.y,sin(b)*low.z)
            var a1 := Vector3(cos(a)*high.x,high.y,sin(a)*high.z)
            var b1 := Vector3(cos(b)*high.x,high.y,sin(b)*high.z)
            for vertex in [a0,a1,b0,b0,a1,b1]:
                mesh.add_vertex(vertex)
    for n in range(segments):
        var a: float=TAU*float(n)/float(segments)
        var b: float=TAU*float(n+1)/float(segments)
        var first: Vector3=rings[0]
        var last: Vector3=rings[-1]
        var low_a := Vector3(cos(a)*first.x,first.y,sin(a)*first.z)
        var low_b := Vector3(cos(b)*first.x,first.y,sin(b)*first.z)
        var high_a := Vector3(cos(a)*last.x,last.y,sin(a)*last.z)
        var high_b := Vector3(cos(b)*last.x,last.y,sin(b)*last.z)
        for vertex in [low_a,low_b,Vector3(0,first.y,0),
                Vector3(0,last.y,0),high_b,high_a]:
            mesh.add_vertex(vertex)
    mesh.generate_normals()
    return _part(parent,label,mesh.commit(),at,paint)

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
        size: Vector2, mat: Material, bulge: float=0.022,
        bevel: float=0.035) -> MeshInstance3D:
    # V11's native solid octagonal pressing closes front/back/all eight sides.
    # The exterior of the rear shield faces +Z; rotate the bulged face toward
    # the rear camera, never use a transparent or one-sided texture plane.
    var node: MeshInstance3D=MechanicsV11._pressed_plate(parent,label,at,
        size.x,size.y,0.035,bevel,bulge,mat)
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

static func has_seals(model: Node3D) -> bool:
    if not has_model(model):
        return false
    for name in [SEAL_SKULL,SEAL_FACE,SEAL_NECK,SEAL_TORSO,SEAL_WAIST]:
        if _find(model,name)==null:
            return false
    for side in [-1,1]:
        for name in [SEAL_SHOULDER,SEAL_ARM,SEAL_HIP,SEAL_BOOT,SEAL_SHIELD]:
            if _find(model,name+"_%d"%side)==null:
                return false
    return true

# Direct comparison of V12.2 vs V12.3 without rebuilding or touching any
# combat movement / rig state; used by shared Studio and native QA.
static func show_seals(model: Node3D, enabled: bool) -> bool:
    if not has_seals(model):
        return false
    for seal in model.find_children(SEAL+"*","",true,false):
        if seal is Node3D:
            (seal as Node3D).visible=enabled
    model.set_meta("tarvoka_engineer_v123_seals_visible",enabled)
    return true

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
    # D2/D3 marks stay on the visible physical cover, with the original
    # position restored whenever the viewer switches back to V11.
    for label in ["V6_RayonesD2","V6_FracturaD3"]:
        var damage_mark: Node3D=_find(model,label)
        if damage_mark!=null:
            if enabled:
                damage_mark.position.z=0.584 if label=="V6_RayonesD2" else 0.591
            else:
                damage_mark.position.z=0.232 if label=="V6_RayonesD2" else 0.240
    model.set_meta(VISIBLE,enabled)
    return true

static func apply(model: Node3D, faction_color: Color, hero: bool) -> bool:
    if model==null or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!=ROLE or not (
            bool(model.get_meta(MechanicsV11.FLAG,false))):
        return false
    var torso: Node3D=_find(model,"TorsoRig")
    var head: Node3D=_find(model,"CabezaRig")
    var hips: Node3D=_find(model,"CaderaRig")
    var shield: Node3D=_find(model,"V6_BarreraArticuladaRig")
    var left: Node3D=_find(model,"V6_AlaIzquierdaRig")
    var right: Node3D=_find(model,"V6_AlaDerechaRig")
    if torso==null or head==null or hips==null or shield==null or left==null or right==null:
        return false
    if shield.get_parent()!=torso or left.get_parent()!=shield or right.get_parent()!=shield:
        return false
    var ceramic := _mat(Color("#7d9598"),0.41,0.43)
    var sidewall := _mat(Color("#344548"),0.15,0.80)
    var fabric := _mat(Color("#56685d"),0.02,0.91)
    var fastener := _mat(Color("#a8babc"),0.63,0.30)
    var faction := _mat(faction_color,0.17,0.37)
    var inner := _mat(Color("#30433e"),0.025,0.93)
    var seal_dark := _mat(Color("#24353b"),0.09,0.86)
    var visor_back := _mat(Color("#173b4a"),0.08,0.74)

    # The original board still exists for reversible V11 comparison. The
    # new single closed, chamfered central shell covers its square silhouette
    # while preserving the whole V6 mechanical hinge and moving wings.
    # V12.1 sat behind the V6 fittings and looked almost unchanged in the
    # native camera. V12.2 brings the sculpt to the actual exterior and
    # preserves the old slab as a reversible interior structural layer.
    _pressed(shield,FRAME,Vector3(0,-0.011,0.344),
        Vector2(1.210,0.668),sidewall,0.016,0.139)
    _pressed(shield,MAIN,Vector3(0,-0.010,0.403),
        Vector2(1.155,0.606),ceramic,0.033,0.126)
    _pressed(shield,"V12_BandaFaccionSuperiorTallada",
        Vector3(0,0.177,0.464),Vector2(0.842,0.113),
        faction,0.012,0.028)
    _pressed(shield,"V12_CierreCentralMetal",
        Vector3(0,-0.221,0.470),Vector2(0.222,0.102),
        fastener,0.008,0.024)
    # Sculpted left/right plating and two vivid inset emblems.
    for side in [-1,1]:
        var x: float=float(side)
        _pressed(shield,OUTER+"_%d"%side,
            Vector3(x*0.272,-0.120,0.475),
            Vector2(0.420,0.273),ceramic,0.018,0.081)
        _pressed(shield,ACCENT+"_%d"%side,
            Vector3(x*0.284,-0.123,0.530),
            Vector2(0.247,0.098),faction,0.011,0.032)
        _pressed(shield,STRUT+"_%d"%side,
            Vector3(x*0.515,-0.117,0.473),
            Vector2(0.071,0.403),sidewall,0.010,0.020)
        var wing: Node3D=left if side<0 else right
        _pressed(wing,WING_SKIN+"_%d"%side,
            Vector3(x*0.082,-0.008,0.172),
            Vector2(0.154,0.557),ceramic,0.014,0.046)
        _pressed(wing,"V12_BandaFaccionAlaMovil_%d"%side,
            Vector3(x*0.082,0.121,0.220),
            Vector2(0.091,0.170),faction,0.010,0.023)
        _ellipsoid(shield,"V12_AmortiguadorAla_%d"%side,
            Vector3(x*0.538,-0.262,0.206),
            Vector3(0.089,0.084,0.102),fabric,hero)

        # Torso-fixed carrier: remains still while the independent shield
        # swivels. Side pods are rounded 3D shells, not stacked square crates.
        _ellipsoid(torso,RACK+"_%d"%side,
            Vector3(x*0.408,-0.150,0.337),
            Vector3(0.175,0.455,0.160),sidewall,hero)
        _contoured_pouch(torso,CASE+"_%d"%side,
            Vector3(x*0.475,-0.224,0.339),fabric,hero)
        _pressed(torso,"V12_TapaEstucheBiselada_%d"%side,
            Vector3(x*0.476,-0.099,0.185),
            Vector2(0.170,0.110),ceramic,0.012)
        _ellipsoid(torso,"V12_IdentificadorEstuche_%d"%side,
            Vector3(x*0.478,-0.138,0.117),
            Vector3(0.122,0.040,0.029),faction,hero)
        var side_plate: MeshInstance3D=_pressed(torso,POUCH_ID+"_%d"%side,
            Vector3(x*0.601,-0.238,0.336),
            Vector2(0.162,0.124),faction,0.010,0.028)
        side_plate.rotation_degrees.y=90.0*x
        _tube(torso,"V12_CinchaCargaDorsal_%d"%side,
            Vector3(x*0.326,0.171,0.432),
            Vector3(x*0.467,-0.070,0.438),
            0.030 if hero else 0.038,fabric,hero)
        if hero:
            # Physical seams, latch heads and subtle chamfer-like guards
            # exist only at hero LOD to keep the Android profile efficient.
            for i in range(2):
                _ellipsoid(shield,"V12_RemacheExterior_%d_%d"%[side,i],
                    Vector3(x*(0.135+float(i)*0.208),-0.244,0.550),
                    Vector3(0.041,0.041,0.031),fastener,hero)
            _tube(shield,"V12_CostillaExterior_%d"%side,
                Vector3(x*0.146,-0.205,0.547),
                Vector3(x*0.374,-0.205,0.547),
                0.014,fastener,hero)
            _ellipsoid(torso,"V12_CierrePouchMetalico_%d"%side,
                Vector3(x*0.480,-0.096,0.108),
                Vector3(0.073,0.039,0.029),fastener,hero)
            for i in range(2):
                _tube(torso,"V12_CosturaEstuche_%d_%d"%[side,i],
                    Vector3(x*0.584,-0.282+float(i)*0.11,0.300),
                    Vector3(x*0.584,-0.271+float(i)*0.11,0.366),
                    0.008,sidewall,hero)

    # V12.3 actual cavity closure. V9 deliberately hid the V2 head's
    # original solid shell and V2 hid stock arm/leg volumes. Low-angle
    # cameras could then look through the gaps between separate armor
    # pieces. Restore INTERNAL opaque volumes, attached to the SAME rigs.
    # Core stays behind the visible V12.2 armor; exterior design is intact.
    _ellipsoid(head,SEAL_SKULL,Vector3(0,0.244,-0.032),
        Vector3(0.448,0.475,0.438),inner,hero)
    # The eye/respirator recess must have a closed back wall, not air
    # between the front mask and the posterior helmet.
    _ellipsoid(head,SEAL_FACE,Vector3(0,0.172,-0.223),
        Vector3(0.347,0.206,0.106),visor_back,hero)
    _ellipsoid(head,SEAL_NECK,Vector3(0,-0.021,-0.006),
        Vector3(0.304,0.244,0.296),seal_dark,hero)
    _ellipsoid(torso,SEAL_TORSO,Vector3(0,-0.045,-0.046),
        Vector3(0.648,0.755,0.505),inner,hero)
    _ellipsoid(torso,SEAL_WAIST,Vector3(0,-0.416,-0.006),
        Vector3(0.550,0.235,0.352),inner,hero)
    for side in [-1,1]:
        var x: float=float(side)
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var leg: Node3D=_find(model,"PiernaRig_%d"%side)
        if arm==null or leg==null or arm.get_parent()!=torso or leg.get_parent()!=hips:
            return false
        # Torso-side material is FIXED; rotating sleeves / wrists and
        # knees remain on their animated arm/leg transforms.
        _ellipsoid(torso,SEAL_SHOULDER+"_%d"%side,
            Vector3(x*0.346,0.228,-0.014),
            Vector3(0.247,0.231,0.265),seal_dark,hero)
        _ellipsoid(arm,SEAL_ARM+"_%d"%side,
            Vector3(0,-0.637,-0.085),
            Vector3(0.237,0.224,0.250),inner,hero)
        _ellipsoid(leg,SEAL_HIP+"_%d"%side,
            Vector3(0,-0.053,0.019),
            Vector3(0.253,0.241,0.281),inner,hero)
        _ellipsoid(leg,SEAL_BOOT+"_%d"%side,
            Vector3(0,-0.765,-0.105),
            Vector3(0.230,0.213,0.257),seal_dark,hero)
        # Protect the barrier's exposed side seam in both OPEN and FOLDED
        # states without restricting, replacing or pinning the V6 hinge.
        _ellipsoid(shield,SEAL_SHIELD+"_%d"%side,
            Vector3(x*0.562,-0.101,0.273),
            Vector3(0.112,0.512,0.193),seal_dark,hero)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v12_visual_only",true)
    model.set_meta("tarvoka_engineer_v12_hero",hero)
    model.set_meta("tarvoka_engineer_v123_seals_visible",true)
    return show_finish(model,true)
