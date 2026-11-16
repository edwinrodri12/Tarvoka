extends RefCounted
class_name TarvokaHeadquartersFinish3D

# Visual-only V2 applied to the approved 2026-11-12 headquarters concept.
# All meshes belong to Godot: no prerendered sprite, gameplay or imported IP.
# Three procedural surface families are cached once for WebGL/mobile.
const STONE := Color("#b3b9b5")
const STEEL := Color("#667987")
const PALE := Color("#d2d7d5")
const ROOF := Color("#344755")
const METAL := Color("#25343d")
const WINDOW := Color("#274e64")
const SAND := Color("#b8a67e")
const WARNING := Color("#e1b343")
const CHAR := Color("#242a2a")
static var _materials: Dictionary = {}
static var _textures: Dictionary = {}
static var _surface_count: int = 0

static func _texture(style: String) -> ImageTexture:
    if _textures.has(style):
        return _textures[style]
    var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var hash: int = posmod(x*73+y*127+(x*y)*11+(x*x+y*y)*19,251)
            var rough: float = float(hash)/251.0
            var value: float = 0.91 + rough*0.085
            if style == "concrete":
                value = 0.79 + rough*0.18
                if x % 64 < 2 or y % 48 < 2:
                    value *= 0.79
                if posmod(x*19+y*7,117) < 2:
                    value *= 0.86
            elif style == "steel":
                value = 0.83 + rough*0.11
                if x % 32 == 0 or y % 64 == 0:
                    value *= 0.72
            elif style == "roof":
                value = 0.78 + rough*0.12
                if x % 12 == 0:
                    value *= 0.81
            elif style == "glass":
                value = 0.80 + 0.17*float((x+y*2)%128)/128.0
                if x % 16 == 0:
                    value *= 0.91
            image.set_pixel(x,y,Color(value,value,value,1.0))
    var texture := ImageTexture.create_from_image(image)
    _textures[style] = texture
    return texture

static func _height_sample(style: String,x: int,y: int) -> float:
    var noise: float = float(posmod(x*73+y*127+x*y*11+x*x*19+y*y*23,251))/251.0
    var height: float = (noise-0.5)*0.14
    if style == "concrete":
        height *= 0.85
        if posmod(x,64) <= 1 or posmod(y,48) <= 1:
            height -= 0.24
        if posmod(x*19+y*7,113) <= 1:
            height -= 0.07
    elif style == "steel":
        height *= 0.52
        if posmod(x,32) == 0:
            height -= 0.11
    elif style == "roof":
        height *= 0.40
        if posmod(x,12) == 0:
            height -= 0.12
    else:
        height *= 0.18
    return height

static func _normal_texture(style: String) -> ImageTexture:
    var key: String = style+"_normal"
    if _textures.has(key):
        return _textures[key]
    var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var dx: float = _height_sample(style,x+1,y)-_height_sample(style,x-1,y)
            var dy: float = _height_sample(style,x,y+1)-_height_sample(style,x,y-1)
            var n: Vector3 = Vector3(-dx*1.6,-dy*1.6,1.0).normalized()
            image.set_pixel(x,y,Color(n.x*0.5+0.5,n.y*0.5+0.5,n.z*0.5+0.5,1.0))
    var texture := ImageTexture.create_from_image(image)
    _textures[key] = texture
    return texture

static func _roughness_texture(style: String) -> ImageTexture:
    var key: String = style+"_roughness"
    if _textures.has(key):
        return _textures[key]
    var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var n: float = float(posmod(x*41+y*71+x*y*3,197))/197.0
            var value: float = 0.66+n*0.27
            if style == "glass":
                value = 0.63+n*0.16
            elif style == "roof":
                value = 0.71+n*0.22
            image.set_pixel(x,y,Color(value,value,value,1.0))
    var texture := ImageTexture.create_from_image(image)
    _textures[key] = texture
    return texture

