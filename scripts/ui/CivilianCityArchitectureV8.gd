extends RefCounted
class_name TarvokaCivilianCityArchitectureV8

# TARVOKA Civilian City V8: actual native 3D rear facades, volumetric
# side elevations and distinct inhabited rooftops. An additive ART layer.
# This is not another building type, factory, HQ or economy rule.
# South faces (+Z) are the REAR of the existing V1 building volumes.
# All elements stay within the original 15.8 x 12.6 city footprint.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const V3=preload("res://scripts/ui/CivilianCityPublicSpaceV3.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV8ArquitecturaPerimetralYAzoteas"

const STONE=Color("#d1c7b4")
const STUCCO=Color("#b8b5a6")
const DARK=Color("#354a50")
const METAL=Color("#607980")
const GLASS=Color("#527d8a")
const SHADOW=Color("#243740")
const BRICK=Color("#a17e70")
const ROOF=Color("#53646a")
const COPPER=Color("#8b785c")
const TIMBER=Color("#856f5a")
const LEAF=Color("#61866a")
const OCHRE=Color("#c9ab72")
const SCAR=Color("#78675f")
const BURNT=Color("#434343")

static func _box(parent: Node3D,name: String,at: Vector3,
        dims: Vector3,tint: Color,finish: String="stone") -> MeshInstance3D:
    return V1._box(parent,name,at,dims,tint,finish)

static func _post(parent: Node3D,name: String,at: Vector3,
        radius: float,height: float,tint: Color) -> void:
    V1._cylinder(parent,name,at,radius,height,tint,8)

static func _rear_window(parent: Node3D,tag: String,
        x: float,y: float,wall_z: float,
        w: float,damage: int,accent: Color,
        civic: bool=false) -> void:
    # Frame is PROUD of the south-facing masonry. No planar decal.
    var name: String="%s_%s" % [tag,str(roundi(x*100.0))]
    var glass: Color=GLASS if damage<2 else BURNT
    _box(parent,"MarcoPosteriorV8_"+name,Vector3(x,y,wall_z+0.065),
        Vector3(w+0.16,1.00,0.13),STONE if civic else DARK)
    if damage==2:
        # The damaged version has a deep, shattered aperture, no intact pane.
        _box(parent,"HuecoAhumadoV8_"+name,
            Vector3(x,y,wall_z+0.141),
            Vector3(w*0.84,0.76,0.045),SHADOW)
        _box(parent,"FragmentoVidrioV8_"+name,
            Vector3(x-w*0.28,y-0.27,wall_z+0.172),
            Vector3(w*0.23,0.20,0.028),SCAR,"glass")
    else:
        _box(parent,"CristalPosteriorV8_"+name,
            Vector3(x,y,wall_z+0.149),
            Vector3(w,0.83,0.047),glass,"glass")
        _box(parent,"MontantePosteriorV8_"+name,
            Vector3(x,y,wall_z+0.183),
            Vector3(0.055,0.82,0.059),METAL,"metal")
        _box(parent,"TravesanoPosteriorV8_"+name,
            Vector3(x,y+0.09,wall_z+0.185),
            Vector3(w,0.047,0.058),METAL,"metal")
    _box(parent,"AlfeizarPosteriorV8_"+name,
        Vector3(x,y-0.55,wall_z+0.21),
        Vector3(w+0.28,0.11,0.32),STONE)
    if civic and damage<2:
        _box(parent,"DovelaCivicaV8_"+name,
            Vector3(x,y+0.61,wall_z+0.092),
            Vector3(w+0.19,0.14,0.18),accent)

