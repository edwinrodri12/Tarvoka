extends RefCounted
class_name TarvokaG15ShelterCabFinishV3

# TARVOKA G15 V3 — original native Godot 3D sculpture.
# ART ONLY: no EW combat, turn logic, money, map reveal, supply or attack.
# V2's curved multi-instance fenders and roof mast gussets remain untouched.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const FLAG="tarvoka_g15_v3_chamfered_electronic_shelter_cab_and_tire_sidewalls"
const SHELTER="G15_V3_ClosedBeveledEWEnclosure"
const CAB="G15_V3_ClosedBeveledCab"
const ROOF="G15_V3_ClosedBeveledRoof"
const SIDEWALL_PREFIX="G15_V3_MatteRubberBulgedSidewall_"
const OLD=["G15_ElectronicShelter","G15_FrontCab","G15_ShieldedRoof"]
const REAL_SIDEWALLS=6
const V3_DRAW_NODES_HIGH=3

static func _material(color:String,metal:float,rough:float,
        clearcoat:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color)
    m.metallic=metal
    m.roughness=rough
    m.clearcoat_enabled=clearcoat
    if clearcoat:
        m.clearcoat=0.24
        m.clearcoat_roughness=0.41
    # Closed shell faces have correct normals, and no fake flat poster cards.
    m.cull_mode=BaseMaterial3D.CULL_BACK
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

# A real watertight eight-sided cross-section swept on longitudinal Z.
# Shelters and cab cast solid silhouettes, not a box buried under a decal.
static func _closed_octagon(half_x:float,y_bottom:float,y_top:float,
        z_front:float,z_back:float,bevel:float)->ArrayMesh:
    var b:float=minf(bevel,minf(half_x*0.45,(y_top-y_bottom)*0.43))
    var points:Array[Vector2]=[
        Vector2(-half_x+b,y_bottom),
        Vector2(half_x-b,y_bottom),
        Vector2(half_x,y_bottom+b),
        Vector2(half_x,y_top-b),
        Vector2(half_x-b,y_top),
        Vector2(-half_x+b,y_top),
        Vector2(-half_x,y_top-b),
        Vector2(-half_x,y_bottom+b)]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Outward-facing front (-Z) and rear (+Z) caps.
    for i in range(1,7):
        var p0:Vector2=points[0]
        var p1:Vector2=points[i]
        var p2:Vector2=points[i+1]
        _tri(st,Vector3(p0.x,p0.y,z_front),
            Vector3(p2.x,p2.y,z_front),
            Vector3(p1.x,p1.y,z_front))
        _tri(st,Vector3(p0.x,p0.y,z_back),
            Vector3(p1.x,p1.y,z_back),
            Vector3(p2.x,p2.y,z_back))
    for i in range(8):
        var j:int=(i+1)%8
        var a:Vector2=points[i]
        var b2:Vector2=points[j]
        _quad(st,Vector3(a.x,a.y,z_front),
            Vector3(b2.x,b2.y,z_front),
            Vector3(b2.x,b2.y,z_back),
            Vector3(a.x,a.y,z_back))
    return st.commit() as ArrayMesh

