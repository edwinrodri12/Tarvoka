extends RefCounted
class_name TarvokaAPCDamageV7

# Enhanced staged sculpt of the P06's actual V6 armored hull.
# Prebuilt physical parts are only toggled on damage changes (zero new
# geometry per animation frame); combat HP, unit status and physics untouched.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V6 = preload("res://scripts/ui/APCFinishV6.gd")
const FLAG := "tarvoka_apc_damage_v7"
const ROOT := "P06V7_DestrozosFisicos"
const CACHE := "tarvoka_apc_damage_v7_nodes"
const TURRET_HOME := "tarvoka_apc_damage_v7_rest_turret_position"
const TURRET_ROT := "tarvoka_apc_damage_v7_rest_turret_angle"
const ENABLED := "tarvoka_apc_damage_v7_visible"
const STAGE := "tarvoka_apc_damage_v7_stage"

static func _make_stage(parent: Node3D,index: int) -> Node3D:
    var item:=Node3D.new()
    item.name="P06V7_DanoFisico_%d" % index
    item.visible=false
    parent.add_child(item)
    return item

static func _tri(parent: Node3D,name: String, vertices: Array[Vector3],
        material: Material) -> MeshInstance3D:
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for p in vertices:
        surface.add_vertex(p)
    surface.generate_normals()
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=surface.commit()
    mesh.material_override=material
    parent.add_child(mesh)
    return mesh

static func prepare(model: Node3D) -> bool:
    if model==null or not model.get_meta(V6.FLAG,false):
        return false
    if model.get_meta(FLAG,false):
        return true
    var exterior: Node3D=model.find_child(
        V6.ROOT,true,false) as Node3D
    var turret: Node3D=model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    if exterior==null or turret==null:
        return false
    var root:=Node3D.new()
    root.name=ROOT
    exterior.add_child(root)
    var charred:=V6._mat(Color("#252826"),0.11,0.96)
    var steel:=V6._mat(Color("#54626a"),0.52,0.86)
    var exposed:=V6._mat(Color("#171e21"),0.20,0.89)
    var broken_glass:=V6._mat(Color("#245064"),0.08,0.32)

    var minor:=_make_stage(root,1)
    # A dented visor rim and genuinely displaced antenna, not just texture.
    V6._box(minor,"FisuraMarcoConductor",
        Vector3(-0.270,1.310,-1.020),
        Vector3(0.205,0.027,0.044),steel,Vector3(0,0,-14))
    V1._cylinder(minor,"AntenaP06DobladaV7",
        Vector3(-0.724,1.744,0.83),0.014,0.35,exposed,8,
        Vector3(0,0,-39))

    var medium:=_make_stage(root,2)
    # The intact outer panel disappears; darker cavity and folded plates
    # replace the panel at the exact right-side armor coordinates.
    V6._box(medium,"HuecoDetrasBlindajeDeformado",
        Vector3(0.826,1.099,-0.165),
        Vector3(0.019,0.302,0.52),exposed)
    _tri(medium,"LaminaDerechaPartida",[
        Vector3(0.853,1.33,-0.43),Vector3(0.938,1.21,-0.34),
        Vector3(0.890,1.08,-0.10),
        Vector3(0.853,1.33,-0.43),Vector3(0.890,1.08,-0.10),
        Vector3(0.850,1.29,0.08)],steel)
    V6._box(medium,"CristalConductorFisurado",
        Vector3(0.249,1.238,-1.056),
        Vector3(0.176,0.025,0.018),broken_glass,
        Vector3(-21,0,-31))

    var critical:=_make_stage(root,3)
    # A sheared fender and rubber shards expose the right-front tire without
    # hiding the entire six-wheel articulation prematurely.
    _tri(critical,"FaldonDelanteroDesprendido",[
        Vector3(-0.853,0.874,-1.37),Vector3(-1.026,0.76,-1.29),
        Vector3(-0.969,0.82,-0.90),
        Vector3(-0.853,0.874,-1.37),Vector3(-0.969,0.82,-0.90),
        Vector3(-0.825,0.899,-0.87)],steel)
    V6._box(critical,"GomaNeumaticoRasgada",
        Vector3(-0.981,0.34,-1.12),
        Vector3(0.045,0.162,0.29),charred,Vector3(-21,0,11))
    V6._box(critical,"TramoDeChasisChamuscado",
        Vector3(-0.848,1.08,0.58),
        Vector3(0.039,0.27,0.32),charred,Vector3(0,0,-10))
    V6._box(critical,"CajaSensorDesencajada",
        Vector3(0.56,1.38,-0.61),
        Vector3(0.12,0.06,0.10),exposed,Vector3(0,24,-19))

    var ruined:=_make_stage(root,4)
    # Terminal wreck: crooked weapon station, exposed rotation ring and
    # scattered torn plating; V3 independently handles smoke/fire and the
    # broken front-right wheel (so we never double-render those effects).
    V1._cylinder(ruined,"AnilloMecanismoTorretaExpuesto",
        Vector3(0,1.534,-0.16),0.224,0.070,exposed,12)
    _tri(ruined,"AletaBlindajeDesgarrada",[
        Vector3(-0.69,1.46,0.40),Vector3(-1.02,1.12,0.45),
        Vector3(-0.84,1.21,0.87),
        Vector3(-0.69,1.46,0.40),Vector3(-0.84,1.21,0.87),
        Vector3(-0.49,1.31,0.84)],charred)
    _tri(ruined,"CostadoAbiertoFragmentado",[
        Vector3(0.79,1.25,0.71),Vector3(1.00,1.01,0.94),
        Vector3(0.76,0.83,1.18),
        Vector3(0.79,1.25,0.71),Vector3(0.76,0.83,1.18),
        Vector3(0.73,1.26,1.19)],steel)
    V6._box(ruined,"EnsambleRampaRetorcido",
        Vector3(-0.46,1.02,1.41),
        Vector3(0.09,0.46,0.10),charred,Vector3(24,0,-18))
    model.set_meta(TURRET_HOME,turret.position)
    model.set_meta(TURRET_ROT,turret.rotation_degrees)
    var antenna: Node3D=model.find_child(
        "AntenaBlindada_-1",true,false) as Node3D
    var side_panel: Node3D=model.find_child(
        "CorazaFaceteadaV2_1_1",true,false) as Node3D
    var sensor: Node3D=model.find_child(
        "VidrioSensorSecundario",true,false) as Node3D
    model.set_meta(CACHE,[turret,root,minor,medium,critical,ruined,
        antenna,side_panel,sensor])
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    model.set_meta(STAGE,0)
    return true

