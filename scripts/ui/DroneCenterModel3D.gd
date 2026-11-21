extends RefCounted
class_name TarvokaDroneCenterModel3D

# New original TARVOKA drone operations center. Replaces ONLY the graphic
# marker for the existing drone_center production site.
# No economy, unit rules, refueling, drone flight or targeting lives here.
# Compact 3D: one MeshInstance3D / four or five material surfaces.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const DISTANT:int=0
const CLOSE:int=1
const NEUTRAL:Color=Color("#939aa0")
const MATERIALS={
    "slab":Color("#879a9d"),
    "steel":Color("#354753"),
    "mark":Color("#d8e3e0")
}
static var _materials:Dictionary={}
static var _meshes:Dictionary={}

static func valid(tier:int,faction:int,damage:int,lod:int) -> bool:
    return tier in [1,2,3] and faction>=-1 and faction<Style.FACTIONS.size() \
        and damage>=0 and damage<=4 and lod in [DISTANT,CLOSE]

static func _mat(kind:String,faction:int) -> StandardMaterial3D:
    var key:String="%s/%d" % [kind,faction]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var material:=StandardMaterial3D.new()
    match kind:
        "faction":
            material.albedo_color=NEUTRAL if faction==-1 else \
                Style.faction_color(faction)
            material.metallic=0.16
            material.roughness=0.52
        "glass":
            material.albedo_color=Color(0.29,0.55,0.64,0.58)
            material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
            material.cull_mode=BaseMaterial3D.CULL_DISABLED
            material.metallic=0.04
            material.roughness=0.19
            material.metallic_specular=0.85
        _:
            material.albedo_color=MATERIALS[kind]
            material.metallic=0.27 if kind=="steel" else 0.03
            material.roughness=0.74
    _materials[key]=material
    return material

static func _box(t:SurfaceTool,center:Vector3,size:Vector3) -> void:
    var lo:Vector3=center-size*0.5
    var hi:Vector3=center+size*0.5
    var a:=Vector3(lo.x,lo.y,lo.z)
    var b:=Vector3(hi.x,lo.y,lo.z)
    var c:=Vector3(lo.x,hi.y,lo.z)
    var d:=Vector3(hi.x,hi.y,lo.z)
    var e:=Vector3(lo.x,lo.y,hi.z)
    var f:=Vector3(hi.x,lo.y,hi.z)
    var g:=Vector3(lo.x,hi.y,hi.z)
    var h:=Vector3(hi.x,hi.y,hi.z)
    for face in [
        [Vector3.FORWARD,[b,a,c,d]],
        [Vector3.BACK,[e,f,h,g]],
        [Vector3.LEFT,[a,e,g,c]],
        [Vector3.RIGHT,[f,b,d,h]],
        [Vector3.UP,[c,g,h,d]],
        [Vector3.DOWN,[a,b,f,e]]
    ]:
        var vertices:Array=face[1]
        for idx in [0,1,2,0,2,3]:
            t.set_normal(face[0])
            t.set_uv(Vector2(float(idx%2),float(idx%3)/2.0))
            t.add_vertex(vertices[idx])

static func _disc(t:SurfaceTool,center:Vector3,radius:float,
        thickness:float,segments:int=18) -> void:
    # Full closed cylinder with top, bottom and radial sides.
    for i in range(segments):
        var a:float=TAU*float(i)/float(segments)
        var b:float=TAU*float(i+1)/float(segments)
        var va:=Vector3(cos(a)*radius,0,sin(a)*radius)
        var vb:=Vector3(cos(b)*radius,0,sin(b)*radius)
        var top:float=center.y+thickness*0.5
        var bottom:float=center.y-thickness*0.5
        for vertex in [
            center+Vector3(0,thickness*0.5,0),
            center+va+Vector3(0,thickness*0.5,0),
            center+vb+Vector3(0,thickness*0.5,0)
        ]:
            t.set_normal(Vector3.UP)
            t.add_vertex(vertex)
        for vertex in [
            center+Vector3(0,-thickness*0.5,0),
            center+vb+Vector3(0,-thickness*0.5,0),
            center+va+Vector3(0,-thickness*0.5,0)
        ]:
            t.set_normal(Vector3.DOWN)
            t.add_vertex(vertex)
        var normal:Vector3=(va+vb).normalized()
        for vertex in [
            Vector3(center.x+va.x,top,center.z+va.z),
            Vector3(center.x+va.x,bottom,center.z+va.z),
            Vector3(center.x+vb.x,bottom,center.z+vb.z),
            Vector3(center.x+va.x,top,center.z+va.z),
            Vector3(center.x+vb.x,bottom,center.z+vb.z),
            Vector3(center.x+vb.x,top,center.z+vb.z)
        ]:
            t.set_normal(normal)
            t.add_vertex(vertex)

