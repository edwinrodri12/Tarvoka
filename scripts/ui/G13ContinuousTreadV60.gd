extends RefCounted
class_name TarvokaG13ContinuousTreadV60

# G13 V60 ART ONLY: repair the actual visible difference to P06 Bastion.
# V59 has 160 real lugs but clustered around eight V7 pad origins.
# Integrate a uniformly spaced 40-sector x 4-row / 160-lug continuous
# tread into the ORIGINAL rotating 4-wheel MultiMesh, not screenshot art.
# Remove tall V59 sidewall teeth in favor of low-profile molded ribs.
# Hero: 64-sector carcass + 160 tapered/closed lugs per wheel.
# Android: 32-sector carcass + 48 lugs per wheel.
# Zero additional nodes, original 4 wheel pivots, faction, glass, rig,
# twin cannons and all combat code unchanged. 1 LESS active GPU batch.
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const FLAG="tarvoka_g13_v60_continuous_bastion_grade_molded_tread"
const SAVED="tarvoka_g13_v60_original_rotating_tire_and_pad_visibility"
const TIRES=V59.TIRES
const PADS=V59.TREAD
const HERO_SECTORS=40
const HERO_ROWS=4
const MOBILE_SECTORS=24
const MOBILE_ROWS=2
const HERO_LUGS=HERO_SECTORS*HERO_ROWS
const MOBILE_LUGS=MOBILE_SECTORS*MOBILE_ROWS
const LUG_RADIUS=0.332
const LUG_BASE_RADIUS=0.315
const INNER_FENDER=V59.FENDER_INNER_RADIUS
const SIDEWALL_PROJECTION=0.007
const SIDE_RIBS_HERO=28
const SIDE_RIBS_MOBILE=14
const DRAW_NODES_ADDED=0
static var _hero_mesh:ArrayMesh
static var _tactical_mesh:ArrayMesh

static func _point(axial:float,radius:float,angle:float)->Vector3:
    return Vector3(radius*cos(angle),axial,radius*sin(angle))

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3,d:Vector3)->void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _four(axial:float,width:float,
        middle:float,half_arc:float,radius:float,slant:float
        )->Array[Vector3]:
    return [
        _point(axial-width*0.5,radius,middle-half_arc-slant),
        _point(axial+width*0.5,radius,middle-half_arc+slant),
        _point(axial+width*0.5,radius,middle+half_arc+slant),
        _point(axial-width*0.5,radius,middle+half_arc-slant)
    ]

static func _molded_lug(st:SurfaceTool,axial:float,
        middle:float,span:float,slant:float,width:float)->void:
    # Continuous true wheel-radial geometry: the root is 3 mm INSIDE
    # the V59 carcass; the top is beveled and 14 mm above the casing.
    # No rigid cubic pillars or detached circumferential pad clusters.
    var ring0:Array[Vector3]=_four(axial,width,
        middle,span*0.430,LUG_BASE_RADIUS,slant)
    var ring1:Array[Vector3]=_four(axial,width*0.92,
        middle,span*0.405,0.325,slant*0.86)
    var crown:Array[Vector3]=_four(axial,width*0.80,
        middle,span*0.337,LUG_RADIUS,slant*0.70)
    _quad(st,crown[0],crown[1],crown[2],crown[3])
    _quad(st,ring0[3],ring0[2],ring0[1],ring0[0])
    for edge in range(4):
        var next:int=(edge+1)%4
        _quad(st,ring0[edge],ring0[next],
            ring1[next],ring1[edge])
        _quad(st,ring1[edge],ring1[next],
            crown[next],crown[edge])

static func _soft_sidewall(st:SurfaceTool,high:bool)->void:
    # V59 rib height measured ~2.5 cm in side profile: it produced
    # angular protrusions at normal gameplay zoom. Real rubber relief
    # should be 4-7 mm and blend into the closed casing shoulder.
    var count:int=SIDE_RIBS_HERO if high else SIDE_RIBS_MOBILE
    for side in [-1,1]:
        var sign:float=float(side)
        for i in range(count):
            var center:float=TAU*(float(i)+0.5)/float(count)
            var half:float=TAU/float(count)*0.190
            var root:Array[Vector3]=[
                _point(sign*0.114,0.263,center-half),
                _point(sign*0.101,0.289,center-half+0.015),
                _point(sign*0.101,0.289,center+half+0.015),
                _point(sign*0.114,0.263,center+half)
            ]
            var raised:Array[Vector3]=[
                _point(sign*0.121,0.263,center-half),
                _point(sign*0.108,0.289,center-half+0.015),
                _point(sign*0.108,0.289,center+half+0.015),
                _point(sign*0.121,0.263,center+half)
            ]
            _quad(st,raised[0],raised[1],raised[2],raised[3])
            _quad(st,root[3],root[2],root[1],root[0])
            for edge in range(4):
                var next:int=(edge+1)%4
                _quad(st,root[edge],root[next],
                    raised[next],raised[edge])

