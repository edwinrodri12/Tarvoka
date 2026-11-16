extends RefCounted
class_name TarvokaG13MobileAirDefenseV1

# G13: original compact four-wheel self-propelled air-defense vehicle.
# This is a 3D ART PROTOTYPE only; no anti-air attacks, SAM unlocks,
# target acquisition, ammunition, range or new BattleSession unit IDs.
const FLAG := "tarvoka_g13_mobile_aa_visual_v1"
const BODY := "G13_Casco4x4"
const TURRET := "G13_TorretaAzimut"
const GUNS := "G13_ElevacionCanones"
const RADAR := "G13_RadarAzimut"
const WHEELS := "G13_Ruedas4x4MultiMesh"
const HUBS := "G13_Bujes4x4MultiMesh"
const MFLASH := "G13_DestelloVisual"
const WHEEL_RADIUS := 0.31
const WHEEL_X := 0.85
const WHEEL_Y := 0.33
const WHEEL_Z := 0.85
const HULL_HALF_X := 0.675
const WHEEL_HALF_WIDTH := 0.12
const INNER_CLEARANCE := WHEEL_X-WHEEL_HALF_WIDTH-HULL_HALF_X
static var _materials: Dictionary = {}

static func _mat(color: Color,metallic: float=0.15,roughness: float=0.72)->StandardMaterial3D:
    var key: String="%s_%s_%s" % [color.to_html(),str(metallic),str(roughness)]
    if _materials.has(key):
        return _materials[key]
    var out:=StandardMaterial3D.new()
    out.albedo_color=color
    out.metallic=metallic
    out.roughness=roughness
    _materials[key]=out
    return out

static func _box(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,material: Material,rotate: Vector3=Vector3.ZERO)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=name
    var cube:=BoxMesh.new()
    cube.size=size
    part.mesh=cube
    part.material_override=material
    part.position=pos
    part.rotation_degrees=rotate
    parent.add_child(part)
    return part

static func _cylinder(parent: Node3D,name: String,pos: Vector3,
        radius: float,height: float,material: Material,
        rotation: Vector3=Vector3.ZERO,segments: int=14)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=name
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    part.mesh=mesh
    part.material_override=material
    part.position=pos
    part.rotation_degrees=rotation
    parent.add_child(part)
    return part

static func _wheel_batch(parent: Node3D,label: String,
        radius: float,depth: float,mat: Material)->MultiMeshInstance3D:
    var wheel:=CylinderMesh.new()
    wheel.top_radius=radius
    wheel.bottom_radius=radius
    wheel.height=depth
    wheel.radial_segments=14
    wheel.material=mat
    var multi:=MultiMesh.new()
    multi.transform_format=MultiMesh.TRANSFORM_3D
    multi.mesh=wheel
    multi.instance_count=4
    var view:=MultiMeshInstance3D.new()
    view.name=label
    view.multimesh=multi
    parent.add_child(view)
    return view

static func _wheels_pose(root: Node3D,progress: float)->bool:
    var wheels:=root.find_child(WHEELS,true,false) as MultiMeshInstance3D
    var hubs:=root.find_child(HUBS,true,false) as MultiMeshInstance3D
    if wheels==null or wheels.multimesh==null or (
            wheels.multimesh.instance_count!=4):
        return false
    var spin: float=clampf(progress,0.0,1.0)*TAU*1.8
    var n: int=0
    for side in [-1,1]:
        for axle in [-1,1]:
            var basis: Basis=Basis(Vector3.FORWARD,PI*0.5)*Basis(Vector3.UP,spin)
            var pos:=Vector3(float(side)*WHEEL_X,
                WHEEL_Y,float(axle)*WHEEL_Z)
            wheels.multimesh.set_instance_transform(n,Transform3D(basis,pos))
            if hubs!=null and hubs.multimesh!=null:
                hubs.multimesh.set_instance_transform(n,Transform3D(
                    basis,pos+Vector3(float(side)*0.125,0,0)))
            n+=1
    return true

