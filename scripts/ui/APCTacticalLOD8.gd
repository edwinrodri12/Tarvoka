extends RefCounted
class_name TarvokaAPCTacticalLOD8

# P06 V8 tactical/mobile mesh: SAME V1 armored 6x6 hull silhouette as hero V7.
# Six real wheels are TWO MultiMesh draws, never six boxes or anonymous discs.
# Separate studio V7 retains the full interior, damage and muzzle VFX.
# This is visual only: gameplay units, fog, movement, ammo and HP do not change.
const Sculpt = preload("res://scripts/ui/APCArtV1.gd")
const FLAG := "tarvoka_apc_tactical_lod_v8"
const ROOT := "P06V8_BastionTactico6x6"
const WHEELS := "P06V8_SeisRuedasInstanciadas"
const HUBS := "P06V8_SeisBujesInstanciados"
const TURRET := "P06V8_TorretaRemota"
const GUN := "P06V8_ArmaEstabilizada"
const RAMP := "P06V8_RampaTropas"
const BASE := "tarvoka_apc_lod8_rest"
const LAST := "tarvoka_apc_lod8_last_pose"
const WHEEL_TURNS := TAU*1.7
const MAX_DRAW_SURFACES := 15
# Same native hull silhouette for every tier, only visibility of small
# glass/hubs changes. Pixel-height thresholds work for orthographic as well
# as perspective camera without inventing fixed geographic distances.
const LOD_NEAR := 0
const LOD_MEDIUM := 1
const LOD_FAR := 2
const LOD_META := "tarvoka_apc_v9_distance_tier"
const VISUAL_HEIGHT := 2.15
const HUB_HOME := 0.145
const TIRES_HOME := 0.0
const TURN_DEGREES := 14.0
const BUMP_AMPLITUDE := 0.025
static var _wheel_mesh: CylinderMesh
static var _hub_mesh: Mesh
static var _wheel_mat: StandardMaterial3D
static var _hub_mat: StandardMaterial3D
static var _black_mat: StandardMaterial3D
static var _glass_mat: StandardMaterial3D
static var _cached_armor: Dictionary = {}

