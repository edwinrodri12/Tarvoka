extends RefCounted
class_name TarvokaHeadquartersBattleAccents3D

# Shared single-mesh finish for the REAL 3D HQ battle building.
# Roof faction panels, proper dark glazing, control-room entrance,
# air/exhaust grilles and antenna signal housings remain solid 3D geometry.
# This never changes tactical state and adds no independent site.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const NAME:String="AcabadosMilitaresNativosV25"
const KEYS:=["accent","glass","steel","trim"]
static var _meshes:Dictionary={}
static var _materials:Dictionary={}

static func _mat(key:String,faction:int) -> StandardMaterial3D:
    var id:String="%s/%d" % [key,faction]
    if _materials.has(id):
        return _materials[id] as StandardMaterial3D
    var material:=StandardMaterial3D.new()
    var accent:Color=Color("#6c828d") if faction<0 else Style.faction_color(faction)
    match key:
        "accent":
            material.albedo_color=accent.darkened(0.08)
            material.metallic=0.31
            material.roughness=0.51
        "glass":
            material.albedo_color=Color("#35677f")
            material.metallic=0.37
            material.roughness=0.23
        "steel":
            material.albedo_color=Color("#253e4a")
            material.metallic=0.39
            material.roughness=0.52
        "trim":
            material.albedo_color=Color("#bccbd1")
            material.metallic=0.23
            material.roughness=0.48
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    _materials[id]=material
    return material

static func _box(st:SurfaceTool,center:Vector3,size:Vector3) -> void:
    # Six closed faces, normals and shared UVs to avoid transparent walls.
    var a:Vector3=center-size*0.5
    var b:Vector3=center+size*0.5
    var p000:=Vector3(a.x,a.y,a.z)
    var p001:=Vector3(a.x,a.y,b.z)
    var p010:=Vector3(a.x,b.y,a.z)
    var p011:=Vector3(a.x,b.y,b.z)
    var p100:=Vector3(b.x,a.y,a.z)
    var p101:=Vector3(b.x,a.y,b.z)
    var p110:=Vector3(b.x,b.y,a.z)
    var p111:=Vector3(b.x,b.y,b.z)
    var faces:Array=[
        [Vector3.FORWARD,[p100,p000,p010,p110]],
        [Vector3.BACK,[p001,p101,p111,p011]],
        [Vector3.LEFT,[p000,p001,p011,p010]],
        [Vector3.RIGHT,[p101,p100,p110,p111]],
        [Vector3.UP,[p010,p011,p111,p110]],
        [Vector3.DOWN,[p100,p101,p001,p000]]]
    var uv:Array[Vector2]=[Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]
    for face in faces:
        for k in [0,1,2,0,2,3]:
            st.set_normal(face[0])
            st.set_uv(uv[k])
            st.add_vertex(face[1][k])

