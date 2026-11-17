extends RefCounted
class_name TarvokaAttackHelicopterFactionV14

# Hero-only HAT-29 identity coat. Preserve V13 destruction geometry, rotors,
# glass, weapons, and the Android battle LOD <= 10.
const FLAG := "tarvoka_a01_hat29_faction_v14"
const DETAIL_ROOT := "A01V14_1_AccesosYJuntasTacticas"
const V13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const PAINTED := [
    ["A01_V2_Casco12CarasCerrado",0.52],
    ["A01V4_BlindajeLateral_-1",0.57],
    ["A01V4_BlindajeLateral_1",0.57],
    ["A01V12_MejillaBlindada_-1",0.55],
    ["A01V12_MejillaBlindada_1",0.55],
    ["A01_V2_PuertaCabina_-1",0.62],
    ["A01_V2_PuertaCabina_1",0.62],
    ["A01_VigaColaSellada",0.50],
    ["A01_AletaVertical",0.60],
    ["A01_EstabilizadorCola",0.42],
    ["A01_V2_BandaIdentificacionSuperior",0.83],
]

# The faction accent is now deliberately restrained: the metal hull remains
# legible while secondary identity color stays on selected access panels.
const SECONDARY := [
    "#ffc83e", # Alianza Norte: blue + military gold
    "#eae0d9", # Pacto Escarlata: red + warm ceramic
    "#bcdf64", # Unión Verde: green + lime
    "#f6e1a6", # Confederación Solar: gold + light champagne
    "#e9c3ff", # Sindicato Violeta: violet + pale lilac
    "#ffd097", # Legión Ámbar: amber + pale bronze
    "#b4eef2", # Dominio Turquesa: teal + ice
    "#d7e1e9", # Orden Ónix: black + steel
]
const TWO_TONE := [
    ["A01V4_MotorCarenado_-1",0.55],
    ["A01V4_MotorCarenado_1",0.55],
    ["A01_AlaRefuerzo_-1",0.50],
    ["A01_AlaRefuerzo_1",0.50],
    ["A01_AletaVertical",0.53],
]

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (model.find_child(DETAIL_ROOT,true,false)!=null)

static func _enamel(mesh: MeshInstance3D,color: Color) -> void:
    var old: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    var coat: StandardMaterial3D=(old.duplicate(true) as StandardMaterial3D
        if old!=null else StandardMaterial3D.new())
    coat.albedo_color=color
    coat.metallic=0.29
    coat.roughness=0.63
    mesh.material_override=coat


# V14.1 high-detail surface sculpt: real raised seams, hinges and fasteners.
# Exclusively on the Studio aircraft; no additional tactical mobile geometry.
static func _hardware(parent: Node3D,name: String,shape: Mesh,
        location: Vector3,color: Color,rotation: Vector3=Vector3.ZERO) -> void:
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=shape
    part.position=location
    part.rotation_degrees=rotation
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=0.44
    mat.roughness=0.58
    part.material_override=mat
    parent.add_child(part)

static func _seam(parent: Node3D,name: String,location: Vector3,
        size: Vector3,color: Color) -> void:
    var shape:=BoxMesh.new()
    shape.size=size
    _hardware(parent,name,shape,location,color)

static func _rivet(parent: Node3D,name: String,location: Vector3) -> void:
    var shape:=CylinderMesh.new()
    shape.top_radius=0.017
    shape.bottom_radius=0.018
    shape.height=0.020
    shape.radial_segments=10
    _hardware(parent,name,shape,location,Color("#b0b8b5"),
        Vector3(0.0,0.0,90.0))

static func _details(model: Node3D) -> bool:
    if model.find_child(DETAIL_ROOT,true,false)!=null:
        return true
    var fuselage: Node3D=model.find_child("A01_HelicopteroAtaque_V1",true,false) as Node3D
    if fuselage==null:
        return false
    var root:=Node3D.new()
    root.name=DETAIL_ROOT
    fuselage.add_child(root)
    var graphite:=Color("#303b43")
    var exposed:=Color("#8c9a9d")
    for side in [-1,1]:
        var sign: float=float(side)
        # The V2 cockpit door is centered at x=0.575, y=1.07, z=-0.52:
        # these are thin individual relief pieces, not a painted rectangle.
        _seam(root,"A01V14_1_DoorTop_%d" % side,
            Vector3(sign*0.605,1.247,-0.52),
            Vector3(0.022,0.018,0.47),graphite)
        _seam(root,"A01V14_1_DoorBottom_%d" % side,
            Vector3(sign*0.605,0.893,-0.52),
            Vector3(0.022,0.018,0.47),graphite)
        for end in range(2):
            var z: float=-0.755+0.47*float(end)
            _seam(root,"A01V14_1_DoorFrame_%d_%d" % [side,end],
                Vector3(sign*0.605,1.07,z),
                Vector3(0.022,0.32,0.016),graphite)
        for hinge in range(2):
            var y: float=0.985+0.17*float(hinge)
            _seam(root,"A01V14_1_DoorHinge_%d_%d" % [side,hinge],
                Vector3(sign*0.622,y,-0.748),
                Vector3(0.025,0.054,0.060),exposed)
        for bolt in range(3):
            _rivet(root,"A01V14_1_DoorFastener_%d_%d" % [side,bolt],
                Vector3(sign*0.622,0.943+0.126*float(bolt),-0.309))
        # Independent aft-engine inspection panel and light-colored seal.
        _seam(root,"A01V14_1_EngineServiceRim_%d" % side,
            Vector3(sign*0.594,1.61,1.006),
            Vector3(0.026,0.115,0.132),graphite)
        _seam(root,"A01V14_1_EngineServicePlate_%d" % side,
            Vector3(sign*0.609,1.61,1.006),
            Vector3(0.014,0.077,0.095),exposed)
        # Two raised inspection straps that respect the narrowing V1 tail.
        for index in range(2):
            var x: float=0.169 if index==0 else 0.133
            var z: float=1.71 if index==0 else 2.11
            _seam(root,"A01V14_1_TailClamp_%d_%d" % [side,index],
                Vector3(sign*x,1.095,z),
                Vector3(0.020,0.135,0.036),graphite)
    return true

static func apply(model: Node3D,faction: Color,faction_index: int=-1) -> bool:
    if not V13.has_model(model):
        return false
    if has_model(model):
        return true
    var count: int=0
    for entry in PAINTED:
        var shape: MeshInstance3D=model.find_child(str(entry[0]),true,false) as MeshInstance3D
        if shape==null:
            continue
        var strength: float=float(entry[1])
        # Mix the faction into naval graphite rather than coating the whole hull.
        var color: Color=Color("#32444e").lerp(faction,strength)
        _enamel(shape,color)
        count+=1
    # A muted two-tone aircraft finish, not a full-body saturated faction coat.
    var second: Color=Color(SECONDARY[faction_index]) if (
        faction_index>=0 and faction_index<SECONDARY.size()) else Color("#e3c77d")
    for entry in TWO_TONE:
        var shape: MeshInstance3D=model.find_child(str(entry[0]),true,false) as MeshInstance3D
        if shape==null:
            continue
        _enamel(shape,Color("#52616b").lerp(second,float(entry[1])))
        count+=1
    if count<11 or not _details(model):
        return false
    model.set_meta(FLAG,true)
    model.set_meta("a01_v14_faction_painted_count",count)
    model.set_meta("a01_v14_faction_color",faction)
    model.set_meta("a01_v14_secondary_color",second)
    model.set_meta("a01_v14_coat_revision","muted_tactical_v14_1")
    return true
