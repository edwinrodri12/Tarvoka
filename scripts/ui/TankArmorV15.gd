extends RefCounted
class_name TarvokaTankArmorV15

# G09 V15 — hard-surface correction after inspecting V14's native four-angle
# render: preserve its readable angular silhouette, eliminate oversized,
# floating-looking wings by actually replacing the existing surface meshes.
# This is an opt-in visual-only edit of the same articulated Godot tank.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V15CorazaIntegrada"
const STEEL := Color("#536872")
const COMPOSITE := Color("#70818A")
const TURNTOP := Color("#627681")
const JOINT := Color("#253944")

const RETIRED := [
    "G09V14CantoProa_-1","G09V14CantoProa_1",
    "G09V14NervioLongitudinal_-1","G09V14NervioLongitudinal_1",
    "G09V14JuntaCarrillera_-1","G09V14JuntaCarrillera_1"
]

static func _replace(model: Node3D, name: String,
        outline: Array, rings: Array) -> bool:
    var original: MeshInstance3D = model.find_child(
        name,true,false) as MeshInstance3D
    if original == null or original.mesh == null:
        return false
    var temporary: MeshInstance3D = Hero._loft(
        original.get_parent(),"__V15_MESH_REPLACEMENT",outline,rings)
    original.mesh = temporary.mesh
    temporary.free()
    return true

static func _polygon(side: int, positive: Array) -> Array:
    var sign: float = float(side)
    var result: Array = []
    for p in positive:
        result.append(Vector2(sign*float(p.x),float(p.y)))
    if side < 0:
        result.reverse()
    return result

static func hide_retired_seams(model: Node3D) -> void:
    if model == null or not model.get_meta("tarvoka_mbt_integrated_v15",false):
        return
    for name in RETIRED:
        var old: Node3D = model.find_child(name,true,false) as Node3D
        if old != null:
            old.visible = false

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_silhouette_v14",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false

    # Nothing is bolted ON TOP of the exaggerated V14 plates: the original
    # MeshInstance3D (name, parent, animation, HP damage mapping) is retained,
    # with only its watertight ArrayMesh swapped for a lower, tighter shape.
    var required := ["G09V14QuillaFrontal"]
    for side in [-1,1]:
        for prefix in ["G09V14AlaBlindadaFrontal_",
                "G09V14LomoBlindadoCentral_",
                "G09V14HombroMotorPosterior_",
                "G09V14CarrilleraEscalonada_"]:
            required.append(prefix+str(side))
    for name in required:
        if not model.find_child(name,true,false) is MeshInstance3D:
            return false

    for side in [-1,1]:
        var key: String = str(side)
        # Bow shoulders begin underneath the continuous hull's armor lip,
        # then angle out only to x=1.35 (V14's x=1.50 looked like a toy wing).
        _replace(model,"G09V14AlaBlindadaFrontal_"+key,
            _polygon(side,[
                Vector2(0.40,-1.70),Vector2(0.68,-1.79),
                Vector2(1.05,-1.61),Vector2(1.34,-1.29),
                Vector2(1.36,-0.79),Vector2(1.01,-0.75),
                Vector2(0.56,-1.15),Vector2(0.43,-1.51)
            ]),[[0.824,0.875,0.017],[0.996,1.005,0.043],
                [1.125,0.918,0.063]])

        # These shoulders taper INTO the top deck. The flush roof stays
        # readable without 0.5m-wide floating gray rectangles.
        _replace(model,"G09V14LomoBlindadoCentral_"+key,
            _polygon(side,[
                Vector2(0.98,-0.59),Vector2(1.33,-0.60),
                Vector2(1.38,0.58),Vector2(1.26,0.79),
                Vector2(0.92,0.85)
            ]),[[0.811,0.932,0.0],[1.008,1.0,0.0],
                [1.113,0.886,0.0]])
        _replace(model,"G09V14HombroMotorPosterior_"+key,
            _polygon(side,[
                Vector2(0.92,0.87),Vector2(1.30,0.90),
                Vector2(1.32,1.25),Vector2(1.15,1.49),
                Vector2(0.82,1.41)
            ]),[[0.821,0.939,0.0],[1.014,1.010,0.0],
                [1.118,0.871,0.0]])

        # Lower ceramic cheek tapers into the original turret shell and leaves
        # the cannon cradle/thermal sleeve unobstructed at every elevation.
        _replace(model,"G09V14CarrilleraEscalonada_"+key,
            _polygon(side,[
                Vector2(0.29,-1.60),Vector2(0.55,-1.63),
                Vector2(0.92,-1.38),Vector2(1.07,-0.94),
                Vector2(0.96,-0.62),Vector2(0.70,-0.54),
                Vector2(0.38,-0.93)
            ]),[[0.180,0.878,0.012],[0.352,1.005,0.028],
                [0.506,0.958,0.038],[0.635,0.811,0.048]])

        # Two recessed original welds replace six protruding V14 guide rods.
        # They belong to the proper pivot and match the remodeled surfaces.
        var sign: float = float(side)
        Hero._rod(hull,"G09V15SoldaduraHombro_"+key,
            Vector3(sign*1.245,1.090,-1.30),
            Vector3(sign*1.303,1.098,-0.88),0.011,JOINT)
        Hero._rod(turret,"G09V15CosturaCarrillera_"+key,
            Vector3(sign*0.84,0.617,-1.20),
            Vector3(sign*0.986,0.606,-0.90),0.010,JOINT)

    _replace(model,"G09V14QuillaFrontal",[
        Vector2(-0.25,-1.85),Vector2(0.25,-1.85),
        Vector2(0.43,-1.59),Vector2(-0.43,-1.59)
    ],[[0.784,0.89,0.035],[0.930,1.0,0.034],
        [1.051,0.89,0.044]])

    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_integrated_v15",true)
    hide_retired_seams(model)
    return true

static func finish_materials(model: Node3D) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_integrated_v15",false):
        return 0
    # Update the ORIGINAL V14 panels after its PBR pass, so lighting/shading
    # is consistent and there are no extra bulky decorative meshes.
    var count: int = 0
    for node in model.find_children("G09V14*","MeshInstance3D",true,false):
        var plate: MeshInstance3D = node as MeshInstance3D
        if not ("AlaBlindadaFrontal" in plate.name or
                "LomoBlindadoCentral" in plate.name or
                "HombroMotorPosterior" in plate.name or
                "CarrilleraEscalonada" in plate.name or
                "QuillaFrontal" in plate.name):
            continue
        var base: StandardMaterial3D = plate.material_override as StandardMaterial3D
        if base == null:
            continue
        var m: StandardMaterial3D = base.duplicate(true) as StandardMaterial3D
        m.albedo_color = COMPOSITE if ("AlaBlindada" in plate.name or
            "Carrillera" in plate.name) else (TURNTOP if
            "Quilla" in plate.name else STEEL)
        m.roughness = 0.84
        m.metallic = 0.15
        m.normal_scale = 0.12
        plate.material_override = m
        count += 1
    # V14's bright detached roof rods must never become visible from repairs.
    hide_retired_seams(model)
    model.set_meta("tarvoka_mbt_integrated_v15_pbr_count",count)
    return count
