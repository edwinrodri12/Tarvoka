extends RefCounted
class_name TarvokaG13FrontLightingV23

# G13 V23: two genuine recessed 3D headlight assemblies on the original 4x4.
# Each assembly is a closed metal bezel with a hollow opening plus a separate
# beveled optical solid. V16's original batched lamps remain as backing lights;
# no launchers, combat behavior, collision, new gameplay stats, or LOD8 cost.
const FLAG := "tarvoka_g13_v23_recessed_headlights"
const RIM := "G13_V23_HeadlightBezel_%d"
const LENS := "G13_V23_RecessedOptic_%d"
const PARTS := 4

static func _coat(hex:String,metal:float,rough:float,glow:bool=false)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color(hex)
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    if glow:
        mat.emission_enabled=true
        mat.emission=Color("#93b8b5")
        mat.emission_energy_multiplier=0.18
    return mat

static func _outline(hx:float,hy:float,cut:float,z:float)->Array[Vector3]:
    # Chamfered rectangle in consistent CCW XY order.
    return [
        Vector3(-hx+cut,-hy,z),Vector3(hx-cut,-hy,z),
        Vector3(hx,-hy+cut,z),Vector3(hx,hy-cut,z),
        Vector3(hx-cut,hy,z),Vector3(-hx+cut,hy,z),
        Vector3(-hx,hy-cut,z),Vector3(-hx,-hy+cut,z)
    ]

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    # The authored vertex winding and the normal must agree (no flipped
    # polygon lighting, including on bevels).
    var n:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(b)
    st.set_normal(n)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3)->void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _bezel()->ArrayMesh:
    # Open front and rear: unlike a BoxMesh, the center is a real hole.
    # Local -Z points forward, toward the camera at the vehicle's nose.
    var ofront:=_outline(0.082,0.066,0.015,-0.048)
    var ifront:=_outline(0.057,0.042,0.012,-0.048)
    var oback:=_outline(0.082,0.066,0.015,0.011)
    var iback:=_outline(0.057,0.042,0.012,0.011)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(8):
        var j:int=(i+1)%8
        _quad(st,ofront[i],ifront[i],ifront[j],ofront[j]) # front ring
        _quad(st,ofront[i],ofront[j],oback[j],oback[i]) # outside
        _quad(st,ifront[i],iback[i],iback[j],ifront[j]) # aperture
        _quad(st,oback[i],oback[j],iback[j],iback[i]) # rear ring
    return st.commit()

static func _optic()->ArrayMesh:
    # Real closed lens at -0.040 to -0.019: 8 mm behind the frontal
    # metal lip, yet forward of the original V16 lamp face at -0.016.
    var face:=_outline(0.055,0.040,0.014,-0.040)
    var back:=_outline(0.055,0.040,0.014,-0.019)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center_front:=Vector3(0,0,-0.040)
    var center_back:=Vector3(0,0,-0.019)
    for i in range(8):
        var j:int=(i+1)%8
        _tri(st,center_front,face[j],face[i])
        _quad(st,face[i],face[j],back[j],back[i])
        _tri(st,center_back,back[i],back[j])
    return st.commit()

static func _piece(parent:Node3D,label:String,geometry:Mesh,
        material:Material,at:Vector3)->void:
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=geometry
    part.material_override=material
    part.position=at
    parent.add_child(part)

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or not bool(
            root.get_meta("tarvoka_g13_v22_underbody_closed_service_finish",false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var originals:Array[MeshInstance3D]=[]
    if hull==null or root.find_child(
            "G13_V16_Headlights",true,false)==null:
        return false
    # Fully validate the inherited light anchors before adding anything.
    for side in [-1,1]:
        var lamp:=hull.find_child("G13_Lamp_%d" % side,
            false,false) as MeshInstance3D
        if lamp==null or not lamp.mesh is BoxMesh or (
                not lamp.position.is_equal_approx(
                    Vector3(float(side)*0.50,0.85,-1.245))):
            return false
        if hull.find_child(RIM % side,false,false)!=null or (
                hull.find_child(LENS % side,false,false)!=null):
            return false
        originals.append(lamp)
    var metal:=_coat("#899a9e",0.62,0.46)
    var optical:=_coat("#bed6d6",0.09,0.31,true)
    var rim_geometry:=_bezel()
    var lens_geometry:=_optic()
    for i in range(2):
        var side:int=-1 if i==0 else 1
        var anchor:Vector3=originals[i].position
        _piece(hull,RIM % side,rim_geometry,metal,anchor)
        _piece(hull,LENS % side,lens_geometry,optical,anchor)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v23_sculpt_parts",PARTS)
    root.set_meta("tarvoka_g13_v23_lamp_clear_openings",2)
    root.set_meta("tarvoka_g13_v23_art_only",true)
    root.set_meta("tarvoka_g13_v23_weapon_identity",
        "twin_autocannon_no_missiles")
    return true

static func compare_v22(root:Node3D,show_v22:bool)->bool:
    # Visual QA only: V16 backing lamps stay in place, just hide V23
    # frames and optics to render the authentic V22 reference.
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var parts:Array[Node3D]=[]
    for side in [-1,1]:
        for label in [RIM % side,LENS % side]:
            var part:=root.find_child(label,true,false) as Node3D
            if part==null:
                return false
            parts.append(part)
    for part in parts:
        part.visible=not show_v22
    return true
