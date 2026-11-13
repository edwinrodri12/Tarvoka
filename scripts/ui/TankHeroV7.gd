extends RefCounted
class_name TarvokaTankHeroV7

# G09: actual full-resolution geometric hero pass, NOT a bolted-on cube layer.
# Continuous sealed multi-ring hull/turret, shaped front armor, suspended tread
# loops, 24 round steel road wheels and integrated low-height optics. The 14
# original faction paintable panels and battle rig stay completely independent.
# Use one coherent matte material family across every new armored surface.
const ROOT := "G09HERO7"
const Finish = preload("res://scripts/ui/TankFinish3D.gd")
const ARMOR := Color("#596a75")
const CERAMIC := Color("#818d99")
const METAL := Color("#424f5a")
const RUBBER := Color("#1c252d")
const GLASS := Color("#174b62")
const WEAR := Color("#929b9c")
const SEAM := Color("#18242c")
const DIRT := Color("#625d55")
const TRACK_COUNT := 156

static var _paint_map: ImageTexture
static var _metal_map: ImageTexture
static var _micro_normal: ImageTexture
static var _micro_roughness: ImageTexture

static func _hash(x: int, y: int) -> float:
    return float(posmod(posmod(x*9283+y*5393+491,104729)*13+73,104729))/104728.0

static func _smooth_hash(x: float,y: float, period: float) -> float:
    var fx: float = x/period
    var fy: float = y/period
    var px: int = floori(fx)
    var py: int = floori(fy)
    var u: float = fx-float(px)
    var v: float = fy-float(py)
    u = u*u*(3.0-2.0*u)
    v = v*v*(3.0-2.0*v)
    return lerpf(lerpf(_hash(px,py),_hash(px+1,py),u),
        lerpf(_hash(px,py+1),_hash(px+1,py+1),u),v)

static func _army_texture() -> ImageTexture:
    # Neutral roughness-ready ENAMEL modulation. Color resides in each
    # independently tintable armor material; gone is the V7 problem of every
    # ceramic/steel part sharing the same bright green camouflage.
    if _paint_map != null:
        return _paint_map
    const SIDE := 256
    var img := Image.create(SIDE,SIDE,false,Image.FORMAT_RGBA8)
    for y in range(SIDE):
        for x in range(SIDE):
            var broad: float = _smooth_hash(float(x),float(y),72.0)
            var medium: float = _smooth_hash(float(x),float(y),21.0)
            var fine: float = _smooth_hash(float(x),float(y),4.0)
            var grit: float = _hash(x,y)
            var dusty: float = (1.0-float(y)/255.0) * 0.028
            var value: float = 0.88 + 0.13*(broad-0.5) + \
                0.066*(medium-0.5)+0.018*(fine-0.5)+dusty
            if grit > 0.994 and fine < 0.40:
                value = minf(1.0,value+0.08)
            value = clampf(value,0.75,1.0)
            img.set_pixel(x,y,Color(value,value,value,1))
    _paint_map = ImageTexture.create_from_image(img)
    return _paint_map

static func _army_micro_normal() -> ImageTexture:
    if _micro_normal != null:
        return _micro_normal
    const SIDE := 256
    var img := Image.create(SIDE,SIDE,false,Image.FORMAT_RGBA8)
    for y in range(SIDE):
        for x in range(SIDE):
            var x1: float = _smooth_hash(float(x+1),float(y),5.0)
            var x0: float = _smooth_hash(float(x-1),float(y),5.0)
            var y1: float = _smooth_hash(float(x),float(y+1),5.0)
            var y0: float = _smooth_hash(float(x),float(y-1),5.0)
            var dx: float = (x1-x0)*0.29
            var dy: float = (y1-y0)*0.29
            var normal: Vector3 = Vector3(-dx,-dy,1.0).normalized()
            img.set_pixel(x,y,Color(
                normal.x*0.5+0.5,normal.y*0.5+0.5,normal.z*0.5+0.5))
    _micro_normal = ImageTexture.create_from_image(img)
    return _micro_normal

