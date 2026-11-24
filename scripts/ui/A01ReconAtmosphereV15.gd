extends RefCounted
class_name TarvokaA01ReconAtmosphereV15

# Stylized real 3D effects for the unarmed reconnaissance UAV.
# Each replaces one legacy cone: no new visible draw calls, no alpha
# sorting, particles, per-frame mesh allocation, or changes to gameplay.
const FLAG:String="tarvoka_a01_v15_organic_effects"
const CACHE:String="tarvoka_a01_v15_effect_nodes"
const SMOKE_A:String="A01_V15_D2_RootSmoke"
const SMOKE_B:String="A01_V15_D2_DriftingSmoke"
const FLAME_A:String="A01_V15_D3_EngineFlame"
const FLAME_B:String="A01_V15_D3_SecondaryFlame"
const SMOKE_WRECK:String="A01_V15_D4_WreckSmoke"
const EMBER:String="A01_V15_D4_WreckEmber"

static func _material(flame:bool)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color.WHITE
    m.vertex_color_use_as_albedo=true
    m.roughness=0.92 if not flame else 0.67
    m.metallic=0.0
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    if flame:
        m.emission_enabled=true
        m.emission=Color("#e45c18")
        m.emission_energy_multiplier=0.55
    return m

static func _color(height:float,flame:bool,angle:float)->Color:
    if flame:
        var hot:Color=Color("#fff1a1")
        var amber:Color=Color("#ff9c26")
        var red:Color=Color("#b52e18")
        return hot.lerp(amber,height/0.5) if height<0.5 else amber.lerp(red,(height-0.5)/0.5)
    var dark:Color=Color("#242b31")
    var ash:Color=Color("#77848c")
    return dark.lerp(ash,clampf(0.13+0.67*height+0.11*sin(angle*3.0),0.0,1.0))

static func _face(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        outward:Vector3,flame:bool,maximum:float)->void:
    # Same outward winding convention as the original aircraft airfoil.
    var vertices:Array[Vector3]=[a,b,c]
    if (b-a).cross(c-a).dot(outward)<0.0:
        vertices=[a,c,b]
    for p in vertices:
        t.set_color(_color(clampf(p.y/maximum,0.0,1.0),flame,atan2(p.z,p.x)))
        t.add_vertex(p)

static func _sculpt(parent:Node3D,tag:String,anchor:Vector3,
        radius:float,height:float,flame:bool,hero:bool,
        material:Material,phase:float)->MeshInstance3D:
    # Cross sections widen, constrict and bend, unlike a straight cone.
    # Each end has a real closed cap. Local origin is the physical source
    # so scaling or swaying cannot detach the base from the airframe.
    var count:int=12 if hero else 8
    var profiles:Array=[
        [0.0,0.54,0.0,0.0],
        [0.16,1.0,0.04,0.09],
        [0.34,0.86,0.19,0.13],
        [0.56,1.09 if not flame else 0.67,0.31,0.30],
        [0.79,0.76 if not flame else 0.35,0.48,0.47],
        [1.0,0.24 if not flame else 0.06,0.69,0.65]
    ]
    var rings:Array=[]
    for profile in profiles:
        var ring:Array[Vector3]=[]
        var y:float=height*float(profile[0])
        for i in range(count):
            var angle:float=TAU*float(i)/float(count)
            var r:float=radius*float(profile[1])*(
                1.0+0.12*sin(angle*3.0+phase+y*7.0)+0.07*cos(angle*5.0-y*4.0))
            ring.append(Vector3(radius*float(profile[2])+r*cos(angle),
                y,radius*float(profile[3])+r*sin(angle)))
        rings.append(ring)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(rings.size()-1):
        var lo:Array=rings[j]
        var hi:Array=rings[j+1]
        for i in range(count):
            var next:int=(i+1)%count
            var angle:float=TAU*(float(i)+0.5)/float(count)
            var outward:=Vector3(cos(angle),0,sin(angle))
            _face(t,lo[i],lo[next],hi[next],outward,flame,height)
            _face(t,lo[i],hi[next],hi[i],outward,flame,height)
    var first:Array=rings[0]
    var last:Array=rings[rings.size()-1]
    for i in range(1,count-1):
        _face(t,first[0],first[i],first[i+1],Vector3.DOWN,flame,height)
        _face(t,last[0],last[i],last[i+1],Vector3.UP,flame,height)
    t.index()
    t.generate_normals()
    var node:=MeshInstance3D.new()
    node.name=tag
    node.position=anchor
    node.mesh=t.commit()
    node.material_override=material
    node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(node)
    return node