static func build(root: Node3D,enamel: Color,high_detail: bool=true)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            INNER_CLEARANCE<0.040):
        return false
    var steel:=_mat(Color("#84918d"),0.36,0.72)
    var armor:=_mat(Color("#667477"),0.24,0.77)
    var dark:=_mat(Color("#252d32"),0.10,0.89)
    var rubber:=_mat(Color("#20262a"),0.02,0.94)
    var alloy:=_mat(Color("#a5b0ab"),0.54,0.46)
    var optic:=_mat(Color("#326276"),0.08,0.35)
    var faction:=_mat(enamel.darkened(0.10),0.20,0.62)
    var base:=Node3D.new()
    base.name=BODY
    root.add_child(base)
    # Low, narrow 4x4 silhouette, visually distinct from P06 6x6 and G11 tracks.
    _box(base,"G13_LowerMonocoque",Vector3(0,0.63,0.05),
        Vector3(1.35,0.47,2.42),armor)
    _box(base,"G13_SlopedGlacis",Vector3(0,0.94,-1.03),
        Vector3(1.19,0.42,0.55),steel,Vector3(-23,0,0))
    _box(base,"G13_SealedCab",Vector3(0,1.08,-0.66),
        Vector3(1.19,0.59,0.92),steel)
    _box(base,"G13_CabRoof",Vector3(0,1.40,-0.68),
        Vector3(1.30,0.075,1.12),armor)
    _box(base,"G13_FrontBumper",Vector3(0,0.51,-1.21),
        Vector3(1.29,0.15,0.18),dark)
    for side in [-1,1]:
        _box(base,"G13_FrontGlass_%d" % side,
            Vector3(float(side)*0.29,1.22,-1.133),
            Vector3(0.49,0.235,0.035),optic,Vector3(-15,0,0))
        _box(base,"G13_SideEnamel_%d" % side,
            Vector3(float(side)*0.672,1.00,0.21),
            Vector3(0.032,0.12,0.77),faction)
        _box(base,"G13_Lamp_%d" % side,
            Vector3(float(side)*0.50,0.85,-1.245),
            Vector3(0.135,0.105,0.032),alloy)
    _box(base,"G13_EngineCover",Vector3(0,1.03,0.70),
        Vector3(1.10,0.18,0.67),armor)
    if high_detail:
        for side in [-1,1]:
            for i in range(3):
                _box(base,"G13_RadiatorLouver_%d_%d" % [side,i],
                    Vector3(float(side)*0.37,1.132,
                        0.56+float(i)*0.12),
                    Vector3(0.15,0.018,0.060),dark)
        _box(base,"G13_RearServiceDoor",Vector3(0,0.94,1.278),
            Vector3(0.87,0.44,0.034),steel)
    var wheels:=_wheel_batch(base,WHEELS,WHEEL_RADIUS,0.24,rubber)
    if high_detail:
        _wheel_batch(base,HUBS,0.132,0.042,alloy)
    _wheels_pose(root,0.0)
    var turret:=Node3D.new()
    turret.name=TURRET
    turret.position=Vector3(0,1.41,0.35)
    base.add_child(turret)
    _cylinder(turret,"G13_RotationRing",Vector3(0,0.055,0),
        0.47,0.11,dark)
    _box(turret,"G13_RemoteWeaponHousing",Vector3(0,0.22,0),
        Vector3(0.97,0.38,0.73),steel)
    for side in [-1,1]:
        _box(turret,"G13_TurretFaction_%d" % side,
            Vector3(float(side)*0.498,0.24,0.09),
            Vector3(0.028,0.16,0.45),faction)
    var pitch:=Node3D.new()
    pitch.name=GUNS
    pitch.position=Vector3(0,0.28,-0.21)
    turret.add_child(pitch)
    _box(pitch,"G13_TwinGunReceiver",Vector3(0,0,-0.15),
        Vector3(0.73,0.23,0.52),dark)
    for side in [-1,1]:
        var x: float=float(side)*0.23
        _cylinder(pitch,"G13_Autocannon_%d" % side,
            Vector3(x,-0.015,-0.66),0.057,1.10,alloy,
            Vector3(90,0,0),12)
        _cylinder(pitch,"G13_RealMuzzle_%d" % side,
            Vector3(x,-0.015,-1.220),0.071,0.085,dark,
            Vector3(90,0,0),12)
    # Reusable 3D muzzle effects; generated once, never during pose updates.
    # Both barrels fire in alternating pulses rather than one giant flash.
    for side in [-1,1]:
        var flash:=Node3D.new()
        flash.name="G13_MuzzleFlash_%d" % side
        flash.position=Vector3(float(side)*0.23,-0.015,-1.29)
        flash.visible=false
        pitch.add_child(flash)
        var glow:=_mat(Color(1.0,0.69,0.22,0.92),0.0,0.40)
        _cylinder(flash,"G13_FlashCone_%d" % side,
            Vector3(0,0,-0.10),0.105,0.22,glow,
            Vector3(90,0,0),8)
        var smoke:=Node3D.new()
        smoke.name="G13_MuzzleSmoke_%d" % side
        smoke.position=Vector3(float(side)*0.23,0,-1.36)
        smoke.visible=false
        pitch.add_child(smoke)
        _box(smoke,"G13_SmokeVolume_%d" % side,
            Vector3.ZERO,Vector3(0.16,0.13,0.23),
            _mat(Color(0.56,0.58,0.59,0.40),0.0,1.0))
    _box(turret,"G13_OpticDirector",Vector3(0.40,0.35,-0.32),
        Vector3(0.18,0.20,0.14),optic)
    var radar:=Node3D.new()
    radar.name=RADAR
    radar.position=Vector3(0,1.36,0.89)
    base.add_child(radar)
    _cylinder(radar,"G13_RadarMast",Vector3(0,0.26,0),
        0.075,0.47,dark)
    _cylinder(radar,"G13_TiltedRadarDish",Vector3(0,0.53,0),
        0.295,0.060,armor,Vector3(68,0,0),16)
    _box(radar,"G13_RadarReceiver",Vector3(0,0.54,-0.12),
        Vector3(0.16,0.17,0.18),optic)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v1_art_only",true)
    root.set_meta("tarvoka_g13_v1_wheel_clearance_m",INNER_CLEARANCE)
    root.set_meta("tarvoka_g13_v1_approved_family","G13")
    root.set_meta("tarvoka_g13_v1_high_detail",high_detail)
    restore(root)
    return wheels!=null

