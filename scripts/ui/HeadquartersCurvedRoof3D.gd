extends RefCounted
class_name TarvokaHeadquartersCurvedRoof3D

# Authored from the APPROVED HQ V13 tactical arch silhouette. This is a
# native 3D extrusion (not a picture/planar decorative sprite).
# Three shared material surfaces. No retained hero nodes on Android.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const NAME:String="CubiertasCurvasTacticasV25"
static var _geometry_cache:Dictionary={}
static var _material_cache:Dictionary={}

static func _material(kind:String,faction:int) -> StandardMaterial3D:
    var key:String="%s/%d" % [kind,faction]
    if _material_cache.has(key):
        return _material_cache[key] as StandardMaterial3D
    var m:=StandardMaterial3D.new()
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.metallic=0.16 if kind!="concrete" else 0.05
    m.roughness=0.74 if kind!="concrete" else 0.9
    var accent:Color=Color("#87949c") if faction<0 else Style.faction_color(faction)
    match kind:
        "roof":
            m.albedo_color=Color("#2b4350")
        "concrete":
            m.albedo_color=Color("#aabbb9")
        "paint":
            m.albedo_color=accent if faction>=0 else accent.darkened(0.15)
    _material_cache[key]=m
    return m

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3) -> void:
    for v in [a,b,c]:
        st.set_uv(Vector2(v.x*0.11+0.5,v.z*0.11+v.y*0.09))
        st.add_vertex(v)

static func _curve(st:SurfaceTool,x_center:float,half:float,
        height:float,rise:float,z_front:float,depth:float,
        thickness:float,segments:int=10) -> void:
    # Closed six-face segmented extrusion, not a two-sided flat plane.
    for i in range(segments):
        var t0:float=float(i)/float(segments)
        var t1:float=float(i+1)/float(segments)
        var x0:float=x_center+(2.0*t0-1.0)*half
        var x1:float=x_center+(2.0*t1-1.0)*half
        var y0:float=height+rise*sqrt(maxf(0.0,1.0-pow(2.0*t0-1.0,2.0)))
        var y1:float=height+rise*sqrt(maxf(0.0,1.0-pow(2.0*t1-1.0,2.0)))
        var a:=Vector3(x0,y0,z_front)
        var b:=Vector3(x1,y1,z_front)
        var c:=Vector3(x0,y0-thickness,z_front)
        var d:=Vector3(x1,y1-thickness,z_front)
        var offset:=Vector3(0,0,depth)
        var e:Vector3=a+offset
        var f:Vector3=b+offset
        var g:Vector3=c+offset
        var h:Vector3=d+offset
        _tri(st,a,b,f)
        _tri(st,a,f,e)
        _tri(st,c,g,h)
        _tri(st,c,h,d)
        _tri(st,c,d,b)
        _tri(st,c,b,a)
        _tri(st,e,f,h)
        _tri(st,e,h,g)
        if i==0:
            _tri(st,a,e,g)
            _tri(st,a,g,c)
        if i==segments-1:
            _tri(st,b,d,h)
            _tri(st,b,h,f)

static func _mesh(level:int,faction:int,damage:int) -> ArrayMesh:
    var key:String="%d/%d/%d" % [level,faction,damage]
    if _geometry_cache.has(key):
        return _geometry_cache[key] as ArrayMesh
    var roof:=SurfaceTool.new()
    var concrete:=SurfaceTool.new()
    var paint:=SurfaceTool.new()
    for surface in [roof,concrete,paint]:
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var y:float=2.87+0.91*float(level-1)
    if damage==4:
        # All main roofs are GONE; retain only partial arch debris.
        _curve(roof,-1.9,0.75,0.42,0.14,-3.99,0.16,0.12,6)
        _curve(concrete,1.70,0.42,0.25,0.08,-3.42,0.19,0.09,6)
        _curve(paint,0.10,0.48,0.29,0.07,-4.19,0.10,0.07,6)
    else:
        for side in [-1,1]:
            # D3: west wing collapsed rather than restoring its roof.
            if damage==3 and side==-1:
                continue
            var x:float=float(side)*4.03
            _curve(roof,x,1.24,3.01,0.54,-2.86,0.65,0.30)
            _curve(concrete,x,1.17,3.14,0.49,-2.98,0.28,0.17)
            if damage<2 or side==1:
                _curve(paint,x,1.08,3.30,0.42,-3.025,0.14,0.10)
            else:
                # A shorter paint segment explicitly marks D2 damage.
                _curve(paint,x-0.46,0.52,3.28,0.30,-3.025,0.14,0.10,6)
        # Central arch remains until ruins. D3 leaves its frame intact,
        # with damage represented by the underlying building and missing wing.
        _curve(roof,0,1.90,y+2.34,0.50,-2.71,0.66,0.30)
        _curve(concrete,0,1.80,y+2.47,0.43,-2.78,0.22,0.15)
        _curve(paint,0,1.71,y+2.59,0.38,-2.81,0.095,0.09)
        if damage>=1:
            _curve(concrete,-4.19,0.25,2.92,0.15,-3.12,0.14,0.10,6)
    var mesh:=ArrayMesh.new()
    for data in [
            [roof,_material("roof",faction)],
            [concrete,_material("concrete",faction)],
            [paint,_material("paint",faction)]]:
        var st:SurfaceTool=data[0]
        st.set_material(data[1])
        st.generate_normals()
        st.commit(mesh)
    _geometry_cache[key]=mesh
    return mesh

static func build(level:int,faction:int,damage:int) -> MeshInstance3D:
    if level<1 or level>3 or faction< -1 or faction>7 or damage<0 or damage>4:
        return null
    var result:=MeshInstance3D.new()
    result.name=NAME
    result.mesh=_mesh(level,faction,damage)
    result.set_meta("native_curved_extrusions",true)
    result.set_meta("visual_damage_stage",damage)
    result.set_meta("surfaces",result.mesh.get_surface_count())
    return result
