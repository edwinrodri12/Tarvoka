extends RefCounted
class_name TarvokaInfantryEngineerPremiumV8

# Engineer-specific premium art pass over the V7 sealed human silhouette.
# Fixes slab shoulders, rectangular folded rear shield and featureless rifle.
# Only opaque procedural 3D geometry. Zero changes to unit stats or camps.
const FLAG := "tarvoka_infantry_engineer_premium_v8"
const SHIELD := "V8_BarreraPanelBiselado"
const SHOULDER := "V8_HombreraAnatomica"
const RIFLE := "V8_CarcasaFusilIngeniero"
const FACTION := "V8_InsigniaBarreraPremium"

static func _coat(color: Color, metallic: float, roughness: float,
        clearcoat: bool=false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color=Color(color.r,color.g,color.b,1.0)
    material.metallic=metallic
    material.roughness=roughness
    material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    if clearcoat:
        material.clearcoat_enabled=true
        material.clearcoat=0.52
        material.clearcoat_roughness=0.27
    return material

static func _mesh(parent: Node3D, label: String, shape: Mesh,
        at: Vector3, mat: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.material_override=mat
    node.position=at
    node.rotation_degrees=rotation
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, mat: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size=size
    return _mesh(parent,label,shape,at,mat,rotation)

static func _ellipsoid(parent: Node3D, label: String, at: Vector3,
        size: Vector3, mat: Material, hero: bool) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius=0.5
    shape.height=1.0
    shape.radial_segments=16 if hero else 10
    shape.rings=8 if hero else 5
    var node: MeshInstance3D=_mesh(parent,label,shape,at,mat)
    node.scale=size
    return node

# Solid, capped, eight-sided contoured plate, not a transparent plane or
# a rectangle with painted corners. The back/side faces exist at all LODs.
static func _bevel(parent: Node3D, label: String, at: Vector3,
        width: float, height: float, thick: float, cut: float,
        mat: Material) -> MeshInstance3D:
    var half_w: float=width*0.5
    var half_h: float=height*0.5
    var b: float=minf(cut,minf(width,height)*0.24)
    var contour: Array[Vector2]=[
        Vector2(-half_w+b,-half_h), Vector2(half_w-b,-half_h),
        Vector2(half_w,-half_h+b), Vector2(half_w,half_h-b),
        Vector2(half_w-b,half_h), Vector2(-half_w+b,half_h),
        Vector2(-half_w,half_h-b), Vector2(-half_w,-half_h+b)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(contour.size()):
        var next: int=(i+1)%contour.size()
        var a: Vector2=contour[i]
        var c: Vector2=contour[next]
        var a_front := Vector3(a.x,a.y,thick*0.5)
        var b_front := Vector3(c.x,c.y,thick*0.5)
        var a_rear := Vector3(a.x,a.y,-thick*0.5)
        var b_rear := Vector3(c.x,c.y,-thick*0.5)
        # Exterior front (+Z) and rear (-Z) filled triangle fans.
        for v in [Vector3(0,0,thick*0.5),a_front,b_front,
                Vector3(0,0,-thick*0.5),b_rear,a_rear,
                a_front,a_rear,b_rear,a_front,b_rear,b_front]:
            st.add_vertex(v)
    st.generate_normals()
    return _mesh(parent,label,st.commit(),at,mat)

static func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return (model!=null and bool(model.get_meta(FLAG,false)) and
        _find(model,SHIELD)!=null and _find(model,RIFLE)!=null)

static func apply(model: Node3D, faction: Color, hero: bool) -> bool:
    if model==null or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!="infantry_engineer":
        return false
    if not bool(model.get_meta(
            "tarvoka_engineer_full_helmet_and_joint_closure_v7",false)):
        return false
    var chest: Node3D=_find(model,"TorsoRig")
    var shield: Node3D=_find(model,"V6_BarreraArticuladaRig")
    var left: Node3D=_find(model,"V6_AlaIzquierdaRig")
    var right: Node3D=_find(model,"V6_AlaDerechaRig")
    var rifle: Node3D=_find(model,"ArmamentoRig")
    var face: Node3D=_find(model,"CabezaRig")
    if chest==null or shield==null or left==null or right==null or \
            rifle==null or face==null:
        return false
    for side in [-1,1]:
        if _find(model,"BrazoRig_%d"%side)==null:
            return false

    var armor := _coat(Color("#87989b"),0.45,0.38,true)
    var trim := _coat(Color("#303c40"),0.21,0.67)
    var steel := _coat(Color("#b2bec1"),0.62,0.29)
    var cloth := _coat(Color("#52645d"),0.02,0.92)
    var optic := _coat(Color("#1d506b"),0.22,0.15,true)
    var marking := _coat(faction,0.22,0.34,true)

    # Folded shield stays on the V6 articulation rig. Tapered plates and
    # recesses soften the enormous V6 rectangular rear silhouette.
    _bevel(shield,SHIELD,Vector3(0,-0.045,0.224),
        0.965,0.57,0.028,0.14,armor)
    _bevel(shield,"V8_BarreraMarcoReforzado",
        Vector3(0,-0.04,0.249),0.77,0.385,0.020,0.10,trim)
    _bevel(shield,FACTION,Vector3(0,0.13,0.277),
        0.57,0.115,0.025,0.035,marking)
    for side in [-1,1]:
        var x: float=float(side)
        var wing: Node3D=left if side<0 else right
        _bevel(wing,"V8_AlaBiselAcero_%d"%side,
            Vector3(x*0.08,-0.02,0.069),
            0.17,0.62,0.024,0.047,armor)
        _bevel(wing,"V8_BandaAlaFaccion_%d"%side,
            Vector3(x*0.08,0.16,0.084),
            0.135,0.11,0.018,0.027,marking)
        if hero:
            _box(shield,"V8_TopeAlaBlindado_%d"%side,
                Vector3(x*0.455,-0.25,0.236),
                Vector3(0.085,0.12,0.068),steel)
            _box(shield,"V8_RielCierreInferior_%d"%side,
                Vector3(x*0.28,-0.29,0.257),
                Vector3(0.21,0.045,0.018),steel)

    # Repair cuboid shoulder prototypes with anatomically rounded, fully
    # solid movable arm-anchored plates. The rig and movement remain unchanged.
    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var old: Node3D=_find(model,"Hombrera_%d"%side)
        if old!=null:
            old.visible=false
        _ellipsoid(arm,SHOULDER+"_%d"%side,
            Vector3(0,-0.072,-0.062),
            Vector3(0.385,0.34,0.355),armor,hero)
        _ellipsoid(arm,"V8_HombreraUnionElastica_%d"%side,
            Vector3(0,-0.19,0.036),
            Vector3(0.20,0.18,0.21),cloth,hero)
        _bevel(arm,"V8_FaccionHombrera_%d"%side,
            Vector3(float(side)*0.19,-0.07,-0.085),
            0.035,0.21,0.035,0.009,marking)
        if hero:
            _box(arm,"V8_CosturaHombrera_%d"%side,
                Vector3(0,-0.26,-0.10),
                Vector3(0.23,0.025,0.032),trim)

    # Front volume follows the vest instead of stacking wide boxes over it.
    _bevel(chest,"V8_PetoDelanteroContinuo",
        Vector3(0,-0.02,-0.399),
        0.58,0.44,0.043,0.11,armor)
    _bevel(chest,"V8_EscudoTecnicoPecho",
        Vector3(0,0.125,-0.429),
        0.325,0.12,0.022,0.041,marking)
    if hero:
        for side in [-1,1]:
            _bevel(chest,"V8_SelloLateralCoraza_%d"%side,
                Vector3(float(side)*0.31,-0.09,-0.304),
                0.09,0.27,0.025,0.023,trim)

    # A real machined receiver: tapered receiver, closed handguard, rubber
    # foregrip and optic. Preserve the original muzzle & weapon pose hooks.
    _bevel(rifle,RIFLE,Vector3(0.13,0.025,-0.005),
        0.55,0.195,0.185,0.065,trim)
    _bevel(rifle,"V8_GuardamanosPerforado",Vector3(0.50,0,-0.004),
        0.40,0.17,0.198,0.045,armor)
    _box(rifle,"V8_RielOpticoSuperior",Vector3(0.26,0.156,0),
        Vector3(0.60,0.048,0.12),steel)
    _ellipsoid(rifle,"V8_LenteProtegida",Vector3(0.18,0.185,-0.105),
        Vector3(0.11,0.09,0.025),optic,hero)
    _box(rifle,"V8_EmpunaduraAntideslizante",
        Vector3(-0.045,-0.195,0),Vector3(0.10,0.26,0.115),
        cloth,Vector3(0,0,-14))
    _box(rifle,"V8_ApoyoManoIzquierda",
        Vector3(0.45,-0.17,0),Vector3(0.14,0.17,0.11),trim)
    if hero:
        for i in range(4):
            _box(rifle,"V8_RanuraVentilacion_%d"%i,
                Vector3(0.37+0.077*float(i),0.11,-0.117),
                Vector3(0.043,0.028,0.025),trim)
        _box(rifle,"V8_TiradorCerrojo",
            Vector3(0.03,0.055,0.116),
            Vector3(0.085,0.055,0.071),steel)
        _box(rifle,"V8_MarcaArmaFaccion",
            Vector3(0.11,-0.04,-0.115),
            Vector3(0.19,0.035,0.027),marking)

    # Reduce blocky facial stack by hiding a redundant old engineer visor;
    # V7 respirator + V2 sealed optics and full rear helmet remain.
    var old_vis: Node3D=_find(model,"V5_ViseraObraIngeniero")
    if old_vis!=null:
        old_vis.visible=false
    _bevel(face,"V8_ViseraSuperiorSellada",
        Vector3(0,0.435,-0.351),0.53,0.11,0.13,0.065,trim)
    _bevel(face,"V8_CrestaCascoFaccion",
        Vector3(0,0.465,-0.435),0.31,0.053,0.022,0.019,marking)

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_infantry_engineer_premium_art_only",true)
    model.set_meta("tarvoka_infantry_engineer_premium_hero",hero)
    return true