static func _color(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _add_face(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _spoked_hub() -> ArrayMesh:
    # One 3D surface with a real disc, recessed rim and five raised radial
    # spokes on BOTH outward faces. Six instances remain exactly one draw.
    # A uniform CylinderMesh looks stationary even when its transform spins.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var radius: float=0.218
    var half: float=0.010
    for seg in range(20):
        var a: float=TAU*float(seg)/20.0
        var b: float=TAU*float(seg+1)/20.0
        var top_a:=Vector3(radius*cos(a),half,radius*sin(a))
        var top_b:=Vector3(radius*cos(b),half,radius*sin(b))
        var bot_a:=Vector3(radius*cos(a),-half,radius*sin(a))
        var bot_b:=Vector3(radius*cos(b),-half,radius*sin(b))
        st.add_vertex(Vector3(0,half,0))
        st.add_vertex(top_b)
        st.add_vertex(top_a)
        st.add_vertex(Vector3(0,-half,0))
        st.add_vertex(bot_a)
        st.add_vertex(bot_b)
        _add_face(st,top_a,top_b,bot_b,bot_a)
    for side in [-1,1]:
        var sign: float=float(side)
        var inner_y: float=sign*0.011
        var raised_y: float=sign*0.031
        for spoke in range(5):
            var a: float=TAU*float(spoke)/5.0
            var out:=Vector2(cos(a),sin(a))
            var across:=Vector2(-sin(a),cos(a))
            var p0: Vector2=out*0.060+across*0.021
            var p1: Vector2=out*0.198+across*0.021
            var p2: Vector2=out*0.198-across*0.021
            var p3: Vector2=out*0.060-across*0.021
            var front: Array[Vector3]=[
                Vector3(p0.x,raised_y,p0.y),
                Vector3(p1.x,raised_y,p1.y),
                Vector3(p2.x,raised_y,p2.y),
                Vector3(p3.x,raised_y,p3.y)]
            var back: Array[Vector3]=[
                Vector3(p0.x,inner_y,p0.y),
                Vector3(p1.x,inner_y,p1.y),
                Vector3(p2.x,inner_y,p2.y),
                Vector3(p3.x,inner_y,p3.y)]
            _add_face(st,front[0],front[1],front[2],front[3])
            for side_index in range(4):
                var nxt: int=(side_index+1)%4
                _add_face(st,back[side_index],back[nxt],
                    front[nxt],front[side_index])
    st.generate_normals()
    return st.commit()

static func _resources() -> void:
    if _wheel_mesh!=null:
        return
    _wheel_mesh=CylinderMesh.new()
    _wheel_mesh.top_radius=Sculpt.WHEEL_RADIUS
    _wheel_mesh.bottom_radius=Sculpt.WHEEL_RADIUS
    _wheel_mesh.height=0.235
    _wheel_mesh.radial_segments=14
    _hub_mesh=_spoked_hub()
    _wheel_mat=_color(Color("#252a2c"),0.05,0.95)
    _hub_mat=_color(Color("#566168"),0.55,0.73)
    _black_mat=_color(Color("#1d282e"),0.16,0.86)
    _glass_mat=_color(Color("#406c81"),0.08,0.26)

static func _armor_material(faction_color: Color) -> StandardMaterial3D:
    # Official faction paint is isolated per faction; tires and hubs are
    # shared across models but never recolored or mutated in place.
    var key: String=faction_color.to_html()
    if not _cached_armor.has(key):
        _cached_armor[key]=_color(
            Color("#526166").lerp(faction_color,0.52),0.31,0.83)
    return _cached_armor[key] as StandardMaterial3D

static func _box(parent: Node3D,label: String,pos: Vector3,
        size: Vector3,material: Material) -> MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=label
    var cube:=BoxMesh.new()
    cube.size=size
    part.mesh=cube
    part.material_override=material
    part.position=pos
    parent.add_child(part)
    return part

static func _wheels(parent: Node3D,label: String,mesh: Mesh,
        mat: Material,hub_offset: float=0.0) -> MultiMeshInstance3D:
    var renderer:=MultiMeshInstance3D.new()
    renderer.name=label
    var instances:=MultiMesh.new()
    instances.transform_format=MultiMesh.TRANSFORM_3D
    instances.mesh=mesh
    instances.instance_count=6
    for side_index in range(2):
        var side: float=-1.0 if side_index==0 else 1.0
        for axle in range(3):
            var i: int=side_index*3+axle
            var pos:=Vector3(side*(Sculpt.WHEEL_X+hub_offset),
                Sculpt.WHEEL_RADIUS+0.08,float(Sculpt.WHEEL_Z[axle]))
            instances.set_instance_transform(i,Transform3D(
                Basis(Vector3.FORWARD,PI/2.0),pos))
    renderer.multimesh=instances
    renderer.material_override=mat
    parent.add_child(renderer)
    return renderer

static func build(model: Node3D, faction_color: Color) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)):
        return false
    _resources()
    var root:=Node3D.new()
    root.name=ROOT
    model.add_child(root)
    var armor: Material=_armor_material(faction_color)
    # Identical five-cross-section welded nose, roof and rear cross section
    # used by the highly detailed version, not a generic APC cuboid.
    Sculpt._hull(root,armor)
    var tires: MultiMeshInstance3D=_wheels(root,WHEELS,_wheel_mesh,_wheel_mat)
    _wheels(root,HUBS,_hub_mesh,_hub_mat,0.145)
    for side in [-1,1]:
        var x: float=float(side)
        _box(root,"P06V8_FaldonLateral_%d" % side,
            Vector3(x*0.755,0.99,0.04),Vector3(0.083,0.13,2.10),
            armor)
        _box(root,"P06V8_VisorConductor_%d" % side,
            Vector3(x*0.255,1.235,-1.035),Vector3(0.27,0.074,0.040),
            _glass_mat)
    _box(root,RAMP,Vector3(0,0.82,1.39),
        Vector3(0.95,0.61,0.068),armor)
    var remote:=Node3D.new()
    remote.name=TURRET
    remote.position=Vector3(0,1.53,-0.16)
    root.add_child(remote)
    var base_cylinder:=CylinderMesh.new()
    base_cylinder.top_radius=0.28
    base_cylinder.bottom_radius=0.28
    base_cylinder.height=0.073
    base_cylinder.radial_segments=12
    Sculpt._part(remote,"P06V8_AnilloTorreta",base_cylinder,
        _black_mat)
    _box(remote,"P06V8_CorazaTorreta",Vector3(0,0.205,0),
        Vector3(0.44,0.31,0.50),armor)
    _box(remote,"P06V8_OpticaTorreta",
        Vector3(0.27,0.27,-0.235),Vector3(0.12,0.10,0.06),
        _glass_mat)
    var gun:=Node3D.new()
    gun.name=GUN
    gun.position=Vector3(-0.02,0.20,-0.27)
    remote.add_child(gun)
    var barrel:=CylinderMesh.new()
    barrel.top_radius=0.048
    barrel.bottom_radius=0.048
    barrel.height=0.53
    barrel.radial_segments=10
    Sculpt._part(gun,"P06V8_CanonCorto",
        barrel,_black_mat,Vector3(0,0,-0.30),Vector3(90,0,0))
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_apc_lod8_wheel_count",6)
    model.set_meta("tarvoka_apc_lod8_faction_color",faction_color)
    model.set_meta("tarvoka_apc_lod8_render_surfaces",draw_surfaces(model))
    model.set_meta(BASE,model.position)
    model.set_meta(LOD_META,LOD_NEAR)
    return tires.multimesh.instance_count==6

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func draw_surfaces(model: Node3D) -> int:
    if model==null:
        return 0
    var count: int=0
    for node in model.find_children("*","MeshInstance3D",true,false):
        count+=1
    for node in model.find_children("*","MultiMeshInstance3D",true,false):
        count+=1
    return count

