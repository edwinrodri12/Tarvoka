extends RefCounted
class_name TarvokaG15MechanicalExteriorV7

# TARVOKA G15 V7 — actual Godot 4.3 native 3D refinement of existing G15.
# Art only: preserves V1-V6 chassis, six driven wheel pivots, EW mast,
# antenna animations, damage poses, faction paints, game logic and Android LOD.
const V1 = preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2 = preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const V3 = preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V4 = preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const V5 = preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const V6 = preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const FLAG = "tarvoka_g15_v7_jointed_underbody_and_chassis_surface"
const ASSEMBLY = "G15_V7_EngineeringFinish"
const UNDERBODY = "G15_V7_ArmoredUndercarriage"
const CAB_SEAMS = "G15_V7_CabMechanicalDetails"
const SHELTER_SEAMS = "G15_V7_ShelterWeldedJoints"
const AXLES = [-1.27, -0.01, 1.25]

static func _material(hex:String,metal:float,rough:float,coat:bool=false)->StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(hex)
    m.metallic = metal
    m.roughness = rough
    m.clearcoat_enabled = coat
    if coat:
        m.clearcoat = 0.26
        m.clearcoat_roughness = 0.28
    return m

static func _mesh(parent:Node3D,label:String,geometry:Mesh,
        mat:Material,pos:Vector3=Vector3.ZERO,
        rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = geometry
    item.material_override = mat
    item.position = pos
    item.rotation_degrees = rot
    parent.add_child(item)
    return item

static func _box(parent:Node3D,label:String,pos:Vector3,
        size3:Vector3,mat:Material,rotation:Vector3=Vector3.ZERO)->MeshInstance3D:
    var geo:=BoxMesh.new()
    geo.size=size3
    return _mesh(parent,label,geo,mat,pos,rotation)

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,segments:int=12)->MeshInstance3D:
    var delta:Vector3=b-a
    var geo:=CylinderMesh.new()
    geo.top_radius=radius
    geo.bottom_radius=radius
    geo.height=delta.length()
    geo.radial_segments=segments
    var cylinder:=_mesh(parent,label,geo,mat,(a+b)*0.5)
    cylinder.quaternion=Quaternion(Vector3.UP,delta.normalized())
    return cylinder

static func _solid(parent:Node3D,label:String,
        a:float,b:float,c:float,bevel:float,
        mat:Material,pos:Vector3,angles:Vector3=Vector3.ZERO)->MeshInstance3D:
    var sculpt:ArrayMesh=V6._chamfered_plate(a,b,c,bevel)
    return _mesh(parent,label,sculpt,mat,pos,angles)

static func _suspension(parent:Node3D,number:int,z:float,
        metal:Material,dark:Material,hero:bool)->void:
    # The 3 axle beams are attached to the fixed 6x6 chassis (NOT the moving
    # wheels), so original wheel rotation and steering poses still work.
    _rod(parent,"G15_V7_AxleShaft_%d" % number,
        Vector3(-0.86,0.365,z),Vector3(0.86,0.365,z),
        0.065,dark,14 if hero else 10)
    var hub:=SphereMesh.new()
    hub.radius=0.23
    hub.height=0.46
    hub.radial_segments=16 if hero else 10
    hub.rings=8 if hero else 5
    var differential:=_mesh(parent,"G15_V7_Differential_%d" % number,
        hub,metal,Vector3(0,0.365,z))
    differential.scale=Vector3(0.76,0.68,0.92)
    for side in [-1,1]:
        var s:float=float(side)
        _rod(parent,"G15_V7_ControlLink_%s_%d" % [side,number],
            Vector3(s*0.55,0.535,z-0.15),
            Vector3(s*0.75,0.38,z),0.028,metal,10)
        if hero:
            _rod(parent,"G15_V7_ShockAbsorber_%s_%d" % [side,number],
                Vector3(s*0.695,0.610,z+0.18),
                Vector3(s*0.72,0.378,z+0.035),0.028,dark,10)

