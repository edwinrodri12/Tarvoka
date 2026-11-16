extends RefCounted
class_name TarvokaHeadquartersRefinementV11

# V11 native geometry: rounded cast edges and functional mechanical details.
# Separate from scene lighting. All assets original; does not touch gameplay.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const PBR = preload("res://scripts/ui/HeadquartersFinishV8.gd")
const CONCRETE := Color("#b3c0bd")
const DEEP := Color("#263a45")
const ALLOY := Color("#adbfc5")
const GRAPHITE := Color("#455662")
const RUBBER := Color("#1b2b35")
const GLASS := Color("#4b7b8c")
const BURNT := Color("#63524c")
const LIGHT := Color("#e4c58f")

static func _group(parent: Node3D, label: String) -> Node3D:
    return Finish._group(parent,label)

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, color: Color, style: String = "brushed_alloy",
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return PBR._box(parent,label,at,size,color,style,rotation)

static func _beam(parent: Node3D, label: String, a: Vector3,
        b: Vector3, radius: float, color: Color,
        style: String = "brushed_alloy") -> MeshInstance3D:
    return PBR._beam(parent,label,a,b,radius,color,style)

static func _mesh(parent: Node3D, label: String, surf: SurfaceTool,
        color: Color, style: String = "brushed_alloy",
        faction: bool = false) -> MeshInstance3D:
    surf.generate_normals()
    surf.generate_tangents()
    var mesh: MeshInstance3D = MeshInstance3D.new()
    mesh.name = label
    mesh.mesh = surf.commit()
    mesh.material_override = PBR._material(color,style)
    if faction:
        mesh.set_meta("tarvoka_faction_panel",true)
    parent.add_child(mesh)
    return mesh