static func _build_mesh(high:bool)->ArrayMesh:
    if high and _hero_mesh!=null:
        return _hero_mesh
    if not high and _tactical_mesh!=null:
        return _tactical_mesh
    # Retain V59's validated 64-/32-section CLOSED tire sidewall and
    # bead contour, but discard its long rib spikes. No new wheel node.
    var source:ArrayMesh=V59._tire_mesh(high)
    if source==null or source.get_surface_count()!=1:
        return null
    var arrays:Array=source.surface_get_arrays(0)
    var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var verts_to_keep:int=(
        V59.HERO_RADIAL if high else V59.MOBILE_RADIAL)*15*2*3
    if positions.size()<verts_to_keep:
        return null
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(verts_to_keep):
        st.add_vertex(positions[i])
    _soft_sidewall(st,high)
    var sectors:int=HERO_SECTORS if high else MOBILE_SECTORS
    var rows:int=HERO_ROWS if high else MOBILE_ROWS
    var span:float=TAU/float(sectors)
    for row in range(rows):
        var x:float=(float(row)-(float(rows)-1.0)*0.5)*(
            0.0515 if high else 0.100)
        var slant:float=(-0.013 if row<rows/2 else 0.013)
        for n in range(sectors):
            var stagger:float=(
                0.42 if ((row%2)==1) else 0.0)
            var a:float=span*(float(n)+stagger)
            _molded_lug(st,x,a,span,slant,
                0.045 if high else 0.074)
    st.generate_normals()
    var generated:=st.commit() as ArrayMesh
    if high:
        _hero_mesh=generated
    else:
        _tactical_mesh=generated
    return generated

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V59.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var high:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var tire:=model.find_child(TIRES,true,false) as MultiMeshInstance3D
    var pads:=model.find_child(PADS,true,false) as MultiMeshInstance3D
    if tire==null or tire.multimesh==null or (
            tire.multimesh.instance_count!=4):
        return false
    # The lightweight LOD8 has no legacy V7 pad node at all: its
    # continuous 48-lug band is baked directly into the rotating tire.
    if high and pads==null:
        return false
    if pads!=null and (pads.multimesh==null or
            pads.multimesh.instance_count!=32):
        return false
    var old_mesh:Mesh=tire.multimesh.mesh
    var real_mesh:ArrayMesh=_build_mesh(high)
    if old_mesh==null or real_mesh==null:
        return false
    # Existing 4 transforms spin by the original V1 wheel pose; new lugs
    # sit in that same local Y-axis radial space, not V7's 8 separate pads.
    model.set_meta(SAVED,{
        "old_mesh":old_mesh,
        "new_mesh":real_mesh,
        "pads_visible":(pads.visible if pads!=null else false)
    })
    tire.multimesh.mesh=real_mesh
    if pads!=null:
        pads.visible=false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v60_lugs_per_wheel",
        HERO_LUGS if high else MOBILE_LUGS)
    model.set_meta("tarvoka_g13_v60_closed_smooth_sidewall_ribs",
        2*(SIDE_RIBS_HERO if high else SIDE_RIBS_MOBILE))
    model.set_meta("tarvoka_g13_v60_original_wheel_instances",4)
    model.set_meta("tarvoka_g13_v60_saved_visible_gpu_batch",
        1 if pads!=null else 0)
    model.set_meta("tarvoka_g13_v60_added_draw_nodes",DRAW_NODES_ADDED)
    model.set_meta("tarvoka_g13_v60_faction_glass_unchanged",true)
    model.set_meta("tarvoka_g13_v60_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SAVED,{})
    if not saved.has("old_mesh") or not saved.has("new_mesh"):
        return false
    var tire:=model.find_child(TIRES,true,false) as MultiMeshInstance3D
    var pads:=model.find_child(PADS,true,false) as MultiMeshInstance3D
    if tire==null or tire.multimesh==null:
        return false
    tire.multimesh.mesh=saved["new_mesh"] if enabled else saved["old_mesh"]
    if pads!=null:
        pads.visible=false if enabled else bool(
            saved.get("pads_visible",true))
    model.set_meta("tarvoka_g13_v60_preview_enabled",enabled)
    return true