static func detail_tier(model: Node3D) -> int:
    if not has_model(model):
        return LOD_FAR
    return clampi(int(model.get_meta(LOD_META,LOD_NEAR)),LOD_NEAR,LOD_FAR)

static func tier_from_pixels(pixel_height: float,old_tier: int=-1) -> int:
    # 15% hysteresis avoids shimmering when a mobile user pinch-zooms.
    if old_tier==LOD_NEAR and pixel_height>=115.0:
        return LOD_NEAR
    if old_tier==LOD_FAR and pixel_height<65.0:
        return LOD_FAR
    if old_tier==LOD_MEDIUM:
        if pixel_height>=145.0:
            return LOD_NEAR
        if pixel_height>=48.0:
            return LOD_MEDIUM
        return LOD_FAR
    if pixel_height>=130.0:
        return LOD_NEAR
    if pixel_height>=55.0:
        return LOD_MEDIUM
    return LOD_FAR

static func set_detail(model: Node3D,tier: int) -> bool:
    if not has_model(model):
        return false
    var level: int=clampi(tier,LOD_NEAR,LOD_FAR)
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    if root==null:
        return false
    # NEVER hide the five-section hull, six tires, turret outline, cannon,
    # rear door or faction paint; avoid 2D impostors and silhouette popping.
    var hub: Node3D=root.find_child(HUBS,false,false) as Node3D
    if hub!=null:
        hub.visible=level<=LOD_MEDIUM
    var optic: Node3D=root.find_child(
        "P06V8_OpticaTorreta",true,false) as Node3D
    if optic!=null:
        optic.visible=level==LOD_NEAR
    for side in [-1,1]:
        var glass: Node3D=root.find_child(
            "P06V8_VisorConductor_%d" % side,false,false) as Node3D
        if glass!=null:
            glass.visible=level<=LOD_MEDIUM
    model.set_meta(LOD_META,level)
    return true

static func set_detail_from_pixels(model: Node3D,pixel_height: float) -> bool:
    if not has_model(model):
        return false
    var current: int=detail_tier(model)
    var desired: int=tier_from_pixels(pixel_height,current)
    if desired==current:
        return true
    return set_detail(model,desired)

static func visible_surfaces(model: Node3D) -> int:
    if not has_model(model):
        return 0
    var count: int=0
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    if root==null:
        return 0
    for piece in root.find_children("*","MeshInstance3D",true,false):
        var item: Node3D=piece as Node3D
        var visible: bool=item.visible
        var parent: Node=item.get_parent()
        while visible and parent!=root and parent!=null:
            if parent is Node3D and not (parent as Node3D).visible:
                visible=false
            parent=parent.get_parent()
        if visible:
            count+=1
    for piece in root.find_children("*","MultiMeshInstance3D",true,false):
        if (piece as Node3D).visible:
            count+=1
    return count