static func stage(model: Node3D) -> int:
    if model==null:
        return 0
    return clampi(int(model.get_meta(STAGE,0)),0,4)

static func set_stage(model: Node3D, damage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var refs: Array=model.get_meta(CACHE,[])
    if refs.size()!=9:
        return false
    var current: int=clampi(damage,0,4)
    var active: bool=bool(model.get_meta(ENABLED,true))
    for i in range(1,5):
        var layer: Node3D=refs[i+1] as Node3D
        if layer!=null:
            layer.visible=active and current>=i
    var antenna: Node3D=refs[6] as Node3D
    var side_panel: Node3D=refs[7] as Node3D
    var sensor: Node3D=refs[8] as Node3D
    if antenna!=null:
        antenna.visible=not(active and current>=1)
    if side_panel!=null:
        side_panel.visible=not(active and current>=2)
    if sensor!=null:
        sensor.visible=not(active and current>=3)
    var turret: Node3D=refs[0] as Node3D
    if turret!=null:
        var base_position: Vector3=model.get_meta(TURRET_HOME,Vector3.ZERO)
        var base_rotation: Vector3=model.get_meta(TURRET_ROT,Vector3.ZERO)
        turret.position=base_position
        turret.rotation_degrees=base_rotation
        if active and current>=4:
            turret.position=base_position+Vector3(0.08,-0.11,0.15)
            turret.rotation_degrees=base_rotation+Vector3(14,-10,-19)
        elif active and current>=3:
            turret.rotation_degrees=base_rotation+Vector3(0,0,-3.0)
    model.set_meta(STAGE,current)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(ENABLED,enabled)
    return set_stage(model,stage(model))
