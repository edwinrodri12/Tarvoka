extends RefCounted
class_name TarvokaArmoredWorkshop3DV2

# TARVOKA Armored Workshop V2: editable Godot 4.3 geometry layered over V1.
# Art-only, fixed building. NOT a separate supply depot or mobile camp.
# V1 is preserved for reversible visual comparison in TARVOKA Studio.
const V1=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const TITLE="Taller de Blindados"
const STAGE="TallerBlindadosV1ModeloNativo"
const FINISH_STAGE="AcabadosYMaquinariaV2"
const LEVEL_NAMES=V1.LEVEL_NAMES
const DAMAGE_NAMES=V1.DAMAGE_NAMES
const NEUTRAL=V1.NEUTRAL
const ARMOR=Color("#596e78")
const ARMOR_DARK=Color("#253a44")
const GALVANIZED=Color("#9dabb0")
const BRIGHT_STEEL=Color("#c7d4d7")
const WORKLIGHT=Color("#e6eee2")
const GLASS_OPAQUE=Color("#789da8")
const CONCRETE=Color("#7d898d")
const HAZARD=Color("#dfa840")
const BLACK=Color("#273038")
const OIL=Color("#354b4d")
const RUST=Color("#82574d")
const RUBBLE=Color("#636266")
static var _materials:Dictionary={}
static var _box_meshes:Dictionary={}

static func valid(level:int,faction:int,damage:int) -> bool:
    return V1.valid(level,faction,damage)

