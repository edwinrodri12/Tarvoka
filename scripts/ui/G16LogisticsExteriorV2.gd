extends RefCounted
class_name TarvokaG16LogisticsFinishV2

# G16 V2 — second native Godot 4.3 production sculpt (original shared Studio).
# Six opaque cab surfaces + 3D PBR glass, tire shoulders, protective wheel arches
# and telescoping crane hydraulic cylinder. Pure model art, zero game logic.
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const FLAG="tarvoka_g16_v2_solid_armor_pbr_tire_crane"
const FINISH="G16_V2_ProductionExterior"
const DYNAMICS="G16_V2_CraneHydraulicAssembly"
const BOOM_SLEEVE="G16_V2_HydraulicSleeve"
const RAM="G16_V2_ChromeRam"
const END_PIN="G16_V2_ActuatorHead"
const SIDEWALL="G16_V2_Sidewall_"
const RIM="G16_V2_MachinedRim_"
const GLASS="G16_V2_Windshield_"
const ARCH_PREFIX="G16_V2_ArchSegment_"
const RAIL="G16_V2_CraneServiceRails"
const ALLOW_COMPARE="tarvoka_g16_v2_preview_enabled"

static func _mat(tint:Color,metal:float,rough:float,
        coated:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=tint
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    if coated:
        m.clearcoat_enabled=true
        m.clearcoat=0.52
        m.clearcoat_roughness=0.20
    return m

static func _box(parent:Node3D,label:String,pos:Vector3,
        size:Vector3,mat:Material,
        euler:Vector3=Vector3.ZERO)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=mesh
    n.position=pos
    n.rotation_degrees=euler
    n.material_override=mat
    parent.add_child(n)
    return n

static func _cylinder(parent:Node3D,label:String,pos:Vector3,
        radius:float,length:float,mat:Material,
        euler:Vector3=Vector3.ZERO,segments:int=16)->MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=segments
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=mesh
    n.position=pos
    n.rotation_degrees=euler
    n.material_override=mat
    parent.add_child(n)
    return n

static func _torus(parent:Node3D,label:String,pos:Vector3,
        inner:float,outer:float,mat:Material,hero:bool)->MeshInstance3D:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=12 if hero else 7
    mesh.ring_segments=28 if hero else 14
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=mesh
    n.position=pos
    n.rotation_degrees.z=90.0
    n.material_override=mat
    parent.add_child(n)
    return n

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,segments:int=12)->MeshInstance3D:
    var part:=_cylinder(parent,label,Vector3.ZERO,radius,1.0,mat,
        Vector3.ZERO,segments)
    _point_rod(part,a,b)
    return part

static func _point_rod(part:MeshInstance3D,a:Vector3,b:Vector3)->void:
    if part==null:
        return
    var distance:Vector3=b-a
    var mag:float=maxf(distance.length(),0.001)
    part.position=(a+b)*0.5
    part.quaternion=Quaternion(Vector3.UP,distance.normalized())
    part.scale=Vector3(1.0,mag,1.0)

static func _arc_on_outer_fender(parent:Node3D,side:int,axle:int,
        mat:Material,hero:bool)->void:
    # 3D swept semicircle protects an exposed tire's upper shoulder;
    # every segment is a real capped steel cylinder, not a dark texture.
    var s:float=float(side)
    var z:float=float(V1.AXLES[axle])
    var radius:float=0.483
    var count:int=8 if hero else 5
    var x:float=s*1.200
    for i in range(count):
        var a:float=PI*float(i)/float(count)
        var b:float=PI*float(i+1)/float(count)
        var at:=Vector3(x,V1.WHEEL_Y+sin(a)*radius,z+cos(a)*radius)
        var end:=Vector3(x,V1.WHEEL_Y+sin(b)*radius,z+cos(b)*radius)
        _rod(parent,ARCH_PREFIX+"%d_%d_%d" % [side,axle,i],
            at,end,0.026,mat,9 if hero else 6)