static func _army_micro_roughness() -> ImageTexture:
    if _micro_roughness != null:
        return _micro_roughness
    const SIDE := 256
    var img := Image.create(SIDE,SIDE,false,Image.FORMAT_RGBA8)
    for y in range(SIDE):
        for x in range(SIDE):
            var patch: float = _smooth_hash(float(x),float(y),26.0)
            var grit: float = _hash(x,y)
            var value: float = clampf(0.73+0.15*(patch-0.5)+0.06*(grit-0.5),0.59,0.87)
            img.set_pixel(x,y,Color(value,value,value,1))
    _micro_roughness = ImageTexture.create_from_image(img)
    return _micro_roughness

static func _army_material(color: Color = ARMOR,
        embedded_paint: bool = true) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    if embedded_paint:
        m.albedo_texture = _army_texture()
        m.normal_enabled = true
        m.normal_texture = _army_micro_normal()
        m.normal_scale = 0.38
        m.roughness_texture = _army_micro_roughness()
    m.roughness = 0.77 if embedded_paint else 0.61
    m.metallic = 0.19 if embedded_paint else 0.42
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    var normal: Vector3 = (b-a).cross(c-a)
    if normal.length_squared() < 0.0000001:
        return
    normal = normal.normalized()
    for p in [a,b,c]:
        st.set_normal(normal)
        # World-consistent handcrafted UV projection; different XY/XZ slopes
        # avoid an untextured top or identical paint panels on both flanks.
        st.set_uv(Vector2(p.x*0.38+p.z*0.19+0.5,p.z*0.31+p.y*0.26+0.5))
        st.add_vertex(p)

static func _loft(parent: Node3D,name: String,outline: Array,
        levels: Array, tint: Color = ARMOR) -> MeshInstance3D:
    # Each level is [height, XZ inset, nose drop]. Every ring connects to its
    # neighbors; both solid caps and every side wall are explicitly triangulated.
    var rings: Array = []
    for section in levels:
        var ring: Array = []
        var h: float = float(section[0])
        var scale: float = float(section[1])
        var nose: float = float(section[2])
        for point in outline:
            var x: float = float(point.x)*scale
            var z: float = float(point.y)*scale
            var falloff: float = clampf((-z-0.69)/0.68,0.0,1.0)
            ring.append(Vector3(x,h-nose*falloff,z))
        rings.append(ring)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size()-1):
        var lo: Array = rings[layer]
        var hi: Array = rings[layer+1]
        for i in range(outline.size()):
            var j: int = (i+1)%outline.size()
            _tri(st,lo[i],lo[j],hi[j])
            _tri(st,lo[i],hi[j],hi[i])
    var bottom: Array = rings[0]
    var top: Array = rings[rings.size()-1]
    var center_bottom := Vector3.ZERO
    var center_top := Vector3.ZERO
    for i in range(outline.size()):
        center_bottom += bottom[i]
        center_top += top[i]
    center_bottom /= float(outline.size())
    center_top /= float(outline.size())
    for i in range(outline.size()):
        var j: int = (i+1)%outline.size()
        _tri(st,center_bottom,bottom[j],bottom[i])
        _tri(st,center_top,top[i],top[j])
    var obj := MeshInstance3D.new()
    obj.name = name
    obj.mesh = st.commit()
    obj.material_override = _army_material(tint)
    parent.add_child(obj)
    return obj

