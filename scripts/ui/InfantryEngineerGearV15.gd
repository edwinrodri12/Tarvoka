extends RefCounted
class_name TarvokaInfantryEngineerGearV15

# V15: make the visible rifle, harness and shield-edge HARD BLOCKS less toy-
# like. Reuse V13's closed outward-rounded solid mesh; no new draw calls.
# All original animations, parents, materials, transforms and G05 rules stay.
const V13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const V14=preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V8=preload("res://scripts/ui/InfantryEngineerPremiumV8.gd")
const FLAG: String="tarvoka_engineer_gear_v15"
const ORIGINAL: String="tarvoka_engineer_gear_v15_original"
const SCULPT: String="tarvoka_engineer_gear_v15_sculpt"

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func _replace(model: Node3D, label: String,
        w: float, h: float, depth: float,
        bevel: float, swell: float, hero: bool) -> bool:
    var part:=model.find_child(label,true,false) as MeshInstance3D
    if part==null or part.mesh==null:
        return false
    var replacement: ArrayMesh=V13._rounded_press(
        w,h,depth,bevel,swell,hero)
    if replacement==null:
        return false
    part.set_meta(ORIGINAL,part.mesh)
    part.set_meta(SCULPT,replacement)
    # Only replace underlying geometry; never move an animation or change
    # faction paints, PBR materials, original scene children or gameplay.
    part.mesh=replacement
    return true

static func show_finish(model: Node3D, refined: bool) -> bool:
    if not has_model(model):
        return false
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if part.has_meta(ORIGINAL) and part.has_meta(SCULPT):
            part.mesh=part.get_meta(SCULPT if refined else ORIGINAL)
    model.set_meta("tarvoka_engineer_gear_v15_visible",refined)
    return true

static func apply(model: Node3D, hero: bool) -> bool:
    if model==null or has_model(model) or not V14.has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!="infantry_engineer":
        return false
    # Main rifle silhouette was still a beveled slab surrounded by hard
    # boxes, despite the V14 anatomical improvements. Use real closed
    # rounded housings, preserving grip animations and weapon pivot.
    var shared: Array=[
        [V8.RIFLE,0.550,0.195,0.185,0.090,0.030],
        ["V8_GuardamanosPerforado",0.400,0.170,0.198,0.077,0.026],
        ["V8_RielOpticoSuperior",0.600,0.048,0.120,0.019,0.008],
        ["V8_EmpunaduraAntideslizante",0.100,0.260,0.115,0.031,0.012],
        ["V8_ApoyoManoIzquierda",0.140,0.170,0.110,0.042,0.010],
        ["V5_ArnesDiagonalIngeniero",0.130,0.640,0.047,0.052,0.009],
        ["V6_BancadaFijaBisagra",0.880,0.160,0.160,0.069,0.012]]
    for item in shared:
        if not _replace(model,str(item[0]),float(item[1]),
                float(item[2]),float(item[3]),float(item[4]),
                float(item[5]),hero):
            return false
    for side in [-1,1]:
        var suffix: String="_%d"%side
        for item in [
            ["V2_CinchaPortaequipo"+suffix,0.075,0.610,0.050,0.029,0.009],
            ["V5_SujecionBarreraIngeniero"+suffix,
                0.110,0.280,0.045,0.040,0.010],
            ["V6_CantoGoma"+suffix,0.038,0.710,0.120,0.014,0.004],
            ["V6_EscuadraFija"+suffix,0.120,0.330,0.130,0.052,0.012]]:
            if not _replace(model,str(item[0]),float(item[1]),
                    float(item[2]),float(item[3]),float(item[4]),
                    float(item[5]),hero):
                return false
    if hero:
        # LOD13 tactile details; do not increase LOD8 triangle budget.
        for side in [-1,1]:
            for item in [
                ["V8_RielCierreInferior_%d"%side,
                    0.210,0.045,0.018,0.014,0.006],
                ["V8_RefuerzoTraseroRodilla_%d"%side,
                    0.165,0.075,0.033,0.023,0.007]]:
                if not _replace(model,str(item[0]),float(item[1]),
                        float(item[2]),float(item[3]),float(item[4]),
                        float(item[5]),hero):
                    return false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_gear_v15_lod13",hero)
    model.set_meta("tarvoka_engineer_gear_v15_visible",true)
    return true
