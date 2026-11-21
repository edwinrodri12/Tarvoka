extends RefCounted
class_name TarvokaA01ReconDamageV6

# V6: visual-only cumulative damage on the ORIGINAL A01 recon UAV.
# It NEVER changes HP, attack, fog, economy, movement or supplies.
# All materials stay opaque. Damage/repair is deterministic and reversible.
const FLAG:String="tarvoka_a01_v6_visual_damage"
const STAGE_KEY:String="tarvoka_a01_v6_damage_stage"
const EFFECTS:String="A01_V6_VisualDamageRig"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const V5=preload("res://scripts/ui/A01ReconTailV5.gd")
const STAGES=["D0 · intacto","D1 · impactos leves","D2 · carcasa dañada y humo",
    "D3 · avería crítica y fuego","D4 · destruido"]

static func _material(color:Color,metallic:float,roughness:float,
        glow:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    if glow:
        m.emission_enabled=true
        m.emission=color
        m.emission_energy_multiplier=1.7
    return m

static func _box(parent:Node3D,label:String,where:Vector3,dim:Vector3,
        mat:Material,rotation:Vector3=Vector3.ZERO)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=BoxMesh.new()
    mesh.size=dim
    n.mesh=mesh
    n.material_override=mat
    n.position=where
    n.rotation_degrees=rotation
    parent.add_child(n)
    return n

static func _orb(parent:Node3D,label:String,where:Vector3,dim:Vector3,
        mat:Material,hero:bool)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=12 if hero else 8
    mesh.rings=6 if hero else 4
    n.mesh=mesh
    n.scale=dim
    n.position=where
    n.material_override=mat
    parent.add_child(n)
    return n

static func _plume(parent:Node3D,label:String,where:Vector3,
        bottom_radius:float,top_radius:float,height:float,
        mat:Material,hero:bool,tilt:float=0.0)->MeshInstance3D:
    # Tiny tapered solid smoke/flame; the old spherical clouds appeared
    # like unsupported floating balloons above this small aircraft.
    # Single opaque low-poly draw, compatible with Android LOD8.
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=CylinderMesh.new()
    mesh.bottom_radius=bottom_radius
    mesh.top_radius=top_radius
    mesh.height=height
    mesh.radial_segments=9 if hero else 6
    n.mesh=mesh
    n.position=where
    n.rotation_degrees.z=tilt
    n.material_override=mat
    parent.add_child(n)
    return n

static func _layer(rig:Node3D,index:int)->Node3D:
    var layer:=Node3D.new()
    layer.name="A01_V6_DamageLayer_"+str(index)
    rig.add_child(layer)
    return layer

static func _find_layer(root:Node3D,index:int)->Node3D:
    return root.find_child("A01_V6_DamageLayer_"+str(index),true,false) as Node3D

static func has_model(root:Node3D)->bool:
    return root!=null and V5.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(EFFECTS,true,false) is Node3D) and (
        _find_layer(root,4)!=null)

static func stage(root:Node3D)->int:
    if not has_model(root):
        return -1
    return clampi(int(root.get_meta(STAGE_KEY,0)),0,4)

