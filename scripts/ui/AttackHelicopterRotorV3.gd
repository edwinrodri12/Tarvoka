extends RefCounted
class_name TarvokaAttackHelicopterRotorV3

# A01 V3 studio-only silhouette cleanup based on real 11-frame Godot review.
# Physically REPLACES V1 rotor slabs and wing boxes; never piles copies over them.
# The V1 animation pivots/weapon nodes and the V2 cockpit remain unchanged.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const FLAG := "tarvoka_a01_rotor_wings_v3"
const ROOT := "A01_V3_PerfilAerodinamicoReal"
const BLADE := "A01V3_PalaPrincipalPerfilada_"
const TAIL_BLADE := "A01V3_PalaColaPerfilada_"
const WING := "A01V3_AlaTrapezoidal_"
const GUARD := "A01V3_AroProtectorRotorCola"
const LEGACY_ROTOR := "A01_AspaPortante_"
const LEGACY_TAIL := "A01_AspaCola_"
const LEGACY_WING := "A01_AlaRefuerzo_"
const ENABLED := "tarvoka_a01_v3_enabled"

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and model.find_child(
        ROOT,true,false)!=null

static func _node(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _material(color: Color,metal: float=0.28,
        rough: float=0.66) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _new_root(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        color: Color,position: Vector3=Vector3.ZERO,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.material_override=_material(color)
    n.position=position
    n.rotation_degrees=rotation
    parent.add_child(n)
    return n

static func _box(parent: Node3D,name: String,position: Vector3,
        dimensions: Vector3,color: Color,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape:=BoxMesh.new()
    shape.size=dimensions
    return _mesh(parent,name,shape,color,position,rotation)

static func _cylinder(parent: Node3D,name: String,position: Vector3,
        radius: float,length: float,color: Color,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=length
    shape.radial_segments=14
    return _mesh(parent,name,shape,color,position,rotation)

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _closed_profile(profile: Array[Vector2],
        thickness: float,vertical: bool=false) -> ArrayMesh:
    # Solid closed airfoil; uses center fan top/bottom and side walls.
    # In horizontal mode Vector2 denotes X,Z, vertical denotes Y,Z.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center:=Vector2.ZERO
    for p in profile:
        center+=p
    center/=float(profile.size())
    for i in range(profile.size()):
        var a: Vector2=profile[i]
        var b: Vector2=profile[(i+1)%profile.size()]
        var top_center: Vector3
        var top_a: Vector3
        var top_b: Vector3
        var bottom_center: Vector3
        var bottom_a: Vector3
        var bottom_b: Vector3
        if vertical:
            top_center=Vector3(thickness*0.5,center.x,center.y)
            top_a=Vector3(thickness*0.5,a.x,a.y)
            top_b=Vector3(thickness*0.5,b.x,b.y)
            bottom_center=Vector3(-thickness*0.5,center.x,center.y)
            bottom_a=Vector3(-thickness*0.5,a.x,a.y)
            bottom_b=Vector3(-thickness*0.5,b.x,b.y)
        else:
            top_center=Vector3(center.x,thickness*0.5,center.y)
            top_a=Vector3(a.x,thickness*0.5,a.y)
            top_b=Vector3(b.x,thickness*0.5,b.y)
            bottom_center=Vector3(center.x,-thickness*0.5,center.y)
            bottom_a=Vector3(a.x,-thickness*0.5,a.y)
            bottom_b=Vector3(b.x,-thickness*0.5,b.y)
        _tri(st,top_center,top_a,top_b)
        _tri(st,bottom_center,bottom_b,bottom_a)
        _tri(st,top_a,bottom_a,bottom_b)
        _tri(st,top_a,bottom_b,top_b)
    st.generate_normals()
    return st.commit()

static func _strut(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,color: Color) -> void:
    var direction: Vector3=b-a
    if direction.length_squared()<0.0001:
        return
    var tube:=CylinderMesh.new()
    tube.top_radius=radius
    tube.bottom_radius=radius
    tube.height=direction.length()
    tube.radial_segments=8
    var item:=_mesh(parent,name,tube,color)
    item.position=(a+b)*0.5
    item.quaternion=Quaternion(Vector3.UP,direction.normalized())

static func _main_rotor(model: Node3D) -> bool:
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    var gray:=Color("#373f43")
    var edges:=Color("#717d84")
    var center:=Color("#b7c0c3")
    var cross:=_new_root(rotor,"A01V3_PalasAerodinamicas")
    for i in range(4):
        var pivot: Node3D=_node(rotor,LEGACY_ROTOR+str(i))
        if pivot==null:
            return false
        for child in pivot.get_children():
            if child is MeshInstance3D:
                (child as MeshInstance3D).visible=false
        # Real planform: broad near the mast, tapered end, swept leading edge.
        # 2 cm thickness in local units, instead of a fat uniform rectangular slab.
        var planform: Array[Vector2]=[
            Vector2(-0.100,-0.17),
            Vector2(0.105,-0.17),
            Vector2(0.155,-0.42),
            Vector2(0.165,-1.26),
            Vector2(0.132,-1.75),
            Vector2(0.055,-1.98),
            Vector2(-0.005,-2.02),
            Vector2(-0.072,-1.90),
            Vector2(-0.096,-1.35),
            Vector2(-0.110,-0.45)
        ]
        var wing:=_mesh(pivot,BLADE+str(i),
            _closed_profile(planform,0.037),gray)
        wing.rotation_degrees.z=-1.5
        _box(pivot,"A01V3_BiselRaizAspa_"+str(i),
            Vector3(0,0,-0.225),Vector3(0.23,0.070,0.24),edges)
        _cylinder(pivot,"A01V3_BisagraPaso_"+str(i),
            Vector3(0,0,-0.14),0.070,0.12,center)
    # Swashplate and pitch link pieces share the original spinning rotor.
    var torus:=TorusMesh.new()
    torus.inner_radius=0.20
    torus.outer_radius=0.26
    torus.rings=9
    torus.ring_segments=24
    _mesh(rotor,"A01V3_PlatilloCiclico",torus,edges,
        Vector3(0,-0.125,0))
    _cylinder(rotor,"A01V3_EjePortante",
        Vector3(0,-0.12,0),0.080,0.28,gray)
    for i in range(4):
        var a: float=TAU*float(i)/4.0
        _strut(rotor,"A01V3_BielaPaso_"+str(i),
            Vector3(sin(a)*0.165,-0.12,cos(a)*0.165),
            Vector3(sin(a)*0.27,-0.015,cos(a)*0.27),
            0.018,center)
    cross.set_meta("tarvoka_a01_v3_main_rotor_sculpt",true)
    return true

static func _tail_rotor(model: Node3D,body: Node3D,
        new_root: Node3D) -> bool:
    var rotor: Node3D=_node(model,V1.TAIL_ROTOR)
    if rotor==null:
        return false
    var metal:=Color("#6b7b83")
    var graphite:=Color("#252e36")
    for i in range(4):
        var pivot: Node3D=_node(rotor,LEGACY_TAIL+str(i))
        if pivot==null:
            return false
        for child in pivot.get_children():
            if child is MeshInstance3D:
                (child as MeshInstance3D).visible=false
        var outline: Array[Vector2]=[
            Vector2(-0.043,-0.12),
            Vector2(0.054,-0.12),
            Vector2(0.076,-0.25),
            Vector2(0.054,-0.42),
            Vector2(0.013,-0.48),
            Vector2(-0.033,-0.42),
            Vector2(-0.063,-0.23)
        ]
        _mesh(pivot,TAIL_BLADE+str(i),_closed_profile(
            outline,0.025,true),graphite)
        _cylinder(pivot,"A01V3_BisagraRotorCola_"+str(i),
            Vector3(0,0,-0.14),0.052,0.045,metal,Vector3(0,0,90))
    # Fixed protective hoop in rotor's actual YZ plane. It must not spin.
    var guard:=_new_root(new_root,GUARD)
    var center:=Vector3(0.285,1.38,2.62)
    var n: int=24
    for i in range(n):
        var a: float=TAU*float(i)/float(n)
        var b: float=TAU*float(i+1)/float(n)
        var p:=center+Vector3(0,0.525*sin(a),0.525*cos(a))
        var q:=center+Vector3(0,0.525*sin(b),0.525*cos(b))
        _strut(guard,"A01V3_AroSegmento_%02d" % i,p,q,0.018,metal)
    for support in range(3):
        var angle:=TAU*float(support)/3.0
        var anchor:=center+Vector3(-0.15,0.52*sin(angle),0.52*cos(angle))
        _strut(guard,"A01V3_SoporteAro_%d" % support,
            Vector3(0.17,1.38,2.62),anchor,0.020,graphite)
    return true

static func _wings(model: Node3D,body: Node3D,
        new_root: Node3D,faction: Color) -> bool:
    var dark:=Color("#56656b")
    var armor:=Color("#2b3940")
    for side in [-1,1]:
        var sign: float=float(side)
        var old: Node3D=_node(model,LEGACY_WING+str(side))
        if old==null:
            return false
        old.visible=false
        # Closed tapered planform, centered on existing missile-pod supports.
        # Drawn gray for primary structural realism; faction color as narrow
        # top stripe rather than a huge saturated rectangular billboard.
        var wing:=_new_root(new_root,"A01V3_AlaArticulada_%d" % side)
        var profile: Array[Vector2]=[
            Vector2(sign*0.55,-0.29),
            Vector2(sign*0.88,-0.25),
            Vector2(sign*1.53,-0.14),
            Vector2(sign*1.53,0.12),
            Vector2(sign*0.91,0.33),
            Vector2(sign*0.55,0.32)
        ]
        _mesh(wing,WING+str(side),
            _closed_profile(profile,0.100),dark,
            Vector3(0,0.81,0))
        _box(wing,"A01V3_FranjaFaccion_%d" % side,
            Vector3(sign*1.03,0.868,0.015),
            Vector3(0.67,0.015,0.060),faction)
        _strut(wing,"A01V3_ArticulacionRaiz_%d" % side,
            Vector3(sign*0.57,0.90,-0.26),
            Vector3(sign*0.93,0.73,-0.18),0.034,armor)
        _strut(wing,"A01V3_RiostraBajoAla_%d" % side,
            Vector3(sign*0.60,0.73,0.30),
            Vector3(sign*1.27,0.70,0.18),0.026,armor)
        _box(wing,"A01V3_PuntaProtegida_%d" % side,
            Vector3(sign*1.47,0.83,-0.01),
            Vector3(0.100,0.110,0.22),armor)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    model.set_meta(ENABLED,enabled)
    var root_layer: Node3D=_node(model,ROOT)
    root_layer.visible=enabled
    for side in [-1,1]:
        var wing: Node3D=_node(model,LEGACY_WING+str(side))
        if wing!=null:
            wing.visible=not enabled
    var main: Node3D=_node(model,V1.MAIN_ROTOR)
    var tail: Node3D=_node(model,V1.TAIL_ROTOR)
    for i in range(4):
        var old_main: Node3D=_node(main,LEGACY_ROTOR+str(i))
        var old_tail: Node3D=_node(tail,LEGACY_TAIL+str(i))
        if old_main==null or old_tail==null:
            return false
        for child in old_main.get_children():
            if child is MeshInstance3D:
                (child as MeshInstance3D).visible=not enabled if (
                    str(child.name).begins_with("A01_Pala_") or
                    str(child.name).begins_with("A01_RaizAspa_")) else enabled
        for child in old_tail.get_children():
            if child is MeshInstance3D:
                (child as MeshInstance3D).visible=not enabled if (
                    str(child.name).begins_with("A01_PalaCola_")) else enabled
    if main!=null:
        for child in main.get_children():
            if str(child.name).begins_with("A01V3_"):
                (child as Node3D).visible=enabled
    return true

static func apply(model: Node3D,faction: Color) -> bool:
    if not V2.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_node(model,V1.ROOT)
    if body==null or _node(model,V1.MAIN_ROTOR)==null or (
            _node(model,V1.TAIL_ROTOR)==null):
        return false
    var layer:=_new_root(body,ROOT)
    if not _main_rotor(model) or not _tail_rotor(model,body,layer) or (
            not _wings(model,body,layer,faction)):
        layer.queue_free()
        return false
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