static func _mesh(level:int,faction:int,damage:int) -> ArrayMesh:
    var key:String="%d/%d/%d" % [level,faction,damage]
    if _meshes.has(key):
        return _meshes[key] as ArrayMesh
    var surfaces:Dictionary={}
    for kind in KEYS:
        var st:=SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        surfaces[kind]=st
    var accent:SurfaceTool=surfaces["accent"]
    var glass:SurfaceTool=surfaces["glass"]
    var steel:SurfaceTool=surfaces["steel"]
    var trim:SurfaceTool=surfaces["trim"]
    var y:float=2.87+0.91*float(level-1)
    if damage==4:
        # Collapsed materials retain no intact glazing or antenna; last
        # colored metal panels sit among fallen concrete pieces.
        _box(steel,Vector3(-2.30,0.27,-2.40),Vector3(1.18,0.16,0.48))
        _box(steel,Vector3(1.75,0.25,-1.80),Vector3(0.82,0.17,1.10))
        _box(trim,Vector3(2.15,0.19,1.45),Vector3(0.64,0.10,0.35))
        _box(accent,Vector3(1.55,0.38,-3.68),Vector3(1.30,0.10,0.83))
    else:
        # Two large roof inset panels: color reads from battle-zoom without
        # repainting all load-bearing concrete. D3 west wing is gone.
        for side in [-1,1]:
            if damage>=3 and side==-1:
                continue
            var x:float=float(side)*4.06
            _box(steel,Vector3(x,2.57,0.48),
                Vector3(2.11,0.10,3.38))
            _box(accent,Vector3(x,2.635,0.48),
                Vector3(1.67,0.040,2.83))
            # Three front windows each supported by real dark metal frames.
            for window_id in range(3):
                if damage>=2 and window_id==0 and side==-1:
                    continue
                var wx:float=x-0.68+float(window_id)*0.68
                _box(steel,Vector3(wx,1.35,-2.04),
                    Vector3(0.56,0.70,0.12))
                _box(glass,Vector3(wx,1.35,-2.115),
                    Vector3(0.43,0.55,0.045))
            _box(accent,Vector3(x,2.35,-2.15),
                Vector3(2.10,0.29,0.13))
            _box(trim,Vector3(x,0.41,-2.15),
                Vector3(2.10,0.075,0.14))
        # Reinforced entrance/gate with deep frame and reflective glass.
        _box(steel,Vector3(0,1.29,-3.99),Vector3(2.16,2.25,0.23))
        if damage<=1:
            _box(glass,Vector3(0,1.30,-4.119),Vector3(1.65,1.84,0.055))
            _box(trim,Vector3(0,1.30,-4.17),Vector3(0.085,1.83,0.07))
        elif damage==2:
            _box(glass,Vector3(-0.43,1.28,-4.12),
                Vector3(0.62,1.27,0.05))
        # Prominent front-color crest backing and command parapet.
        _box(accent,Vector3(0,y+0.78,-3.48),
            Vector3(2.45,1.13,0.14))
        _box(trim,Vector3(0,y+1.43,-3.54),
            Vector3(3.05,0.10,0.17))
        _box(steel,Vector3(0,y+1.77,-2.06),
            Vector3(3.06,0.09,1.85))
        _box(accent,Vector3(0,y+1.83,-2.06),
            Vector3(2.43,0.055,1.31))
        # Accessible armored gate / steps at the forward platform.
        for step in range(3):
            _box(trim,Vector3(0,0.14+float(step)*0.085,
                -5.43+float(step)*0.32),
                Vector3(1.76-float(step)*0.18,0.085,0.40))
        if damage<=2:
            # T3 roof sensor housings: only architecture, never weapon stats.
            _box(steel,Vector3(1.69,y+2.21,1.45),
                Vector3(0.88,0.33,0.94))
            _box(accent,Vector3(1.69,y+2.42,1.45),
                Vector3(1.02,0.10,1.06))
            if level>=2:
                _box(steel,Vector3(-4.55,4.90+float(level-1)*0.46,
                    1.38),Vector3(0.82,0.20,0.82))
                _box(accent,Vector3(-4.55,5.05+float(level-1)*0.46,
                    1.38),Vector3(0.98,0.14,0.98))
            if level==3:
                # Upper roof exhaust vents make level 3 distinct in zoom.
                for x in [-0.90,0.90]:
                    _box(steel,Vector3(x,y+1.99,0.82),
                        Vector3(0.57,0.31,0.81))
                    _box(trim,Vector3(x,y+2.17,0.82),
                        Vector3(0.62,0.07,0.88))
    var mesh:=ArrayMesh.new()
    for kind in KEYS:
        var st:SurfaceTool=surfaces[kind]
        st.set_material(_mat(kind,faction))
        st.commit(mesh)
    _meshes[key]=mesh
    return mesh

static func build(level:int,faction:int,damage:int) -> MeshInstance3D:
    if level<1 or level>3 or faction< -1 or faction>7 or damage<0 or damage>4:
        return null
    var result:=MeshInstance3D.new()
    result.name=NAME
    result.mesh=_mesh(level,faction,damage)
    result.set_meta("surface_count",result.mesh.get_surface_count())
    result.set_meta("solid_architecture",true)
    return result