static func _base(g:Dictionary,tier:int,damage:int) -> void:
    var slab:SurfaceTool=g["slab"]
    var steel:SurfaceTool=g["steel"]
    var color:SurfaceTool=g["faction"]
    var mark:SurfaceTool=g["mark"]
    # Raised hardstand and drainage: never share airbase long runway.
    _box(slab,Vector3(0,-0.12,0),Vector3(12.9,0.23,12.6))
    _box(steel,Vector3(-2.32,0.035,-0.87),Vector3(6.75,0.12,8.80))
    _box(slab,Vector3(3.45,0.035,1.65),Vector3(5.1,0.13,5.12))
    # Disc landing pad (right), crisp colored ring + H-like quadrotor cross.
    _disc(steel,Vector3(3.45,0.135,1.65),2.05,0.06,24)
    if damage<4:
        _disc(color,Vector3(3.45,0.174,1.65),1.68,0.018,24)
        _disc(steel,Vector3(3.45,0.188,1.65),1.38,0.016,24)
    for side in [-1,1]:
        _box(mark,Vector3(3.45+float(side)*0.28,0.202,1.65),
            Vector3(0.11,0.018,1.25))
    _box(mark,Vector3(3.45,0.202,1.65),Vector3(0.69,0.018,0.09))
    for side in [-1,1]:
        _box(color,Vector3(float(side)*5.65,0.16,1.65),
            Vector3(0.16,0.18,4.8))
    # Vary architecture rather than simply scaling a generic box.
    if damage<4:
        var roof:float=2.52+float(tier-1)*0.27
        _box(slab,Vector3(-2.3,1.28,-1.2),Vector3(6.58,2.52,6.72))
        if damage<3:
            _box(steel,Vector3(-2.3,roof,-1.2),
                Vector3(7.20,0.32,7.05))
            _box(color,Vector3(-2.3,roof+0.19,2.34),
                Vector3(6.84,0.22,0.13))
        else:
            # No pristine roof above exposed broken hangar in critical damage.
            _box(steel,Vector3(-4.40,2.28,-2.85),
                Vector3(2.40,0.22,3.02))
            _box(steel,Vector3(-0.66,2.19,-2.49),
                Vector3(1.25,0.23,2.18))
        # Twin compact service-bay doors for quadcopters, *not* an air runway.
        if damage<3:
            for bay in range(2):
                var bx:float=-3.96+float(bay)*3.33
                _box(steel,Vector3(bx,1.20,2.235),
                    Vector3(2.92,1.84,0.16))
                _box(color,Vector3(bx,2.23,2.36),
                    Vector3(3.05,0.15,0.16))
        else:
            for bay in range(2):
                _box(steel,Vector3(-4.98+float(bay)*3.13,1.3,2.28),
                    Vector3(0.12,2.24,0.14))
        # Tier-2/3 command module grows above left maintenance hangar.
        if tier>=2 and damage<4:
            var height:float=3.63 if tier==2 else 4.45
            _box(slab,Vector3(3.69,1.45,-3.4),
                Vector3(2.28,2.55,2.4))
            if damage<3:
                _box(steel,Vector3(3.69,height-0.48,-3.4),
                    Vector3(2.71,0.58,2.78))
                _box(color,Vector3(3.69,height-0.14,-3.4),
                    Vector3(2.77,0.12,2.78))
            else:
                _box(steel,Vector3(3.69,2.82,-3.4),
                    Vector3(1.31,0.24,2.37))
        # V1 has radar on roof; V2 gains tower; V3 an extra sensor mast.
        if damage<3:
            _box(steel,Vector3(-1.62,roof+0.84,-2.7),
                Vector3(0.18,1.48,0.18))
            _disc(steel,Vector3(-1.62,roof+1.56,-2.7),
                0.79,0.10,16)
            _disc(color,Vector3(-1.62,roof+1.64,-2.7),
                0.27,0.13,12)
            if tier>=3:
                _box(steel,Vector3(5.06,3.31,-4.04),
                    Vector3(0.11,2.83,0.11))
                _box(color,Vector3(5.06,4.76,-4.04),
                    Vector3(0.53,0.12,0.53))
    else:
        # D4 ruins: no intact hangar, glass, operational sensors or command.
        for n in range(8):
            _box(steel,Vector3(-4.94+float(n%4)*1.51,
                0.36+float(n%3)*0.18,-3.2+float(n/4)*2.7),
                Vector3(1.20,0.27,1.07))
        _box(slab,Vector3(-2.80,0.55,-1.0),Vector3(5.4,0.92,3.5))
        _box(color,Vector3(-2.62,0.45,2.38),
            Vector3(2.5,0.14,0.22))
    # Cosmetic damage does NOT implement hit points or attackable buildings.
    if damage>=1:
        for n in range(damage+1):
            _box(steel,Vector3(-5.35+float(n)*0.77,
                0.29,3.02-float(n%2)*0.35),
                Vector3(0.41,0.17,0.41))

