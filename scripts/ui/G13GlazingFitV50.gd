extends RefCounted
class_name TarvokaG13GlazingFitV50

# V50 REAL Godot 4.3 geometry. Fix the rectangular glazing outlines and
# side-cab seams seen in the G13 V49 native Studio screenshots.
# Replaces the Mesh resource on the EXISTING two frontal glazing nodes and,
# on hero LOD13, both original V11 side windows. No new draw nodes, pivots,
# glass positions, faction colors or weapons. Exact V49 meshes are saved.
const V49 = preload("res://scripts/ui/G13SeamlessSilhouetteV49.gd")
const FLAG := "tarvoka_g13_v50_integrated_glazing_bevel"
const REQUIRES := "tarvoka_g13_v49_window_turret_seamless_lofts"
const SAVED := "tarvoka_g13_v50_glass_resources_before_and_after"
const FRONT_TRIANGLES := 44
const SIDE_TRIANGLES := 28
const HERO_GLASS_NODES := 4
const TACTICAL_GLASS_NODES := 2
const NEW_DRAW_NODES := 0

static func _tri(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
    var n: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _quad(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3, d: Vector3) -> void:
    _tri(st, a, b, c)
    _tri(st, a, c, d)

static func _sealed(rings: Array) -> ArrayMesh:
    # Identical contour vertex count for every section, double-sided
    # physically bevelled front and sides; closed caps and no open edges.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n: int = (rings[0] as Array).size()
    for layer in range(rings.size()-1):
        var low: Array = rings[layer]
        var high: Array = rings[layer+1]
        for i in range(n):
            var j: int = (i+1)%n
            _quad(st, low[i], high[i], high[j], low[j])
    var start: Array = rings[0]
    var finish: Array = rings[rings.size()-1]
    for i in range(1,n-1):
        _tri(st, start[0], start[i+1], start[i])
        _tri(st, finish[0], finish[i], finish[i+1])
    return st.commit()

static func _front_section(hx:float, hy:float,
        bevel:float, z:float) -> Array[Vector3]:
    var cut:float=minf(bevel,minf(hx,hy)*0.42)
    return [
        Vector3(-hx+cut,-hy,z), Vector3(hx-cut,-hy,z),
        Vector3(hx,-hy+cut,z), Vector3(hx,hy-cut,z),
        Vector3(hx-cut,hy,z), Vector3(-hx+cut,hy,z),
        Vector3(-hx,hy-cut,z), Vector3(-hx,-hy+cut,z)
    ]

static func _front_glass(src: Mesh) -> ArrayMesh:
    var box: AABB = src.get_aabb()
    var hx:float = box.size.x*0.5
    var hy:float = box.size.y*0.5
    var hz:float = box.size.z*0.5
    # Preserve the exact transform/overall dimensions of each original
    # front pane; form its chamfered surface from three sealed octagons.
    return _sealed([
        _front_section(hx*0.973,hy*0.963,0.018,-hz),
        _front_section(hx,hy,0.018,-hz+0.007),
        _front_section(hx*0.983,hy*0.974,0.018,hz)
    ])

static func _side_glass(side: int) -> ArrayMesh:
    var sign:float=float(side)
    # V49 cab global side at Y=1.155 is ~|X|=.556; at Y=1.275
    # ~|X|=.510. The visible glass surfaces are offset just 9-10 mm
    # from that steel rather than leaving large dark discontinuities.
    # Original V11 glass lay along Z=-1.045..-.540. This eight-corner
    # polygon maintains that window footprint but bevels every corner.
    var outline:Array[Vector2] = [
        Vector2(-1.019,1.151),
        Vector2(-0.571,1.151),
        Vector2(-0.546,1.179),
        Vector2(-0.560,1.250),
        Vector2(-0.589,1.275),
        Vector2(-0.942,1.275),
        Vector2(-0.972,1.247),
        Vector2(-1.037,1.179)
    ]
    var outer:Array[Vector3]=[]
    var inner:Array[Vector3]=[]
    for point in outline:
        var fraction:float=clampf((point.y-1.151)/0.124,0.0,1.0)
        var x:float=lerpf(0.567,0.520,fraction)
        outer.append(Vector3(sign*x,point.y,point.x))
        inner.append(Vector3(sign*(x-0.014),point.y,point.x))
    return _sealed([inner,outer])

static func _nodes(root: Node3D, high: bool) -> Dictionary:
    if root==null or not bool(root.get_meta(REQUIRES,false)):
        return {}
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    if hull==null:
        return {}
    var labels:Array = ["G13_FrontGlass_-1","G13_FrontGlass_1"]
    if high:
        labels.append_array([
            "G13_V11_SideWindow_-1","G13_V11_SideWindow_1"
        ])
    var found:Dictionary={}
    for label in labels:
        var pane:=root.find_child(label,true,false) as MeshInstance3D
        if pane==null or pane.get_parent()!=hull or (
                pane.mesh==null) or (
                not pane.material_override is StandardMaterial3D):
            return {}
        if str(label).begins_with("G13_FrontGlass") and (
                not pane.mesh is BoxMesh):
            return {}
        if str(label).begins_with("G13_V11") and (
                not pane.mesh is ArrayMesh):
            return {}
        found[label]=pane
    return found

static func apply(root:Node3D) -> bool:
    if root==null or not bool(root.get_meta(REQUIRES,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var high:bool=bool(root.get_meta(
        "tarvoka_g13_v1_high_detail",true))
    var parts:=_nodes(root,high)
    var target_count:int=HERO_GLASS_NODES if high else TACTICAL_GLASS_NODES
    if parts.size()!=target_count:
        return false
    var old_meshes:Dictionary={}
    var new_meshes:Dictionary={}
    var old_coats:Dictionary={}
    var new_coats:Dictionary={}
    for label in parts.keys():
        var pane:=parts[label] as MeshInstance3D
        var finish:ArrayMesh
        if str(label).begins_with("G13_FrontGlass"):
            finish=_front_glass(pane.mesh)
            if finish.get_faces().size()!=FRONT_TRIANGLES*3:
                return false
        else:
            finish=_side_glass(-1 if str(label).ends_with("-1") else 1)
            if finish.get_faces().size()!=SIDE_TRIANGLES*3:
                return false
        var original:=pane.material_override as StandardMaterial3D
        var coat:=original.duplicate(true) as StandardMaterial3D
        coat.cull_mode=BaseMaterial3D.CULL_DISABLED
        # Keep the V47 optics PBR, do not force blue or alter faction paint.
        old_meshes[label]=pane.mesh
        new_meshes[label]=finish
        old_coats[label]=original
        new_coats[label]=coat
    root.set_meta(SAVED,{
        "old_meshes":old_meshes,"new_meshes":new_meshes,
        "old_coats":old_coats,"new_coats":new_coats,
        "hero":high
    })
    for label in parts.keys():
        var pane:=parts[label] as MeshInstance3D
        pane.mesh=new_meshes[label]
        pane.material_override=new_coats[label]
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v50_reprofiled_window_count",target_count)
    root.set_meta("tarvoka_g13_v50_new_draw_nodes",NEW_DRAW_NODES)
    root.set_meta("tarvoka_g13_v50_window_positions_unchanged",true)
    root.set_meta("tarvoka_g13_v50_armament","two_autocannons_no_missiles")
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=root.get_meta(SAVED,{})
    if saved.is_empty() or not V49.show_finish(root,true):
        return false
    var parts:=_nodes_for_preview(root,bool(saved.get("hero",true)))
    if parts.is_empty():
        return false
    var meshes:Dictionary=(
        saved["new_meshes"] if enabled else saved["old_meshes"])
    var coats:Dictionary=(
        saved["new_coats"] if enabled else saved["old_coats"])
    for label in parts.keys():
        if not meshes.has(label) or not coats.has(label):
            return false
    for label in parts.keys():
        var pane:=parts[label] as MeshInstance3D
        pane.mesh=meshes[label]
        pane.material_override=coats[label]
    root.set_meta("tarvoka_g13_v50_preview_enabled",enabled)
    return true

static func _nodes_for_preview(root:Node3D,high:bool)->Dictionary:
    # Once installed, source BoxMesh is replaced by ArrayMesh: find by
    # node identity rather than pre-V50 type validation.
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    if hull==null:
        return {}
    var names:Array=["G13_FrontGlass_-1","G13_FrontGlass_1"]
    if high:
        names.append_array([
            "G13_V11_SideWindow_-1","G13_V11_SideWindow_1"])
    var result:Dictionary={}
    for name in names:
        var pane:=root.find_child(name,true,false) as MeshInstance3D
        if pane==null or pane.get_parent()!=hull:
            return {}
        result[name]=pane
    return result
