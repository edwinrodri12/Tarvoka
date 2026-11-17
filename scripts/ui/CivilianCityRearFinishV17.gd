extends RefCounted
class_name TarvokaCivilianCityRearFinishV17

# V17: true three-dimensional rear/side facades, service doors,
# masonry joints and damaged rear elevation. Visual only.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V16=preload("res://scripts/ui/CivilianCityMaterialJointsV16.gd")
const STAGE_NAME="CiudadCivilV17FachadasTraserasYServicios"
const GLASS=Color("#648a94")
const STONE=Color("#c6b9a5")
const BRICK=Color("#977360")
const METAL=Color("#61757c")
const WOOD=Color("#80634d")
const CHAR=Color("#434747")
const RUBBLE=Color("#776c61")

static func _part(p: Node3D,n: String,at: Vector3,dims: Vector3,
        color: Color,finish: String="stone") -> void:
    var m: MeshInstance3D=V1._box(p,n,at,dims,color)
    m.material_override=V9._finish(color,finish)

static func _rear(stage: Node3D,tag: String,x: float,z: float,
        w: float,d: float,floors: int,level: int,damage: int) -> void:
    var group:=V1._group(stage,"FachadaPosteriorV17_"+tag)
    var rear_z: float=z+d*0.5+0.07
    var height: float=float(floors)*2.10+0.21
    if damage>=3:
        # Shallow fallen elements: no magically preserved windows at D3/D4.
        for i in range(3 if damage==3 else 5):
            _part(group,"EscombroPosteriorV17_%d" % i,
                Vector3(x+(float(i%3)-1.0)*w*0.27,
                    0.12+float(i%2)*0.045,rear_z+0.14+float(i%2)*0.25),
                Vector3(0.46,0.22,0.35),
                RUBBLE if i%2==0 else CHAR)
        return
    _part(group,"PuertaServicioPosteriorV17",
        Vector3(x,0.93,rear_z+0.035),
        Vector3(0.81,1.72,0.13),
        WOOD if level==1 else METAL,"wood" if level==1 else "steel")
    _part(group,"UmbralServicioV17",
        Vector3(x,0.09,rear_z+0.19),
        Vector3(1.00,0.16,0.46),STONE)
    for floor in range(floors):
        var y: float=0.96+float(floor)*2.10
        if y+0.44>=height:
            continue
        for side in [-1,1]:
            if damage==2 and (floor+side+4)%3==0:
                continue
            var sx: float=x+float(side)*w*0.26
            var pane: Color=(GLASS if damage==0 else CHAR)
            _part(group,"MarcoVentanaTraseraV17_%d_%d" % [floor,side],
                Vector3(sx,y,rear_z),
                Vector3(0.66,0.86,0.16),
                STONE if level<3 else METAL)
            _part(group,"CristalVentanaTraseraV17_%d_%d" % [floor,side],
                Vector3(sx,y,rear_z+0.091),
                Vector3(0.48,0.62,0.025),pane,"glass")
            _part(group,"AlfeizarTraseroV17_%d_%d" % [floor,side],
                Vector3(sx,y-0.46,rear_z+0.12),
                Vector3(0.75,0.09,0.28),STONE)
    if damage==2:
        _part(group,"GrietaDintelPosteriorV17",
            Vector3(x+w*0.24,height*0.61,rear_z+0.10),
            Vector3(0.10,0.81,0.10),CHAR)
        return
    for side in [-1,1]:
        _part(group,"EsquineroPosteriorV17_%d" % side,
            Vector3(x+float(side)*w*0.48,height*0.5,rear_z-0.04),
            Vector3(0.12,height*0.94,0.14),
            WOOD if level==1 else BRICK if level==2 else METAL,
            "wood" if level==1 else "steel" if level==3 else "stone")
    if level==3:
        # Two 3D service vents; no extra skyline or fake texture.
        for side in [-1,1]:
            _part(group,"RejillaClimatizacionPosteriorV17_%d" % side,
                Vector3(x+float(side)*w*0.24,height-0.53,rear_z+0.13),
                Vector3(0.55,0.36,0.14),METAL,"steel")

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V16.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var rear_floors: int=1 if level==1 else 2 if level==2 else 4
    var front_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        _rear(stage,"Norte_%d" % side,x,-3.80,2.74,2.84,
            rear_floors,level,damage)
        _rear(stage,"Sur_%d" % side,x,3.62,2.77,2.80,
            front_floors,level,damage)
    _rear(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        2 if level==1 else 3 if level==2 else 4,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",17)
    model.set_meta("city_art_work_in_progress",17)
    model.set_meta("city_model_approved_final",false)
    return true
