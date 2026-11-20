extends RefCounted
class_name TarvokaG16LogisticsV1

# TARVOKA G16 V1: original non-combat 6x6 armored logistics carrier.
# Native Godot 4.3 3D meshes. These are VISUAL camp and unloading previews;
# no supply, ammunition, fuel, repair, turn or saved-game rules are changed.
const FLAG := "tarvoka_g16_v1_native_armored_logistics_6x6"
const CHASSIS := "G16_V1_ChasisBlindado6x6"
const WHEEL_PREFIX := "G16_V1_Wheel_"
const CRANE := "G16_V1_ArticulatedSupplyCrane"
const BOOM := "G16_V1_TelescopingBoom"
const GATE := "G16_V1_RearLiftgateHinge"
const AWNING := "G16_V1_SupplyCampAwningHinge"
const CRATE := "G16_V1_CraneSupplyCrate"
const MARKERS := "G16_V1_ResupplyVisualOnly"
const AXLES := [-1.43,-0.42,1.33]
const WHEEL_X:float=1.032
const WHEEL_Y:float=0.395
const RADIUS:float=0.345
const VALID_POSES := [
    "idle","move","deploy","unload","resupply","camp","pack","hit"
]

static func _mat(tint:Color,metal:float=0.2,rough:float=0.66,
        enamel:bool=false,glow:bool=false)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=tint
    mat.metallic=metal
    mat.roughness=rough
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    if enamel:
        mat.clearcoat_enabled=true
        mat.clearcoat=0.31
        mat.clearcoat_roughness=0.34
    if glow:
        mat.emission_enabled=true
        mat.emission=tint
        mat.emission_energy_multiplier=1.40
    return mat

static func _box(parent:Node3D,label:String,center:Vector3,
        dimensions:Vector3,mat:Material,
        angles:Vector3=Vector3.ZERO)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var m:=BoxMesh.new()
    m.size=dimensions
    n.mesh=m
    n.material_override=mat
    n.position=center
    n.rotation_degrees=angles
    parent.add_child(n)
    return n

static func _cyl(parent:Node3D,label:String,center:Vector3,
        radius:float,height:float,mat:Material,
        angles:Vector3=Vector3.ZERO,detail:int=14)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var m:=CylinderMesh.new()
    m.top_radius=radius
    m.bottom_radius=radius
    m.height=height
    m.radial_segments=detail
    n.mesh=m
    n.material_override=mat
    n.position=center
    n.rotation_degrees=angles
    parent.add_child(n)
    return n

static func _torus(parent:Node3D,label:String,pos:Vector3,
        inner:float,outer:float,mat:Material,hero:bool,
        orientation:Vector3=Vector3(0,0,90))->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=12 if hero else 7
    mesh.ring_segments=28 if hero else 14
    n.mesh=mesh
    n.material_override=mat
    n.position=pos
    n.rotation_degrees=orientation
    parent.add_child(n)
    return n

static func _wheel(parent:Node3D,side:int,axle:int,hero:bool,
        rubber:Material,alloy:Material,shadow:Material)->void:
    var tag:String="%d_%d" % [side,axle]
    var s:float=float(side)
    var pivot:=Node3D.new()
    pivot.name=WHEEL_PREFIX+tag
    pivot.position=Vector3(s*WHEEL_X,WHEEL_Y,float(AXLES[axle]))
    parent.add_child(pivot)
    _cyl(pivot,"G16_V1_Tire_"+tag,Vector3.ZERO,RADIUS,0.285,
        rubber,Vector3(0,0,90),24 if hero else 14)
    _torus(pivot,"G16_V1_RubberSidewall_"+tag,
        Vector3(s*0.144,0,0),0.216,0.310,rubber,hero)
    _torus(pivot,"G16_V1_MachinedWheelBead_"+tag,
        Vector3(s*0.159,0,0),0.142,0.202,alloy,hero)
    _cyl(pivot,"G16_V1_RecessedWheelCap_"+tag,
        Vector3(s*0.172,0,0),0.128,0.023,shadow,
        Vector3(0,0,90),20 if hero else 12)
    # Instanced, real rubber treads: no billboard-wheel texture.
    var tread_mesh:=BoxMesh.new()
    tread_mesh.size=Vector3(0.132,0.038,0.128)
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=tread_mesh
    var segments:int=18 if hero else 10
    mm.instance_count=segments*2
    for j in range(segments):
        for lane in range(2):
            var ang:float=TAU*(float(j)+float(lane)*0.25)/float(segments)
            var pos:=Vector3(-0.068 if lane==0 else 0.068,
                cos(ang)*0.350,sin(ang)*0.350)
            mm.set_instance_transform(j*2+lane,Transform3D(
                Basis(Vector3.RIGHT,-ang),pos))
    var inst:=MultiMeshInstance3D.new()
    inst.name="G16_V1_RealTread_"+tag
    inst.multimesh=mm
    inst.material_override=rubber
    pivot.add_child(inst)

