extends RefCounted
class_name TarvokaG15AntennaMechanicsV4

# G15 V4: real 3D electronic array, mast couplings and physically linked
# hydraulic deployment. ART ONLY; jamming remains an animation, not a rule.
# V1/V2/V3 geometry, eight faction paints, action rig and existing LOD survive.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const FLAG="tarvoka_g15_v4_antenna_silhouette_hydraulic_mast_and_array"
const ARRAY="G15_V4_PhasedArrayHead"
const MAST_HARDWARE="G15_V4_MastMovingHardware"
const FIXED_HINGE="G15_V4_ArticulatedRootMount"
const PISTON="G15_V4_TelescopicPiston"
const BARREL="G15_V4_HydraulicBarrel"
const CELLS="G15_V4_BatchedRealPhasedArrayCells"
const OLD_PREFIXES=[
    "G15_AntennaPanel_","G15_AntennaFace_","G15_ArraySlot_",
    "G15_Crossbar","G15_DirectionalDish","G15_DishFeed"]

static func _finish(code:String,metallic:float,roughness:float,
        lacquer:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(code)
    m.metallic=metallic
    m.roughness=roughness
    m.clearcoat_enabled=lacquer
    if lacquer:
        m.clearcoat=0.26
        m.clearcoat_roughness=0.31
    return m

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(b)
    st.set_normal(n)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3,d:Vector3)->void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

# Solid chamfered closed front/back shell, not a flat rectangle or sprite.
static func _panel_mesh(width:float,height:float,depth:float,
        chamfer:float)->ArrayMesh:
    var x:float=width*0.5
    var y:float=height*0.5
    var q:float=minf(chamfer,minf(x*0.40,y*0.40))
    var contour:Array[Vector2]=[
        Vector2(-x+q,-y),Vector2(x-q,-y),Vector2(x,-y+q),
        Vector2(x,y-q),Vector2(x-q,y),Vector2(-x+q,y),
        Vector2(-x,y-q),Vector2(-x,-y+q)]
    var zfront:float=-depth*0.5
    var zback:float=depth*0.5
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1,7):
        var a:Vector2=contour[0]
        var b:Vector2=contour[i]
        var c:Vector2=contour[i+1]
        _tri(st,Vector3(a.x,a.y,zfront),
            Vector3(c.x,c.y,zfront),Vector3(b.x,b.y,zfront))
        _tri(st,Vector3(a.x,a.y,zback),
            Vector3(b.x,b.y,zback),Vector3(c.x,c.y,zback))
    for j in range(8):
        var n:int=(j+1)%8
        var a:Vector2=contour[j]
        var b:Vector2=contour[n]
        _quad(st,Vector3(a.x,a.y,zfront),
            Vector3(b.x,b.y,zfront),
            Vector3(b.x,b.y,zback),Vector3(a.x,a.y,zback))
    return st.commit() as ArrayMesh

static func _mesh(parent:Node3D,name:String,geo:Mesh,mat:Material,
        pos:Vector3=Vector3.ZERO)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=geo
    node.material_override=mat
    node.position=pos
    parent.add_child(node)
    return node

static func _box(parent:Node3D,name:String,pos:Vector3,size3:Vector3,
        mat:Material)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size3
    return _mesh(parent,name,mesh,mat,pos)

static func _cylinder(parent:Node3D,name:String,at:Vector3,
        radius:float,height:float,mat:Material,
        sides:int=14)->MeshInstance3D:
    var geo:=CylinderMesh.new()
    geo.top_radius=radius
    geo.bottom_radius=radius
    geo.height=height
    geo.radial_segments=sides
    return _mesh(parent,name,geo,mat,at)

static func _rod(parent:Node3D,name:String,
        a:Vector3,b:Vector3,radius:float,
        material:Material,sides:int=12)->MeshInstance3D:
    var d:Vector3=b-a
    var result:=_cylinder(parent,name,(a+b)*0.5,
        radius,d.length(),material,sides)
    result.quaternion=Quaternion(Vector3.UP,d.normalized())
    return result

static func _original_head_details(head:Node3D)->Array[MeshInstance3D]:
    var out:Array[MeshInstance3D]=[]
    for child in head.get_children():
        if not child is MeshInstance3D:
            continue
        for prefix in OLD_PREFIXES:
            if str(child.name).begins_with(prefix):
                out.append(child as MeshInstance3D)
                break
    return out