static func apply(root:Node3D,paint:Color)->bool:
    if not V1.has_model(root):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var crane:=root.find_child(V1.CRANE,true,false) as Node3D
    var boom:=root.find_child(V1.BOOM,true,false) as Node3D
    var extend:=root.find_child("G16_V1_ExtendingBoom",true,false) as Node3D
    if chassis==null or crane==null or boom==null or extend==null:
        return false
    if chassis.find_child(FINISH,false,false)!=null:
        return false
    for side in [-1,1]:
        for axle in range(3):
            if root.find_child(V1.WHEEL_PREFIX+"%d_%d" % [side,axle],
                    true,false)==null:
                return false
    var hero:bool=bool(root.get_meta("tarvoka_g16_v1_high_detail",false))
    var steel:=_mat(Color("#6b7f88"),0.51,0.42)
    var deep:=_mat(Color("#32454f"),0.42,0.54)
    var border:=_mat(Color("#182a35"),0.34,0.64)
    var chrome:=_mat(Color("#b1c2c9"),0.84,0.22)
    var rubber:=_mat(Color("#222830"),0.01,0.95)
    var glass:=_mat(Color("#326884"),0.18,0.12,true)
    var faction:=_mat(paint.darkened(0.04),0.40,0.36,true)
    var amber:=_mat(Color("#e9b352"),0.25,0.30)
    var red:=_mat(Color("#a73d35"),0.14,0.42)
    var fuel:=_mat(Color("#7b969d"),0.45,0.41)
    var ammo:=_mat(Color("#728767"),0.22,0.64)
    var highlight:=_mat(Color("#b9c8ce"),0.76,0.30)
    var root_v2:=Node3D.new()
    root_v2.name=FINISH
    chassis.add_child(root_v2)

    # Complete six-face opaque angular body shell in the V1 cabin volume:
    # these independent BoxMesh volumes deliberately overlap their neighbor
    # to prevent invisible transparent corner cracks on mobile OpenGL.
    _box(root_v2,"G16_V2_HeavyCabRoofArmor",
        Vector3(0,1.745,-1.256),Vector3(1.851,0.102,1.278),steel)
    _box(root_v2,"G16_V2_HeavyCabFrontBrow",
        Vector3(0,1.570,-1.939),Vector3(1.788,0.129,0.098),deep,
        Vector3(-11,0,0))
    _box(root_v2,"G16_V2_LowerCabFrontShell",
        Vector3(0,1.010,-1.998),Vector3(1.700,0.275,0.144),steel,
        Vector3(-8,0,0))
    _box(root_v2,"G16_V2_BonnetAngularRidge",
        Vector3(0,1.208,-2.021),Vector3(1.515,0.128,0.212),
        steel,Vector3(-16,0,0))
    _box(root_v2,"G16_V2_FrontClosedBumper",
        Vector3(0,0.678,-2.245),Vector3(2.00,0.184,0.167),chrome)
    _box(root_v2,"G16_V2_DeepIntakeGrille",
        Vector3(0,0.910,-2.201),Vector3(1.168,0.217,0.085),border)
    for line in range(5 if hero else 3):
        _box(root_v2,"G16_V2_FrontGrilleLouvre_%02d" % line,
            Vector3(0,0.840+float(line)*0.038,-2.247),
            Vector3(1.117,0.013,0.018),chrome)
    # Restore physical two-piece windshield. New V2 panes are well outside
    # V1's flat front surface (z=-1.892); opaque PBR, no ALPHA blend holes.
    for side in [-1,1]:
        var s:float=float(side)
        var tag:String=str(side)
        _box(root_v2,GLASS+tag,Vector3(s*0.389,1.439,-1.982),
            Vector3(0.717,0.335,0.060),glass,
            Vector3(-10,0,0))
        _box(root_v2,"G16_V2_WindscreenOuterSeal_"+tag,
            Vector3(s*0.779,1.435,-1.989),
            Vector3(0.041,0.394,0.088),border,
            Vector3(-10,0,0))
        _box(root_v2,"G16_V2_WindscreenSill_"+tag,
            Vector3(s*0.382,1.253,-2.043),
            Vector3(0.765,0.055,0.058),border)
        _box(root_v2,"G16_V2_ArmoredSideDoors_"+tag,
            Vector3(s*0.914,1.041,-1.246),
            Vector3(0.090,0.491,1.048),steel)
        _box(root_v2,"G16_V2_ClosedSideGlass_"+tag,
            Vector3(s*0.936,1.448,-1.294),
            Vector3(0.079,0.333,0.668),glass)
        _box(root_v2,"G16_V2_SideWindowTopSeal_"+tag,
            Vector3(s*0.982,1.634,-1.294),
            Vector3(0.029,0.048,0.702),border)
        for z in [-1.646,-0.941]:
            _box(root_v2,"G16_V2_SideWindowPillar_%s_%s" % [tag,str(z)],
                Vector3(s*0.986,1.458,z),
                Vector3(0.035,0.403,0.041),border)
        _box(root_v2,"G16_V2_DoorHingeStamp_"+tag,
            Vector3(s*0.975,1.155,-0.792),
            Vector3(0.048,0.191,0.037),chrome)
        _box(root_v2,"G16_V2_DoorPull_"+tag,
            Vector3(s*0.984,1.239,-1.353),
            Vector3(0.050,0.038,0.252),border)
        _box(root_v2,"G16_V2_MirrorReflectiveMetal_"+tag,
            Vector3(s*1.107,1.481,-1.836),
            Vector3(0.042,0.186,0.060),chrome)
        # Old block body remains underlying, now covered by inset-colored
        # steel skirts and a thin faction stripe distinct from the cab.
        _box(root_v2,"G16_V2_ThickWheelbaySkirt_"+tag,
            Vector3(s*0.951,0.884,0.513),
            Vector3(0.126,0.183,2.295),deep)
        _box(root_v2,"G16_V2_FactionFleetStripe_"+tag,
            Vector3(s*1.032,0.977,0.620),
            Vector3(0.050,0.096,1.770),faction)
        _box(root_v2,"G16_V2_CabFactionPanel_"+tag,
            Vector3(s*0.966,1.044,-1.243),
            Vector3(0.031,0.120,0.852),faction)
        _box(root_v2,"G16_V2_FuelWarning_"+tag,
            Vector3(s*0.998,1.075,1.200),
            Vector3(0.045,0.093,0.164),amber)
        _box(root_v2,"G16_V2_RearBrakeLamp_"+tag,
            Vector3(s*0.847,0.886,2.011),
            Vector3(0.178,0.137,0.069),red)
        for axle in range(3):
            _arc_on_outer_fender(root_v2,side,axle,deep,hero)

    _box(root_v2,"G16_V2_RearUtilityBuffer",
        Vector3(0,0.731,2.100),Vector3(1.87,0.158,0.164),steel)
    _box(root_v2,"G16_V2_RearHazardPanel",
        Vector3(0,1.02,2.082),Vector3(0.62,0.12,0.072),faction)
    _box(root_v2,"G16_V2_RoofBeaconBase",
        Vector3(0,1.839,-1.37),Vector3(0.63,0.065,0.19),deep)
    for side in [-1,1]:
        _box(root_v2,"G16_V2_AmberSafetyBeacon_%d" % side,
            Vector3(float(side)*0.222,1.911,-1.37),
            Vector3(0.167,0.083,0.125),amber)
    # True 3D wheel shoulders and metal rims: rotating V1 wheel pivots drive
    # ALL added elements, with lower draw counts on Android LOD8.
    for side in [-1,1]:
        for axle in range(3):
            var tag:String="%d_%d" % [side,axle]
            var s:float=float(side)
            var wheel:=root.find_child(V1.WHEEL_PREFIX+tag,
                true,false) as Node3D
            if wheel==null:
                return false
            var local_side:=Node3D.new()
            local_side.name=SIDEWALL+tag
            wheel.add_child(local_side)
            _torus(local_side,RIM+tag,
                Vector3(s*0.178,0,0),0.143,0.230,chrome,hero)
            _torus(local_side,"G16_V2_RubberShoulder_"+tag,
                Vector3(s*0.152,0,0),0.250,0.324,rubber,hero)
            _cylinder(local_side,"G16_V2_HubCenter_"+tag,
                Vector3(s*0.192,0,0),0.085,0.029,deep,
                Vector3(0,0,90),14 if hero else 10)
            if hero:
                for b in range(6):
                    var t:float=TAU*float(b)/6.0
                    _cylinder(local_side,"G16_V2_HubBolt_%s_%d" % [tag,b],
                        Vector3(s*0.211,cos(t)*0.139,sin(t)*0.139),
                        0.018,0.018,chrome,Vector3(0,0,90),8)
            else:
                for b in range(3):
                    var t:float=TAU*float(b)/3.0
                    _box(local_side,"G16_V2_CompactWheelBolt_%s_%d" % [tag,b],
                        Vector3(s*0.210,cos(t)*0.139,sin(t)*0.139),
                        Vector3(0.014,0.032,0.028),highlight)
    # Service couplings/chemical color bands specifically distinguish fluid
    # tanks from armored ammunition boxes — not two identical cargo blocks.
    for i in range(2):
        var z:float=0.36+float(i)*0.94
        _box(root_v2,"G16_V2_FuelLabel_%d" % i,
            Vector3(-0.78,1.497,z),
            Vector3(0.041,0.162,0.341),fuel)
        _cylinder(root_v2,"G16_V2_FuelCap_%d" % i,
            Vector3(-0.45,1.78,z),
            0.097,0.050,chrome,Vector3.ZERO,12 if hero else 8)
        _box(root_v2,"G16_V2_AmmoLatch_%d" % i,
            Vector3(0.846,1.400,z),
            Vector3(0.049,0.082,0.189),chrome)
        _box(root_v2,"G16_V2_AmmoProtectedCorner_%d" % i,
            Vector3(0.762,1.650,z+0.304),
            Vector3(0.173,0.057,0.094),ammo)
    _box(root_v2,"G16_V2_FuelHoseReelCase",
        Vector3(-0.667,1.185,-0.180),
        Vector3(0.374,0.227,0.188),deep)
    _cylinder(root_v2,"G16_V2_FuelServiceReel",
        Vector3(-0.668,1.251,-0.294),0.107,0.061,chrome,
        Vector3(90,0,0),18 if hero else 10)
    _box(root_v2,"G16_V2_FuelValve",
        Vector3(-0.678,1.286,1.842),
        Vector3(0.180,0.125,0.154),border)

    # Gripper slides in REAL boom coordinates. V2 adds a genuinely oriented
    # telescopic actuator tracking V1 boom rotation, not cosmetic static rods.
    var hydraulic:=Node3D.new()
    hydraulic.name=DYNAMICS
    crane.add_child(hydraulic)
    _cylinder(hydraulic,"G16_V2_CraneBaseBearing",
        Vector3(-0.135,0.070,0.003),0.102,0.201,deep,
        Vector3(0,0,90),18 if hero else 12)
    _rod(hydraulic,BOOM_SLEEVE,
        Vector3(-0.165,0.070,-0.068),Vector3(-0.165,0.08,0.36),
        0.069,steel,16 if hero else 10)
    _rod(hydraulic,RAM,
        Vector3(-0.165,0.08,0.36),Vector3(-0.165,0.15,0.79),
        0.034,chrome,14 if hero else 9)
    _cylinder(hydraulic,END_PIN,
        Vector3(-0.165,0.16,0.76),0.067,0.118,deep,
        Vector3(0,0,90),12 if hero else 8)
    var rails:=Node3D.new()
    rails.name=RAIL
    extend.add_child(rails)
    for side in [-1,1]:
        var s:float=float(side)
        _box(rails,"G16_V2_BoomSliderRail_%d" % side,
            Vector3(s*0.085,0,0.253),
            Vector3(0.027,0.044,0.567),chrome)
        _box(rails,"G16_V2_BoomCylinderCollar_%d" % side,
            Vector3(s*0.081,-0.076,0.050),
            Vector3(0.027,0.057,0.095),deep)
    root.set_meta(FLAG,true)
    root.set_meta(ALLOW_COMPARE,true)
    root.set_meta("tarvoka_g16_v2_cab_sealed",true)
    root.set_meta("tarvoka_g16_v2_solid_pbr_glass",true)
    root.set_meta("tarvoka_g16_v2_wheels",6)
    root.set_meta("tarvoka_g16_v2_native_hydraulic_crane",true)
    root.set_meta("tarvoka_g16_v2_visual_only",true)
    return sync(root)

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func show_finish(root:Node3D,enabled:bool)->bool:
    if not has_model(root):
        return false
    var exterior:=root.find_child(FINISH,true,false) as Node3D
    var actuator:=root.find_child(DYNAMICS,true,false) as Node3D
    var boom_rails:=root.find_child(RAIL,true,false) as Node3D
    if exterior==null or actuator==null or boom_rails==null:
        return false
    exterior.visible=enabled
    actuator.visible=enabled
    boom_rails.visible=enabled
    for side in [-1,1]:
        for axle in range(3):
            var sidewall:=root.find_child(
                SIDEWALL+"%d_%d" % [side,axle],true,false) as Node3D
            if sidewall==null:
                return false
            sidewall.visible=enabled
    root.set_meta(ALLOW_COMPARE,enabled)
    return true

static func sync(root:Node3D)->bool:
    if not has_model(root):
        return false
    var boom:=root.find_child(V1.BOOM,true,false) as Node3D
    var sleeve:=root.find_child(BOOM_SLEEVE,true,false) as MeshInstance3D
    var ram:=root.find_child(RAM,true,false) as MeshInstance3D
    var head:=root.find_child(END_PIN,true,false) as MeshInstance3D
    if boom==null or sleeve==null or ram==null or head==null:
        return false
    # Parent of both physical rods is the crane's yawing platform. Its
    # movement is inherited; coordinates for tip come from the actual V1 boom.
    var base:=Vector3(-0.165,0.070,-0.068)
    var tip:Vector3=boom.transform*Vector3(-0.165,0.0,0.784)
    var center:Vector3=base.lerp(tip,0.57)
    _point_rod(sleeve,base,center)
    _point_rod(ram,center,tip)
    head.position=tip
    return true
