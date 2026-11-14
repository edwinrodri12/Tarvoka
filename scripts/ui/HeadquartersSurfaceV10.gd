extends RefCounted
class_name TarvokaHeadquartersSurfaceV10

# V10: architectural surface transition pass. All meshes are native editable
# Godot geometry. No gameplay state, no replacement faction atlas and no decals
# that are merely flattened screenshots.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const PBR = preload("res://scripts/ui/HeadquartersFinishV8.gd")
const GUNMETAL := Color("#27353e")
const JOINT := Color("#1d2931")
const EDGE := Color("#a4b1b6")
const CONCRETE := Color("#adb9b7")
const CEMENT := Color("#9aa6a2")
const GLASS := Color("#3e7388")
const OXIDE := Color("#70564b")
const SOOT := Color("#302d2e")
const SIGNAL := Color("#b3cdd0")

static func _group(parent: Node3D,name: String) -> Node3D:
    return Finish._group(parent,name)

static func _box(parent: Node3D,name: String,at: Vector3,
        size: Vector3,color: Color,kind: String = "blast_concrete",
        rotate: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return PBR._box(parent,name,at,size,color,kind,rotate)

static func _chamfer(parent: Node3D,name: String,at: Vector3,
        size: Vector3,cut: float,color: Color,
        kind: String = "blast_concrete",paint: bool = false) -> MeshInstance3D:
    var part: MeshInstance3D = Finish._chamfer(
        parent,name,at,size,cut,color,"concrete",paint)
    part.material_override = PBR._material(color,kind)
    return part

static func _beam(parent: Node3D,name: String,a: Vector3,
        b: Vector3,radius: float,color: Color,
        kind: String = "brushed_alloy") -> MeshInstance3D:
    return PBR._beam(parent,name,a,b,radius,color,kind)

static func _material_junctions(model: Node3D,level: int) -> void:
    var root := _group(model,"EncuentrosMaterialesArquitectonicosV10")
    # Real rebated cement frames with black inset expansion seals. Individual
    # seams sit *forward* of the main front wall and are visible without
    # taking over the faction accents or official central shield.
    for side in [-1,1]:
        var sx: float = float(side)
        _box(root,"JuntaHorizontalHormigonAlero_%s" % side,
            Vector3(sx*4.12,2.28,-2.618),
            Vector3(2.25,0.062,0.055),JOINT,"industrial_roof")
        _box(root,"CornisaHormigonPulido_%s" % side,
            Vector3(sx*4.12,2.37,-2.638),
            Vector3(2.31,0.086,0.086),CEMENT)
        for column in range(3):
            var xx: float = sx*(3.41+float(column)*0.71)
            _box(root,"JuntaVerticalPanel_%s_%d" % [side,column],
                Vector3(xx,1.14,-2.630),
                Vector3(0.064,1.90,0.045),JOINT,"industrial_roof")
            _chamfer(root,"PanelCementicioPrefabricado_%s_%d" % [side,column],
                Vector3(xx,1.14,-2.664),
                Vector3(0.57,1.73,0.071),
                0.065,CONCRETE.darkened(float(column%2)*0.06))
            _box(root,"JuntaCapilarSuperior_%s_%d" % [side,column],
                Vector3(xx,2.045,-2.710),
                Vector3(0.46,0.028,0.044),GUNMETAL,"industrial_roof")
        # A secondary black gasket physically separates the concrete mass
        # from the V9 painted structural pilaster.
        _box(root,"SelloElastomeroPilastro_%s" % side,
            Vector3(sx*2.79,1.42,-3.040),
            Vector3(0.075,2.40,0.040),JOINT,"industrial_roof")
        _box(root,"SombraBajoVoladizo_%s" % side,
            Vector3(sx*3.96,2.645,-2.272),
            Vector3(2.25,0.044,0.082),GUNMETAL,"industrial_roof")
        # Exterior edge and rain flashing: different material, shadow, edge.
        _box(root,"BotaImpermeableDeAlero_%s" % side,
            Vector3(sx*5.25,2.817,-1.41),
            Vector3(0.115,0.115,1.62),GUNMETAL,"industrial_roof")
        _box(root,"CantoneraAluminioExpuesta_%s" % side,
            Vector3(sx*5.28,2.89,-1.44),
            Vector3(0.085,0.041,1.56),EDGE,"brushed_alloy")

    # Reveal a lightweight horizontal window band around the high tower,
    # limited to its outer panes so the central approved crest is untouched.
    top: float = 2.87+float(level-1)*0.91
    for side in [-1,1]:
        var sx: float = float(side)
        _box(root,"JuntaPerimetralCristalComando_%s" % side,
            Vector3(sx*1.45,top+0.63,-3.375),
            Vector3(0.43,0.81,0.049),JOINT,"industrial_roof")
        _chamfer(root,"PaqueteDobleVidrioComando_%s" % side,
            Vector3(sx*1.45,top+0.64,-3.418),
            Vector3(0.32,0.67,0.048),0.038,GLASS,"laminated_glass")
        _box(root,"ReflejoLateralCristalComando_%s" % side,
            Vector3(sx*(1.46-0.095),top+0.69,-3.449),
            Vector3(0.038,0.46,0.015),SIGNAL,"laminated_glass")
        _box(root,"TapajuntasBajoVidrio_%s" % side,
            Vector3(sx*1.45,top+0.234,-3.456),
            Vector3(0.39,0.065,0.083),EDGE,"brushed_alloy")
    # Alloy junction cover spanning the canopy extrusion and entry structure.
    _box(root,"SelloMetalHormigonAcceso",
        Vector3(0,2.205,-4.11),
        Vector3(2.46,0.065,0.12),JOINT,"industrial_roof")
    _box(root,"PerfilRemateAcceso",
        Vector3(0,2.267,-4.155),
        Vector3(2.55,0.052,0.11),EDGE,"brushed_alloy")

static func _roof_panels(model: Node3D,tint: Color) -> void:
    var root := _group(model,"CubiertasDeMaterialesConUnionesV10")
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(5):
            var z: float = -0.77+float(i)*0.53
            _box(root,"JuntaTermosoldadaCubierta_%s_%02d" % [side,i],
                Vector3(sx*4.07,2.769,z),
                Vector3(1.84,0.022,0.056),GUNMETAL,"industrial_roof")
            _box(root,"CintaDeRemateTecho_%s_%02d" % [side,i],
                Vector3(sx*4.07,2.788,z+0.06),
                Vector3(1.73,0.019,0.031),EDGE,"brushed_alloy")
        _box(root,"ChaflanCubiertaElevado_%s" % side,
            Vector3(sx*3.18,2.87,0.96),
            Vector3(0.13,0.16,2.82),tint.darkened(0.37),"brushed_alloy")
        _box(root,"BordeCubiertaCinc_%s" % side,
            Vector3(sx*5.07,2.86,0.96),
            Vector3(0.15,0.10,2.86),EDGE,"brushed_alloy")
        _box(root,"JuntaEntreBaseYCarcasaHVAC_%s" % side,
            Vector3(sx*3.92,3.045,0.84),
            Vector3(1.02,0.055,1.19),JOINT,"industrial_roof")
        # Inset outer grille adds the mechanical depth missing on V8 roof.
        for grille in range(3):
            _box(root,"LamaExtraccionOxidacion_%s_%02d" % [side,grille],
                Vector3(sx*(3.72+0.18*float(grille)),3.32,0.206),
                Vector3(0.103,0.30,0.041),GUNMETAL,"industrial_roof")
    _box(root,"TransicionCobreCuelloTorre",
        Vector3(0,3.14,1.91),
        Vector3(2.29,0.069,0.11),EDGE,"brushed_alloy")

static func _wear_from_drains(model: Node3D) -> void:
    # Traces originate at drain joints only, never a uniformly dirty overlay.
    var root := _group(model,"DesgasteFisicoLocalizadoV10")
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(3):
            var spread: float = float(i)*0.095
            _box(root,"EscurrimientoBajoCanalon_%s_%02d" % [side,i],
                Vector3(sx*(4.79+spread),1.45-float(i)*0.16,-2.656),
                Vector3(0.085,0.80-float(i)*0.15,0.028),
                OXIDE.darkened(float(i)*0.12),"heat_oxidation")
        _box(root,"MarcaDeCalorExtractor_%s" % side,
            Vector3(sx*3.92,3.61,0.43),
            Vector3(0.46,0.055,0.040),SOOT,"heat_oxidation")
        _box(root,"OxidoBaseAnclaje_%s" % side,
            Vector3(sx*3.06,0.46,-2.755),
            Vector3(0.24,0.038,0.044),OXIDE,"heat_oxidation")

static func _detail_near(model: Node3D) -> void:
    var near := _group(model,"MicrojuntasYRemachesV10")
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(12):
            var x: float = sx*(3.24+float(i)*0.158)
            _box(near,"RemacheJuntaAlta_%s_%02d" % [side,i],
                Vector3(x,2.39,-2.69),
                Vector3(0.044,0.045,0.031),EDGE,"brushed_alloy")
        for i in range(5):
            _box(near,"GotaDesgasteCanal_%s_%02d" % [side,i],
                Vector3(sx*4.85,1.79-float(i)*0.21,-2.679),
                Vector3(0.026,0.098,0.023),
                OXIDE,"heat_oxidation")
    near.visible = false

static func _fractured_facade(model: Node3D) -> void:
    # Replace the V10 intact cement panel instead of layering a burn mark
    # over an undamaged slab. Exposed fracture takes the same real depth.
    var intact: MeshInstance3D = model.find_child(
        "PanelCementicioPrefabricado_-1_1",true,false) as MeshInstance3D
    if intact != null:
        intact.visible = false
    var ruin := _group(model,"PanelDeHormigonFracturadoV10")
    _box(ruin,"HuecoBajoLosaRota",
        Vector3(-4.12,1.13,-2.682),
        Vector3(0.55,1.65,0.055),JOINT,"industrial_roof")
    _chamfer(ruin,"FragmentoPanelSuperior",
        Vector3(-4.14,1.85,-2.744),
        Vector3(0.51,0.30,0.095),0.08,CEMENT,"blast_concrete")
    _box(ruin,"FragmentoPanelInferiorGrieta",
        Vector3(-4.20,0.56,-2.747),
        Vector3(0.37,0.42,0.065),CEMENT,"blast_concrete",
        Vector3(0,0,11))
    for i in range(3):
        var x: float = -4.29+float(i)*0.14
        _beam(ruin,"AceroArmadoExpuesto_%02d" % i,
            Vector3(x,0.61,-2.79),
            Vector3(x+0.08,1.60-float(i)*0.14,-2.77),
            0.033,OXIDE,"heat_oxidation")
    _box(ruin,"PlacaDeFachadaEnSuelo",
        Vector3(-3.78,0.21,-3.36),
        Vector3(0.58,0.055,0.41),CEMENT,"blast_concrete",
        Vector3(0,24,0))

static func _destroyed(model: Node3D) -> void:
    var ruin := _group(model,"RestosEncuentrosMaterialesV10")
    for i in range(5):
        var x: float = -2.4+float(i)*1.12
        _box(ruin,"LaminaCincColapsada_%02d" % i,
            Vector3(x,0.17+float(i%2)*0.09,-4.14),
            Vector3(0.68,0.044,0.35),EDGE.darkened(0.25),"heat_oxidation",
            Vector3(0,float(i)*17.0,12.0*float(i%3)))
    _beam(ruin,"VarillaDeHormigonDoblada",
        Vector3(-2.30,0.25,-3.45),
        Vector3(-1.75,0.83,-3.61),0.056,OXIDE,"heat_oxidation")

static func set_near_detail(model: Node3D,near: bool) -> void:
    if model == null:
        return
    var group: Node3D = model.find_child("MicrojuntasYRemachesV10",true,false) as Node3D
    if group != null:
        group.visible = near

static func apply(model: Node3D,level: int,tint: Color,condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_visual_v10",false):
        return
    if not model.get_meta("tarvoka_hq_visual_v9",false):
        return
    model.set_meta("tarvoka_hq_visual_v10",true)
    model.set_meta("tarvoka_hq_v10_visual_only",true)
    if condition == "destruido":
        _destroyed(model)
        return
    _material_junctions(model,level)
    _roof_panels(model,tint)
    _wear_from_drains(model)
    _detail_near(model)
    if condition == "danado":
        _fractured_facade(model)
    set_near_detail(model,false)
