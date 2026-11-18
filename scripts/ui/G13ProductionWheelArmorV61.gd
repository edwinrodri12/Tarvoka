extends RefCounted
class_name TarvokaG13ProductionWheelArmorV61

# G13 V61: physically comparable finish to the approved P06 Bastion.
# Replace each FLAT armored wheel hub with one true open eight-spoke
# machined wheel; 8 existing captive bolts sit exactly on the 8 spokes.
# The existing dark V7 brake/shield disk shows through the 8 REAL holes.
# The original 4-spinning-wheels MultiMesh and V46 bolt/rim transforms
# remain the same. No new draw nodes, per-frame code or weapon effects.
# Improve PBR light response on original armor panels, preserve every
# armor/faction albedo and the existing V59 reflective glass unchanged.
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const V46=preload("res://scripts/ui/G13WheelMachiningV46.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const FLAG="tarvoka_g13_v61_open_machined_wheel_and_armored_pbr"
const SAVED="tarvoka_g13_v61_original_meshes_and_coats"
const HUB=V46.HUBS
const RING=V46.RINGS
const OUTER="G13_V7_OuterRims"
const SPOKES=8
const HUB_RADIUS=0.147
const SPOKE_R_IN=0.052
const SPOKE_R_OUT=0.133
const RING_IN=0.121
const RING_OUT=HUB_RADIUS
const HUB_HALF_THICK=0.013
const EXTRA_DRAW_NODES=0
const ARMOR=[
    "G13_LowerMonocoque",
    "G13_SlopedGlacis",
    "G13_EngineCover",
    "G13_V10_ChamferedCabShell",
    "G13_V10_ChamferedTurretShell",
    "G13_V44_FacetedSideArmor",
    "G13_V45_LowerFacetedServiceHatches",
    "G13_V11_ArmoredRoof",
    "G13_V37_SculptedRoofShoulders"
]
static var _hero_open:ArrayMesh
static var _mobile_open:ArrayMesh

static func _metal_point(radius:float,angle:float,
        y:float)->Vector3:
    # V46 CylinderMesh is axial-Y; its 4 transforms already roll with X.
    return Vector3(radius*cos(angle),y,radius*sin(angle))

static func _vertex(st:SurfaceTool,
        point:Vector3,color:Color)->void:
    st.set_color(color)
    st.add_vertex(point)

static func _triangle(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3,color:Color)->void:
    _vertex(st,a,color)
    _vertex(st,b,color)
    _vertex(st,c,color)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3,d:Vector3,color:Color)->void:
    _triangle(st,a,b,c,color)
    _triangle(st,a,c,d,color)

static func _ring_geometry(st:SurfaceTool,high:bool)->void:
    var segments:int=48 if high else 24
    var front:=Color("#a8b3b6")
    var edge:=Color("#657176")
    for i in range(segments):
        var a:float=TAU*float(i)/float(segments)
        var b:float=TAU*float(i+1)/float(segments)
        var ri0:=_metal_point(RING_IN,a,-HUB_HALF_THICK)
        var ri1:=_metal_point(RING_IN,b,-HUB_HALF_THICK)
        var ro0:=_metal_point(RING_OUT,a,-HUB_HALF_THICK)
        var ro1:=_metal_point(RING_OUT,b,-HUB_HALF_THICK)
        var fi0:=_metal_point(RING_IN,a,HUB_HALF_THICK)
        var fi1:=_metal_point(RING_IN,b,HUB_HALF_THICK)
        var fo0:=_metal_point(RING_OUT,a,HUB_HALF_THICK)
        var fo1:=_metal_point(RING_OUT,b,HUB_HALF_THICK)
        _quad(st,fi0,fo0,fo1,fi1,front)
        _quad(st,ri1,ro1,ro0,ri0,front.darkened(0.22))
        _quad(st,ro0,ro1,fo1,fo0,edge)
        _quad(st,ri1,ri0,fi0,fi1,edge.darkened(0.16))