static func apply(root:Node3D,faction_color:Color)->bool:
    if root==null or not V1.has_model(root) or (
            not bool(root.get_meta(V2.FLAG,false))) or (
            not bool(root.get_meta(V3.FLAG,false))) or (
            not bool(root.get_meta(V4.FLAG,false))) or (
            not bool(root.get_meta(V5.FLAG,false))) or (
            not bool(root.get_meta(V6.FLAG,false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if chassis==null or wheels==null or wheels.get_child_count()!=6 or (
            root.find_child(ASSEMBLY,true,false)!=null):
        return false
    var hero:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var steel:=_material("#73838b",0.68,0.45)
    var edge:=_material("#b4c2c4",0.79,0.31)
    var gunmetal:=_material("#323f46",0.44,0.74)
    var rubber:=_material("#24292c",0.0,0.92)
    var patina:=_material("#575e61",0.43,0.69)
    var paint:=StandardMaterial3D.new()
    paint.albedo_color=faction_color
    paint.metallic=0.35
    paint.roughness=0.40
    paint.clearcoat_enabled=true
    paint.clearcoat=0.30
    paint.clearcoat_roughness=0.24

    var group:=Node3D.new()
    group.name=ASSEMBLY
    chassis.add_child(group)
    var underside:=Node3D.new()
    underside.name=UNDERBODY
    group.add_child(underside)
    var cab:=Node3D.new()
    cab.name=CAB_SEAMS
    group.add_child(cab)
    var shelter:=Node3D.new()
    shelter.name=SHELTER_SEAMS
    group.add_child(shelter)

    # 6x6 ladder frame: two sealed real octagonal box beams and three
    # crossmembers; each differential is 3D and supported by real axles.
    # Low-height positions keep suspension below shelter and clear of tires.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _solid(underside,"G15_V7_ClosedLongitudinalFrame_"+id,
            0.205,0.190,3.415,0.030,gunmetal,
            Vector3(s*0.560,0.510,0.035),Vector3(90,0,0))
        _box(underside,"G15_V7_RailOuterWeld_"+id,
            Vector3(s*0.680,0.521,0.08),
            Vector3(0.026,0.075,2.95),edge)
        _solid(underside,"G15_V7_FrontChassisNose_"+id,
            0.230,0.20,0.30,0.036,steel,
            Vector3(s*0.545,0.545,-1.60),Vector3(90,0,0))
        _solid(underside,"G15_V7_RearArmoredFrameEnd_"+id,
            0.24,0.22,0.28,0.03,steel,
            Vector3(s*0.555,0.52,1.66),Vector3(90,0,0))
    for i in range(4):
        var z:float=-1.46+0.97*float(i)
        _solid(underside,"G15_V7_BoxCrossmember_%d" % i,
            1.22,0.12,0.17,0.022,patina,
            Vector3(0,0.527,z),Vector3.ZERO)
    for i in range(3):
        _suspension(underside,i,float(AXLES[i]),steel,gunmetal,hero)
    _solid(underside,"G15_V7_UndersideTransferCase",
        0.64,0.175,0.49,0.058,steel,
        Vector3(0,0.432,0.59))
    if hero:
        _solid(underside,"G15_V7_FrontEngineSkid",
            0.91,0.135,0.62,0.045,edge,
            Vector3(0,0.394,-1.13))
        _solid(underside,"G15_V7_RearElectronicSkid",
            0.95,0.125,0.43,0.052,edge,
            Vector3(0,0.399,1.44))
        for i in range(2):
            _rod(underside,"G15_V7_DriveShaft_%d" % i,
                Vector3(0,0.367,float(AXLES[i])+0.19),
                Vector3(0,0.367,float(AXLES[i+1])-0.19),
                0.045,gunmetal,12)
        for side in [-1,1]:
            var s:float=float(side)
            for axle in range(3):
                var z:float=float(AXLES[axle])
                _box(underside,"G15_V7_RubberWheelMudflap_%s_%d" % [side,axle],
                    Vector3(s*0.875,0.428,z+0.386),
                    Vector3(0.22,0.295,0.030),rubber)
                _box(underside,"G15_V7_MudflapBracket_%s_%d" % [side,axle],
                    Vector3(s*0.870,0.580,z+0.381),
                    Vector3(0.22,0.031,0.052),edge)

    # Cab doorwork: steel hinge knuckles, external gaskets, steps, sill, and
    # armor corners. All fixed to original body, never connected to wheel pivots.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _solid(cab,"G15_V7_CabDoorRecess_"+id,
            0.390,0.522,0.052,0.048,gunmetal,
            Vector3(s*0.767,1.175,-1.050),Vector3(0,90,0))
        _solid(cab,"G15_V7_CabDoorInsetArmor_"+id,
            0.338,0.464,0.053,0.036,steel,
            Vector3(s*0.804,1.180,-1.052),Vector3(0,90,0))
        _box(cab,"G15_V7_EnamelDoorBead_"+id,
            Vector3(s*0.839,1.43,-1.051),
            Vector3(0.014,0.033,0.263),paint)
        _solid(cab,"G15_V7_CabStep_"+id,
            0.240,0.080,0.420,0.026,gunmetal,
            Vector3(s*0.835,0.790,-1.028),Vector3.ZERO)
        _box(cab,"G15_V7_CabDoorSeal_"+id,
            Vector3(s*0.830,1.180,-1.065),
            Vector3(0.016,0.372,0.274),rubber)
        _box(cab,"G15_V7_CabDoorLatch_"+id,
            Vector3(s*0.850,1.230,-0.955),
            Vector3(0.023,0.052,0.105),edge)
        _solid(cab,"G15_V7_CabPillarReinforcement_"+id,
            0.13,0.700,0.064,0.015,patina,
            Vector3(s*0.708,1.505,-0.432),Vector3(0,90,0))
        if hero:
            for hinge in range(2):
                _rod(cab,"G15_V7_CabDoorHinge_%s_%d" % [id,hinge],
                    Vector3(s*0.847,0.990+float(hinge)*0.370,-1.300),
                    Vector3(s*0.847,1.100+float(hinge)*0.370,-1.300),
                    0.031,edge)
            for tread in range(4):
                _box(cab,"G15_V7_CabAntiSlip_%s_%d" % [id,tread],
                    Vector3(s*(0.740+float(tread)*0.063),0.837,-1.030),
                    Vector3(0.025,0.009,0.323),rubber)

        # EW shelter construction: raised water-sealed hatches and
        # disconnected physical weld-beads between individual armor plates.
        _box(shelter,"G15_V7_WaterproofUpperSeam_"+id,
            Vector3(s*0.844,1.895,0.385),
            Vector3(0.036,0.030,1.052),gunmetal)
        _box(shelter,"G15_V7_WaterproofLowerSeam_"+id,
            Vector3(s*0.839,1.093,0.380),
            Vector3(0.034,0.034,1.008),edge)
        for j in range(3 if hero else 2):
            var z:float=-0.160+0.375*float(j)
            _box(shelter,"G15_V7_HardArmorVerticalWeld_%s_%d" % [id,j],
                Vector3(s*0.850,1.492,z),
                Vector3(0.026,0.565,0.031),patina)
        _solid(shelter,"G15_V7_CableAccessPlate_"+id,
            0.250,0.244,0.061,0.041,steel,
            Vector3(s*0.863,1.480,0.740),Vector3(0,90,0))
        _box(shelter,"G15_V7_FactionAccessStripe_"+id,
            Vector3(s*0.900,1.482,0.738),
            Vector3(0.013,0.042,0.176),paint)
        _solid(shelter,"G15_V7_FenderShoulderReinforcement_"+id,
            0.178,0.13,0.775,0.023,gunmetal,
            Vector3(s*0.814,0.994,-0.030),Vector3(90,0,0))
        if hero:
            for i in range(4):
                _box(shelter,"G15_V7_HatchLockBolt_%s_%d" % [id,i],
                    Vector3(s*0.904,1.393+float(floori(float(i)/2.0))*0.178,
                        0.652+float(i%2)*0.170),
                    Vector3(0.018,0.025,0.028),edge)
            _rod(shelter,"G15_V7_CableServiceHandle_"+id,
                Vector3(s*0.909,1.407,0.672),
                Vector3(s*0.909,1.407,0.810),0.019,gunmetal,10)

    # Rear seam remains visible in three-quarter view and prevents the rear
    # cooling housing from looking bolted onto an undifferentiated flat box.
    for side in [-1,1]:
        var s:float=float(side)
        _box(shelter,"G15_V7_RearDoorFrame_%s" % side,
            Vector3(s*0.685,1.477,1.799),
            Vector3(0.045,0.870,0.044),edge)
        if hero:
            _rod(shelter,"G15_V7_RearDoorLockingBar_%s" % side,
                Vector3(s*0.555,1.127,1.805),
                Vector3(s*0.555,1.786,1.805),0.025,gunmetal,10)
    _box(shelter,"G15_V7_RearCrossJoint",
        Vector3(0,1.94,1.790),Vector3(1.34,0.054,0.037),edge)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v7_original_rig_unchanged",true)
    root.set_meta("tarvoka_g15_v7_six_reconstructed_axle_endpoints",true)
    root.set_meta("tarvoka_g15_v7_faction_3d_enamel",true)
    root.set_meta("tarvoka_g15_v7_no_gameplay_changes",true)
    root.set_meta("tarvoka_g15_v7_hero",hero)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var assembly:=root.find_child(ASSEMBLY,true,false) as Node3D
    if assembly==null:
        return false
    assembly.visible=enabled
    root.set_meta("tarvoka_g15_v7_preview_enabled",enabled)
    return true
