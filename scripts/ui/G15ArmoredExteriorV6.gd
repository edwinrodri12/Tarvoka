extends RefCounted
class_name TarvokaG15ArmoredExteriorV6

# G15 V6 — true native Godot 4.3 geometry, not a texture/proxy.
# War-electronics carrier ONLY. No new combat ability or stat changes.
# Earlier 6x6 wheels, V2 arches, V3 sealed shells, V4 antenna and V5 damage
# remain intact; all added parts are grouped and reversible for Studio QA.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const V5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const FLAG="tarvoka_g15_v6_armored_exterior_hard_edges_glazing_vents"
const ASSEMBLY="G15_V6_HullExteriorFinish"
const GLASS_GROUP="G15_V6_CabReflectiveGlazing"
const SIDE_GROUP="G15_V6_EWShelterModularArmor"
const REAR_GROUP="G15_V6_RearElectronicsCooling"
const OLD_GLAZING=["G15_FrontWindow_-1","G15_FrontWindow_1"]

static func _mat(hex:String,metal:float,rough:float,
        coat:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(hex)
    m.metallic=metal
    m.roughness=rough
    m.clearcoat_enabled=coat
    if coat:
        m.clearcoat=0.66
        m.clearcoat_roughness=0.11
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

# A six-sided? No: eight actual corners, closed and front/back capped with
# 28 physical triangles; the side panels occupy real 3D volume.
static func _chamfered_plate(width:float,height:float,depth:float,
        bevel:float)->ArrayMesh:
    var hw:float=width*0.5
    var hh:float=height*0.5
    var b:float=minf(bevel,minf(hw*0.38,hh*0.38))
    var corners:Array[Vector2]=[
        Vector2(-hw+b,-hh),Vector2(hw-b,-hh),
        Vector2(hw,-hh+b),Vector2(hw,hh-b),
        Vector2(hw-b,hh),Vector2(-hw+b,hh),
        Vector2(-hw,hh-b),Vector2(-hw,-hh+b)]
    var front:float=-depth*0.5
    var back:float=depth*0.5
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for k in range(1,7):
        var a:Vector2=corners[0]
        var d:Vector2=corners[k]
        var e:Vector2=corners[k+1]
        _tri(st,Vector3(a.x,a.y,front),
            Vector3(e.x,e.y,front),Vector3(d.x,d.y,front))
        _tri(st,Vector3(a.x,a.y,back),
            Vector3(d.x,d.y,back),Vector3(e.x,e.y,back))
    for i in range(8):
        var j:int=(i+1)%8
        var p:Vector2=corners[i]
        var q:Vector2=corners[j]
        _quad(st,Vector3(p.x,p.y,front),
            Vector3(q.x,q.y,front),
            Vector3(q.x,q.y,back),Vector3(p.x,p.y,back))
    return st.commit() as ArrayMesh

static func _mesh(parent:Node3D,label:String,geo:Mesh,
        material:Material,pos:Vector3=Vector3.ZERO,
        rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=geo
    n.material_override=material
    n.position=pos
    n.rotation_degrees=rot
    parent.add_child(n)
    return n

static func _box(parent:Node3D,label:String,pos:Vector3,
        size:Vector3,mat:Material,
        rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var geo:=BoxMesh.new()
    geo.size=size
    return _mesh(parent,label,geo,mat,pos,rot)

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,sides:int=10)->MeshInstance3D:
    var vec:Vector3=b-a
    var geo:=CylinderMesh.new()
    geo.top_radius=radius
    geo.bottom_radius=radius
    geo.radial_segments=sides
    geo.height=vec.length()
    var n:=_mesh(parent,label,geo,mat,(a+b)*0.5)
    n.quaternion=Quaternion(Vector3.UP,vec.normalized())
    return n

static func _original_windows(root:Node3D)->Array[MeshInstance3D]:
    var arr:Array[MeshInstance3D]=[]
    for label in OLD_GLAZING:
        var n:=root.find_child(label,true,false) as MeshInstance3D
        if n==null or not n.mesh is BoxMesh:
            return []
        arr.append(n)
    return arr

static func apply(root:Node3D,paint:Color)->bool:
    if root==null or not V1.has_model(root) or (
            not bool(root.get_meta(V3.FLAG,false))) or (
            not bool(root.get_meta(V4.FLAG,false))) or (
            not bool(root.get_meta(V5.FLAG,false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var hull:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var windows:Array[MeshInstance3D]=_original_windows(root)
    if hull==null or windows.size()!=2 or (
            root.find_child(ASSEMBLY,true,false)!=null):
        return false
    var high:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var armor:=_mat("#8798a0",0.58,0.45)
    var dark_armor:=_mat("#65757f",0.46,0.59)
    var joint:=_mat("#344148",0.29,0.81)
    var brushed:=_mat("#c0cdd1",0.85,0.29)
    var black:=_mat("#242c31",0.06,0.91)
    var screen:=_mat("#284e66",0.12,0.075,true)
    var warning:=_mat("#c3934d",0.45,0.56)
    var faction:=StandardMaterial3D.new()
    faction.albedo_color=paint
    faction.metallic=0.39
    faction.roughness=0.40
    faction.clearcoat_enabled=true
    faction.clearcoat=0.43
    faction.clearcoat_roughness=0.19

    var root6:=Node3D.new()
    root6.name=ASSEMBLY
    hull.add_child(root6)
    var glass:=Node3D.new()
    glass.name=GLASS_GROUP
    root6.add_child(glass)
    var sides:=Node3D.new()
    sides.name=SIDE_GROUP
    root6.add_child(sides)
    var rear:=Node3D.new()
    rear.name=REAR_GROUP
    root6.add_child(rear)

    var pane:=_chamfered_plate(0.53,0.30,0.020,0.043)
    var seal:=_chamfered_plate(0.576,0.344,0.022,0.050)
    var panel:=_chamfered_plate(0.69,0.64,0.055,0.105)
    var aft:=_chamfered_plate(0.305,0.63,0.049,0.069)
    if pane==null or seal==null or panel==null or aft==null:
        return false
    for piece in [pane,seal,panel,aft]:
        if piece.get_faces().size()!=28*3:
            return false

    # Cab glazing is two real sealed eight-sided panels with a clearcoat
    # specular finish, projected ahead of the original flat windshield.
    # Glass remains opaque/tinted so GLES3/Android does not sort translucent
    # panes against the existing glass and vehicle armor.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _mesh(glass,"G15_V6_FrontWindowSeal_"+id,
            seal,black,Vector3(s*0.338,1.521,-1.683),
            Vector3(-17,0,0))
        _mesh(glass,"G15_V6_SpecularGlass_"+id,
            pane,screen,Vector3(s*0.338,1.527,-1.703),
            Vector3(-17,0,0))
        _box(glass,"G15_V6_WindshieldCenterRib_"+id,
            Vector3(s*0.035,1.52,-1.714),
            Vector3(0.021,0.35,0.027),brushed,
            Vector3(-17,0,0))
        _rod(glass,"G15_V6_WiperArm_"+id,
            Vector3(s*0.125,1.392,-1.731),
            Vector3(s*0.45,1.446,-1.730),0.010,black,8)
        _box(glass,"G15_V6_WiperBlade_"+id,
            Vector3(s*0.446,1.451,-1.740),
            Vector3(0.018,0.018,0.24),black,
            Vector3(0,90,0))
        # Side viewport with beveled glass/physical rubber weather stripping.
        # Cab width is ~1.42m, so X=.770 sits outboard of its armored skin.
        var side_seal:=_box(glass,"G15_V6_SideGlazingSeal_"+id,
            Vector3(s*0.772,1.538,-1.245),
            Vector3(0.023,0.285,0.39),black)
        side_seal.rotation_degrees=Vector3(0,0,0)
        _box(glass,"G15_V6_SideSpecularGlass_"+id,
            Vector3(s*0.789,1.550,-1.247),
            Vector3(0.013,0.239,0.344),screen)
        # Functional-looking side mirrors sit outside wheel-arch line and
        # use real metallic mounting arms rather than hovering rectangles.
        if high:
            _rod(glass,"G15_V6_MirrorBracket_"+id,
                Vector3(s*0.729,1.425,-1.458),
                Vector3(s*0.899,1.521,-1.487),0.015,brushed,10)
            _box(glass,"G15_V6_MirrorHousing_"+id,
                Vector3(s*0.917,1.551,-1.49),
                Vector3(0.104,0.19,0.102),black)
            _box(glass,"G15_V6_MirrorReflection_"+id,
                Vector3(s*0.973,1.555,-1.49),
                Vector3(0.012,0.154,0.075),brushed)

        # Real solid shield plates on shelter's broad flanks. Two short
        # sections leave the existing service hatch and roof outriggers clear.
        # Their local Z is rotated into outboard X, giving real side volume.
        _mesh(sides,"G15_V6_SculptedSideArmor_"+id,
            panel,armor,Vector3(s*0.787,1.445,0.035),
            Vector3(0,90,0))
        _mesh(sides,"G15_V6_RearCornerArmor_"+id,
            aft,dark_armor,Vector3(s*0.788,1.465,1.418),
            Vector3(0,90,0))
        # Faction enamel is EXTERNAL (x=.830): never buried in the steel.
        _box(sides,"G15_V6_FactionMainStripe_"+id,
            Vector3(s*0.832,1.548,0.018),
            Vector3(0.016,0.135,0.50),faction)
        _box(sides,"G15_V6_FactionRearStripe_"+id,
            Vector3(s*0.828,1.580,1.432),
            Vector3(0.015,0.095,0.208),faction)
        _box(sides,"G15_V6_PanelEdgeRib_"+id,
            Vector3(s*0.835,1.778,0.043),
            Vector3(0.052,0.044,0.625),brushed)
        _box(sides,"G15_V6_RoofSideShoulder_"+id,
            Vector3(s*0.712,2.096,0.62),
            Vector3(0.155,0.095,1.93),dark_armor)
        _box(sides,"G15_V6_FactionRoofShoulder_"+id,
            Vector3(s*0.798,2.103,-0.10),
            Vector3(0.014,0.054,0.39),faction)
        # Real recessed metal air duct, isolated from paint and waterproof
        # inspection door. Slats are attached OUTSIDE its dark metal housing.
        _box(sides,"G15_V6_CoolingRecess_"+id,
            Vector3(s*0.836,1.755,1.06),
            Vector3(0.023,0.313,0.33),joint)
        _box(sides,"G15_V6_CoolingMetalRim_"+id,
            Vector3(s*0.850,1.755,1.06),
            Vector3(0.019,0.34,0.36),dark_armor)
        if high:
            for n in range(6):
                _box(sides,"G15_V6_VentFin_%s_%d" % [id,n],
                    Vector3(s*0.865,1.630+float(n)*0.051,1.06),
                    Vector3(0.015,0.019,0.299),black)
            for bolt in range(4):
                _box(sides,"G15_V6_ShieldBolt_%s_%d" % [id,bolt],
                    Vector3(s*0.861,
                        1.166 if bolt<2 else 1.712,
                        -0.200 if bolt%2==0 else 0.265),
                    Vector3(0.025,0.032,0.035),brushed)
            _box(sides,"G15_V6_LowerSkidPlate_"+id,
                Vector3(s*0.85,0.985,0.25),
                Vector3(0.23,0.055,1.30),dark_armor)
            for grab in range(2):
                _rod(sides,"G15_V6_ServiceGrabBar_%s_%d" % [id,grab],
                    Vector3(s*0.834,1.280,1.260+0.090*float(grab)),
                    Vector3(s*0.851,1.571,1.260+0.090*float(grab)),
                    0.012,brushed,8)

    # Rear EW enclosure: deep gasket + fins and protected extractor.
    _box(rear,"G15_V6_RearShieldGasket",
        Vector3(0,1.45,1.692),
        Vector3(1.278,0.844,0.019),black)
    _box(rear,"G15_V6_RearExtractorHousing",
        Vector3(0,1.52,1.716),
        Vector3(0.96,0.390,0.072),dark_armor)
    _box(rear,"G15_V6_RearExtractorRecess",
        Vector3(0,1.52,1.759),
        Vector3(0.807,0.296,0.026),joint)
    for n in range(5 if high else 3):
        var y:float=1.392+float(n)*(0.052 if high else 0.104)
        _box(rear,"G15_V6_RearVentSlat_%d" % n,
            Vector3(0,y,1.786),
            Vector3(0.752,0.022,0.031),brushed)
    _box(rear,"G15_V6_RearHazardStripe",
        Vector3(0,1.045,1.743),
        Vector3(0.98,0.053,0.025),warning)
    if high:
        for sx in [-1,1]:
            _box(rear,"G15_V6_RearLiftEye_%s" % sx,
                Vector3(float(sx)*0.572,1.94,1.71),
                Vector3(0.12,0.105,0.078),brushed)
            _box(rear,"G15_V6_BumperGuard_%s" % sx,
                Vector3(float(sx)*0.565,0.67,1.799),
                Vector3(0.228,0.175,0.11),dark_armor)

    var previous:Dictionary={}
    for window in windows:
        previous[window.name]=window.visible
        window.visible=false
    root.set_meta("tarvoka_g15_v6_prior_windshield",previous)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v6_hero",high)
    root.set_meta("tarvoka_g15_v6_closed_steel_side_panels",4)
    root.set_meta("tarvoka_g15_v6_real_glass_panes",4)
    root.set_meta("tarvoka_g15_v6_hard_surface_only",true)
    root.set_meta("tarvoka_g15_v6_no_gameplay_changes",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var assembly:=root.find_child(ASSEMBLY,true,false) as Node3D
    var old:Array[MeshInstance3D]=_original_windows(root)
    if assembly==null or old.size()!=2:
        return false
    var previous:Dictionary=root.get_meta(
        "tarvoka_g15_v6_prior_windshield",{})
    for prior in old:
        prior.visible=false if enabled else bool(
            previous.get(prior.name,true))
    assembly.visible=enabled
    root.set_meta("tarvoka_g15_v6_preview_enabled",enabled)
    return true
