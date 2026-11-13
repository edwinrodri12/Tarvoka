extends RefCounted
class_name TarvokaHeadquartersHero4

# TARVOKA Cuartel General V4: shape, hierarchy, readable faction identity.
# Built in native Godot 4.3. Keeps V1–V3 untouched for fair comparisons.
# This module is strictly visual; it never changes tactical game state.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const ARMOR := Color("#536b7a")
const ARMOR_DARK := Color("#263c4b")
const WHITE := Color("#dce4e6")
const GLASS := Color("#1e435d")
const CONCRETE := Color("#abb7b7")
const RUST := Color("#796b56")
const GOLD := Color("#e9b54e")
const SOOT := Color("#272f35")
const PAVEMENT := Color("#475763")
static var _flag_materials: Dictionary = {}

static func _group(parent: Node3D, name: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
    return Finish._group(parent,name,pos)

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, tint: Color, style: String = "steel",
        painted: bool = false, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return Finish._box(parent,name,pos,size,tint,style,painted,rotation)

static func _shell(parent: Node3D, name: String, pos: Vector3,
        dims: Vector3, bevel: float, tint: Color,
        style: String = "concrete", paint: bool = false) -> MeshInstance3D:
    return Finish._chamfer(parent,name,pos,dims,bevel,tint,style,paint)

static func _beam(parent: Node3D, name: String, a: Vector3,
        b: Vector3, radius: float, color: Color) -> MeshInstance3D:
    return Finish._beam(parent,name,a,b,radius,color)

static func _flag_material(color: Color) -> StandardMaterial3D:
    var id: String = color.to_html()
    if _flag_materials.has(id):
        return _flag_materials[id]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.03
    mat.roughness = 0.88
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _flag_materials[id] = mat
    return mat

static func _badge_mesh(parent: Node3D, tint: Color, name: String,
        center: Vector3, width: float, height: float) -> MeshInstance3D:
    # Sculpted, deliberately unbranded shield mount. The officially approved
    # faction emblems can later attach here as textures/geometry.
    var profile: Array[Vector2] = [
        Vector2(-0.49,0.48), Vector2(0.49,0.48),
        Vector2(0.46,-0.18), Vector2(0.28,-0.46),
        Vector2(0,-0.67), Vector2(-0.28,-0.46),
        Vector2(-0.46,-0.18)]
    var surf := SurfaceTool.new()
    surf.begin(Mesh.PRIMITIVE_TRIANGLES)
    var forward: float = -0.07
    var back: float = 0.06
    var amount: int = profile.size()
    for i in range(amount):
        var next: int = (i+1)%amount
        var a: Vector2 = profile[i]
        var b: Vector2 = profile[next]
        var pf0 := Vector3(a.x,a.y,forward)
        var pf1 := Vector3(b.x,b.y,forward)
        var pb0 := Vector3(a.x,a.y,back)
        var pb1 := Vector3(b.x,b.y,back)
        for p in [Vector3(0,0,forward),pf0,pf1]:
            surf.set_uv(Vector2(p.x+0.5,p.y+0.7))
            surf.add_vertex(p)
        for p in [Vector3(0,0,back),pb1,pb0]:
            surf.set_uv(Vector2(p.x+0.5,p.y+0.7))
            surf.add_vertex(p)
        for p in [pf0,pb0,pf1,pf1,pb0,pb1]:
            surf.set_uv(Vector2(p.x+0.5,p.y+0.7))
            surf.add_vertex(p)
    surf.generate_normals()
    var item := MeshInstance3D.new()
    item.name = name
    item.mesh = surf.commit()
    item.material_override = Finish._mat(tint,"steel")
    item.position = center
    item.scale = Vector3(width,height,0.70)
    item.set_meta("tarvoka_faction_panel",true)
    item.set_meta("tarvoka_emblem_mount",true)
    parent.add_child(item)
    return item

static func _flag(parent: Node3D,tint: Color,
        origin: Vector3,level: int) -> void:
    var h: float = 3.15 + 0.40*float(level-1)
    var flag_root: Node3D = _group(parent,"BanderaPrincipalV4",origin)
    _beam(flag_root,"MastilBandera",Vector3.ZERO,Vector3(0,h,0),0.054,ARMOR_DARK)
    _beam(flag_root,"TraviesaBandera",Vector3(0,h-0.36,0),
        Vector3(0.98,h-0.36,0),0.023,WHITE)
    _box(flag_root,"RemateMastil",Vector3(0,h+0.04,0),
        Vector3(0.13,0.12,0.13),GOLD)
    var cloth := SurfaceTool.new()
    cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
    var columns: int = 7
    var rows: int = 4
    for y in range(rows):
        for x in range(columns):
            var x0: float = float(x)/float(columns)
            var x1: float = float(x+1)/float(columns)
            var y0: float = float(y)/float(rows)
            var y1: float = float(y+1)/float(rows)
            var p0 := Vector3(1.18*x0,h-0.16-0.94*y0,
                0.105*sin(x0*PI*1.6+y0*0.6)*x0)
            var p1 := Vector3(1.18*x1,h-0.16-0.94*y0,
                0.105*sin(x1*PI*1.6+y0*0.6)*x1)
            var p2 := Vector3(1.18*x1,h-0.16-0.94*y1,
                0.105*sin(x1*PI*1.6+y1*0.6)*x1)
            var p3 := Vector3(1.18*x0,h-0.16-0.94*y1,
                0.105*sin(x0*PI*1.6+y1*0.6)*x0)
            for p in [p0,p1,p2,p0,p2,p3]:
                cloth.set_uv(Vector2(p.x/1.18,(h-0.16-p.y)/0.94))
                cloth.add_vertex(p)
    cloth.generate_normals()
    var cloth_mesh := MeshInstance3D.new()
    cloth_mesh.name = "TelaBanderaOndulada"
    cloth_mesh.mesh = cloth.commit()
    cloth_mesh.material_override = _flag_material(tint)
    cloth_mesh.set_meta("tarvoka_faction_panel",true)
    flag_root.add_child(cloth_mesh)
    # Visible contrast stripe; does not imitate any approved emblem.
    _box(flag_root,"BordeTelaBlanco",
        Vector3(0.07,h-0.63,-0.025),
        Vector3(0.045,0.93,0.025),WHITE)

static func _command_tower(parent: Node3D, level: int,tint: Color) -> void:
    var y: float = 2.87+0.91*float(level-1)
    var tower: Node3D = _group(parent,"NucleoVerticalDeMandoV4")
    # Unlike earlier passes, this centerpiece is full sized and projects
    # above the old flat roof. First-person / map-scale recognizable.
    _shell(tower,"MasaCentralElevada",
        Vector3(0,y+0.64,-2.36),
        Vector3(3.25,1.62,1.64),0.36,ARMOR,"roof")
    _shell(tower,"CubiertaConEscalon",
        Vector3(0,y+1.56,-2.38),
        Vector3(3.70,0.28,1.99),0.32,ARMOR_DARK,"roof")
    _shell(tower,"PilarFrontalDeEmblema",
        Vector3(0,y+0.67,-3.24),
        Vector3(2.32,1.44,0.18),0.15,tint.darkened(0.23),
        "steel",true)
    _shell(tower,"BaseEmblemaMetalica",
        Vector3(0,y+0.68,-3.372),
        Vector3(1.63,1.31,0.20),0.18,ARMOR_DARK,"roof")
    _badge_mesh(tower,tint,"EscudoDeFaccionModular",
        Vector3(0,y+0.77,-3.50),0.96,1.17)
    # Readable non-faction-specific embossed chevron along shield's bottom.
    for side in [-1,1]:
        var s: float = float(side)
        _beam(tower,"InsigniaNeutralCincelada_%s" % side,
            Vector3(0,y+0.46,-3.591),
            Vector3(s*0.25,y+0.70,-3.591),0.032,WHITE)
    for side in [-1,1]:
        var s: float = float(side)
        _shell(tower,"ColumnaFaccionVertical_%s" % side,
            Vector3(s*1.43,y+0.68,-3.23),
            Vector3(0.19,1.48,0.24),0.035,tint.darkened(0.05),
            "steel",true)
        _box(tower,"AletaDorada_%s" % side,
            Vector3(s*1.74,y+1.50,-3.26),
            Vector3(0.12,0.12,0.24),GOLD)
        _box(tower,"CristalLateralTorre_%s" % side,
            Vector3(s*1.68,y+0.71,-2.37),
            Vector3(0.048,0.60,0.78),GLASS,"glass")
    _box(tower,"FranjaSuperiorMando",Vector3(0,y+1.60,-3.23),
        Vector3(2.85,0.11,0.060),GOLD,"steel")
    # Connect roof and central front podium with credible vertical buttresses.
    for side in [-1,1]:
        var s: float = float(side)
        _beam(tower,"RiostraFachadaAlta_%s" % side,
            Vector3(s*1.55,y+1.45,-3.21),
            Vector3(s*2.07,y-0.31,-3.12),0.087,WHITE)

static func _wing_cladding(parent: Node3D, level: int,tint: Color) -> void:
    var wing: Node3D = _group(parent,"BlindajeDeAlasV4")
    # The gray boxes in V3 become layered, restrained blue/naval cladding.
    for side in [-1,1]:
        var s: float = float(side)
        var x: float = s*4.06
        _shell(wing,"CoronaAlaTecnica_%s" % side,
            Vector3(x,2.49,0.37),
            Vector3(2.64,0.29,4.64),0.23,ARMOR,"roof")
        _shell(wing,"BandaDeFaccion_%s" % side,
            Vector3(x,2.43,-1.92),
            Vector3(2.26,0.18,0.14),0.03,tint.darkened(0.17),"steel",true)
        _box(wing,"MolduraDoradaAla_%s" % side,
            Vector3(x,2.29,-1.999),
            Vector3(2.15,0.064,0.063),GOLD)
        for i in range(3):
            var at_x: float = x-0.79+float(i)*0.78
            _box(wing,"VentanillaEnmarcada_%s_%d" % [side,i],
                Vector3(at_x,1.39,-1.985),
                Vector3(0.51,0.71,0.078),ARMOR_DARK)
            _box(wing,"VidrioLateralPolarizado_%s_%d" % [side,i],
                Vector3(at_x,1.42,-2.032),
                Vector3(0.38,0.53,0.044),GLASS,"glass")
            _box(wing,"RejillaBajoVentanilla_%s_%d" % [side,i],
                Vector3(at_x,1.02,-2.044),
                Vector3(0.39,0.046,0.08),WHITE)
        _shell(wing,"VentiladorLateralExterior_%s" % side,
            Vector3(s*5.19,1.35,1.03),
            Vector3(0.18,1.05,1.21),0.08,ARMOR_DARK,"roof")
        for j in range(5):
            _box(wing,"AletaVentilador_%s_%d" % [side,j],
                Vector3(s*5.31,1.03+float(j)*0.14,1.03),
                Vector3(0.028,0.049,0.94),WHITE)

static func _comms_lattice(parent: Node3D,level: int,tint: Color) -> void:
    # Original reference has a recognizable side communications tower.
    var structure: Node3D = _group(parent,"TorreDeRedesTrianguladaV4",
        Vector3(4.50,2.54,1.38))
    var h: float = 2.47+0.56*float(level-1)
    _shell(structure,"BaseDeTorre",Vector3(0,0.12,0),
        Vector3(1.26,0.24,1.29),0.17,ARMOR_DARK,"roof")
    for side in [-1,1]:
        var sx: float = float(side)
        for depth in [-1,1]:
            var sz: float = float(depth)
            _beam(structure,"ColumnaEnCelosia_%s_%s" % [side,depth],
                Vector3(sx*0.52,0.15,sz*0.53),
                Vector3(sx*0.31,h,sz*0.32),
                0.050,ARMOR)
        for tier in range(3):
            var y0: float = 0.27+float(tier)*h/3.0
            var y1: float = y0+h/3.0
            _beam(structure,"CruzCelosia_%s_%d" % [side,tier],
                Vector3(sx*0.48,y0,0.46),
                Vector3(sx*0.35,y1,-0.35),0.026,WHITE)
    _shell(structure,"CabinaComunicacionesSuperior",
        Vector3(0,h+0.13,0),
        Vector3(1.50,0.50,1.51),0.17,GLASS,"glass")
    _shell(structure,"CumbreDeComunicaciones",
        Vector3(0,h+0.46,0),
        Vector3(1.80,0.18,1.80),0.22,tint.darkened(0.16),"steel",true)
    _beam(structure,"AntenaCentralSuperior",
        Vector3(0,h+0.53,0),Vector3(0,h+1.55,0),0.048,ARMOR_DARK)
    _box(structure,"BalizaTorre",Vector3(0,h+1.61,0),
        Vector3(0.17,0.16,0.17),GOLD)
    # A cloth faction pennant forms a clear readable silhouette at distance.
    _flag(parent,tint,Vector3(5.59,2.48,0.46),level)

static func _radar_upgrade(model: Node3D,level: int) -> void:
    var dish: Node = model.find_child("RadarPremium3D",true,false)
    if dish is Node3D:
        var main: Node3D = dish as Node3D
        var y: float = 2.87+0.91*float(level-1)
        main.position = Vector3(-1.86,y+2.05,0.76)
        main.rotation_degrees = Vector3(-46,21,0)
        main.scale = Vector3(1.56,1.56,1.56)
    var structure: Node3D = model.find_child("EstructuraPrincipal",true,false) as Node3D
    if structure == null:
        return
    var rack := _group(structure,"ArmazonDeRadarV4")
    var base := Vector3(-1.86,2.87+0.91*float(level-1),0.76)
    _shell(rack,"CimentacionAntena",
        base+Vector3(0,0.15,0),
        Vector3(1.09,0.30,1.10),0.16,ARMOR_DARK,"roof")
    for side in [-1,1]:
        var s: float = float(side)
        _beam(rack,"SoporteRadial_%s" % side,
            base+Vector3(s*0.43,0.24,0),
            base+Vector3(s*0.15,1.21,0),0.072,ARMOR)
    # Existing V1 flat plate remains hidden behind the new curved dish.

static func _move_helipad(model: Node3D,level: int,tint: Color) -> void:
    var node: Node = model.find_child("Helipuerto",true,false)
    if not (node is Node3D):
        return
    var pad: Node3D = node as Node3D
    # The original concept shows the landing pad in the FRONT LEFT yard.
    # It was previously placed behind and above the building. Reposition it.
    pad.position = Vector3(-4.85,-2.02,-4.08)
    for name in ["PilaresHelipuerto","AccesoEscalera","SeccionAccesoElevado",
            "PuenteDeAcceso","SeguridadHelipuertoV3"]:
        var part: Node = pad.find_child(name,true,false)
        if part is Node3D:
            (part as Node3D).visible = false
    for name in ["CasetaControl_-1","TechoCaseta_-1","CristalCaseta_-1",
            "FarolaIngreso_-1","LuminariaEntrada_-1"]:
        var part: Node = model.find_child(name,true,false)
        if part is Node3D:
            (part as Node3D).visible = false
    var approach: Node3D = _group(model,"AproximacionHelipuertoV4")
    _shell(approach,"PlataformaBaseHelipuerto",
        Vector3(-4.85,0.10,-4.08),
        Vector3(3.44,0.22,3.34),0.29,PAVEMENT,"roof")
    _box(approach,"PasilloDeAcceso",
        Vector3(-2.86,0.10,-3.84),
        Vector3(1.25,0.15,0.95),CONCRETE,"concrete")
    for i in range(6):
        var z: float = -4.92+float(i)*0.34
        _box(approach,"AdvertenciaDeSeguridad_%d" % i,
            Vector3(-3.12,0.20,z),
            Vector3(0.20,0.027,0.15),
            tint.darkened(0.25) if i%2==0 else GOLD,"roof",i%2==0)
    # All original H/ring geometry and visual states remain mounted on the pad.

static func _front_cladding(parent: Node3D,level: int,tint: Color) -> void:
    var walls := _group(parent,"RevestimientoAzulDeMandoV4")
    var y: float = 2.87+float(level-1)*0.91
    for side in [-1,1]:
        var s: float = float(side)
        _shell(walls,"AletaAzulDeFachada_%s" % side,
            Vector3(s*2.65,y*0.65,-2.64),
            Vector3(0.31,y*0.75,0.30),0.04,
            tint.darkened(0.25),"steel",true)
        _box(walls,"PerfilLuzExterior_%s" % side,
            Vector3(s*2.87,y*0.67,-2.83),
            Vector3(0.085,y*0.64,0.065),GOLD)
        for i in range(2):
            _shell(walls,"PanelVerticalBlindado_%s_%d" % [side,i],
                Vector3(s*(2.96+float(i)*0.14),y*0.42,
                    -1.96+float(i)*0.41),
                Vector3(0.17,y*0.56,0.27),0.03,ARMOR,"roof")
    _box(walls,"MolduraDeFaccionFrontal",
        Vector3(0,y-0.18,-2.74),
        Vector3(5.12,0.20,0.13),tint.darkened(0.12),"steel",true)
    # More visual warmth than monochrome gray; still restrained brand colors.
    _box(walls,"AristaDeSeguridadOro",
        Vector3(0,y-0.36,-2.82),
        Vector3(4.85,0.062,0.072),GOLD)

static func _bolts_batch(parent: Node3D,name: String,
        positions: Array[Vector3],size: float = 0.055) -> MultiMeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(size,size*0.68,size)
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = mesh
    mm.instance_count = positions.size()
    for i in range(positions.size()):
        mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,positions[i]))
    var inst := MultiMeshInstance3D.new()
    inst.name = name
    inst.multimesh = mm
    inst.material_override = Finish._mat(CONCRETE,"steel")
    parent.add_child(inst)
    return inst

