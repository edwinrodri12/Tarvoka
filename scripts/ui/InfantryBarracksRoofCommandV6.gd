extends RefCounted
class_name TarvokaInfantryBarracksRoofCommandV6

# Native Godot 4.3 ART pass. Designed after inspecting actual V5 GPU renders.
# This is an additional, reversible architectural layer only.
# Do not alter fixed building production, combat, captures, training zones,
# the N3 west-side obstacle corridor, or the three approved floor plans.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V5=preload("res://scripts/ui/InfantryBarracksEntranceYardV5.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV6CubiertasEIdentidadMilitar"
const STEEL=Color("#52676d")
const EDGE=Color("#95a9ac")
const DARK=Color("#273d43")
const GLASS=Color("#476d77")
const WARNING=Color("#d0af60")
const DAMAGE=Color("#946c58")

static func _part(parent: Node3D,name: String,at: Vector3,
        size: Vector3,tint: Color,metal: float=0.25) -> void:
    Base._box(parent,name,at,size,tint,metal)

static func _vent(root: Node3D,tag: String,at: Vector3,
        width: float,damage: int) -> void:
    var metal_color: Color=DAMAGE if damage==1 else STEEL
    var node:=Base._group(root,"VentilacionTecnicaV6_"+tag)
    # A distinct, readable roof extractor (not another identical roof rib).
    _part(node,"ZocaloExtractor",
        at+Vector3(0,-0.12,0),
        Vector3(width+0.20,0.18,0.89),DARK,0.32)
    _part(node,"CajaExtractor",
        at+Vector3(0,0.14,0),
        Vector3(width,0.43,0.73),metal_color,0.37)
    _part(node,"TapaInclinadaExtractor",
        at+Vector3(0,0.39,-0.03),
        Vector3(width+0.16,0.09,0.82),EDGE if damage==0 else DAMAGE,0.37)
    for i in range(3):
        _part(node,"LamaExtractor_%d" % i,
            at+Vector3(-width*0.31+float(i)*width*0.31,
                0.12,-0.389),
            Vector3(0.12,0.23,0.035),DARK,0.21)

static func _roof(stage: Node3D,module: Dictionary,level: int,
        damage: int,accent: Color) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var main: bool=bool(module["primary"])
    var roof:=Base._group(stage,"CubiertaMilitarV6_"+tag)
    var front: float=z-d*0.5
    if damage==2:
        # Roof is partly torn open in V1; add ONLY one displaced remnant.
        _part(roof,"PerfilTechoDanado",
            Vector3(x+w*0.36,h+0.32,z+d*0.30),
            Vector3(w*0.19,0.075,0.15),DAMAGE,0.25)
        return
    if damage>2:
        return
    # Two narrow edge drip profiles silhouette the slab, but do not cap
    # missing panels and do not touch the neighboring towers or training lane.
    for side in [-1,1]:
        _part(roof,"RemateLateralCubierta_%d" % side,
            Vector3(x+float(side)*(w*0.5+0.078),h+0.315,z),
            Vector3(0.090,0.115,d+0.20),
            DAMAGE if damage==1 else EDGE,0.43)
    if main:
        # Military wayfinding from the existing entrance canopy, not a
        # duplicate door or opaque facade. It also distinguishes N1/N2/N3.
        _part(roof,"MarcaFaccionBordeTecho",
            Vector3(x,h+0.354,front-0.13),
            Vector3(w*(0.22 if level==1 else 0.34),0.086,0.072),
            accent,0.18)
    # Roof panels #0 and #3 survive damage stage 1, so keep equipment
    # on those physical panels, never across the absent center roof plate.
    if damage==0 or main:
        var vent_x: float=x-w*0.345
        _vent(roof,"Principal",Vector3(vent_x,h+0.49,z+d*0.16),
            0.75 if level==1 else 0.95,damage)
    if damage==0 and main and level>=2:
        _vent(roof,"Secundario",
            Vector3(x+w*0.34,h+0.49,z+d*0.16),
            0.78,damage)
    if damage==0 and level==3 and not main:
        # Small wing vents are intentionally lower than the command mast.
        _part(roof,"SalidaAireAla",
            Vector3(x+w*0.28,h+0.45,z+d*0.24),
            Vector3(0.47,0.29,0.64),STEEL,0.29)
        _part(roof,"CubiertaSalidaAire",
            Vector3(x+w*0.28,h+0.64,z+d*0.24),
            Vector3(0.56,0.10,0.74),DARK,0.37)

