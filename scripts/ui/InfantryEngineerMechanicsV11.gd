extends RefCounted
class_name TarvokaInfantryEngineerMechanicsV11

# Engineering infantry: true volumetric press-formed abdominal armor, joint
# continuity and coaxial mechanical hinge details on the EXISTING moving rigs.
# The shield remains an inspection prop (V6): NO cover/camp/stat/collision
# behavior, no new production buildings or changed damage rules.
const FLAG := "tarvoka_engineer_formed_torso_coaxial_hinges_v11"
const LOWER := "V11_CorazaAbdominalCurvaCerrada"
const LATERAL := "V11_CostillaFrontalCurva"
const HIP := "V11_CojineteCadera"
const SHOULDER := "V11_SelloArticuladoHombro"
const HINGE_FIXED := "V11_CasquilloBisagraFijo"
const HINGE_MOVING := "V11_EjeBisagraGiratorio"
const WING := "V11_CierreAlaMecanizado"
const ROLE := "infantry_engineer"

static func _coat(color: Color, metal: float, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color=Color(color.r,color.g,color.b,1.0)
    mat.metallic=metal
    mat.roughness=roughness
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    return mat

static func _mesh(parent: Node3D, name: String, shape: Mesh,
        at: Vector3, mat: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name=name
    item.mesh=shape
    item.material_override=mat
    item.position=at
    parent.add_child(item)
    return item

static func _ball(parent: Node3D, name: String, at: Vector3,
        size: Vector3, mat: Material, hero: bool) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius=0.5
    shape.height=1.0
    shape.radial_segments=18 if hero else 10
    shape.rings=9 if hero else 6
    var item: MeshInstance3D=_mesh(parent,name,shape,at,mat)
    item.scale=size
    return item

static func _box(parent: Node3D, name: String, at: Vector3,
        size: Vector3, mat: Material) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size=size
    return _mesh(parent,name,shape,at,mat)

static func _pin(parent: Node3D, name: String, at: Vector3,
        length: float, radius: float, mat: Material, hero: bool,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.height=length
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.radial_segments=14 if hero else 8
    var item: MeshInstance3D=_mesh(parent,name,shape,at,mat)
    item.rotation_degrees=rotation
    return item

# 8-sided *fully closed*, convex press-formed armor. The front center bulges
# forward (-Z), perimeter returns to the back on solid side walls. Unlike
# a billboard, all four camera sides and the rear of this mesh contain faces.
static func _pressed_plate(parent: Node3D, name: String, at: Vector3,
        width: float, height: float, thick: float, cut: float,
        bulge: float, mat: Material) -> MeshInstance3D:
    var x: float=width*0.5
    var y: float=height*0.5
    var c: float=minf(cut,minf(width,height)*0.24)
    var outline: Array[Vector2]=[
        Vector2(-x+c,-y),Vector2(x-c,-y),
        Vector2(x,-y+c),Vector2(x,y-c),
        Vector2(x-c,y),Vector2(-x+c,y),
        Vector2(-x,y-c),Vector2(-x,-y+c)
    ]
    var front_z: float=-thick*0.5
    var rear_z: float=thick*0.5
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(outline.size()):
        var j: int=(i+1)%outline.size()
        var a: Vector2=outline[i]
        var b: Vector2=outline[j]
        var af := Vector3(a.x,a.y,front_z)
        var bf := Vector3(b.x,b.y,front_z)
        var ar := Vector3(a.x,a.y,rear_z)
        var br := Vector3(b.x,b.y,rear_z)
        # Closed front, back and all perimeter sides.
        for point in [
            Vector3(0,0,front_z-bulge),bf,af,
            Vector3(0,0,rear_z),ar,br,
            af,bf,br,af,br,ar
        ]:
            tool.add_vertex(point)
    tool.generate_normals()
    return _mesh(parent,name,tool.commit(),at,mat)

static func _find(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return (model!=null and bool(model.get_meta(FLAG,false)) and
        _find(model,LOWER)!=null and
        _find(model,HINGE_FIXED+"_1")!=null and
        _find(model,HINGE_MOVING+"_-1")!=null)

static func apply(model: Node3D, faction: Color, hero: bool) -> bool:
    if model==null or has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!=ROLE or not bool(
            model.get_meta("tarvoka_engineer_anatomy_v10",false)):
        return false
    var chest: Node3D=_find(model,"TorsoRig")
    var hips: Node3D=_find(model,"CaderaRig")
    var hinge: Node3D=_find(model,"V6_BarreraArticuladaRig")
    var left: Node3D=_find(model,"V6_AlaIzquierdaRig")
    var right: Node3D=_find(model,"V6_AlaDerechaRig")
    if chest==null or hips==null or hinge==null or left==null or right==null:
        return false
    if hinge.get_parent()!=chest:
        return false
    for side in [-1,1]:
        if (_find(model,"BrazoRig_%d"%side)==null or
                _find(model,"PiernaRig_%d"%side)==null):
            return false

    var armor := _coat(Color("#84999d"),0.40,0.39)
    var steel := _coat(Color("#b4c0c1"),0.67,0.31)
    var dark := _coat(Color("#2c383a"),0.10,0.84)
    var fabric := _coat(Color("#4e6358"),0.01,0.93)
    var marking := _coat(faction,0.18,0.36)

    # The V8 faction crest stays exposed ABOVE. Only the lower vest becomes
    # contoured steel, rather than another cuboid covering the entire chest.
    _pressed_plate(chest,LOWER,Vector3(0,-0.190,-0.447),
        0.50,0.215,0.040,0.045,0.036,armor)
    _pressed_plate(chest,"V11_CintaColorEnPetoCurvo",
        Vector3(0,-0.239,-0.515),0.250,0.046,0.023,0.010,0.004,marking)
    for side in [-1,1]:
        var x: float=float(side)
        _pressed_plate(chest,LATERAL+"_%d"%side,
            Vector3(x*0.303,-0.065,-0.370),
            0.105,0.296,0.036,0.021,0.024,armor)
        _ball(chest,"V11_SelloBajoAxila_%d"%side,
            Vector3(x*0.377,0.172,-0.077),
            Vector3(0.14,0.185,0.155),fabric,hero)

        # Articulating shoulder shells are on BrazoRig; hip sockets sit
        # on CaderaRig, while the inner bearing moves on each PiernaRig.
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        var leg: Node3D=_find(model,"PiernaRig_%d"%side)
        _ball(arm,SHOULDER+"_%d"%side,
            Vector3(0,-0.151,0.034),
            Vector3(0.215,0.203,0.208),dark,hero)
        _ball(hips,HIP+"_%d"%side,
            Vector3(x*0.205,-0.049,-0.012),
            Vector3(0.245,0.198,0.230),fabric,hero)
        _ball(leg,"V11_CabezalFemurCerrado_%d"%side,
            Vector3(0,0.017,-0.080),
            Vector3(0.204,0.175,0.169),dark,hero)

        # True physical coaxial pivot: a fixed sleeve on TorsoRig and a
        # moving metal axle at the origin of the existing V6 shield pivot.
        # Their centers remain coincident at ALL shield opening angles.
        _pin(chest,HINGE_FIXED+"_%d"%side,
            Vector3(x*0.42,0.10,0.55),0.154,0.076,dark,hero,
            Vector3(0,0,90))
        _pin(hinge,HINGE_MOVING+"_%d"%side,
            Vector3(x*0.42,0,0),0.171,0.047,steel,hero,
            Vector3(0,0,90))
        # Wing bolts must be children of the wing's own rotation hinge,
        # never free-floating on a stationary torso or nonmoving panel.
        var wing: Node3D=left if side<0 else right
        _pin(wing,WING+"_%d"%side,
            Vector3(x*0.082,0.263,0.069),0.105,0.038,steel,hero,
            Vector3(90,0,0))
        _box(wing,"V11_PernoRetencionAla_%d"%side,
            Vector3(x*0.082,-0.263,0.075),
            Vector3(0.075,0.092,0.043),dark)
        if hero:
            # Visible maintenance clasps and faction ID on the moving wing.
            _box(wing,"V11_CierreColorAla_%d"%side,
                Vector3(x*0.083,-0.105,0.134),
                Vector3(0.099,0.057,0.023),marking)
            _box(chest,"V11_BrocheCinturonFijado_%d"%side,
                Vector3(x*0.245,-0.350,-0.258),
                Vector3(0.060,0.075,0.042),steel)

    # Neither old construction visor nor existing physical V8 shield core
    # has been hidden, removed or detached.
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v11_art_only",true)
    model.set_meta("tarvoka_engineer_v11_hero",hero)
    return true
