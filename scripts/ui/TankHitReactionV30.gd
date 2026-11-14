extends RefCounted
class_name TarvokaTankHitReactionV30

# Two distinctly different, prebuilt reactions, real G09 Godot 3D:
# BULLET: short ricochet and small hot metal sparks / subtle vehicle jolt.
# EXPLOSIVE: bright blast, opaque-to-soft smoke pulse, expanding halo,
#             flying armored fragments and longer recoil.
# No scene allocations during playback and no authoritative HP modifications.
const ROOT := "G09V30ImpactosBalasExplosivos"
const BULLET := "hit_bullet"
const EXPLOSIVE := "hit_explosion"
const BULLET_DURATION := 0.40
const EXPLOSIVE_DURATION := 1.13
static var _flare: ImageTexture
static var _smoke: ImageTexture

static func duration(kind: String) -> float:
    return BULLET_DURATION if kind==BULLET else EXPLOSIVE_DURATION

static func classify_weapon(role: String,weapon: String = "") -> String:
    var w:=weapon.to_lower()
    if "missile" in w or "rocket" in w or "bomb" in w or (
            "explos" in w) or "artillery" in w or "shell" in w:
        return EXPLOSIVE
    return EXPLOSIVE if role in [
        "tank","mlrs","fighter","attack_heli","destroyer",
        "bomber","artillery"] else BULLET

static func _mask(smoky: bool) -> ImageTexture:
    if smoky and _smoke!=null:
        return _smoke
    if not smoky and _flare!=null:
        return _flare
    const SZ := 96
    var img:=Image.create(SZ,SZ,false,Image.FORMAT_RGBA8)
    for y in range(SZ):
        for x in range(SZ):
            var uv:=Vector2(float(x)/95.0-0.5,float(y)/95.0-0.5)
            var r: float = uv.length()*2.0
            var angle: float = atan2(uv.y,uv.x)
            var noise: float = sin(angle*7.0+float(x)*0.12) * cos(angle*11.0+float(y)*0.07)
            var edge: float = clampf((1.0-r+(0.18 if smoky else 0.09)*noise)*3.6,0.0,1.0)
            var alpha: float = edge*edge * (0.70 if smoky else 0.98)
            var rgb := Color(0.24,0.28,0.33,alpha) if smoky else Color(
                1.0,0.71+0.21*(1.0-r),0.24+0.32*(1.0-r),alpha)
            img.set_pixel(x,y,rgb)
    img.generate_mipmaps()
    var texture:=ImageTexture.create_from_image(img)
    if smoky:
        _smoke=texture
    else:
        _flare=texture
    return texture

static func _card(parent: Node3D,name: String,
        at: Vector3,size: Vector2,smoke: bool) -> MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=name
    var quad:=QuadMesh.new()
    quad.size=size
    node.mesh=quad
    var mat:=StandardMaterial3D.new()
    mat.albedo_texture=_mask(smoke)
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    if not smoke:
        mat.emission_enabled=true
        mat.emission=Color("#FFBE62")
        mat.emission_energy_multiplier=0.55
    node.material_override=mat
    node.position=at
    node.visible=false
    node.set_meta("v30_home",at)
    parent.add_child(node)
    return node

static func _streak(parent: Node3D,index: int) -> MeshInstance3D:
    var sprite:=_card(parent,"ChispaBalistica_%d" % index,
        Vector3(0.55,1.11,-0.82),Vector2(0.04,0.23),false)
    sprite.rotation_degrees.z=35.0*float(index)
    return sprite

static func apply(model: Node3D) -> bool:
    if model==null or model.get_meta("tarvoka_hit_v30",false):
        return false
    if not model.get_meta("tarvoka_mbt_track_final_v29",false):
        return false
    var root:=Node3D.new()
    root.name=ROOT
    model.add_child(root)
    for i in range(7):
        _streak(root,i)
    _card(root,"DestelloRicochet",Vector3(0.61,1.09,-0.83),
        Vector2(0.28,0.27),false)
    _card(root,"ExplosionCentral",Vector3(0.58,1.22,-0.59),
        Vector2(1.35,1.30),false)
    _card(root,"OndaExplosiva",Vector3(0.58,1.22,-0.59),
        Vector2(1.65,1.65),false)
    for i in range(4):
        _card(root,"HumoExplosion_%d" % i,
            Vector3(0.30+0.18*float(i),1.36+0.11*float(i),-0.32),
            Vector2(0.68,0.75),true)
    for i in range(6):
        _card(root,"FragmentoExplosion_%d" % i,
            Vector3(0.53,1.13,-0.62),Vector2(0.075,0.18),false)
    model.set_meta("tarvoka_hit_v30",true)
    model.set_meta("tarvoka_hit_v30_type","")
    return true

static func _one(model: Node3D,name: String,visible: bool,
        scale_value: float = 1.0,offset: Vector3 = Vector3.ZERO,
        opacity: float = 1.0) -> void:
    var node: MeshInstance3D = model.find_child(
        name,true,false) as MeshInstance3D
    if node==null:
        return
    node.visible=visible
    node.scale=Vector3.ONE*maxf(0.001,scale_value)
    node.position=(node.get_meta("v30_home",node.position) as Vector3)+offset
    node.transparency=clampf(1.0-opacity,0.0,1.0)

static func pose(model: Node3D,kind: String,t: float) -> void:
    if model==null or not model.get_meta("tarvoka_hit_v30",false):
        return
    t=clampf(t,0.0,1.0)
    var bullet: bool = kind==BULLET
    var explosive: bool = kind==EXPLOSIVE
    var pulse: float = sin(PI*minf(1.0,t*2.15))
    for i in range(7):
        var angle: float = TAU*float(i)/7.0
        var travel: float = 0.08+0.35*t
        _one(model,"ChispaBalistica_%d" % i,
            bullet and t<0.63,0.85-0.52*t,
            Vector3(cos(angle)*travel,sin(angle)*travel,-t*0.13),
            clampf(1.0-t*1.7,0.0,1.0))
    _one(model,"DestelloRicochet",bullet and t<0.32,
        1.0+0.3*t,Vector3.ZERO,1.0-t*2.6)
    _one(model,"ExplosionCentral",explosive and t<0.48,
        0.74+1.12*t,Vector3.ZERO,1.0-t*1.95)
    _one(model,"OndaExplosiva",explosive and t<0.64,
        0.52+2.05*t,Vector3.ZERO,1.0-t*1.4)
    for i in range(4):
        _one(model,"HumoExplosion_%d" % i,
            explosive and t>0.12 and t<0.95,
            0.8+1.08*t,
            Vector3(0.02*float(i),0.49*t+0.12*float(i),0.13*t),
            clampf(0.82-t*0.73,0.0,1.0))
    for i in range(6):
        var a: float = TAU*float(i)/6.0
        _one(model,"FragmentoExplosion_%d" % i,
            explosive and t<0.74,1.0-0.55*t,
            Vector3(cos(a)*0.72*t,0.34*t+sin(a)*0.49*t,-0.31*t),
            1.0-t)
    model.set_meta("tarvoka_hit_v30_type",kind if (bullet or explosive) else "")
    model.set_meta("tarvoka_hit_v30_progress",t)
