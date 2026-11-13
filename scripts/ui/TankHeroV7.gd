extends RefCounted
class_name TarvokaTankHeroV7

# G09: actual full-resolution geometric hero pass, NOT a bolted-on cube layer.
# Continuous sealed multi-ring hull/turret, shaped front armor, suspended tread
# loops, 24 round steel road wheels and integrated low-height optics. The 14
# original faction paintable panels and battle rig stay completely independent.
# Use one coherent matte material family across every new armored surface.
const ROOT := "G09HERO7"
const Finish = preload("res://scripts/ui/TankFinish3D.gd")
const ARMOR := Color("#69776A")
const CERAMIC := Color("#77847A")
const METAL := Color("#424F50")
const RUBBER := Color("#202C30")
const GLASS := Color("#214857")
const WEAR := Color("#818982")
const SEAM := Color("#2A383B")
const DIRT := Color("#656459")
const TRACK_COUNT := 156

static var _paint_map: ImageTexture
static var _metal_map: ImageTexture

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
    if _paint_map != null:
        return _paint_map
    const SIDE := 256
    var img := Image.create(SIDE,SIDE,false,Image.FORMAT_RGBA8)
    # Commercial-safe original paint masks, no photography or purchased art.
    # Large camouflage islands, sprayed transitions, dust and hairline chips.
    for y in range(SIDE):
        for x in range(SIDE):
            var broad: float = _smooth_hash(float(x),float(y),78.0)
            var medium: float = _smooth_hash(float(x),float(y),27.0)
            var detail: float = _smooth_hash(float(x),float(y),6.0)
            var grit: float = _hash(x,y)
            var pattern: float = broad*0.56+medium*0.44
            var base: Color = Color("#667265")
            if pattern < 0.425:
                base = Color("#535E56")
            elif pattern > 0.61:
                base = Color("#7B806F")
            else:
                base = Color("#657164")
            var smoothed: float = clampf((pattern-0.40)/0.27,0.0,1.0)
            var darkened: float = 0.91+0.16*smoothed+0.09*(detail-0.5)
            var dusty: float = maxf(0.0,1.0-float(y)/float(SIDE))*0.062
            var color: Color = base*darkened
            color = color.lerp(Color("#A3997F"),dusty)
            if grit > 0.989 and detail < 0.40:
                color = color.lerp(Color("#ACABA0"),0.44)
            img.set_pixel(x,y,Color(color.r,color.g,color.b,1.0))
    _paint_map = ImageTexture.create_from_image(img)
    return _paint_map

static func _army_material(color: Color = ARMOR,
        embedded_paint: bool = true) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color.WHITE if embedded_paint else color
    m.albedo_texture = _army_texture() if embedded_paint else null
    m.uv1_scale = Vector3.ONE
    m.roughness = 0.83 if embedded_paint else 0.68
    m.metallic = 0.13 if embedded_paint else 0.39
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
    obj.material_override = _army_material(tint)
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
            "VisorComandante_0","VisorComandante_1","VisorComandante_2",
            "VisorComandante_3","VisorComandante_4","VisorComandante_5",
            "AntenaTorre1","AntenaTorre-1"]:
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
    var link_mesh := BoxMesh.new()
    link_mesh.size = Vector3(0.125,0.065,0.102)
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
        mat.albedo_color = Color.WHITE
        mat.albedo_texture = _army_texture()
        mat.roughness = 0.83
        mat.metallic = 0.15
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
        [0.08,0.86,0.01],[0.16,1.0,0.04],[0.39,1.0,0.05],
        [0.58,0.90,0.07],[0.675,0.77,0.09]
    ]
    _loft(turret,"TorreBajaSoldadaV7",turret_profile,turret_levels)
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
    return true
