extends RefCounted
class_name TarvokaInfantryEngineerContourV14

# Art-only anatomical proportion pass on the EXISTING engineer model.
# No rig pivots, weapons, material colors, team IDs, collision or game rules
# change. The exact same MeshInstance3D nodes can compare V13 <-> V14.
const SmoothV13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const DorsalV12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const V9=preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const V8=preload("res://scripts/ui/InfantryEngineerPremiumV8.gd")
const FLAG: String="tarvoka_engineer_anatomic_contours_v14"
const OLD: String="tarvoka_v14_previous_geometry"
const NEW: String="tarvoka_v14_anatomic_geometry"
const SHOULDER: String="V8_HombreraAnatomica"
const YOKE: String="V12_SelladoCuelloContinuo"
const FRONT: String="V8_PetoDelanteroContinuo"
const CHEST: String="V8_EscudoTecnicoPecho"

static func _find(model: Node3D, name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func _snapshot(mesh: MeshInstance3D) -> Dictionary:
    return {"mesh":mesh.mesh,"scale":mesh.scale,"position":mesh.position}

static func _morph(part: MeshInstance3D, replacement: Mesh,
        new_scale: Vector3, new_pos: Vector3) -> bool:
    if part==null or replacement==null:
        return false
    # Save real V13 meshes and transforms; no duplicate renderable shells.
    part.set_meta(OLD,_snapshot(part))
    part.set_meta(NEW,{"mesh":replacement,
        "scale":new_scale,"position":new_pos})
    part.mesh=replacement
    part.scale=new_scale
    part.position=new_pos
    return true

static func _pose(part: MeshInstance3D, scale: Vector3,
        shift: Vector3=Vector3.ZERO) -> bool:
    if part==null:
        return false
    return _morph(part,part.mesh,scale,part.position+shift)

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _find(model,SHOULDER+"_1")!=null and
        _find(model,SHOULDER+"_-1")!=null and
        _find(model,V9.HELMET)!=null)

static func show_contours(model: Node3D, enabled: bool) -> bool:
    if not has_model(model):
        return false
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if not part.has_meta(OLD) or not part.has_meta(NEW):
            continue
        var state: Dictionary=part.get_meta(NEW if enabled else OLD)
        part.mesh=state["mesh"]
        part.scale=state["scale"]
        part.position=state["position"]
    model.set_meta("tarvoka_engineer_v14_contours_visible",enabled)
    return true