static func _bevel(parent: Node3D,name: String,pos: Vector3,
        dimensions: Vector3,radius: float,tint: Color = ARMOR,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var obj: MeshInstance3D = Finish._bevel(parent,name,pos,dimensions,radius,tint)
    obj.rotation_degrees = angles
    # Do not map the pale camouflage coat onto optics/steel fittings:
    # this was the cause of two nearly white toy squares on the turret roof.
    var armor_paint: bool = not (tint == METAL or tint == RUBBER
        or tint == GLASS or tint == WEAR or tint == SEAM or tint == DIRT)
    obj.material_override = _army_material(tint,armor_paint)
    return obj

static func _dark_box(parent: Node3D,name: String,pos: Vector3,
        dims: Vector3,tint: Color = METAL) -> MeshInstance3D:
    var obj: MeshInstance3D = Finish._box(parent,name,pos,dims,tint)
    obj.material_override = _army_material(tint,false)
    return obj

static func _rod(parent: Node3D,name: String,a: Vector3,b: Vector3,
        thickness: float,color: Color = SEAM) -> MeshInstance3D:
    var obj: MeshInstance3D = Finish._rod(parent,name,a,b,thickness,color,12)
    obj.material_override = _army_material(color,false)
    return obj

static func _hide(node: Node3D,patterns: Array) -> void:
    # Parts are kept in the rig (animation and damage history still valid),
    # but only the coherent G09 high detail surface is visible.
    for pattern in patterns:
        var old: Node3D = node.find_child(str(pattern),true,false) as Node3D
        if old != null:
            old.visible = false

static func _suppress_prototype(model: Node3D) -> void:
    for name in ["CascoHermeticoV5","TorreHermeticaV5",
            "CorazaCascoAngular","CorazaTorreFacetada",
            "CunaBlindajeFrontalV5_-1","CunaBlindajeFrontalV5_1",
            "LomaBlindajeMotorV5_-1_0","LomaBlindajeMotorV5_-1_1",
            "LomaBlindajeMotorV5_-1_2","LomaBlindajeMotorV5_-1_3",
            "LomaBlindajeMotorV5_1_0","LomaBlindajeMotorV5_1_1",
            "LomaBlindajeMotorV5_1_2","LomaBlindajeMotorV5_1_3",
            "MejillaMonoliticaV6_-1","MejillaMonoliticaV6_1",
            "CantoBlindajeMejillaV6_-1","CantoBlindajeMejillaV6_1",
            "BastidorCanonIntegradoV6","BordeMantleteCeramicoV6",
            "LaminaExteriorTorreV5_-1","LaminaExteriorTorreV5_1",
            "TapaCestaBlindadaV5","BastidorTraseroIntegradoV5",
            "DeflectorPosteriorV6_-1","DeflectorPosteriorV6_1",
            "ModuloOpticoPanoramicoV6","VentanaOpticaPanoramicaV6",
            "SensorDeApuntamientoV6","LenteDeApuntamientoV6",
            "BaseEscotillaComandante","EscotillaComandante",
            "PantallaTermica","CristalTermico","VisorTermicoProtegido",
            "LenteTermicoPrincipal","ModuloVisionPanoramica",
            "CristalPanoramicoFrontal","CristalPanoramicoLateral",
            "TapaComandanteBlindadaV6","ModuloLASERBlindado1",
            "ModuloLASERBlindado-1","CristalTelescopio1","CristalTelescopio-1",
            "BarandaPosterior-1","BarandaPosterior1","BastidorTrasero-1",
            "BastidorTrasero1","BarraCestaSuperior1","BarraCestaSuperior-1",
            "BrazaSuperiorTorre1","BrazaSuperiorTorre-1",
            "CubiertaMotorSelladaV5","TapaBlindadaEstibaV6",
            "PortonTraseroHermeticoV5",
            "ModuloCeramicoLateralV6_-1_0","ModuloCeramicoLateralV6_-1_1",
            "ModuloCeramicoLateralV6_1_0","ModuloCeramicoLateralV6_1_1",
            "VisorComandante_0","VisorComandante_1","VisorComandante_2",
            "VisorComandante_3","VisorComandante_4","VisorComandante_5",
            "AntenaTorre1","AntenaTorre-1",
            "AntenaTorre1Tip","AntenaTorre-1Tip",
            "AroRuedaMotriz-1_0","AroRuedaMotriz-1_1",
            "AroRuedaMotriz1_0","AroRuedaMotriz1_1",
            "ArgollaRemolque-1","ArgollaRemolque1",
            "LanzaFumigenas-1_0","LanzaFumigenas-1_1",
            "LanzaFumigenas-1_2","LanzaFumigenas1_0",
            "LanzaFumigenas1_1","LanzaFumigenas1_2"]:
        var old: Node3D = model.find_child(name,true,false) as Node3D
        if old != null:
            old.visible = false

static func _road_wheel(parent: Node3D, side: int, index: int,
        y: float,z: float) -> void:
    var sign: float = float(side)
    var wheel := MeshInstance3D.new()
    wheel.name = "RuedaG09V7_%s_%02d" % [side,index]
    var rim := CylinderMesh.new()
    rim.top_radius = 0.164
    rim.bottom_radius = 0.164
    rim.height = 0.071
    rim.radial_segments = 24
    wheel.mesh = rim
    wheel.material_override = _army_material(METAL,false)
    wheel.position = Vector3(sign*1.304,y,z)
    wheel.rotation_degrees.z = 90
    parent.add_child(wheel)
    var hub := MeshInstance3D.new()
    hub.name = "BujeG09V7_%s_%02d" % [side,index]
    var circle := CylinderMesh.new()
    circle.top_radius = 0.071
    circle.bottom_radius = 0.071
    circle.height = 0.017
    circle.radial_segments = 18
    hub.mesh = circle
    hub.material_override = _army_material(WEAR,false)
    hub.position = Vector3(sign*1.351,y,z)
    hub.rotation_degrees.z = 90
    parent.add_child(hub)

static func _tread_mesh() -> ArrayMesh:
    # Chamfered steel/rubber tread pads, not BoxMesh prototypes. Every pad
    # carries a raised crossbar, visible at mobile isometric camera distance.
    var perimeter := [
        Vector2(-0.073,-0.048),Vector2(0.073,-0.048),
        Vector2(0.080,-0.034),Vector2(0.080,0.034),
        Vector2(0.073,0.048),Vector2(-0.073,0.048),
        Vector2(-0.080,0.034),Vector2(-0.080,-0.034)
    ]
    var rings: Array = []
    for section in [[-0.035,0.88],[-0.024,1.0],[0.023,1.0],[0.035,0.91]]:
        var outline: Array = []
        for p in perimeter:
            outline.append(Vector3(p.x*float(section[1]),float(section[0]),p.y*float(section[1])))
        rings.append(outline)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for level in range(rings.size()-1):
        var low: Array = rings[level]
        var high: Array = rings[level+1]
        for i in range(perimeter.size()):
            var j: int = (i+1)%perimeter.size()
            _tri(st,low[i],low[j],high[j])
            _tri(st,low[i],high[j],high[i])
    for i in range(perimeter.size()):
        var j: int = (i+1)%perimeter.size()
        _tri(st,Vector3(0,-0.035,0),rings[0][j],rings[0][i])
        _tri(st,Vector3(0,0.035,0),rings[3][i],rings[3][j])
    # Raised rib bonded into the rubber pad (no separate draw call).
    for side in [-1,1]:
        var s: float = float(side)
        var a := Vector3(s*0.010,0.035,-0.016)
        var b := Vector3(s*0.070,0.035,-0.016)
        var d := Vector3(s*0.010,0.047,0.016)
        var e := Vector3(s*0.070,0.047,0.016)
        _tri(st,a,b,e)
        _tri(st,a,e,d)
    return st.commit()

static func _tracks(parent: Node3D, side: int) -> MultiMeshInstance3D:
    var sign: float = float(side)
    var transforms: Array = []
    const N := 29
    for row in [0,1]:
        for i in range(N):
            var z: float = lerpf(-1.22,1.22,float(i)/float(N-1))
            var y: float = 0.613 if row == 0 else 0.041
            transforms.append(Transform3D(Basis.IDENTITY,
                Vector3(sign*1.335,y,z)))
    # Both semicircular links curve around realistic end sprockets.
    for end in [-1,1]:
        for i in range(13):
            var angle: float = -PI*0.50+PI*float(i)/12.0
            var z: float = float(end)*(1.22+0.29*cos(angle))
            var y: float = 0.327+0.286*sin(angle)
            var rotation := Basis(Vector3.RIGHT,float(end)*angle)
            transforms.append(Transform3D(rotation,Vector3(sign*1.335,y,z)))
    var inst := MultiMeshInstance3D.new()
    inst.name = "OrugaArticuladaG09V7_%s" % side
    var link_mesh: ArrayMesh = _tread_mesh()
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = link_mesh
    batch.instance_count = transforms.size()
    for i in range(transforms.size()):
        batch.set_instance_transform(i,transforms[i])
    inst.multimesh = batch
    inst.material_override = _army_material(RUBBER,false)
    parent.add_child(inst)
    return inst

static func apply_final_materials(model: Node3D) -> void:
    # Called AFTER TankSurface.apply_finish because generic PBR processing
    # installs another albedo texture. This guarantees the actual original
    # armored UV material is what both Android and browser ultimately render.
    if model == null or not model.get_meta("tarvoka_mbt_hero_v7",false):
        return
    var painted: int = 0
    for name in ["CorazaSoldadaHermeticaV7","TorreBajaSoldadaV7",
            "CubiertaMotorRectificadaV7","EstibaBlindadaTraseraV7",
            "MantleteConjuntoV7",
            "GlacisCeramicoV7_-1","GlacisCeramicoV7_1",
            "ModuloBlindajeCeramicoV7_-1","ModuloBlindajeCeramicoV7_1",
            "HombroBastidorV7_-1","HombroBastidorV7_1",
            "FaldonBlindadoIntegradoV7_-1","FaldonBlindadoIntegradoV7_1",
            "EscotillaCircularV7_00","EscotillaCircularV7_01"]:
        var mesh: MeshInstance3D = model.find_child(name,true,false) as MeshInstance3D
        if mesh == null:
            continue
        var old: StandardMaterial3D = mesh.material_override as StandardMaterial3D
        var mat: StandardMaterial3D = old.duplicate(true) as StandardMaterial3D if old != null else _army_material()
        # Body, ceramic blocks and engine plates have separate pigments,
        # not the same flat olive atlas multiplied by white.
        var is_ceramic: bool = name.begins_with("GlacisCeramico") or             name.begins_with("ModuloBlindajeCeramico")
        var is_trim: bool = name.begins_with("EscotillaCircular")
        mat.albedo_color = CERAMIC if is_ceramic else (METAL if is_trim else ARMOR)
        mat.albedo_texture = _army_texture()
        mat.normal_enabled = true
        mat.normal_texture = _army_micro_normal()
        mat.normal_scale = 0.38
        mat.roughness_texture = _army_micro_roughness()
        mat.roughness = 0.76
        mat.metallic = 0.20
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        mesh.material_override = mat
        painted += 1
    model.set_meta("tarvoka_mbt_hero_v7_textured",painted)


static func apply(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    if not model.get_meta("tarvoka_mbt_art_v6",false):
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    if hull == null or turret == null or gun == null:
        return false
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)
    _suppress_prototype(model)

    # Genuine multi-level sealed cast armor (5 distinct concentric sections)
    # produces realistic grazing edge highlights and coherent body geometry.
    var hull_profile := [
        Vector2(-0.54,-1.58),Vector2(0.54,-1.58),
        Vector2(0.73,-1.45),Vector2(0.87,-1.20),
        Vector2(0.93,-0.78),Vector2(0.94,1.07),
        Vector2(0.73,1.52),Vector2(-0.73,1.52),
        Vector2(-0.94,1.07),Vector2(-0.93,-0.78),
        Vector2(-0.87,-1.20),Vector2(-0.73,-1.45)
    ]
    var hull_levels := [
        [0.38,0.93,0.02],[0.52,1.0,0.08],
        [0.92,1.0,0.11],[1.046,0.93,0.17],[1.087,0.88,0.18]
    ]
    var shell: MeshInstance3D = _loft(hull,"CorazaSoldadaHermeticaV7",
        hull_profile,hull_levels)

    # Reinforced prow is an integral composite wedge, not a flat gray box.
    for side in [-1,1]:
        var sign: float = float(side)
        var nose := _bevel(hull,"GlacisCeramicoV7_%s" % side,
            Vector3(sign*0.37,0.94,-1.25),
            Vector3(0.62,0.086,0.59),0.061,CERAMIC,
            Vector3(-27.0,sign*5.0,0.0))
        _rod(hull,"UnionSoldadaGlacisV7_%s" % side,
            Vector3(sign*0.71,0.98,-1.03),
            Vector3(sign*0.63,0.83,-1.50),0.017)
    _dark_box(hull,"NarizInferiorV7",Vector3(0,0.49,-1.55),
        Vector3(1.15,0.18,0.10),METAL)
    # Wedge armor is layered into a flush service brow rather than the old
    # giant empty front slab. Thin white LED housings use actual emissive
    # PBR materials (night battle readability), not billboard glows.
    for side in [-1,1]:
        var sign: float = float(side)
        _bevel(hull,"SoporteFaroBlindadoG09_%s" % side,
            Vector3(sign*0.58,0.865,-1.521),
            Vector3(0.24,0.145,0.095),0.028,METAL)
        var light := _dark_box(hull,"LuzFrontalG09_%s" % side,
            Vector3(sign*0.58,0.864,-1.578),
            Vector3(0.165,0.069,0.012),Color("#B5D5DF"))
        var light_mat := light.material_override as StandardMaterial3D
        light_mat.roughness = 0.22
        light_mat.metallic = 0.08
        light_mat.emission_enabled = true
        light_mat.emission = Color("#BEDBE9")
        light_mat.emission_energy_multiplier = 0.62
        _rod(hull,"CantoFrontalChasisG09_%s" % side,
            Vector3(sign*0.81,0.945,-1.33),
            Vector3(sign*0.66,0.805,-1.52),0.022,METAL)
    _bevel(hull,"RampaBlindajeProaV8",Vector3(0,0.708,-1.565),
        Vector3(0.76,0.14,0.105),0.044,ARMOR)
    _bevel(hull,"CubiertaMotorRectificadaV7",
        Vector3(0,1.102,1.055),Vector3(1.39,0.066,0.79),0.038,ARMOR)
    # Embedded rear louvers and exhaust appear as dark vents, not blocks.
    for i in range(5):
        var z: float = 0.80+float(i)*0.125
        _dark_box(hull,"RespiraderoMotorV7_%02d" % i,
            Vector3(0,1.143,z),Vector3(1.07,0.014,0.060),SEAM)
        _rod(hull,"BordeVentilacionV7_%02d" % i,
            Vector3(-0.50,1.151,z+0.038),
            Vector3(0.50,1.151,z+0.038),0.009,METAL)
    # The watertight main chassis ALREADY has a solid, painted rear face.
    # Three stacked prototype panels created a distracting bright rectangular
    # outline in the real WebGL review. Leave a flush service closure and
    # small recessed black latches instead of another floating rear box.
    for side in [-1,1]:
        var rear_sign: float = float(side)
        _dark_box(hull,"CerrojoRebajadoPosteriorV7_%s" % side,
            Vector3(rear_sign*0.49,0.71,1.529),
            Vector3(0.12,0.18,0.019),SEAM)
        var tail := _dark_box(hull,"LuzTraseraG09_%s" % side,
            Vector3(rear_sign*0.66,0.694,1.558),
            Vector3(0.165,0.064,0.012),Color("#8C2E33"))
        var tail_mat := tail.material_override as StandardMaterial3D
        tail_mat.roughness = 0.27
        tail_mat.metallic = 0.05
        tail_mat.emission_enabled = true
        tail_mat.emission = Color("#BA3540")
        tail_mat.emission_energy_multiplier = 0.38
    for side in [-1,1]:
        var sign: float = float(side)
        # Actual heavy side composite shoulder and inside tread belt.
        _bevel(hull,"HombroBastidorV7_%s" % side,
            Vector3(sign*0.96,0.82,0.02),
            Vector3(0.225,0.204,2.75),0.062,ARMOR)
        _rod(hull,"SoldaduraHombroV7_%s" % side,
            Vector3(sign*1.05,0.942,-1.25),
            Vector3(sign*1.05,0.942,1.26),0.020,SEAM)
        # Side skirt covers the tread from above but leaves moving belts
        # and the physically circular road wheels visible below.
        _bevel(hull,"FaldonBlindadoIntegradoV7_%s" % side,
            Vector3(sign*1.18,0.754,-0.025),
            Vector3(0.105,0.36,2.69),0.049,ARMOR)
        # The original faction stripes remain at x~1.25, so still visible.
        for wheel in range(7):
            _road_wheel(hull,side,wheel,0.29,-1.13+float(wheel)*0.377)
        _tracks(hull,side)
        # No repeated polygonal wheels overlaid atop the new cylinders.
        for index in range(7):
            for mask in ["Rodillo%s_%02d","BujeOscuro%s_%02d"]:
                var old: Node3D = model.find_child(mask % [side,index],true,false) as Node3D
                if old != null:
                    old.visible = false
        for i in range(15):
            for prefix in ["EslabonTreadSuperior","EslabonTreadInferior"]:
                var link: Node3D = model.find_child(
                    "%s%s_%02d" % [prefix,side,i],true,false) as Node3D
                if link != null:
                    link.visible = false
        var antenna: Node3D = model.find_child("AntenaTorre%s" % side,true,false) as Node3D
        if antenna != null:
            antenna.visible = false

    # Low faceted turret whose silhouette is produced by the *actual hull*
    # rather than a rectangular core covered by isolated cubes.
    var turret_profile := [
        Vector2(-0.23,-1.23),Vector2(0.23,-1.23),
        Vector2(0.58,-1.11),Vector2(0.85,-0.79),
        Vector2(0.915,-0.24),Vector2(0.91,0.69),
        Vector2(0.72,1.12),Vector2(-0.72,1.12),
        Vector2(-0.91,0.69),Vector2(-0.915,-0.24),
        Vector2(-0.85,-0.79),Vector2(-0.58,-1.11)
    ]
    var turret_levels := [
        [0.08,0.88,0.01],[0.16,1.0,0.03],[0.40,1.0,0.04],
        [0.605,0.92,0.045],[0.665,0.88,0.050]
    ]
    _loft(turret,"TorreBajaSoldadaV7",turret_profile,turret_levels)
    # These long, flush seams follow the actual multi-level turret geometry.
    # They articulate together with the turret and provide real close-up
    # manufactured hard-surface detail without scattered floating cuboids.
    for side in [-1,1]:
        var sign: float = float(side)
        _rod(turret,"SoldaduraLongitudinalTorreG09_%s" % side,
            Vector3(sign*0.67,0.640,-0.54),
            Vector3(sign*0.64,0.655,0.55),0.012,SEAM)
        _bevel(turret,"CubiertaCompuestaFrontalG09_%s" % side,
            Vector3(sign*0.314,0.459,-0.990),
            Vector3(0.338,0.160,0.330),0.066,CERAMIC,
            Vector3(-17.0,sign*14.0,-sign*4.0))
    # Integrated armor cheek extensions follow sloped shell; each bevel has
    # chamfered corners and consistent material with the central body.
    for side in [-1,1]:
        var sign: float = float(side)
        _bevel(turret,"ModuloBlindajeCeramicoV7_%s" % side,
            Vector3(sign*0.55,0.355,-0.78),
            Vector3(0.46,0.26,0.53),0.092,CERAMIC,
            Vector3(-14.0,sign*20.0,-sign*3.0))
        _rod(turret,"UnionCompuestoV7_%s" % side,
            Vector3(sign*0.79,0.54,-0.55),
            Vector3(sign*0.85,0.49,0.21),0.014,SEAM)
        # Protected low profile optics use small authentic smoke-tinted glass.
        var optic_z: float = -0.39 if side < 0 else -0.46
        _bevel(turret,"ModuloVisionIntegradoV7_%s" % side,
            Vector3(sign*0.47,0.70,optic_z),
            Vector3(0.215,0.132,0.215),0.043,METAL)
        _dark_box(turret,"CristalVisionIntegradoV7_%s" % side,
            Vector3(sign*0.47,0.703,optic_z-0.119),
            Vector3(0.155,0.078,0.014),GLASS)
    # Integrated smoke dischargers are mounted on armored side cheeks,
    # pointing outward/forward. Replace the six random-looking bare barrels.
    for side in [-1,1]:
        var sign: float = float(side)
        _bevel(turret,"BancadaFumigenasV7_%s" % side,
            Vector3(sign*0.805,0.44,0.12),
            Vector3(0.15,0.18,0.43),0.035,METAL,
            Vector3(0,sign*8.0,0))
        for n in range(3):
            _rod(turret,"LanzadorFumigenoRealV7_%s_%d" % [side,n],
                Vector3(sign*0.88,0.46,-0.04+float(n)*0.145),
                Vector3(sign*1.08,0.58,-0.20+float(n)*0.145),
                0.044,SEAM)
    # Fine welds around the hatch and upper armor: these follow the real
    # tapered roof and remain visible in close-up without looking blocky.
    for side in [-1,1]:
        var sign: float = float(side)
        _rod(turret,"UnionSoldaduraTechoV7_%s" % side,
            Vector3(sign*0.49,0.672,-0.53),
            Vector3(sign*0.53,0.666,0.56),0.010,SEAM)
        _rod(turret,"CordoncilloParapetoV7_%s" % side,
            Vector3(sign*0.57,0.582,-0.93),
            Vector3(sign*0.73,0.586,-0.44),0.010,WEAR)
    # Crew hatch circles are capped and angled to sit flush with roof.
    for hatch in range(2):
        var sign: float = -1.0 if hatch == 0 else 1.0
        var disk := MeshInstance3D.new()
        disk.name = "EscotillaCircularV7_%02d" % hatch
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.255 if hatch == 0 else 0.19
        cylinder.bottom_radius = 0.255 if hatch == 0 else 0.19
        cylinder.height = 0.040
        cylinder.radial_segments = 32
        disk.mesh = cylinder
        disk.material_override = _army_material(METAL)
        disk.position = Vector3(sign*0.40,0.687,0.25)
        turret.add_child(disk)
        _rod(turret,"CierreEscotillaV7_%02d" % hatch,
            Vector3(sign*0.40-0.10,0.72,0.29),
            Vector3(sign*0.40+0.10,0.72,0.29),0.014,SEAM)
    # Replace the square toy roof station with a low armored remote
    # weapon module. Keep its original machine-gun barrel (for animations).
    var remote: Node3D = model.find_child("ArmaSecundariaEstabilizada",true,false) as Node3D
    if remote != null:
        for label in ["ReceptorAmetralladora","MunicionAmetralladora","CamaraArma"]:
            var original: Node3D = remote.find_child(label,true,false) as Node3D
            if original != null:
                original.visible = false
        _bevel(remote,"EstacionRemotaBlindadaV7",
            Vector3(0,0.115,-0.08),Vector3(0.28,0.145,0.33),
            0.056,METAL)
        _dark_box(remote,"LenteArmaEstabilizadaV7",
            Vector3(-0.092,0.14,-0.258),Vector3(0.071,0.059,0.018),GLASS)
        _rod(remote,"UnionArmaEstabilizadaV7",
            Vector3(0.0,0.232,-0.11),Vector3(0.0,0.245,0.03),0.014,SEAM)
    # Flexible dark radio whips without bright toy-gold antenna tips.
    for side in [-1,1]:
        var sign: float = float(side)
        _rod(turret,"AntenaFlexibleG09V7_%s" % side,
            Vector3(sign*0.59,0.64,0.72),
            Vector3(sign*0.615,1.22,0.77),0.009,SEAM)
        _bevel(turret,"BaseAntenaG09V7_%s" % side,
            Vector3(sign*0.59,0.646,0.72),Vector3(0.095,0.070,0.095),
            0.022,METAL)
    # Low-profile panoramic command sensor; optical glass is actually
    # recessed and has a dark gasket, not a glowing white cube.
    _bevel(turret,"CabezalPanoramicoG09V7",
        Vector3(0.42,0.742,-0.43),Vector3(0.225,0.13,0.212),
        0.052,METAL)
    _dark_box(turret,"CristalCabezalPanoramicoG09V7",
        Vector3(0.42,0.741,-0.553),Vector3(0.148,0.067,0.013),GLASS)
    # Angular engine-independent bustle has proper rear slope and a rigid
    # steel frame, but no exposed toy bars or loose floating ammunition.
    _bevel(turret,"EstibaBlindadaTraseraV7",
        Vector3(0,0.37,0.99),Vector3(1.38,0.31,0.31),
        0.083,ARMOR,Vector3(0,0,0))
    _rod(turret,"SoldaduraEstibaV7",
        Vector3(-0.60,0.543,0.87),Vector3(0.60,0.543,0.87),0.016,SEAM)

    # Crucial: single integrated cannon bearing follows the *existing*
    # pivot. Recoil, elevation and muzzle smoke continue to work unchanged.
    _bevel(gun,"MantleteConjuntoV7",
        Vector3(0,0,-0.305),Vector3(0.70,0.41,0.37),
        0.132,ARMOR)
    _bevel(gun,"CollarBlindajeCanonV7",
        Vector3(0,0,-0.493),Vector3(0.385,0.345,0.095),
        0.078,METAL)
    for ring in range(3):
        var z: float = -0.75-float(ring)*0.48
        var collar := MeshInstance3D.new()
        collar.name = "AnilloAceroCanonV7_%d" % ring
        var tube := TorusMesh.new()
        tube.inner_radius = 0.115
        tube.outer_radius = 0.136
        tube.rings = 8
        tube.ring_segments = 20
        collar.mesh = tube
        collar.material_override = _army_material(METAL,false)
        collar.position = Vector3(0,0,z)
        collar.rotation_degrees.x = 90.0
        gun.add_child(collar)
    model.set_meta("tarvoka_mbt_hero_v7",true)
    model.set_meta("tarvoka_mbt_premium_finish_v8",true)
    return true
