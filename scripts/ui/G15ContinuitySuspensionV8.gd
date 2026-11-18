extends RefCounted
class_name TarvokaG15ContinuitySuspensionV8

# TARVOKA G15 native art, revision V8. This layer adds welded cab-to-shelter
# transitions, three-dimensional armor edge breaks, and visible real coils.
# It never changes wheel pivots, faction stats, EW actions, battlefield data,
# V1-V7 animations, nor V5 visual-destruction behavior.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const V7=preload("res://scripts/ui/G15MechanicalExteriorV7.gd")
const FLAG="tarvoka_g15_v8_continuous_armor_beveled_metal_coil_suspension"
const ASSEMBLY="G15_V8_ContinuousArmorAndRunningGear"
const ARMOR="G15_V8_ContinuousArmorTransitions"
const METAL="G15_V8_SatinBrushedMetalFinishing"
const SUSPENSION="G15_V8_PhysicalCoilSpringAssemblies"

static func _mat(hex:String,metallic:float,roughness:float,
        coat:bool=false)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(hex)
    material.metallic=metallic
    material.roughness=roughness
    material.clearcoat_enabled=coat
    if coat:
        material.clearcoat=0.36
        material.clearcoat_roughness=0.29
    return material

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3)->void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _mesh(parent:Node3D,label:String,geo:Mesh,
        mat:Material,pos:Vector3=Vector3.ZERO)->MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=geo
    item.material_override=mat
    item.position=pos
    parent.add_child(item)
    return item

static func _box(parent:Node3D,label:String,pos:Vector3,size:Vector3,
        mat:Material)->MeshInstance3D:
    var geo:=BoxMesh.new()
    geo.size=size
    return _mesh(parent,label,geo,mat,pos)

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,sides:int=10)->MeshInstance3D:
    var d:Vector3=b-a
    var geo:=CylinderMesh.new()
    geo.top_radius=radius
    geo.bottom_radius=radius
    geo.height=d.length()
    geo.radial_segments=sides
    var rod:=_mesh(parent,label,geo,mat,(a+b)*0.5)
    rod.quaternion=Quaternion(Vector3.UP,d.normalized())
    return rod

# Closed 8-corner tapered upper shoulder, joining the shorter cab to the
# taller EW shelter. This is a real thickness solid: six closed quads or
# exactly 12 triangles, with normals in all three axes. Side-specific X
# vertices are outward-facing at both ends of the tapered cross-section.
static func _transition_mesh(side:int)->ArrayMesh:
    var sign:float=float(side)
    var start:Array[Vector3]=[
        Vector3(sign*0.596,1.616,-0.666),
        Vector3(sign*0.715,1.616,-0.666),
        Vector3(sign*0.715,1.755,-0.666),
        Vector3(sign*0.596,1.755,-0.666)]
    var end:Array[Vector3]=[
        Vector3(sign*0.692,1.676,-0.177),
        Vector3(sign*0.814,1.676,-0.177),
        Vector3(sign*0.814,2.071,-0.177),
        Vector3(sign*0.692,2.071,-0.177)]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _quad(st,start[0],start[3],start[2],start[1])
    _quad(st,end[0],end[1],end[2],end[3])
    for edge in range(4):
        var next:int=(edge+1)%4
        _quad(st,start[edge],start[next],end[next],end[edge])
    return st.commit() as ArrayMesh

# Helical spring wire, not a painted tube or decal: each single coil turn
# is a hollow-around-its-axis contiguous volume. 5 turns x 42 longitudinal
# slices with 7 circular cross-section slices gives 588 real triangles.
# Created only at hero LOD13; mobile LOD8 gets a one-piece steel sleeve.
static func _coil_mesh(height:float,radius:float,wire:float,
        turns:int,segments:int,sides:int)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(segments):
        var t0:float=float(i)/float(segments)
        var t1:float=float(i+1)/float(segments)
        var theta0:float=TAU*float(turns)*t0
        var theta1:float=TAU*float(turns)*t1
        var center0:=Vector3(
            radius*cos(theta0),-height*0.5+height*t0,
            radius*sin(theta0))
        var center1:=Vector3(
            radius*cos(theta1),-height*0.5+height*t1,
            radius*sin(theta1))
        for j in range(sides):
            var angle0:float=TAU*float(j)/float(sides)
            var angle1:float=TAU*float(j+1)/float(sides)
            var radial0:=Vector3(cos(theta0),0,sin(theta0))
            var radial1:=Vector3(cos(theta1),0,sin(theta1))
            var p00:Vector3=center0+wire*(
                radial0*cos(angle0)+Vector3.UP*sin(angle0))
            var p01:Vector3=center0+wire*(
                radial0*cos(angle1)+Vector3.UP*sin(angle1))
            var p10:Vector3=center1+wire*(
                radial1*cos(angle0)+Vector3.UP*sin(angle0))
            var p11:Vector3=center1+wire*(
                radial1*cos(angle1)+Vector3.UP*sin(angle1))
            _quad(st,p00,p10,p11,p01)
    return st.commit() as ArrayMesh