static func build(root:Node3D,paint:Color,hero:bool=true)->bool:
    if root==null or root.has_meta(FLAG):
        return false
    var hull:=_mat(Color("#687b83"),0.47,0.48)
    var armor:=_mat(Color("#4e636e"),0.43,0.56)
    var skirt:=_mat(Color("#394850"),0.33,0.65)
    var rubber:=_mat(Color("#21262b"),0.0,0.94)
    var steel:=_mat(Color("#9cabb2"),0.77,0.32)
    var frame:=_mat(Color("#222c32"),0.20,0.86)
    var glazing:=_mat(Color("#1e4a63"),0.11,0.11,true)
    glazing.clearcoat=0.80
    glazing.clearcoat_roughness=0.14
    var faction:=_mat(paint.darkened(0.08),0.32,0.43,true)
    var canvas:=_mat(Color("#82928b"),0.05,0.87)
    var fuel:=_mat(Color("#788989"),0.45,0.58)
    var ammo:=_mat(Color("#899375"),0.22,0.74)
    var amber:=_mat(Color("#e7ac54"),0.12,0.37,false,true)
    var white:=_mat(Color("#d2e3e7"),0.16,0.24)
    var chassis:=Node3D.new()
    chassis.name=CHASSIS
    root.add_child(chassis)
    # Shape language: compact forward armored cab / rear utility frame,
    # NOT a SAM truck, G13 AA or G15 electronic warfare shelter.
    _box(chassis,"G16_V1_ClosedFrame",
        Vector3(0,0.667,0.10),Vector3(1.77,0.36,4.12),frame)
    _box(chassis,"G16_V1_BellyArmor",
        Vector3(0,0.867,0.02),Vector3(1.75,0.165,3.87),skirt)
    _box(chassis,"G16_V1_ClosedCabin",
        Vector3(0,1.225,-1.265),Vector3(1.67,0.87,1.20),hull)
    _box(chassis,"G16_V1_RakedNose",
        Vector3(0,1.031,-1.944),Vector3(1.67,0.495,0.345),
        armor,Vector3(-19,0,0))
    _box(chassis,"G16_V1_CompleteRoof",
        Vector3(0,1.720,-1.24),Vector3(1.77,0.110,1.18),armor)
    _box(chassis,"G16_V1_FrontGrille",
        Vector3(0,0.878,-2.100),Vector3(1.050,0.265,0.042),frame)
    _box(chassis,"G16_V1_FullBumper",
        Vector3(0,0.667,-2.169),Vector3(1.87,0.165,0.150),steel)
    _box(chassis,"G16_V1_CargoBedFull",
        Vector3(0,1.035,0.827),Vector3(1.90,0.182,2.12),armor)
    # Cargo area is intentionally open (no pretend see-through solid walls).
    # Its cargo modules and rails are physical 3D assets.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(chassis,"G16_V1_SolidSideCabWindow_"+id,
            Vector3(s*0.857,1.421,-1.296),
            Vector3(0.075,0.322,0.553),glazing)
        _box(chassis,"G16_V1_CabWindowGasket_"+id,
            Vector3(s*0.899,1.251,-1.296),
            Vector3(0.035,0.036,0.589),frame)
        _box(chassis,"G16_V1_SideFactionCabBand_"+id,
            Vector3(s*0.856,1.103,-1.31),
            Vector3(0.038,0.171,0.941),faction)
        _box(chassis,"G16_V1_LongFactionStripe_"+id,
            Vector3(s*0.967,0.983,0.711),
            Vector3(0.068,0.132,1.651),faction)
        _box(chassis,"G16_V1_SideArmoredSkirt_"+id,
            Vector3(s*0.943,0.819,0.604),
            Vector3(0.122,0.230,2.199),skirt)
        _box(chassis,"G16_V1_SideWorkRail_"+id,
            Vector3(s*0.881,1.274,0.733),
            Vector3(0.074,0.102,1.99),steel)
        _box(chassis,"G16_V1_DoorSeam_"+id,
            Vector3(s*0.903,1.189,-0.887),
            Vector3(0.029,0.56,0.023),frame)
        _box(chassis,"G16_V1_Headlight_"+id,
            Vector3(s*0.685,0.993,-2.110),
            Vector3(0.251,0.117,0.027),white)
        _box(chassis,"G16_V1_MirrorArm_"+id,
            Vector3(s*0.945,1.465,-1.807),
            Vector3(0.215,0.045,0.061),steel)
        _box(chassis,"G16_V1_MirrorHousing_"+id,
            Vector3(s*1.031,1.473,-1.815),
            Vector3(0.118,0.231,0.076),frame)
        if hero:
            _box(chassis,"G16_V1_Handhold_"+id,
                Vector3(s*0.932,1.611,-0.990),
                Vector3(0.034,0.182,0.035),steel)
            for vent in range(3):
                _box(chassis,"G16_V1_EngineVent_%d_%d" % [side,vent],
                    Vector3(s*0.681,1.782,-1.697+float(vent)*0.12),
                    Vector3(0.154,0.018,0.068),frame)
    # All front windscreens are closed BoxMesh solids with opaque PBR.
    for half in [-1,1]:
        _box(chassis,"G16_V1_SolidWindshield_%d" % half,
            Vector3(float(half)*0.390,1.431,-1.892),
            Vector3(0.650,0.310,0.062),glazing,Vector3(-10,0,0))
        _box(chassis,"G16_V1_WindshieldTopTrim_%d" % half,
            Vector3(float(half)*0.390,1.606,-1.837),
            Vector3(0.695,0.050,0.102),frame)
    _box(chassis,"G16_V1_CompleteFrontWindshieldSill",
        Vector3(0,1.249,-1.956),Vector3(1.548,0.050,0.053),frame)

    for axle in range(AXLES.size()):
        _box(chassis,"G16_V1_AxleAssembly_%d" % axle,
            Vector3(0,0.451,float(AXLES[axle])),
            Vector3(1.97,0.13,0.16),frame)
        for side in [-1,1]:
            _wheel(chassis,side,axle,hero,rubber,steel,frame)

    # Exposed enclosed fluid tanks at the left and separately sealed
    # ammunition crates on the right, not one generic opaque cargo box.
    for i in range(2):
        var z:float=0.36+float(i)*0.94
        _cyl(chassis,"G16_V1_SealedFuelTank_%d" % i,
            Vector3(-0.45,1.47,z),0.283,0.81,fuel,
            Vector3(90,0,0),20 if hero else 12)
        _torus(chassis,"G16_V1_FuelClamp_%d" % i,
            Vector3(-0.45,1.47,z-0.32),0.28,0.317,frame,hero,
            Vector3(90,0,0))
        _box(chassis,"G16_V1_TankMount_%d" % i,
            Vector3(-0.45,1.161,z),
            Vector3(0.37,0.064,0.72),steel)
        _box(chassis,"G16_V1_AmmoChest_%d" % i,
            Vector3(0.47,1.373,z),
            Vector3(0.68,0.497,0.743),ammo)
        _box(chassis,"G16_V1_AmmoLid_%d" % i,
            Vector3(0.47,1.640,z),
            Vector3(0.71,0.059,0.773),frame)
        _box(chassis,"G16_V1_AmmoFactionMark_%d" % i,
            Vector3(0.831,1.421,z),
            Vector3(0.031,0.133,0.455),faction)
    for i in range(3):
        _box(chassis,"G16_V1_RearDeckCrossbar_%d" % i,
            Vector3(0,1.156,-0.14+float(i)*0.81),
            Vector3(1.79,0.055,0.068),steel)
    _box(chassis,"G16_V1_RearDeckTailgateBeam",
        Vector3(0,1.077,1.959),Vector3(1.90,0.102,0.130),frame)
    _box(chassis,"G16_V1_CargoServiceHatch",
        Vector3(0,1.072,-0.082),Vector3(1.79,0.049,0.175),frame)

    # Native hinged fold-out support-camp roof on the left flank.
    var awning:=Node3D.new()
    awning.name=AWNING
    awning.position=Vector3(-0.961,1.47,0.64)
    chassis.add_child(awning)
    _box(awning,"G16_V1_CampRoofOpaqueCanvas",
        Vector3(-0.448,0,0),Vector3(0.893,0.059,1.55),canvas)
    _box(awning,"G16_V1_CampFrontFrame",
        Vector3(-0.899,-0.066,0),
        Vector3(0.050,0.112,1.58),steel)
    _box(awning,"G16_V1_CampSupportEdge",
        Vector3(-0.443,0,0.757),Vector3(0.93,0.071,0.043),frame)

    # Rear loading ramp: open behind truck, closed vertically when driving.
    var gate:=Node3D.new()
    gate.name=GATE
    gate.position=Vector3(0,0.976,2.007)
    chassis.add_child(gate)
    _box(gate,"G16_V1_ThickClosedRearGate",
        Vector3(0,0,0.393),Vector3(1.746,0.106,0.786),armor)
    for side in [-1,1]:
        _box(gate,"G16_V1_RearGateSteelSide_%d" % side,
            Vector3(float(side)*0.838,0.063,0.385),
            Vector3(0.062,0.102,0.746),steel)

    # Small rear cantilever loading crane, separate from the main body.
    var crane:=Node3D.new()
    crane.name=CRANE
    crane.position=Vector3(0.431,1.722,1.530)
    chassis.add_child(crane)
    _cyl(crane,"G16_V1_CraneTurntable",Vector3(0,-0.056,0),
        0.203,0.142,frame,Vector3.ZERO,20 if hero else 12)
    _box(crane,"G16_V1_CranePedestal",Vector3(0,0.165,0),
        Vector3(0.336,0.341,0.353),steel)
    var boom:=Node3D.new()
    boom.name=BOOM
    boom.position=Vector3(0,0.350,0)
    crane.add_child(boom)
    _box(boom,"G16_V1_SteelFirstBoom",
        Vector3(0,0,0.515),Vector3(0.191,0.184,1.115),steel)
    var extend:=Node3D.new()
    extend.name="G16_V1_ExtendingBoom"
    extend.position=Vector3(0,0,1.025)
    boom.add_child(extend)
    _box(extend,"G16_V1_ChromeSlidingBoom",
        Vector3(0,0,0.260),Vector3(0.134,0.130,0.570),steel)
    var hook:=Node3D.new()
    hook.name="G16_V1_LoadHook"
    hook.position=Vector3(0,-0.265,0.595)
    extend.add_child(hook)
    _cyl(hook,"G16_V1_HangingHookCable",Vector3(0,0.185,0),
        0.019,0.431,frame,Vector3.ZERO,8)
    _box(hook,"G16_V1_HangingHook",
        Vector3(0,-0.060,0),Vector3(0.108,0.082,0.107),steel)
    var crate:=_box(hook,CRATE,
        Vector3(0,-0.323,0),Vector3(0.452,0.337,0.469),ammo)
    crate.visible=false

    # Compact visible stabilizers; no independent new resupply building.
    for side in [-1,1]:
        var s:float=float(side)
        var foot:=Node3D.new()
        foot.name="G16_V1_Stabilizer_%d" % side
        foot.position=Vector3(s*0.91,0.878,1.514)
        chassis.add_child(foot)
        _box(foot,"G16_V1_StabilizerBeam",
            Vector3(s*0.275,-0.070,0),
            Vector3(0.562,0.116,0.128),steel)
        _box(foot,"G16_V1_StabilizerPad",
            Vector3(s*0.576,-0.322,0),
            Vector3(0.159,0.532,0.246),frame)

    # Visual-only glowing supply indicators, not a combat healing effect.
    var markers:=Node3D.new()
    markers.name=MARKERS
    markers.visible=false
    chassis.add_child(markers)
    for i in range(3):
        _box(markers,"G16_V1_LitCargoMarker_%d" % i,
            Vector3(-0.845+float(i)*0.83,1.72,0.155),
            Vector3(0.175,0.030,0.115),amber)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g16_v1_art_only",true)
    root.set_meta("tarvoka_g16_v1_wheels",6)
    root.set_meta("tarvoka_g16_v1_tank_count",2)
    root.set_meta("tarvoka_g16_v1_ammo_chests",2)
    root.set_meta("tarvoka_g16_v1_opaque_glass",true)
    root.set_meta("tarvoka_g16_v1_camp_is_visual_only",true)
    root.set_meta("tarvoka_g16_v1_high_detail",hero)
    root.set_meta("tarvoka_g16_v1_faction_color",paint.to_html())
    restore(root)
    return true

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func restore(root:Node3D)->void:
    if not has_model(root):
        return
    root.rotation_degrees.z=0
    var boom:=root.find_child(BOOM,true,false) as Node3D
    var crane:=root.find_child(CRANE,true,false) as Node3D
    var extending:=root.find_child("G16_V1_ExtendingBoom",true,false) as Node3D
    var awning:=root.find_child(AWNING,true,false) as Node3D
    var gate:=root.find_child(GATE,true,false) as Node3D
    var crate:=root.find_child(CRATE,true,false) as MeshInstance3D
    var supply:=root.find_child(MARKERS,true,false) as Node3D
    if boom!=null:
        boom.rotation_degrees=Vector3.ZERO
    if crane!=null:
        crane.rotation_degrees.y=0
    if extending!=null:
        extending.position.z=1.025
    if awning!=null:
        awning.rotation_degrees.z=90
    if gate!=null:
        gate.rotation_degrees.x=-90
    if crate!=null:
        crate.visible=false
    if supply!=null:
        supply.visible=false
    for side in [-1,1]:
        var leg:=root.find_child("G16_V1_Stabilizer_%d" % side,
            true,false) as Node3D
        if leg!=null:
            leg.rotation_degrees.z=0
    for side in [-1,1]:
        for axle in range(AXLES.size()):
            var wheel:=root.find_child(
                WHEEL_PREFIX+"%d_%d" % [side,axle],true,false) as Node3D
            if wheel!=null:
                wheel.rotation_degrees.x=0
    root.set_meta("tarvoka_g16_v1_pose","idle")

