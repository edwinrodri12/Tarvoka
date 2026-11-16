extends RefCounted
class_name TarvokaAttackHelicopterLandingFinishV6

# A01 V6: physical landing-gear joinery, compact hinge/pins, telescopic dampers,
# curved skid gripping pads, and engine-mount seam. No tactical geometry changes.
# Replaces oversized V5 joint spheres and long flat skid rubber strips.
const V1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const V4 = preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V5 = preload("res://scripts/ui/AttackHelicopterLandingV5.gd")
const ROOT := "A01V6_ArticulacionesYAmortiguacion"
const FLAG := "tarvoka_a01_landing_finish_v6"
const ENABLED := "tarvoka_a01_landing_finish_v6_enabled"
const DAMPER := "A01V6_AmortiguadorExterior_"
const PISTON := "A01V6_PistonCromado_"
const UPPER_PIN := "A01V6_PasadorSuperior_"
const LOWER_PIN := "A01V6_PasadorInferior_"
const CLAMP := "A01V6_AbrazaderaPatin_"
const GRIP := "A01V6_ProtectorGoma_"
const ENGINE_SEAM := "A01V6_CosturaCircularMotor_"
const SEGMENTS := 16

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false)!=null)

static func _part(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _mat(color: Color,metallic: float=0.2,
        roughness: float=0.68) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        color: Color,pos: Vector3=Vector3.ZERO,
        metallic: float=0.2,roughness: float=0.68) -> MeshInstance3D:
    var m:=MeshInstance3D.new()
    m.name=name
    m.mesh=shape
    m.material_override=_mat(color,metallic,roughness)
    m.position=pos
    parent.add_child(m)
    return m

static func _box(parent: Node3D,name: String,pos: Vector3,
        dims: Vector3,color: Color) -> MeshInstance3D:
    var b:=BoxMesh.new()
    b.size=dims
    return _mesh(parent,name,b,color,pos)

static func _rod(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,color: Color,
        metal: float=0.24,rough: float=0.62) -> MeshInstance3D:
    var axis: Vector3=b-a
    var bmesh:=CylinderMesh.new()
    bmesh.top_radius=radius
    bmesh.bottom_radius=radius
    bmesh.height=axis.length()
    bmesh.radial_segments=12
    var item:=_mesh(parent,name,bmesh,color,(a+b)*0.5,metal,rough)
    item.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return item

static func _pin(parent: Node3D,name: String,
        center: Vector3,size: float,
        dark: Color,steel: Color) -> void:
    # A short lateral physical shaft through two socket plates.
    var left: Vector3=center+Vector3(-size*0.53,0,0)
    var right: Vector3=center+Vector3(size*0.53,0,0)
    _rod(parent,name,left,right,0.042,steel,0.62,0.31)
    for side in [-1,1]:
        var s: float=float(side)
        _rod(parent,name+"_Arandela_"+str(side),
            center+Vector3(s*size*0.52,0,0),
            center+Vector3(s*size*0.67,0,0),0.061,dark)
    for side in [-1,1]:
        var s: float=float(side)
        _box(parent,name+"_Oreja_"+str(side),
            center+Vector3(s*size*0.32,-0.045,0),
            Vector3(0.025,0.115,0.115),dark)

static func _shock(parent: Node3D,side: int,index: int) -> void:
    var sign: float=float(side)
    var top_z: float=-0.58 if index==0 else 0.62
    var bottom_z: float=-0.66 if index==0 else 0.75
    var upper:=Vector3(sign*0.37,0.80,top_z)
    var lower:=Vector3(sign*0.674,0.20,bottom_z)
    var direction: Vector3=lower-upper
    var graphite:=Color("#28343c")
    var steel:=Color("#839199")
    var chrome:=Color("#c1d0d5")
    var neoprene:=Color("#151e24")
    var key: String="%d_%d" % [side,index]
    # The shock surrounds (not duplicates) the real V5 inclined structural rod.
    _rod(parent,DAMPER+key,
        upper+direction*0.17,upper+direction*0.52,0.068,graphite,0.48,0.42)
    _rod(parent,PISTON+key,
        upper+direction*0.48,upper+direction*0.84,0.037,chrome,0.82,0.22)
    _rod(parent,"A01V6_CollarSuperior_"+key,
        upper+direction*0.18,upper+direction*0.25,0.076,steel)
    _rod(parent,"A01V6_CollarInferior_"+key,
        upper+direction*0.48,upper+direction*0.55,0.075,steel)
    _rod(parent,"A01V6_RetenPolvo_"+key,
        upper+direction*0.56,upper+direction*0.64,0.053,neoprene)
    _pin(parent,UPPER_PIN+key,upper,0.155,graphite,chrome)
    _pin(parent,LOWER_PIN+key,lower,0.155,graphite,chrome)