static func _front(stage: Node3D,module: Dictionary,level: int,
        damage: int,accent: Color) -> void:
    if damage>=2:
        return
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var w: float=float(module["w"])
    var h: float=float(module["h"])
    var z: float=float(module["z"])-float(module["d"])*0.5
    var main: bool=bool(module["primary"])
    if not main:
        return
    var facade:=Base._group(stage,"IdentificacionMandoV6_"+tag)
    if level==1:
        # Small field-garrison identification on the canopy, not skyscraper
        # signage and not a plate covering the original faction emblem.
        for side in [-1,1]:
            _part(facade,"MarcaCompaniaN1_%d" % side,
                Vector3(x+float(side)*1.20,2.63,z-0.72),
                Vector3(0.16,0.10,0.09),accent,0.13)
    elif level==2:
        # The two-storey main wing gets a light command-band framing.
        _part(facade,"BandaComandoN2",
            Vector3(x,3.86,z-0.211),
            Vector3(2.40,0.12,0.065),accent,0.13)
        for side in [-1,1]:
            _part(facade,"TerminacionBandaN2_%d" % side,
                Vector3(x+float(side)*1.27,3.86,z-0.20),
                Vector3(0.105,0.28,0.065),STEEL,0.30)
    else:
        # N3 has a faction emblem already at y=5.95. Surround that original
        # instead of drawing a second badge over it.
        _part(facade,"RemateSuperiorEmblemaN3",
            Vector3(x,6.27,z-0.195),
            Vector3(2.82,0.092,0.09),EDGE,0.32)
        _part(facade,"RemateInferiorEmblemaN3",
            Vector3(x,5.63,z-0.195),
            Vector3(2.82,0.090,0.09),EDGE,0.32)
        for side in [-1,1]:
            _part(facade,"MontanteEmblemaN3_%d" % side,
                Vector3(x+float(side)*1.41,5.95,z-0.19),
                Vector3(0.095,0.72,0.095),accent,0.16)

static func _command_antenna(stage: Node3D,module: Dictionary,
        damage: int,accent: Color) -> void:
    if damage!=0:
        return
    var x: float=float(module["x"])+0.22
    var z: float=float(module["z"])+0.50
    var h: float=float(module["h"])
    var comm:=Base._group(stage,"AntenaComunicacionesComandoN3")
    _part(comm,"BaseAntenaComando",
        Vector3(x,h+0.42,z),Vector3(0.66,0.24,0.66),DARK,0.34)
    Base._cylinder(comm,"MastilRadioN3",
        Vector3(x,h+1.20,z),0.055,1.54,STEEL)
    Base._cylinder(comm,"BalizaSuperiorN3",
        Vector3(x,h+2.04,z),0.095,0.18,accent)
    _part(comm,"TraviesaRadioN3",
        Vector3(x,h+1.75,z),Vector3(0.91,0.070,0.090),EDGE,0.41)
    for side in [-1,1]:
        _part(comm,"PanelRadioN3_%d" % side,
            Vector3(x+float(side)*0.40,h+1.54,z),
            Vector3(0.16,0.36,0.085),GLASS,0.16)

static func _finish_surfaces(stage: Node3D,accent: Color) -> void:
    # V6 must match the original V3 PBR visual language. All procedural
    # steel and roof parts receive native texture roughness/mipmaps, while
    # the exact faction paint stays clear and never shifts hue.
    var textured: int=0
    var colored: int=0
    var pending: Array[Node]=[stage]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
            if not child is MeshInstance3D:
                continue
            var piece: MeshInstance3D=child as MeshInstance3D
            var material: StandardMaterial3D=piece.material_override as StandardMaterial3D
            if material==null:
                continue
            if material.albedo_color.is_equal_approx(accent):
                colored+=1
                continue
            var name: String=str(piece.name).to_lower()
            var kind: String="steel"
            if name.contains("panelradio"):
                kind="glass"
            elif name.contains("perfiltechodanado"):
                kind="rubble"
            elif (name.contains("cubierta") or name.contains("tapa") or
                    name.contains("remate") or name.contains("borde")):
                kind="roof"
            piece.material_override=V3._finish_material(material,kind)
            textured+=1
    stage.set_meta("pbr_v3_textured_meshes",textured)
    stage.set_meta("faction_paint_untouched",colored)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V5.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level or \
            int(model.get_meta("visual_faction",-1))!=faction or \
            int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        var accent: Color=Style.faction_color(faction)
        for module in V2._modules(level):
            if damage<=2:
                _roof(stage,module,level,damage,accent)
            _front(stage,module,level,damage,accent)
        if level==3 and damage==0:
            _command_antenna(stage,V2._modules(level)[0],damage,accent)
    if damage<4:
        _finish_surfaces(stage,Style.faction_color(faction))
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("roof_identity_version",6)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    return true