static func has_model(root: Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func restore(root: Node3D)->void:
    if not has_model(root):
        return
    var turret:=root.find_child(TURRET,true,false) as Node3D
    var pitch:=root.find_child(GUNS,true,false) as Node3D
    var radar:=root.find_child(RADAR,true,false) as Node3D
    if turret!=null:
        turret.rotation_degrees=Vector3.ZERO
    if pitch!=null:
        pitch.rotation_degrees=Vector3(12,0,0)
    if radar!=null:
        radar.rotation_degrees=Vector3.ZERO
    _wheels_pose(root,0.0)
    for side in [-1,1]:
        var flash:=root.find_child("G13_MuzzleFlash_%d" % side,
            true,false) as Node3D
        var smoke:=root.find_child("G13_MuzzleSmoke_%d" % side,
            true,false) as Node3D
        if flash!=null:
            flash.visible=false
            flash.scale=Vector3.ONE
        if smoke!=null:
            smoke.visible=false
            smoke.scale=Vector3.ONE
    root.set_meta("tarvoka_g13_v1_pose","idle")

# Visual-only cinematic firing poses. No damage, target selection, or ammo.
# Legacy aim/attack remain valid and default to anti-air behavior.
static func pose(root: Node3D,kind: String,t: float,
        heading: Vector2i=Vector2i(0,-1))->bool:
    if not has_model(root) or kind not in [
            "idle","move","scan","aim","attack",
            "aim_air","attack_air","aim_ground","attack_ground"]:
        return false
    var p: float=clampf(t,0.0,1.0)
    restore(root)
    var turret:=root.find_child(TURRET,true,false) as Node3D
    var pitch:=root.find_child(GUNS,true,false) as Node3D
    var radar:=root.find_child(RADAR,true,false) as Node3D
    if turret==null or pitch==null or radar==null:
        return false
    var yaw: float=0.0
    if heading!=Vector2i.ZERO:
        yaw=rad_to_deg(atan2(float(heading.x),-float(heading.y)))
    var air: bool=kind in ["aim","attack","aim_air","attack_air"]
    var ground: bool=kind in ["aim_ground","attack_ground"]
    var firing: bool=kind in ["attack","attack_air","attack_ground"]
    match kind:
        "move":
            _wheels_pose(root,p)
            radar.rotation_degrees.y=15.0*sin(p*TAU)
        "scan":
            radar.rotation_degrees.y=-70.0+140.0*p
        "aim","attack","aim_air","attack_air","aim_ground","attack_ground":
            # AA tracks a high aircraft; ground fire stays near horizontal.
            # The heading controls horizontal bearing without rotating radar.
            turret.rotation_degrees.y=yaw
            pitch.rotation_degrees.x=42.0 if air else 7.0
            radar.rotation_degrees.y=18.0*sin(p*PI)
            if firing:
                # Short staggered bursts: each muzzle flashes only during
                # selected phases. An early muzzle flash differs from smoke.
                var phase: int=int(floor(p*12.0))
                var pulse: bool=phase%3!=2 and p>0.08 and p<0.94
                for side in [-1,1]:
                    var flash:=root.find_child(
                        "G13_MuzzleFlash_%d" % side,true,false) as Node3D
                    var smoke:=root.find_child(
                        "G13_MuzzleSmoke_%d" % side,true,false) as Node3D
                    var active: bool=pulse and (phase%2==0)==(side==-1)
                    if flash!=null:
                        flash.visible=active
                        flash.scale=Vector3.ONE*(0.83+0.17*sin(p*TAU*12.0))
                    if smoke!=null:
                        smoke.visible=p>0.18 and p<0.96 and (
                            (phase+side+12)%3!=0)
                        smoke.scale=Vector3.ONE*(0.85+0.4*p)
                pitch.rotation_degrees.x+=1.2*sin(p*TAU*12.0)
    root.set_meta("tarvoka_g13_v1_pose",kind)
    root.set_meta("tarvoka_g13_v1_demo_domain",
        "air" if air else ("ground" if ground else "none"))
    return true
