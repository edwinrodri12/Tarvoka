extends RefCounted
class_name TarvokaA01ReconDamageFinishV14

# A01 V14: damage is sculpted ON the actual airframe, never a flat
# floating rectangle. D4 swaps the complete right wing for a sealed,
# irregularly fractured shorter wing and physical detached debris.
# Visual ONLY: original DamageV6 stage/repair and combat remain authoritative.
const FLAG:String="tarvoka_a01_v14_organic_damage"
const FRACTURE:String="A01_V14_SealedFracturedRightWing"
const D1_WING:String="A01_V14_D1_ConformalPortWingScrape"
const D1_NOSE:String="A01_V14_D1_ConformalNoseScratch"
const D2_BURN:String="A01_V14_D2_ConformalWingBurn"
const D2_PLATE:String="A01_V14_D2_BentTrailingComposite"
const D3_TAIL:String="A01_V14_D3_ConformalTailBurn"
const D3_PANEL:String="A01_V14_D3_LiftedAccessPanel"
const D4_RIB:String="A01_V14_D4_ExposedFractureCore"
const D4_SHARD:String="A01_V14_D4_IrregularDetachedWing"
const D4_BLADE:String="A01_V14_D4_TwistedPropBlade"

const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const V6=preload("res://scripts/ui/A01ReconDamageV6.gd")
const V8=preload("res://scripts/ui/A01ReconWingletV8.gd")
const V9=preload("res://scripts/ui/A01ReconWingletV9.gd")
const V11=preload("res://scripts/ui/A01ReconAirframeV11.gd")
const V13=preload("res://scripts/ui/A01ReconTailOpticsV13.gd")

