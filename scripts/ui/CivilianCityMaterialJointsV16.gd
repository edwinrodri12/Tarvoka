extends RefCounted
class_name TarvokaCivilianCityMaterialJointsV16

# Visual sculpture, Godot 4.3 native 3D, not a texture overlay.
# Respects the identity established by V15 and every D0..D4 state.
# No economy/capture/ownership/collision/attack changes.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const V12=preload("res://scripts/ui/CivilianCityDamageFinishV12.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V15=preload("res://scripts/ui/CivilianCityIdentityV15.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV16EncuentrosMaterialesYFachadas"

const TERRA=Color("#b56c50")
const TERRA_DARK=Color("#85554a")
const TIMBER=Color("#7c614d")
const ASH=Color("#514847")
const WARM_STONE=Color("#cfc2aa")
const MORTAR=Color("#b4a690")
const BRICK=Color("#9d7564")
const CEMENT=Color("#9a9489")
const MARBLE=Color("#d1c6b2")
const ZINC=Color("#74858b")
const STEEL=Color("#62777e")
const GLASS=Color("#5d8591")
const BROKEN_GLASS=Color("#39525d")
const CHAR=Color("#3c4446")
const DUST=Color("#8b8176")

static func _part(parent: Node3D,name: String,p: Vector3,
        size: Vector3,color: Color,finish: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,name,p,size,color)
    mesh.material_override=V9._finish(color,finish)
    return mesh

static func _joint_strip(root: Node3D,name: String,
        at: Vector3,w: float,d: float,color: Color,
        material: String) -> void:
    # Physically sloped layered top and end-cap; avoid infinitely thin
    # rectangles in top-down inspection.
    var layer:=V14._sloped_slab(
        root,name,at,w,d,0.07,0.13,color)
    layer.material_override=V9._finish(color,material)

