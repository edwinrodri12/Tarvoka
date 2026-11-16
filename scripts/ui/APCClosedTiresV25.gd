extends RefCounted
class_name TarvokaAPCClosedTiresV25

# P06 V25: definitive closed tyre casing, aligned with wheel axis X.
# V2's old rubber casing was revolved about Y even though V1 and V14
# rims, V23 tread and suspension rotate about X. In the live model
# this was a genuine axis mismatch, NOT a missing tread decal.
# No gameplay, movement, steering, stats, collision or rig changes.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V23=preload("res://scripts/ui/APCTireFinishV23.gd")
const V24=preload("res://scripts/ui/APCRubberArchV24.gd")
const FLAG := "tarvoka_apc_closed_tires_v25"
const ROOT := "P06V25_CarcasaCerradaEjeCorrecto"
const BODY := "P06V25_GomaToricaCerrada"
const BACKING := "P06V25_RespaldoOscuroRin"
const SHOW := "tarvoka_apc_v25_visible"
const WEATHER := "tarvoka_apc_v25_weather"
const STAGE := "tarvoka_apc_v25_stage"
const CASING := "NeumaticoTodoTerreno"
const SEGMENTS := 64
const PROFILE := 14
const INNER_BEAD_RADIUS := 0.207
const OUTER_BODY_RADIUS := 0.345
const AXIAL_HALF_WIDTH := 0.123
const BACKING_OUTER := 0.197
const BACKING_INNER := 0.073

static func _group(parent: Node3D, label: String) -> Node3D:
    var part:=Node3D.new()
    part.name=label
    parent.add_child(part)
    return part

static func _paint(color: Color,metal: float,rough: float) -> StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=rough
    material.metallic=metal
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    return material

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        st.add_vertex(vertex)

static func _around(x: float,r: float,a: float) -> Vector3:
    # X is AXIAL. Radial tyre coordinates are Y and Z.
    return Vector3(x,r*cos(a),r*sin(a))

static func _profile() -> Array[Vector2]:
    # Revolve an entire CLOSED cross section. The inner bead overlaps
    # the V14 metal rim by 17 mm; the hole in the middle is the actual
    # hub/brake assembly, not a missing sidewall or an open tyre.
    return [
        Vector2(-0.119,0.207), Vector2(-0.121,0.237),
        Vector2(-0.120,0.273), Vector2(-0.114,0.298),
        Vector2(-0.102,0.320), Vector2(-0.086,0.339),
        Vector2(-0.075,0.345), Vector2(0.075,0.345),
        Vector2(0.086,0.339), Vector2(0.102,0.320),
        Vector2(0.114,0.298), Vector2(0.120,0.273),
        Vector2(0.121,0.237), Vector2(0.119,0.207)
    ]

static func _casing_mesh() -> ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var section: Array[Vector2]=_profile()
    for n in range(SEGMENTS):
        var a: float=TAU*float(n)/float(SEGMENTS)
        var b: float=TAU*float(n+1)/float(SEGMENTS)
        for i in range(section.size()):
            var next: int=(i+1)%section.size()
            var p: Vector2=section[i]
            var q: Vector2=section[next]
            _quad(st,_around(p.x,p.y,a),_around(p.x,p.y,b),
                _around(q.x,q.y,b),_around(q.x,q.y,a))
    st.generate_normals()
    return st.commit()

static func _dark_brake_shield() -> ArrayMesh:
    # Two-sided CLOSED annular drum behind V14's six OPEN metal spokes.
    # Actual spoke cut-outs stay visible, but can no longer expose
    # an empty wheel cavity or see-through triangular gaps.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sections: int=48
    var axial: float=0.008
    for n in range(sections):
        var a: float=TAU*float(n)/float(sections)
        var b: float=TAU*float(n+1)/float(sections)
        for x in [-axial,axial]:
            _quad(st,_around(x,BACKING_INNER,a),
                _around(x,BACKING_OUTER,a),
                _around(x,BACKING_OUTER,b),
                _around(x,BACKING_INNER,b))
        for r in [BACKING_INNER,BACKING_OUTER]:
            _quad(st,_around(-axial,r,a),_around(axial,r,a),
                _around(axial,r,b),_around(-axial,r,b))
    st.generate_normals()
    return st.commit()

static func _piece(parent: Node3D,label: String,shape: Mesh,
        paint: Material) -> MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=shape
    item.material_override=paint
    parent.add_child(item)
    return item

static func apply(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(V24.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var casing: ArrayMesh=_casing_mesh()
    var shield: ArrayMesh=_dark_brake_shield()
    var rubber: StandardMaterial3D=_paint(Color("#292c2c"),0.015,0.95)
    var brake: StandardMaterial3D=_paint(Color("#22292b"),0.25,0.82)
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],
                true,false) as Node3D
            if wheel==null:
                return false
            var old: MeshInstance3D=wheel.find_child(
                CASING,false,false) as MeshInstance3D
            if old==null:
                return false
            old.visible=false
            var root_node: Node3D=_group(wheel,ROOT)
            var tire: MeshInstance3D=_piece(root_node,BODY,casing,rubber)
            tire.set_meta("tarvoka_p06_v25_factory_material",rubber)
            # Behind six-spoke rim on EACH visible side of the vehicle;
            # never attached to the static V14 brake caliper.
            var disc: MeshInstance3D=_piece(root_node,BACKING,shield,brake)
            disc.position.x=float(side)*0.104
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(WEATHER,"clear")
    model.set_meta(STAGE,0)
    model.set_meta("tarvoka_p06_v25_casing_axis","X")
    model.set_meta("tarvoka_p06_v25_closed_casing",true)
    _refresh(model)
    return true

static func _refresh(model: Node3D) -> void:
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var weather: String=str(model.get_meta(WEATHER,"clear"))
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],
                true,false) as Node3D
            if wheel==null:
                continue
            var root_node: Node3D=wheel.find_child(
                ROOT,false,false) as Node3D
            var original: Node3D=wheel.find_child(
                CASING,false,false) as Node3D
            if root_node!=null:
                root_node.visible=enabled
                var tyre: MeshInstance3D=root_node.find_child(
                    BODY,false,false) as MeshInstance3D
                if tyre!=null:
                    var material: StandardMaterial3D=tyre.get_meta(
                        "tarvoka_p06_v25_factory_material") as StandardMaterial3D
                    if weather!="clear":
                        var altered: StandardMaterial3D=material.duplicate() as StandardMaterial3D
                        if weather=="rain":
                            altered.roughness=0.72
                            altered.albedo_color=material.albedo_color.darkened(0.08)
                        else:
                            altered.roughness=0.99
                            altered.albedo_color=material.albedo_color.lerp(
                                Color("#8b979c"),0.08)
                        tyre.material_override=altered
                    else:
                        tyre.material_override=material
            if original!=null:
                original.visible=not enabled

static func set_weather(model: Node3D,weather: String) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)) or not (
            weather in ["clear","rain","snow"]):
        return false
    model.set_meta(WEATHER,weather)
    _refresh(model)
    return true

static func set_stage(model: Node3D,stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(STAGE,clampi(stage,0,4))
    # Existing V14/V23 cut pieces handle real 5-stage visual damage;
    # the closed rubber body must stay intact as an underlying surface.
    _refresh(model)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    _refresh(model)
    return true