static func prepare(root:Node3D,hero:bool)->bool:
    if root==null or not V5.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    var rig:=Node3D.new()
    rig.name=EFFECTS
    body.add_child(rig)
    var soot:=_material(Color("#3a4146"),0.12,0.87)
    var blast:=_material(Color("#151e24"),0.10,0.92)
    var hot:=_material(Color("#eb7a2e"),0.06,0.51,true)
    var steel:=_material(Color("#788993"),0.48,0.56)
    var smoke:=_material(Color("#57636c"),0.04,0.97)

    var d1:=_layer(rig,1)
    _box(d1,"A01_V6_D1_PortWingScuff",Vector3(-0.97,1.142,-0.064),
        Vector3(0.52,0.026,0.100),soot,Vector3(0,21,0))
    _box(d1,"A01_V6_D1_NoseScuff",Vector3(0.13,1.125,-0.89),
        Vector3(0.085,0.018,0.24),soot,Vector3(0,-20,11))

    var d2:=_layer(rig,2)
    _box(d2,"A01_V6_D2_ScorchedWingRoot",Vector3(0.45,1.125,0.005),
        Vector3(0.29,0.026,0.23),blast,Vector3(0,16,0))
    _box(d2,"A01_V6_D2_FraggedTrailingPlate",Vector3(0.81,1.096,0.20),
        Vector3(0.21,0.032,0.13),steel,Vector3(0,0,26))
    _plume(d2,"A01_V6_SmokePlume_0",Vector3(0.25,1.29,0.19),
        0.085,0.025,0.30,smoke,hero,12.0)
    _plume(d2,"A01_V6_SmokePlume_1",Vector3(0.32,1.53,0.24),
        0.112,0.018,0.39,soot,hero,-16.0)

    var d3:=_layer(rig,3)
    _box(d3,"A01_V6_D3_BurntTailRoot",Vector3(-0.45,1.005,1.34),
        Vector3(0.20,0.026,0.23),blast)
    _plume(d3,"A01_V6_EngineEmber_0",Vector3(0.0,1.105,1.04),
        0.080,0.008,0.23,hot,hero,9.0)
    _plume(d3,"A01_V6_EngineEmber_1",Vector3(0.11,1.225,1.09),
        0.057,0.005,0.16,hot,hero,-11.0)
    _box(d3,"A01_V6_D3_BentAccessPanel",Vector3(0.20,1.145,0.65),
        Vector3(0.23,0.035,0.21),steel,Vector3(0,0,22))

    var d4:=_layer(rig,4)
    _box(d4,"A01_V6_D4_OpenWingFracture",Vector3(1.35,1.08,0.10),
        Vector3(0.25,0.05,0.28),blast,Vector3(0,0,-28))
    _box(d4,"A01_V6_D4_DetachedCompositeShard",Vector3(1.44,0.74,0.18),
        Vector3(0.28,0.06,0.22),steel,Vector3(22,18,-33))
    _box(d4,"A01_V6_D4_BrokenPropBlade",Vector3(-0.20,0.78,1.25),
        Vector3(0.34,0.055,0.13),blast,Vector3(14,-28,22))
    _plume(d4,"A01_V6_D4_ThickSmoke",Vector3(-0.12,1.47,0.60),
        0.165,0.027,0.46,smoke,hero,16.0)
    _plume(d4,"A01_V6_D4_FinalEmber",Vector3(0.0,0.95,1.01),
        0.090,0.004,0.19,hot,hero,-8.0)

    root.set_meta(FLAG,true)
    root.set_meta(STAGE_KEY,0)
    root.set_meta("tarvoka_a01_v6_visual_only",true)
    root.set_meta("tarvoka_a01_v6_lod",13 if hero else 8)
    return set_stage(root,0)

static func set_stage(root:Node3D,new_stage:int)->bool:
    if not has_model(root) or new_stage<0 or new_stage>4:
        return false
    for index in range(1,5):
        var layer:=_find_layer(root,index)
        if layer==null:
            return false
        layer.visible=new_stage>=index
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    var prop:=root.find_child(V1.PROPELLER,true,false) as Node3D
    if body==null or prop==null:
        return false
    body.rotation_degrees.z=(-14.0 if new_stage==4 else
        -3.5 if new_stage==3 else 0.0)
    body.position.y=-0.18 if new_stage==4 else 0.0
    # Rotor blades disappear ONLY on physical destruction; fixed motor
    # and sensor geometry are preserved for 360 examination and repair.
    for blade_idx in range(3):
        var rotor:=prop.find_child("A01_V3_PusherBladePivot_"+str(blade_idx),
            true,false) as Node3D
        if rotor!=null:
            rotor.visible=new_stage<4
    root.set_meta(STAGE_KEY,new_stage)
    return true

static func repair(root:Node3D)->bool:
    if not has_model(root):
        return false
    V1.restore(root)
    return set_stage(root,0)

static func animate(root:Node3D,clock:float)->bool:
    if not has_model(root) or stage(root)<2:
        return false
    # Two narrow physical smoke plumes move; no fake alpha circles.
    for index in range(2):
        var vapor:=root.find_child("A01_V6_SmokePlume_"+str(index),
            true,false) as MeshInstance3D
        if vapor!=null:
            vapor.position.y=(1.29 if index==0 else 1.53)+(
                0.055*sin(clock*2.0+float(index)))
            vapor.position.x=(0.25 if index==0 else 0.32)+(
                0.025*sin(clock*1.3+float(index)))
    return true
