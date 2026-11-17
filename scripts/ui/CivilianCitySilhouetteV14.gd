extends RefCounted
class_name TarvokaCivilianCitySilhouetteV14

# TARVOKA CIVILIAN CITY — V14: 360 DEGREE ARCHITECTURAL SILHOUETTE.
# Actual three-dimensional Godot meshes; the state remains ART WIP.
# Works on the real V1-V4 + V8-V13 scene and does not touch city economy.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const V12=preload("res://scripts/ui/CivilianCityDamageFinishV12.gd")
const V13=preload("res://scripts/ui/CivilianCityCohesionV13.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV14LecturaArquitectonica360"

const BRICK=Color("#9a7668")
const LIMESTONE=Color("#c3b7a6")
const RENDER=Color("#afa89e")
const CONCRETE=Color("#8d8b83")
const METAL=Color("#718187")
const OXIDE=Color("#79645b")
const SOOT=Color("#3d484b")
const MORTAR=Color("#ada291")
const DUST=Color("#9d988c")
const DARK=Color("#303a40")
const WOOD=Color("#7c6451")

static func _box(root: Node3D,n: String,p: Vector3,
        d: Vector3,c: Color,material: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(root,n,p,d,c)
    mesh.material_override=V9._finish(c,material)
    return mesh

static func _rod(root: Node3D,n: String,p: Vector3,
        radius: float,height: float,c: Color) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._cylinder(
        root,n,p,radius,height,c,8)
    mesh.material_override=V9._finish(c,"steel")
    return mesh

static func _sloped_slab(root: Node3D,n: String,
        center: Vector3,width: float,depth: float,
        left_h: float,right_h: float,tint: Color) -> MeshInstance3D:
    # Closed 3D slab with an uneven upper edge; unlike a box this is
    # a real pitched/broken piece seen from front, back and both sides.
    var dx: float=width*0.5
    var dz: float=depth*0.5
    var a:=Vector3(-dx,left_h,-dz)
    var b:=Vector3(dx,right_h,-dz)
    var c:=Vector3(dx,right_h,dz)
    var d:=Vector3(-dx,left_h,dz)
    var down:=Vector3.DOWN*0.11
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    V11._tri(surface,a,b,c)
    V11._tri(surface,a,c,d)
    V11._tri(surface,c+down,b+down,a+down)
    V11._tri(surface,d+down,c+down,a+down)
    V11._tri(surface,a,a+down,b+down)
    V11._tri(surface,a,b+down,b)
    V11._tri(surface,b,b+down,c+down)
    V11._tri(surface,b,c+down,c)
    V11._tri(surface,c,c+down,d+down)
    V11._tri(surface,c,d+down,d)
    V11._tri(surface,d,d+down,a+down)
    V11._tri(surface,d,a+down,a)
    var mesh:=MeshInstance3D.new()
    mesh.name=n
    mesh.position=center
    mesh.mesh=surface.commit()
    mesh.material_override=V9._finish(tint,"stone")
    root.add_child(mesh)
    return mesh

static func _undamaged_corners(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int,
        accent: Color) -> void:
    if damage>=2:
        return
    var detail:=V1._group(root,"RemateEsquinas360V14_"+tag)
    var roof_h: float=float(floors)*2.10+0.21
    # The V8/V9 silhouette is already tier-dependent. Close only the
    # mitred exterior corner where roof flashing meets a vertical wall.
    for side in [-1,1]:
        var px: float=x+float(side)*(w*0.5+0.046)
        for face in [-1,1]:
            var zz: float=z+float(face)*(d*0.5+0.068)
            var ridge:=_box(detail,
                "JuntaMitraEsquinaV14_%s_%d_%d" % [tag,side,face],
                Vector3(px,roof_h+0.20,zz),
                Vector3(0.18,0.15,0.20),
                BRICK if level==1 else LIMESTONE if level==2 else METAL,
                "steel" if level==3 else "stone")
            ridge.rotation_degrees.y=float(side*face)*7.0
        if level==3:
            # Tiny roof-edge civic identity remains physically attached.
            _box(detail,"PerfilFachadaMetropoliV14_%s_%d" % [tag,side],
                Vector3(px,roof_h-0.25,z),
                Vector3(0.095,0.21,d*0.68),accent,"steel")
        if damage==1:
            _box(detail,"PiezaMitreDesgastadaV14_%s_%d" % [tag,side],
                Vector3(px,roof_h+0.09,z-d*0.39),
                Vector3(0.18,0.12,0.30),OXIDE)

static func _moderate_360(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int) -> void:
    var volume:=V1._group(root,"BordeTornasol360V14_"+tag)
    var h: float=float(floors)*2.10+0.21
    var tint: Color=BRICK if level==1 else CONCRETE if level==2 else METAL
    for side in [-1,1]:
        var px: float=x+float(side)*w*0.50
        # Roof-to-wall fracture: one is attached at the rear and the
        # other to the front, allowing distinct silhouettes at 180°.
        for back in [-1,1]:
            var pz: float=z+float(back)*(d*0.5-0.20)
            var plate:=_sloped_slab(volume,
                "LaminaRotaVoladizoV14_%s_%d_%d" % [tag,side,back],
                Vector3(px-float(side)*0.24,h+0.21,pz),
                0.47,0.60,0.10 if side==-1 else 0.31,
                0.36 if side==-1 else 0.08,tint)
            plate.rotation_degrees.z=float(side)*5.0
            _box(volume,"SoporteLaminaV14_%s_%d_%d" % [tag,side,back],
                Vector3(px-float(side)*0.18,h-0.055,pz),
                Vector3(0.24,0.33,0.29),CONCRETE)
        # A visible broken vertical seam and pulled-out steel bars
        # terminate at surviving wall rather than a floating roof.
        for i in range(2):
            var zz: float=z+d*(0.18 if i==0 else -0.25)
            var crack:=_box(volume,
                "RoturaCostado360V14_%s_%d_%d" % [tag,side,i],
                Vector3(px+float(side)*0.087,
                    h-0.93+float(i)*0.20,zz),
                Vector3(0.14,0.70,0.11),SOOT)
            crack.rotation_degrees.x=float(side)*(12.0+float(i)*11.0)
        var metal:=_rod(volume,"BarraArrancadaCostadoV14_%s_%d" % [tag,side],
            Vector3(px+float(side)*0.13,h+0.01,z+d*0.34),
            0.037,0.44,OXIDE)
        metal.rotation_degrees.z=float(side)*26.0
    # Parted gable/flat roof profile, designed to read from the street
    # and from the opposite rear courtyard, without closing the D2 hole.
    for face in [-1,1]:
        var pz: float=z+float(face)*d*0.49
        var shard:=_sloped_slab(volume,
            "PerfilCornisaSeparadaV14_%s_%d" % [tag,face],
            Vector3(x,h+0.14,pz),w*0.34,0.22,
            0.10 if face==-1 else 0.26,
            0.27 if face==-1 else 0.08,SOOT)
        shard.rotation_degrees.y=float(face)*8.0

static func _severe_360(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    if damage<3:
        return
    var ruin:=V1._group(root,"Vista360CascaronV14_"+tag)
    # Reinforce V11's jagged full-perimeter outline with asymmetric
    # corner buttresses. D4 intentionally has no upright high wall.
    for side in [-1,1]:
        var px: float=x+float(side)*(w*0.5-0.065)
        for back in [-1,1]:
            var pz: float=z+float(back)*(d*0.5-0.11)
            var height: float=0.58 if damage==3 else 0.21
            var buttress:=_box(ruin,
                "PieMuroSerradoV14_%s_%d_%d" % [tag,side,back],
                Vector3(px,0.10+height*0.5,pz),
                Vector3(0.23,height,0.27),
                BRICK if level==1 else CONCRETE)
            buttress.rotation_degrees.y=float(side*back)*14.0
        if damage==3:
            # A real triangular exposed cross-section from the side;
            # near the ground, not a phantom intact upper storey.
            V11._broken_wall(ruin,
                "DienteMuroCostadoV14_%s_%d" % [tag,side],
                Vector3(px,0.08,z+d*0.17),
                Vector3(0,0,d*0.56),
                PackedFloat32Array([0.45,0.93,0.67,0.47]),SOOT,0.15)
    # Asymmetrical fractured floor plates show through the empty roof.
    if damage==3:
        for i in range(2):
            var px: float=x+(float(i)-0.5)*w*0.36
            var slab:=_sloped_slab(ruin,
                "PisoAbiertoDienteV14_%s_%d" % [tag,i],
                Vector3(px,0.90,z+d*(0.16 if i==0 else -0.19)),
                w*0.30,d*0.36,
                0.04,0.26,CONCRETE)
            slab.rotation_degrees.y=9.0+float(i)*21.0
            _box(ruin,"VigaPisoAisladaV14_%s_%d" % [tag,i],
                Vector3(px,0.79,z+d*(0.16 if i==0 else -0.19)),
                Vector3(w*0.31,0.13,0.16),OXIDE,"steel")
    else:
        # Distinct short broken rings / rubble silhouettes from all sides.
        for i in range(3):
            var px: float=x+(float(i)-1.0)*w*0.24
            var pz: float=z+d*(0.23 if i%2==0 else -0.21)
            V12._rubble_wedge(ruin,
                "CrestaEscombros360V14_%s_%d" % [tag,i],
                Vector3(px,0.037,pz),
                Vector3(0.46,0.20+float(i)*0.07,0.43),
                SOOT if i==1 else BRICK)

static func _civic_360(root: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var hall:=V1._group(root,"Ayuntamiento360V14")
    var z: float=-3.75
    var half_d: float=2.74*0.5
    var front: float=z-half_d
    var rear: float=z+half_d
    var top: float=float(2 if level==1 else 3 if level==2 else 4)*2.10+0.21
    if damage<=1:
        # Rear civic cornice has the same rich silhouette as the entrance.
        for face in [-1,1]:
            var zz: float=front if face==-1 else rear
            _box(hall,"RemateEsquinaCivica360V14_%d" % face,
                Vector3(1.45,top+0.21,zz),
                Vector3(0.30,0.21,0.27),LIMESTONE)
            _box(hall,"RemateOpuestoCivico360V14_%d" % face,
                Vector3(-1.45,top+0.21,zz),
                Vector3(0.30,0.21,0.27),LIMESTONE)
        if damage==1:
            _box(hall,"FisuraBordeMunicipal360V14",
                Vector3(1.20,top-0.19,rear+0.12),
                Vector3(0.07,0.38,0.09),OXIDE)
        return
    if damage==2:
        # Surviving civic eave is visibly crooked from FRONT and REAR,
        # attached to V13's split municipal roof corbels.
        for face in [-1,1]:
            var zz: float=front if face==-1 else rear
            var shard:=_sloped_slab(hall,
                "VigaCoronaMunicipalAbiertaV14_%d" % face,
                Vector3(0.46,top+0.12,zz),
                1.24,0.28,0.06,0.26,LIMESTONE)
            shard.rotation_degrees.y=float(face)*8.0
            _box(hall,"ApoyoCoronaMunicipalV14_%d" % face,
                Vector3(0.31,top-0.11,zz-float(face)*0.13),
                Vector3(0.50,0.35,0.27),CONCRETE)
        if level>=2:
            _box(hall,"SoporteRelojMunicipalV14",
                Vector3(0.23,0.25,rear+0.36),
                Vector3(0.55,0.25,0.37),OXIDE,"steel")
        return
    # No intact civic entrance or clock crown on D3/D4. These profiles
    # are low polygons anchored in the original town-hall foundation.
    for face in [-1,1]:
        var zz: float=front if face==-1 else rear
        var heights:=PackedFloat32Array([0.41,1.14,0.74,0.37])
        if damage==4:
            heights=PackedFloat32Array([0.13,0.38,0.25,0.10])
        V11._broken_wall(hall,
            "MuroMunicipal360V14_%d" % face,
            Vector3(0.0,0.12,zz),
            Vector3(2.68,0,0),heights,
            LIMESTONE if face==1 else BRICK,0.23)
    if damage==3:
        for side in [-1,1]:
            var px: float=float(side)*1.47
            V11._broken_wall(hall,
                "CostadoMunicipalColapsadoV14_%d" % side,
                Vector3(px,0.09,z),
                Vector3(0,0,2.45),
                PackedFloat32Array([0.36,1.02,0.57,0.22]),
                CONCRETE,0.21)
            _box(hall,"VigaHallRotaV14_%d" % side,
                Vector3(float(side)*0.86,0.46,z+0.15),
                Vector3(0.24,0.14,1.71),OXIDE,"steel")
    else:
        # D4 roughens the footprint but doesn't recreate a standing hall.
        V12._rubble_wedge(hall,"FrisoMunicipalSuelo360V14",
            Vector3(0.62,0.04,rear-0.25),
            Vector3(0.76,0.34,0.52),LIMESTONE)
    if level>=2:
        _box(hall,"FragmentoRelojEscombroV14",
            Vector3(-0.58,0.15,rear+0.22),
            Vector3(0.34,0.10,0.27),accent,"steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V13.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var rear_floors: int=1 if level==1 else 2 if level==2 else 4
    var front_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for south in [false,true]:
            var tag: String=("ResidencialSur_%d" % side
                if south else "ResidencialNorte_%d" % side)
            var z: float=3.62 if south else -3.80
            var w: float=2.77 if south else 2.74
            var d: float=2.80 if south else 2.84
            var floors: int=front_floors if south else rear_floors
            if damage<=1:
                _undamaged_corners(stage,tag,x,z,w,d,
                    floors,level,damage,accent)
            elif damage==2:
                _moderate_360(stage,tag,x,z,w,d,floors,level)
            else:
                _severe_360(stage,tag,x,z,w,d,level,damage)
    _civic_360(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",14)
    stage.set_meta("design_focus","four-facade-360-tactical-silhouettes")
    stage.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",14)
    model.set_meta("city_model_approved_final",false)
    return true
