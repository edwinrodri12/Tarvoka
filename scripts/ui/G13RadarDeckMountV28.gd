extends RefCounted
class_name TarvokaG13RadarDeckMountV28

# G13 V28: correct the floating rear radar support in the mobile 3D LOD8.
# Sculpt the EXISTING mast node into a closed, 12-sided stepped armored foot,
# joining it to the top of the rear engine deck. No new render nodes, lights,
# missiles, collider, attack stats or gameplay commands. Approved LOD13 stays.
const FLAG:="tarvoka_g13_v28_radar_deck_mounted"
const SOURCE:="tarvoka_g13_v28_original_and_deck_meshes"
const MAST:="G13_RadarMast"
const COVER:="G13_EngineCover"
const PIVOT:="G13_RadarAzimut"
const SEGMENTS:=12
const TRIANGLES:=96
const PROFILE:Array[Vector2]=[
    Vector2(-0.640,0.145),
    Vector2(-0.520,0.145),
    Vector2(-0.465,0.108),
    Vector2(0.350,0.086)
]
const FOOT_DECK_PENETRATION:=0.025
const NEW_MESH_INSTANCES:=0

static func _point(y:float,radius:float,i:int)->Vector3:
    var angle:float=TAU*float(i)/float(SEGMENTS)
    return Vector3(cos(angle)*radius,y,sin(angle)*radius)

static func _triangle(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    # Identical exterior winding to the closed V10 armor sculpture;
    # append flat normals to give the stepped support genuine beveled edges.
    var normal:Vector3=(b-a).cross(c-a).normalized()
    surface.set_normal(normal)
    surface.add_vertex(a)
    surface.set_normal(normal)
    surface.add_vertex(c)
    surface.set_normal(normal)
    surface.add_vertex(b)

static func _sculpt()->ArrayMesh:
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(PROFILE.size()-1):
        var low:Vector2=PROFILE[layer]
        var high:Vector2=PROFILE[layer+1]
        for i in range(SEGMENTS):
            var j:int=(i+1)%SEGMENTS
            var a:Vector3=_point(low.x,low.y,i)
            var b:Vector3=_point(low.x,low.y,j)
            var c:Vector3=_point(high.x,high.y,j)
            var d:Vector3=_point(high.x,high.y,i)
            _triangle(surface,a,c,b)
            _triangle(surface,a,d,c)
    var lower:Vector2=PROFILE[0]
    var upper:Vector2=PROFILE[PROFILE.size()-1]
    for i in range(SEGMENTS):
        var j:int=(i+1)%SEGMENTS
        _triangle(surface,Vector3(0,lower.x,0),
            _point(lower.x,lower.y,i),_point(lower.x,lower.y,j))
        _triangle(surface,Vector3(0,upper.x,0),
            _point(upper.x,upper.y,j),_point(upper.x,upper.y,i))
    return surface.commit()

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta(
                "tarvoka_g13_v27_elevated_mobile_radar",false))) or (
            bool(root.get_meta("tarvoka_g13_v1_high_detail",true))):
        return false
    var radar:=root.find_child(PIVOT,true,false) as Node3D
    var mast:=root.find_child(MAST,true,false) as MeshInstance3D
    var cover:=root.find_child(COVER,true,false) as MeshInstance3D
    if radar==null or mast==null or cover==null or (
            mast.get_parent()!=radar) or (
            not mast.mesh is CylinderMesh) or (
            not cover.mesh is BoxMesh):
        return false
    var current:=mast.mesh as CylinderMesh
    if not is_equal_approx(current.height,0.70) or (
            not is_equal_approx(current.top_radius,0.086)) or (
            not mast.position.is_equal_approx(Vector3(0,0.375,0))) or (
            not cover.position.is_equal_approx(Vector3(0,1.03,0.70))):
        return false

    # Radar pivot lies at (0,1.36,0.89) on the same G13 root as the
    # 1.03m rear cover, 0.18m thick. The 3D foot penetrates the deck
    # 25mm, avoiding the visible air gap of the V27 cylinder base.
    var cover_top:float=cover.position.y+(
        cover.mesh as BoxMesh).size.y*0.5
    var foot_bottom:float=radar.position.y+mast.position.y+PROFILE[0].x
    if absf((cover_top-foot_bottom)-FOOT_DECK_PENETRATION)>0.003 or (
            absf(radar.position.z-0.89)>0.001) or (
            PROFILE[0].y>0.148):
        return false
    var sculpt:ArrayMesh=_sculpt()
    if sculpt==null or sculpt.get_surface_count()!=1 or (
            sculpt.get_faces().size()!=TRIANGLES*3):
        return false
    var original:Mesh=mast.mesh
    mast.mesh=sculpt
    root.set_meta(SOURCE,{"old":original,"new":sculpt})
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v28_draw_nodes_added",NEW_MESH_INSTANCES)
    root.set_meta("tarvoka_g13_v28_mast_triangles",TRIANGLES)
    root.set_meta("tarvoka_g13_v28_deck_overlap_m",
        cover_top-foot_bottom)
    root.set_meta("tarvoka_g13_v28_art_only",true)
    return true

static func show_v27_reference(root:Node3D,old:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var mast:=root.find_child(MAST,true,false) as MeshInstance3D
    var options:Dictionary=root.get_meta(SOURCE,{})
    if mast==null or not options.has("old") or not options.has("new"):
        return false
    mast.mesh=options["old"] if old else options["new"]
    root.set_meta("tarvoka_g13_v28_reference_v27",old)
    return true