static func _mat(c:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _tri(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    # Godot considers clockwise triangles front-facing.
    t.add_vertex(a)
    t.add_vertex(c)
    t.add_vertex(b)

# V21: irregular sealed scars with softer perimeter shading. All points
# follow the original wing/body parameterization, with buried inner skin.
const SCAR_OUTLINE:Array=[
    Vector2(0.04,0.40),Vector2(0.20,0.08),Vector2(0.53,0.03),
    Vector2(0.85,0.16),Vector2(0.98,0.52),Vector2(0.78,0.87),
    Vector2(0.40,0.98),Vector2(0.12,0.79)
]

static func _colored_tri(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        ca:Color,cb:Color,cc:Color)->void:
    t.set_color(ca)
    t.add_vertex(a)
    t.set_color(cc)
    t.add_vertex(c)
    t.set_color(cb)
    t.add_vertex(b)

static func _patch(parent:Node3D,tag:String,points:Array,center:Vector3,
        up:Vector3,mat:StandardMaterial3D,substrate:Array)->MeshInstance3D:
    var normal:Vector3=up.normalized()
    var order:Array=[]
    for i in range(points.size()):
        order.append(i)
    if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)<0.0:
        order.reverse()
    var outside:Array=[]
    var inside:Array=[]
    for idx in order:
        var p:Vector3=points[int(idx)]
        outside.append(p+normal*0.005)
        inside.append(p-normal*0.008)
    # V29: fully opaque pigment blends into the actual underlying finish.
    # Preserve the sealed scar mesh, with only its center strongly weathered.
    var dark:Color=mat.albedo_color
    var top:Vector3=center+normal*0.006
    var bottom:Vector3=center-normal*0.008
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(order.size()):
        var j:int=(i+1)%order.size()
        var ei:Color=substrate[int(order[i])]
        var ej:Color=substrate[int(order[j])]
        _colored_tri(t,top,outside[i],outside[j],dark,ei,ej)
        _colored_tri(t,bottom,inside[j],inside[i],dark,ej,ei)
        _colored_tri(t,outside[i],inside[i],inside[j],ei,ei,ej)
        _colored_tri(t,outside[i],inside[j],outside[j],ei,ej,ej)
    t.index()
    t.generate_normals()
    var n:=MeshInstance3D.new()
    n.name=tag
    n.mesh=t.commit()
    var finish:=mat.duplicate() as StandardMaterial3D
    finish.albedo_color=Color.WHITE
    finish.vertex_color_use_as_albedo=true
    finish.vertex_color_is_srgb=true
    n.material_override=finish
    parent.add_child(n)
    return n

static func _wing_patch(parent:Node3D,tag:String,side:float,
        x0:float,x1:float,u0:float,u1:float,hero:bool,
        mat:StandardMaterial3D)->MeshInstance3D:
    var points:Array=[]
    var substrate:Array=[]
    for uv in SCAR_OUTLINE:
        var point:Vector3=V11._wing_surface(side,lerpf(x0,x1,uv.x),
            lerpf(u0,u1,uv.y),hero)
        points.append(point)
        substrate.append(V4._wing_pigment(point,hero))
    var center:Vector3=V11._wing_surface(side,(x0+x1)*0.5,(u0+u1)*0.5,hero)
    return _patch(parent,tag,points,center,Vector3.UP,mat,substrate)

static func _hull_point(z:float,angle:float,hero:bool)->Vector3:
    # Match actual polygon facets instead of an ideal ellipse outside them.
    var step:float=360.0/float(16 if hero else 12)
    var lo:float=floorf(angle/step)*step
    return V11._body_surface(z,lo).lerp(
        V11._body_surface(z,lo+step),(angle-lo)/step)

static func _body_patch(parent:Node3D,tag:String,z0:float,z1:float,
        a0:float,a1:float,hero:bool,mat:StandardMaterial3D,faction:Color)->MeshInstance3D:
    var points:Array=[]
    var substrate:Array=[]
    for uv in SCAR_OUTLINE:
        var z:float=lerpf(z0,z1,uv.x)
        var angle:float=lerpf(a0,a1,uv.y)
        var point:Vector3=_hull_point(z,angle,hero)
        points.append(point)
        # The actual dorsal crest lies above part of this substrate.
        var crown_angle:bool=angle>=(45.0 if hero else 60.0) and angle<=(135.0 if hero else 120.0)
        var on_crest:bool=crown_angle and z>=-0.570 and z<=0.760
        substrate.append(faction if on_crest else V11._hull_pigment(point,faction))
    var mid:float=deg_to_rad((a0+a1)*0.5)
    var center:Vector3=_hull_point((z0+z1)*0.5,(a0+a1)*0.5,hero)
    return _patch(parent,tag,points,center,Vector3(cos(mid),sin(mid),0),mat,substrate)

static func _tail_patch(parent:Node3D,hero:bool,
        mat:StandardMaterial3D)->MeshInstance3D:
    var points:Array=[]
    var substrate:Array=[]
    for uv in SCAR_OUTLINE:
        points.append(V13._tail_top(-1.0,lerpf(0.42,0.59,uv.x),
            lerpf(0.29,0.76,uv.y),hero))
        substrate.append(Color("#8899a5"))
    return _patch(parent,D3_TAIL,points,V13._tail_top(-1.0,0.505,0.525,hero),
        Vector3(0,0.92,0.39),mat,substrate)

static func _fracture_pigment(point:Vector3,hero:bool)->Color:
    var base:Color=V4._wing_pigment(point,hero)
    return base.lerp(Color("#303b42"),0.90*smoothstep(0.99,1.035,point.x))

static func _finish_fracture(wing:MeshInstance3D,hero:bool)->bool:
    if not V4.apply_composite_finish(wing,hero):
        return false
    var arrays:Array=wing.mesh.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        pigments.append(_fracture_pigment(vertex,hero))
    arrays[Mesh.ARRAY_COLOR]=pigments
    var mesh:=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    wing.mesh=mesh
    return true

static func _fractured_wing(parent:Node3D,hero:bool,
        shell:Material)->MeshInstance3D:
    # Reuse EXACT V4 root foil and hero mid-span; terminate at a jagged
    # closed carbon-fiber fracture rather than draw an opaque box over
    # the still-complete wing. No original wing mesh is permanently freed.
    var stations:Array=[
        V4._profile(0.280,1.030,-0.364,0.264,0.100)
    ]
    if hero:
        stations.append(V4._profile(0.990,1.047,-0.322,0.220,0.086))
    var broken:Array[Vector3]=V4._profile(1.12,1.056,-0.311,0.210,0.075)
    var edges:Array=[1.08,1.23,1.155,1.035,1.13,1.215]
    for i in range(6):
        var v:Vector3=broken[i]
        v.x=float(edges[i])
        broken[i]=v
    stations.append(broken)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    var normals:Array[Vector3]=[
        Vector3(0,0.7,-0.7),Vector3.UP,Vector3(0,0.7,0.7),
        Vector3(0,-0.7,0.7),Vector3.DOWN,Vector3(0,-0.7,-0.7)
    ]
    for j in range(stations.size()-1):
        var a:Array=stations[j]
        var b:Array=stations[j+1]
        for i in range(6):
            var next:int=(i+1)%6
            V4._triangle(t,a[i],b[i],b[next],normals[i])
            V4._triangle(t,a[i],b[next],a[next],normals[i])
    for i in range(1,5):
        V4._triangle(t,stations[0][0],stations[0][i],
            stations[0][i+1],Vector3.LEFT)
        V4._triangle(t,broken[0],broken[i],broken[i+1],Vector3.RIGHT)
    t.generate_normals()
    var n:=MeshInstance3D.new()
    n.name=FRACTURE
    n.mesh=t.commit()
    n.material_override=shell
    parent.add_child(n)
    return n

static func _debris(parent:Node3D,tag:String,points:Array,
        thickness:float,mat:Material)->MeshInstance3D:
    # Convex five-point splinter, enclosed on both sides and five edges.
    # It is separate from the airframe by design, not an open wing hole.
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    var p:Array=[]
    var q:Array=[]
    for v in points:
        p.append(v+Vector3(0,thickness,0))
        q.append(v-Vector3(0,thickness,0))
    for i in range(1,p.size()-1):
        V4._triangle(t,p[0],p[i],p[i+1],Vector3.UP)
        V4._triangle(t,q[0],q[i],q[i+1],Vector3.DOWN)
    for i in range(p.size()):
        var j:int=(i+1)%p.size()
        var e:Vector3=p[j]-p[i]
        var side_normal:=Vector3(e.z,0,-e.x)
        V4._triangle(t,p[i],q[i],q[j],side_normal)
        V4._triangle(t,p[i],q[j],p[j],side_normal)
    t.generate_normals()
    var n:=MeshInstance3D.new()
    n.name=tag
    n.mesh=t.commit()
    n.material_override=mat
    parent.add_child(n)
    return n

static func has_model(root:Node3D)->bool:
    return root!=null and V13.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(FRACTURE,true,false) is MeshInstance3D) and (
        root.find_child(D1_NOSE,true,false) is MeshInstance3D) and (
        root.find_child(D4_SHARD,true,false) is MeshInstance3D)

