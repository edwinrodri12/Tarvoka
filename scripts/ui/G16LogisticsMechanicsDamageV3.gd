extends RefCounted
class_name TarvokaG16LogisticsMechanicsV3

# TARVOKA G16 V3: real geometric suspension, sealed cargo connections,
# movable ammo compartment doors and reversible 0..4 visual wreck states.
# NO change to the existing playable 'logistics' role, HP or supply rules.
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const FLAG="tarvoka_g16_v3_native_logistics_mechanics_damage"
const MECHANICS="G16_V3_RealSuspensionAndDrivetrain"
const CARGO="G16_V3_FuelAndAmmoService"
const DOOR="G16_V3_AmmoLidHinge_"
const RAMP="G16_V3_RearGateMechanicalFinish"
const DAMAGE="G16_V3_DamageStage_"
const DAMAGED_CARGO="G16_V3_DamageOnAmmoDoor_"
const DAMAGES=4
const HIDE_ORIGINAL="tarvoka_g16_v3_saved_original_lids"
const SHOW="tarvoka_g16_v3_preview_visible"

static func _mat(color:Color,metal:float=0.2,rough:float=0.72,
        emission:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    if emission:
        m.emission_enabled=true
        m.emission=color
        m.emission_energy_multiplier=1.05
    return m

static func _box(parent:Node3D,label:String,center:Vector3,
        dimensions:Vector3,mat:Material,
        angles:Vector3=Vector3.ZERO)->MeshInstance3D:
    var m:=BoxMesh.new()
    m.size=dimensions
    var mesh:=MeshInstance3D.new()
    mesh.name=label
    mesh.mesh=m
    mesh.material_override=mat
    mesh.position=center
    mesh.rotation_degrees=angles
    parent.add_child(mesh)
    return mesh

static func _cyl(parent:Node3D,label:String,pos:Vector3,
        radius:float,length:float,mat:Material,
        angles:Vector3=Vector3.ZERO,
        segments:int=12)->MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=length
    shape.radial_segments=segments
    var inst:=MeshInstance3D.new()
    inst.name=label
    inst.mesh=shape
    inst.material_override=mat
    inst.position=pos
    inst.rotation_degrees=angles
    parent.add_child(inst)
    return inst

static func _segment(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,detail:int=10)->MeshInstance3D:
    var delta:Vector3=b-a
    var part:=_cyl(parent,label,(a+b)*0.5,radius,
        maxf(delta.length(),0.001),mat,Vector3.ZERO,detail)
    if delta.length_squared()>0.00001:
        part.quaternion=Quaternion(Vector3.UP,delta.normalized())
    return part

static func _sphere(parent:Node3D,label:String,pos:Vector3,
        scaling:Vector3,mat:Material,hero:bool)->MeshInstance3D:
    var sphere:=SphereMesh.new()
    sphere.radius=0.5
    sphere.height=1.0
    sphere.radial_segments=14 if hero else 8
    sphere.rings=8 if hero else 4
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=sphere
    n.material_override=mat
    n.position=pos
    n.scale=scaling
    parent.add_child(n)
    return n

static func _group(parent:Node3D,label:String)->Node3D:
    var item:=Node3D.new()
    item.name=label
    parent.add_child(item)
    return item

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func _original_lids(root:Node3D,visible:bool)->bool:
    var saved:Dictionary=root.get_meta(HIDE_ORIGINAL,{})
    for i in range(2):
        var name:String="G16_V1_AmmoLid_%d" % i
        var original:=root.find_child(name,true,false) as MeshInstance3D
        if original==null or not saved.has(name):
            return false
    for i in range(2):
        var name:String="G16_V1_AmmoLid_%d" % i
        var original:=root.find_child(name,true,false) as MeshInstance3D
        original.visible=(bool(saved[name]) if visible else false)
    return true

static func apply(root:Node3D,paint:Color)->bool:
    if not V1.has_model(root) or not V2.has_model(root):
        return false
    if has_model(root):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var gate:=root.find_child(V1.GATE,true,false) as Node3D
    if chassis==null or gate==null:
        return false
    for i in range(2):
        if root.find_child("G16_V1_AmmoLid_%d" % i,true,false)==null:
            return false
    var saved:Dictionary={}
    for i in range(2):
        var old:=root.find_child("G16_V1_AmmoLid_%d" % i,true,false
            ) as MeshInstance3D
        saved[old.name]=old.visible
    var hero:bool=bool(root.get_meta("tarvoka_g16_v1_high_detail",false))
    var steel:=_mat(Color("#81949a"),0.72,0.38)
    var shadow:=_mat(Color("#263039"),0.33,0.79)
    var alloy:=_mat(Color("#b7c4c6"),0.85,0.30)
    var rubber:=_mat(Color("#20272b"),0.04,0.94)
    var spring:=_mat(Color("#4e5d66"),0.48,0.60)
    var fuel:=_mat(Color("#698991"),0.49,0.50)
    var ammo:=_mat(Color("#838d70"),0.29,0.69)
    var accent:=_mat(paint.darkened(0.07),0.31,0.45)
    var warning:=_mat(Color("#e9ac48"),0.13,0.44)
    var rust:=_mat(Color("#7b5d55"),0.25,0.92)
    var ash:=_mat(Color("#282c2e"),0.08,0.98)
    var glass_crack:=_mat(Color("#1e3541"),0.15,0.94)
    var embers:=_mat(Color("#e78a47"),0.22,0.44,true)

    # Real, separate 6x6 suspension housings: three independently built axle
    # groups, each with leaf-spring stacks, shackles, hydraulic dampers, and
    # wheel-hub sleeves. All sit UNDER the closed cab/cargo 3D geometry.
    var running:=_group(chassis,MECHANICS)
    _box(running,"G16_V3_TransferGearbox",
        Vector3(0,0.568,-0.765),
        Vector3(0.387,0.303,0.482),spring)
    _box(running,"G16_V3_ProtectedCenterExhaust",
        Vector3(-0.456,0.567,0.065),
        Vector3(0.092,0.092,1.64),shadow)
    for axle in range(3):
        var zz:float=float(V1.AXLES[axle])
        var diff:=_group(running,"G16_V3_Axle_%d" % axle)
        diff.position.z=zz
        _box(diff,"G16_V3_CenterDifferential_%d" % axle,
            Vector3(0,0.420,0),
            Vector3(0.394,0.279,0.312),shadow)
        _cyl(diff,"G16_V3_LiveAxleShaft_%d" % axle,
            Vector3(0,0.397,0),0.095,1.86,
            alloy,Vector3(0,0,90),16 if hero else 10)
        for side in [-1,1]:
            var s:float=float(side)
            var prefix:String="%d_%d" % [side,axle]
            var leaf:=_group(diff,"G16_V3_SpringAssembly_"+prefix)
            leaf.position=Vector3(s*0.724,0.672,0)
            for layer in range(4 if hero else 2):
                var scale_width:float=0.659-float(layer)*0.115
                _box(leaf,"G16_V3_LeafSpring_%s_%d" % [prefix,layer],
                    Vector3(0,-float(layer)*0.038,0),
                    Vector3(0.100,0.030,scale_width),spring,
                    Vector3(s*float(layer)*2,0,0))
            for end in [-1,1]:
                _box(leaf,"G16_V3_Shackle_%s_%d" % [prefix,end],
                    Vector3(0,-0.015,float(end)*0.307),
                    Vector3(0.146,0.130,0.067),steel)
            _segment(leaf,"G16_V3_TelescopicShockBody_"+prefix,
                Vector3(s*0.118,-0.195,-0.244),
                Vector3(s*0.060,0.211,0.218),0.069,shadow,
                12 if hero else 8)
            _segment(leaf,"G16_V3_ShockPiston_"+prefix,
                Vector3(s*0.060,0.211,0.218),
                Vector3(s*0.036,0.347,0.366),0.032,alloy,
                12 if hero else 8)
            _box(leaf,"G16_V3_LeafClamp_"+prefix,
                Vector3(0,0.055,0),
                Vector3(0.158,0.096,0.084),alloy)
            _box(diff,"G16_V3_WheelHousing_"+prefix,
                Vector3(s*1.009,0.417,0),
                Vector3(0.179,0.207,0.164),spring)
        if axle>0:
            other_z:float=float(V1.AXLES[axle-1])
            _segment(running,"G16_V3_ProtectedDriveshaft_%d" % axle,
                Vector3(0,0.504,other_z+0.113),
                Vector3(0,0.504,zz-0.113),
                0.052,steel,12 if hero else 8)

    # Cargo is new native 3D geometry — no extra permanent supply building.
    # Fuel coupling is on tank side; ammo lids hinge on each existing chest.
    var cargo:=_group(chassis,CARGO)
    _box(cargo,"G16_V3_PressurizedSupplyPump",
        Vector3(-0.740,1.267,-0.067),
        Vector3(0.301,0.229,0.259),steel)
    _cyl(cargo,"G16_V3_RetractableHoseReel",
        Vector3(-0.733,1.299,-0.230),
        0.133,0.085,shadow,Vector3(90,0,0),20 if hero else 12)
    _cyl(cargo,"G16_V3_FuelIntakeValve",
        Vector3(-0.724,1.382,0.115),
        0.071,0.087,alloy,Vector3.ZERO,16 if hero else 10)
    for i in range(2):
        var z:float=0.36+float(i)*0.94
        # Opaque physical steel clamps and tank-bottom feeder pipes
        for side in [-1,1]:
            _box(cargo,"G16_V3_FuelMountBand_%d_%d" % [i,side],
                Vector3(-0.45,1.480,z+float(side)*0.269),
                Vector3(0.617,0.043,0.038),shadow)
        _cyl(cargo,"G16_V3_FuelNeck_%d" % i,
            Vector3(-0.450,1.805,z),
            0.094,0.088,alloy,Vector3.ZERO,12 if hero else 8)
        _cyl(cargo,"G16_V3_ValveWheel_%d" % i,
            Vector3(-0.450,1.868,z),
            0.101,0.032,warning,Vector3.ZERO,12 if hero else 8)
        _segment(cargo,"G16_V3_LowPressurePipe_%d" % i,
            Vector3(-0.700,1.267,z-0.11),
            Vector3(-0.695,1.264,-0.020),
            0.039,rubber,10 if hero else 6)
        for corner in [-1,1]:
            _box(cargo,"G16_V3_AmmoReinforcedCorner_%d_%d" % [i,corner],
                Vector3(0.804,1.411,z+float(corner)*0.320),
                Vector3(0.044,0.494,0.044),steel)
        lid:=_group(cargo,DOOR+str(i))
        lid.position=Vector3(0.470,1.649,z+0.378)
        # Rotating closed lid fully covers the original ammo box opening.
        _box(lid,"G16_V3_SealedLid_"+str(i),
            Vector3(0,0,-0.378),
            Vector3(0.737,0.063,0.775),ammo)
        _box(lid,"G16_V3_ThickLidGasket_"+str(i),
            Vector3(0,-0.045,-0.377),
            Vector3(0.642,0.024,0.714),shadow)
        _box(lid,"G16_V3_AmmoWarningMark_"+str(i),
            Vector3(0,0.042,-0.382),
            Vector3(0.352,0.015,0.130),accent)
        for hinge in [-1,1]:
            _cyl(lid,"G16_V3_HingePin_%d_%d" % [i,hinge],
                Vector3(float(hinge)*0.277,0,0.008),
                0.048,0.097,alloy,Vector3(0,0,90),12 if hero else 8)
        _box(cargo,"G16_V3_LidLatch_%d" % i,
            Vector3(0.467,1.600,z-0.382),
            Vector3(0.118,0.129,0.052),steel)
        _box(cargo,"G16_V3_CrateLockingClamp_%d" % i,
            Vector3(0.851,1.306,z),
            Vector3(0.067,0.159,0.213),shadow)
    for i in range(4):
        var p:float=float(i)/3.0
        _segment(cargo,"G16_V3_FlexibleSupplyHose_%d" % i,
            Vector3(-0.733,1.30,-0.202+p*0.16),
            Vector3(-0.870-p*0.10,1.04+p*0.22,0.15+p*0.18),
            0.034,rubber,10 if hero else 6)
    _box(cargo,"G16_V3_SolidAmmoCabinetBulkhead",
        Vector3(0,1.348,-0.213),
        Vector3(1.772,0.744,0.096),shadow)
    _box(cargo,"G16_V3_UnitColorCargoNameplate",
        Vector3(0,1.772,-0.262),
        Vector3(0.971,0.092,0.036),accent)

    # Physical tailgate fittings follow SAME V1 hinged ramp in every pose.
    var ramp:=_group(gate,RAMP)
    for side in [-1,1]:
        var s:float=float(side)
        _box(ramp,"G16_V3_GripStrips_%d" % side,
            Vector3(s*0.586,0.063,0.392),
            Vector3(0.122,0.022,0.646),rubber)
        _box(ramp,"G16_V3_SideRampGuide_%d" % side,
            Vector3(s*0.792,0.101,0.392),
            Vector3(0.043,0.106,0.774),steel)
    for n in range(5 if hero else 3):
        _box(ramp,"G16_V3_RampTread_%d" % n,
            Vector3(0,0.074,0.117+float(n)*0.138),
            Vector3(1.50,0.021,0.044),steel)

    # Four cumulative reversible mesh-based damage states, never altering
    # the original solid cab/roof/windshields (V1/V2 stay present).
    var chips:=_group(chassis,DAMAGE+"1")
    _box(chips,"G16_V3_DentLeftDoor",Vector3(-0.989,1.126,-1.20),
        Vector3(0.025,0.104,0.289),rust,Vector3(0,0,12))
    _box(chips,"G16_V3_DentRightSkirt",Vector3(1.026,0.883,0.752),
        Vector3(0.033,0.134,0.340),ash,Vector3(0,0,-13))
    _box(chips,"G16_V3_BumperPaintScuff",Vector3(-0.316,0.678,-2.338),
        Vector3(0.324,0.049,0.028),rust)

    var battered:=_group(chassis,DAMAGE+"2")
    _box(battered,"G16_V3_DamagedLateralArmor",
        Vector3(-1.035,0.923,0.150),
        Vector3(0.036,0.152,0.617),rust,Vector3(0,0,11))
    _box(battered,"G16_V3_DamagedRightRear",
        Vector3(0.586,1.113,2.125),
        Vector3(0.254,0.168,0.043),ash,Vector3(0,-15,4))
    # Thin fracture lines SURFACE-mounted to opaque BoxMesh panes. No wall
    # is perforated, transparent, removed, or re-parented.
    for side in [-1,1]:
        _box(battered,"G16_V3_SealedGlassCrack_%d" % side,
            Vector3(float(side)*0.363,1.459,-2.032),
            Vector3(0.027,0.012,0.046),glass_crack,
            Vector3(26,float(side)*17,35))

    var severe:=_group(chassis,DAMAGE+"3")
    _box(severe,"G16_V3_BrokenLeftTankerCover",
        Vector3(-0.724,1.691,1.140),
        Vector3(0.049,0.280,0.493),ash,Vector3(0,0,-19))
    _box(severe,"G16_V3_CrushedAmmoBoxSurround",
        Vector3(0.850,1.380,1.302),
        Vector3(0.058,0.415,0.573),rust,Vector3(-8,0,16))
    _sphere(severe,"G16_V3_ExhaustDamageDarkSmoke",
        Vector3(-0.740,1.941,1.160),
        Vector3(0.385,0.319,0.312),ash,hero)
    for i in range(2):
        cargo_damage:=_group(cargo,DAMAGED_CARGO+str(i))
        _box(cargo_damage,"G16_V3_AmmoLidCrack_"+str(i),
            Vector3(0.470,1.688,0.36+float(i)*0.94),
            Vector3(0.242,0.031,0.041),rust,Vector3(0,26,0))
    var wreck:=_group(chassis,DAMAGE+"4")
    _box(wreck,"G16_V3_BurntFrontCowl",Vector3(0,1.106,-2.110),
        Vector3(1.531,0.173,0.088),ash)
    _box(wreck,"G16_V3_BurnedRoofPatch",Vector3(0.419,1.810,-1.364),
        Vector3(0.574,0.031,0.516),ash,Vector3(0,17,0))
    _box(wreck,"G16_V3_RearCargoScorch",Vector3(0.384,1.488,1.487),
        Vector3(0.894,0.092,0.572),ash,Vector3(0,-16,0))
    _sphere(wreck,"G16_V3_SmokeColumnOne",Vector3(0.482,1.986,1.03),
        Vector3(0.461,0.582,0.456),ash,hero)
    _sphere(wreck,"G16_V3_SmokeColumnTwo",Vector3(0.612,2.453,1.152),
        Vector3(0.565,0.754,0.522),ash,hero)
    _sphere(wreck,"G16_V3_EmberBelowCargo",Vector3(0.368,1.647,0.922),
        Vector3(0.197,0.117,0.178),embers,hero)
    root.set_meta(FLAG,true)
    root.set_meta(HIDE_ORIGINAL,saved)
    root.set_meta(SHOW,true)
    root.set_meta("tarvoka_g16_v3_6_independent_springs",true)
    root.set_meta("tarvoka_g16_v3_two_hinged_ammo_lids",true)
    root.set_meta("tarvoka_g16_v3_damage_stages",DAMAGES)
    root.set_meta("tarvoka_g16_v3_opaque_structural_cab",true)
    root.set_meta("tarvoka_g16_v3_visual_only",true)
    root.set_meta("tarvoka_g16_v3_damage_level",0)
    if not show_finish(root,true):
        return false
    return sync(root,"idle",0)

static func stage(root:Node3D)->int:
    return int(root.get_meta("tarvoka_g16_v3_damage_level",-1)) if has_model(root) else -1

static func _damage_mesh(root:Node3D,number:int)->Node3D:
    return root.find_child(DAMAGE+str(number),true,false) as Node3D

static func set_damage(root:Node3D,level:int)->bool:
    if not has_model(root) or level<0 or level>DAMAGES:
        return false
    var preview:bool=bool(root.get_meta(SHOW,false))
    for i in range(1,DAMAGES+1):
        if _damage_mesh(root,i)==null:
            return false
    for i in range(2):
        if root.find_child(DAMAGED_CARGO+str(i),true,false)==null:
            return false
    root.set_meta("tarvoka_g16_v3_damage_level",level)
    for i in range(1,DAMAGES+1):
        _damage_mesh(root,i).visible=preview and i<=level
    for i in range(2):
        var damage:=root.find_child(DAMAGED_CARGO+str(i),
            true,false) as Node3D
        damage.visible=preview and level>=3
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if not has_model(root):
        return false
    var running:=root.find_child(MECHANICS,true,false) as Node3D
    var cargo:=root.find_child(CARGO,true,false) as Node3D
    var ramp:=root.find_child(RAMP,true,false) as Node3D
    if running==null or cargo==null or ramp==null:
        return false
    if not _original_lids(root,not enabled):
        return false
    running.visible=enabled
    cargo.visible=enabled
    ramp.visible=enabled
    for i in range(1,DAMAGES+1):
        if _damage_mesh(root,i)==null:
            return false
    root.set_meta(SHOW,enabled)
    if not set_damage(root,stage(root)):
        return false
    if enabled:
        return sync(root,str(root.get_meta("tarvoka_g16_v3_active_pose","idle")),
            float(root.get_meta("tarvoka_g16_v3_active_progress",0)))
    return true

static func sync(root:Node3D,kind:String,progress:float)->bool:
    if not has_model(root):
        return false
    var p:float=clampf(progress,0,1)
    root.set_meta("tarvoka_g16_v3_active_pose",kind)
    root.set_meta("tarvoka_g16_v3_active_progress",p)
    if not bool(root.get_meta(SHOW,true)):
        return true
    for i in range(2):
        var lid:=root.find_child(DOOR+str(i),true,false) as Node3D
        if lid==null:
            return false
        var opening:float=0.0
        if kind=="resupply":
            opening=smoothstep(0.13,0.72,p)
        elif kind=="unload" and i==1:
            opening=smoothstep(0.30,0.75,p)
        elif kind=="camp":
            opening=1.0
        elif kind=="pack":
            opening=1.0-smoothstep(0.12,0.87,p)
        lid.rotation_degrees.x=83.0*opening
    return set_damage(root,stage(root))

static func restore(root:Node3D)->bool:
    return sync(root,"idle",0.0)