static func _central_boss(st:SurfaceTool,high:bool)->void:
    var segments:int=32 if high else 20
    var face:=Color("#96a4a8")
    var edge:=Color("#526267")
    var inner_radius:float=0.061
    for i in range(segments):
        var a:float=TAU*float(i)/float(segments)
        var b:float=TAU*float(i+1)/float(segments)
        var f0:=_metal_point(inner_radius,a,HUB_HALF_THICK)
        var f1:=_metal_point(inner_radius,b,HUB_HALF_THICK)
        var b0:=_metal_point(inner_radius,a,-HUB_HALF_THICK)
        var b1:=_metal_point(inner_radius,b,-HUB_HALF_THICK)
        _triangle(st,Vector3(0,HUB_HALF_THICK,0),
            f0,f1,face)
        _triangle(st,Vector3(0,-HUB_HALF_THICK,0),
            b1,b0,face.darkened(0.18))
        _quad(st,b0,b1,f1,f0,edge)

static func _real_spokes(st:SurfaceTool)->void:
    # Eight actual OPEN openings, exactly aligned with the 8 existing
    # rolling V46 bolt positions (angle = i*TAU/8). No loose bolt floats.
    var front:=Color("#b3bfc1")
    var rimedge:=Color("#57666c")
    for i in range(SPOKES):
        var ang:float=TAU*float(i)/float(SPOKES)
        var inner:float=0.225
        var outer:float=0.168
        var front_points:Array[Vector3]=[
            _metal_point(SPOKE_R_IN,ang-inner,HUB_HALF_THICK),
            _metal_point(SPOKE_R_OUT,ang-outer,HUB_HALF_THICK),
            _metal_point(SPOKE_R_OUT,ang+outer,HUB_HALF_THICK),
            _metal_point(SPOKE_R_IN,ang+inner,HUB_HALF_THICK)]
        var back_points:Array[Vector3]=[]
        for p in front_points:
            back_points.append(Vector3(p.x,-HUB_HALF_THICK,p.z))
        _quad(st,front_points[0],front_points[1],
            front_points[2],front_points[3],front)
        _quad(st,back_points[3],back_points[2],
            back_points[1],back_points[0],front.darkened(0.22))
        for edge in range(4):
            var next:int=(edge+1)%4
            _quad(st,back_points[edge],back_points[next],
                front_points[next],front_points[edge],rimedge)
 
static func _open_spoke_mesh(high:bool)->ArrayMesh:
    if high and _hero_open!=null:
        return _hero_open
    if not high and _mobile_open!=null:
        return _mobile_open
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _ring_geometry(st,high)
    _central_boss(st,high)
    _real_spokes(st)
    st.generate_normals()
    var result:=st.commit() as ArrayMesh
    if high:
        _hero_open=result
    else:
        _mobile_open=result
    return result

static func _hub_coat(original:StandardMaterial3D)->StandardMaterial3D:
    var material:=original.duplicate(true) as StandardMaterial3D
    material.albedo_color=Color.WHITE
    material.vertex_color_use_as_albedo=true
    material.metallic=0.72
    material.roughness=0.40
    material.clearcoat_enabled=false
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    return material

static func _ring_coat(original:StandardMaterial3D)->StandardMaterial3D:
    var material:=original.duplicate(true) as StandardMaterial3D
    # Preserve the exact live faction's PBR hue and albedo on wheel
    # recognition bands; only the light response becomes machined metal.
    material.metallic=0.57
    material.roughness=0.38
    material.clearcoat_enabled=true
    material.clearcoat=0.25
    material.clearcoat_roughness=0.32
    return material

static func _armor_coat(original:StandardMaterial3D,
        kind:String)->StandardMaterial3D:
    var material:=original.duplicate(true) as StandardMaterial3D
    # Armor is military painted steel, NOT chrome, and original albedo
    # remains unchanged for all faction configurations.
    material.metallic=0.61 if kind!="roof" else 0.51
    material.roughness=0.43 if kind!="roof" else 0.49
    material.clearcoat_enabled=true
    material.clearcoat=0.18
    material.clearcoat_roughness=0.35
    return material

