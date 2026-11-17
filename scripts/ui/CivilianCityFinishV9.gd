extends RefCounted
class_name TarvokaCivilianCityFinishV9

# CIVILIAN CITY V9 — physical junctions, material relief and roof weathering.
# Additive, editable Godot 4.3 sculpt on V1-V4 + V8 architecture.
# This remains artwork-in-progress. It creates no new tactical properties.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const V3=preload("res://scripts/ui/CivilianCityPublicSpaceV3.gd")
const V8=preload("res://scripts/ui/CivilianCityArchitectureV8.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV9RematesEncuentrosYMaterialidad"

const LIMESTONE=Color("#c9c0aa")
const STUCCO=Color("#b6b2a5")
const BRICK=Color("#9e7568")
const MORTAR=Color("#c9b3a1")
const COPPER=Color("#85795f")
const OXIDE=Color("#5e857d")
const SLATE=Color("#45545c")
const ZINC=Color("#879498")
const ALUMINUM=Color("#627e85")
const GLASS=Color("#4c7c8b")
const SHADOW=Color("#28383e")
const AGED=Color("#746e65")
const SCORCH=Color("#3e4242")
const WARM=Color("#d1bd91")
const TIMBER=Color("#786755")
static var _finish_cache: Dictionary={}

static func _finish(tint: Color,surface: String) -> StandardMaterial3D:
    var key: String=tint.to_html(true)+"/"+surface
    if _finish_cache.has(key):
        return _finish_cache[key] as StandardMaterial3D
    var material:=StandardMaterial3D.new()
    material.albedo_color=tint
    match surface:
        "ceramic":
            material.roughness=0.83
            material.metallic=0.0
        "stone":
            material.roughness=0.91
            material.metallic=0.01
        "glass":
            material.roughness=0.18
            material.metallic=0.04
        "copper":
            material.roughness=0.55
            material.metallic=0.68
        "oxidized":
            material.roughness=0.76
            material.metallic=0.25
        "steel":
            material.roughness=0.41
            material.metallic=0.61
        "rubber":
            material.roughness=0.95
            material.metallic=0.0
        _:
            material.roughness=0.80
            material.metallic=0.02
    _finish_cache[key]=material
    return material

static func _part(root: Node3D,label: String,
        position: Vector3,size: Vector3,color: Color,
        material: String="stone") -> MeshInstance3D:
    var node: MeshInstance3D=V1._box(
        root,label,position,size,color)
    node.material_override=_finish(color,material)
    return node

static func _pipe(root: Node3D,label: String,
        position: Vector3,radius: float,length: float,
        tint: Color,material: String="steel") -> MeshInstance3D:
    var node: MeshInstance3D=V1._cylinder(
        root,label,position,radius,length,tint,10)
    node.material_override=_finish(tint,material)
    return node

static func _joint_gutters(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        height: float,level: int,damage: int) -> void:
    if damage>=3:
        return
    var junction:=V1._group(root,"JuntasCanalonesV9_"+tag)
    var front: float=z-d*0.5
    var rear: float=z+d*0.5
    # Copper/Zinc sheet edges are physically contiguous with the roof
    # perimeter; downpipes join at the corners rather than float in space.
    var tint: Color=COPPER if level==1 else ZINC if level==2 else ALUMINUM
    var finish: String="copper" if level==1 else "steel"
    for side in [-1,1]:
        var face_z: float=front-0.18 if side==-1 else rear+0.18
        var gutter:=_part(junction,
            "CanalonCoronacionV9_%s_%d" % [tag,side],
            Vector3(x,height+0.13,face_z),
            Vector3(w+0.44,0.095,0.21),tint,finish)
        if level==1:
            gutter.rotation_degrees.x=float(side)*4.0
        if damage==2 and side==1:
            gutter.rotation_degrees.z=-8.0
        for edge in [-1,1]:
            var anchor_x: float=x+float(edge)*(w*0.45)
            _part(junction,
                "AbrazaderaCanalonV9_%s_%d_%d" % [tag,side,edge],
                Vector3(anchor_x,height+0.075,face_z),
                Vector3(0.12,0.14,0.28),AGED,"steel")
    # One gutter return bends into a vertical pipe. At cosmetic damage 2
    # the upper return is visibly disconnected (not magically repaired).
    var pipe_x: float=x+w*0.5+0.13
    var pipe_z: float=rear+0.16
    var low: float=0.40
    var high: float=height+0.10
    if damage==2:
        high=height*0.68
    _pipe(junction,"BajantePluvialV9_"+tag,
        Vector3(pipe_x,(low+high)*0.5,pipe_z),
        0.065,high-low,tint,finish)
    _part(junction,"CodoBajanteV9_"+tag,
        Vector3(pipe_x-0.10,high,pipe_z),
        Vector3(0.30,0.13,0.15),tint,finish)
    for floor_index in range(1,level+2):
        var y: float=float(floor_index)*1.20
        if y>=high:
            continue
        _part(junction,
            "GrapaBajanteV9_%s_%d" % [tag,floor_index],
            Vector3(pipe_x-0.05,y,pipe_z),
            Vector3(0.12,0.10,0.18),AGED,"steel")
    if damage==0:
        _part(junction,"BocaPluvialV9_"+tag,
            Vector3(pipe_x,0.36,pipe_z+0.18),
            Vector3(0.18,0.13,0.41),SHADOW,"steel")

static func _villa_masonry(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        height: float,damage: int) -> void:
    if damage>=3:
        return
    var joint:=V1._group(root,"LadrilloYTejaVillaV9_"+tag)
    var rear: float=z+d*0.5+0.079
    # Staggered brick returns and dry-stone sill courses on the corners
    # make the side-to-rear seam read as built masonry, not overlapping boxes.
    for side in [-1,1]:
        var bx: float=x+float(side)*(w*0.5+0.084)
        for row in range(4):
            if damage==2 and row>1:
                continue
            var y: float=0.42+float(row)*0.40
            _part(joint,"HiladaEsquinaV9_%s_%d_%d" %
                [tag,side,row],
                Vector3(bx,y,rear-0.16),
                Vector3(0.19,0.14,0.40),
                BRICK if row%2==0 else MORTAR,"ceramic")
        _part(joint,"ZocaloEsquinaVillaV9_%s_%d" % [tag,side],
            Vector3(bx,0.25,z),
            Vector3(0.20,0.38,d+0.18),LIMESTONE)
    if damage<=1:
        for roof_side in [-1,1]:
            var rz: float=z+float(roof_side)*d*0.31
            _part(joint,
                "RemateTejaBordeVillaV9_%s_%d" % [tag,roof_side],
                Vector3(x,height+0.43,rz),
                Vector3(w+0.43,0.12,0.18),
                OXIDE if damage==1 else COPPER,"ceramic")
        # Lead/copper flashing closes the seam between each dormer
        # sculpted in V8 and the sloping roof beneath it.
        if damage==0:
            for bay in [-1,1]:
                _part(joint,
                    "BaberoBuhardillaV9_%s_%d" % [tag,bay],
                    Vector3(x+float(bay)*0.51,
                        height+0.25,z-d*0.26-0.26),
                    Vector3(0.83,0.08,0.29),COPPER,"copper")
    if damage==2:
        var crack:=_part(joint,"JuntaAbiertaVillaV9_"+tag,
            Vector3(x+w*0.46,1.17,rear+0.01),
            Vector3(0.11,1.25,0.08),SCORCH,"stone")
        crack.rotation_degrees.z=19.0

static func _city_masonry(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        height: float,damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var joint:=V1._group(root,"RematePiedraYComercioV9_"+tag)
    var rear: float=z+d*0.5
    var front: float=z-d*0.5
    # Continuous parapet joints meet corner posts and turn the rooftop
    # into a coherent volume. They deliberately avoid glazing.
    if damage<=1:
        for side in [-1,1]:
            var px: float=x+float(side)*(w*0.5+0.035)
            _part(joint,
                "MachoEsquinaPiedraV9_%s_%d" % [tag,side],
                Vector3(px,height*0.52,rear+0.064),
                Vector3(0.18,height*0.96,0.23),LIMESTONE)
            _part(joint,
                "PiezaCoronaEsquinaV9_%s_%d" % [tag,side],
                Vector3(px,height+0.39,rear+0.065),
                Vector3(0.30,0.17,0.35),ZINC,"steel")
        _part(joint,"VigaCoronaPosteriorV9_"+tag,
            Vector3(x,height+0.35,rear+0.08),
            Vector3(w+0.15,0.20,0.24),STUCCO)
        _part(joint,"VigaCoronaFrontalV9_"+tag,
            Vector3(x,height+0.35,front-0.08),
            Vector3(w+0.15,0.20,0.24),STUCCO)
        for bay in [-1,1]:
            # Physical counterflashing between the door awnings and facade.
            _part(joint,
                "TapajuntaMarquesinaV9_%s_%d" % [tag,bay],
                Vector3(x+float(bay)*w*0.29,
                    2.22,rear+0.21),
                Vector3(w*0.33,0.11,0.20),
                COPPER if damage==0 else AGED,"copper")
        _part(joint,"BandaIdentidadCiudadV9_"+tag,
            Vector3(x,height-0.31,rear+0.154),
            Vector3(w*0.62,0.15,0.09),accent,"steel")
    else:
        _part(joint,"RemateParapetoRotoV9_"+tag,
            Vector3(x-w*0.23,height+0.21,rear+0.10),
            Vector3(w*0.41,0.18,0.25),AGED)

static func _metropolis_glazing(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,height: float,damage: int,
        accent: Color) -> void:
    if damage>=3:
        return
    var joint:=V1._group(root,"VidrioCerchasYCoronasV9_"+tag)
    var rear: float=z+d*0.5+0.061
    # Restrained civilian office/residential facade: narrow vertical glass
    # corners and REAL metal spandrels between V8 window floors.
    if damage<=1:
        for side in [-1,1]:
            var px: float=x+float(side)*w*0.475
            _part(joint,"EsquinaVidriadaV9_%s_%d" % [tag,side],
                Vector3(px,height*0.53,rear+0.056),
                Vector3(0.16,height*0.86,0.085),
                GLASS,"glass")
            _part(joint,"PerfilAluminioV9_%s_%d" % [tag,side],
                Vector3(px+float(side)*0.12,height*0.53,
                    rear+0.069),
                Vector3(0.09,height*0.90,0.13),ALUMINUM,"steel")
        for floor_index in range(1,floors):
            var y: float=float(floor_index)*2.10+0.02
            _part(joint,"FajaEntrePisosV9_%s_%d" %
                [tag,floor_index],
                Vector3(x,y,rear+0.105),
                Vector3(w*0.64,0.14,0.11),
                SHADOW if floor_index%2==0 else ALUMINUM,"steel")
        # Crown attaches to front/rear parapets instead of appearing
        # as a freestanding slab on the solar roof.
        for face in [-1,1]:
            var zz: float=z+float(face)*(d*0.5+0.052)
            _part(joint,"VigaCoronaMetropolitanaV9_%s_%d" %
                [tag,face],
                Vector3(x,height+0.37,zz),
                Vector3(w+0.24,0.22,0.19),SLATE,"steel")
            _part(joint,"FiloCoronaMetropolitanaV9_%s_%d" %
                [tag,face],
                Vector3(x,height+0.54,zz),
                Vector3(w*0.72,0.083,0.19),
                accent if damage==0 else AGED,"steel")
        for panel in [-1,1]:
            # V8 solar slabs gain a continuous structural frame and cable.
            var px: float=x+float(panel)*w*0.37
            _part(joint,"CostillaPanelSolarV9_%s_%d" %
                [tag,panel],
                Vector3(px,height+0.33,z-d*0.10),
                Vector3(0.10,0.31,1.12),ALUMINUM,"steel")
    else:
        _part(joint,"GrietaJuntaMetropolitanaV9_"+tag,
            Vector3(x+w*0.34,height*0.73,rear+0.124),
            Vector3(0.14,1.27,0.10),SCORCH)

static func _municipal_finish(root: Node3D,
        level: int,damage: int,accent: Color) -> void:
    # Municipality keeps a recognizable public identity on all city tiers.
    var civic:=V1._group(root,"AyuntamientoPiedraYRematesV9")
    var h: float=float(2 if level==1 else 3 if level==2 else 4)*2.10+0.21
    var south: float=-3.75+2.74*0.5
    var north: float=-3.75-2.74*0.5
    if damage>=3:
        _part(civic,"ClaveMunicipalDerribadaV9",
            Vector3(0.52,0.24,-2.16),
            Vector3(0.45,0.27,0.34),SCORCH)
        return
    if damage==2:
        _part(civic,"CornisaMunicipalAstilladaV9",
            Vector3(-0.47,h-0.29,south+0.13),
            Vector3(1.11,0.22,0.27),AGED)
        return
    for side in [-1,1]:
        var px: float=float(side)*1.53
        _part(civic,"PilastraMunicipalDelanteraV9_%d" % side,
            Vector3(px,1.53,north-0.125),
            Vector3(0.22,2.94,0.19),LIMESTONE)
        _part(civic,"PilastraMunicipalTraseraV9_%d" % side,
            Vector3(px,1.53,south+0.15),
            Vector3(0.22,2.94,0.19),LIMESTONE)
    # A protected canopy flashing closes V3's civic south entrance.
    _part(civic,"RemateMarquesinaMunicipalV9",
        Vector3(0.0,2.55,south+0.40),
        Vector3(2.02,0.11,0.90),OXIDE,"copper")
    _part(civic,"JuntaCubiertaAyuntamientoV9",
        Vector3(0.0,h+0.30,south+0.035),
        Vector3(3.69,0.14,0.27),LIMESTONE)
    _part(civic,"FrisoAyuntamientoV9",
        Vector3(0.0,h-0.48,south+0.18),
        Vector3(2.26,0.20,0.07),accent,"steel")
    if level>=2:
        # Surround the existing V1 clock face, without drawing over it.
        _part(civic,"DintelTorreRelojV9",
            Vector3(0.0,h+1.05,-3.75-0.59),
            Vector3(1.32,0.12,0.18),COPPER,"copper")
        for side in [-1,1]:
            _part(civic,"JambaTorreRelojV9_%d" % side,
                Vector3(float(side)*0.61,h+0.75,-4.34),
                Vector3(0.10,0.67,0.16),LIMESTONE)
    if level==3:
        for side in [-1,1]:
            _part(civic,"PiezaCoronaCivicaV9_%d" % side,
                Vector3(float(side)*1.27,h+0.61,south+0.035),
                Vector3(0.31,0.34,0.28),SLATE,"steel")

static func _ruin_finish(root: Node3D,level: int,
        damage: int) -> void:
    if damage<2:
        return
    var fragments:=V1._group(root,"DesgasteMaterialYRoturasV9")
    for side in [-1,1]:
        var sx: float=float(side)*4.63
        var z: float=-3.80 if side==-1 else 3.62
        if damage==2:
            # Mortar fractures are embedded in the surviving wall,
            # not intact glass placed on a devastated structure.
            var seam:=_part(fragments,
                "FisuraMamposteriaV9_%d" % side,
                Vector3(sx+float(side)*1.37,1.23,z+1.44),
                Vector3(0.08,1.65,0.14),SCORCH,"stone")
            seam.rotation_degrees.z=float(side)*18.0
        else:
            for index in range(3):
                var part:=_part(fragments,
                    "RestosPiedraV9_%d_%d" % [side,index],
                    Vector3(sx+float(index)*0.38-0.30,
                        0.17+float(index%2)*0.13,
                        z+1.22+float(index%2)*0.31),
                    Vector3(0.52,0.28,0.37),
                    BRICK if index==0 else SCORCH)
                part.rotation_degrees.y=float(index)*18.0
    if damage>=3 and level==3:
        _part(fragments,"PanelCoronaDobladoV9",
            Vector3(0.66,0.37,-2.24),
            Vector3(1.22,0.15,0.35),OXIDE,"oxidized")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V1.STAGE_NAME)
            or not model.has_node(V2.STAGE_NAME)
            or not model.has_node(V3.STAGE_NAME)
            or not model.has_node(V8.STAGE_NAME)
            or model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var layer:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    if damage<=2:
        for side in [-1,1]:
            var x: float=float(side)*4.63
            for south in [false,true]:
                var tag: String=("ResidencialSur_%d" % side
                    if south else "ResidencialNorte_%d" % side)
                var z: float=3.62 if south else -3.80
                var w: float=2.77 if south else 2.74
                var d: float=2.80 if south else 2.84
                var floors: int=south_floors if south else north_floors
                var h: float=float(floors)*2.10+0.21
                _joint_gutters(layer,tag,x,z,w,d,h,level,damage)
                match level:
                    1:
                        _villa_masonry(layer,tag,x,z,w,d,h,damage)
                    2:
                        _city_masonry(layer,tag,x,z,w,d,h,
                            damage,accent)
                    3:
                        _metropolis_glazing(layer,tag,x,z,w,d,
                            floors,h,damage,accent)
    _municipal_finish(layer,level,damage,accent)
    _ruin_finish(layer,level,damage)
    layer.set_meta("visual_only",true)
    layer.set_meta("no_gameplay_changes",true)
    layer.set_meta("design_stage",9)
    layer.set_meta("finish","roof-wall-joints-facade-relief-and-materials")
    layer.set_meta("damage",damage)
    layer.set_meta("faction",faction)
    model.set_meta("city_architectural_finish_stage",9)
    return true
