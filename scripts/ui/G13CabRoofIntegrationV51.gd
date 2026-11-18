extends RefCounted
class_name TarvokaG13CabRoofIntegrationV51

# V51 native Godot art: fix the large hovering roof overhang visible in all
# 11 real V50 Godot screenshots. Rebuild existing roof and V45 steel brow
# resources IN PLACE; do not add draw nodes, lights, color, guns or rig.
const V50 = preload("res://scripts/ui/G13GlazingFitV50.gd")
const V48 = preload("res://scripts/ui/G13SculptFinishV48.gd")
const FLAG := "tarvoka_g13_v51_roof_to_glazing_integration"
const REQUIRES := "tarvoka_g13_v50_integrated_glazing_bevel"
const SAVED := "tarvoka_g13_v51_original_and_integrated_roof"
const BROW := "G13_V45_ClosedArmoredWindshieldBrow"
const ROOF_TRIANGLES := 112
const BROW_TRIANGLES := 32
const NEW_DRAW_NODES := 0
const ORIGINAL_BROW_NOSE := -1.186
const V51_BROW_NOSE := -1.161
const BROW_BACK := -1.068

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _tri_original(st:SurfaceTool,a:Vector3,
        b:Vector3,c:Vector3)->void:
    # Copy native V45 triangle winding unchanged while updating Z.
    var normal:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

static func _ring(x:float,z:float,bevel:float,
        y:float,nose:float,tail:float)->Array[Vector3]:
    var cut:float=minf(bevel,minf(x,z)*0.45)
    var front:float=-z+nose
    var back:float=z+tail
    return [
        Vector3(-x+cut,y,front),Vector3(x-cut,y,front),
        Vector3(x,y,front+cut),Vector3(x,y,back-cut),
        Vector3(x-cut,y,back),Vector3(-x+cut,y,back),
        Vector3(-x,y,back-cut),Vector3(-x,y,front+cut)
    ]

static func _roof_mesh()->ArrayMesh:
    # Roof center remains at (0,1.4,-.68). V49 nose extended to ~-1.239,
    # which made a visibly flat slab ahead of the V50 glazing. These seven
    # nested rings retract the nose ~60 mm and bevel into the roof crown.
    # Preserve outer shoulder width at the V37/V11 roof perimeter.
    var rings:Array=[
        _ring(0.545,0.457,0.105,-0.046,-0.014,0.008),
        _ring(0.593,0.477,0.118,-0.031,-0.017,0.004),
        _ring(0.629,0.481,0.134,-0.012,-0.016,0.002),
        _ring(0.639,0.478,0.137,0.000,-0.016,0.000),
        _ring(0.605,0.457,0.124,0.018,0.005,-0.009),
        _ring(0.558,0.434,0.112,0.032,0.017,-0.013),
        _ring(0.526,0.418,0.104,0.043,0.023,-0.015)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for level in range(rings.size()-1):
        var low:Array[Vector3]=rings[level]
        var high:Array[Vector3]=rings[level+1]
        for i in range(8):
            var j:int=(i+1)%8
            _tri(st,low[i],high[j],low[j])
            _tri(st,low[i],high[i],high[j])
    var start:Array[Vector3]=rings[0]
    var finish:Array[Vector3]=rings[rings.size()-1]
    for i in range(8):
        var j:int=(i+1)%8
        _tri(st,Vector3(0,start[0].y,0),start[i],start[j])
        _tri(st,Vector3(0,finish[0].y,0),finish[j],finish[i])
    return st.commit()

static func _brow_mesh(source:ArrayMesh)->ArrayMesh:
    # The V45 steel eyebrow previously reached Z=-1.186. Shift its
    # forward edge 25 mm rearward to meet the new V51 roof and preserve
    # the crest carrying the existing two faction-recognition bars.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var vertices:PackedVector3Array=source.get_faces()
    for i in range(0,vertices.size(),3):
        var face:Array[Vector3]=[]
        for k in range(3):
            var p:Vector3=vertices[i+k]
            var fraction:float=clampf(
                (p.z-ORIGINAL_BROW_NOSE)/(BROW_BACK-ORIGINAL_BROW_NOSE),
                0.0,1.0)
            p.z=lerpf(V51_BROW_NOSE,BROW_BACK,fraction)
            face.append(p)
        _tri_original(st,face[0],face[1],face[2])
    return st.commit()

static func _parts(root:Node3D)->Dictionary:
    if root==null or not bool(root.get_meta(REQUIRES,false)):
        return {}
    var high:bool=bool(root.get_meta(
        "tarvoka_g13_v1_high_detail",true))
    var roof_name:String=str(V48.HERO[2] if high else V48.TACTICAL[2])
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var roof:=root.find_child(roof_name,true,false) as MeshInstance3D
    var brow:=root.find_child(BROW,true,false) as MeshInstance3D
    if hull==null or roof==null or brow==null or (
            roof.get_parent()!=hull or brow.get_parent()!=hull) or (
            not roof.mesh is ArrayMesh) or (
            not brow.mesh is ArrayMesh):
        return {}
    return {"roof":roof,"brow":brow}

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(REQUIRES,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var parts:Dictionary=_parts(root)
    if parts.size()!=2:
        return false
    var roof:=parts["roof"] as MeshInstance3D
    var brow:=parts["brow"] as MeshInstance3D
    if brow.mesh.get_faces().size()!=BROW_TRIANGLES*3:
        return false
    var loft:=_roof_mesh()
    var eyebrow:=_brow_mesh(brow.mesh as ArrayMesh)
    if loft==null or eyebrow==null or (
            loft.get_surface_count()!=1 or eyebrow.get_surface_count()!=1) or (
            loft.get_faces().size()!=ROOF_TRIANGLES*3) or (
            eyebrow.get_faces().size()!=BROW_TRIANGLES*3):
        return false
    root.set_meta(SAVED,{
        "roof_before":roof.mesh,"roof_v51":loft,
        "brow_before":brow.mesh,"brow_v51":eyebrow
    })
    roof.mesh=loft
    brow.mesh=eyebrow
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v51_roof_triangles",ROOF_TRIANGLES)
    root.set_meta("tarvoka_g13_v51_brow_triangles",BROW_TRIANGLES)
    root.set_meta("tarvoka_g13_v51_new_draw_nodes",NEW_DRAW_NODES)
    root.set_meta("tarvoka_g13_v51_materials_preserved",true)
    root.set_meta("tarvoka_g13_v51_weapons","two_autocannons_no_missiles")
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=root.get_meta(SAVED,{})
    if saved.is_empty() or not V50.show_finish(root,true):
        return false
    var parts:Dictionary=_parts(root)
    if parts.size()!=2:
        return false
    var roof:=parts["roof"] as MeshInstance3D
    var brow:=parts["brow"] as MeshInstance3D
    roof.mesh=saved["roof_v51"] if enabled else saved["roof_before"]
    brow.mesh=saved["brow_v51"] if enabled else saved["brow_before"]
    root.set_meta("tarvoka_g13_v51_preview_enabled",enabled)
    return true