static func _near_detail(parent: Node3D,level: int) -> void:
    var detail: Node3D = _group(parent,"DetalleCercanoV4")
    var bolts: Array[Vector3] = []
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(12):
            var z: float = -1.57+float(i)*0.30
            bolts.append(Vector3(sx*5.22,2.54,z))
        for j in range(11):
            bolts.append(Vector3(sx*(3.10+float(j)*0.17),2.61,-1.97))
    _bolts_batch(detail,"RemachesDeBlindajeInstanciados",bolts)
    var y: float = 2.87+float(level-1)*0.91
    for s in [-1,1]:
        var side: float = float(s)
        for i in range(5):
            _box(detail,"RejillaDeServicioFina_%s_%d" % [s,i],
                Vector3(side*(2.45+float(i)*0.10),y-0.82,-2.82),
                Vector3(0.055,0.25,0.034),CONCRETE)
        for i in range(4):
            _box(detail,"JuntaDeVentanilla_%s_%d" % [s,i],
                Vector3(side*4.03,0.76+float(i)*0.12,-2.09),
                Vector3(0.44,0.028,0.030),ARMOR_DARK)

static func _destroyed(parent: Node3D,tint: Color) -> void:
    var ruins: Node3D = _group(parent,"EscombrosHeroV4")
    _shell(ruins,"TorreDeMandoColapsada",
        Vector3(-1.22,0.53,-2.69),
        Vector3(2.48,0.66,1.42),0.22,ARMOR_DARK,"roof")
    _badge_mesh(ruins,tint.darkened(0.45),"EscudoFragmentadoEnSuelo",
        Vector3(1.61,0.20,-4.12),0.87,0.61)
    for i in range(6):
        var x: float = -2.45+float(i)*0.92
        _beam(ruins,"TuboDeTorreRoto_%02d" % i,
            Vector3(x,0.24,0.25),
            Vector3(x-0.65,0.66+float(i%3)*0.25,0.91),0.068,SOOT)