static func _wheel_transform(side: float,axle: int,travel: float,
        steering: float,offset: float) -> Transform3D:
    var yaw: float=steering if axle==0 else 0.0
    # Rotate about physical cylinder axle and yaw only the front pair.
    var wheel_axis: Basis=Basis(Vector3.FORWARD,PI/2.0)
    var pose_basis: Basis=Basis(Vector3.UP,yaw)*wheel_axis*Basis(
        Vector3.UP,travel)
    var height: float=Sculpt.WHEEL_RADIUS+0.08
    return Transform3D(pose_basis,Vector3(
        side*(Sculpt.WHEEL_X+offset),height,
        float(Sculpt.WHEEL_Z[axle])))

static func pose(model: Node3D,kind: String,progress: float,
        heading: Vector2i=Vector2i(0,-1)) -> bool:
    if not has_model(model):
        return false
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    if root==null:
        return false
    var t: float=clampf(progress,0.0,1.0)
    var base_pos: Vector3=model.get_meta(BASE,model.position)
    model.position=base_pos
    var remote: Node3D=root.find_child(TURRET,false,false) as Node3D
    var tires: MultiMeshInstance3D=root.find_child(
        WHEELS,false,false) as MultiMeshInstance3D
    var gun: Node3D=root.find_child(GUN,true,false) as Node3D
    if remote==null or tires==null or gun==null:
        return false
    remote.rotation_degrees.y=0.0
    gun.rotation_degrees.x=0.0
    model.rotation_degrees.z=0.0
    var hubs: MultiMeshInstance3D=root.find_child(
        HUBS,false,false) as MultiMeshInstance3D
    if kind in ["move","move_turn"]:
        var travel: float=WHEEL_TURNS*t
        var turning: bool=kind=="move_turn"
        var steering: float=deg_to_rad(TURN_DEGREES)*sin(PI*t) if turning else 0.0
        for i in range(6):
            var side: float=-1.0 if i<3 else 1.0
            var axle: int=i%3
            tires.multimesh.set_instance_transform(i,
                _wheel_transform(side,axle,travel,steering,TIRES_HOME))
            # Metallic hubs spin WITH their tires, unlike V8 where hubs
            # remained visually static while tread rotation advanced.
            if hubs!=null:
                hubs.multimesh.set_instance_transform(i,
                    _wheel_transform(side,axle,travel,steering,HUB_HOME))
        var envelope: float=sin(PI*t)
        model.position.y=base_pos.y-BUMP_AMPLITUDE*absf(
            sin(TAU*2.4*t))*envelope
        model.rotation_degrees.z=(
            -0.75*sin(PI*t) if turning else
            0.22*sin(TAU*2.0*t)*envelope)
    elif kind=="idle":
        # Restoration must not rewind the tires: parking never teleports a
        # wheel or changes the last accumulated vehicle heading.
        pass
    elif kind=="attack":
        # Distanced shots retain six short separate weapon kicks, no
        # glowing V7 muzzle particles or individual shell actors.
        var shot: float=-1.0
        for i in range(6):
            var age: float=t-(0.25+float(i)*0.108)
            if age>=0.0 and age<0.08:
                shot=maxf(shot,1.0-age/0.08)
        remote.rotation_degrees.y=rad_to_deg(
            atan2(float(heading.x),-float(heading.y)))*0.37
        gun.rotation_degrees.x= -0.80*maxf(0.0,shot)
    elif kind in ["hit_bullet","hit_explosive"]:
        var strength: float=0.055 if kind=="hit_explosive" else 0.012
        model.position.y=base_pos.y-strength*sin(PI*t)
        model.rotation_degrees.z=(
            1.45 if kind=="hit_explosive" else 0.24) * sin(PI*t*3.0) * (1.0-t)
    model.set_meta(LAST,kind)
    return true

static func restore(model: Node3D) -> void:
    if has_model(model):
        pose(model,"idle",1.0)