static func prepare(root:Node3D,rig:Node3D,hero:bool)->bool:
    if root==null or rig==null or bool(root.get_meta(FLAG,false)):
        return false
    var smoke:=_material(false)
    var fire:=_material(true)
    # Anchors in the body coordinate system: lower smoke emerges from
    # the dorsal skin, upper smoke overlaps that first plume. D3 flames
    # sit at the rear shell, D4 adds a broader wreck plume.
    var specs:Array=[
        [2,"A01_V6_SmokePlume_0",SMOKE_A,Vector3(0.16,1.145,0.19),0.082,0.34,false],
        [2,"A01_V6_SmokePlume_1",SMOKE_B,Vector3(0.20,1.39,0.24),0.103,0.33,false],
        [3,"A01_V6_EngineEmber_0",FLAME_A,Vector3(0.0,1.080,0.93),0.087,0.26,true],
        [3,"A01_V6_EngineEmber_1",FLAME_B,Vector3(0.105,1.075,0.87),0.052,0.19,true],
        [4,"A01_V6_D4_ThickSmoke",SMOKE_WRECK,Vector3(-0.10,1.135,0.54),0.148,0.53,false],
        [4,"A01_V6_D4_FinalEmber",EMBER,Vector3(-0.095,1.075,0.66),0.076,0.19,true]
    ]
    var records:Array=[]
    var old_nodes:Array[MeshInstance3D]=[]
    for idx in range(specs.size()):
        var spec:Array=specs[idx]
        var layer:=rig.get_node_or_null("A01_V6_DamageLayer_"+str(spec[0])) as Node3D
        if layer==null:
            return false
        var old:=layer.get_node_or_null(str(spec[1])) as MeshInstance3D
        if old==null:
            return false
        old_nodes.append(old)
    for idx in range(specs.size()):
        var spec:Array=specs[idx]
        var layer:=old_nodes[idx].get_parent() as Node3D
        var is_flame:bool=bool(spec[6])
        var n:=_sculpt(layer,str(spec[2]),spec[3],float(spec[4]),float(spec[5]),
            is_flame,hero,fire if is_flame else smoke,float(idx)*0.87)
        if n.mesh==null:
            return false
        records.append([n,int(spec[0]),is_flame,float(idx)*1.31])
    for old in old_nodes:
        old.visible=false
    root.set_meta(CACHE,records)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v15_lod",13 if hero else 8)
    return reset(root)

static func has_model(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var records:Array=root.get_meta(CACHE,[])
    if records.size()!=6:
        return false
    for record in records:
        if not is_instance_valid(record[0]):
            return false
    return true

static func reset(root:Node3D)->bool:
    if not has_model(root):
        return false
    for record in root.get_meta(CACHE,[]):
        var n:=record[0] as MeshInstance3D
        n.scale=Vector3.ONE
        n.rotation=Vector3.ZERO
    return true

static func animate(root:Node3D,stage:int,clock:float)->bool:
    if root==null or stage<2 or not bool(root.get_meta(FLAG,false)):
        return false
    # Cached references, no scene searches or material/geometry changes.
    for record in root.get_meta(CACHE,[]):
        var n:=record[0] as MeshInstance3D
        if not is_instance_valid(n):
            return false
        if stage<int(record[1]):
            continue
        var flame:bool=bool(record[2])
        var phase:float=float(record[3])
        var t:float=clock*(8.1 if flame else 1.55)+phase
        var pulse:float=sin(t)+0.31*sin(t*1.71+0.4)
        var lateral:float=1.0+(0.065 if flame else 0.045)*pulse
        n.scale=Vector3(lateral,1.0+(0.13 if flame else 0.065)*pulse,lateral)
        n.rotation.y=sin(t*0.71)*0.18
        n.rotation.z=sin(t*0.83)*0.065
    return true
