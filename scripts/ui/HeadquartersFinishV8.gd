extends RefCounted
class_name TarvokaHeadquartersFinishV8

# V8 artistic finish for an existing HQ V7 scene. Does not touch gameplay.
# PBR materials are procedurally authored and cached; the approved eight
# emblems and the original faction material identity remain unchanged.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const ALLOY := Color("#899ba4")
const IRON := Color("#263945")
const SEAL := Color("#25303a")
const PALE := Color("#d0d9d8")
const GLASS := Color("#315d73")
const OXIDE := Color("#826c58")
const ASH := Color("#343537")
const AMBER := Color("#e7b954")
static var _maps: Dictionary = {}
static var _material_cache: Dictionary = {}

static func _noise(x: int, y: int, seed: int) -> float:
    return float(posmod(x*73+y*127+x*y*17+seed*271+x*x*11+y*y*7,997))/996.0

static func _map(style: String, kind: String) -> ImageTexture:
    var key: String = style+"/"+kind
    if _maps.has(key):
        return _maps[key]
    var im := Image.create(128,128,false,Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var grain: float = _noise(x,y,5)
            var fine: float = _noise(x,y,19)
            var height: float = (grain-0.5)*0.16
            var value: float = 0.86+0.09*grain
            var rough: float = 0.64+0.16*fine
            if style == "brushed_alloy":
                height = (fine-0.5)*0.07
                value = 0.86+0.10*grain
                rough = 0.39+0.11*fine
                if y%13 == 0:
                    value *= 0.88
                    height -= 0.12
                if x%41 == 0 and (y+13)%47 < 17:
                    value *= 0.82
            elif style == "industrial_roof":
                value = 0.75+0.18*grain
                rough = 0.68+0.17*fine
                if x%32 < 2:
                    value *= 0.75
                    height -= 0.25
                if (x*3+y*5)%211 < 3:
                    value *= 0.76
            elif style == "laminated_glass":
                value = 0.88+0.09*grain
                rough = 0.17+0.13*fine
                height = (fine-0.5)*0.016
                if x%32 == 0:
                    value *= 0.95
            elif style == "blast_concrete":
                value = 0.73+0.18*grain
                rough = 0.77+0.17*fine
                if y%46 < 2 or x%64 < 2:
                    value *= 0.78
                    height -= 0.20
            elif style == "heat_oxidation":
                value = 0.58+0.25*grain
                rough = 0.83+0.11*fine
                if (x+y*3)%43 < 4:
                    value *= 0.78
            if kind == "albedo":
                im.set_pixel(x,y,Color(value,value,value,1))
            elif kind == "roughness":
                im.set_pixel(x,y,Color(rough,rough,rough,1))
            else:
                var h_x: float = (_noise(x+1,y,5)-_noise(x-1,y,5))*0.19
                var h_y: float = (_noise(x,y+1,19)-_noise(x,y-1,19))*0.19
                var n: Vector3 = Vector3(-h_x,-h_y,1.0+absf(height)).normalized()
                im.set_pixel(x,y,Color(n.x*0.5+0.5,n.y*0.5+0.5,n.z*0.5+0.5,1))
    var tex: ImageTexture = ImageTexture.create_from_image(im)
    _maps[key] = tex
    return tex

static func _material(color: Color,style: String) -> StandardMaterial3D:
    var key: String = style+"/"+color.to_html(true)
    if _material_cache.has(key):
        return _material_cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.albedo_texture = _map(style,"albedo")
    m.roughness_texture = _map(style,"roughness")
    m.normal_enabled = true
    m.normal_texture = _map(style,"normal")
    m.normal_scale = 0.20 if style == "laminated_glass" else 0.42
    m.metallic = 0.61 if style == "brushed_alloy" else (
        0.32 if style == "industrial_roof" else (0.03 if style == "laminated_glass" else 0.06))
    m.roughness = 0.35 if style == "laminated_glass" else (
        0.53 if style == "brushed_alloy" else 0.88)
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    _material_cache[key] = m
    return m

static func _group(parent: Node3D, name: String) -> Node3D:
    return Finish._group(parent,name)

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, color: Color, style: String = "brushed_alloy",
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var instance: MeshInstance3D = Finish._box(
        parent,name,pos,size,color,"steel",false,rotation)
    instance.material_override = _material(color,style)
    return instance

static func _beam(parent: Node3D, name: String, a: Vector3,
        b: Vector3, thickness: float, color: Color,
        style: String = "brushed_alloy") -> MeshInstance3D:
    var instance: MeshInstance3D = Finish._beam(parent,name,a,b,thickness,color)
    instance.material_override = _material(color,style)
    return instance

static func _finish_existing(model: Node3D) -> int:
    var count: int = 0
    var rules: Dictionary = {
        "MarquesinaAerodinamicaCurvaV7":"industrial_roof",
        "MarcoExteriorDeAcceso":"brushed_alloy",
        "DintelEscudoDeMandoCurvo":"brushed_alloy",
        "CubiertaConEscalon":"industrial_roof",
        "MasaCentralElevada":"industrial_roof",
        "CarcasaHVAC_-1":"brushed_alloy",
        "CarcasaHVAC_1":"brushed_alloy",
        "BaseHVAC_-1":"industrial_roof",
        "BaseHVAC_1":"industrial_roof",
        "CubiertaConvexaAla_-1":"industrial_roof",
        "CubiertaConvexaAla_1":"industrial_roof",
        "CristalPanoramicoComando_-1":"laminated_glass",
        "CristalPanoramicoComando_1":"laminated_glass",
        "HojaCristalBlindado_-1":"laminated_glass",
        "HojaCristalBlindado_1":"laminated_glass",
        "UmbralInteriorRehundido":"industrial_roof",
        "AristaAlaBiselada_-1":"brushed_alloy",
        "AristaAlaBiselada_1":"brushed_alloy"
    }
    for name in rules:
        var mesh: MeshInstance3D = model.find_child(name,true,false) as MeshInstance3D
        if mesh == null:
            continue
        var old: StandardMaterial3D = mesh.material_override as StandardMaterial3D
        if old == null:
            continue
        # Keep the exact approved faction tint for painted meshes.
        mesh.material_override = _material(old.albedo_color,str(rules[name]))
        count += 1
    model.set_meta("tarvoka_hq_v8_pbr_overrides",count)
    return count

static func _construction_joints(model: Node3D, tint: Color) -> void:
    var joints := _group(model,"UnionesEstructuralesV8")
    # Deep dark gaskets and metal cover plates at real wing/body junctions.
    # These details visually explain how the building volumes connect.
    for side in [-1,1]:
        var sx: float = float(side)
        _box(joints,"JuntaExpansionFachada_%s" % side,
            Vector3(sx*2.95,1.29,-2.425),
            Vector3(0.067,2.37,0.09),SEAL,"industrial_roof")
        _box(joints,"CubreJuntaAluminio_%s" % side,
            Vector3(sx*3.04,1.35,-2.498),
            Vector3(0.17,2.23,0.056),ALLOY)
        for k in range(3):
            _box(joints,"PlacaAnclajeUnión_%s_%d" % [side,k],
                Vector3(sx*3.04,0.62+float(k)*0.69,-2.541),
                Vector3(0.28,0.19,0.049),IRON)
        _beam(joints,"RiostraCubiertaAla_%s" % side,
            Vector3(sx*2.96,2.69,-2.12),
            Vector3(sx*3.57,2.91,-1.63),0.074,ALLOY)
        _box(joints,"PerfilCantosDeHormigón_%s" % side,
            Vector3(sx*2.05,0.57,-2.64),
            Vector3(0.13,0.80,0.055),PALE,"blast_concrete")
        _box(joints,"DesagüeFachada_%s" % side,
            Vector3(sx*4.96,1.02,-2.10),
            Vector3(0.09,1.39,0.12),IRON,"industrial_roof")
        _box(joints,"BaseProtecciónDesagüe_%s" % side,
            Vector3(sx*4.96,0.25,-2.14),
            Vector3(0.22,0.19,0.20),SEAL)
    _box(joints,"ZócaloHormigónRepicado",
        Vector3(0,0.32,-3.75),
        Vector3(2.44,0.13,0.13),PALE,"blast_concrete")
    _box(joints,"CantoneraMetálicaPortón",
        Vector3(0,2.09,-4.082),
        Vector3(2.17,0.085,0.06),ALLOY)
    _box(joints,"CanalDeDrenajeAcceso",
        Vector3(0,0.065,-4.80),
        Vector3(2.35,0.05,0.15),SEAL,"industrial_roof")
    for i in range(9):
        _box(joints,"RejillaDrenaje_%02d" % i,
            Vector3(-1.01+float(i)*0.25,0.100,-4.81),
            Vector3(0.075,0.035,0.11),ALLOY)

static func _weathered_details(model: Node3D, level: int) -> void:
    var near := _group(model,"MicroAcabadosV8")
    # Conservative physical grime at expansion seams and bottom plates:
    # visible only at close zoom so the tactical silhouette remains clean.
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(6):
            var x: float = sx*(3.13+float(i)*0.37)
            _box(near,"PicaduraOxidoBajoAlero_%s_%02d" % [side,i],
                Vector3(x,2.18-float(i%3)*0.064,-2.128),
                Vector3(0.16,0.042+float(i%3)*0.028,0.025),
                OXIDE,"heat_oxidation")
        for i in range(4):
            _box(near,"FinaJuntaVidrio_%s_%02d" % [side,i],
                Vector3(sx*4.06,1.12+float(i)*0.15,-2.103),
                Vector3(0.48,0.020,0.032),ALLOY)
    var y: float = 2.87+float(level-1)*0.91
    var bolts := MultiMesh.new()
    var fastener := SphereMesh.new()
    fastener.radius = 0.031
    fastener.height = 0.062
    fastener.radial_segments = 8
    fastener.rings = 4
    bolts.mesh = fastener
    bolts.transform_format = MultiMesh.TRANSFORM_3D
    bolts.instance_count = 60
    for i in range(60):
        var row: int = int(i/30)
        var col: int = i%30
        var x: float = -1.71+float(col)*0.118
        var position := Vector3(x,y+1.72-float(row)*0.11,-3.51)
        bolts.set_instance_transform(i,Transform3D(Basis.IDENTITY,position))
    var rivets := MultiMeshInstance3D.new()
    rivets.name = "RemachesFachadaPBRV8"
    rivets.multimesh = bolts
    rivets.material_override = _material(ALLOY,"brushed_alloy")
    near.add_child(rivets)
    near.visible = false

static func _wedge(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    for p in [a,b,c]:
        st.set_uv(Vector2(p.x+1.3,2.0-p.y))
        st.add_vertex(p)

static func _fractured_glass(model: Node3D) -> void:
    var intact: MeshInstance3D = model.find_child(
        "HojaCristalBlindado_-1",true,false) as MeshInstance3D
    if intact != null:
        intact.visible = false
    # Irregular shards around a genuinely open center; not a black rectangle
    # painted over an undamaged full window.
    var damage := _group(model,"CristalRotoGeometricoV8")
    var z: float = -4.11
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var top_left := Vector3(-0.90,1.79,z)
    var top_right := Vector3(-0.09,1.79,z)
    var bottom_left := Vector3(-0.90,0.33,z)
    var bottom_right := Vector3(-0.09,0.33,z)
    var rim_a := Vector3(-0.55,1.38,z)
    var rim_b := Vector3(-0.31,1.20,z)
    var rim_c := Vector3(-0.61,0.84,z)
    var rim_d := Vector3(-0.24,0.64,z)
    _wedge(st,top_left,top_right,rim_a)
    _wedge(st,top_right,rim_b,rim_a)
    _wedge(st,top_left,rim_a,bottom_left)
    _wedge(st,bottom_left,rim_c,rim_a)
    _wedge(st,bottom_left,bottom_right,rim_c)
    _wedge(st,bottom_right,rim_d,rim_c)
    _wedge(st,bottom_right,bottom_right+Vector3(0,0.33,0),rim_d)
    st.generate_normals()
    st.generate_tangents()
    var broken := MeshInstance3D.new()
    broken.name = "FragmentosDeVidrioConVacioV8"
    broken.mesh = st.commit()
    broken.material_override = _material(GLASS,"laminated_glass")
    damage.add_child(broken)
    _beam(damage,"GrietaDeVidrioPrincipal",
        Vector3(-0.55,1.38,z-0.01),Vector3(-0.31,1.20,z-0.01),
        0.012,PALE)
    _beam(damage,"PerfilDePuertaDeformado",
        Vector3(-0.91,1.78,z-0.012),Vector3(-0.81,0.48,z-0.012),
        0.036,ASH)

static func _scorched_damage(model: Node3D) -> void:
    var part := _group(model,"QuemadurasFísicasV8")
    _box(part,"AblaciónBajoCubierta",
        Vector3(-4.07,2.77,-2.28),
        Vector3(0.71,0.08,0.21),ASH,"heat_oxidation",
        Vector3(-8,0,9))
    _box(part,"TapaMotorRadarArrancada",
        Vector3(-1.25,3.44,1.20),
        Vector3(0.42,0.09,0.39),OXIDE,"heat_oxidation",
        Vector3(24,-9,16))
    _beam(part,"CanalónAbollado",
        Vector3(3.14,2.68,-2.27),
        Vector3(3.96,2.45,-2.21),0.049,ASH,"heat_oxidation")

static func _ruin_materials(model: Node3D, tint: Color) -> void:
    var debris := _group(model,"RuinaMetalicaDeMaterialesV8")
    _box(debris,"CompuertaCortada",
        Vector3(-2.33,0.32,-3.89),
        Vector3(1.40,0.13,0.66),IRON,"heat_oxidation",
        Vector3(0,-18,17))
    _box(debris,"PlacaDeBlindajeQuemada",
        Vector3(1.11,0.48,-2.89),
        Vector3(1.37,0.18,0.73),ASH,"heat_oxidation",
        Vector3(9,23,21))
    _beam(debris,"AristaTorreResquebrajada",
        Vector3(0.51,0.32,-3.87),
        Vector3(1.23,1.04,-3.16),0.085,OXIDE)
    for i in range(7):
        _box(debris,"PanelRevestimientoRoto_%02d" % i,
            Vector3(-1.90+float(i)*0.55,0.17,-4.45+float(i%2)*0.28),
            Vector3(0.36,0.045,0.22),
            tint.darkened(0.36) if i%2==0 else ASH,
            "heat_oxidation",Vector3(0,float(i)*21.0,0))

static func set_near_detail(model: Node3D, visible: bool) -> void:
    if model == null:
        return
    var near: Node3D = model.find_child(
        "MicroAcabadosV8",true,false) as Node3D
    if near != null:
        near.visible = visible

static func apply(model: Node3D,level: int,tint: Color,
        condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_visual_v8",false):
        return
    if not model.get_meta("tarvoka_hq_visual_v7",false):
        return
    model.set_meta("tarvoka_hq_visual_v8",true)
    if condition == "destruido":
        _ruin_materials(model,tint)
        return
    _finish_existing(model)
    _construction_joints(model,tint)
    _weathered_details(model,level)
    if condition == "danado":
        _fractured_glass(model)
        _scorched_damage(model)
    set_near_detail(model,false)