static func _villa_contacts(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int) -> void:
    var group:=V1._group(stage,"EncuentroCeramicaYAlfajiaV16_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # Ridge caps overlap the REAL V8/V15 pitched roof; the ridge
        # never floats alone above an exploded D2 roof.
        for face in [-1,1]:
            var zz: float=z+float(face)*d*0.45
            _joint_strip(group,
                "TejaRemateCeramicoVillaV16_%s_%d" % [tag,face],
                Vector3(x,h+0.60,zz),w*0.42,0.25,
                TERRA_DARK if damage==1 else TERRA,"ceramic")
            for side in [-1,1]:
                var xx: float=x+float(side)*w*0.39
                _part(group,
                    "AlfajiaEnMaderaVillaV16_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h+0.13,zz-float(face)*0.21),
                    Vector3(0.17,0.20,0.47),TIMBER)
        for side in [-1,1]:
            _part(group,"PiezaEsquinaPiedraVillaV16_%s_%d" % [tag,side],
                Vector3(x+float(side)*w*0.47,0.28,z-d*0.41),
                Vector3(0.30,0.38,0.28),WARM_STONE)
        if damage==1:
            _part(group,"JuntaMorteroErosionadaVillaV16_"+tag,
                Vector3(x-w*0.20,0.49,z+d*0.5+0.12),
                Vector3(0.50,0.09,0.10),DUST)
        return
    if damage==2:
        for side in [-1,1]:
            var sx: float=x+float(side)*w*0.31
            var tile:=_part(group,
                "TejaDelaminadaVillaV16_%s_%d" % [tag,side],
                Vector3(sx,h+0.40,z+d*0.21),
                Vector3(0.40,0.11,0.59),TERRA,"ceramic")
            tile.rotation_degrees.z=float(side)*16.0
            _part(group,"NudoVigaSujecionVillaV16_%s_%d" % [tag,side],
                Vector3(sx,h+0.05,z+d*0.30),
                Vector3(0.20,0.28,0.26),ASH)
        return
    # D3/D4: low debris never recreates intact timber walls.
    for i in range(4 if damage==3 else 5):
        var xx: float=x+(float(i%3)-1.0)*w*0.28
        var zz: float=z+(0.33 if i%2==0 else -0.34)*d
        var shard:=V12._rubble_wedge(group,
            "PerfilTejaCaidaVillaV16_%s_%d" % [tag,i],
            Vector3(xx,0.045,zz),
            Vector3(0.41,0.19 if damage==3 else 0.10,0.38),
            TERRA if i%2==0 else ASH)
        shard.material_override=V9._finish(
            TERRA if i%2==0 else ASH,
            "ceramic" if i%2==0 else "stone")

static func _town_contacts(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int) -> void:
    var group:=V1._group(stage,"MorteroCornisaCiudadV16_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # Three stepped ribbons make the brick and lime layer transition
        # readable from a raised tactical camera without recoloring the wall.
        for face in [-1,1]:
            var zz: float=z+float(face)*d*0.5
            _part(group,"BocelCornisaPiedraCiudadV16_%s_%d" % [tag,face],
                Vector3(x,h+0.43,zz+float(face)*0.15),
                Vector3(w*0.71,0.13,0.28),MARBLE)
            _part(group,"JuntaMorteroCornisaV16_%s_%d" % [tag,face],
                Vector3(x,h+0.28,zz+float(face)*0.15),
                Vector3(w*0.79,0.055,0.28),MORTAR)
            for side in [-1,1]:
                _part(group,
                    "SillarEsquinaCornisaV16_%s_%d_%d" %
                    [tag,face,side],
                    Vector3(x+float(side)*w*0.38,h+0.36,zz),
                    Vector3(0.24,0.20,0.33),WARM_STONE)
        if damage==1:
            _part(group,"FajaMorteroErosionadaCiudadV16_"+tag,
                Vector3(x-w*0.14,0.61,z+d*0.5+0.15),
                Vector3(0.56,0.11,0.08),DUST)
        return
    if damage==2:
        for face in [-1,1]:
            var zz: float=z+float(face)*d*0.5
            V11._broken_wall(group,
                "CornisaRotaMaterialCiudadV16_%s_%d" % [tag,face],
                Vector3(x,h-0.21,zz),
                Vector3(w*0.64,0,0),
                PackedFloat32Array([0.12,0.35,0.09,0.28,0.05]),
                BRICK,0.23)
            _part(group,"ApoyoPiedraRoturaCiudadV16_%s_%d" % [tag,face],
                Vector3(x-w*0.24,h-0.10,zz-float(face)*0.08),
                Vector3(0.44,0.30,0.31),WARM_STONE)
        return
    for i in range(4 if damage==3 else 5):
        var side: float=-1.0 if i%2==0 else 1.0
        var px: float=x+side*w*(0.19+float(i%3)*0.08)
        var pz: float=z+d*(0.32 if i%2==0 else -0.31)
        V12._rubble_wedge(group,
            "SillarSeparadoCiudadV16_%s_%d" % [tag,i],
            Vector3(px,0.044,pz),
            Vector3(0.43,0.24 if damage==3 else 0.13,0.38),
            BRICK if i%2==0 else MARBLE)

static func _metro_contacts(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int,
        accent: Color) -> void:
    var group:=V1._group(stage,"CerramientoMetalYVidrioV16_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # Real metal transoms and independent glass bands; preserve
        # V15 corner mullions instead of duplicating the whole facade.
        for face in [-1,1]:
            var zz: float=z+float(face)*(d*0.5+0.17)
            for side in [-1,1]:
                var xx: float=x+float(side)*w*0.42
                _part(group,
                    "CantoneraAluminioMetroV16_%s_%d_%d" %
                    [tag,face,side],
                    Vector3(xx,h*0.5,zz),
                    Vector3(0.10,h*0.88,0.085),ZINC,"steel")
            for f in range(floors):
                var yy: float=float(f)*2.10+1.74
                if yy>h-0.20:
                    continue
                _part(group,"TravesanoMetalMetroV16_%s_%d_%d" %
                    [tag,face,f],
                    Vector3(x,yy,zz),
                    Vector3(w*0.75,0.08,0.10),STEEL,"steel")
            _part(group,"RibeteVidrioTacticoMetroV16_%s_%d" % [tag,face],
                Vector3(x,h*0.76,zz+float(face)*0.035),
                Vector3(w*0.64,0.16,0.055),GLASS,"glass")
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.32
            _joint_strip(group,
                "TapajuntaCoronaMetroV16_%s_%d" % [tag,side],
                Vector3(xx,h+0.84,z+d*0.43),
                w*0.27,0.27,ZINC,"steel")
            _part(group,"DetalleColorMetroV16_%s_%d" % [tag,side],
                Vector3(xx,h+0.89,z+d*0.57),
                Vector3(w*0.18,0.075,0.09),accent,"steel")
        return
    if damage==2:
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.32
            var bent:=_part(group,
                "PerfilRetorcidoMetroV16_%s_%d" % [tag,side],
                Vector3(xx,h+0.23,z+d*0.41),
                Vector3(w*0.31,0.10,0.17),ZINC,"steel")
            bent.rotation_degrees.z=float(side)*17.0
            _part(group,"VidrioRotoSujetoMetroV16_%s_%d" % [tag,side],
                Vector3(xx,h+0.14,z+d*0.49),
                Vector3(w*0.21,0.18,0.06),BROKEN_GLASS,"glass")
        return
    # D3/D4: flat metallic shards visibly in the ground debris, no
    # tall ornamental skyline or panes suspended in the sky.
    for i in range(5):
        var xx: float=x+(float(i%3)-1.0)*w*0.25
        var zz: float=z+d*(0.29 if i%2==0 else -0.35)
        var height: float=0.22 if damage==3 else 0.13
        var glass:=V12._rubble_wedge(group,
            "CristalDesprendidoMetroV16_%s_%d" % [tag,i],
            Vector3(xx,0.037,zz),
            Vector3(0.42,height,0.41),
            BROKEN_GLASS if i%2==0 else STEEL)
        glass.material_override=V9._finish(
            BROKEN_GLASS if i%2==0 else STEEL,
            "glass" if i%2==0 else "steel")

static func _civic_junctions(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var group:=V1._group(stage,"LecturaAyuntamientoV16")
    var floors: int=2 if level==1 else 3 if level==2 else 4
    var h: float=float(floors)*2.10+0.21
    var front: float=-3.75-2.74*0.5
    if damage<=1:
        var tint: Color=(
            TERRA if level==1 else MARBLE if level==2 else ZINC)
        for side in [-1,1]:
            var x: float=float(side)*1.03
            _part(group,"CornisaCivicaTransicionV16_%d" % side,
                Vector3(x,h+0.35,front-0.14),
                Vector3(0.61,0.14,0.25),
                tint,"ceramic" if level==1 else
                "steel" if level==3 else "stone")
        return
    # On a ruined hall, the material remains as fragments anchored at
    # street-level, not on a fully preserved clock-tower.
    var count: int=2 if damage==2 else 3 if damage==3 else 4
    for i in range(count):
        var px: float=(float(i)-float(count-1)*0.5)*0.57
        var pz: float=front+0.29+float(i%2)*0.33
        var kind: Color=(
            TERRA if level==1 else BRICK if level==2 else STEEL)
        var shard:=V12._rubble_wedge(group,
            "DespieceArquitecturaCivilV16_%d" % i,
            Vector3(px,0.036,pz),
            Vector3(0.35,0.16 if damage<4 else 0.09,0.35),
            kind)
        shard.material_override=V9._finish(
            kind,"ceramic" if level==1 else
            "steel" if level==3 else "stone")
    if damage==2:
        _part(group,"UltimoFrisoMaterialAytoV16",
            Vector3(-0.48,0.17,front+0.68),
            Vector3(0.38,0.18,0.30),accent,"steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V15.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for south in [false,true]:
            var tag: String=("ResidencialSur_%d" % side
                if south else "ResidencialNorte_%d" % side)
            var z: float=3.62 if south else -3.80
            var w: float=2.77 if south else 2.74
            var d: float=2.80 if south else 2.84
            var floors: int=south_floors if south else north_floors
            match level:
                1:
                    _villa_contacts(stage,tag,x,z,w,d,floors,damage)
                2:
                    _town_contacts(stage,tag,x,z,w,d,floors,damage)
                3:
                    _metro_contacts(stage,tag,x,z,w,d,floors,damage,accent)
    _civic_junctions(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",16)
    stage.set_meta("finish",
        "ceramic-wood/stone-brick/metal-glass-material-transitions")
    stage.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",16)
    model.set_meta("city_model_approved_final",false)
    return true