static func _mesh(parent:Node3D,name:String,geometry:Mesh,
        finish:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=geometry
    n.material_override=finish
    parent.add_child(n)
    return n

static func _box(parent:Node3D,name:String,at:Vector3,size:Vector3,
        material:Material,tilt:Vector3=Vector3.ZERO)->MeshInstance3D:
    var b:=BoxMesh.new()
    b.size=size
    var node:=_mesh(parent,name,b,material)
    node.position=at
    node.rotation_degrees=tilt
    return node

static func _rod(parent:Node3D,name:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,sides:int=10)->MeshInstance3D:
    var dif:Vector3=b-a
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=dif.length()
    cylinder.radial_segments=sides
    var rod:=_mesh(parent,name,cylinder,mat)
    rod.position=(a+b)*0.5
    rod.quaternion=Quaternion(Vector3.UP,dif.normalized())
    return rod

static func _ring(parent:Node3D,name:String,x:float,mat:Material,
        side:int)->MeshInstance3D:
    var torus:=TorusMesh.new()
    torus.inner_radius=0.233
    torus.outer_radius=0.327
    torus.rings=16
    torus.ring_segments=24
    var node:=_mesh(parent,name,torus,mat)
    node.position=Vector3(float(side)*x,0,0)
    node.rotation_degrees=Vector3(0,0,90)
    return node

static func _original_solids(root:Node3D,chassis:Node3D)->Array[MeshInstance3D]:
    var nodes:Array[MeshInstance3D]=[]
    for name in OLD:
        var node:=root.find_child(name,true,false) as MeshInstance3D
        if node==null or node.get_parent()!=chassis or (
                not node.mesh is BoxMesh):
            return []
        nodes.append(node)
    return nodes

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(V1.FLAG,false)) or (
            not bool(root.get_meta(V2.FLAG,false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    var mast:=root.find_child(V1.MAST,true,false) as Node3D
    if chassis==null or wheels==null or mast==null or (
            wheels.get_child_count()!=6):
        return false
    var old:Array[MeshInstance3D]=_original_solids(root,chassis)
    if old.size()!=3 or root.find_child(SHELTER,true,false)!=null:
        return false
    # The original right/left V1 side faction paint and rear electronic hatch
    # remain outside these shells. G15 V2 fender steel and mast pivot are
    # deliberately preserved in their original frame.
    var armor:=_material("#849198",0.54,0.49)
    var cab_steel:=_material("#717f88",0.47,0.56)
    var roof_steel:=_material("#aab7b8",0.64,0.39)
    var rubber:=_material("#212326",0.0,0.93)
    var sealed:=_material("#313c43",0.30,0.73)
    var latches:=_material("#cad1d3",0.83,0.29)
    var shroud:=_material("#56666d",0.39,0.67)
    var f1:=_closed_octagon(0.76,0.88,2.06,-0.31,1.57,0.115)
    var f2:=_closed_octagon(0.71,0.855,1.735,-1.59,-0.39,0.12)
    var f3:=_closed_octagon(0.805,2.045,2.23,-0.34,1.63,0.07)
    for geo in [f1,f2,f3]:
        if geo==null or geo.get_faces().size()!=28*3:
            return false
    # A visible seam separates armor from removable roof, with physical
    # chamfers instead of a uniformly glossy primitive rectangular slab.
    _mesh(chassis,SHELTER,f1,armor)
    _mesh(chassis,CAB,f2,cab_steel)
    _mesh(chassis,ROOF,f3,roof_steel)
    var old_visibility:Dictionary={}
    for solid in old:
        old_visibility[solid.name]=solid.visible
        solid.visible=false

    # Real hermetically sealed access: side hatch gaskets and elongated
    # physical hinges sit ON TOP of original panels; the existing colored
    # stripe remains exposed rather than being buried inside new geometry.
    var hero:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    if hero:
        for side in [-1,1]:
            var s:float=float(side)
            var prefix:String="G15_V3_%s_" % side
            _box(chassis,prefix+"ElectronicHatchSeal",
                Vector3(s*0.785,1.303,1.04),
                Vector3(0.017,0.395,0.49),sealed)
            _box(chassis,prefix+"ElectronicHatchFace",
                Vector3(s*0.796,1.303,1.04),
                Vector3(0.013,0.323,0.418),roof_steel)
            for hinge in range(2):
                _box(chassis,prefix+"HatchHinge_%d" % hinge,
                    Vector3(s*0.815,1.19+float(hinge)*0.24,0.822),
                    Vector3(0.047,0.072,0.085),latches)
            _box(chassis,prefix+"CableServiceCover",
                Vector3(s*0.809,1.85,0.91),
                Vector3(0.050,0.11,0.41),shroud)
            for slot in range(5):
                _box(chassis,prefix+"VentLouver_%d" % slot,
                    Vector3(s*0.839,1.75+float(slot)*0.045,0.97),
                    Vector3(0.016,0.014,0.37),sealed)
            _box(chassis,prefix+"CabDoorWeatherSeal",
                Vector3(s*0.734,1.15,-1.02),
                Vector3(0.014,0.49,0.64),sealed)
            _box(chassis,prefix+"CabDoorArmorFace",
                Vector3(s*0.744,1.15,-1.02),
                Vector3(0.014,0.415,0.566),cab_steel)
            _box(chassis,prefix+"DoorProtectiveSill",
                Vector3(s*0.778,0.867,-1.03),
                Vector3(0.19,0.063,0.71),shroud)
            _box(chassis,prefix+"DoorRecessHandle",
                Vector3(s*0.755,1.27,-0.823),
                Vector3(0.018,0.047,0.17),latches)
            # Small removable bumper covers protect the side service harness.
            _box(chassis,prefix+"RearCornerProtect",
                Vector3(s*0.706,1.12,1.59),
                Vector3(0.115,0.35,0.08),shroud)
        # Cable management: true diagonal cylindrical geometry terminates at
        # the EXISTING mast base, no unattached floating wires or duplicate rig.
        for side in [-1,1]:
            var s:float=float(side)
            _rod(chassis,"G15_V3_MastCableAnchor_%s" % side,
                Vector3(s*0.43,2.230,0.58),
                Vector3(s*0.20,2.267,0.47),0.024,sealed,9)
            _rod(chassis,"G15_V3_CableGuard_%s" % side,
                Vector3(s*0.55,2.24,0.76),
                Vector3(s*0.43,2.235,0.58),0.024,shroud,9)
            _box(chassis,"G15_V3_CableBaseBolt_%s" % side,
                Vector3(s*0.53,2.242,0.76),
                Vector3(0.10,0.030,0.11),latches)
        for n in range(6):
            _box(chassis,"G15_V3_ShieldedRoofSeam_%d" % n,
                Vector3(-0.55+float(n)*0.22,2.236,1.57),
                Vector3(0.087,0.022,0.05),shroud)
        # Genuine convex rubber sidewalls bulge around the machining without
        # painting wheel rims black; all six torus pieces follow the original
        # wheel-pivot rotations in motion and damage poses.
        for wheel in wheels.get_children():
            var pivot:=wheel as Node3D
            var pieces:String=str(pivot.name).trim_prefix("G15_Wheel_")
            var side:int=int(pieces.split("_")[0])
            _ring(pivot,SIDEWALL_PREFIX+pieces,0.133,rubber,side)
    root.set_meta("tarvoka_g15_v3_old_shell_visibility",old_visibility)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v3_hero",hero)
    root.set_meta("tarvoka_g15_v3_closed_chamfered_shells",3)
    root.set_meta("tarvoka_g15_v3_bulged_real_rubber_sidewalls",6 if hero else 0)
    root.set_meta("tarvoka_g15_v3_pbr_rubber_metallic",0.0)
    root.set_meta("tarvoka_g15_v3_preserves_v2_curved_arches",true)
    root.set_meta("tarvoka_g15_v3_no_gameplay_changes",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    if chassis==null:
        return false
    var old:Array[MeshInstance3D]=_original_solids(root,chassis)
    if old.size()!=3:
        return false
    var previous:Dictionary=root.get_meta(
        "tarvoka_g15_v3_old_shell_visibility",{})
    for solid in old:
        solid.visible=(not enabled) and bool(previous.get(solid.name,true))
    for node_name in [SHELTER,CAB,ROOF]:
        var sculpt:=root.find_child(node_name,true,false) as MeshInstance3D
        if sculpt==null:
            return false
        sculpt.visible=enabled
    # All added welds / fairings / sidewalls are grouped by V3 prefix.
    for child in chassis.get_children():
        if str(child.name).begins_with("G15_V3_"):
            if child is MeshInstance3D and str(child.name) not in [
                    SHELTER,CAB,ROOF]:
                (child as MeshInstance3D).visible=enabled
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if wheels!=null:
        for wheel in wheels.get_children():
            for detail in wheel.get_children():
                if str(detail.name).begins_with(SIDEWALL_PREFIX):
                    (detail as MeshInstance3D).visible=enabled
    root.set_meta("tarvoka_g15_v3_preview_enabled",enabled)
    return true
