extends RefCounted
class_name TarvokaCivilianCityFacadeV2

# TARVOKA Ciudades Civiles V2: additive native Godot 4.3 facade sculpture.
# V1 is never replaced, and no tactical income/capture/health logic changes.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV2FachadasAyuntamientoTejados"
const LIMESTONE=Color("#d1c7b4")
const PORCELAIN=Color("#a4b9bd")
const BRONZE=Color("#907c59")
const CHARCOAL=Color("#334c54")
const RAIL=Color("#647a80")
const SHUTTER=Color("#8b9b9a")
const MARKET=Color("#a57c66")
const TERRACOTTA=Color("#935f50")
const CONCRETE=Color("#b4aaa0")
const WEAR=Color("#8c6b5c")

static func _box(root: Node3D,n: String,p: Vector3,d: Vector3,
        c: Color,kind: String="stone") -> MeshInstance3D:
    return V1._box(root,n,p,d,c,kind)

static func _bar(root: Node3D,n: String,p: Vector3,radius: float,
        height: float,c: Color) -> void:
    V1._cylinder(root,n,p,radius,height,c,8)

# Small true 3D triangular classical pediment -- not a floating square
# nor a plane/textured sticker. Each of its five faces is closed.
static func _pediment(parent: Node3D,tag: String,
        center: Vector3,half_w: float,rise: float,
        depth: float,color: Color) -> void:
    var a:=Vector3(center.x-half_w,center.y,center.z-depth*0.5)
    var b:=Vector3(center.x,center.y+rise,center.z-depth*0.5)
    var c:=Vector3(center.x+half_w,center.y,center.z-depth*0.5)
    var d:=Vector3(center.x-half_w,center.y,center.z+depth*0.5)
    var e:=Vector3(center.x,center.y+rise,center.z+depth*0.5)
    var f:=Vector3(center.x+half_w,center.y,center.z+depth*0.5)
    var triangles: Array=[
        [a,c,b],[d,e,f],  # front / back
        [a,b,e],[a,e,d],  # roof slope left
        [b,c,f],[b,f,e],  # roof slope right
        [a,d,f],[a,f,c]   # underside
    ]
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for tri in triangles:
        var p0: Vector3=tri[0]
        var p1: Vector3=tri[1]
        var p2: Vector3=tri[2]
        var normal: Vector3=(p1-p0).cross(p2-p0).normalized()
        for vertex in tri:
            surface.set_normal(normal)
            surface.add_vertex(vertex)
    var mesh:=MeshInstance3D.new()
    mesh.name="FrontonTriangularV2_"+tag
    mesh.mesh=surface.commit()
    mesh.material_override=V1._material(color)
    parent.add_child(mesh)