static func set_near_detail(model: Node3D,near: bool) -> void:
    var detail: Node = model.find_child("DetalleCercanoV4",true,false)
    if detail is Node3D:
        (detail as Node3D).visible = near

static func apply(model: Node3D,level: int,tint: Color,condition: String) -> void:
    if model == null:
        return
    model.set_meta("tarvoka_hq_visual_v4",true)
    model.set_meta("tarvoka_hq_reference","approved-hq-20261112")
    if condition == "destruido":
        _destroyed(model,tint)
        return
    # Remove visual overlap, not gameplay data or historical geometry.
    var old: Node = model.find_child("PabellonComandoElevado",true,false)
    if old is Node3D:
        (old as Node3D).visible = false
    _command_tower(model,level,tint)
    _wing_cladding(model,level,tint)
    _comms_lattice(model,level,tint)
    _radar_upgrade(model,level)
    _front_cladding(model,level,tint)
    _move_helipad(model,level,tint)
    _near_detail(model,level)
    if condition == "danado":
        var damage := _group(model,"ImpactosHeroV4")
        _box(damage,"PlacaChamuscadaTorre",
            Vector3(-0.78,3.82+float(level-1)*0.91,-3.63),
            Vector3(0.51,0.36,0.05),SOOT,"roof")
        _beam(damage,"CortaduraEnEmblema",
            Vector3(-0.29,3.70+float(level-1)*0.91,-3.73),
            Vector3(0.19,4.12+float(level-1)*0.91,-3.73),0.031,SOOT)
    set_near_detail(model,false)
