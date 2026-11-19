extends RefCounted
class_name TarvokaCivilianCityFactionIdentityV44

# Visual-only reinforcement for civilian cities. The eight official TARVOKA
# faction swatches are NOT changed. Neutral uses blue-grey slate rather than
# the earlier golden city accent which resembled Confederacion Solar.
# A small number of physically modeled trim pieces replaces no existing mesh.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV44IdentidadFaccion"
const PREFIX="CiudadIdentidadV44_"
const NEUTRAL_SLATE=Color("#70838B")
const CIVIC_X=0.0
const RESIDENTIAL_X=4.63

static func _accent(faction: int,damage: int) -> Color:
    var color: Color=Style.faction_color(faction) if faction>=0 else NEUTRAL_SLATE
    return color.darkened(0.10) if damage==2 else color

static func _piece(root: Node3D,label: String,pos: Vector3,
        dimensions: Vector3,tint: Color,faction: int) -> void:
    V1._box(root,PREFIX+label,pos,dimensions,tint,
        "metal" if faction>=0 else "stone")

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if model.has_node(STAGE_NAME):
        return false
    var stage: Node3D=V1._group(model,STAGE_NAME)
    var tint: Color=_accent(faction,damage)
    if damage>=3:
        # Ruins have displaced, non-continuous remnants of former signage.
        # No intact facade stripes float above destroyed civic buildings.
        for side in [-1,1]:
            _piece(stage,"RestosIdentidad_%d" % side,
                Vector3(float(side)*1.05,0.27,2.20),
                Vector3(0.50,0.10,0.22),tint.darkened(0.28),faction)
    else:
        var rear_floors: int=1 if level==1 else 2 if level==2 else 4
        var front_floors: int=1 if level==1 else 3 if level==2 else 5
        var civic_floors: int=2 if level==1 else 3 if level==2 else 4
        # A modest extra painted metal fascia on real residential facades,
        # front AND back streets, remains legible in all three 3D LODs.
        for side in [-1,1]:
            var sx: float=float(side)*RESIDENTIAL_X
            for zone in [0,1]:
                var floors: int=rear_floors if zone==0 else front_floors
                var z: float=-3.80 if zone==0 else 3.62
                var depth: float=2.84 if zone==0 else 2.80
                var facade_z: float=z-depth*0.50-0.18
                var height: float=float(floors)*2.10+0.21
                _piece(stage,"Residencial_%d_%d" % [side,zone],
                    Vector3(sx,height-0.54,facade_z),
                    Vector3(2.13,0.21,0.15),tint,faction)
                if damage<=1:
                    _piece(stage,"MarcoEntrada_%d_%d" % [side,zone],
                        Vector3(sx+0.64,1.10,facade_z-0.02),
                        Vector3(0.14,1.07,0.13),tint,faction)
        var civic_height: float=float(civic_floors)*2.10+0.21
        _piece(stage,"Municipal_Cornisa",
            Vector3(CIVIC_X,civic_height-0.56,-5.28),
            Vector3(2.66,0.22,0.15),tint,faction)
        if damage<=1:
            for side in [-1,1]:
                _piece(stage,"Municipal_Pilar_%d" % side,
                    Vector3(float(side)*1.31,1.21,-5.28),
                    Vector3(0.16,1.16,0.14),tint,faction)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("faction_id",faction)
    stage.set_meta("palette_version",44)
    stage.set_meta("accent_hex",tint.to_html(false))
    stage.set_meta("neutral_is_slate",faction==-1)
    model.set_meta("city_faction_identity_version",44)
    return true
