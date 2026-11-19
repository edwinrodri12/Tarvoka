extends RefCounted
class_name TarvokaG14MobileSAMLauncherV3

# G14 V3 — native mechanical SAM pod finish.
# Two real-length telescoping hydraulic actuators, 4 independent hatch hinges,
# bore rims, flange bolts, locking collars and faction recognition bands.
# Visual-only. No modifications to projectile damage, targeting or ammunition.
const V1=preload("res://scripts/ui/G14MobileSAMV1.gd")
const V2=preload("res://scripts/ui/G14MobileSAMExteriorV2.gd")
const FLAG="tarvoka_g14_v3_hydraulic_4pod_mount"
const HYDRAULICS="G14_V3_TrueTelescopicSupports"
const PODS="G14_V3_SealedPodMechanics"
const ORIGINAL_DOORS="tarvoka_g14_v3_legacy_door_visibility"
const HATCH="G14_V3_HatchHinge_"
const SHAFT="G14_V3_ChromeRam_"
const HOUSING="G14_V3_HydraulicBarrel_"
const PIVOT="G14_V3_PivotPin_"
const MOUTH="G14_V3_SealedMouth_"
const POD_COUNT=4

static func _material(tint:Color,metal:float,rough:float,
        coated:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=tint
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    if coated:
        m.clearcoat_enabled=true
        m.clearcoat=0.33
        m.clearcoat_roughness=0.30
    return m

static func _box(parent:Node3D,label:String,position:Vector3,
        size:Vector3,material:Material)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=mesh
    item.position=position
    item.material_override=material
    parent.add_child(item)
    return item

static func _cylinder(parent:Node3D,label:String,position:Vector3,
        radius:float,length:float,material:Material,
        degrees:Vector3=Vector3.ZERO,segments:int=12)->MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=segments
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=mesh
    item.material_override=material
    item.position=position
    item.rotation_degrees=degrees
    parent.add_child(item)
    return item

static func _sphere(parent:Node3D,label:String,pos:Vector3,
        radius:float,material:Material,hero:bool)->MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=16 if hero else 10
    mesh.rings=8 if hero else 5
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=mesh
    item.position=pos
    item.material_override=material
    parent.add_child(item)
    return item

static func _torus(parent:Node3D,label:String,pos:Vector3,
        inner:float,outer:float,material:Material,hero:bool)->MeshInstance3D:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=12 if hero else 7
    mesh.ring_segments=24 if hero else 12
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=mesh
    item.position=pos
    item.rotation_degrees.x=90.0
    item.material_override=material
    parent.add_child(item)
    return item

static func _rod(parent:Node3D,label:String,radius:float,
        material:Material,hero:bool)->MeshInstance3D:
    # One unit-length native cylinder rescaled along its axis every frame,
    # so its endpoints track both ends of the actual moving joint.
    var item:=_cylinder(parent,label,Vector3.ZERO,
        radius,1.0,material,Vector3.ZERO,16 if hero else 10)
    return item

static func _point_rod(item:MeshInstance3D,a:Vector3,b:Vector3)->void:
    if item==null:
        return
    var diff:Vector3=b-a
    var length:float=maxf(diff.length(),0.005)
    item.position=(a+b)*0.5
    item.quaternion=Quaternion(Vector3.UP,diff.normalized())
    item.scale=Vector3(1.0,length,1.0)

static func _pod_centroid(i:int)->Vector2:
    return Vector2(-0.36 if i%2==0 else 0.36,
        -0.23 if i<2 else 0.23)

static func apply(root:Node3D,paint:Color)->bool:
    if not V1.has_model(root) or not V2.has_model(root):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var turret:=root.find_child(V1.LAUNCHER,true,false) as Node3D
    var elevation:=root.find_child(V1.ELEVATION,true,false) as Node3D
    if turret==null or elevation==null or (
            turret.find_child(HYDRAULICS,false,false)!=null) or (
            elevation.find_child(PODS,false,false)!=null):
        return false
    var previous:Dictionary={}
    for i in range(POD_COUNT):
        var name:String="G14_TapaLanzador_%d" % i
        var old:=elevation.find_child(name,false,false) as MeshInstance3D
        if old==null:
            return false
        previous[name]=old.visible
    var hero:bool=bool(root.get_meta("tarvoka_g14_v1_high_detail",false))
    var armor:=_material(Color("#556975"),0.55,0.48)
    var machined:=_material(Color("#9cabaf"),0.78,0.28)
    var dark:=_material(Color("#252d32"),0.19,0.75)
    var spring:=_material(Color("#667981"),0.65,0.41)
    var chrome:=_material(Color("#b9c8cd"),0.85,0.17)
    var enamel:=_material(paint.darkened(0.04),0.37,0.39,true)
    var black_bore:=_material(Color("#131b21"),0.08,0.94)
    var hyd:=Node3D.new()
    hyd.name=HYDRAULICS
    turret.add_child(hyd)
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(hyd,"G14_V3_ThickenedTurretCheek_"+id,
            Vector3(s*0.55,0.19,-0.08),
            Vector3(0.185,0.29,0.66),armor)
        _cylinder(hyd,"G14_V3_BaseBearing_"+id,
            Vector3(s*0.52,0.225,-0.42),
            0.126,0.148,machined,Vector3(0,0,90))
        _rod(hyd,HOUSING+id,0.082,spring,hero)
        _rod(hyd,SHAFT+id,0.041,chrome,hero)
        _sphere(hyd,"G14_V3_BaseBallJoint_"+id,
            Vector3(s*0.52,0.21,-0.42),0.094,machined,hero)
        _sphere(hyd,PIVOT+id,
            Vector3(s*0.44,0.34,-0.38),0.089,machined,hero)
        if hero:
            _box(hyd,"G14_V3_HydraulicProtection_"+id,
                Vector3(s*0.61,0.17,-0.18),
                Vector3(0.060,0.24,0.40),dark)

    var rack:=Node3D.new()
    rack.name=PODS
    elevation.add_child(rack)
    _box(rack,"G14_V3_ReinforcedLauncherSpine",
        Vector3(0,-0.008,-0.58),Vector3(1.41,0.12,1.78),dark)
    _cylinder(rack,"G14_V3_CentralTrunnion",
        Vector3(0,-0.04,-0.15),0.12,1.44,machined,
        Vector3(0,0,90),20 if hero else 12)
    for i in range(POD_COUNT):
        var position:Vector2=_pod_centroid(i)
        var x:float=position.x
        var y:float=position.y
        var suffix:String=str(i)
        _box(rack,"G14_V3_PodRoofArmor_"+suffix,
            Vector3(x,y+0.215,-0.68),
            Vector3(0.578,0.049,1.61),armor)
        _box(rack,"G14_V3_PodSideService_"+suffix,
            Vector3(x+0.285,y,-0.63),
            Vector3(0.045,0.343,1.48),armor)
        _box(rack,"G14_V3_FactionGuide_"+suffix,
            Vector3(x+0.310,y+0.008,-0.69),
            Vector3(0.027,0.093,1.20),enamel)
        _box(rack,"G14_V3_RearLock_"+suffix,
            Vector3(x,y,0.19),
            Vector3(0.567,0.410,0.089),dark)
        _torus(rack,MOUTH+suffix,
            Vector3(x,y,-1.638),0.144,0.210,machined,hero)
        _cylinder(rack,"G14_V3_LaunchBore_"+suffix,
            Vector3(x,y,-1.654),0.134,0.045,black_bore,
            Vector3(90,0,0),16 if hero else 12)
        # Individual hinged muzzle hatch. V1 fake flush doors are hidden
        # when V3 is visible and restored exactly in comparison mode.
        var hatch:=Node3D.new()
        hatch.name=HATCH+suffix
        hatch.position=Vector3(x-0.264,y,-1.690)
        rack.add_child(hatch)
        _cylinder(hatch,"G14_V3_DoorHingePin_"+suffix,
            Vector3.ZERO,0.038,0.376,machined)
        _box(hatch,"G14_V3_ArmoredDoor_"+suffix,
            Vector3(0.267,0,0.0),Vector3(0.534,0.338,0.046),armor)
        _box(hatch,"G14_V3_DoorGasket_"+suffix,
            Vector3(0.267,0,-0.031),Vector3(0.462,0.288,0.018),dark)
        if hero:
            for bolt in range(4):
                _cylinder(rack,"G14_V3_PodFastener_%d_%d" % [i,bolt],
                    Vector3(x+(-0.21 if bolt%2==0 else 0.21),
                        y+(-0.183 if bolt<2 else 0.183),-1.650),
                    0.019,0.025,machined,Vector3(90,0,0),8)
        else:
            _box(rack,"G14_V3_LowPolyTubeLatch_"+suffix,
                Vector3(x+0.258,y,-1.640),
                Vector3(0.035,0.18,0.034),machined)

    root.set_meta(ORIGINAL_DOORS,previous)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g14_v3_hydraulics",2)
    root.set_meta("tarvoka_g14_v3_launcher_hatches",4)
    root.set_meta("tarvoka_g14_v3_native_joint_motion",true)
    root.set_meta("tarvoka_g14_v3_no_gameplay_changes",true)
    if not sync(root,"idle",0.0):
        return false
    return show_finish(root,true)

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func show_finish(root:Node3D,enabled:bool)->bool:
    if not has_model(root):
        return false
    var hyd:=root.find_child(HYDRAULICS,true,false) as Node3D
    var rack:=root.find_child(PODS,true,false) as Node3D
    if hyd==null or rack==null:
        return false
    var saved:Dictionary=root.get_meta(ORIGINAL_DOORS,{})
    for i in range(POD_COUNT):
        var name:String="G14_TapaLanzador_%d" % i
        var door:=root.find_child(name,true,false) as MeshInstance3D
        if door==null or not saved.has(name):
            return false
    hyd.visible=enabled
    rack.visible=enabled
    for i in range(POD_COUNT):
        var name:String="G14_TapaLanzador_%d" % i
        var door:=root.find_child(name,true,false) as MeshInstance3D
        door.visible=false if enabled else bool(saved[name])
    root.set_meta("tarvoka_g14_v3_preview_enabled",enabled)
    return true

static func _deploy_progress(kind:String,p:float)->float:
    match kind:
        "deploy":
            return smoothstep(0.0,0.75,p)
        "scan","aim","launch":
            return 1.0
        "stow":
            return 1.0-p
    return 0.0

static func sync(root:Node3D,kind:String,progress:float)->bool:
    if not has_model(root):
        return false
    var elevation:=root.find_child(V1.ELEVATION,true,false) as Node3D
    var turret:=root.find_child(V1.LAUNCHER,true,false) as Node3D
    if elevation==null or turret==null:
        return false
    var p:float=clampf(progress,0.0,1.0)
    var raised:float=_deploy_progress(kind,p)
    # Drive the pistons from actual V1 elevating joint orientation. We do
    # NOT keyframe a cosmetic static bar or change the V1 pitch authority.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        var base:=Vector3(s*0.52,0.21,-0.42)
        var tip:Vector3=elevation.transform*Vector3(s*0.44,0.02,-0.94)
        var mid:Vector3=base.lerp(tip,0.58)
        var barrel:=root.find_child(HOUSING+id,true,false) as MeshInstance3D
        var shaft:=root.find_child(SHAFT+id,true,false) as MeshInstance3D
        var endcap:=root.find_child(PIVOT+id,true,false) as MeshInstance3D
        if barrel==null or shaft==null or endcap==null:
            return false
        _point_rod(barrel,base,mid)
        _point_rod(shaft,mid,tip)
        endcap.position=tip
    for i in range(POD_COUNT):
        var hinge:=root.find_child(HATCH+str(i),true,false) as Node3D
        if hinge==null:
            return false
        var angle:float=0.0
        if kind=="launch":
            var segment:float=p*float(POD_COUNT)
            var active:int=clampi(int(floor(segment)),0,POD_COUNT-1)
            if i==active and p<0.999:
                var shot:float=fmod(segment,1.0)
                var open_fraction:float=smoothstep(0.01,0.30,shot)*(
                    1.0-smoothstep(0.72,0.96,shot))
                angle=93.0*open_fraction
        elif kind=="deploy":
            angle=0.0
        hinge.rotation_degrees.y=-angle if i%2==0 else angle
    root.set_meta("tarvoka_g14_v3_pitch_progress",raised)
    root.set_meta("tarvoka_g14_v3_active_pose",kind)
    return true

static func restore(root:Node3D)->bool:
    return sync(root,"idle",0.0)
