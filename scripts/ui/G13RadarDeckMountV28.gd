extends RefCounted
class_name TarvokaG13RadarDeckMountV28

# G13 V28: correct the floating rear radar support in the mobile 3D LOD8.
# Sculpt the EXISTING mast node into a closed, 12-sided stepped armored foot,
# joining it to the top of the rear engine deck. Position the mast aft\n# of the turret armor sweep, using a longer existing engine cover. No lights,
# missiles, collider, attack stats or gameplay commands. Approved LOD13 stays.
const FLAG:="tarvoka_g13_v28_radar_deck_mounted"
const SOURCE:="tarvoka_g13_v28_original_and_deck_meshes"
const MAST:="G13_RadarMast"
const COVER:="G13_EngineCover"
const PIVOT:="G13_RadarAzimut"
const SEGMENTS:=12
const RADAR_DECK_Z:=1.135
const COVER_DEPTH:=1.15
const MIN_TURRET_CLEARANCE:=0.025
const TRIANGLES:=96
const PROFILE:Array[Vector2]=[
    Vector2(-0.640,0.125),
    Vector2(-0.520,0.125),
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
            not cover.position.is_equal_approx(Vector3(0,1.03,0.70))) or (
            not radar.position.is_equal_approx(Vector3(0,1.36,0.89))) or (
            not is_equal_approx((cover.mesh as BoxMesh).size.z,0.67)):
        return false
    # Sweep-independent radius bound for the low-poly turret shell and
    # its original targeting optic (the two gun barrels are evaluated
    # separately). At all turret headings, each armor corner lies inside
    # this circle around the yaw axis.
    var turret:=root.find_child("G13_TorretaAzimut",true,false) as Node3D
    if turret==null:
        return false
    var armor_radius:float=0.0
    for child in turret.get_children():
        if not child is MeshInstance3D:
            continue
        var part:=child as MeshInstance3D
        if part.mesh==null:
            return false
        if part.mesh is CylinderMesh:
            # The turret ring is genuinely circular: an AABB square would
            # overestimate its radius by sqrt(2) and reject valid clearance.
            var ring:=part.mesh as CylinderMesh
            var ring_radius:float=0.0
            ring_radius=maxf(ring.bottom_radius,ring.top_radius)
            armor_radius=maxf(armor_radius,
                Vector2(part.position.x,part.position.z).length()+ring_radius)
            continue
        var bounds:AABB=part.mesh.get_aabb()
        for xx in [bounds.position.x,bounds.end.x]:
            for zz in [bounds.position.z,bounds.end.z]:
                var corner:Vector3=part.transform*Vector3(xx,0,zz)
                armor_radius=maxf(armor_radius,Vector2(corner.x,corner.z).length())
    var proposed_distance:float=RADAR_DECK_Z-turret.position.z
    var margin:float=proposed_distance-armor_radius-PROFILE[0].y
    if margin<MIN_TURRET_CLEARANCE:
        return false
    # One shared BoxMesh keeps the foot inside the physical rear deck:
    # extend its depth, not the number of meshes or render objects.
    var extended_cover:BoxMesh=(cover.mesh as BoxMesh).duplicate(true)
    extended_cover.size.z=COVER_DEPTH
    if cover.position.z+COVER_DEPTH*0.5<RADAR_DECK_Z+PROFILE[0].y:
        return false

    # Radar pivot is offset to the rear (z=1.135), leaving space for the
    # rotating turret housing. The ground-facing base remains centered over
    # the extended rear deck. Only existing pivot + existing deck are edited.
    # Radar pivot lies at (0,1.36,z) on the same G13 root as the
    # 1.03m rear cover, 0.18m thick. The 3D foot penetrates the deck
    # 25mm, avoiding the visible air gap of the V27 cylinder base.
    var cover_top:float=cover.position.y+(
        cover.mesh as BoxMesh).size.y*0.5
    var foot_bottom:float=radar.position.y+mast.position.y+PROFILE[0].x
    if absf((cover_top-foot_bottom)-FOOT_DECK_PENETRATION)>0.003 or (
            PROFILE[0].y>0.130):
        return false
    var sculpt:ArrayMesh=_sculpt()
    if sculpt==null or sculpt.get_surface_count()!=1 or (
            sculpt.get_faces().size()!=TRIANGLES*3):
        return false
    var old_mast:Mesh=mast.mesh
    var old_cover:Mesh=cover.mesh
    var old_pivot:Vector3=radar.position
    mast.mesh=sculpt
    cover.mesh=extended_cover
    radar.position=Vector3(0,radar.position.y,RADAR_DECK_Z)
    root.set_meta(SOURCE,{
        "old":{"mast":old_mast,"cover":old_cover,"radar_pos":old_pivot},
        "new":{"mast":sculpt,"cover":extended_cover,
            "radar_pos":radar.position}
    })
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v28_draw_nodes_added",NEW_MESH_INSTANCES)
    root.set_meta("tarvoka_g13_v28_mast_triangles",TRIANGLES)
    root.set_meta("tarvoka_g13_v28_deck_overlap_m",
        cover_top-foot_bottom)
    root.set_meta("tarvoka_g13_v28_armor_clearance_m",margin)
    root.set_meta("tarvoka_g13_v28_deck_depth_m",COVER_DEPTH)
    root.set_meta("tarvoka_g13_v28_art_only",true)
    return true

static func show_v27_reference(root:Node3D,old:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var mast:=root.find_child(MAST,true,false) as MeshInstance3D
    var cover:=root.find_child(COVER,true,false) as MeshInstance3D
    var radar:=root.find_child(PIVOT,true,false) as Node3D
    var options:Dictionary=root.get_meta(SOURCE,{})
    if mast==null or cover==null or radar==null or (
            not options.has("old") or not options.has("new")):
        return false
    var resources:Dictionary=options["old"] if old else options["new"]
    if not resources.has("mast") or not resources.has("cover") or (
            not resources.has("radar_pos")):
        return false
    mast.mesh=resources["mast"]
    cover.mesh=resources["cover"]
    radar.position=resources["radar_pos"]
    root.set_meta("tarvoka_g13_v28_reference_v27",old)
    return true
