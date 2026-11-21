extends RefCounted
class_name TarvokaA01ReconFinishV2

# Additive original UAV PBR finish. Adds physical opaque details to the
# SAME A01 wing, twin-boom and EO/IR gimbal on both Android and hero LODs.
# Art only: no vision changes, no weapons, no flight-rule or fog effects.
const FLAG:String="tarvoka_a01_recon_v2_faction_and_optics_finish"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const WING_LIGHT_L:String="A01_V2_NavLightPort"
const WING_LIGHT_R:String="A01_V2_NavLightStarboard"
const LENS_BEZEL:String="A01_V2_EOIRLensProtectiveBezel"
const GIMBAL_SHELL:String="A01_V2_ClosedGimbalRing"
const FACTION_STRIPE:String="A01_V2_LargeFactionWingBand"

static func _mat(color:Color,metal:float=0.24,rough:float=0.54)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _box(root:Node3D,tag:String,at:Vector3,dim:Vector3,
        mat:Material,angles:Vector3=Vector3.ZERO)->MeshInstance3D:
    var mesh:=MeshInstance3D.new()
    mesh.name=tag
    var geo:=BoxMesh.new()
    geo.size=dim
    mesh.mesh=geo
    mesh.material_override=mat
    mesh.position=at
    mesh.rotation_degrees=angles
    root.add_child(mesh)
    return mesh

static func _ring(root:Node3D,tag:String,at:Vector3,radius:float,
        depth:float,mat:Material,sides:int)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=tag
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=depth
    cylinder.radial_segments=sides
    node.mesh=cylinder
    node.material_override=mat
    node.position=at
    node.rotation_degrees.x=90.0
    root.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    return V1.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(LENS_BEZEL,true,false)!=null) and (
        root.find_child(WING_LIGHT_L,true,false)!=null) and (
        root.find_child(WING_LIGHT_R,true,false)!=null)

static func apply(root:Node3D,color:Color,hero:bool)->bool:
    if not V1.has_model(root) or root.get_meta(FLAG,false):
        return false
    var airframe:=root.find_child(V1.BODY,true,false) as Node3D
    var optics:=root.find_child(V1.SENSOR,true,false) as Node3D
    if airframe==null or optics==null:
        return false
    var edge:=_mat(Color("#62747e"),0.61,0.33)
    var graphite:=_mat(Color("#252e36"),0.18,0.73)
    var ceramic:=_mat(Color("#b8c8ce"),0.47,0.32)
    var faction:=_mat(color,0.24,0.39)
    var lens:=_mat(Color("#4c99b7"),0.07,0.12)
    var light_port:=_mat(Color("#c72a37"),0.08,0.35)
    var light_starboard:=_mat(Color("#43ce79"),0.08,0.35)

    # Solid wing edges and flap roots are placed flush to the original
    # 3-D wing meshes; never a 2-D decal or floating invisible panel.
    for side in [-1,1]:
        var sg:float=float(side)
        var tag:String="Port" if side<0 else "Starboard"
        _box(airframe,"A01_V2_WingLeadingEdge_"+tag,
            Vector3(sg*1.00,1.09,-0.325),
            Vector3(1.46,0.042,0.077),edge,Vector3(0,0,sg*2.0))
        _box(airframe,"A01_V2_ClosedFlaperon_"+tag,
            Vector3(sg*1.00,1.08,0.153),
            Vector3(1.16,0.045,0.145),ceramic,Vector3(0,0,sg*2.0))
        _box(airframe,FACTION_STRIPE+"_"+tag,
            Vector3(sg*1.31,1.13,-0.098),
            Vector3(0.39,0.032,0.42),faction,Vector3(0,0,sg*2.0))
        var tip_material:Material=light_port if side<0 else light_starboard
        _box(airframe,WING_LIGHT_L if side<0 else WING_LIGHT_R,
            Vector3(sg*1.69,1.11,-0.22),
            Vector3(0.060,0.050,0.091),tip_material)
        _box(airframe,"A01_V2_TailServoBridge_"+tag,
            Vector3(sg*0.47,0.91,1.36),
            Vector3(0.13,0.15,0.13),graphite)
        if hero:
            _box(airframe,"A01_V2_WingRootFastener_"+tag,
                Vector3(sg*0.44,1.115,-0.11),
                Vector3(0.075,0.025,0.075),edge)
            _box(airframe,"A01_V2_CableChannel_"+tag,
                Vector3(sg*0.46,0.91,0.70),
                Vector3(0.036,0.047,0.65),graphite)

    # Camera optics physically rotate WITH the original gimbal, not with
    # the fuselage, and remain opaque from any 360-degree inspection.
    _ring(optics,GIMBAL_SHELL,Vector3(0,0,-0.185),0.202,0.105,
        ceramic,20 if hero else 10)
    _ring(optics,LENS_BEZEL,Vector3(0,0,-0.255),0.138,0.031,
        graphite,20 if hero else 10)
    _ring(optics,"A01_V2_ClosedOpticalGlass",Vector3(0,0,-0.278),
        0.104,0.018,lens,18 if hero else 8)
    _box(airframe,"A01_V2_OpticalMountCradle",
        Vector3(0,0.655,-0.565),Vector3(0.42,0.11,0.33),edge)
    if hero:
        _box(airframe,"A01_V2_NoseCompositeSeam",
            Vector3(0,1.055,-1.17),Vector3(0.20,0.025,0.125),graphite)
        _box(airframe,"A01_V2_SensorIdentificationPlate",
            Vector3(0,0.77,-0.91),Vector3(0.23,0.028,0.12),faction)
        _box(airframe,"A01_V2_ProtectedAirIntake",
            Vector3(0,1.13,0.62),Vector3(0.26,0.038,0.26),graphite)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v2_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v2_no_fog_or_damage_rules",true)
    root.set_meta("tarvoka_a01_v2_hero_microdetails",hero)
    return has_model(root)