static func _roof(root: Node3D,tag: String,level: int,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var h: float=float(floors)*2.10+0.21
    var is_civic: bool=tag=="Ayuntamiento"
    var roof:=V1._group(root,"TejadoRematadoV2_"+tag)
    if damage==2:
        # Severed coping, not a brand-new intact roof after shell impacts.
        _box(roof,"CornisaQuebradaV2",Vector3(x-w*0.21,h+0.26,z),
            Vector3(w*0.35,0.13,0.31),WEAR)
        return
    if level==1 and not is_civic:
        # Each tilted plate forms one half of a true gabled residential roof.
        # Its ridge aligns along the x axis; no intersection with window glass.
        for side in [-1,1]:
            var roof_half:=_box(roof,"TejaInclinadaV2_%d" % side,
                Vector3(x,h+0.30,z+float(side)*d*0.255),
                Vector3(w+0.44,0.12,d*0.57),
                TERRACOTTA)
            roof_half.rotation_degrees.x=float(side)*15.0
        _box(roof,"CaballeteTejadoV2",Vector3(x,h+0.62,z),
            Vector3(w+0.45,0.10,0.23),BRONZE)
        _box(roof,"ChimeneaV2",Vector3(x+w*0.24,h+0.84,z+d*0.17),
            Vector3(0.31,0.69,0.35),CONCRETE)
        _box(roof,"TapaChimeneaV2",
            Vector3(x+w*0.24,h+1.21,z+d*0.17),
            Vector3(0.42,0.10,0.43),CHARCOAL,"metal")
    elif level==2 and not is_civic:
        # Utilitarian flat roofs with a parapet and visible rain outlets.
        for side in [-1,1]:
            _box(roof,"ParapetoLateralV2_%d" % side,
                Vector3(x+float(side)*(w*0.5+0.04),h+0.38,z),
                Vector3(0.18,0.42,d+0.18),PORCELAIN)
        _box(roof,"ParapetoPosteriorV2",
            Vector3(x,h+0.38,z+d*0.5+0.04),
            Vector3(w+0.18,0.42,0.16),PORCELAIN)
        _box(roof,"CanalonPluvialV2",
            Vector3(x,h+0.22,z-d*0.5-0.20),
            Vector3(w+0.35,0.09,0.16),BRONZE,"metal")
    elif level==3 and not is_civic:
        # Metropolitan rooftops: antenna and weatherproof service boxes.
        _box(roof,"MaquinaClimaV2",
            Vector3(x-w*0.25,h+0.41,z+d*0.08),
            Vector3(0.64,0.45,0.74),CHARCOAL,"metal")
        _box(roof,"FiltroMaquinaV2",
            Vector3(x-w*0.25,h+0.69,z+d*0.08),
            Vector3(0.53,0.09,0.61),RAIL,"metal")
        _bar(roof,"AntenaUrbanaV2",
            Vector3(x+w*0.25,h+0.90,z+d*0.11),
            0.045,1.30,CHARCOAL)
        _box(roof,"BalizaAntenaV2",
            Vector3(x+w*0.25,h+1.58,z+d*0.11),
            Vector3(0.17,0.13,0.17),accent,"metal")
    elif is_civic:
        _box(roof,"CoronacionAyuntamientoV2",
            Vector3(x,h+0.36,z),
            Vector3(w+0.55,0.22,d+0.48),LIMESTONE)
        if level>=2:
            _box(roof,"SombraPerimetralV2",
                Vector3(x,h+0.52,z),
                Vector3(w+0.32,0.13,d+0.32),CHARCOAL,"metal")

static func _balcony(root: Node3D,tag: String,level: int,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int) -> void:
    if level==1 or damage>=2 or tag=="Ayuntamiento":
        return
    var front_z: float=z-d*0.5-0.037
    var group:=V1._group(root,"BalconesV2_"+tag)
    # N2 has a single balcony; N3 adds higher residential balconies.
    for floor in range(1,floors):
        if level==2 and floor>1:
            continue
        if level==3 and floor%2==0:
            continue
        if damage==1 and floor==floors-1:
            # Damage level one: top balcony's railing is removed.
            continue
        var y: float=float(floor)*2.10+0.12
        var suffix: String=str(floor)
        var balcony_z: float=front_z-0.38
        _box(group,"BandejaBalconV2_"+suffix,
            Vector3(x,y,balcony_z),
            Vector3(w*0.76,0.16,0.79),CONCRETE)
        _box(group,"BarandillaFrenteV2_"+suffix,
            Vector3(x,y+0.50,balcony_z-0.41),
            Vector3(w*0.76,0.13,0.08),RAIL,"metal")
        for side in [-1,1]:
            var edge_x: float=x+float(side)*w*0.365
            _box(group,"BarandillaCostadoV2_"+suffix+"_"+str(side),
                Vector3(edge_x,y+0.50,balcony_z),
                Vector3(0.085,0.13,0.80),RAIL,"metal")
            _box(group,"PosteBalconV2_"+suffix+"_"+str(side),
                Vector3(edge_x,y+0.28,balcony_z-0.37),
                Vector3(0.075,0.52,0.075),CHARCOAL,"metal")
        _box(group,"PuertaBalconV2_"+suffix,
            Vector3(x,y+0.87,front_z-0.08),
            Vector3(0.69,1.65,0.065),GLASS_CITY(),"glass")

static func GLASS_CITY() -> Color:
    return Color("#577d8a")

static func _front(root: Node3D,tag: String,level: int,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var group:=V1._group(root,"FachadaV2_"+tag)
    var front: float=z-d*0.5-0.037
    var is_civic: bool=tag=="Ayuntamiento"
    var h: float=float(floors)*2.10+0.21
    if damage==2:
        _box(group,"DintelFracturadoV2",
            Vector3(x+w*0.12,1.80,front-0.10),
            Vector3(w*0.42,0.10,0.14),WEAR)
        return
    if is_civic:
        _box(group,"BandaAyuntamientoV2",
            Vector3(x,h-0.52,front-0.16),
            Vector3(w+0.18,0.23,0.28),LIMESTONE)
        _pediment(group,"Ayuntamiento",
            Vector3(x,h+0.42,front-0.10),
            w*0.57,0.50 if level==1 else 0.71,
            0.30,LIMESTONE)
        _box(group,"TimpanoBajoV2",
            Vector3(x,h+0.40,front-0.12),
            Vector3(w+0.30,0.10,0.38),BRONZE)
        _box(group,"EscudoCivilV2",
            Vector3(x,h-0.24,front-0.20),
            Vector3(0.34,0.24,0.12),accent,"metal")
        if level>=2:
            # Municipal entrance with true volumetric portico and balcony.
            _box(group,"MarquesinaCivicaV2",
                Vector3(x,1.85,front-0.37),
                Vector3(w*0.73,0.20,0.72),LIMESTONE)
            for side in [-1,1]:
                _box(group,"PilarPorticoV2_%d" % side,
                    Vector3(x+float(side)*w*0.30,0.97,front-0.64),
                    Vector3(0.15,1.80,0.16),LIMESTONE)
            _box(group,"BarandaMunicipalV2",
                Vector3(x,2.41,front-0.61),
                Vector3(w*0.68,0.10,0.09),BRONZE,"metal")
        if level==3:
            _box(group,"VentanalPanoramicoV2",
                Vector3(x,3.44,front-0.17),
                Vector3(w*0.56,0.63,0.05),GLASS_CITY(),"glass")
    else:
        # Shop fronts only appear in the developed city and metropolis.
        if level>=2 and z>0:
            _box(group,"LetreroComercioV2",
                Vector3(x,1.86,front-0.13),
                Vector3(w*0.68,0.22,0.16),accent,"metal")
            _box(group,"MarquesinaComercioV2",
                Vector3(x,2.03,front-0.46),
                Vector3(w*0.75,0.12,0.76),
                MARKET if damage==0 else WEAR)
            for side in [-1,1]:
                _box(group,"CristalEscaparateV2_%d" % side,
                    Vector3(x+float(side)*w*0.23,
                        0.96,front-0.16),
                    Vector3(w*0.29,0.85,0.05),GLASS_CITY(),"glass")
        # Shutters articulate the smaller villa without changing the wall.
        if level==1:
            for side in [-1,1]:
                var wx: float=x+float(side)*w*0.23
                for shutter_side in [-1,1]:
                    _box(group,
                        "PersianaVillaV2_%d_%d" % [side,shutter_side],
                        Vector3(wx+float(shutter_side)*0.40,
                            0.86,front-0.09),
                        Vector3(0.115,0.75,0.09),
                        SHUTTER if damage==0 else WEAR)

static func apply(model: Node3D,level: int,faction: int,
        damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("visual_city_v1",false)):
        return false
    if not model.has_node(V1.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level:
        return false
    if int(model.get_meta("visual_faction",-2))!=faction:
        return false
    if int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=Style.faction_color(faction) if faction>=0 else V1.NEUTRAL_ACCENT
    if damage!=4:
        var rear: int=1 if level==1 else 2 if level==2 else 4
        var front: int=1 if level==1 else 3 if level==2 else 5
        var civic: int=2 if level==1 else 3 if level==2 else 4
        for side in [-1,1]:
            var x: float=float(side)*4.63
            var specs: Array=[
                ["ResidencialNorte_%d" % side,x,-3.80,2.74,2.84,rear],
                ["ResidencialSur_%d" % side,x,3.62,2.77,2.80,front]
            ]
            for spec in specs:
                var tag: String=spec[0]
                var cx: float=spec[1]
                var z: float=spec[2]
                var w: float=spec[3]
                var d: float=spec[4]
                var floors: int=spec[5]
                _roof(stage,tag,level,cx,z,w,d,floors,damage,accent)
                _front(stage,tag,level,cx,z,w,d,floors,damage,accent)
                _balcony(stage,tag,level,cx,z,w,d,floors,damage)
        _roof(stage,"Ayuntamiento",level,0.0,-3.75,
            3.35,2.74,civic,damage,accent)
        _front(stage,"Ayuntamiento",level,0.0,-3.75,
            3.35,2.74,civic,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("detail_version",2)
    stage.set_meta("level",level)
    stage.set_meta("faction",faction)
    stage.set_meta("damage",damage)
    return true
