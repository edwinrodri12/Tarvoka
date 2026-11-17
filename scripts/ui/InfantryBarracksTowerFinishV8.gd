extends RefCounted
class_name TarvokaInfantryBarracksTowerFinishV8

# Structural 3D art audit over the V1-V7 Infantry Barracks.
# Repairs the only documented N3 tower/wing footprint overlap by moving the
# two complete tower assemblies 0.50 m to the rear. V1, V2 and V7 components
# move together. The addition is reversible by rebuilding without V8.
# No gameplay units, capture rules, production, or map buildings are touched.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V7=preload("res://scripts/ui/InfantryBarracksSideTowersV7.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV8TorresSeparacionAcabados"
const N3_REAR_CLEARANCE_SHIFT=0.50
const METAL=Color("#536970")
const TRIM=Color("#94a7ab")
const DARK=Color("#293b43")
const CAUTION=Color("#d6b875")
const WEATHERED=Color("#876a61")

static func _part(parent: Node3D,label: String,at: Vector3,
        dims: Vector3,tint: Color,metal: float=0.33) -> void:
    Base._box(parent,label,at,dims,tint,metal)

static func _move_wing_towers(model: Node3D,damage: int) -> bool:
    var parts: Array[Node3D]=[]
    for tag in ["TorreOesteNivel3","TorreEsteNivel3"]:
        var first_name: String=(
            "BaseTorreCaida_"+tag if damage>=3 else tag)
        var v1_part: Node3D=model.find_child(first_name,true,false) as Node3D
        var v2_part: Node3D=model.find_child(
            "Detalles_"+tag,true,false) as Node3D
        var v7_part: Node3D=model.find_child(
            "CabinaVigilanciaV7_"+tag,true,false) as Node3D
        if v1_part==null or v2_part==null or v7_part==null:
            return false
        parts.append_array([v1_part,v2_part,v7_part])
    # Validation happens before any modification, avoiding half-shifted
    # towers if a required earlier art stage is missing.
    for part in parts:
        part.position.z+=N3_REAR_CLEARANCE_SHIFT
    return true

static func _tower_finish(stage: Node3D,tag: String,
        x: float,z: float,h: float,damage: int,accent: Color) -> void:
    if damage>=2:
        return
    var node:=Base._group(stage,"RematesTorresV8_"+tag)
    var metal_color: Color=WEATHERED if damage==1 else METAL
    # Perimeter roof drip flashing stays under V1's roof and outside the
    # blue V7 faction stripe. V1 roof footprint: 2.15 by 2.15.
    for side in [-1,1]:
        var suffix: String=str(side)
        _part(node,"GoteronFrontalPosteriorV8_"+suffix,
            Vector3(x,h+1.276,z+float(side)*1.146),
            Vector3(2.19,0.090,0.070),metal_color,0.40)
        _part(node,"GoteronLateralV8_"+suffix,
            Vector3(x+float(side)*1.146,h+1.276,z),
            Vector3(0.070,0.090,2.18),metal_color,0.40)
    # The V2 rear ladder finishes at the standing platform height.
    # Build short, separate side handles and an anchored landing threshold:
    # do not close the walkway with a full-width guardrail.
    _part(node,"UmbralEscaleraTorreV8",
        Vector3(x,h+0.210,z+0.965),
        Vector3(0.93,0.057,0.32),metal_color,0.38)
    for side in [-1,1]:
        var sx: float=x+float(side)*0.48
        _part(node,"BarandalAccesoEscaleraV8_"+str(side),
            Vector3(sx,h+0.655,z+1.045),
            Vector3(0.075,0.70,0.075),TRIM,0.43)
        _part(node,"EmpunaduraAccesoEscaleraV8_"+str(side),
            Vector3(sx,h+1.000,z+1.085),
            Vector3(0.102,0.065,0.32),TRIM,0.43)
    if damage!=0:
        return
    # Light roof equipment: no spotlight shadows, no rotating sensors,
    # and no intersect with the original V7 corner beacons.
    _part(node,"PedestalVentiladorTorreV8",
        Vector3(x,h+1.525,z+0.37),
        Vector3(0.53,0.115,0.58),DARK,0.35)
    _part(node,"CajaVentiladorTorreV8",
        Vector3(x,h+1.675,z+0.37),
        Vector3(0.42,0.24,0.47),METAL,0.40)
    _part(node,"TapaVentiladorTorreV8",
        Vector3(x,h+1.835,z+0.37),
        Vector3(0.56,0.073,0.58),TRIM,0.39)
    for i in range(3):
        _part(node,"RejillaVentiladorTorreV8_%d" % i,
            Vector3(x,h+1.590+float(i)*0.066,z+0.122),
            Vector3(0.34,0.031,0.032),DARK,0.27)
    # Bright but restrained rear identification, distinct from the V7
    # front stripe and placed above the solid perimeter metal.
    _part(node,"FranjaTraseraFaccionTorreV8",
        Vector3(x,h+1.392,z+1.094),
        Vector3(0.84,0.074,0.038),accent,0.13)

static func _paint(stage: Node3D,accent: Color) -> void:
    var painted: int=0
    var textured: int=0
    var pending: Array[Node]=[stage]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
            if not child is MeshInstance3D:
                continue
            var part: MeshInstance3D=child as MeshInstance3D
            var mat: StandardMaterial3D=part.material_override as StandardMaterial3D
            if mat==null:
                continue
            if mat.albedo_color.is_equal_approx(accent):
                painted+=1
            else:
                part.material_override=V3._finish_material(mat,"steel")
                textured+=1
    stage.set_meta("pbr_meshes",textured)
    stage.set_meta("faction_paint_preserved",painted)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V7.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-1))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    if level==3 and damage!=4:
        if not _move_wing_towers(model,damage):
            return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<=1 and level>=2:
        var accent: Color=Style.faction_color(faction)
        if level==2:
            _tower_finish(stage,"TorreSupervisionNivel2",
                5.67,-2.77,3.72,damage,accent)
        else:
            for side in [-1,1]:
                _tower_finish(stage,
                    "TorreOesteNivel3" if side==-1 else "TorreEsteNivel3",
                    float(side)*6.47,3.65+N3_REAR_CLEARANCE_SHIFT,
                    4.93,damage,accent)
        _paint(stage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("tower_finish_version",8)
    stage.set_meta("n3_rear_shift_m",N3_REAR_CLEARANCE_SHIFT if level==3 and damage!=4 else 0.0)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    return true