static func _close(g:Dictionary,tier:int,damage:int) -> void:
    var slab:SurfaceTool=g["slab"]
    var steel:SurfaceTool=g["steel"]
    var faction:SurfaceTool=g["faction"]
    var mark:SurfaceTool=g["mark"]
    # Side cladding, facade supports and ribbed doors, physical 3D.
    if damage<4:
        var roof:float=2.52+float(tier-1)*0.27
        for side in [-1,1]:
            var x:float=-2.30+float(side)*3.34
            for n in range(5):
                _box(steel,Vector3(x,1.24,-3.75+float(n)*1.30),
                    Vector3(0.10,2.23,0.10))
            _box(faction,Vector3(x+float(side)*0.066,1.64,-1.05),
                Vector3(0.042,0.31,4.90))
        if damage<=2:
            for bay in range(2):
                var bx:float=-3.96+float(bay)*3.33
                for slat in range(4):
                    _box(slab,Vector3(bx,0.50+float(slat)*0.40,2.343),
                        Vector3(2.70,0.07,0.045))
                for side in [-1,1]:
                    _box(steel,Vector3(bx+float(side)*1.46,1.23,2.36),
                        Vector3(0.08,2.06,0.12))
            # Eaves have drainage channels; D2 shows exposed damage.
            for n in range(7):
                if damage==2 and n in [3,4]:
                    continue
                _box(steel,Vector3(-5.36+float(n)*1.02,roof+0.19,-1.18),
                    Vector3(0.06,0.08,6.58))
        else:
            # Never rebuild missing walls in D3.
            for n in range(4):
                _box(steel,Vector3(-5.2+float(n)*1.66,2.43,-1.18),
                    Vector3(0.08,0.15,5.46))
        if tier>=2 and damage<3:
            var cab:float=3.63 if tier==2 else 4.45
            var glass:SurfaceTool=g["glass"]
            _box(glass,Vector3(3.69,cab-0.59,-4.795),
                Vector3(2.18,0.47,0.031))
            _box(glass,Vector3(3.69,cab-0.59,-2.005),
                Vector3(2.18,0.47,0.031))
            for side in [-1,1]:
                _box(glass,Vector3(3.69+float(side)*1.35,
                    cab-0.59,-3.4),
                    Vector3(0.031,0.47,2.05))
                _box(steel,Vector3(3.69+float(side)*1.35,
                    cab-0.59,-4.44),
                    Vector3(0.06,0.62,0.06))
        # D0-D2: a parked static DRONE art detail on the service pad.
        # This is geometry, not a unit, order target or ammunition item.
        if damage<3:
            _disc(steel,Vector3(3.45,0.47,1.65),0.30,0.13,14)
            for side in [-1,1]:
                _box(steel,Vector3(3.45,0.50,1.65),
                    Vector3(2.10,0.06,0.16))
                _box(steel,Vector3(3.45,0.51,1.65),
                    Vector3(0.15,0.06,2.04))
                for other in [-1,1]:
                    _disc(steel,Vector3(3.45+float(side)*0.94,
                        0.54,1.65+float(other)*0.90),
                        0.32,0.06,12)
                    _disc(mark,Vector3(3.45+float(side)*0.94,
                        0.58,1.65+float(other)*0.90),
                        0.19,0.018,12)
            _box(faction,Vector3(3.45,0.60,1.65),
                Vector3(0.41,0.12,0.44))
        # True service paths, lighting stripes and explicit faction paint.
        for side in [-1,1]:
            _box(faction,Vector3(3.45+float(side)*2.45,0.14,1.65),
                Vector3(0.15,0.024,4.65))
        for n in range(5):
            _box(mark,Vector3(0.53,0.14,-0.16+float(n)*0.54),
                Vector3(0.09,0.02,0.25))
        if tier==3 and damage<3:
            _box(faction,Vector3(-2.24,roof+0.32,-4.25),
                Vector3(4.80,0.12,0.13))
            for n in range(3):
                _box(steel,Vector3(-3.44+float(n)*1.25,
                    roof+0.38,0.28),Vector3(0.92,0.09,0.57))
    else:
        # Distinguishable slag and broken frames at D4, not intact drones.
        for n in range(5):
            _box(steel,Vector3(-4.55+float(n)*1.50,
                0.41,1.32+float(n%2)*0.48),
                Vector3(0.75,0.20,0.23))

static func build_mesh(tier:int,faction:int,damage:int,
        lod:int=DISTANT) -> MeshInstance3D:
    if not valid(tier,faction,damage,lod):
        return null
    var key:String="%d/%d/%d/%d" % [tier,faction,damage,lod]
    if not _meshes.has(key):
        var kinds:Array=["slab","steel","faction","mark"]
        if lod==CLOSE and tier>=2 and damage<3:
            kinds.append("glass")
        var tools:Dictionary={}
        for kind in kinds:
            var tool:=SurfaceTool.new()
            tool.begin(Mesh.PRIMITIVE_TRIANGLES)
            tool.set_material(_mat(str(kind),faction))
            tools[kind]=tool
        _base(tools,tier,damage)
        if lod==CLOSE:
            _close(tools,tier,damage)
        var array:=ArrayMesh.new()
        for kind in kinds:
            (tools[kind] as SurfaceTool).commit(array)
        _meshes[key]=array
    var output:=MeshInstance3D.new()
    output.name="CentroDrones3D_Malla"
    output.mesh=_meshes[key] as Mesh
    output.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    output.set_meta("drone_center_native_3d",true)
    output.set_meta("drone_center_lod",lod)
    return output