static func _tri(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    # Real UVs allow the retained cached PBR maps to shade bevel curvature.
    for p in [a,b,c]:
        tool.set_uv(Vector2(p.x*0.23+0.52,p.y*0.27+p.z*0.16))
        tool.add_vertex(p)

static func _curve(parent: Node3D,label: String,
        start_x: float,end_x: float, height: float,z: float,
        rise: float,depth: float, color: Color,
        style: String = "brushed_alloy",
        faction: bool = false) -> MeshInstance3D:
    # A fully closed, convex, 24-segment extruded cast-metal eyebrow.
    # Important: real top, bottom, front and back surfaces (not flat decal).
    var steps: int = 24
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var radius: float = maxf(0.001,(end_x-start_x)*0.5)
    for i in range(steps):
        var t0: float = float(i)/float(steps)
        var t1: float = float(i+1)/float(steps)
        var x0: float = lerpf(start_x,end_x,t0)
        var x1: float = lerpf(start_x,end_x,t1)
        var shape0: float = sqrt(maxf(0.0,1.0-pow((x0-(start_x+end_x)*0.5)/radius,2.0)))
        var shape1: float = sqrt(maxf(0.0,1.0-pow((x1-(start_x+end_x)*0.5)/radius,2.0)))
        var y0: float = height+rise*shape0
        var y1: float = height+rise*shape1
        var a := Vector3(x0,y0,z)
        var b := Vector3(x1,y1,z)
        var c := Vector3(x0,y0-0.13,z)
        var d := Vector3(x1,y1-0.13,z)
        var e: Vector3 = a+Vector3(0,0,depth)
        var f: Vector3 = b+Vector3(0,0,depth)
        var g: Vector3 = c+Vector3(0,0,depth)
        var h: Vector3 = d+Vector3(0,0,depth)
        # Winding is set for external faces, cull remains disabled for export.
        _tri(st,a,b,f)
        _tri(st,a,f,e)
        _tri(st,d,c,g)
        _tri(st,d,g,h)
        _tri(st,c,d,b)
        _tri(st,c,b,a)
        _tri(st,e,f,h)
        _tri(st,e,h,g)
        if i == 0:
            _tri(st,a,e,g)
            _tri(st,a,g,c)
        if i == steps-1:
            _tri(st,b,d,h)
            _tri(st,b,h,f)
    return _mesh(parent,label,st,color,style,faction)

static func _rounded_exteriors(model: Node3D,level: int,tint: Color) -> void:
    var node := _group(model,"CantonerasRedondeadasDeHormigonV11")
    # Recessed colored lower band / cast concrete curved caps replace the
    # former disconnected floating rectangular slab appearance.
    for side in [-1,1]:
        var sx: float = float(side)
        var x: float = sx*4.02
        _curve(node,"CornisaCurvadaHormigonAla_%s" % side,
            x-1.13,x+1.13,2.36,-2.80,0.15,0.22,CONCRETE,"blast_concrete")
        _curve(node,"PerfilCurvadoColorAla_%s" % side,
            x-1.06,x+1.06,2.48,-2.838,0.13,0.09,
            tint.darkened(0.22),"brushed_alloy",true)
        _curve(node,"RejillaSombreroAluminio_%s" % side,
            x-0.79,x+0.79,3.52,0.27,0.16,0.26,ALLOY)
        for i in range(5):
            var gx: float = x-0.49+float(i)*0.245
            _box(node,"BranquiaAdmisiónHVAC_%s_%02d" % [side,i],
                Vector3(gx,3.26,0.173),
                Vector3(0.12,0.38,0.084),DEEP,"industrial_roof",
                Vector3(13,0,0))
            _box(node,"AristaPulidaAdmisión_%s_%02d" % [side,i],
                Vector3(gx,3.09,0.111),
                Vector3(0.13,0.05,0.064),ALLOY)
        _beam(node,"TuberíaDeDrenajeCodoSuperior_%s" % side,
            Vector3(sx*4.97,2.78,1.71),
            Vector3(sx*5.14,2.71,1.60),0.062,GRAPHITE)
        _beam(node,"TuberíaDeDrenajeVertical_%s" % side,
            Vector3(sx*5.14,2.71,1.60),
            Vector3(sx*5.14,0.37,1.60),0.061,GRAPHITE)
        _box(node,"PieTuboSellado_%s" % side,
            Vector3(sx*5.14,0.28,1.60),
            Vector3(0.23,0.12,0.24),RUBBER,"industrial_roof")
    var top: float = 2.87+0.91*float(level-1)
    _curve(node,"RemateCascaraCurvaDelPuente",
        -1.81,1.81,top+1.83,-3.36,0.21,0.48,
        GRAPHITE,"brushed_alloy")
    _curve(node,"FileteMetalSuperiorTorre",
        -1.69,1.69,top+1.93,-3.388,0.22,0.11,
        ALLOY,"brushed_alloy")
    # Narrow real black gasket beneath the cast curved cap to establish the
    # gap between opaque metal and panoramic safety glazing.
    _curve(node,"SelloGomaBajoCornisaTorre",
        -1.73,1.73,top+1.66,-3.387,0.06,0.075,RUBBER,
        "industrial_roof")

static func _door_and_scales(model: Node3D,tint: Color) -> void:
    var node := _group(model,"AcabadoEntradaSinAristasDurasV11")
    _curve(node,"ArcoMetalBlindadoPuerta",
        -1.35,1.35,2.22,-4.31,0.21,0.36,ALLOY)
    _curve(node,"SelladoCurvadoPortal",
        -1.23,1.23,2.11,-4.36,0.17,0.10,RUBBER,
        "industrial_roof")
    _box(node,"UmbralDeCeramicaTactil",
        Vector3(0,0.215,-4.52),
        Vector3(2.34,0.035,0.13),CONCRETE,"blast_concrete")
    for side in [-1,1]:
        var sx: float = float(side)
        _beam(node,"JambaCurvaPuerta_%s" % side,
            Vector3(sx*1.31,0.29,-4.286),
            Vector3(sx*1.31,2.11,-4.286),0.045,ALLOY)
        _box(node,"JuntaDePuertaElastomero_%s" % side,
            Vector3(sx*1.27,1.12,-4.315),
            Vector3(0.047,1.68,0.047),RUBBER,"industrial_roof")
        for i in range(3):
            _box(node,"BisagraCarcasaVisible_%s_%d" % [side,i],
                Vector3(sx*1.35,0.62+float(i)*0.47,-4.346),
                Vector3(0.10,0.16,0.072),GRAPHITE)

static func _fine_details(model: Node3D) -> void:
    var detail := _group(model,"MicrodetalleCurvasV11")
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(9):
            var xx: float = sx*(3.31+float(i)*0.182)
            _box(detail,"RemacheCantoneraV11_%s_%02d" % [side,i],
                Vector3(xx,2.492,-2.913),
                Vector3(0.044,0.033,0.025),ALLOY)
        for i in range(4):
            _box(detail,"AbrazaderaDrenajeV11_%s_%02d" % [side,i],
                Vector3(sx*5.14,0.69+float(i)*0.58,1.60),
                Vector3(0.18,0.085,0.18),RUBBER,"industrial_roof")
    detail.visible = false

static func _damaged(model: Node3D) -> void:
    # Material failure, not a dark rectangle over the healthy curved shell.
    var original: MeshInstance3D = model.find_child(
        "CornisaCurvadaHormigonAla_-1",true,false) as MeshInstance3D
    if original != null:
        original.visible = false
    var damaged := _group(model,"CornisaFisicamenteFracturadaV11")
    _curve(damaged,"CornisaCurvaFragmentoSano",
        -5.11,-4.40,2.36,-2.80,0.10,0.21,CONCRETE,
        "blast_concrete")
    _curve(damaged,"CornisaCurvaFragmentoAstillado",
        -3.84,-2.88,2.27,-2.81,0.06,0.18,
        CONCRETE.darkened(0.16),"blast_concrete")
    _beam(damaged,"AnguloAceroSeparado",
        Vector3(-4.34,2.34,-2.83),
        Vector3(-4.11,2.06,-2.77),0.048,BURNT,"heat_oxidation")
    _box(damaged,"AislanteVisibleBajoFractura",
        Vector3(-4.19,2.19,-2.78),
        Vector3(0.34,0.16,0.09),RUBBER,"industrial_roof")

static func _destroyed(model: Node3D,tint: Color) -> void:
    var broken := _group(model,"EscombrosCurvasOriginalesV11")
    _curve(broken,"PerfilArcoFachadaSobreEscombros",
        -2.62,-0.85,0.48,-4.21,0.16,0.26,
        tint.darkened(0.44),"heat_oxidation")
    _box(broken,"FragmentoCascoTorre",
        Vector3(1.38,0.33,-3.65),
        Vector3(1.13,0.22,0.60),BURNT,"heat_oxidation",
        Vector3(8,27,21))

static func set_near_detail(model: Node3D,near: bool) -> void:
    if model == null:
        return
    var detail: Node3D = model.find_child(
        "MicrodetalleCurvasV11",true,false) as Node3D
    if detail != null:
        detail.visible = near

static func apply(model: Node3D,level: int,tint: Color,condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_visual_v11",false):
        return
    if not model.get_meta("tarvoka_hq_visual_v10",false):
        return
    model.set_meta("tarvoka_hq_visual_v11",true)
    model.set_meta("tarvoka_hq_v11_visual_only",true)
    if condition == "destruido":
        _destroyed(model,tint)
        return
    _rounded_exteriors(model,level,tint)
    _door_and_scales(model,tint)
    _fine_details(model)
    if condition == "danado":
        _damaged(model)
    set_near_detail(model,false)
