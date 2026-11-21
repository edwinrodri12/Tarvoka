extends RefCounted
class_name TarvokaNavalBaseTactical3D

# Compact, true native Godot 3D tactical interpretation of the APPROVED
# Naval Base V13 architecture: harbour water, U quays, hangar, command tower,
# real piers, crane, maritime accents and progressive wreckage. The original
# 360-degree V13 HERO model remains untouched in the Art Studio branch.
# No new ships, shipyards, economy values or gameplay changes.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const PROFILE_DISTANT:int=0
const PROFILE_CLOSE:int=1
const NEUTRAL:Color=Color("#849ca6")
const PALETTE={
    "water":Color("#205872"),
    "concrete":Color("#b0bfc1"),
    "metal":Color("#405762")
}
static var _material_cache:Dictionary={}
static var _mesh_cache:Dictionary={}

static func valid(level:int,faction:int,damage:int,detail:int) -> bool:
    return level in [1,2,3] and faction>=-1 and \
        faction<Style.FACTIONS.size() and damage>=0 and damage<=4 and \
        detail in [PROFILE_DISTANT,PROFILE_CLOSE]

static func _material(kind:String,faction:int) -> StandardMaterial3D:
    var key:String="%s/%d" % [kind,faction]
    if _material_cache.has(key):
        return _material_cache[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    if kind=="faction":
        mat.albedo_color=NEUTRAL if faction==-1 else Style.faction_color(faction)
        mat.metallic=0.19
        mat.roughness=0.54
    elif kind=="glass":
        mat.albedo_color=Color(0.23,0.57,0.66,0.65)
        mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.cull_mode=BaseMaterial3D.CULL_DISABLED
        mat.metallic=0.02
        mat.roughness=0.23
    else:
        mat.albedo_color=PALETTE[kind]
        mat.metallic=0.25 if kind=="metal" else 0.04
        mat.roughness=0.80
    _material_cache[key]=mat
    return mat

static func _box(tool:SurfaceTool,center:Vector3,size:Vector3) -> void:
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
    for item in [
        [Vector3.FORWARD,[b,a,c,d]],
        [Vector3.BACK,[e,f,h,g]],
        [Vector3.LEFT,[a,e,g,c]],
        [Vector3.RIGHT,[f,b,d,h]],
        [Vector3.UP,[c,g,h,d]],
        [Vector3.DOWN,[a,b,f,e]]
    ]:
        var vertices:Array=item[1]
        for idx in [0,1,2,0,2,3]:
            tool.set_normal(item[0])
            tool.set_uv(Vector2(float(idx%2),float(idx%3)/2.0))
            tool.add_vertex(vertices[idx])

static func _far(tools:Dictionary,tier:int,damage:int) -> void:
    var water:SurfaceTool=tools["water"]
    var conc:SurfaceTool=tools["concrete"]
    var iron:SurfaceTool=tools["metal"]
    var faction:SurfaceTool=tools["faction"]
    # TRUE open-water berth, not a solid concrete island on a sea tile.
    _box(water,Vector3(0,-0.21,0),Vector3(13.65,0.08,13.65))
    # Original V13 U-shaped twin piers: central water access from +Z.
    for side in [-1,1]:
        _box(conc,Vector3(float(side)*4.40,0.10,0.25),
            Vector3(3.25,0.52,11.90))
        _box(iron,Vector3(float(side)*4.40,0.385,0.25),
            Vector3(3.28,0.08,11.92))
        _box(faction,Vector3(float(side)*2.785,0.423,0.35),
            Vector3(0.15,0.02,9.55))
    _box(conc,Vector3(0,0.15,-5.00),Vector3(11.6,0.64,2.65))
    _box(iron,Vector3(0,0.50,-5.00),Vector3(11.55,0.10,2.64))
    # Harbor command warehouse on the rear seawall.
    if damage<4:
        var roof:float=2.55+0.33*float(tier-1)
        _box(conc,Vector3(-2.25,1.55,-4.88),
            Vector3(5.7,2.1,2.15))
        if damage<3:
            _box(iron,Vector3(-2.25,roof+0.13,-4.86),
                Vector3(6.25,0.35,2.50))
            _box(faction,Vector3(-2.25,roof+0.24,-6.18),
                Vector3(6.20,0.23,0.12))
        else:
            _box(iron,Vector3(-3.15,2.38,-4.98),
                Vector3(2.75,0.18,1.75))
        # Seaward command tower with recognizable bridge.
        var tower:float=3.55+0.52*float(tier-1)
        _box(conc,Vector3(3.70,tower*0.50,-4.68),
            Vector3(1.80,tower,1.92))
        if damage<3:
            _box(iron,Vector3(3.70,tower+0.24,-4.68),
                Vector3(2.60,0.42,2.65))
            _box(faction,Vector3(3.70,tower+0.49,-4.68),
                Vector3(2.55,0.15,2.68))
        # Maritime portal in the rear facing the basin.
        if damage<2:
            _box(iron,Vector3(-2.25,1.39,-3.75),
                Vector3(3.66,1.72,0.13))
            _box(faction,Vector3(-2.25,2.30,-3.85),
                Vector3(4.22,0.17,0.16))
        if damage<3:
            # Gantry arm facing the actual marine basin, no collision.
            _box(iron,Vector3(-4.48,2.75,0.15),
                Vector3(0.18,4.40,0.20))
            _box(iron,Vector3(-2.60,4.81,0.15),
                Vector3(3.95,0.18,0.21))
            _box(faction,Vector3(-0.88,4.85,0.15),
                Vector3(0.35,0.24,0.30))
    else:
        # D4 is rubble: no clean hangar, intact tower or operational crane.
        for i in range(5):
            _box(conc,Vector3(-4.0+float(i)*1.66,
                0.37+float(i%2)*0.14,-4.88),
                Vector3(1.00,0.52,1.06))
            _box(iron,Vector3(-4.2+float(i)*1.35,
                0.35,-3.62+float(i%2)*0.36),
                Vector3(0.91,0.16,0.42))
        _box(faction,Vector3(0,0.42,-5.20),
            Vector3(1.4,0.06,0.19))
    # D2-D4 progressive material loss without fabricated building HP.
    if damage>=2:
        for i in range(damage):
            _box(iron,Vector3(-5.1+float(i)*0.77,
                0.29,3.55-float(i)*0.52),
                Vector3(0.68,0.16,0.45))

static func _close(tools:Dictionary,tier:int,damage:int) -> void:
    var conc:SurfaceTool=tools["concrete"]
    var iron:SurfaceTool=tools["metal"]
    var mark:SurfaceTool=tools["faction"]
    # V13 approval preserved as a reference; this is a baked mobile LOD.
    for side in [-1,1]:
        var sx:float=float(side)*3.07
        for segment in range(8):
            _box(iron,Vector3(sx,0.45,-4.6+float(segment)*1.35),
                Vector3(0.16,0.19,0.50))
        # Fender pairs anchored to the piers, not floating above water.
        for i in range(5):
            var z:float=-4.40+float(i)*2.03
            _box(iron,Vector3(sx,0.09,z),
                Vector3(0.34,0.44,0.65))
        if damage<4:
            for i in range(4):
                _box(mark,Vector3(float(side)*4.4,
                    0.44,-3.7+float(i)*2.15),
                    Vector3(2.25,0.035,0.16))
    if damage==4:
        for i in range(6):
            _box(iron,Vector3(-5.5+float(i)*1.90,
                0.28,3.0+float(i%2)*0.49),
                Vector3(0.71,0.15,0.43))
        return
    var roof:float=2.55+0.33*float(tier-1)
    var tower:float=3.55+0.52*float(tier-1)
    if damage<=2:
        # Hangar door ribs and coated sidewalls, left clear for boarding.
        for rib in range(4):
            _box(iron,Vector3(-4.71+float(rib)*1.64,
                1.31,-3.77),Vector3(0.09,1.81,0.12))
        for stripe in range(3):
            _box(iron,Vector3(-2.25,0.74+float(stripe)*0.48,
                -3.68),Vector3(3.68,0.055,0.06))
        for support in range(6):
            _box(iron,Vector3(-5.03+float(support)*1.10,
                roof+0.37,-4.86),
                Vector3(0.065,0.19,2.31))
    else:
        # D3 exposed hangar girder and shattered roof segments.
        for beam in range(5):
            _box(iron,Vector3(-5.0+float(beam)*1.18,
                2.77,-4.86),
                Vector3(0.10,0.16,2.03))
    # V13 inspection: small berth bollards, readable maritime warnings.
    for side in [-1,1]:
        for i in range(5):
            var z:float=-3.95+float(i)*1.79
            _box(iron,Vector3(float(side)*5.55,0.59,z),
                Vector3(0.20,0.29,0.28))
            if damage<3:
                _box(mark,Vector3(float(side)*5.55,0.75,z),
                    Vector3(0.20,0.05,0.28))
    if damage<3:
        # V13 panoramic cab glass is thin, translucent and framed.
        var glass:SurfaceTool=tools["glass"]
        _box(glass,Vector3(3.70,tower+0.23,-6.016),
            Vector3(2.03,0.39,0.031))
        _box(glass,Vector3(3.70,tower+0.23,-3.343),
            Vector3(2.03,0.39,0.031))
        for side in [-1,1]:
            _box(glass,Vector3(3.70+float(side)*1.32,
                tower+0.23,-4.68),Vector3(0.031,0.39,2.21))
            for i in [0,1]:
                _box(iron,Vector3(3.70+float(side)*1.16,
                    tower+0.23,-5.96+float(i)*2.56),
                    Vector3(0.07,0.48,0.065))
        _box(iron,Vector3(3.70,tower+0.71,-4.68),
            Vector3(0.10,0.66,0.10))
        _box(mark,Vector3(3.70,tower+1.09,-4.68),
            Vector3(0.50,0.14,0.50))
    # Crane service markings visible on each approved faction.
    if damage<3:
        for i in range(5):
            _box(mark,Vector3(-4.48,1.01+float(i)*0.57,
                0.33),Vector3(0.16,0.13,0.08))

static func build_proxy(level:int,faction:int,damage:int,
        detail:int=PROFILE_DISTANT) -> MeshInstance3D:
    if not valid(level,faction,damage,detail):
        return null
    var key:String="%d/%d/%d/%d" % [level,faction,damage,detail]
    if not _mesh_cache.has(key):
        var names:Array=["water","concrete","metal","faction"]
        if detail==PROFILE_CLOSE and damage<3:
            names.append("glass")
        var groups:Dictionary={}
        for name in names:
            var tool:=SurfaceTool.new()
            tool.begin(Mesh.PRIMITIVE_TRIANGLES)
            tool.set_material(_material(name,faction))
            groups[name]=tool
        _far(groups,level,damage)
        if detail==PROFILE_CLOSE:
            _close(groups,level,damage)
        var geometry:=ArrayMesh.new()
        for name in names:
            (groups[name] as SurfaceTool).commit(geometry)
        _mesh_cache[key]=geometry
    var mesh:=MeshInstance3D.new()
    mesh.name="BaseNaval3D_Compacta"
    mesh.mesh=_mesh_cache[key] as Mesh
    mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mesh.set_meta("naval_visual_profile",detail)
    mesh.set_meta("visual_level",level)
    mesh.set_meta("visual_faction",faction)
    mesh.set_meta("visual_damage_stage",damage)
    return mesh
