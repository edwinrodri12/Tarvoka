extends RefCounted
class_name TarvokaG13ArmoredIntakeV24

# G13 V24: a shallow, physically connected, real 3D armored air intake.
# Replaces the visually empty central slope with a framed open aperture,
# inset dark grille backplate, and four individually closed angled blades
# merged into a single surface. Sits on the exact 23-degree V1 glacis
# plane, never intersects V23 headlights or four-wheel suspension.
# No missile pods, functional weapons, air mechanics, collisions or LOD8.
const FLAG:="tarvoka_g13_v24_front_armored_intake"
const PIVOT:="G13_V24_FrontIntakeSlopeAnchor"
const BEZEL:="G13_V24_IntakeClosedBezel"
const BACK:="G13_V24_RecessedDarkBacking"
const LOUVRES:="G13_V24_ClosedAngledLouvers"
const MESH_PARTS:=3
const SLAT_COUNT:=4
const CENTER_Y:=-0.12

static func _material(hex:String,metal:float,rough:float)->StandardMaterial3D:
    var out:=StandardMaterial3D.new()
    out.albedo_color=Color(hex)
    out.metallic=metal
    out.roughness=rough
    out.cull_mode=BaseMaterial3D.CULL_DISABLED
    return out

static func _outline(z:float,hw:float,hh:float,cut:float)->Array[Vector3]:
    return [
        Vector3(-hw+cut,CENTER_Y-hh,z),
        Vector3(hw-cut,CENTER_Y-hh,z),
        Vector3(hw,CENTER_Y-hh+cut,z),
        Vector3(hw,CENTER_Y+hh-cut,z),
        Vector3(hw-cut,CENTER_Y+hh,z),
        Vector3(-hw+cut,CENTER_Y+hh,z),
        Vector3(-hw,CENTER_Y+hh-cut,z),
        Vector3(-hw,CENTER_Y-hh+cut,z)
    ]

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3,d:Vector3)->void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _open_armored_frame()->ArrayMesh:
    # A true THROUGH-HOLE in front and rear face; not painted 2D grille.
    # Outer and inner profiles both have eight beveled corners.
    # Rear face is 0.009m INTO the sloped armor, fixing the frame to hull.
    var outside_front:=_outline(-0.315,0.322,0.088,0.024)
    var inside_front:=_outline(-0.315,0.270,0.058,0.014)
    var outside_rear:=_outline(-0.266,0.322,0.088,0.024)
    var inside_rear:=_outline(-0.266,0.270,0.058,0.014)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(8):
        var j:int=(i+1)%8
        _quad(st,outside_front[i],inside_front[i],
            inside_front[j],outside_front[j])
        _quad(st,outside_front[i],outside_front[j],
            outside_rear[j],outside_rear[i])
        _quad(st,inside_front[i],inside_rear[i],
            inside_rear[j],inside_front[j])
        _quad(st,outside_rear[i],outside_rear[j],
            inside_rear[j],inside_rear[i])
    return st.commit()

static func _slat(st:SurfaceTool,mid_y:float)->void:
    # Each 3D louvre has six solid faces, not translucent fake rectangles.
    # Upper edge tilts forward 5mm to create readable shadow and volume.
    # Four louvres share one ArrayMesh and therefore one GPU material draw.
    var hw:float=0.255
    var h:float=0.008
    var front_bottom:float=-0.297
    var front_top:float=-0.302
    var rear_bottom:float=-0.280
    var rear_top:float=-0.282
    var a:=Vector3(-hw,mid_y-h,front_bottom)
    var b:=Vector3(hw,mid_y-h,front_bottom)
    var c:=Vector3(hw,mid_y+h,front_top)
    var d:=Vector3(-hw,mid_y+h,front_top)
    var e:=Vector3(-hw,mid_y-h,rear_bottom)
    var f:=Vector3(hw,mid_y-h,rear_bottom)
    var g:=Vector3(hw,mid_y+h,rear_top)
    var k:=Vector3(-hw,mid_y+h,rear_top)
    _quad(st,a,d,c,b) # front visible toward vehicle nose -Z
    _quad(st,e,f,g,k) # rear
    _quad(st,d,k,g,c) # upper lip
    _quad(st,a,b,f,e) # lower lip
    _quad(st,a,e,k,d) # left end
    _quad(st,b,c,g,f) # right end

static func _louvre_mesh()->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(SLAT_COUNT):
        _slat(st,-0.165+float(i)*0.030)
    return st.commit()

static func _part(parent:Node3D,label:String,geometry:Mesh,coat:Material,
        at:Vector3=Vector3.ZERO)->MeshInstance3D:
    var instance:=MeshInstance3D.new()
    instance.name=label
    instance.mesh=geometry
    instance.material_override=coat
    instance.position=at
    parent.add_child(instance)
    return instance

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or not bool(
            root.get_meta("tarvoka_g13_v23_recessed_headlights",false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",
        true,false) as Node3D
    var glacis:=root.find_child("G13_SlopedGlacis",
        true,false) as MeshInstance3D
    if hull==null or glacis==null or glacis.get_parent()!=hull or (
            not glacis.mesh is BoxMesh):
        return false
    if not glacis.position.is_equal_approx(
            Vector3(0,0.94,-1.03)) or (
            not glacis.rotation_degrees.is_equal_approx(
                Vector3(-23,0,0))):
        return false
    if hull.find_child(PIVOT,false,false)!=null:
        return false
    for side in [-1,1]:
        var optic:=hull.find_child("G13_V23_RecessedOptic_%d" % side,
            false,false) as MeshInstance3D
        if optic==null or not optic.visible:
            return false
    # All dependencies prevalidated: install once, entirely on original hull.
    var pivot:=Node3D.new()
    pivot.name=PIVOT
    pivot.position=glacis.position
    pivot.rotation=glacis.rotation
    hull.add_child(pivot)
    var rim:=_material("#77858a",0.46,0.66)
    var inset:=_material("#202b31",0.16,0.93)
    var slats:=_material("#56656b",0.43,0.71)
    _part(pivot,BEZEL,_open_armored_frame(),rim)
    var backing:=BoxMesh.new()
    backing.size=Vector3(0.54,0.111,0.010)
    _part(pivot,BACK,backing,inset,Vector3(0,CENTER_Y,-0.279))
    _part(pivot,LOUVRES,_louvre_mesh(),slats)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v24_geometry_parts",MESH_PARTS)
    root.set_meta("tarvoka_g13_v24_louvres",SLAT_COUNT)
    root.set_meta("tarvoka_g13_v24_visual_only",true)
    root.set_meta("tarvoka_g13_v24_weapon_identity",
        "twin_autocannon_no_missiles")
    return true

static func show_v23_reference(root:Node3D,old:bool)->bool:
    # Genuine single-mesh comparison: no clone, no change in camera, pose,
    # paint or other V23 details. Toggle the entire 3D intake as one group.
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var pivot:=root.find_child(PIVOT,true,false) as Node3D
    if pivot==null:
        return false
    for label in [BEZEL,BACK,LOUVRES]:
        var detail:=pivot.find_child(label,false,false) as MeshInstance3D
        if detail==null:
            return false
    pivot.visible=not old
    return true