static func apply(root:Node3D,paint:Color)->bool:
    if root==null or not bool(root.get_meta(V7.FLAG,false)) or (
            not bool(root.get_meta(V6.FLAG,false))) or (
            not V1.has_model(root)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var hull:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if hull==null or wheels==null or wheels.get_child_count()!=6 or (
            root.find_child(ASSEMBLY,true,false)!=null):
        return false
    var high:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var armor_mat:=_mat("#87969e",0.53,0.50)
    var satin:=_mat("#adb9bb",0.70,0.38)
    var edge:=_mat("#c0c9c8",0.82,0.29)
    var dark:=_mat("#3b484f",0.38,0.70)
    var deep:=_mat("#253238",0.12,0.88)
    var spring_steel:=_mat("#b8c4c5",0.76,0.35)
    var rubber:=_mat("#242a2e",0.02,0.89)
    var faction:=StandardMaterial3D.new()
    faction.albedo_color=paint
    faction.metallic=0.38
    faction.roughness=0.44
    faction.clearcoat_enabled=true
    faction.clearcoat=0.29
    faction.clearcoat_roughness=0.29

    var group:=Node3D.new()
    group.name=ASSEMBLY
    hull.add_child(group)
    var connecting:=Node3D.new()
    connecting.name=ARMOR
    group.add_child(connecting)
    var surface:=Node3D.new()
    surface.name=METAL
    group.add_child(surface)
    var suspension:=Node3D.new()
    suspension.name=SUSPENSION
    group.add_child(suspension)

    # 3D transitional bridge hides the hard line between the short driver
    # cab and taller electronic enclosure but never conceals any V6 windows.
    for side in [-1,1]:
        var s:float=float(side)
        var name_id:String=str(side)
        var bridge:=_transition_mesh(side)
        if bridge==null or bridge.get_faces().size()!=36:
            return false
        _mesh(connecting,"G15_V8_ClosedCabShelterBridge_"+name_id,
            bridge,armor_mat)
        _rod(connecting,"G15_V8_ContinuousShoulderEdge_"+name_id,
            Vector3(s*0.724,1.766,-0.675),
            Vector3(s*0.822,2.081,-0.186),0.020,satin,10 if high else 8)
        _rod(connecting,"G15_V8_CabShelterLowerSeal_"+name_id,
            Vector3(s*0.723,1.626,-0.66),
            Vector3(s*0.823,1.687,-0.18),0.016,dark,10)
        # Single lower protection belt runs continuously below all the
        # individual armor panels, with actual beveled front/rear end caps.
        # It remains under y=1.13 so that existing faction rails stay clear.
        _box(connecting,"G15_V8_ContinuousSideBelt_"+name_id,
            Vector3(s*0.845,1.054,0.47),
            Vector3(0.065,0.066,1.61),satin)
        for z in [-0.32,1.26]:
            _box(connecting,
                "G15_V8_ArmoredBeltEnd_%s_%s" % [name_id,str(z)],
                Vector3(s*0.846,1.053,z),
                Vector3(0.086,0.098,0.06),dark)
        # Thin physical variation in brushed steel creates multiple
        # specular edges, without adding costly noise textures or light maps.
        for n in range(4 if high else 2):
            var z:float=-0.20+float(n)*(0.40 if high else 0.80)
            _box(surface,"G15_V8_ShelterSatinEdge_%s_%d" % [name_id,n],
                Vector3(s*0.864,1.825,z),
                Vector3(0.017,0.083,0.018),edge)
        _box(surface,"G15_V8_RoofCornerHighlight_"+name_id,
            Vector3(s*0.783,2.202,0.935),
            Vector3(0.039,0.018,0.980),edge)
        _box(surface,"G15_V8_LowerDiffuserUnderPaint_"+name_id,
            Vector3(s*0.867,1.089,0.330),
            Vector3(0.019,0.025,0.692),deep)
        _box(surface,"G15_V8_FactionServicePip_"+name_id,
            Vector3(s*0.879,1.530,0.80),
            Vector3(0.012,0.045,0.160),faction)
        if high:
            for bolt in range(4):
                _box(surface,"G15_V8_EdgeLockBolt_%s_%d" % [name_id,bolt],
                    Vector3(s*0.871,1.84,-0.19+0.37*float(bolt)),
                    Vector3(0.019,0.027,0.030),dark)
            _box(surface,"G15_V8_CabApertureStriker_"+name_id,
                Vector3(s*0.860,1.380,-0.912),
                Vector3(0.021,0.093,0.049),edge)

    # Physical coil-over springs adjacent to all three original wheel axles.
    # Each spring is fixed to the V7 stationary suspension rail; it does not
    # rotate the original wheel pivots or impose new battle physics.
    for axle in range(3):
        var z:float=float(V7.AXLES[axle])
        for side in [-1,1]:
            var s:float=float(side)
            var suffix:String="%s_%d" % [str(side),axle]
            var anchor_a:=Vector3(s*0.715,0.662,z+0.220)
            var anchor_b:=Vector3(s*0.787,0.365,z+0.042)
            var direction:Vector3=anchor_b-anchor_a
            var axis_len:float=direction.length()
            _rod(suspension,"G15_V8_ShockChromedCore_"+suffix,
                anchor_a,anchor_b,0.016,spring_steel,10)
            for tip in range(2):
                var point:Vector3=anchor_a if tip==0 else anchor_b
                var cap:=_box(suspension,
                    "G15_V8_SuspensionMount_%s_%d" % [suffix,tip],
                    point,Vector3(0.083,0.064,0.083),dark)
                cap.rotation_degrees.x=12.0
            if high:
                var wiremesh:=_coil_mesh(axis_len*0.85,0.050,0.012,5,45,7)
                if wiremesh==null or wiremesh.get_faces().size()!=45*7*6:
                    return false
                var spring:=_mesh(suspension,
                    "G15_V8_RealCoilSpring_"+suffix,
                    wiremesh,spring_steel,(anchor_a+anchor_b)*0.5)
                spring.quaternion=Quaternion(Vector3.UP,direction.normalized())
                _rod(suspension,"G15_V8_CoilSupportPlate_"+suffix,
                    anchor_a+direction*0.07,
                    anchor_a+direction*0.12,0.063,dark,10)
            else:
                _rod(suspension,"G15_V8_MobileSpringSleeve_"+suffix,
                    anchor_a+direction*0.30,
                    anchor_a+direction*0.70,0.044,satin,8)
            # Oblique diagonal control arm gives the six-wheel independent
            # geometry a distinct suspended profile under isometric camera.
            _rod(suspension,"G15_V8_LowerControlArm_"+suffix,
                Vector3(s*0.49,0.405,z-0.15),
                Vector3(s*0.77,0.366,z+0.05),0.032,dark,10 if high else 8)
            if high:
                _rod(suspension,"G15_V8_UpperControlArm_"+suffix,
                    Vector3(s*0.50,0.57,z+0.02),
                    Vector3(s*0.71,0.61,z+0.21),0.026,satin,10)
                # Close-view readability fix: the inner springs are physically
                # accurate but entirely screened by the rubber tires.
                # Expose a SECOND shock mount in the inter-wheel gap, *outside*
                # each tire's radial shadow, with two chassis-connected rods.
                # These are genuine compact auxiliary dampers and are never
                # made children of the rotating wheel or floating objects.
                var out_top:=Vector3(s*0.995,0.812,z+0.428)
                var out_bottom:=Vector3(s*1.025,0.486,z+0.442)
                var out_dir:Vector3=out_bottom-out_top
                var gap_coil:=_coil_mesh(
                    out_dir.length()*0.80,0.061,0.012,4,36,8)
                if gap_coil==null or gap_coil.get_faces().size()!=36*8*6:
                    return false
                var gap_spring:=_mesh(suspension,
                    "G15_V8_VisibleGapCoil_"+suffix,
                    gap_coil,spring_steel,(out_top+out_bottom)*0.5)
                gap_spring.quaternion=Quaternion(
                    Vector3.UP,out_dir.normalized())
                _rod(suspension,"G15_V8_AuxiliaryDamperCore_"+suffix,
                    out_top,out_bottom,0.018,dark,10)
                _rod(suspension,"G15_V8_GapUpperBrace_"+suffix,
                    Vector3(s*0.790,0.768,z+0.286),
                    out_top,0.025,satin,10)
                _rod(suspension,"G15_V8_GapLowerBrace_"+suffix,
                    Vector3(s*0.785,0.406,z+0.295),
                    out_bottom,0.026,dark,10)
                _box(suspension,"G15_V8_GapCoilEndRetainer_"+suffix,
                    out_top,Vector3(0.118,0.038,0.116),deep)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v8_solid_bridge_triangles",12)
    root.set_meta("tarvoka_g15_v8_coils",12 if high else 0)
    root.set_meta("tarvoka_g15_v8_interwheel_coils",6 if high else 0)
    root.set_meta("tarvoka_g15_v8_suspension_pivots_untouched",true)
    root.set_meta("tarvoka_g15_v8_all_visual_only",true)
    root.set_meta("tarvoka_g15_v8_android_lod",not high)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var model:=root.find_child(ASSEMBLY,true,false) as Node3D
    if model==null:
        return false
    model.visible=enabled
    root.set_meta("tarvoka_g15_v8_preview_enabled",enabled)
    return true