static func apply(root:Node3D,faction_color:Color)->bool:
    if root==null or not V1.has_model(root) or (
            not bool(root.get_meta(V2.FLAG,false))) or (
            not bool(root.get_meta(V3.FLAG,false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var mast:=root.find_child(V1.MAST,true,false) as Node3D
    var head:=root.find_child(V1.ROTOR,true,false) as Node3D
    var signal:=root.find_child(V1.PULSE,true,false) as MeshInstance3D
    if chassis==null or mast==null or head==null or signal==null or (
            mast.get_parent()!=chassis or head.get_parent()!=mast):
        return false
    if root.find_child(ARRAY,true,false)!=null:
        return false
    var old:Array[MeshInstance3D]=_original_head_details(head)
    if old.size()<6:
        return false
    var prior:Dictionary={}
    for old_node in old:
        prior[str(old_node.name)]=old_node.visible

    var hero:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var panel_metal:=_finish("#788890",0.52,0.43)
    var ceramic:=_finish("#aeb7b6",0.16,0.59)
    var emitter:=_finish("#34484e",0.21,0.64)
    var brushed:=_finish("#c1cbd0",0.81,0.29)
    var gasket:=_finish("#2b3336",0.16,0.80)
    var hydraulic:=_finish("#54656d",0.58,0.49)
    var faction:=StandardMaterial3D.new()
    faction.albedo_color=faction_color
    faction.metallic=0.38
    faction.roughness=0.46
    faction.clearcoat_enabled=true
    faction.clearcoat=0.24

    var new_head:=Node3D.new()
    new_head.name=ARRAY
    head.add_child(new_head)
    # Two taller outward-canted solid panels establish a strong EW identity
    # at isometric scale, without adding launchers or apparent weapons.
    var shell_mesh:ArrayMesh=_panel_mesh(0.40,0.82,0.105,0.047)
    var front_mesh:ArrayMesh=_panel_mesh(0.338,0.731,0.018,0.029)
    var rows:int=7 if hero else 4
    var cols:int=3 if hero else 2
    var plate:=BoxMesh.new()
    plate.size=Vector3(0.066,0.048,0.015)
    var batch:=MultiMesh.new()
    batch.transform_format=MultiMesh.TRANSFORM_3D
    batch.mesh=plate
    batch.instance_count=rows*cols*2
    var emitter_index:int=0
    for side in [-1,1]:
        var s:float=float(side)
        var panel:=Node3D.new()
        panel.name="G15_V4_CantedPanel_%s" % side
        panel.position=Vector3(s*0.545,0.115,-0.055)
        panel.rotation_degrees.z=-s*8.0
        new_head.add_child(panel)
        _mesh(panel,"G15_V4_BevelArmor_%s" % side,
            shell_mesh,panel_metal)
        _mesh(panel,"G15_V4_RadomeFace_%s" % side,
            front_mesh,ceramic,Vector3(0,0,-0.068))
        _box(panel,"G15_V4_WeatherGasket_%s" % side,
            Vector3(0,0,-0.093),
            Vector3(0.28,0.670,0.012),gasket)
        _box(panel,"G15_V4_PanelFactionRail_%s" % side,
            Vector3(s*0.160,0,-0.067),
            Vector3(0.031,0.55,0.026),faction)
        var front_corner:Vector3=panel.position
        var panel_basis:Basis=Basis(Vector3.FORWARD,panel.rotation.z)
        for row in range(rows):
            for col in range(cols):
                var px:float=lerpf(-0.092,0.092,
                    float(col)/float(maxi(cols-1,1)))
                var py:float=lerpf(-0.270,0.270,
                    float(row)/float(maxi(rows-1,1)))
                var local:=Vector3(px,py,-0.109)
                batch.set_instance_transform(emitter_index,
                    Transform3D(panel_basis,
                        front_corner+panel_basis*local))
                emitter_index+=1
        # Mechanical yoke bars welded to the rotating head.
        _rod(new_head,"G15_V4_Yoke_%s" % side,
            Vector3(0,0.015,0.065),
            Vector3(s*0.50,-0.15,0.020),0.032,brushed,10)
        _rod(new_head,"G15_V4_UpperYoke_%s" % side,
            Vector3(0,0.14,0.07),
            Vector3(s*0.50,0.21,0.020),0.022,hydraulic,10)
    var cells:=MultiMeshInstance3D.new()
    cells.name=CELLS
    cells.multimesh=batch
    cells.material_override=emitter
    new_head.add_child(cells)
    # Center directional weather dome: convex steel cap and physical
    # metal rim, replacing the V1 flat cylinder dish.
    var dome:=SphereMesh.new()
    dome.radius=0.5
    dome.height=1.0
    dome.radial_segments=22 if hero else 12
    dome.rings=10 if hero else 6
    var cap:=_mesh(new_head,"G15_V4_CentralRadome",
        dome,ceramic,Vector3(0,0.13,-0.170))
    cap.scale=Vector3(0.47,0.57,0.20)
    var rim_mesh:=TorusMesh.new()
    rim_mesh.inner_radius=0.205
    rim_mesh.outer_radius=0.263
    rim_mesh.rings=12 if hero else 8
    rim_mesh.ring_segments=20 if hero else 12
    var rim:=_mesh(new_head,"G15_V4_CentralRadomeRim",
        rim_mesh,brushed,Vector3(0,0.13,-0.215))
    rim.rotation_degrees=Vector3(90,0,0)
    # The signal preview remains pure visual, but now sits in front of
    # the actual antenna instead of being concealed behind the head.
    var original_pulse:Vector3=signal.position

    var moving:=Node3D.new()
    moving.name=MAST_HARDWARE
    mast.add_child(moving)
    # Double reinforced rails and true telescopic mast sleeve.
    _cylinder(moving,"G15_V4_TelescopingCollar",
        Vector3(0,0.91,0),0.106,0.16,brushed,12)
    _cylinder(moving,"G15_V4_SealedMainMastSleeve",
        Vector3(0,0.52,0),0.105,0.58,hydraulic,14)
    for side in [-1,1]:
        var s:float=float(side)
        _rod(moving,"G15_V4_UpperTruss_%s" % side,
            Vector3(s*0.130,0.22,0.025),
            Vector3(s*0.085,1.10,0.018),0.028,panel_metal,10)
        _box(moving,"G15_V4_MastCableDuct_%s" % side,
            Vector3(s*0.088,0.56,0.092),
            Vector3(0.036,0.44,0.048),gasket)
        _rod(moving,"G15_V4_AntennaFeed_%s" % side,
            Vector3(s*0.074,1.14,0.065),
            Vector3(s*0.30,1.34,0.062),0.018,gasket,8)
    _rod(moving,"G15_V4_HeadTraverseBearing",
        Vector3(-0.225,1.37,0.04),
        Vector3(0.225,1.37,0.04),0.051,brushed,12)

    var fixed:=Node3D.new()
    fixed.name=FIXED_HINGE
    chassis.add_child(fixed)
    for side in [-1,1]:
        var s:float=float(side)
        _box(fixed,"G15_V4_RoofHingeBearing_%s" % side,
            Vector3(s*0.235,2.285,0.44),
            Vector3(0.135,0.18,0.29),hydraulic)
        _rod(fixed,"G15_V4_RoofHingePin_%s" % side,
            Vector3(s*0.158,2.292,0.44),
            Vector3(s*0.32,2.292,0.44),0.064,brushed,12)
    _box(fixed,"G15_V4_HydraulicRootPlate",
        Vector3(0,2.22,0.90),
        Vector3(0.30,0.07,0.26),hydraulic)
    # Persistent unit-height geometry. The two sections rescale to the
    # current real mount separation when the V1 mast animates; a permanently
    # attached decorative ram would float during a -58° deploy pose.
    _cylinder(fixed,BARREL,Vector3.ZERO,0.071,1.0,hydraulic,14)
    _cylinder(fixed,PISTON,Vector3.ZERO,0.039,1.0,brushed,12)
    for old_node in old:
        old_node.visible=false
    signal.position=Vector3(0,0.15,-0.315)
    root.set_meta("tarvoka_g15_v4_original_signal_position",original_pulse)
    root.set_meta("tarvoka_g15_v4_original_head_visibility",prior)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v4_canted_array_panels",2)
    root.set_meta("tarvoka_g15_v4_real_metal_hinges",2)
    root.set_meta("tarvoka_g15_v4_batched_array_cells",batch.instance_count)
    root.set_meta("tarvoka_g15_v4_no_gameplay_changes",true)
    sync(root)
    return true

# This lives outside the original mast pivot: the split hydraulic actuator
# actually follows the animated mast in move/deploy/restore/damage poses.
static func sync(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var mast:=root.find_child(V1.MAST,true,false) as Node3D
    var fixed:=root.find_child(FIXED_HINGE,true,false) as Node3D
    var barrel:=root.find_child(BARREL,true,false) as MeshInstance3D
    var piston:=root.find_child(PISTON,true,false) as MeshInstance3D
    if mast==null or fixed==null or barrel==null or piston==null:
        return false
    var start:=Vector3(0,2.235,0.90)
    # Mast is direct child of the original fixed chassis.
    var end:Vector3=mast.transform*Vector3(0,0.79,0.0)
    var d:Vector3=end-start
    var len:float=d.length()
    if len<0.09:
        return false
    var direction:Vector3=d/len
    var sleeve:float=len*0.58
    var shaft:float=len*0.54
    barrel.position=start+direction*(sleeve*0.5)
    barrel.quaternion=Quaternion(Vector3.UP,direction)
    barrel.scale=Vector3(1,sleeve,1)
    piston.position=end-direction*(shaft*0.5)
    piston.quaternion=Quaternion(Vector3.UP,direction)
    piston.scale=Vector3(1,shaft,1)
    root.set_meta("tarvoka_g15_v4_actuator_span_m",len)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var head:=root.find_child(V1.ROTOR,true,false) as Node3D
    var signal:=root.find_child(V1.PULSE,true,false) as MeshInstance3D
    var array:=root.find_child(ARRAY,true,false) as Node3D
    var moving:=root.find_child(MAST_HARDWARE,true,false) as Node3D
    var fixed:=root.find_child(FIXED_HINGE,true,false) as Node3D
    if head==null or signal==null or array==null or moving==null or fixed==null:
        return false
    var prior:Dictionary=root.get_meta(
        "tarvoka_g15_v4_original_head_visibility",{})
    for old_node in _original_head_details(head):
        old_node.visible=false if enabled else bool(
            prior.get(str(old_node.name),true))
    array.visible=enabled
    moving.visible=enabled
    fixed.visible=enabled
    signal.position=(Vector3(0,0.15,-0.315) if enabled else
        root.get_meta("tarvoka_g15_v4_original_signal_position",
            Vector3(0,0.15,0.34)))
    root.set_meta("tarvoka_g15_v4_preview_enabled",enabled)
    return true
