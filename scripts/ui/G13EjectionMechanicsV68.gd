extends RefCounted
class_name TarvokaG13EjectionMechanicsV68

# G13 V68 native 3D art: ejection deflector recesses, machined cooling
# fins, four small receiver fastening heads and authentic barrel steel.
# Uses ONLY existing V67/V45/V18/V31 nodes. No new draw objects,
# projectile spawns, ammo mechanics, missiles or scene callbacks.
# Hero gains real 3D relief; Android retains low draw/triangle budget.
const V67=preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const V31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
const FLAG="tarvoka_g13_v68_ejector_guides_machined_barrels"
const SAVED="tarvoka_g13_v68_original_and_machined_gun_surfaces"
const EXTRA_DRAW_NODES=0
const EJECTION_COUNT=2
const COOLING_FIN_COUNT=10
const RECEIVER_FASTENERS=4
const PORT_BEFORE_TRIANGLES=60
const PORT_AFTER_TRIANGLES=114
const FIN_AFTER_TRIANGLES=60
static var _port_cache: ArrayMesh
static var _fin_cache: ArrayMesh

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        brightness:float)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    st.set_color(Color(brightness,brightness,brightness,1.0))
    st.set_normal(n)
    st.add_vertex(a)
    st.set_color(Color(brightness,brightness,brightness,1.0))
    st.set_normal(n)
    st.add_vertex(b)
    st.set_color(Color(brightness,brightness,brightness,1.0))
    st.set_normal(n)
    st.add_vertex(c)

static func _rim(y:float,half_x:float,half_z:float)->Array[Vector3]:
    var cut:float=0.006
    return [
        Vector3(-half_x+cut,y,-half_z),Vector3(half_x-cut,y,-half_z),
        Vector3(half_x,y,-half_z+cut),Vector3(half_x,y,half_z-cut),
        Vector3(half_x-cut,y,half_z),Vector3(-half_x+cut,y,half_z),
        Vector3(-half_x,y,half_z-cut),Vector3(-half_x,y,-half_z+cut)
    ]

static func _ejection_cover(original:ArrayMesh)->ArrayMesh:
    if original==null or original.get_faces().size()!=(
            PORT_BEFORE_TRIANGLES*3):
        return null
    if _port_cache!=null:
        return _port_cache
    var arrays:Array=original.surface_get_arrays(0)
    var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
    if positions.size()!=PORT_BEFORE_TRIANGLES*3 or (
            normals.size()!=positions.size()) or (
            colors.size()!=positions.size()):
        return null
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(positions.size()):
        st.set_color(colors[i])
        st.set_normal(normals[i])
        st.add_vertex(positions[i])
    # Real 19mm-raised outer guide lip and 13mm deeper dark central
    # deflection channel: all vertices belong to this ORIGINAL cover node.
    # Center floor is intentionally above the old cap, not a through hole.
    var levels:Array=[
        _rim(0.022,0.034,0.049),
        _rim(0.039,0.029,0.044),
        _rim(0.039,0.021,0.036),
        _rim(0.026,0.020,0.035)
    ]
    for layer in range(3):
        var low:Array[Vector3]=levels[layer]
        var high:Array[Vector3]=levels[layer+1]
        var shade:float=(
            0.59 if layer==0 else (
            0.92 if layer==1 else 0.44))
        for i in range(8):
            var j:int=(i+1)%8
            _tri(st,low[i],low[j],high[j],shade)
            _tri(st,low[i],high[j],high[i],shade)
    var floor:Array[Vector3]=levels[3]
    for i in range(1,7):
        _tri(st,floor[0],floor[i],floor[i+1],0.26)
    _port_cache=st.commit() as ArrayMesh
    return _port_cache

static func _fin_ring(x:float,scale:float)->Array[Vector3]:
    var e:float=0.5*scale
    var chamfer:float=0.12*scale
    return [
        Vector3(x,-e+chamfer,-e),Vector3(x,e-chamfer,-e),
        Vector3(x,e,-e+chamfer),Vector3(x,e,e-chamfer),
        Vector3(x,e-chamfer,e),Vector3(x,-e+chamfer,e),
        Vector3(x,-e,e-chamfer),Vector3(x,-e,-e+chamfer)
    ]

