extends RefCounted
class_name TarvokaA02FpvArtV1

# Fictional game sculpture; abstract Godot display units, not engineering.
const FLAG:String="tarvoka_a02_fpv_art_v1"
const BODY:String="A02_VisualBody"
const PAINT:String="A02_FactionCrown"

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _part(parent:Node3D,tag:String,mesh:Mesh,at:Vector3,
        size:Vector3,paint:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=tag
    n.mesh=mesh
    n.position=at
    n.scale=size
    n.material_override=paint
    parent.add_child(n)
    return n

static func _oval(parent:Node3D,tag:String,at:Vector3,size:Vector3,
        paint:Material,hero:bool)->MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=16 if hero else 10
    mesh.rings=6 if hero else 4
    return _part(parent,tag,mesh,at,size,paint)

# Bevelled abstract game sculpture. All surfaces are closed and clockwise.
static func _face(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,outward:Vector3)->void:
    t.add_vertex(a)
    if (b-a).cross(c-a).dot(outward)>0.0:
        t.add_vertex(c)
        t.add_vertex(b)
    else:
        t.add_vertex(b)
        t.add_vertex(c)

static func _sculpt()->ArrayMesh:
    var outline:Array[Vector2]=[
        Vector2(-0.30,-0.5),Vector2(0.30,-0.5),
        Vector2(0.5,-0.28),Vector2(0.5,0.28),
        Vector2(0.30,0.5),Vector2(-0.30,0.5),
        Vector2(-0.5,0.28),Vector2(-0.5,-0.28)]
    var rings:Array=[]
    for layer in [Vector2(-0.5,0.72),Vector2(-0.27,1.0),
            Vector2(0.22,1.0),Vector2(0.5,0.72)]:
        var ring:Array[Vector3]=[]
        for point in outline:
            ring.append(Vector3(point.x*layer.y,layer.x,point.y*layer.y))
        rings.append(ring)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(rings.size()-1):
        var low:Array=rings[j]
        var high:Array=rings[j+1]
        for i in range(outline.size()):
            var k:int=(i+1)%outline.size()
            var mid:Vector2=(outline[i]+outline[k])*0.5
            var outward:=Vector3(mid.x,0,mid.y)
            _face(t,low[i],low[k],high[k],outward)
            _face(t,low[i],high[k],high[i],outward)
    for i in range(1,outline.size()-1):
        _face(t,rings[0][0],rings[0][i],rings[0][i+1],Vector3.DOWN)
        _face(t,rings[3][0],rings[3][i],rings[3][i+1],Vector3.UP)
    t.index()
    t.generate_normals()
    return t.commit()

static func _shell_finish(source:ArrayMesh,upper:Color,lower:Color)->ArrayMesh:
    # V3 opaque tonal variation on the same closed ornamental surface.
    var arrays:Array=source.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        var shade:Color=lower.lerp(upper,smoothstep(-0.5,0.5,vertex.y))
        pigments.append(shade)
    arrays[Mesh.ARRAY_COLOR]=pigments
    var mesh:=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh

static func _guard_finish(primitive:TorusMesh,faction:Color)->ArrayMesh:
    # Color is baked into existing visual geometry; no decal or alpha.
    var arrays:Array=primitive.get_mesh_arrays()
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        pigments.append(Color("#43535d").lerp(faction,
            0.10+0.72*smoothstep(-0.015,0.06,vertex.y)))
    arrays[Mesh.ARRAY_COLOR]=pigments
    var mesh:=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh

static func build(root:Node3D,faction:Color,hero:bool)->bool:
    if root==null or root.has_meta(FLAG):
        return false
    var body:=Node3D.new()
    body.name=BODY
    root.add_child(body)
    var graphite:=_mat(Color("#33414a"),0.12,0.74)
    var coated_shell:=_mat(Color.WHITE,0.12,0.74)
    coated_shell.vertex_color_use_as_albedo=true
    coated_shell.vertex_color_is_srgb=true
    var shell:=_mat(Color("#697b86"),0.14,0.73)
    var coated_guard:=_mat(Color.WHITE,0.12,0.74)
    coated_guard.vertex_color_use_as_albedo=true
    coated_guard.vertex_color_is_srgb=true
    var sculpt:=_sculpt()
    var enamel:=_mat(faction,0.13,0.72)
    var glass:=_mat(Color("#286477"),0.15,0.34)
    var dark_trim:=_mat(Color("#263740"),0.10,0.70)
    var shell_mesh:=_shell_finish(sculpt,Color("#697b86"),Color("#34434c"))
    _part(body,"A02_ClosedCentralShell",shell_mesh,Vector3(0,0.96,0),
        Vector3(0.72,0.44,1.05),coated_shell)
    _part(body,PAINT,sculpt,Vector3(0,1.105,-0.045),
        Vector3(0.61,0.20,0.83),enamel)
    # V3: a stylized opaque faceplate, not a real imaging assembly.
    # The bevelled dark frame overlaps the existing sculpture; the inset
    # colored face overlaps the frame, with no detached or transparent panel.
    _part(body,"A02_VisorFrame",sculpt,Vector3(0,0.98,-0.485),
        Vector3(0.43,0.25,0.16),dark_trim)
    _part(body,"A02_FrontVisor",sculpt,Vector3(0,0.98,-0.552),
        Vector3(0.32,0.16,0.065),glass)
    _part(body,"A02_SealedUndershell",shell_mesh,Vector3(0,0.805,0.07),
        Vector3(0.57,0.25,0.77),coated_shell)
    for i in range(4):
        var side:float=-1.0 if i%2==0 else 1.0
        var depth:float=-1.0 if i<2 else 1.0
        var at:=Vector3(side*0.61,0.98,depth*0.52)
        var shoulder:=_part(body,"A02_SculptedShoulder_"+str(i),sculpt,
            Vector3(side*0.34,0.96,depth*0.28),Vector3(0.75,0.24,0.32),shell)
        shoulder.rotation_degrees.y=-side*depth*34.0
        var ring:=TorusMesh.new()
        ring.inner_radius=0.28
        ring.outer_radius=0.42
        ring.rings=24 if hero else 12
        ring.ring_segments=10 if hero else 6
        _part(body,"A02_ClosedRotorGuard_"+str(i),_guard_finish(ring,faction),
            at,Vector3.ONE,coated_guard)
        var rotor:=Node3D.new()
        rotor.name="A02_VisualRotor_"+str(i)
        rotor.position=at
        body.add_child(rotor)
        _oval(rotor,"A02_RotorCap",Vector3.ZERO,Vector3(0.22,0.14,0.22),shell,hero)
        for j in range(2):
            var graphic:=_oval(rotor,"A02_RotorGraphic_"+str(j),Vector3(0,0.025,0),
                Vector3(0.48,0.042,0.085),graphite,hero)
            graphic.rotation_degrees.y=float(j)*90.0
        if hero:
            _part(body,"A02_ShoulderBadge_"+str(i),sculpt,
                Vector3(side*0.34,1.065,depth*0.28),Vector3(0.22,0.07,0.20),enamel)
    root.set_meta("tarvoka_a02_v3_surface_finish",true)
    root.set_meta("tarvoka_a02_v2_beveled_visual_shell",true)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a02_visual_only",true)
    root.set_meta("tarvoka_a02_lod",13 if hero else 8)
    return true

static func restore(root:Node3D)->void:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return
    body.rotation=Vector3.ZERO
    body.position=Vector3.ZERO
    for i in range(4):
        var rotor:=body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
        if rotor!=null:
            rotor.rotation=Vector3.ZERO

static func pose(root:Node3D,kind:String,progress:float)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)) or not kind in ["idle","move","hit"]:
        return false
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return false
    var p:float=clampf(progress,0.0,1.0)
    var envelope:float=pow(sin(p*PI),2.0)
    body.position.y=0.06*envelope if kind=="move" else 0.0
    body.rotation_degrees.z=4.0*sin(p*TAU)*envelope if kind=="move" else (7.0*sin(p*TAU)*envelope if kind=="hit" else 0.0)
    for i in range(4):
        var rotor:=body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
        if rotor!=null:
            rotor.rotation_degrees.y=(1.0 if i%2==0 else -1.0)*720.0*p if kind=="move" else 0.0
    return true