static func _residential_rear(stage: Node3D,tag: String,
        x: float,z: float,width: float,depth: float,
        floors: int,level: int,damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var group:=V1._group(stage,"FachadaPosteriorHabitadaV8_"+tag)
    var wall_z: float=z+depth*0.5+0.035
    var shop: bool=level>=2 and z<0.0
    # Two real, recessed-feeling window bays per inhabited floor.
    # Skip the ground-floor house windows wherever a storefront opens.
    for floor_index in range(floors):
        if shop and floor_index==0:
            continue
        if damage==2 and floor_index%2==1:
            continue
        var y: float=1.06+float(floor_index)*2.10
        for side in [-1,1]:
            var wx: float=x+float(side)*width*0.29
            _rear_window(group,"%s_P%d_E%d" %
                [tag,floor_index,side],wx,y,wall_z,0.55,
                damage,accent)
    # Door and entry volume face the road from the previously blank rear.
    var door_x: float=x
    _box(group,"PortonTraseroV8_"+tag,
        Vector3(door_x,0.96,wall_z+0.102),
        Vector3(0.82,1.82,0.12),DARK,"metal")
    _box(group,"DintelAccesoPosteriorV8_"+tag,
        Vector3(door_x,1.96,wall_z+0.15),
        Vector3(1.02,0.17,0.27),STONE)
    _box(group,"EscalonAccesoV8_"+tag,
        Vector3(door_x,0.10,wall_z+0.40),
        Vector3(1.04,0.17,0.65),STONE)
    if shop:
        # A street-facing shop is a civic/commercial façade, NOT a factory.
        for side in [-1,1]:
            var sx: float=x+float(side)*width*0.305
            _box(group,"EscaparatePosteriorV8_%s_%d" % [tag,side],
                Vector3(sx,1.02,wall_z+0.124),
                Vector3(0.50,1.20,0.065),
                GLASS if damage<2 else SHADOW,"glass")
            _box(group,"ParteluzComercioV8_%s_%d" % [tag,side],
                Vector3(sx,1.02,wall_z+0.176),
                Vector3(0.056,1.23,0.057),METAL,"metal")
        _box(group,"MarquesinaContinuaV8_"+tag,
            Vector3(x,2.20,wall_z+0.40),
            Vector3(width+0.16,0.14,0.83),
            TIMBER if damage==2 else COPPER)
        _box(group,"FranjaComercialV8_"+tag,
            Vector3(x,2.04,wall_z+0.17),
            Vector3(width*0.73,0.16,0.13),
            SCAR if damage==2 else accent,"metal")
    elif level==1 and damage==0:
        # Villa: handmade wood shutters and a small covered doorstep.
        for side in [-1,1]:
            var wx: float=x+float(side)*width*0.29
            for edge in [-1,1]:
                _box(group,"ContraventanaVillaV8_%s_%d_%d" %
                    [tag,side,edge],
                    Vector3(wx+float(edge)*0.34,1.06,wall_z+0.175),
                    Vector3(0.115,0.91,0.12),TIMBER)
        _box(group,"AleroPuertaVillaV8_"+tag,
            Vector3(x,2.04,wall_z+0.39),
            Vector3(1.42,0.13,0.81),ROOF)

static func _side_elevation(stage: Node3D,tag: String,x: float,
        z: float,width: float,depth: float,floors: int,
        level: int,damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var group:=V1._group(stage,"AlzadosLateralesV8_"+tag)
    # Both side elevations are genuinely modeled (not reflected decals).
    for side in [-1,1]:
        var face_x: float=x+float(side)*(width*0.5+0.052)
        for floor_index in range(floors):
            if damage==2 and floor_index%2==0:
                continue
            var y: float=1.16+float(floor_index)*2.10
            for bay in [-1,1]:
                var rz: float=z+float(bay)*depth*0.23
                _box(group,"MarcoCostadoV8_%s_%d_%d_%d" %
                    [tag,side,floor_index,bay],
                    Vector3(face_x,y,rz),
                    Vector3(0.15,0.87,0.52),STONE)
                _box(group,"CristalCostadoV8_%s_%d_%d_%d" %
                    [tag,side,floor_index,bay],
                    Vector3(face_x+float(side)*0.083,y,rz),
                    Vector3(0.042,0.70,0.40),
                    GLASS if damage<2 else BURNT,"glass")
                if level>=2 and damage<2:
                    _box(group,"AlfeizarCostadoV8_%s_%d_%d_%d" %
                        [tag,side,floor_index,bay],
                        Vector3(face_x+float(side)*0.12,y-0.48,rz),
                        Vector3(0.31,0.085,0.64),STONE)
        if level>=2 and damage<=1 and tag.begins_with("Residencial"):
            # Escape landing is vertical side architecture, not a loose
            # square intersecting the vehicle lane in the middle of town.
            var y: float=2.21 if level==2 else 4.31
            var landing_x: float=face_x+float(side)*0.21
            _box(group,"PlataformaEvacuacionV8_%s_%d" % [tag,side],
                Vector3(landing_x,y,z+depth*0.15),
                Vector3(0.51,0.11,1.10),METAL,"metal")
            _box(group,"BarandaEvacuacionV8_%s_%d" % [tag,side],
                Vector3(landing_x+float(side)*0.24,y+0.45,z+depth*0.15),
                Vector3(0.075,0.86,1.11),DARK,"metal")
            _box(group,"EscaleraEvacuacionV8_%s_%d" % [tag,side],
                Vector3(landing_x,y-0.72,z+depth*0.46),
                Vector3(0.11,1.47,0.12),METAL,"metal")
    # Continuous material band makes the side wall read as constructed,
    # even when windows are culled at tactical LOD.
    if damage<=1:
        for side in [-1,1]:
            _box(group,"CornisaLateralV8_%s_%d" % [tag,side],
                Vector3(x+float(side)*(width*0.5+0.055),
                    float(floors)*2.10-0.11,z),
                Vector3(0.20,0.23,depth+0.19),
                accent if level==3 else STONE)

static func _villa_roof(stage: Node3D,tag: String,x: float,z: float,
        depth: float,h: float,damage: int) -> void:
    if damage!=0:
        return
    var group:=V1._group(stage,"VentanasBuhardillaVillaV8_"+tag)
    # Two real dormers rise through the existing sloping terracotta roof.
    for side in [-1,1]:
        var px: float=x+float(side)*0.51
        _box(group,"BuhardillaVillaV8_%s_%d" % [tag,side],
            Vector3(px,h+0.52,z-depth*0.26),
            Vector3(0.63,0.58,0.50),STUCCO)
        _box(group,"CristalBuhardillaV8_%s_%d" % [tag,side],
            Vector3(px,h+0.55,z-depth*0.26-0.27),
            Vector3(0.41,0.36,0.063),GLASS,"glass")
        var canopy:=_box(group,"TejadilloBuhardillaV8_%s_%d" %
            [tag,side],
            Vector3(px,h+0.88,z-depth*0.27),
            Vector3(0.76,0.12,0.62),ROOF)
        canopy.rotation_degrees.x=-9.0
        _box(group,"MarcoBuhardillaV8_%s_%d" % [tag,side],
            Vector3(px,h+0.55,z-depth*0.26-0.32),
            Vector3(0.52,0.47,0.058),TIMBER)

static func _town_roof(stage: Node3D,tag: String,x: float,z: float,
        width: float,depth: float,h: float,
        damage: int,accent: Color) -> void:
    if damage>1:
        return
    var group:=V1._group(stage,"CubiertaServiciosCiudadV8_"+tag)
    # Small stairwell protrusion and a real circular water tank with
    # articulated rim and independent supports.
    var sx: float=x+width*0.14
    var sz: float=z+depth*0.16
    _box(group,"CasetaAccesoAzoteaV8_"+tag,
        Vector3(sx,h+0.63,sz),
        Vector3(0.74,0.75,0.84),STUCCO)
    _box(group,"CubiertaCasetaV8_"+tag,
        Vector3(sx,h+1.03,sz),
        Vector3(0.88,0.12,0.95),ROOF,"metal")
    var tx: float=x-width*0.26
    var tz: float=z+depth*0.14
    _post(group,"DepositoAguaV8_"+tag,
        Vector3(tx,h+0.64,tz),0.31,0.61,DARK)
    _box(group,"TapaDepositoV8_"+tag,
        Vector3(tx,h+0.98,tz),
        Vector3(0.76,0.09,0.76),METAL,"metal")
    for side in [-1,1]:
        _box(group,"SoporteDepositoV8_%s_%d" % [tag,side],
            Vector3(tx+float(side)*0.22,h+0.29,tz),
            Vector3(0.09,0.20,0.10),METAL,"metal")
    if damage==0:
        _box(group,"FranjaRemateAzoteaV8_"+tag,
            Vector3(x,h+0.32,z+depth*0.5+0.07),
            Vector3(width*0.89,0.14,0.16),accent,"metal")

static func _metropolis_roof(stage: Node3D,tag: String,x: float,z: float,
        width: float,depth: float,h: float,
        damage: int,accent: Color) -> void:
    if damage>1:
        return
    var group:=V1._group(stage,"CoronacionTerrazasMetropoliV8_"+tag)
    # Rooftop relief stays clear of the already-approved central terrace.
    # Thin photovoltaic slabs form an unmistakable civilian skyline.
    for side in [-1,1]:
        var sx: float=x+float(side)*width*0.37
        var solar:=_box(group,"PanelSolarV8_%s_%d" % [tag,side],
            Vector3(sx,h+0.56,z-depth*0.10),
            Vector3(0.62,0.075,1.27),GLASS,"glass")
        solar.rotation_degrees.x=-13.0
        _box(group,"BastidorSolarV8_%s_%d" % [tag,side],
            Vector3(sx,h+0.37,z-depth*0.12),
            Vector3(0.10,0.25,0.74),METAL,"metal")
    _box(group,"RemateEscalonadoV8_"+tag,
        Vector3(x,h+0.46,z+depth*0.5+0.02),
        Vector3(width*0.79,0.33,0.20),DARK,"metal")
    _box(group,"FranjaRemateMetropolitanoV8_"+tag,
        Vector3(x,h+0.64,z+depth*0.5+0.02),
        Vector3(width*0.70,0.10,0.22),
        SCAR if damage==1 else accent,"metal")
    if damage==0:
        _post(group,"BalizaCivicaV8_"+tag,
            Vector3(x,h+0.95,z+depth*0.29),
            0.07,0.49,OCHRE)

static func _civic_rear(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var group:=V1._group(stage,"AyuntamientoPosteriorCivilV8")
    var x: float=0.0
    var z: float=-3.75
    var depth: float=2.74
    var wall_z: float=z+depth*0.5+0.035
    var floors: int=2 if level==1 else 3 if level==2 else 4
    for floor_index in range(floors):
        if damage==2 and floor_index>1:
            continue
        var wy: float=1.18+float(floor_index)*2.10
        for side in [-1,1]:
            var wx: float=float(side)*1.04
            # Preserve the central V3 public doorway and its canopy.
            if floor_index==0:
                _box(group,"PilastraMunicipalV8_%d" % side,
                    Vector3(float(side)*1.35,1.11,wall_z+0.10),
                    Vector3(0.23,2.20,0.26),STONE)
                continue
            _rear_window(group,"Ayto_%d_%d" %
                [floor_index,side],wx,wy,wall_z,0.53,
                damage,accent,true)
    if damage<=1:
        _box(group,"EntablamentoMunicipalPosteriorV8",
            Vector3(0.0,float(floors)*2.10-0.28,wall_z+0.12),
            Vector3(3.52,0.31,0.26),STONE)
        for side in [-1,1]:
            _box(group,"FranjaCivicaPosteriorV8_%d" % side,
                Vector3(float(side)*1.23,
                    float(floors)*2.10+0.40,wall_z+0.09),
                Vector3(0.25,0.74,0.20),
                accent if level==3 else COPPER,"metal")
        if level>=2:
            _box(group,"RemateTorreCivicaV8",
                Vector3(0.0,float(floors)*2.10+1.55,-3.75),
                Vector3(1.49,0.24,1.37),ROOF,"metal")
    else:
        _box(group,"CornisaMunicipalQuebradaV8",
            Vector3(-0.65,float(floors)*2.10-0.35,wall_z+0.12),
            Vector3(0.89,0.22,0.25),SCAR)

static func _damage_silhouette(stage: Node3D,level: int,
        damage: int) -> void:
    if damage<2:
        return
    var group:=V1._group(stage,"CicatricesUrbanasV8")
    # Damage 2 gets broken lintels only; 3/4 keep ONLY collapsed shapes,
    # never floating pristine windows or intact rooftop installations.
    for side in [-1,1]:
        var x: float=float(side)*4.63
        var y: float=0.48 if damage>=3 else 1.53
        var z: float=3.62 if side==1 else -3.80
        _box(group,"MamposteriaFracturadaV8_%d" % side,
            Vector3(x+float(side)*0.46,y,z+0.77),
            Vector3(0.69,0.30 if damage==4 else 0.41,0.39),
            SCAR if damage<=3 else BURNT)
        if damage>=3:
            for i in range(2):
                var fragment:=_box(group,
                    "CascoteAngularV8_%d_%d" % [side,i],
                    Vector3(x+float(i)*0.47-0.28,
                        0.30+float(i)*0.13,z+0.99),
                    Vector3(0.54,0.27,0.44),
                    BRICK if i==0 else BURNT)
                fragment.rotation_degrees.y=float(side)*(
                    19.0+float(i)*17.0)
    if level==3 and damage>=3:
        _box(group,"RestosCoronaMetropoliV8",
            Vector3(0.55,0.35,-2.45),
            Vector3(1.31,0.31,0.48),BURNT)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V1.STAGE_NAME)
            or not model.has_node(V2.STAGE_NAME)
            or not model.has_node(V3.STAGE_NAME)
            or model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(
        Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var rear_floors: int=1 if level==1 else 2 if level==2 else 4
    var front_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        var north: String="ResidencialNorte_%d" % side
        var south: String="ResidencialSur_%d" % side
        _residential_rear(stage,north,x,-3.80,2.74,2.84,
            rear_floors,level,damage,accent)
        _residential_rear(stage,south,x,3.62,2.77,2.80,
            front_floors,level,damage,accent)
        _side_elevation(stage,north,x,-3.80,2.74,2.84,
            rear_floors,level,damage,accent)
        _side_elevation(stage,south,x,3.62,2.77,2.80,
            front_floors,level,damage,accent)
        if damage<2:
            for front in [false,true]:
                var tag: String=south if front else north
                var z: float=3.62 if front else -3.80
                var w: float=2.77 if front else 2.74
                var d: float=2.80 if front else 2.84
                var floors: int=front_floors if front else rear_floors
                var h: float=float(floors)*2.10+0.21
                if level==1:
                    _villa_roof(stage,tag,x,z,d,h,damage)
                elif level==2:
                    _town_roof(stage,tag,x,z,w,d,h,damage,accent)
                else:
                    _metropolis_roof(stage,tag,x,z,w,d,h,damage,accent)
    _civic_rear(stage,level,damage,accent)
    _damage_silhouette(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",8)
    stage.set_meta("architecture","inhabited-rear-and-side-elevations")
    stage.set_meta("roof_profile",
        "dormer" if level==1 else
        "service-tank" if level==2 else "metropolitan-terraces")
    stage.set_meta("damage",damage)
    stage.set_meta("faction",faction)
    model.set_meta("city_architecture_stage",8)
    return true
