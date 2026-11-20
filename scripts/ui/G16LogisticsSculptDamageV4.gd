extends RefCounted
class_name TarvokaG16LogisticsSculptV4

# TARVOKA G16 V4: ORIGINAL real, closed hard-surface geometry.
# Bevelled armoured body, recognisable faction panels, detailed headlights,
# cargo/tool silhouettes and reversible physical impact/wreck sequence.
# This is VISUAL ART for existing G16. Tactical logic stays untouched.
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const FLAG="tarvoka_g16_v4_native_closed_bevel_sculpt_and_dynamic_wreck"
const BODY="G16_V4_ClosedPremiumSculpt"
const WRECK="G16_V4_DynamicPhysicalWreck"
const LOOSE_LEFT="G16_V4_TornLeftArmorHinge"
const LOOSE_RIGHT="G16_V4_TornRightRearPanel"
const SMOKE="G16_V4_HeavyWreckSmoke"
const SPARKS="G16_V4_WreckEmbers"
const ACTIVE="tarvoka_g16_v4_visible"
const POSE="tarvoka_g16_v4_wreck_progress"

static func _mat(c:Color,metal:float=0.35,rough:float=0.47,
        glowing:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    if glowing:
        m.emission_enabled=true
        m.emission=c
        m.emission_energy_multiplier=1.75
    return m

static func _group(parent:Node3D,name:String)->Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _box(parent:Node3D,name:String,pos:Vector3,size:Vector3,
        material:Material,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=mesh
    n.material_override=material
    n.position=pos
    n.rotation_degrees=rot
    parent.add_child(n)
    return n

static func _cyl(parent:Node3D,name:String,pos:Vector3,
        radius:float,length:float,material:Material,
        rot:Vector3=Vector3.ZERO,detail:int=14)->MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=detail
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=mesh
    n.material_override=material
    n.position=pos
    n.rotation_degrees=rot
    parent.add_child(n)
    return n

static func _sphere(parent:Node3D,name:String,pos:Vector3,
        scaling:Vector3,material:Material,hero:bool)->MeshInstance3D:
    var shape:=SphereMesh.new()
    shape.radius=0.5
    shape.height=1.0
    shape.radial_segments=12 if hero else 7
    shape.rings=8 if hero else 5
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.position=pos
    n.scale=scaling
    n.material_override=material
    parent.add_child(n)
    return n

static func _vertex(st:SurfaceTool,p:Vector3)->void:
    st.add_vertex(p)

static func _triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    _vertex(st,a)
    _vertex(st,b)
    _vertex(st,c)

static func _closed_bevel(parent:Node3D,name:String,pos:Vector3,
        ext:Vector3,chamfer:float,material:Material,
        rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    # Fully 3D eight-corner cross-section, two sealed endcaps and all eight
    # closed side walls; no plane cards, no alpha and no mesh holes.
    var x:float=ext.x*0.5
    var y:float=ext.y*0.5
    var z:float=ext.z*0.5
    var c:float=clampf(chamfer,0.005,minf(x,y)*0.70)
    var ring:Array[Vector2]=[
        Vector2(x-c,-y),Vector2(x,-y+c),
        Vector2(x,y-c),Vector2(x-c,y),
        Vector2(-x+c,y),Vector2(-x,y-c),
        Vector2(-x,-y+c),Vector2(-x+c,-y)]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1,7):
        _triangle(st,Vector3(ring[0].x,ring[0].y,-z),
            Vector3(ring[i+1].x,ring[i+1].y,-z),
            Vector3(ring[i].x,ring[i].y,-z))
        _triangle(st,Vector3(ring[0].x,ring[0].y,z),
            Vector3(ring[i].x,ring[i].y,z),
            Vector3(ring[i+1].x,ring[i+1].y,z))
    for i in range(8):
        var j:int=(i+1)%8
        var a:=Vector3(ring[i].x,ring[i].y,-z)
        var b:=Vector3(ring[j].x,ring[j].y,-z)
        var c1:=Vector3(ring[i].x,ring[i].y,z)
        var d:=Vector3(ring[j].x,ring[j].y,z)
        _triangle(st,a,b,d)
        _triangle(st,a,d,c1)
    st.generate_normals()
    var solid:Mesh=st.commit()
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=solid
    n.position=pos
    n.rotation_degrees=rot
    n.material_override=material
    parent.add_child(n)
    return n

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func apply(root:Node3D,faction:Color)->bool:
    if not V1.has_model(root) or not V2.has_model(root) or (
            not V3.has_model(root)):
        return false
    if has_model(root):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var gate:=root.find_child(V1.GATE,true,false) as Node3D
    var crane:=root.find_child(V1.CRANE,true,false) as Node3D
    if chassis==null or gate==null or crane==null:
        return false
    var hero:bool=bool(root.get_meta("tarvoka_g16_v1_high_detail",false))
    var alloy:=_mat(Color("#839da8"),0.73,0.32)
    var armor:=_mat(Color("#576c75"),0.62,0.49)
    var dark:=_mat(Color("#26353c"),0.43,0.68)
    var rubber:=_mat(Color("#242e32"),0.07,0.91)
    var chrome:=_mat(Color("#b5c9cb"),0.88,0.19)
    var paint:=_mat(faction,0.48,0.34)
    var subdued:=_mat(faction.darkened(0.23),0.36,0.49)
    var light:=_mat(Color("#e5e4cd"),0.21,0.18,true)
    var hazard:=_mat(Color("#f9b552"),0.18,0.37,true)
    var red:=_mat(Color("#ad3e2b"),0.20,0.48)
    var ash:=_mat(Color("#272d32"),0.06,0.96)
    var smoke:=_mat(Color("#52575a"),0.02,1.0)
    var hot:=_mat(Color("#f58e31"),0.14,0.38,true)
    var body:=_group(chassis,BODY)

    # Real octagonal closed panels break the generic rectangular 6x6 cabin
    # silhouette WITHOUT covering the existing four V2 PBR windows.
    _closed_bevel(body,"G16_V4_ClosedBevelRoof",
        Vector3(0,1.800,-1.256),Vector3(1.89,0.116,1.363),
        0.047,armor,Vector3(-2.2,0,0))
    _closed_bevel(body,"G16_V4_ClosedFrontArmorLower",
        Vector3(0,1.011,-2.130),Vector3(1.680,0.290,0.226),
        0.062,armor,Vector3(-7,0,0))
    _closed_bevel(body,"G16_V4_DeepFrontBumper",
        Vector3(0,0.669,-2.345),Vector3(1.959,0.228,0.271),
        0.085,alloy)
    _closed_bevel(body,"G16_V4_OverheadCabBrow",
        Vector3(0,1.684,-2.050),Vector3(1.858,0.137,0.177),
        0.042,armor,Vector3(-7,0,0))
    _closed_bevel(body,"G16_V4_ForwardUnderbodySkid",
        Vector3(0,0.551,-2.160),Vector3(1.568,0.091,0.457),
        0.027,dark,Vector3(15,0,0))
    _closed_bevel(body,"G16_V4_CabRoofCrestFaction",
        Vector3(0,1.875,-1.352),Vector3(0.897,0.029,0.443),
        0.010,subdued)
    for side in [-1,1]:
        var s:float=float(side)
        var tag:String=str(side)
        # Lateral faction panels: visible at tactical distance; the glass
        # begins higher at 1.28m, therefore no panel hides cockpit glazing.
        _closed_bevel(body,"G16_V4_DoorFactionShoulder_"+tag,
            Vector3(s*1.015,1.093,-1.224),
            Vector3(0.091,0.244,0.877),0.040,paint)
        _closed_bevel(body,"G16_V4_RearFactionShield_"+tag,
            Vector3(s*1.008,1.277,0.968),
            Vector3(0.113,0.254,0.939),0.055,paint)
        _closed_bevel(body,"G16_V4_RearToolArmor_"+tag,
            Vector3(s*0.994,1.023,1.407),
            Vector3(0.128,0.208,0.756),0.066,armor)
        _box(body,"G16_V4_RoadworthyDoorStep_"+tag,
            Vector3(s*1.010,0.760,-1.113),
            Vector3(0.266,0.058,0.993),rubber)
        for n in range(4 if hero else 2):
            _box(body,"G16_V4_StepGrip_%s_%d" % [tag,n],
                Vector3(s*1.133,0.798,-1.465+float(n)*0.233),
                Vector3(0.038,0.015,0.079),chrome)
        _closed_bevel(body,"G16_V4_BevelSideMirrorBody_"+tag,
            Vector3(s*1.119,1.493,-1.839),
            Vector3(0.152,0.223,0.131),0.033,dark)
        _box(body,"G16_V4_MirrorChromedSurface_"+tag,
            Vector3(s*1.204,1.492,-1.837),
            Vector3(0.015,0.163,0.085),chrome)
        _closed_bevel(body,"G16_V4_ForwardHeadlampBezel_"+tag,
            Vector3(s*0.687,1.109,-2.301),
            Vector3(0.360,0.183,0.100),0.038,dark)
        _box(body,"G16_V4_ForwardHeadlampReflector_"+tag,
            Vector3(s*0.684,1.110,-2.357),
            Vector3(0.254,0.103,0.036),light)
        _closed_bevel(body,"G16_V4_AmberFrontSignal_"+tag,
            Vector3(s*0.876,1.128,-2.280),
            Vector3(0.094,0.118,0.090),0.018,hazard)
        _box(body,"G16_V4_RearReflectiveStrip_"+tag,
            Vector3(s*0.764,0.930,2.105),
            Vector3(0.240,0.085,0.026),red)
        _closed_bevel(body,"G16_V4_StiffenedLowerBodyRib_"+tag,
            Vector3(s*0.921,0.911,0.320),
            Vector3(0.132,0.098,1.835),0.035,dark)
    # Cargo/cabin separation and an upper reinforced side-rail remain
    # full-volume, sealed 3D steel solids.
    _closed_bevel(body,"G16_V4_ClosedCabRearBulkhead",
        Vector3(0,1.347,-0.519),Vector3(1.752,0.749,0.102),
        0.055,alloy)
    _closed_bevel(body,"G16_V4_CargoBedUpperBrace",
        Vector3(0,1.767,0.705),Vector3(1.794,0.081,2.296),
        0.028,dark)
    _closed_bevel(body,"G16_V4_FleetColorTopBrace",
        Vector3(0,1.822,0.749),Vector3(0.921,0.034,1.541),
        0.013,paint)
    for i in range(3):
        _box(body,"G16_V4_RearArmoredCargoVent_%d" % i,
            Vector3(-0.448+float(i)*0.448,1.569,1.936),
            Vector3(0.275,0.094,0.056),dark)

    # Toolboxes and safety kit are recognisable separate objects, not an
    # arbitrary slab. Rope hooks are attached to the existing supply deck.
    for side in [-1,1]:
        var s:float=float(side)
        _closed_bevel(body,"G16_V4_RearEmergencyKit_%d" % side,
            Vector3(s*0.629,1.785,1.411),
            Vector3(0.324,0.220,0.399),0.047,armor)
        _box(body,"G16_V4_KitFactionHandle_%d" % side,
            Vector3(s*0.629,1.906,1.407),
            Vector3(0.207,0.031,0.058),paint)

    # Damage overlays are physically articulated, not the old static ash
    # bubbles. The original closed body remains underneath for all stages.
    var wreck:=_group(chassis,WRECK)
    var left:=_group(wreck,LOOSE_LEFT)
    left.position=Vector3(-1.063,1.115,-1.118)
    _closed_bevel(left,"G16_V4_LeftHingedArmorShard",
        Vector3(-0.126,0,-0.125),Vector3(0.227,0.334,0.563),
        0.062,armor,Vector3(0,0,15))
    var right:=_group(wreck,LOOSE_RIGHT)
    right.position=Vector3(1.018,1.260,1.393)
    _closed_bevel(right,"G16_V4_RightHingedRearCargoFragment",
        Vector3(0.138,0,0.039),Vector3(0.218,0.428,0.667),
        0.062,subdued,Vector3(0,0,-12))
    _box(wreck,"G16_V4_BuckledFrontGrille",
        Vector3(0.110,0.935,-2.369),
        Vector3(0.543,0.124,0.074),ash,
        Vector3(0,0,13))
    var exhaust:=_group(wreck,SMOKE)
    exhaust.position=Vector3(0.366,1.768,0.768)
    for i in range(5 if hero else 3):
        var t:float=float(i)
        var plume:=_sphere(exhaust,"G16_V4_DenseSmokeCluster_%02d" % i,
            Vector3(sin(t*1.43)*0.190,0.175+t*0.252,
                cos(t*0.93)*0.155),
            Vector3(0.325+t*0.055,0.424+t*0.092,
                0.327+t*0.051),smoke if i%2==0 else ash,hero)
        plume.visible=true
    var sparks:=_group(wreck,SPARKS)
    sparks.position=Vector3(-0.396,1.446,1.062)
    for i in range(9 if hero else 4):
        var theta:float=TAU*float(i)/float(9 if hero else 4)
        var radius:float=0.091+float(i%3)*0.102
        _cyl(sparks,"G16_V4_EmissiveMetalSpark_%02d" % i,
            Vector3(cos(theta)*radius,0.033+float(i%4)*0.065,
                sin(theta)*radius),
            0.015,0.096,hot,Vector3(0,0,25+float(i)*8.0),
            7 if hero else 5)
    root.set_meta(FLAG,true)
    root.set_meta(ACTIVE,true)
    root.set_meta(POSE,0.0)
    root.set_meta("tarvoka_g16_v4_closed_bevelled_shells",true)
    root.set_meta("tarvoka_g16_v4_solid_side_faction_panels",true)
    root.set_meta("tarvoka_g16_v4_physical_damage",true)
    root.set_meta("tarvoka_g16_v4_visual_only",true)
    root.set_meta("tarvoka_g16_v4_original_cab_unmodified",true)
    return sync(root)

static func _motion(root:Node3D,p:float)->bool:
    var left:=root.find_child(LOOSE_LEFT,true,false) as Node3D
    var right:=root.find_child(LOOSE_RIGHT,true,false) as Node3D
    var fumes:=root.find_child(SMOKE,true,false) as Node3D
    var sparks:=root.find_child(SPARKS,true,false) as Node3D
    var wreck:=root.find_child(WRECK,true,false) as Node3D
    if left==null or right==null or fumes==null or sparks==null or wreck==null:
        return false
    var level:int=V3.stage(root)
    var active:bool=bool(root.get_meta(ACTIVE,true))
    var damage:float=smoothstep(0.0,1.0,clampf(p,0.0,1.0))
    wreck.visible=active and level>=2
    left.visible=active and level>=2
    right.visible=active and level>=3
    fumes.visible=active and level>=4
    sparks.visible=active and level>=4
    left.rotation_degrees=Vector3(0,-12*damage,-12-26*damage)
    right.rotation_degrees=Vector3(4*damage,9*damage,11+29*damage)
    fumes.position.y=1.768+0.22*damage
    fumes.scale=Vector3.ONE*(0.72+0.38*damage)
    sparks.rotation_degrees.y=59.0*damage
    sparks.scale=Vector3.ONE*(0.64+0.48*damage)
    root.set_meta(POSE,p)
    return true

static func sync(root:Node3D)->bool:
    if not has_model(root):
        return false
    return _motion(root,float(root.get_meta(POSE,0.0)))

static func set_damage(root:Node3D,level:int)->bool:
    if not has_model(root) or not V3.set_damage(root,level):
        return false
    root.set_meta(POSE,1.0 if level>=3 else 0.0)
    return sync(root)

static func pose_wreck(root:Node3D,progress:float)->bool:
    if not has_model(root):
        return false
    var p:float=clampf(progress,0.0,1.0)
    var level:int=clampi(int(floor(p*5.0)),0,4)
    if not V3.set_damage(root,level):
        return false
    return _motion(root,p)

static func show_finish(root:Node3D,visible:bool)->bool:
    if not has_model(root):
        return false
    var body:=root.find_child(BODY,true,false) as Node3D
    if body==null:
        return false
    body.visible=visible
    root.set_meta(ACTIVE,visible)
    return sync(root)

static func restore(root:Node3D)->bool:
    # Intentionally keep selected damage until user requests 'repair'.
    return sync(root)