static func _mat(color: Color, style: String = "steel") -> StandardMaterial3D:
    var key: String = color.to_html(true)+"_"+style
    if _materials.has(key):
        return _materials[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.albedo_texture = _texture(style)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    material.metallic = 0.58 if style == "steel" or style == "roof" else 0.08
    material.roughness = 0.52 if style == "steel" else (0.31 if style == "glass" else 0.81)
    material.roughness_texture = _roughness_texture(style)
    if style != "glass":
        material.normal_enabled = true
        material.normal_scale = 0.42 if style == "concrete" else 0.29
        material.normal_texture = _normal_texture(style)
    _materials[key] = material
    return material

static func _group(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
    var n := Node3D.new()
    n.name = label
    n.position = at
    parent.add_child(n)
    return n

static func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3,
        color: Color, style: String = "steel", paint: bool = false,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var box := BoxMesh.new()
    box.size = size
    item.mesh = box
    item.position = pos
    item.rotation_degrees = rotation
    item.material_override = _mat(color,style)
    if paint:
        item.set_meta("tarvoka_faction_panel",true)
    parent.add_child(item)
    _surface_count += 1
    return item

static func _beam(parent: Node3D, label: String, a: Vector3, b: Vector3,
        radius: float, tint: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := CylinderMesh.new()
    mesh.height = a.distance_to(b)
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.radial_segments = 8
    item.mesh = mesh
    item.position = (a+b)*0.5
    if a.distance_to(b) > 0.0001:
        item.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
    item.material_override = _mat(tint,"steel")
    parent.add_child(item)
    _surface_count += 1
    return item

static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    for point in [a,b,c]:
        tool.set_uv(Vector2(point.x*0.28+0.5,point.z*0.28+0.5))
        tool.add_vertex(point)

static func _tri_uv(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
        ua: Vector2, ub: Vector2, uc: Vector2) -> void:
    tool.set_uv(ua)
    tool.add_vertex(a)
    tool.set_uv(ub)
    tool.add_vertex(b)
    tool.set_uv(uc)
    tool.add_vertex(c)

static func _chamfer(parent: Node3D, name: String, at: Vector3,
        dims: Vector3, cut: float, color: Color,
        style: String = "concrete", paint: bool = false) -> MeshInstance3D:
    # Solid eight-sided architectural prism; proper triangles and normals.
    var cx: float = dims.x*0.5
    var cy: float = dims.y*0.5
    var cz: float = dims.z*0.5
    var k: float = minf(cut,minf(cx,cz)*0.45)
    var points: Array[Vector2] = [
        Vector2(-cx+k,-cz), Vector2(cx-k,-cz),
        Vector2(cx,-cz+k), Vector2(cx,cz-k),
        Vector2(cx-k,cz),Vector2(-cx+k,cz),
        Vector2(-cx,cz-k),Vector2(-cx,-cz+k)]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(8):
        var j: int = (i+1)%8
        var a: Vector3 = Vector3(points[i].x,-cy,points[i].y)
        var b: Vector3 = Vector3(points[j].x,-cy,points[j].y)
        var ta: Vector3 = Vector3(a.x,cy,a.z)
        var tb: Vector3 = Vector3(b.x,cy,b.z)
        _tri(st,ta,Vector3(0,cy,0),tb)
        _tri(st,a,b,Vector3(0,-cy,0))
        var distance: float = a.distance_to(b)*0.43
        var elevation: float = dims.y*0.43
        # Previously the vertical walls sampled only X/Z, making the
        # textured facades appear almost uniformly flat. Real side UVs.
        _tri_uv(st,a,ta,b,Vector2(0,0),
            Vector2(0,elevation),Vector2(distance,0))
        _tri_uv(st,b,ta,tb,Vector2(distance,0),
            Vector2(0,elevation),Vector2(distance,elevation))
    st.generate_normals()
    st.generate_tangents()
    var item := MeshInstance3D.new()
    item.name = name
    item.mesh = st.commit()
    item.material_override = _mat(color,style)
    item.position = at
    if paint:
        item.set_meta("tarvoka_faction_panel",true)
    parent.add_child(item)
    _surface_count += 1
    return item

static func _hide(root: Node3D, label: String) -> void:
    var old: Node = root.find_child(label,true,false)
    if old is Node3D:
        (old as Node3D).visible = false

static func _decorative_cantilevers(parent: Node3D, roof_y: float, tint: Color) -> void:
    var front: float = -2.47
    for side in [-1,1]:
        var s: float = float(side)
        _chamfer(parent,"ContrafuerteBlindado_%s" % side,
            Vector3(s*2.64,roof_y*0.52,-2.43),
            Vector3(0.57,roof_y-0.23,0.38),0.09,STEEL)
        for i in range(3):
            var y: float = 0.80+float(i)*(roof_y-1.13)/2.0
            _box(parent,"TapaJunta_%s_%d" % [side,i],
                Vector3(s*2.65,y,-2.67),
                Vector3(0.52,0.037,0.038),METAL)
        _beam(parent,"RiostraPortico_%s" % side,
            Vector3(s*1.71,2.22,-3.63),Vector3(s*2.45,3.00,-2.77),
            0.075,STEEL)
        _box(parent,"AletaColor_%s" % side,
            Vector3(s*2.67,roof_y*0.60,front-0.26),
            Vector3(0.13,0.96,0.06),tint,"steel",true)
    # Large entry reads as a recessed military gateway, not a solid facade.
    _chamfer(parent,"ViseraDeMandoBiselada",Vector3(0,2.42,-3.18),
        Vector3(3.76,0.28,1.98),0.24,ROOF,"roof")
    for i in range(7):
        var x: float = -1.30+float(i)*0.43
        _box(parent,"CostillasVisera_%d" % i,Vector3(x,2.28,-4.09),
            Vector3(0.055,0.15,0.19),STEEL)
    _box(parent,"PortalCristalBlindado",Vector3(0,0.98,-3.80),
        Vector3(1.58,1.82,0.07),WINDOW,"glass")
    for side in [-1,1]:
        _box(parent,"MarcoSeguridadPortal_%s" % side,
            Vector3(float(side)*0.83,1.08,-3.84),
            Vector3(0.12,1.96,0.11),PALE,"steel")
    _box(parent,"UmbralPortal",Vector3(0,0.20,-3.87),
        Vector3(2.05,0.12,0.50),STEEL,"steel")
    _box(parent,"AristaFranjaEntrada",Vector3(0,2.43,-4.13),
        Vector3(3.15,0.095,0.10),tint,"steel",true)

static func _facade_windows(parent: Node3D, level: int, roof_y: float) -> void:
    for floor_id in range(level):
        var y: float = minf(roof_y-0.64,1.26+float(floor_id)*1.09)
        for bay in range(4):
            var x: float = [-2.18,-1.32,1.32,2.18][bay]
            _box(parent,"RecesoVentana_%d_%d" % [floor_id,bay],
                Vector3(x,y,-2.47),Vector3(0.68,0.73,0.040),METAL)
            _box(parent,"TramaCristal_%d_%d" % [floor_id,bay],
                Vector3(x,y,-2.497),Vector3(0.53,0.54,0.038),WINDOW,"glass")
            _box(parent,"VoladizoVentana_%d_%d" % [floor_id,bay],
                Vector3(x,y+0.41,-2.54),Vector3(0.78,0.06,0.22),STEEL)
            _box(parent,"Alfeizar_%d_%d" % [floor_id,bay],
                Vector3(x,y-0.37,-2.55),Vector3(0.81,0.08,0.21),STONE,"concrete")
            _box(parent,"DivisionVidrio_%d_%d" % [floor_id,bay],
                Vector3(x,y,-2.54),Vector3(0.037,0.55,0.03),PALE)
    for s in [-1,1]:
        var x: float = float(s)*4.06
        _chamfer(parent,"TejadoAlaBiselado_%s" % s,
            Vector3(x,2.32,0.35),Vector3(2.65,0.24,4.50),
            0.27,ROOF,"roof")
        for i in range(3):
            var px: float = x-0.78+float(i)*0.78
            _box(parent,"MarcoAla_%s_%d" % [s,i],
                Vector3(px,1.35,-1.86),Vector3(0.52,0.66,0.09),METAL)
            _box(parent,"VidrioAla_%s_%d" % [s,i],
                Vector3(px,1.35,-1.91),Vector3(0.40,0.51,0.04),WINDOW,"glass")
            _box(parent,"LaminaSuperiorAla_%s_%d" % [s,i],
                Vector3(px,1.72,-1.91),Vector3(0.61,0.048,0.18),STEEL)

static func _radar_dish(parent: Node3D, roof_y: float, level: int,
        tint: Color) -> void:
    # Concave dish made of actual curved triangles with a clear silhouette.
    var anchor := _group(parent,"RadarPremium3D",Vector3(-1.66,roof_y+1.06,0.62))
    anchor.rotation_degrees = Vector3(-56,13,0)
    var radius: float = 0.75 if level < 3 else 1.00
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(4):
        var r0: float = radius*float(ring)/4.0
        var r1: float = radius*float(ring+1)/4.0
        for i in range(24):
            var a: float = TAU*float(i)/24.0
            var b: float = TAU*float(i+1)/24.0
            var p0 := Vector3(cos(a)*r0,-0.24*(1.0-pow(r0/radius,2.0)),sin(a)*r0)
            var p1 := Vector3(cos(a)*r1,-0.24*(1.0-pow(r1/radius,2.0)),sin(a)*r1)
            var q0 := Vector3(cos(b)*r0,-0.24*(1.0-pow(r0/radius,2.0)),sin(b)*r0)
            var q1 := Vector3(cos(b)*r1,-0.24*(1.0-pow(r1/radius,2.0)),sin(b)*r1)
            # Dish normals must face the feed horn, not the underside.
            _tri(st,p0,q1,p1)
            _tri(st,p0,q0,q1)
    st.generate_normals()
    st.generate_tangents()
    var bowl := MeshInstance3D.new()
    bowl.name = "PlatoParabolicoConcavo"
    bowl.mesh = st.commit()
    bowl.material_override = _mat(PALE,"steel")
    anchor.add_child(bowl)
    _surface_count += 1
    for i in range(24):
        var a: float = TAU*float(i)/24.0
        var b: float = TAU*float(i+1)/24.0
        _beam(anchor,"AroPerimetral_%02d" % i,
            Vector3(cos(a)*radius,0,sin(a)*radius),
            Vector3(cos(b)*radius,0,sin(b)*radius),0.026,tint)
    for i in range(4):
        var angle: float = TAU*float(i)/4.0
        _beam(anchor,"ArmazonParabolica_%d" % i,
            Vector3(0,-0.30,0),
            Vector3(cos(angle)*radius,0,sin(angle)*radius),0.024,STEEL)
    _beam(anchor,"AlimentadorPrincipal",Vector3(0,-0.25,0),
        Vector3(0,0.42,0),0.043,METAL)
    _box(anchor,"CabezalSensor",Vector3(0,0.44,0),
        Vector3(0.17,0.12,0.13),WINDOW,"glass")

static func _roof_details(parent: Node3D, level: int,
        y: float, color: Color) -> void:
    _chamfer(parent,"CubiertaPrincipalBiselada",Vector3(0,y+0.12,0.25),
        Vector3(6.19,0.28,5.47),0.34,ROOF,"roof")
    for s in [-1,1]:
        var sign: float = float(s)
        _box(parent,"CanaletaLateral_%s" % s,
            Vector3(sign*2.92,y+0.12,0.24),
            Vector3(0.07,0.11,5.16),STEEL)
        for i in range(3):
            _box(parent,"RielRoof_%s_%d" % [s,i],
                Vector3(sign*(0.62+float(i)*0.59),y+0.29,0.40),
                Vector3(0.052,0.035,3.54),PALE,"steel")
    for i in range(6):
        var x: float = -2.12+float(i)*0.83
        _box(parent,"LamaClimatizacion_%d" % i,
            Vector3(x,y+0.43,2.02),Vector3(0.54,0.31,0.15),STEEL)
    for side in [-1,1]:
        var sign: float = float(side)
        _beam(parent,"BajadaPluvial_%s" % side,
            Vector3(sign*3.03,y+0.08,2.64),Vector3(sign*3.03,0.30,2.64),
            0.055,STEEL)
    _radar_dish(parent,y,level,color)
    if level >= 2:
        _box(parent,"PuenteTecnico",Vector3(1.59,y+0.19,-0.72),
            Vector3(1.33,0.16,0.55),STEEL)
        for i in range(5):
            var z: float = -1.16+float(i)*0.24
            _box(parent,"VentanalTorre_%d" % i,
                Vector3(1.56,y+1.27,z),Vector3(0.81,0.31,0.065),
                WINDOW,"glass")
    if level == 3:
        # Radome is no longer a lone sphere: reinforced base, panels and ribs.
        _chamfer(parent,"SoporteRadomoOctogonal",
            Vector3(0.16,y+1.12,0.34),
            Vector3(1.67,0.43,1.65),0.22,STEEL)
        for i in range(8):
            var angle: float = TAU*float(i)/8.0
            _beam(parent,"RefuerzoRadomo_%d" % i,
                Vector3(0.16+0.67*cos(angle),y+1.23,
                    0.34+0.67*sin(angle)),
                Vector3(0.16+0.34*cos(angle),y+2.46,
                    0.34+0.34*sin(angle)),0.038,PALE)

static func _helipad_detail(parent: Node3D, tint: Color,
        level: int) -> void:
    var old: Node = parent.find_child("Helipuerto",true,false)
    if not (old is Node3D):
        return
    var pad: Node3D = old as Node3D
    _chamfer(pad,"PistaBiseladaDeDespegue",Vector3(0,2.26,0),
        Vector3(3.22,0.20,3.11),0.35,ROOF,"roof")
    # One row of low safety rails, with the front left clear to read the H.
    for side in [-1,1]:
        for k in range(3):
            var z: float = -0.90+float(k)*0.90
            var x: float = float(side)*1.47
            _beam(pad,"BarandalHelipuerto_%s_%d" % [side,k],
                Vector3(x,2.42,z),Vector3(x,2.80,z),0.025,PALE)
        _beam(pad,"GuardaHelipuerto_%s" % side,
            Vector3(float(side)*1.47,2.80,-1.03),
            Vector3(float(side)*1.47,2.80,1.03),0.033,tint)
    for i in range(7):
        var x: float = -1.02+float(i)*0.34
        _box(pad,"Antideslizante_%02d" % i,
            Vector3(x,2.374,-1.10),Vector3(0.13,0.01,0.25),
            WARNING if i%2==0 else METAL,"roof")
    _box(pad,"AccesoEscalera",Vector3(1.57,1.33,1.33),
        Vector3(0.20,1.94,0.15),STEEL)
    for i in range(7):
        var y: float = 0.56+float(i)*0.24
        _box(pad,"Peldaño_%d" % i,
            Vector3(1.57,y,1.33),Vector3(0.42,0.05,0.14),PALE)
    if level >= 3:
        _beam(pad,"RiostraPadNivel3",
            Vector3(-1.53,1.28,0.72),
            Vector3(-0.69,2.16,0.73),0.090,STEEL)

static func _site_detail(parent: Node3D, level: int, tint: Color) -> void:
    for s in [-1,1]:
        var sign: float = float(s)
        for i in range(5):
            var z: float = -3.66+float(i)*1.15
            _box(parent,"TopeEstacionamiento_%s_%d" % [s,i],
                Vector3(sign*5.31,0.10,z),
                Vector3(0.22,0.09,0.73),PALE,"concrete")
        _beam(parent,"CableSensorPerimetral_%s" % s,
            Vector3(sign*6.35,0.85,-5.18),
            Vector3(sign*6.35,0.85,5.29),0.018,METAL)
        # Low service boxes make the compound feel operated and inhabited.
        _chamfer(parent,"GrupoElectrico_%s" % s,
            Vector3(sign*4.84,0.32,4.92),
            Vector3(0.75,0.64,1.04),0.11,STEEL)
        _box(parent,"PictogramaGrupo_%s" % s,
            Vector3(sign*4.84,0.37,4.37),
            Vector3(0.25,0.21,0.03),tint,"steel",true)
    for i in range(3):
        var x: float = -1.06+float(i)*1.12
        _box(parent,"GuiaEntrada_%d" % i,
            Vector3(x,0.101,-5.40),
            Vector3(0.075,0.02,0.62),WARNING,"roof")
    if level >= 2:
        for i in range(4):
            _chamfer(parent,"NodoSatelital_%d" % i,
                Vector3(4.62,0.18+float(i%2)*0.17,1.70+float(int(i/2))*0.83),
                Vector3(0.46,0.29,0.61),0.06,STEEL)

static func _damage_detail(parent: Node3D, level: int) -> void:
    var y: float = 2.87+float(level-1)*0.91
    var damage := _group(parent,"DesgasteEstructuralPremium")
    for i in range(6):
        var x: float = -2.44+float(i)*0.24
        _beam(damage,"GrietaFachada_%d" % i,
            Vector3(x,1.31+float(i%2)*0.13,-2.75),
            Vector3(x+0.20,1.04+float(i%3)*0.11,-2.77),0.020,CHAR)
    _box(damage,"MarcoVentanillaTorcido",Vector3(1.33,1.41,-2.64),
        Vector3(0.77,0.06,0.08),CHAR,"roof",false,Vector3(0,0,19))
    _beam(damage,"AntenaColapsada",
        Vector3(2.32,y+0.06,1.60),
        Vector3(3.32,y+0.41,1.90),0.048,CHAR)
    _chamfer(damage,"FragmentoTecho",Vector3(-2.84,0.33,-4.71),
        Vector3(0.93,0.37,0.66),0.16,STONE)
    _box(damage,"HollinEntrada",Vector3(-0.14,2.14,-4.17),
        Vector3(1.07,0.29,0.032),CHAR)
    var pad: Node = parent.find_child("Helipuerto",true,false)
    if pad is Node3D:
        _beam(pad as Node3D,"PasamanosCaido",
            Vector3(1.56,2.38,0.90),
            Vector3(1.94,1.59,1.30),0.034,CHAR)

static func _ruins_detail(parent: Node3D, tint: Color) -> void:
    var wreck := _group(parent,"RuinasDeMandoPremium")
    for i in range(8):
        var x: float = -2.68+float(i%4)*1.70
        var z: float = -1.71+float(int(i/4))*3.22
        _beam(wreck,"VigaRetorcida_%02d" % i,
            Vector3(x,0.28,z),
            Vector3(x+0.54,0.50+float(i%3)*0.33,z+0.60),
            0.077,CHAR)
    for i in range(14):
        var x: float = -2.83+float(i%7)*0.94
        var z: float = -4.03+float(int(i/7))*6.40
        _chamfer(wreck,"PlacaRota_%02d" % i,
            Vector3(x,0.36+float(i%4)*0.06,z),
            Vector3(0.61,0.18,0.42),0.15,
            STONE.darkened(0.20) if i%3!=0 else CHAR)
    _box(wreck,"EscudoFaccionCaido",Vector3(2.04,0.29,-3.32),
        Vector3(0.57,0.10,0.83),tint.darkened(0.41),"steel",true,
        Vector3(12,22,17))
    _chamfer(wreck,"RadomoDerrumbado",Vector3(-1.45,0.46,1.81),
        Vector3(1.32,0.65,1.21),0.18,PALE)
    _beam(wreck,"MastilPartido",Vector3(-1.18,0.23,2.30),
        Vector3(-2.42,0.68,3.10),0.07,CHAR)

static func apply(model: Node3D, level: int, tint: Color,
        condition: String) -> void:
    if model == null:
        return
    model.set_meta("tarvoka_hq_visual_v2",true)
    _surface_count = 0
    if condition == "destruido":
        _ruins_detail(model,tint)
        model.set_meta("tarvoka_hq_v2_extra_meshes",_surface_count)
        return
    # The original volumes remain in the tree for backwards-compatible
    # damage/faction selectors; only redundant visual slabs are hidden.
    for label in ["BloqueDeMando","CoronamientoDeTecho",
            "PorticoAcceso","TechoDelPortico","PlataformaHelipuerto",
            "PlatoExterior"]:
        _hide(model,label)
    var structure: Node3D = model.find_child("EstructuraPrincipal",true,false) as Node3D
    if structure == null:
        return
    var roof_y: float = 2.87+float(level-1)*0.91
    _chamfer(structure,"MandoBiseladoPrincipal",
        Vector3(0,roof_y*0.5,0.25),
        Vector3(5.82,roof_y,5.12),0.32,STONE)
    _roof_details(structure,level,roof_y,tint)
    _decorative_cantilevers(structure,roof_y,tint)
    _facade_windows(structure,level,roof_y)
    _helipad_detail(model,tint,level)
    _site_detail(model,level,tint)
    if condition == "danado":
        _damage_detail(model,level)
    model.set_meta("tarvoka_hq_v2_extra_meshes",_surface_count)
