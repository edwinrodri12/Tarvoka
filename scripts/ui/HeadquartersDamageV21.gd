extends RefCounted
class_name TarvokaHeadquartersDamageV21

# Visual-only staged destruction. 0 intact, 1 small impacts, 2 fractured
# openings, 3 critical structural failure, 4 genuine rubble model.
# No HP, combat statistics, pathfinding, save-game or physics mutation.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const STAGES := ["Intacto","Impactos leves","Daño moderado",
    "Daño crítico","Destruido"]
const STAGE_NAME := "DeterioroEstructuralProgresivoHQV21"
const CHAR := Color("#302a2b")
const EXPOSED := Color("#515961")
const CONCRETE := Color("#94a3a5")
const STEEL := Color("#869baa")
const RUST := Color("#815b4f")
const GLASS := Color("#47819b")
const SMOKE := Color(0.20,0.22,0.24,0.45)

static func _box(parent: Node3D,name: String,p: Vector3,size: Vector3,
        color: Color,rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return HQ._box(parent,name,p,size,color,0.08,false,rotation)

static func _group(parent: Node3D,name: String) -> Node3D:
    var root := Node3D.new()
    root.name = name
    parent.add_child(root)
    return root

static func _crack(parent: Node3D,label: String,points: Array,
        radius: float = 0.025) -> void:
    # True short 3D bevelled beams, NOT hand-painted triangular blotches.
    for i in range(points.size()-1):
        var start: Vector3 = points[i]
        var end: Vector3 = points[i+1]
        var vec: Vector3 = end-start
        var mesh := CylinderMesh.new()
        mesh.top_radius = radius*0.86
        mesh.bottom_radius = radius
        mesh.height = vec.length()
        mesh.radial_segments = 6
        var part := MeshInstance3D.new()
        part.name = "%s_%d" % [label,i]
        part.mesh = mesh
        part.position = (start+end)*0.5
        part.quaternion = Quaternion(Vector3.UP,vec.normalized())
        var mat := StandardMaterial3D.new()
        mat.albedo_color = CHAR
        mat.metallic = 0.04
        mat.roughness = 0.92
        part.material_override = mat
        part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(part)

static func _light(model: Node3D,part: Node3D,level: int) -> void:
    # Surface-local discrete impact pits (metal edges + dark 3D cores).
    # Markers avoid faction shield, remaining separated by >2 m.
    var marks := [Vector3(-2.25,1.49,-3.08),
        Vector3(4.75,1.25,-3.15),Vector3(3.31,2.04,-3.15)]
    for i in range(marks.size()):
        var mark: Vector3 = marks[i]
        _box(part,"AnilloMetalImpactoHQV21_%d" % i,mark,
            Vector3(0.19,0.17,0.043),RUST)
        _box(part,"AbolladuraRehundidaHQV21_%d" % i,
            mark+Vector3(0,0,-0.030),
            Vector3(0.075,0.07,0.014),CHAR)
    _crack(part,"MicrofisuraBajoVentanaHQV21",
        [Vector3(-2.38,1.12,-3.092),
         Vector3(-2.22,1.05,-3.101),
         Vector3(-2.10,0.93,-3.110)],0.019)

static func _moderate(model: Node3D,part: Node3D,level: int) -> void:
    # Actual source glass is removed: the resulting gap is not covered
    # by a black polygon. Real displaced shards and bent frame take its place.
    var glass: MeshInstance3D = model.find_child(
        "HojaCristalBlindado_-1",true,false) as MeshInstance3D
    if glass != null:
        glass.visible = false
    var chipped: MeshInstance3D = model.find_child(
        "CristalPuerta",true,false) as MeshInstance3D
    if chipped != null:
        chipped.visible = false
    var wing_glass: MeshInstance3D = model.find_child(
        "VidrioMiradorAla_1_1",true,false) as MeshInstance3D
    if wing_glass != null:
        wing_glass.visible = false
    var breakage := _group(part,"CristaleriaAbiertaYFragmentosHQV21")
    for i in range(6):
        var x: float = -0.77+float(i%3)*0.24
        var y: float = 0.60+float(int(i/3))*0.71
        _box(breakage,"LaminaVidrioDislocadaV21_%d" % i,
            Vector3(x,y,-4.151-float(i%2)*0.05),
            Vector3(0.16,0.36,0.026),GLASS,
            Vector3(7.0+float(i)*4.0,0,18.0+float(i)*11.0))
    _box(breakage,"MarcoPuertaRetorcidoV21",
        Vector3(-0.90,0.98,-4.20),Vector3(0.073,1.41,0.089),
        STEEL,Vector3(0,0,-13.0))
    # Clearly visible front-right observatory failure: real glass is gone,
    # and three inclined surviving fragments replace the original pane.
    for k in range(3):
        _box(breakage,"CristalMiradorDerechoRotoV21_%d" % k,
            Vector3(4.54+float(k)*0.12,2.48+float(k%2)*0.13,-3.22),
            Vector3(0.11,0.25,0.028),GLASS,
            Vector3(11.0,0,21.0+float(k)*19.0))
    _box(part,"PlacaFrontalDesgarradaModeradaV21",
        Vector3(4.08,1.04,-3.28),
        Vector3(0.96,1.12,0.14),EXPOSED,
        Vector3(9.0,0,23.0))
    _box(part,"SombraFisuraBajoPlacaModeradaV21",
        Vector3(4.39,0.83,-3.26),
        Vector3(0.24,0.94,0.12),CHAR,Vector3(0,0,-16.0))
    _crack(part,"GrietaFracturaLadoDerechoV21",
        [Vector3(4.95,2.04,-3.181),Vector3(4.78,1.85,-3.183),
         Vector3(4.92,1.69,-3.186),Vector3(4.73,1.51,-3.188)],0.037)
    # Physical angled wall fragments at rear, with real thickness.
    for i in range(3):
        _box(part,"PlacaPosteriorDesprendidaV21_%d" % i,
            Vector3(-1.84+float(i)*0.66,0.35,3.25+float(i)*0.10),
            Vector3(0.54,0.62,0.16),CONCRETE.darkened(0.13),
            Vector3(7.0+float(i)*5.0,float(i)*7.0,23.0+float(i)*14.0))

static func _critical(model: Node3D,part: Node3D,level: int) -> void:
    # The damaged LEFT wing really loses its original wall and front
    # curved parapet, exposing its fracture and replaced half-height chunks.
    for label in ["MuroPosteriorAlaV21_-1",
            "MuroContinuoBajoVentanasAlaV20_-1",
            "TechoAla-1",
            "BandaAla-1",
            "PetoCurvoDeAlaV12_-1",
            "CoronaHormigonAlaV12_-1",
            "VidrioMiradorAla_-1_-1"]:
        var original: MeshInstance3D = model.find_child(
            label,true,false) as MeshInstance3D
        if original != null:
            original.visible = false
    var collapsed := _group(part,"AlaTraseraRotaYAceroExpuestoV21")
    for i in range(4):
        var x: float = -5.0+float(i)*0.53
        _box(collapsed,"LosaQuebradaTrasera_%d" % i,
            Vector3(x,0.66+float(i%2)*0.25,2.61),
            Vector3(0.62,1.20+float(i%3)*0.23,0.24),
            CONCRETE.darkened(0.20),Vector3(12.0,float(i)*9.0,17.0+float(i)*8.0))
    for i in range(5):
        _box(collapsed,"VigaExpuestaRetorcida_%d" % i,
            Vector3(-5.07+float(i)*0.53,1.64+float(i%2)*0.26,2.55),
            Vector3(0.077,1.72,0.091),RUST,
            Vector3(0,0,-30.0+float(i)*17.0))
    # Highly readable front-facing structural opening, not a small soot
    # patch pasted over the same intact facade used by moderate damage.
    for i in range(3):
        _box(collapsed,"RestosMuroAlaFrontalCriticaV21_%d" % i,
            Vector3(-4.88+float(i)*0.68,0.81+float(i%2)*0.24,-3.25),
            Vector3(0.83,1.20+float(i)*0.13,0.30),
            CONCRETE.darkened(0.16+float(i)*0.08),
            Vector3(11.0+float(i)*7,7.0,25.0+float(i)*15.0))
    for i in range(4):
        _box(collapsed,"AceroAlaAbiertaFrontalV21_%d" % i,
            Vector3(-5.00+float(i)*0.61,1.85+float(i%2)*0.21,-3.23),
            Vector3(0.11,2.05,0.12),RUST,
            Vector3(0.0,0.0,-26.0+float(i)*18.0))
    _box(collapsed,"PlacaVoladaHaciaPatioV21",
        Vector3(-3.86,0.53,-4.44),Vector3(1.87,0.24,1.02),
        EXPOSED,Vector3(26.0,18.0,32.0))
    _box(collapsed,"VoladizoCurvoCaidoV21",
        Vector3(-4.04,0.33,-3.78),
        Vector3(2.04,0.22,0.78),CHAR,Vector3(16.0,11.0,28.0))
    _box(collapsed,"PlacaBlindajeRotaHQV21",
        Vector3(-2.20,0.26,-4.43),
        Vector3(1.57,0.22,0.61),EXPOSED,Vector3(21.0,19.0,14.0))
    for i in range(3):
        HQ._sphere(collapsed,"NubeHumoCriticoHQV21_%d" % i,
            Vector3(-4.40+float(i)*0.38,2.95+float(i)*0.58,-2.98),
            Vector3(0.85+float(i)*0.18,1.03+float(i)*0.21,0.88),
            Color(0.15,0.16,0.17,0.56-float(i)*0.06))
    _crack(collapsed,"FisuraGraveTorreHQV21",
        [Vector3(-1.57,4.20+0.91*float(level-1),-3.56),
         Vector3(-1.30,3.96+0.91*float(level-1),-3.58),
         Vector3(-1.55,3.69+0.91*float(level-1),-3.61)],0.056)

static func _wreck(part: Node3D) -> void:
    # Destroyed model already uses REAL HQ rubble; these are broken rear
    # wall chunks lying on the same foundation instead of a standing wall.
    for i in range(5):
        _box(part,"RestosMuroPosteriorHQV21_%d" % i,
            Vector3(-3.38+float(i)*1.68,0.36+float(i%3)*0.11,2.82),
            Vector3(1.15,0.47,0.42),CONCRETE.darkened(0.32),
            Vector3(11+float(i)*9,float(i)*6,21.0+float(i)*15.0))
    for i in range(3):
        _box(part,"VarillaFerroconcretoRuinasHQV21_%d" % i,
            Vector3(-2.6+float(i)*2.4,0.40,3.27),
            Vector3(0.085,0.71,0.075),RUST,
            Vector3(22.0,0,36.0+float(i)*20.0))

static func apply(model: Node3D,stage: int,level: int) -> bool:
    if model == null or stage < 0 or stage > 4 or level < 1 or level > 3:
        return false
    var old: Node = model.get_node_or_null(STAGE_NAME)
    if old != null:
        model.remove_child(old)
        old.free()
    # Model is freshly built by Studio on stage changes. Do not call
    # apply() repeatedly on the same model after source meshes are hidden.
    var details := _group(model,STAGE_NAME)
    details.set_meta("tarvoka_visual_only",true)
    details.set_meta("tarvoka_hq_damage_v21",stage)
    if stage > 0 and stage < 4:
        _light(model,details,level)
    if stage >= 2 and stage < 4:
        _moderate(model,details,level)
    if stage == 3:
        _critical(model,details,level)
    elif stage == 4:
        _wreck(details)
    model.set_meta("tarvoka_hq_damage_stage",stage)
    return true