static func _mat(tint:Color,metal:float=0.0,rough:float=0.65,
        lit:bool=false) -> StandardMaterial3D:
    var key:String="%s/%.2f/%.2f/%s" % [tint.to_html(true),metal,rough,str(lit)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var result:=StandardMaterial3D.new()
    result.albedo_color=tint
    result.metallic=metal
    result.roughness=rough
    # Opaque metal siding and glazing: avoid disappearing/translucent walls.
    result.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    result.cull_mode=BaseMaterial3D.CULL_BACK
    if lit:
        result.emission_enabled=true
        result.emission=tint
        result.emission_energy_multiplier=0.70
    _materials[key]=result
    return result

static func _node(parent:Node3D,label:String) -> Node3D:
    var item:=Node3D.new()
    item.name=label
    parent.add_child(item)
    return item

static func _box(parent:Node3D,label:String,at:Vector3,size:Vector3,
        color:Color,metal:float=0.0,rough:float=0.70,
        rotation:Vector3=Vector3.ZERO,lit:bool=false) -> MeshInstance3D:
    var key:String=str(size)
    var shape:BoxMesh
    if _box_meshes.has(key):
        shape=_box_meshes[key] as BoxMesh
    else:
        shape=BoxMesh.new()
        shape.size=size
        _box_meshes[key]=shape
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=shape
    item.position=at
    item.rotation_degrees=rotation
    item.material_override=_mat(color,metal,rough,lit)
    parent.add_child(item)
    return item

static func _cylinder(parent:Node3D,label:String,at:Vector3,
        radius:float,length:float,color:Color,metal:float=0.70,
        rough:float=0.51,rotation:Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=length
    shape.radial_segments=16
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=shape
    item.position=at
    item.rotation_degrees=rotation
    item.material_override=_mat(color,metal,rough)
    parent.add_child(item)
    return item

static func _portal(parent:Node3D,width:float,depth:float,
        height:float,bays:int,damage:int,accent:Color) -> void:
    if damage>=4:
        return
    var front:float=-depth*0.5
    var bw:float=width/float(bays)
    # D3 must not keep the intact full-height front lintel suspended.
    if damage>=3:
        for fragment in range(2):
            _box(parent,"FragmentoFrontispicioCaido_%d" % fragment,
                Vector3(width*(-0.19 if fragment==0 else 0.22),
                    0.19,front-0.53+float(fragment)*0.35),
                Vector3(width*0.31,0.20,0.38),RUST,0.51,0.79,
                Vector3(0,19.0 if fragment==0 else -13.0,
                    -13.0 if fragment==0 else 8.0))
        return
    _box(parent,"FrontispicioBlindadoV2",Vector3(0,height-0.33,front-0.42),
        Vector3(width-0.35,0.68,0.24),ARMOR_DARK,0.72,0.49)
    _box(parent,"BandaFaccionSuperiorV2",
        Vector3(0,height+0.025,front-0.46),
        Vector3(width*0.76,0.15,0.13),accent,0.44,0.34)
    for bay in range(bays):
        var cx:float=-width*0.5+bw*(float(bay)+0.5)
        # Solid machined aperture with full physical door jambs.
        for side in [-1,1]:
            var edge:float=cx+float(side)*(bw*0.5-0.33)
            _box(parent,"MarcoVertical_%d_%d" % [bay,side],
                Vector3(edge,height*0.50,front-0.43),
                Vector3(0.22,height*0.91,0.22),GALVANIZED,0.79,0.43)
            _box(parent,"ParachoquesBollard_%d_%d" % [bay,side],
                Vector3(edge,0.55,front-0.82),
                Vector3(0.22,1.10,0.22),HAZARD,0.29,0.62)
            for stripe in range(3):
                _box(parent,"RayadoSeguridad_%d_%d_%d" % [bay,side,stripe],
                    Vector3(edge,0.31+float(stripe)*0.31,front-0.942),
                    Vector3(0.228,0.095,0.022),BLACK,0.05,0.79,
                    Vector3(0,0,24.0))
        # Machined roller drum and individual articulated door sections;
        # raised shutters leave the service mouth unobstructed.
        if damage<=1:
            _cylinder(parent,"TamborPersiana_%d" % bay,
                Vector3(cx,height-0.62,front-0.58),0.22,bw-0.57,
                ARMOR,0.78,0.40,Vector3(0,0,90))
            for slat in range(5):
                _box(parent,"LamaPorton_%d_%d" % [bay,slat],
                    Vector3(cx,height-0.41-float(slat)*0.105,front-0.786),
                    Vector3(bw-0.56,0.087,0.045),
                    GALVANIZED if slat%2==0 else ARMOR,
                    0.65,0.52)
        else:
            for slat in range(3):
                _box(parent,"LamaPortonDanada_%d_%d" % [bay,slat],
                    Vector3(cx,height-0.43-float(slat)*0.135,
                        front-0.79+float(slat)*0.027),
                    Vector3(bw-0.77,0.082,0.049),
                    RUST,0.52,0.82,
                    Vector3(0,0,float(slat-1)*7.0))
        _box(parent,"PlacaIdentidad_%d" % bay,
            Vector3(cx,height-0.13,front-0.56),
            Vector3(bw*0.32,0.25,0.07),accent,0.38,0.44)
        _box(parent,"PlacaIdentidadCentro_%d" % bay,
            Vector3(cx,height-0.13,front-0.604),
            Vector3(bw*0.10,0.11,0.02),BRIGHT_STEEL,0.65,0.35)
        if damage<=1:
            for lamp in [-1,1]:
                _box(parent,"FocoAcceso_%d_%d" % [bay,lamp],
                    Vector3(cx+float(lamp)*bw*0.38,height-0.86,front-0.74),
                    Vector3(0.31,0.12,0.20),WORKLIGHT,0.12,0.23,
                    Vector3.ZERO,true)

static func _wall_enclosure(parent:Node3D,width:float,depth:float,
        height:float,damage:int,accent:Color) -> void:
    # D3/D4 deliberately have NO complete full-height siding:
    # shattered pillars and ground-based debris belong to V1 wreckage.
    if damage>=3:
        return
    var upper:float=height-0.86
    var wall_h:float=upper-1.76
    # Opaque siding closes V1's open-looking lateral bays; non-transparent
    # raised metallic windows are inlaid into a fully solid workshop envelope.
    for side in [-1,1]:
        var x:float=float(side)*(width*0.5+0.11)
        for segment in range(3):
            var z:float=-depth*0.31+float(segment)*depth*0.31
            _box(parent,"PanelLateralCerrado_%d_%d" % [side,segment],
                Vector3(x,1.76+wall_h*0.5,z),
                # Overlap V1 lower concrete plinth and upper steel lintel:
                # no ten-centimeter see-through horizontal seam.
                Vector3(0.20,wall_h+0.18,depth*0.306),
                CONCRETE if segment%2==0 else ARMOR,0.30,0.69)
            if damage<=2:
                _box(parent,"VentanaMarco_%d_%d" % [side,segment],
                    Vector3(x+float(side)*0.116,2.53,z),
                    Vector3(0.065,0.73,depth*0.18),ARMOR_DARK,0.70,0.45)
                _box(parent,"VentanaVidrioPBR_%d_%d" % [side,segment],
                    Vector3(x+float(side)*0.157,2.53,z),
                    Vector3(0.027,0.56,depth*0.151),GLASS_OPAQUE,0.28,0.12)
                _box(parent,"VentanaMarcoHorizontal_%d_%d" % [side,segment],
                    Vector3(x+float(side)*0.18,2.53,z),
                    Vector3(0.030,0.035,depth*0.15),BRIGHT_STEEL,0.78,0.36)
                for seam in [-1,1]:
                    _box(parent,"NervaduraFachada_%d_%d_%d" % [side,segment,seam],
                        Vector3(x+float(side)*0.12,1.76+wall_h*0.5,
                            z+float(seam)*depth*0.148),
                        Vector3(0.07,wall_h-0.07,0.055),ARMOR_DARK,0.76,0.49)
        # End caps close the last 3.7% of depth near front/rear corners.
        # Without these the three siding panels only span 92.6% of the wall,
        # leaving narrow sightlines behind the structural pillars.
        for end_side in [-1,1]:
            _box(parent,
                "RemateEsquinaLateral_%d_%d" % [side,end_side],
                Vector3(x,1.76+wall_h*0.5,
                    float(end_side)*depth*0.467),
                Vector3(0.20,wall_h+0.18,depth*0.082),
                ARMOR_DARK,0.61,0.59)
        # Physical vertical joint seals bridge all three panels.
        for seam in range(2):
            var join_z:float=-depth*0.155+float(seam)*depth*0.31
            _box(parent,"JuntaLateralSellada_%d_%d" % [side,seam],
                Vector3(x+float(side)*0.155,1.76+wall_h*0.5,join_z),
                Vector3(0.105,wall_h+0.20,0.145),ARMOR_DARK,0.71,0.51)
        if damage<=2:
            _box(parent,"ZunchoLateralFaccion_%d" % side,
                Vector3(x+float(side)*0.145,upper-0.19,0),
                Vector3(0.08,0.11,depth*0.72),accent.darkened(0.12),0.52,0.50)
    if damage<=2:
        _box(parent,"PanelPosteriorAlto",
            Vector3(0,(3.13+height-0.48)*0.5,depth*0.5-0.03),
            Vector3(width-0.52,height-3.61,0.23),
            ARMOR,0.48,0.65)
        for i in range(5):
            var x:float=-width*0.37+float(i)*width*0.185
            _box(parent,"CostillaPosterior_%d" % i,
                Vector3(x,height*0.69,depth*0.5+0.116),
                Vector3(0.075,height*0.38,0.08),GALVANIZED,0.74,0.45)
        # The V1 high rear windows were buried behind opaque upper cladding.
        # V2 places visible, framed opaque-glass inlays on the exterior face.
        for pane in range(4):
            var wx:float=-width*0.35+float(pane)*width*0.2333
            _box(parent,"MarcoVentanaPosterior_%d" % pane,
                Vector3(wx,height-1.00,depth*0.5+0.145),
                Vector3(width*0.145,0.52,0.10),ARMOR_DARK,0.69,0.46)
            _box(parent,"CristalPosteriorPBR_%d" % pane,
                Vector3(wx,height-1.00,depth*0.5+0.200),
                Vector3(width*0.119,0.390,0.025),GLASS_OPAQUE,0.26,0.13)
            _box(parent,"ReflejoCristalPosterior_%d" % pane,
                Vector3(wx-width*0.025,height-0.93,depth*0.5+0.219),
                Vector3(width*0.012,0.24,0.007),BRIGHT_STEEL,0.33,0.18)

static func _roof_finish(parent:Node3D,width:float,depth:float,height:float,
        bays:int,damage:int) -> void:
    # D3 and D4 have no continuous roofing: even a single full-length rib
    # would appear to float above the ruined workshop without a supporting wall.
    if damage>=3:
        return
    # Fine metal crests, real housings, shutters and mechanical ventilation.
    for bay in range(bays):
        var bw:float=width/float(bays)
        var cx:float=-width*0.5+bw*(float(bay)+0.5)
        for ridge in range(4):
            var x:float=cx+bw*(float(ridge)-1.5)*0.20
            _box(parent,"NervioCubierta_%d_%d" % [bay,ridge],
                Vector3(x,height+0.259,0),
                Vector3(0.055,0.07,depth*0.91),GALVANIZED,0.72,0.53)
        # V1 roofing has 0.03*depth open seams between its three panels.
        # Full opaque metal flashings overlap both sides, eliminating holes.
        if damage<=1:
            for seam in range(2):
                _box(parent,"JuntaCubiertaSellada_%d_%d" % [bay,seam],
                    Vector3(cx,height+0.176,
                        depth*(-0.17 if seam==0 else 0.17)),
                    Vector3(bw-0.25,0.115,depth*0.067),
                    GALVANIZED,0.65,0.54)
        if damage<=2:
            _box(parent,"ConductoVentilacion_%d" % bay,
                Vector3(cx,height+0.54,depth*0.27),
                Vector3(bw*0.36,0.47,0.87),ARMOR_DARK,0.65,0.54)
            for vane in range(3):
                _box(parent,"LamelaVentilacion_%d_%d" % [bay,vane],
                    Vector3(cx,height+0.47+float(vane)*0.11,
                        depth*0.27-0.47),
                    Vector3(bw*0.27,0.052,0.04),GALVANIZED,0.72,0.52)
        if damage<=1:
            for led in [-1,1]:
                _box(parent,"FocoCubierta_%d_%d" % [bay,led],
                    Vector3(cx+float(led)*bw*0.25,height+0.28,
                        -depth*0.35),
                    Vector3(0.18,0.11,0.24),WORKLIGHT,0.20,0.23,
                    Vector3.ZERO,true)

static func _machinery(parent:Node3D,width:float,depth:float,height:float,
        bays:int,damage:int) -> void:
    if damage>=3:
        return
    var bw:float=width/float(bays)
    var shop:=_node(parent,"MaquinariaDeBlindados")
    for bay in range(bays):
        var cx:float=-width*0.5+bw*(float(bay)+0.5)
        # Machined lift plates and recessed work inspection walkways.
        for side in [-1,1]:
            var sx:float=cx+float(side)*bw*0.32
            _box(shop,"RielRodadura_%d_%d" % [bay,side],
                Vector3(sx,0.145,0.04),
                Vector3(0.145,0.045,depth*0.49),GALVANIZED,0.73,0.47)
            for pad in range(4):
                var z:float=-depth*0.18+float(pad)*depth*0.125
                _box(shop,"PlacaAntideslizante_%d_%d_%d" % [bay,side,pad],
                    Vector3(sx,0.185,z),Vector3(0.31,0.052,0.34),
                    ARMOR_DARK,0.64,0.65)
                _box(shop,"BordePlaca_%d_%d_%d" % [bay,side,pad],
                    Vector3(sx,0.215,z-0.12),
                    Vector3(0.25,0.018,0.035),HAZARD,0.22,0.71)
        if damage<=1:
            # Spare armor plates: dedicated military-vehicle workshop identity.
            var rack_x:float=cx-bw*0.34
            var rack_z:float=depth*0.5-1.48
            _box(shop,"BancadaPlacas_%d" % bay,
                Vector3(rack_x,0.48,rack_z),
                Vector3(0.42,0.16,1.55),ARMOR_DARK,0.63,0.57)
            for plate in range(4):
                _box(shop,"PlacaBlindaje_%d_%d" % [bay,plate],
                    Vector3(rack_x,0.72+float(plate)*0.24,
                        rack_z+float(plate%2)*0.075),
                    Vector3(0.11,0.23,1.19),ARMOR,0.74,0.39,
                    Vector3(float(plate%2)*3.0,0,-13.0))
            # Tank track repair stand: real wheels, guide rails and ground feet.
            var track_x:float=cx+bw*0.33
            var track_z:float=depth*0.5-1.64
            _box(shop,"BancadaOruga_%d" % bay,
                Vector3(track_x,0.35,track_z),
                Vector3(0.66,0.21,2.12),ARMOR_DARK,0.73,0.50)
            for wheel in range(5):
                var wz:float=track_z-0.76+float(wheel)*0.38
                _cylinder(shop,"RodilloOruga_%d_%d" % [bay,wheel],
                    Vector3(track_x,0.67,wz),0.19,0.13,
                    GALVANIZED,0.77,0.42,Vector3(0,0,90))
                _cylinder(shop,"BujeOruga_%d_%d" % [bay,wheel],
                    Vector3(track_x+0.076,0.67,wz),0.073,0.026,
                    ARMOR_DARK,0.78,0.45,Vector3(0,0,90))
            for side in [-1,1]:
                _box(shop,"CarrilOruga_%d_%d" % [bay,side],
                    Vector3(track_x,0.67+float(side)*0.205,track_z),
                    Vector3(0.18,0.055,2.05),BLACK,0.15,0.88)
        # Real crane carriage fasteners, rollers and lower hoist plate.
        if damage<=2:
            for side in [-1,1]:
                _cylinder(shop,"RodamientoGrua_%d_%d" % [bay,side],
                    Vector3(cx+float(side)*0.19,height-0.94,depth*0.12),
                    0.13,0.09,BRIGHT_STEEL,0.83,0.34,
                    Vector3(0,0,90))
            _box(shop,"PlacaGancho_%d" % bay,
                Vector3(cx,height-2.27,depth*0.12),
                Vector3(0.32,0.09,0.25),ARMOR_DARK,0.76,0.42)
        for position in [-1,1]:
            _box(shop,"LuzBancada_%d_%d" % [bay,position],
                Vector3(cx+float(position)*bw*0.35,
                    height-0.51,depth*0.02),
                Vector3(0.16,0.06,0.87),WORKLIGHT,0.09,0.18,
                Vector3.ZERO,damage<=1)
    # Service room is a real machine shop, not a supply depot.
    if damage<=1:
        var px:float=width*0.5-0.87
        _box(shop,"PrensaBase",
            Vector3(px,0.39,depth*0.5-3.02),
            Vector3(0.92,0.25,0.72),ARMOR_DARK,0.71,0.52)
        for side in [-1,1]:
            _box(shop,"PrensaColumna_%d" % side,
                Vector3(px+float(side)*0.38,1.19,depth*0.5-3.02),
                Vector3(0.11,1.46,0.13),GALVANIZED,0.82,0.41)
        _box(shop,"PrensaTravesano",
            Vector3(px,1.90,depth*0.5-3.02),
            Vector3(0.91,0.18,0.26),ARMOR,0.68,0.47)
        _cylinder(shop,"PrensaHusillo",
            Vector3(px,1.38,depth*0.5-3.02),
            0.115,0.80,BRIGHT_STEEL,0.83,0.35)

static func _wear(parent:Node3D,width:float,depth:float,
        damage:int,accent:Color) -> void:
    if damage==0:
        return
    var group:=_node(parent,"DesgasteFisicoV2")
    var n:int=3 if damage==1 else 8 if damage==2 else 15 if damage==3 else 23
    for i in range(n):
        var x:float=-width*0.38+float((i*5)%17)*width*0.047
        var z:float=-depth*0.38+float((i*7)%19)*depth*0.044
        _box(group,"RetazoDeAcero_%02d" % i,
            Vector3(x,0.095+float(i%2)*0.05,z),
            Vector3(0.30+float(i%3)*0.15,0.10,0.40+float(i%5)*0.11),
            RUST if i%3==0 else RUBBLE,
            0.54,0.88,Vector3(0,float(i*37),float(i%3)*8.0))
    if damage>=3:
        # Detached rafters and armored plating rest ON ground (not floating).
        for i in range(4):
            _box(group,"ArmaduraHundidaV2_%d" % i,
                Vector3(-width*0.23+float(i)*width*0.14,
                    0.16,-depth*0.24+float(i%2)*depth*0.24),
                Vector3(0.15,0.18,depth*0.29),ARMOR_DARK,0.70,0.78,
                Vector3(0,float(i*23),-10.0))
        _box(group,"CartelCaidoV2",
            Vector3(width*0.12,0.085,-depth*0.31),
            Vector3(1.48,0.08,0.52),accent.darkened(0.32),0.44,0.82)

static func build(level:int=1,faction:int=-1,damage:int=0) -> Node3D:
    if not valid(level,faction,damage):
        return null
    var model:Node3D=V1.build(level,faction,damage)
    if model==null:
        return null
    var width:float=9.5 if level==1 else 15.0 if level==2 else 20.5
    var depth:float=12.0 if level==1 else 15.0 if level==2 else 18.0
    var height:float=4.90 if level==1 else 6.10 if level==2 else 7.20
    var bays:int=level
    var accent:Color=Style.faction_color(faction) if faction>=0 else NEUTRAL
    var base_root:Node3D=model.get_node(STAGE) as Node3D
    # The inherited V1 D3 still kept an elevated roof over its middle bay
    # and an orphaned detached front beam. Remove those ONLY in V2, not in
    # the preserved V1 comparison source; V2 generates fallen fragments.
    if damage==3:
        for legacy_piece in ["CubiertaIndustrial","VigaFrontalDesprendida"]:
            var unsupported:Node=base_root.get_node_or_null(legacy_piece)
            if unsupported!=null:
                base_root.remove_child(unsupported)
                unsupported.free()
    var stage:Node3D=_node(base_root,FINISH_STAGE)
    _portal(stage,width,depth,height,bays,damage,accent)
    _wall_enclosure(stage,width,depth,height,damage,accent)
    _roof_finish(stage,width,depth,height,bays,damage)
    _machinery(stage,width,depth,height,bays,damage)
    _wear(stage,width,depth,damage,accent)
    model.name="TallerBlindados_V2_N%d_F%d_D%d" % [level,faction,damage]
    model.set_meta("workshop_art_version",2)
    model.set_meta("workshop_approved",false)
    model.set_meta("workshop_visual_finish","industriales_v2_opacos")
    return model

static func mesh_count(root:Node) -> int:
    return V1.mesh_count(root)