static func _skid_rails(parent: Node3D,side: int,faction: Color) -> void:
    var sign: float=float(side)
    var steel:=Color("#88969e")
    var rubber:=Color("#1c292e")
    var matte:=Color("#354247")
    var dark:=Color("#222d33")
    # Clamp centers match the real V5 skid geometry, not guessed vertical bars.
    for index in range(2):
        var z: float=-0.66 if index==0 else 0.75
        var center:=Vector3(sign*0.675,0.17,z)
        var guard:=TorusMesh.new()
        guard.inner_radius=0.052
        guard.outer_radius=0.077
        guard.rings=8
        guard.ring_segments=20
        var clamp:=_mesh(parent,CLAMP+"%d_%d" % [side,index],
            guard,matte,center,0.44,0.52)
        # A ring's hole must be perpendicular to the rail tangent (Z).
        clamp.rotation_degrees.x=90.0
        _box(parent,"A01V6_TornilloAbrazadera_%d_%d" % [side,index],
            center+Vector3(sign*0.076,0.014,0.0),
            Vector3(0.023,0.021,0.022),steel)
    # Four short insert pads conform to the side of the actual rail; they
    # replace V5's single long rectangular strip and avoid hanging ends.
    for index in range(4):
        var center_z: float=-0.57+float(index)*0.39
        var outline: Array[Vector2]=[
            Vector2(0.161,center_z-0.138),
            Vector2(0.191,center_z-0.125),
            Vector2(0.206,center_z-0.095),
            Vector2(0.206,center_z+0.095),
            Vector2(0.191,center_z+0.125),
            Vector2(0.161,center_z+0.138)
        ]
        var pad:=_mesh(parent,GRIP+"%d_%d" % [side,index],
            V4._panel_solid(outline,0.018),
            rubber,Vector3(sign*0.730,0,0),0.05,0.91)
        pad.rotation_degrees.y=sign*3.5
    # A compact protective cap follows each curved rail endpoint.
    var endpoints: Array[Vector3]=[
        Vector3(sign*0.645,0.39,-1.23),
        Vector3(sign*0.660,0.33,1.29)]
    var inside: Array[Vector3]=[
        Vector3(sign*0.653,0.324,-1.16),
        Vector3(sign*0.667,0.264,1.20)]
    for index in range(2):
        _rod(parent,"A01V6_TaponExtremo_%d_%d" % [side,index],
            endpoints[index],inside[index],0.063,dark,0.07,0.9)
    _box(parent,"A01V6_MarcaMantenimiento_"+str(side),
        Vector3(sign*0.735,0.183,0.68),
        Vector3(0.011,0.027,0.087),faction)

static func _engine_seams(parent: Node3D,side: int) -> void:
    var sign: float=float(side)
    var metal:=Color("#89979c")
    var graphite:=Color("#303d43")
    # Weld seam physically follows the elliptical V5 engine saddle's y=1.43
    # section rather than a floating circumferential decoration.
    var center_x: float=sign*0.335
    var center_z: float=0.645
    var rx: float=0.218
    var rz: float=0.365
    for index in range(SEGMENTS):
        var a: float=TAU*float(index)/float(SEGMENTS)
        var b: float=TAU*float(index+1)/float(SEGMENTS)
        _rod(parent,ENGINE_SEAM+"%d_%02d" % [side,index],
            Vector3(center_x+cos(a)*rx,1.432,center_z+sin(a)*rz),
            Vector3(center_x+cos(b)*rx,1.432,center_z+sin(b)*rz),
            0.010,graphite,0.42,0.55)
    # Four visible mounting studs belong to the metal shoulder, not the glass.
    for index in range(2):
        var z: float=0.43 if index==0 else 0.87
        _rod(parent,"A01V6_PernoBaseMotor_%d_%d" % [side,index],
            Vector3(sign*0.555,1.405,z),
            Vector3(sign*0.590,1.405,z),0.032,metal,0.65,0.35)

static func _toggle_old(model: Node3D,enabled: bool) -> bool:
    # V6 must not leave hidden prior rubber/pivot pieces over the new joinery.
    for side in [-1,1]:
        var stripe:=_part(model,"A01V5_BandaGomaAntideslizante_"+str(side))
        if stripe==null:
            return false
        stripe.visible=not enabled
        for index in range(2):
            for prefix in ["A01V5_AnclajeSuperior_","A01V5_CodoInferior_"]:
                var joint:=_part(model,prefix+"%d_%d" % [side,index])
                if joint==null:
                    return false
                joint.visible=not enabled
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    if not _toggle_old(model,enabled):
        return false
    var layer: Node3D=_part(model,ROOT)
    layer.visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,faction: Color) -> bool:
    if not V5.has_model(model):
        return false
    if has_model(model):
        return true
    var parent: Node3D=_part(model,V5.ROOT)
    if parent==null:
        return false
    for side in [-1,1]:
        if _part(model,"A01V5_BandaGomaAntideslizante_"+str(side))==null:
            return false
        for index in range(2):
            for prefix in ["A01V5_AnclajeSuperior_","A01V5_CodoInferior_"]:
                if _part(model,prefix+"%d_%d" % [side,index])==null:
                    return false
    var layer:=_group(parent,ROOT)
    for side in [-1,1]:
        _skid_rails(layer,side,faction)
        for index in range(2):
            _shock(layer,side,index)
        _engine_seams(layer,side)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