static func _parts(model:Node3D)->Dictionary:
    var parts:Dictionary={}
    # V46 steel hub and faction ring exist on BOTH art profiles.
    # The older V7 OuterRims only exists in HERO LOD13, deliberately
    # omitted in the original lightweight Android 8 model.
    for key in [HUB,RING]:
        var node:=model.find_child(key,true,false) as MultiMeshInstance3D
        if node==null or node.multimesh==null or (
                node.multimesh.instance_count!=4):
            return {}
        parts[key]=node
    var outer:=model.find_child(OUTER,true,false) as MultiMeshInstance3D
    if outer!=null and outer.multimesh!=null and (
            outer.multimesh.instance_count==4):
        parts[OUTER]=outer
    for key in ARMOR:
        var part:=model.find_child(key,true,false) as GeometryInstance3D
        if part!=null and part.material_override is StandardMaterial3D:
            parts[key]=part
    return parts

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V60.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var high:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var parts:Dictionary=_parts(model)
    # Android LOD8 deliberately omits many hero armor panels. The
    # production eight-spoke wheel itself is REQUIRED on both levels;
    # additional armor material upgrades are opportunistic per LOD.
    if parts.size()<2:
        return false
    var hubs:=parts.get(HUB,null) as MultiMeshInstance3D
    if hubs==null or not hubs.multimesh.mesh is CylinderMesh:
        return false
    var mesh:ArrayMesh=_open_spoke_mesh(high)
    if mesh==null or mesh.get_faces().size()==0:
        return false
    var old:Dictionary={}
    var new:Dictionary={}
    for key in parts:
        var node:=parts[key] as GeometryInstance3D
        var material:=node.material_override as StandardMaterial3D
        if material==null:
            return false
        old[key]=material
        if key==HUB:
            new[key]=_hub_coat(material)
        elif key==RING:
            new[key]=_ring_coat(material)
        elif key==OUTER:
            var outer:=material.duplicate(true) as StandardMaterial3D
            outer.roughness=0.42
            outer.metallic=0.69
            new[key]=outer
        else:
            new[key]=_armor_coat(material,
                "roof" if key.find("Roof")>=0 else "armor")
    var original_mesh:Mesh=hubs.multimesh.mesh
    for key in parts:
        var node:=parts[key] as GeometryInstance3D
        node.material_override=new[key]
    hubs.multimesh.mesh=mesh
    model.set_meta(SAVED,{
        "before_materials":old,"after_materials":new,
        "before_hub_mesh":original_mesh,"after_hub_mesh":mesh
    })
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v61_true_open_spokes",8)
    model.set_meta("tarvoka_g13_v61_real_wheel_centers",4)
    model.set_meta("tarvoka_g13_v61_armor_panels",
        parts.size()-(3 if parts.has(OUTER) else 2))
    model.set_meta("tarvoka_g13_v61_extra_draw_nodes",EXTRA_DRAW_NODES)
    model.set_meta("tarvoka_g13_v61_exact_faction_albedo_preserved",true)
    model.set_meta("tarvoka_g13_v61_glass_and_continuous_tread_preserved",true)
    model.set_meta("tarvoka_g13_v61_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stored:Dictionary=model.get_meta(SAVED,{})
    if not stored.has("before_materials") or not stored.has(
            "after_materials"):
        return false
    var mats:Dictionary=stored["after_materials"] if enabled else (
        stored["before_materials"])
    var hub:=model.find_child(HUB,true,false) as MultiMeshInstance3D
    if hub==null or hub.multimesh==null:
        return false
    for key in mats:
        if model.find_child(str(key),true,false)==null:
            return false
    for key in mats:
        var node:=model.find_child(str(key),true,false) as GeometryInstance3D
        node.material_override=mats[key]
    hub.multimesh.mesh=stored["after_hub_mesh"] if enabled else (
        stored["before_hub_mesh"])
    model.set_meta("tarvoka_g13_v61_preview_enabled",enabled)
    return true
