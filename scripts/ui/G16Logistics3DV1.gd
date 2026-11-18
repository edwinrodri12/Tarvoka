extends RefCounted
class_name TarvokaG16Logistics3DV1

# TARVOKA G16 V1: actual Godot MeshInstance3D art for the already-defined
# logistics family. This script deliberately never edits supply stocks,
# turns, attack rules, save files, AI, prices or tactical movement.
const FLAG := "tarvoka_g16_logistics_native_3d_v1"
const BODY := "G16_ChassisAndCab"
const WHEELS := "G16_WheelAssemblies"
const CRANE := "G16_CraneBaseAzimuth"
const BOOM := "G16_CraneBoomElevation"
const PALLET := "G16_SupplyPallet"
const HOSE := "G16_RefuelHosePivot"
const TIRES := "G16_VulcanizedRubber"
const RIMS := "G16_MachinedRim"
const PAINT := "G16_FactionEnamel"
static var _materials: Dictionary = {}

static func _mat(color: Color, metallic: float, roughness: float,
        lacquer: bool = false) -> StandardMaterial3D:
    var key: String = "%s|%.2f|%.2f|%s" % [
        color.to_html(),metallic,roughness,str(lacquer)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    m.clearcoat_enabled = lacquer
    if lacquer:
        m.clearcoat = 0.36
        m.clearcoat_roughness = 0.32
    _materials[key] = m
    return m

static func _box(parent: Node3D, label: String, pos: Vector3,
        extent: Vector3, mat: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = extent
    node.mesh = mesh
    node.material_override = mat
    node.position = pos
    node.rotation_degrees = angles
    parent.add_child(node)
    return node

static func _cylinder(parent: Node3D, label: String, pos: Vector3,
        radius: float, height: float, mat: Material,
        angle: Vector3 = Vector3.ZERO, sides: int = 18) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    node.mesh = mesh
    node.material_override = mat
    node.position = pos
    node.rotation_degrees = angle
    parent.add_child(node)
    return node

static func _sphere(parent: Node3D, label: String, pos: Vector3,
        size3: Vector3, mat: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 14
    mesh.rings = 8
    node.mesh = mesh
    node.material_override = mat
    node.position = pos
    node.scale = size3
    parent.add_child(node)
    return node

# CLOSED octagonal cross section, truly beveled hard-surface geometry instead
# of a basic rectangular truck box. Front/rear/side triangles face outward.
static func _octagonal_shell(parent: Node3D,label: String,half_width: float,
        y_low: float,y_high: float,z_front: float,z_rear: float,
        bevel: float,mat: Material) -> MeshInstance3D:
    var w: float = half_width
    var h: float = clampf(bevel,0.02,minf(w*0.6,(y_high-y_low)*0.40))
    var contour: Array[Vector2] = [
        Vector2(-w+h,y_low),Vector2(w-h,y_low),
        Vector2(w,y_low+h),Vector2(w,y_high-h),
        Vector2(w-h,y_high),Vector2(-w+h,y_high),
        Vector2(-w,y_high-h),Vector2(-w,y_low+h)]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for idx in range(1,contour.size()-1):
        for v in [0,idx+1,idx]:
            var xy: Vector2 = contour[v]
            surface.add_vertex(Vector3(xy.x,xy.y,z_front))
        for v in [0,idx,idx+1]:
            var xy: Vector2 = contour[v]
            surface.add_vertex(Vector3(xy.x,xy.y,z_rear))
    for idx in range(contour.size()):
        var next: int = (idx+1)%contour.size()
        var a: Vector2=contour[idx]
        var b: Vector2=contour[next]
        var af:=Vector3(a.x,a.y,z_front)
        var bf:=Vector3(b.x,b.y,z_front)
        var ar:=Vector3(a.x,a.y,z_rear)
        var br:=Vector3(b.x,b.y,z_rear)
        for v in [af,bf,br,af,br,ar]:
            surface.add_vertex(v)
    surface.generate_normals()
    var out := MeshInstance3D.new()
    out.name=label
    out.mesh=surface.commit()
    out.material_override=mat
    parent.add_child(out)
    return out

static func _wheel(parent: Node3D,side: int,axle: int,z: float,
        hero: bool,rubber: Material,rim: Material,dark: Material) -> void:
    var sx: float = float(side)
    var steer := Node3D.new()
    steer.name="G16_Steer_%s_%d" % [side,axle]
    steer.position=Vector3(sx*0.89,0.34,z)
    parent.add_child(steer)
    var roll := Node3D.new()
    roll.name="G16_Roll_%s_%d" % [side,axle]
    steer.add_child(roll)
    _cylinder(roll,TIRES+"_%s_%d" % [side,axle],
        Vector3.ZERO,0.326,0.246,rubber,Vector3(0,0,90),24)
    # 3D sidewall and central hub, not flat wheel textures.
    _cylinder(roll,"G16_RubberSidewall_%s_%d" % [side,axle],
        Vector3(sx*0.131,0,0),0.285,0.012,rubber,Vector3(0,0,90),22)
    _cylinder(roll,RIMS+"_%s_%d" % [side,axle],
        Vector3(sx*0.146,0,0),0.175,0.032,rim,Vector3(0,0,90),18)
    _cylinder(roll,"G16_CenterHub_%s_%d" % [side,axle],
        Vector3(sx*0.168,0,0),0.074,0.042,dark,Vector3(0,0,90),14)
    if hero:
        for tread in range(14):
            var a: float = TAU*float(tread)/14.0
            _box(roll,"G16_TreadBlock_%s_%d_%02d" % [side,axle,tread],
                Vector3(0,cos(a)*0.323,sin(a)*0.323),
                Vector3(0.252,0.039,0.080),rubber,
                Vector3(rad_to_deg(a),0,0))
        for bolt in range(6):
            var a: float=TAU*float(bolt)/6.0
            _sphere(roll,"G16_LugNut_%s_%d_%d" % [side,axle,bolt],
                Vector3(sx*0.177,cos(a)*0.121,sin(a)*0.121),
                Vector3(0.039,0.039,0.039),rim)

static func build(root: Node3D,faction_color: Color,
        hero: bool = true) -> bool:
    if root==null:
        return false
    if has_model(root):
        return true
    var armor := _mat(Color("#87969b"),0.47,0.52)
    var armored_trim := _mat(Color("#abb3b7"),0.56,0.47)
    var frame := _mat(Color("#293840"),0.42,0.66)
    var steel := _mat(Color("#c7d1d2"),0.80,0.29)
    var rubber := _mat(Color("#242629"),0.0,0.94)
    var tanksteel := _mat(Color("#75858b"),0.64,0.44)
    var cargo := _mat(Color("#697a66"),0.10,0.78)
    var pale_cargo := _mat(Color("#a3a78a"),0.07,0.83)
    var glass := _mat(Color("#4a7185"),0.12,0.16,true)
    var paint := _mat(faction_color,0.26,0.45,true)
    var lamps := _mat(Color("#f8dfab"),0.08,0.24)
    var tail_lamps := _mat(Color("#bd4a40"),0.08,0.35)
    var body := Node3D.new()
    body.name=BODY
    root.add_child(body)
    # CAB-OVER configuration: compact articulated support truck rather
    # than G15's long sealed EW hut or G13's combat turret.
    _octagonal_shell(body,"G16_ArmoredCab",0.69,
        0.83,1.88,-1.79,-0.40,0.125,armor)
    _octagonal_shell(body,"G16_CabRoof",0.68,
        1.86,1.99,-1.68,-0.36,0.065,armored_trim)
    _box(body,"G16_ArmoredWindshield",Vector3(0,1.52,-1.802),
        Vector3(1.13,0.42,0.04),glass,Vector3(-11,0,0))
    _box(body,"G16_CabGlassDivider",Vector3(0,1.53,-1.836),
        Vector3(0.074,0.46,0.065),frame,Vector3(-11,0,0))
    _box(body,"G16_DieselGrille",Vector3(0,1.01,-1.812),
        Vector3(0.92,0.24,0.032),frame)
    _box(body,"G16_Bumper",Vector3(0,0.69,-1.89),
        Vector3(1.63,0.19,0.20),steel)
    _box(body,"G16_LadderFrame",Vector3(0,0.70,-0.02),
        Vector3(1.39,0.22,3.64),frame)
    for side in [-1,1]:
        var sx: float=float(side)
        _box(body,"G16_CabDoor_%s" % side,
            Vector3(sx*0.698,1.30,-0.96),
            Vector3(0.026,0.70,0.78),armored_trim)
        _box(body,"G16_DoorWindow_%s" % side,
            Vector3(sx*0.721,1.58,-1.06),
            Vector3(0.025,0.27,0.49),glass)
        _box(body,"G16_DoorHandle_%s" % side,
            Vector3(sx*0.736,1.26,-0.78),
            Vector3(0.045,0.04,0.18),steel)
        _box(body,"G16_FactionDoor_%s" % side,
            Vector3(sx*0.738,1.04,-1.02),
            Vector3(0.018,0.13,0.56),paint)
        # The earlier band sat INSIDE the metal sideboard and was hidden in
        # real Godot screenshots. Place restrained color on its outer face.
        _box(body,"G16_FactionBed_%s" % side,
            Vector3(sx*0.820,1.34,0.66),
            Vector3(0.022,0.145,1.68),paint)
        _box(body,"G16_Headlamp_%s" % side,
            Vector3(sx*0.52,0.99,-1.839),
            Vector3(0.23,0.15,0.042),lamps)
        _box(body,"G16_RearLamp_%s" % side,
            Vector3(sx*0.59,0.73,1.81),
            Vector3(0.22,0.15,0.04),tail_lamps)
        _box(body,"G16_Step_%s" % side,
            Vector3(sx*0.80,0.70,-0.91),
            Vector3(0.30,0.082,0.68),frame)
        _box(body,"G16_SideGuard_%s" % side,
            Vector3(sx*0.825,0.78,0.49),
            Vector3(0.090,0.16,2.12),frame)
    # Raised flatbed, ribbed bottom and low slingable sideboards.
    _box(body,"G16_CargoBed",Vector3(0,1.06,0.70),
        Vector3(1.55,0.18,2.25),armored_trim)
    for side in [-1,1]:
        var sx: float=float(side)
        _box(body,"G16_FoldSideboard_%s" % side,
            Vector3(sx*0.77,1.29,0.67),
            Vector3(0.07,0.36,2.10),armor)
        for lug in range(3):
            _box(body,"G16_SideboardHinge_%s_%d" % [side,lug],
                Vector3(sx*0.804,1.10,-0.08+float(lug)*0.78),
                Vector3(0.13,0.09,0.12),steel)
    _box(body,"G16_RearTailgate",Vector3(0,1.27,1.84),
        Vector3(1.45,0.39,0.072),armor)
    for plank in range(8):
        _box(body,"G16_BedRib_%02d" % plank,
            Vector3(0,1.177,-0.34+float(plank)*0.294),
            Vector3(1.33,0.022,0.046),frame)
    # Two cylindrical liquid containers, not a fake flat decal.
    for side in [-1,1]:
        var sx: float=float(side)
        _cylinder(body,"G16_FuelPod_%s" % side,
            Vector3(sx*0.36,1.47,0.44),0.265,1.22,
            tanksteel,Vector3(90,0,0),24)
        for end in [-1,1]:
            _cylinder(body,"G16_FuelPodCap_%s_%s" % [side,end],
                Vector3(sx*0.36,1.47,0.44+float(end)*0.63),
                0.213,0.036,steel,Vector3(90,0,0),20)
        _box(body,"G16_TankSupport_%s" % side,
            Vector3(sx*0.36,1.232,0.44),
            Vector3(0.35,0.085,1.25),frame)
        _cylinder(body,"G16_Valve_%s" % side,
            Vector3(sx*0.36,1.75,0.44),0.060,0.13,
            steel,Vector3.ZERO,10)
    # Removable strapped cargo boxes show finite carried supply, without
    # assuming the game has awarded extra ammunition or fuel.
    var pallet := Node3D.new()
    pallet.name=PALLET
    pallet.position=Vector3(0,1.23,1.35)
    body.add_child(pallet)
    _box(pallet,"G16_PalletBase",Vector3.ZERO,
        Vector3(1.22,0.10,0.66),frame)
    for side in [-1,1]:
        var sx: float=float(side)
        _box(pallet,"G16_CargoCase_%s" % side,
            Vector3(sx*0.325,0.265,0),
            Vector3(0.55,0.45,0.55),cargo)
        _box(pallet,"G16_CaseMetalLid_%s" % side,
            Vector3(sx*0.325,0.502,0),
            Vector3(0.57,0.052,0.57),steel)
        _box(pallet,"G16_CaseStrap_%s" % side,
            Vector3(sx*0.325,0.54,0),
            Vector3(0.10,0.025,0.61),pale_cargo)
    # Service-hose reel is only a physical articulation for the viewer.
    var hose := Node3D.new()
    hose.name=HOSE
    hose.position=Vector3(0.78,1.03,-0.14)
    body.add_child(hose)
    _cylinder(hose,"G16_HoseSpool",Vector3(0.065,0.0,0),
        0.22,0.15,frame,Vector3(0,0,90),20)
    _cylinder(hose,"G16_CoupledHose",Vector3(0.20,-0.19,0),
        0.037,0.45,rubber,Vector3(0,0,25),12)
    _cylinder(hose,"G16_ServiceNozzle",Vector3(0.29,-0.37,0),
        0.07,0.16,steel,Vector3(0,0,25),12)
    # Crane support root, main piston and hooked extension use a genuine
    # articulated Node3D hierarchy rather than a baked animation sprite.
    var crane := Node3D.new()
    crane.name=CRANE
    crane.position=Vector3(-0.60,1.22,1.58)
    body.add_child(crane)
    _cylinder(crane,"G16_CraneTurntable",Vector3(0,0.08,0),
        0.21,0.16,frame,Vector3.ZERO,20)
    _box(crane,"G16_CranePedestal",Vector3(0,0.24,0),
        Vector3(0.23,0.39,0.24),steel)
    var boom := Node3D.new()
    boom.name=BOOM
    boom.position=Vector3(0,0.41,0)
    crane.add_child(boom)
    _box(boom,"G16_HydraulicBoom",Vector3(0,0,-0.60),
        Vector3(0.18,0.14,1.21),armor)
    _box(boom,"G16_BoomExtension",Vector3(0,0,-1.20),
        Vector3(0.13,0.10,0.58),steel)
    _cylinder(boom,"G16_HydraulicRam",Vector3(0,-0.095,-0.50),
        0.052,0.76,steel,Vector3(90,0,0),10)
    _box(boom,"G16_HookMount",Vector3(0,-0.075,-1.48),
        Vector3(0.14,0.20,0.12),frame)
    _sphere(boom,"G16_LoadHook",Vector3(0,-0.19,-1.48),
        Vector3(0.115,0.14,0.09),steel)
    var wheel_group := Node3D.new()
    wheel_group.name=WHEELS
    body.add_child(wheel_group)
    for side in [-1,1]:
        for axle in range(3):
            var z: float=-1.18+float(axle)*1.18
            _wheel(wheel_group,side,axle,z,hero,rubber,steel,frame)
            _box(body,"G16_WheelArch_%s_%d" % [side,axle],
                Vector3(float(side)*0.79,0.735,z),
                Vector3(0.23,0.08,0.74),frame)
    if hero:
        for bolt in range(4):
            var x: float=-0.43+float(bolt)*0.28
            _box(body,"G16_CabRoofGrip_%d" % bolt,
                Vector3(x,2.06,-0.75),
                Vector3(0.075,0.045,0.55),steel)
        for rib in range(4):
            _box(body,"G16_TailgateReinforcement_%d" % rib,
                Vector3(-0.50+float(rib)*0.33,1.27,1.887),
                Vector3(0.055,0.28,0.018),frame)
        for side in [-1,1]:
            var sx:float=float(side)
            _cylinder(body,"G16_FuelLine_%s" % side,
                Vector3(sx*0.39,1.205,0.44),0.026,1.08,
                rubber,Vector3(90,0,0),9)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g16_hero",hero)
    root.set_meta("tarvoka_g16_art_only",true)
    root.set_meta("tarvoka_g16_real_cargo_sculpt",true)
    restore(root)
    return true

static func has_model(root: Node3D) -> bool:
    return root!=null and bool(root.get_meta(FLAG,false)) and (
        root.find_child(BODY,true,false)!=null)

static func pose(root: Node3D,kind: String,amount: float,
        heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_model(root):
        return false
    var chassis:=root.find_child(BODY,true,false) as Node3D
    var wheel_group:=root.find_child(WHEELS,true,false) as Node3D
    var crane:=root.find_child(CRANE,true,false) as Node3D
    var boom:=root.find_child(BOOM,true,false) as Node3D
    var pallet:=root.find_child(PALLET,true,false) as Node3D
    var hose:=root.find_child(HOSE,true,false) as Node3D
    if chassis==null or wheel_group==null or crane==null or boom==null or (
            pallet==null or hose==null):
        return false
    var t:float=clampf(amount,0.0,1.0)
    # All poses are deterministic and can be interrupted without stale parts.
    restore(root)
    chassis.rotation.y=atan2(float(heading.x),-float(heading.y))
    match kind:
        "idle":
            pass
        "move":
            for steer in wheel_group.get_children():
                if str(steer.name).ends_with("_0"):
                    (steer as Node3D).rotation.y=0.13*sin(t*TAU)
                var rolling:Node3D=steer.get_child(0) as Node3D
                rolling.rotation.x=t*TAU*1.9
            chassis.position.y=0.017*sin(t*TAU*2.0)
        "crane":
            crane.rotation.y=deg_to_rad(58.0*t)
            boom.rotation.x=deg_to_rad(48.0*t)
        "supply":
            hose.rotation.y=deg_to_rad(-70.0*t)
            pallet.position.y=1.23+0.18*t
            crane.rotation.y=deg_to_rad(35.0*t)
            boom.rotation.x=deg_to_rad(35.0*t)
        "hit":
            chassis.rotation_degrees.z=3.0*sin(t*PI)
            boom.rotation_degrees.x=6.0*sin(t*PI)
        "destroy":
            chassis.rotation_degrees.z=12.0*t
            boom.rotation_degrees.x=28.0*t
            pallet.rotation_degrees.z=-28.0*t
            chassis.position.y=-0.11*t
        _:
            return false
    root.set_meta("tarvoka_g16_preview_pose",kind)
    return true

static func restore(root: Node3D) -> void:
    if not has_model(root):
        return
    var chassis:=root.find_child(BODY,true,false) as Node3D
    var wheel_group:=root.find_child(WHEELS,true,false) as Node3D
    var crane:=root.find_child(CRANE,true,false) as Node3D
    var boom:=root.find_child(BOOM,true,false) as Node3D
    var pallet:=root.find_child(PALLET,true,false) as Node3D
    var hose:=root.find_child(HOSE,true,false) as Node3D
    chassis.position=Vector3.ZERO
    chassis.rotation=Vector3.ZERO
    crane.rotation=Vector3.ZERO
    boom.rotation=Vector3.ZERO
    hose.rotation=Vector3.ZERO
    pallet.position=Vector3(0,1.23,1.35)
    pallet.rotation=Vector3.ZERO
    for steer in wheel_group.get_children():
        (steer as Node3D).rotation=Vector3.ZERO
        (steer.get_child(0) as Node3D).rotation=Vector3.ZERO
    root.set_meta("tarvoka_g16_preview_pose","idle")