static func _cooling_fin()->ArrayMesh:
    if _fin_cache!=null:
        return _fin_cache
    var rings:Array=[
        _fin_ring(-0.50,0.72),_fin_ring(-0.41,1.0),
        _fin_ring(0.41,1.0),_fin_ring(0.50,0.72)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(3):
        var left:Array[Vector3]=rings[layer]
        var right:Array[Vector3]=rings[layer+1]
        var shade:float=(0.59 if layer==0 else (
            0.84 if layer==1 else 0.66))
        for i in range(8):
            var j:int=(i+1)%8
            _tri(st,left[i],left[j],right[j],shade)
            _tri(st,left[i],right[j],right[i],shade)
    var front:Array[Vector3]=rings[0]
    var back:Array[Vector3]=rings[3]
    for i in range(1,7):
        _tri(st,front[0],front[i+1],front[i],0.57)
        _tri(st,back[0],back[i],back[i+1],0.91)
    _fin_cache=st.commit() as ArrayMesh
    return _fin_cache

static func _mat(original:StandardMaterial3D,
        kind:String)->StandardMaterial3D:
    var m:=original.duplicate(true) as StandardMaterial3D
    match kind:
        "port":
            m.albedo_color=Color("#8c9ba0")
            m.metallic=0.70
            m.roughness=0.41
            m.vertex_color_use_as_albedo=true
            m.clearcoat_enabled=true
            m.clearcoat=0.16
            m.clearcoat_roughness=0.35
        "fins":
            m.albedo_color=Color("#5f7179")
            m.metallic=0.62
            m.roughness=0.48
            m.vertex_color_use_as_albedo=true
            m.clearcoat_enabled=false
        "bolts":
            m.albedo_color=Color("#adb9b8")
            m.metallic=0.76
            m.roughness=0.38
            m.clearcoat_enabled=false
        "barrel":
            m.albedo_color=original.albedo_color.lerp(
                Color("#71858a"),0.45)
            m.metallic=0.71
            m.roughness=0.42
            m.clearcoat_enabled=true
            m.clearcoat=0.13
            m.clearcoat_roughness=0.39
        "muzzle":
            m.albedo_color=original.albedo_color.lerp(
                Color("#3a484e"),0.34)
            m.metallic=0.68
            m.roughness=0.49
            m.clearcoat_enabled=false
        "cheek":
            # V32 faction enamel (inherited through V67) is unchanged.
            m.metallic=clampf(original.metallic+0.03,0.20,0.68)
            m.roughness=clampf(original.roughness-0.025,0.38,0.70)
            m.clearcoat_enabled=true
            m.clearcoat=0.18
            m.clearcoat_roughness=0.41
    return m

static func _material(node:GeometryInstance3D)->StandardMaterial3D:
    if node.material_override is StandardMaterial3D:
        return node.material_override as StandardMaterial3D
    if node is MultiMeshInstance3D:
        var mm:MultiMeshInstance3D=node as MultiMeshInstance3D
        if mm.multimesh!=null and mm.multimesh.mesh is PrimitiveMesh:
            return (mm.multimesh.mesh as PrimitiveMesh
                ).material as StandardMaterial3D
    return null

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V67.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hero:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var pitch:Node3D=model.find_child(
        "G13_ElevacionCanones",true,false) as Node3D
    if pitch==null:
        return false
    var targets:Dictionary={}
    var kinds:Dictionary={}
    var new_meshes:Dictionary={}
    for side in [-1,1]:
        var barrel_name:String="G13_Autocannon_%d" % side
        var mouth_name:String="G13_RealMuzzle_%d" % side
        for name in [barrel_name,mouth_name]:
            var item:MeshInstance3D=model.find_child(
                name,true,false) as MeshInstance3D
            if item==null or item.get_parent()!=pitch:
                return false
            targets[name]=item
            kinds[name]="barrel" if name==barrel_name else "muzzle"
    if hero:
        var fin:MultiMeshInstance3D=model.find_child(
            V45.RIBS,true,false) as MultiMeshInstance3D
        var rivets:MultiMeshInstance3D=model.find_child(
            V18.RIVETS,true,false) as MultiMeshInstance3D
        if fin==null or rivets==null or (
                fin.get_parent()!=pitch) or (
                rivets.get_parent()!=pitch) or (
                fin.multimesh==null or
                rivets.multimesh==null) or (
                fin.multimesh.instance_count!=COOLING_FIN_COUNT) or (
                rivets.multimesh.instance_count!=RECEIVER_FASTENERS) or (
                not fin.multimesh.mesh is BoxMesh) or (
                not rivets.multimesh.mesh is SphereMesh):
            return false
        var sculpt:ArrayMesh=_cooling_fin()
        if sculpt.get_faces().size()!=FIN_AFTER_TRIANGLES*3:
            return false
        var heads:=CylinderMesh.new()
        heads.top_radius=0.011
        heads.bottom_radius=0.014
        heads.height=0.011
        heads.radial_segments=6
        targets[V45.RIBS]=fin
        kinds[V45.RIBS]="fins"
        new_meshes[V45.RIBS]=sculpt
        targets[V18.RIVETS]=rivets
        kinds[V18.RIVETS]="bolts"
        new_meshes[V18.RIVETS]=heads
        for side in [-1,1]:
            var name:String=V18.EJECTION%side
            var node:MeshInstance3D=model.find_child(
                name,true,false) as MeshInstance3D
            if node==null or node.get_parent()!=pitch or (
                    not node.mesh is ArrayMesh):
                return false
            var ejection:ArrayMesh=_ejection_cover(node.mesh as ArrayMesh)
            if ejection==null or (
                    ejection.get_faces().size()!=PORT_AFTER_TRIANGLES*3):
                return false
            targets[name]=node
            kinds[name]="port"
            new_meshes[name]=ejection
    else:
        var name:String=V31.CHEEKS
        var cheek:MeshInstance3D=model.find_child(
            name,true,false) as MeshInstance3D
        if cheek==null or cheek.get_parent()!=pitch or (
                not cheek.mesh is ArrayMesh):
            return false
        targets[name]=cheek
        kinds[name]="cheek"
    var materials_before:Dictionary={}
    var materials_after:Dictionary={}
    var meshes_before:Dictionary={}
    for name in targets:
        var node:GeometryInstance3D=targets[name] as GeometryInstance3D
        var original:StandardMaterial3D=_material(node)
        if original==null:
            return false
        materials_before[name]=node.material_override
        materials_after[name]=_mat(original,str(kinds[name]))
    for name in new_meshes:
        var node:GeometryInstance3D=targets[name] as GeometryInstance3D
        if node is MultiMeshInstance3D:
            meshes_before[name]=(node as MultiMeshInstance3D
                ).multimesh.mesh
        else:
            meshes_before[name]=(node as MeshInstance3D).mesh
    for name in targets:
        var node:GeometryInstance3D=targets[name] as GeometryInstance3D
        node.material_override=materials_after[name]
    for name in new_meshes:
        var node:GeometryInstance3D=targets[name] as GeometryInstance3D
        if node is MultiMeshInstance3D:
            (node as MultiMeshInstance3D
                ).multimesh.mesh=new_meshes[name]
        else:
            (node as MeshInstance3D).mesh=new_meshes[name]
    model.set_meta(SAVED,{
        "before_coats":materials_before,"after_coats":materials_after,
        "before_meshes":meshes_before,"after_meshes":new_meshes})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v68_ejection_guides",
        EJECTION_COUNT if hero else 0)
    model.set_meta("tarvoka_g13_v68_cooling_ribs",
        COOLING_FIN_COUNT if hero else 0)
    model.set_meta("tarvoka_g13_v68_receiver_fasteners",
        RECEIVER_FASTENERS if hero else 0)
    model.set_meta("tarvoka_g13_v68_extra_draw_nodes",EXTRA_DRAW_NODES)
    model.set_meta("tarvoka_g13_v68_gun_count",2)
    model.set_meta("tarvoka_g13_v68_missile_count",0)
    model.set_meta("tarvoka_g13_v68_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SAVED,{})
    var coats:Dictionary=saved.get(
        "after_coats",{}) if enabled else saved.get(
        "before_coats",{})
    var meshes:Dictionary=saved.get(
        "after_meshes",{}) if enabled else saved.get(
        "before_meshes",{})
    if coats.size()!=(
            8 if bool(model.get_meta(
            "tarvoka_g13_v1_high_detail",false)) else 5):
        return false
    for name in coats:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in meshes:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in coats:
        var node:GeometryInstance3D=model.find_child(
            str(name),true,false) as GeometryInstance3D
        node.material_override=coats[name]
    for name in meshes:
        var node:GeometryInstance3D=model.find_child(
            str(name),true,false) as GeometryInstance3D
        if node is MultiMeshInstance3D:
            (node as MultiMeshInstance3D).multimesh.mesh=meshes[name]
        else:
            (node as MeshInstance3D).mesh=meshes[name]
    model.set_meta("tarvoka_g13_v68_preview_enabled",enabled)
    return true