static func apply(root:Node3D,hero:bool)->bool:
    if root==null or not V13.has_model(root) or not V6.has_model(root) or (
            bool(root.get_meta(FLAG,false))):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    var layers:Array=[]
    for i in range(1,5):
        var layer:=V6._find_layer(root,i)
        if layer==null:
            return false
        layers.append(layer)
    var obsolete:Array=[
        ["A01_V6_D1_PortWingScuff","A01_V6_D1_NoseScuff"],
        ["A01_V6_D2_ScorchedWingRoot","A01_V6_D2_FraggedTrailingPlate"],
        ["A01_V6_D3_BurntTailRoot","A01_V6_D3_BentAccessPanel"],
        ["A01_V6_D4_OpenWingFracture","A01_V6_D4_DetachedCompositeShard",
            "A01_V6_D4_BrokenPropBlade"]
    ]
    var to_hide:Array=[]
    for i in range(4):
        for name in obsolete[i]:
            var old:=layers[i].find_child(str(name),false,false) as MeshInstance3D
            if old==null:
                return false
            to_hide.append(old)
    var swap_names:Array=[
        V4.WING_R,V11.WING_R,V8.FIN_R,V9.PANEL_R,V9.ROOT_R,
        "A01_V4_SolidTrailingFlap_R","A01_V2_NavLightStarboard"
    ]
    var intact:Array=[]
    for name in swap_names:
        var original:=body.find_child(str(name),false,false) as MeshInstance3D
        if original==null or not original.visible:
            return false
        intact.append(original)
    var crest:=body.find_child(V11.CREST,false,false) as MeshInstance3D
    if crest==null or not (crest.material_override is StandardMaterial3D):
        return false
    var faction:Color=(crest.material_override as StandardMaterial3D).albedo_color
    var soot:=_mat(Color("#56636b"),0.13,0.91)
    var burn:=_mat(Color("#343d43"),0.08,0.92)
    var metal:=_mat(Color("#9faeb7"),0.33,0.55)
    var carbon:=_mat(Color("#42525a"),0.17,0.81)
    var gray:=_mat(Color("#bdc9ce"),0.34,0.46)
    _wing_patch(layers[0],D1_WING,-1.0,0.88,1.12,0.28,0.54,hero,soot)
    _body_patch(layers[0],D1_NOSE,-0.95,-0.73,41,66,hero,soot,faction)
    _wing_patch(layers[1],D2_BURN,1.0,0.88,1.14,0.45,0.79,hero,burn)
    _wing_patch(layers[1],D2_PLATE,1.0,1.04,1.23,0.78,0.96,hero,carbon)
    _tail_patch(layers[2],hero,burn)
    _body_patch(layers[2],D3_PANEL,0.52,0.71,48,70,hero,metal,faction)
    var fracture:=_fractured_wing(layers[3],hero,gray)
    if not _finish_fracture(fracture,hero):
        return false
    _debris(layers[3],D4_RIB,[
        Vector3(1.12,1.067,-0.215),Vector3(1.24,1.07,-0.135),
        Vector3(1.17,1.07,-0.025),Vector3(1.18,1.07,0.134),
        Vector3(1.035,1.07,0.177)
    ],0.016,burn)
    _debris(layers[3],D4_SHARD,[
        Vector3(1.42,0.79,-0.19),Vector3(1.61,0.81,-0.13),
        Vector3(1.69,0.83,-0.03),Vector3(1.53,0.80,0.15),
        Vector3(1.38,0.77,0.09)
    ],0.026,metal)
    _debris(layers[3],D4_BLADE,[
        Vector3(-0.24,0.78,1.14),Vector3(-0.09,0.80,1.13),
        Vector3(-0.01,0.78,1.21),Vector3(-0.12,0.78,1.30),
        Vector3(-0.30,0.76,1.27)
    ],0.022,carbon)
    for old in to_hide:
        (old as MeshInstance3D).visible=false
    root.set_meta("tarvoka_a01_v29_substrate_damage",true)
    root.set_meta("tarvoka_a01_v21_conformal_damage",true)
    root.set_meta("tarvoka_a01_v14_intact_wing_nodes",intact)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v14_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v14_visual_only",true)
    # Existing V6 stage API remains the single source of truth.
    return V6.set_stage(root,V6.stage(root)) and has_model(root)