static func pose(root:Node3D,kind:String,progress:float,
        _heading:Vector2i=Vector2i(0,-1))->bool:
    if not has_model(root) or kind not in VALID_POSES:
        return false
    var p:float=clampf(progress,0.0,1.0)
    restore(root)
    var boom:=root.find_child(BOOM,true,false) as Node3D
    var crane:=root.find_child(CRANE,true,false) as Node3D
    var extending:=root.find_child("G16_V1_ExtendingBoom",true,false) as Node3D
    var awning:=root.find_child(AWNING,true,false) as Node3D
    var gate:=root.find_child(GATE,true,false) as Node3D
    var crate:=root.find_child(CRATE,true,false) as MeshInstance3D
    var markers:=root.find_child(MARKERS,true,false) as Node3D
    if boom==null or crane==null or extending==null or (
            awning==null or gate==null or crate==null or markers==null):
        return false
    var deployed:float=0.0
    if kind=="move":
        for side in [-1,1]:
            for axle in range(AXLES.size()):
                var wheel:=root.find_child(
                    WHEEL_PREFIX+"%d_%d" % [side,axle],true,false) as Node3D
                if wheel!=null:
                    wheel.rotation_degrees.x=rad_to_deg(TAU*1.80*p)
    elif kind in ["deploy","unload","resupply","camp","pack"]:
        deployed=smoothstep(0.0,0.75,p) if kind=="deploy" else (
            1.0-p if kind=="pack" else 1.0)
        gate.rotation_degrees.x=-90.0*(1.0-deployed)
        awning.rotation_degrees.z=90.0*(1.0-deployed)
        for side in [-1,1]:
            var stabilizer:=root.find_child(
                "G16_V1_Stabilizer_%d" % side,true,false) as Node3D
            if stabilizer!=null:
                stabilizer.rotation_degrees.z=-float(side)*17.0*deployed
        crane.rotation_degrees.y=25.0*deployed
        if kind in ["unload","resupply"]:
            boom.rotation_degrees.x=-37.0*smoothstep(0.0,0.55,p)
            extending.position.z=1.025+0.28*smoothstep(0.17,0.83,p)
            crate.visible=p>0.18 and p<0.96
        if kind=="camp":
            boom.rotation_degrees.x=-29.0
            extending.position.z=1.305
            crate.visible=false
            markers.visible=true
        if kind=="resupply":
            markers.visible=true
    elif kind=="hit":
        root.rotation_degrees.z=sin(p*PI)*2.1
    root.set_meta("tarvoka_g16_v1_pose",kind)
    root.set_meta("tarvoka_g16_v1_deploy_progress",deployed)
    return true