static func apply(model: Node3D, hero: bool) -> bool:
    if model==null or has_model(model) or not SmoothV13.has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!="infantry_engineer":
        return false
    var head: Node3D=model.find_child("CabezaRig",true,false) as Node3D
    var torso: Node3D=model.find_child("TorsoRig",true,false) as Node3D
    if head==null or torso==null:
        return false

    # A more natural crown: the lower rim maintains the visor/earpiece
    # alignment; upper quarters narrow subtly before reaching the crown.
    # SmoothV13's lathe generates a fully closed, outward-facing hull with
    # continuous normals and Android-aware 14 vs 24 radial sections.
    var shell: MeshInstance3D=_find(model,V9.HELMET)
    if shell==null or shell.get_parent()!=head:
        return false
    var helmet_profiles: Array=[
        Vector3(0.168,0.135,0.184),
        Vector3(0.247,0.191,0.238),
        Vector3(0.281,0.302,0.270),
        Vector3(0.282,0.413,0.277),
        Vector3(0.240,0.530,0.245),
        Vector3(0.150,0.607,0.153),
        Vector3(0.048,0.642,0.050)
    ]
    if not _morph(shell,SmoothV13._lathe(helmet_profiles,hero,0.006),
            shell.scale,shell.position):
        return false

    # The collar and closed inner neck should intersect the torso,
    # eliminating the stacked-discs look while never exposing a cavity.
    var collar: MeshInstance3D=_find(model,V9.COLLAR)
    var neck: MeshInstance3D=_find(model,DorsalV12.SEAL_NECK)
    if (collar==null or neck==null or collar.get_parent()!=head or
            neck.get_parent()!=head):
        return false
    if not _morph(collar,collar.mesh,
            Vector3(0.342,0.292,0.322),Vector3(0,0.027,0.026)):
        return false
    if not _morph(neck,neck.mesh,
            Vector3(0.309,0.294,0.302),Vector3(0,-0.051,-0.006)):
        return false

    # V8's main chest plate is still an 8-corner hard prism after V13.
    # Curve this REAL surface in place, without covering any faction art.
    for spec in [[FRONT,0.58,0.44,0.104,0.017],
            [CHEST,0.325,0.12,0.041,0.009]]:
        var part: MeshInstance3D=_find(model,str(spec[0]))
        if part==null or part.get_parent()!=torso:
            return false
        if not _morph(part,SmoothV13._rounded_press(
                float(spec[1]),float(spec[2]),0.043 if part.name==FRONT else 0.022,
                float(spec[3]),float(spec[4]),hero),
                part.scale,part.position):
            return false

    # Deltoid shells used to look like big spheres floating over short upper
    # arms. Retain the EXACT original arm rig pivots, shoulder paint and
    # hit-free art transforms; taper actual material from joint to bicep.
    var shoulder_profiles: Array=[
        Vector3(0.075,-0.490,0.082),
        Vector3(0.285,-0.440,0.318),
        Vector3(0.405,-0.306,0.418),
        Vector3(0.510,-0.110,0.492),
        Vector3(0.505,0.123,0.487),
        Vector3(0.389,0.349,0.408),
        Vector3(0.106,0.494,0.139)
    ]
    for side in [-1,1]:
        var arm: Node3D=model.find_child(
            "BrazoRig_%d"%side,true,false) as Node3D
        if arm==null or arm.get_parent()!=torso:
            return false
        var pauldron: MeshInstance3D=_find(
            model,SHOULDER+"_%d"%side)
        if pauldron==null or pauldron.get_parent()!=arm:
            return false
        if not _morph(pauldron,
                SmoothV13._lathe(shoulder_profiles,hero),
                Vector3(0.342,0.306,0.333),
                Vector3(0,-0.083,-0.065)):
            return false
        var sleeve: MeshInstance3D=_find(model,
            "V8_HombreraUnionElastica_%d"%side)
        var socket: MeshInstance3D=_find(model,
            "V11_SelloArticuladoHombro_%d"%side)
        var fixed: MeshInstance3D=_find(model,
            DorsalV12.SEAL_SHOULDER+"_%d"%side)
        if sleeve==null or socket==null or fixed==null:
            return false
        if not _pose(sleeve,Vector3(0.210,0.216,0.216)):
            return false
        if not _pose(socket,Vector3(0.219,0.230,0.214)):
            return false
        if not _pose(fixed,Vector3(0.268,0.258,0.269),
                Vector3(-float(side)*0.009,-0.006,0.0)):
            return false

    # Visual audit revealed that the previous deltoid/collar adjustment
    # was barely noticeable: the real front camera is dominated by V5's
    # square construction brow, V7's square respirator and a broad V6
    # rectangular folding shield behind the head. Replace these SOURCE
    # objects in-place with fully capped curved geometry. No fake overlays.
    var shield: Node3D=model.find_child(
        "V6_BarreraArticuladaRig",true,false) as Node3D
    if shield==null or shield.get_parent()!=torso:
        return false
    var face_parts: Array=[
        ["V5_ViseraObraIngeniero",0.59,0.15,0.16,0.041,0.020],
        ["V5_InsigniaCascoIngeniero",0.37,0.075,0.026,0.019,0.008],
        ["V7_MascaraResistenciaIngeniero",0.35,0.21,0.095,0.050,0.015],
        ["V7_FiltroCentralRespirador",0.16,0.105,0.038,0.022,0.007],
        ["V2_BordeFrontalCasco",0.50,0.09,0.13,0.025,0.010]
    ]
    for entry in face_parts:
        var face_mesh: MeshInstance3D=_find(model,str(entry[0]))
        if face_mesh==null or face_mesh.get_parent()!=head:
            return false
        if not _morph(face_mesh,SmoothV13._rounded_press(
                float(entry[1]),float(entry[2]),float(entry[3]),
                float(entry[4]),float(entry[5]),hero),
                face_mesh.scale,face_mesh.position):
            return false
    var rear_parts: Array=[
        ["V6_PlacaPrincipalDeAcero",1.12,0.68,0.12,0.124,0.015],
        ["V6_CostraBlindajeExterior",0.93,0.45,0.037,0.088,0.010]
    ]
    for entry in rear_parts:
        var plate: MeshInstance3D=_find(model,str(entry[0]))
        if plate==null or plate.get_parent()!=shield:
            return false
        if not _morph(plate,SmoothV13._rounded_press(
                float(entry[1]),float(entry[2]),float(entry[3]),
                float(entry[4]),float(entry[5]),hero),
                plate.scale,plate.position):
            return false
    for side in [-1,1]:
        var wing: Node3D=model.find_child(
            "V6_AlaIzquierdaRig" if side<0 else "V6_AlaDerechaRig",
            true,false) as Node3D
        var wing_plate: MeshInstance3D=_find(model,
            "V6_AlaMetal_%d"%side)
        if wing==null or wing_plate==null or wing_plate.get_parent()!=wing:
            return false
        if not _morph(wing_plate,SmoothV13._rounded_press(
                0.18,0.70,0.11,0.049,0.012,hero),
                wing_plate.scale,wing_plate.position):
            return false

    # Anatomy changes are strictly on existing visible geometry; count of
    # mesh nodes/draw calls does not increase in either tactical or hero LOD.
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v14_hero",hero)
    model.set_meta("tarvoka_engineer_v14_contours_visible",true)
    return true
