extends RefCounted
class_name TarvokaAPCDetailV5

# P06 Bastion V5 — ACTUAL native 3D Godot meshes (no 2D art).
# Lightweight material-batched finishing geometry added to the existing
# six-wheeled chassis, remote turret, ramp and five damage stages.
# V4 already identifies the static batching optimization; V5 is the
# subsequent authored exterior finishing pass, NOT a gameplay upgrade.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V2=preload("res://scripts/ui/APCArmorV2.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const ROOT: String="APC_P06_V5_AcabadosComerciales"
const ROOF: String="P06V5_TechoAcabado"
const BOLTS: String="P06V5_PernosDeCoraza"
const FLAG: String="tarvoka_apc_detail_v5"

static func _quad(vertices: Array[Vector3],
        a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
    vertices.append_array([a,b,c,a,c,d])

static func _mesh(parent: Node3D,name: String,
        vertices: Array[Vector3],material: Material,
        paint: bool=false) -> MeshInstance3D:
    if vertices.size()<3:
        return null
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for vertex in vertices:
        st.add_vertex(vertex)
    st.generate_normals()
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=st.commit()
    node.material_override=material
    if paint:
        # Same recolor hook as V3; all eight official faction paints work.
        node.set_meta(V3.PAINT,true)
    parent.add_child(node)
    return node

static func _bolt_group(parent: Node3D,steel: Material) -> int:
    # One draw-call batch instead of separate meshes for 36 mechanical
    # fasteners. Bolts are native 3D geometry, not texture/decal fakes.
    var transforms: Array[Transform3D]=[]
    # Roof rivet rows on the outer continuous armor panel.
    for side in [-1,1]:
        for n in range(10):
            var x: float=float(side)*0.57
            var z: float=-0.44+float(n)*0.126
            transforms.append(Transform3D(
                Basis().scaled(Vector3(0.022,0.009,0.022)),
                Vector3(x,1.503,z)))
    # Side fasteners on upper skirts; Y axis of the bolt faces outward.
    for side in [-1,1]:
        for n in range(8):
            var x: float=float(side)*0.839
            var z: float=-1.00+float(n)*0.270
            var rotation:=Basis(Vector3.FORWARD,PI*0.5*float(side))
            transforms.append(Transform3D(
                rotation.scaled(Vector3(0.021,0.012,0.021)),
                Vector3(x,1.155,z)))
    var bolt:=CylinderMesh.new()
    bolt.top_radius=0.5
    bolt.bottom_radius=0.5
    bolt.height=1.0
    bolt.radial_segments=6
    var mm:=MultiMesh.new()
    mm.mesh=bolt
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.instance_count=transforms.size()
    for i in range(transforms.size()):
        mm.set_instance_transform(i,transforms[i])
    var batch:=MultiMeshInstance3D.new()
    batch.name=BOLTS
    batch.multimesh=mm
    batch.material_override=steel
    parent.add_child(batch)
    return transforms.size()

static func apply(model: Node3D,color: Color) -> bool:
    if model==null or not model.get_meta("tarvoka_apc_finish_v3",false):
        return false
    if model.get_meta(FLAG,false):
        return false
    var v3: Node3D=model.find_child(V3.ROOT,true,false) as Node3D
    var turret: Node3D=model.find_child("EstacionRemotaP06",true,false) as Node3D
    if v3==null or turret==null:
        return false
    var root:=Node3D.new()
    root.name=ROOT
    v3.add_child(root)
    var roof:=Node3D.new()
    roof.name=ROOF
    root.add_child(roof)
    var main: Material=V2._coated(V2._main_color(color),0.36,0.83)
    var edge: Material=V2._coated(Color("#26363C"),0.46,0.77)
    var weld: Material=V2._coated(Color("#697478"),0.42,0.90)
    var glass: Material=V2._coated(Color("#316078"),0.08,0.27)

    # A real faceted roof with flush service covers. The original
    # V3 ceiling remains sealed; these shallow added panels are not a
    # floating box or an independent replacement roof.
    var plates: Array[Vector3]=[]
    var joins: Array[Vector3]=[]
    for side in [-1,1]:
        var s: float=float(side)
        _quad(plates,
            Vector3(s*0.19,1.507,-0.32),
            Vector3(s*0.49,1.507,-0.28),
            Vector3(s*0.48,1.507,0.17),
            Vector3(s*0.20,1.507,0.21))
        for z in [-0.32,0.17]:
            _quad(joins,
                Vector3(s*0.18,1.510,z),
                Vector3(s*0.51,1.510,z+0.015),
                Vector3(s*0.51,1.513,z+0.028),
                Vector3(s*0.18,1.513,z+0.012))
    _mesh(roof,"P06V5_TapasTechoEnrasadas",plates,main,true)
    _mesh(roof,"P06V5_BordesHatchYJuntas",joins,edge)

    # One visible armored applique per side, contiguous with V2 side
    # plates. Light faceted raised ribbing and fender reinforcement.
    var skirts: Array[Vector3]=[]
    var skirt_welds: Array[Vector3]=[]
    for side in [-1,1]:
        var s: float=float(side)
        for z in [-0.92,0.11,0.68]:
            _quad(skirts,
                Vector3(s*0.837,1.17,z),
                Vector3(s*0.843,1.17,z+0.25),
                Vector3(s*0.853,1.06,z+0.25),
                Vector3(s*0.850,1.06,z))
            _quad(skirt_welds,
                Vector3(s*0.851,1.055,z),
                Vector3(s*0.855,1.055,z+0.25),
                Vector3(s*0.855,1.068,z+0.25),
                Vector3(s*0.851,1.068,z))
    _mesh(root,"P06V5_BandasBlindajeModular",skirts,main,true)
    _mesh(root,"P06V5_SoldaduraFlancos",skirt_welds,weld)

    # Practical front service intake and rear work-light recesses.
    # Combine the small details in ONE dark-metal mesh.
    var grilles: Array[Vector3]=[]
    for row in range(4):
        var y: float=0.88+float(row)*0.034
        _quad(grilles,
            Vector3(-0.28,y,-1.470),Vector3(0.28,y,-1.470),
            Vector3(0.28,y+0.010,-1.474),
            Vector3(-0.28,y+0.010,-1.474))
    for side in [-1,1]:
        var s: float=float(side)
        _quad(grilles,
            Vector3(s*0.44,1.02,1.455),Vector3(s*0.65,1.02,1.455),
            Vector3(s*0.65,1.12,1.455),Vector3(s*0.44,1.12,1.455))
    _mesh(root,"P06V5_RejillasProaYLucesTraseras",grilles,edge)

    # Extra sensor shroud moves WITH the remote turret pivot. Native glass
    # lens remains visible while the gun fires and turns.
    var turret_finish:=Node3D.new()
    turret_finish.name="P06V5_SensoresEnTorreta"
    turret.add_child(turret_finish)
    var sensor: Array[Vector3]=[]
    _quad(sensor,
        Vector3(-0.14,0.40,-0.21),Vector3(0.12,0.40,-0.21),
        Vector3(0.14,0.36,0.10),Vector3(-0.14,0.36,0.10))
    _mesh(turret_finish,"P06V5_CubiertaTermica",sensor,main,true)
    var lens: Array[Vector3]=[]
    _quad(lens,
        Vector3(-0.082,0.38,-0.228),Vector3(0.067,0.38,-0.228),
        Vector3(0.067,0.326,-0.233),Vector3(-0.082,0.326,-0.233))
    _mesh(turret_finish,"P06V5_VidrioOpticaPrincipal",lens,glass)

    # Hide both roof and flank fasteners with the wreck's damaged shell.
    var bolt_count: int=_bolt_group(roof,weld)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_apc_v5_bolt_count",bolt_count)
    model.set_meta("tarvoka_apc_v5_visual_meshes",7)
    return true

# Reversible V3/V5 comparison in the actual Godot editor, web and Android.
# No model rebuild, no animation reset, no new textures or combat edits.
static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var exterior: Node3D=model.find_child(ROOT,true,false) as Node3D
    var sensors: Node3D=model.find_child(
        "P06V5_SensoresEnTorreta",true,false) as Node3D
    if exterior==null or sensors==null:
        return false
    exterior.visible=enabled
    sensors.visible=enabled
    model.set_meta("tarvoka_apc_v5_visible",enabled)
    return true
