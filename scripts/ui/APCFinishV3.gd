extends RefCounted
class_name TarvokaAPCFinishV3

# P06 BASTIÓN V3 — real Godot sculpted roof, armor seams, remote turret,
# deterministic 5-stage cosmetic damage. Entirely visuals, no HP/rules.
# Built once per unit. Damage is hidden/visible staging, not model rebuild.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V2=preload("res://scripts/ui/APCArmorV2.gd")
const ROOT: String="APC_P06_V3_TechoJuntasYDesgaste"
const STAGES: String="APC_P06_V3_DanoPorEtapas"
const PAINT: String="tarvoka_apc_v3_faction_zone"
static var _scorch_tex: ImageTexture
static var _smoke_tex: ImageTexture
static var _flame_tex: ImageTexture

static func _color_mask(kind: String) -> ImageTexture:
    if kind=="soot" and _scorch_tex!=null:
        return _scorch_tex
    if kind=="smoke" and _smoke_tex!=null:
        return _smoke_tex
    if kind=="fire" and _flame_tex!=null:
        return _flame_tex
    var image:=Image.create(96,96,false,Image.FORMAT_RGBA8)
    for y in range(96):
        for x in range(96):
            var u: float=float(x)/95.0-0.5
            var v: float=float(y)/95.0-0.5
            var a: float=atan2(v,u)
            var fuzz: float=0.065*sin(a*9.0+0.7)+0.034*cos(a*17.0)
            var r: float=Vector2(u,v).length()/(0.40+fuzz)
            var alpha: float=clampf((1.0-r)*4.2,0.0,1.0)
            var col: Color=Color(0.07,0.08,0.08,0.78*alpha)
            if kind=="smoke":
                var noise: float=0.69+0.28*sin(float(x)*0.22+float(y)*0.16)*cos(float(y)*0.31)
                col=Color(0.24,0.26,0.28,0.60*alpha*noise)
            elif kind=="fire":
                var flame_r: float=Vector2(u*1.2,v*0.74-0.16).length()/0.39
                var f: float=clampf((1.0-flame_r)*4.0,0.0,1.0)
                col=Color(1.0,0.37+0.46*(1.0-flame_r),0.06,0.88*f)
            image.set_pixel(x,y,col)
    image.generate_mipmaps()
    var result:=ImageTexture.create_from_image(image)
    match kind:
        "soot": _scorch_tex=result
        "smoke": _smoke_tex=result
        "fire": _flame_tex=result
    return result

static func _material(color: Color,metal: float=0.34,
        rough: float=0.82) -> StandardMaterial3D:
    return V2._coated(color,metal,rough)

static func _node(parent: Node3D,name: String,
        mesh: Mesh,material: Material,paint: bool=false) -> MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=name
    item.mesh=mesh
    item.material_override=material
    if paint:
        item.set_meta(PAINT,true)
    parent.add_child(item)
    return item

static func _sculpt(parent: Node3D,name: String,
        points: Array[Vector3],material: Material,
        paint: bool=false) -> MeshInstance3D:
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for point in points:
        tool.add_vertex(point)
    tool.generate_normals()
    return _node(parent,name,tool.commit(),material,paint)

static func _quad(a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> Array[Vector3]:
    return [a,b,c,a,c,d]

static func _rim(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,material: Material) -> MeshInstance3D:
    var span: Vector3=b-a
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=span.length()
    cylinder.radial_segments=6
    var part: MeshInstance3D=_node(parent,name,cylinder,material)
    part.position=(a+b)*0.5
    part.quaternion=Quaternion(Vector3.UP,span.normalized())
    return part

static func _card(parent: Node3D,name: String,
        position: Vector3,size: Vector2,
        kind: String,billboard: bool=false) -> MeshInstance3D:
    var panel:=QuadMesh.new()
    panel.size=size
    var mat:=StandardMaterial3D.new()
    mat.albedo_texture=_color_mask(kind)
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    if billboard:
        mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
    if kind=="fire":
        mat.emission_enabled=true
        mat.emission=Color("#F5A44E")
        mat.emission_energy_multiplier=0.55
    var node: MeshInstance3D=_node(parent,name,panel,mat)
    node.position=position
    node.set_meta("apc_v3_effect_origin",position)
    return node

static func _roof(parent: Node3D,
        armor: Material,steel: Material,glass: Material) -> void:
    # Single sculpted segmented roof with recessed service hatch. Avoid
    # floating oversized boxes and re-use the V2 chassis proportions.
    _sculpt(parent,"TechoBlindadoContinuoV3",_quad(
        Vector3(-0.626,1.474,-0.54),Vector3(0.626,1.474,-0.54),
        Vector3(0.614,1.471,0.79),Vector3(-0.614,1.471,0.79)),
        armor,true)
    for side in [-1,1]:
        var sign: float=float(side)
        _sculpt(parent,"HombroTechoInclinadoV3_%d" % side,_quad(
            Vector3(sign*0.625,1.472,-0.54),
            Vector3(sign*0.766,1.326,-0.54),
            Vector3(sign*0.778,1.332,0.80),
            Vector3(sign*0.615,1.469,0.80)),armor,true)
        _rim(parent,"SoldaduraUnidaTechoV3_%d" % side,
            Vector3(sign*0.615,1.479,-0.51),
            Vector3(sign*0.615,1.479,0.76),0.008,steel)
        for i in range(3):
            var z: float=-0.43+float(i)*0.54
            _rim(parent,"PernoAnclajeTecho_%d_%d" % [side,i],
                Vector3(sign*0.608,1.487,z),
                Vector3(sign*0.608,1.503,z),0.019,steel)
    # Access hatch is faceted and flush, with recessed dark optic glass.
    _sculpt(parent,"EscotillaTechoOctogonalV3",[
        Vector3(-0.31,1.497,0.27),Vector3(0.31,1.497,0.27),
        Vector3(0.38,1.497,0.38),Vector3(-0.31,1.497,0.27),
        Vector3(0.38,1.497,0.38),Vector3(0.34,1.497,0.67),
        Vector3(-0.31,1.497,0.27),Vector3(0.34,1.497,0.67),
        Vector3(-0.32,1.497,0.67)],steel)
    _sculpt(parent,"BlindajeRegistroSuperiorV3",_quad(
        Vector3(-0.25,1.507,0.34),Vector3(0.25,1.507,0.34),
        Vector3(0.27,1.507,0.60),Vector3(-0.27,1.507,0.60)),armor,true)
    _sculpt(parent,"PeriscopioFrontalV3",_quad(
        Vector3(-0.15,1.491,-0.50),Vector3(0.15,1.491,-0.50),
        Vector3(0.15,1.491,-0.38),Vector3(-0.15,1.491,-0.38)),glass)
    _rim(parent,"JuntaTechoDelanteraV3",
        Vector3(-0.62,1.480,-0.53),Vector3(0.62,1.480,-0.53),0.010,steel)

static func _side_seams(parent: Node3D,steel: Material) -> void:
    # 4 flank panel joins and 2 glacis welds on shared battle hull, rather
    # than repeatedly parenting tiny cubes into the rendering tree.
    for side in [-1,1]:
        var sign: float=float(side)
        for z in [-0.61,0.04,0.70]:
            _rim(parent,"JuntaFlancoV3_%d_%d" % [side,int(z*100.0)],
                Vector3(sign*0.810,1.29,z),
                Vector3(sign*0.840,0.91,z),0.008,steel)
        _rim(parent,"RemacheSoldadoProaV3_%d" % side,
            Vector3(sign*0.08,1.10,-1.44),
            Vector3(sign*0.67,1.04,-1.24),0.011,steel)

static func _turret(model: Node3D,armor: Material,
        steel: Material,glass: Material) -> bool:
    var turret: Node3D=model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    if turret==null:
        return false
    var details:=Node3D.new()
    details.name="TorretaP06AcabadoV3"
    turret.add_child(details)
    # Side chamfer armor is attached INSIDE turret pivot: rotates correctly.
    for side in [-1,1]:
        var sign: float=float(side)
        _sculpt(details,"CarrilleraTorretaV3_%d" % side,_quad(
            Vector3(sign*0.27,0.115,-0.23),
            Vector3(sign*0.29,0.263,-0.21),
            Vector3(sign*0.245,0.31,0.16),
            Vector3(sign*0.258,0.117,0.19)),armor,true)
        _rim(details,"NervioTorretaV3_%d" % side,
            Vector3(sign*0.26,0.30,-0.16),
            Vector3(sign*0.245,0.30,0.14),0.010,steel)
    _sculpt(details,"ProtectorOpticaP06V3",_quad(
        Vector3(0.201,0.355,-0.335),
        Vector3(0.33,0.355,-0.335),
        Vector3(0.33,0.415,-0.27),
        Vector3(0.201,0.415,-0.27)),steel)
    _sculpt(details,"CristalSensorTermicoV3",_quad(
        Vector3(0.215,0.36,-0.340),
        Vector3(0.319,0.36,-0.340),
        Vector3(0.315,0.393,-0.32),
        Vector3(0.215,0.393,-0.32)),glass)
    return true

static func _damage(parent: Node3D,
        armor: Material,charred: Material,steel: Material) -> void:
    var stages:=Node3D.new()
    stages.name=STAGES
    parent.add_child(stages)
    for stage in range(1,5):
        var root:=Node3D.new()
        root.name="DanoP06Etapa_%d" % stage
        root.visible=false
        stages.add_child(root)
        if stage==1:
            # Small impacts and scratches (not solid grey boxes).
            var spot:=_card(root,"MarcaImpactoLeve",
                Vector3(0.642,1.27,-0.70),Vector2(0.34,0.24),"soot")
            spot.rotation_degrees=Vector3(0,78,-12)
            _rim(root,"AntenaRechazadaLeve",
                Vector3(-0.57,1.55,0.83),
                Vector3(-0.73,1.94,0.83),0.014,steel)
        if stage==2:
            var scar:=_card(root,"ImpactoLateralMedio",
                Vector3(0.842,1.00,0.11),Vector2(0.52,0.43),"soot")
            scar.rotation_degrees=Vector3(0,90,8)
            _sculpt(root,"BlindajeAstilladoMedio",[
                Vector3(0.85,0.96,0.14),Vector3(0.91,0.88,0.26),
                Vector3(0.86,1.11,0.37),
                Vector3(0.85,0.96,0.14),Vector3(0.86,1.11,0.37),
                Vector3(0.89,1.05,0.01)],steel)
            _card(root,"HumoMotorMedio",Vector3(0.40,1.50,0.72),
                Vector2(0.54,0.60),"smoke",true)
        if stage==3:
            for i in range(3):
                var f: float=float(i)
                _sculpt(root,"FragmentoCorazaPesada_%d" % i,[
                    Vector3(-0.68+f*0.38,1.33,0.72),
                    Vector3(-0.53+f*0.35,1.48,0.64),
                    Vector3(-0.58+f*0.42,1.51,0.90),
                    Vector3(-0.68+f*0.38,1.33,0.72),
                    Vector3(-0.58+f*0.42,1.51,0.90),
                    Vector3(-0.73+f*0.36,1.26,0.84)],armor)
            _card(root,"FogonMotorGrave",Vector3(-0.24,1.59,0.87),
                Vector2(0.60,0.77),"fire",true)
            _card(root,"HumoMotorGrave",Vector3(-0.23,1.83,0.86),
                Vector2(0.78,0.91),"smoke",true)
        if stage==4:
            _sculpt(root,"TechoColapsadoIrregular",[
                Vector3(-0.60,1.48,-0.15),Vector3(0.18,1.27,-0.18),
                Vector3(0.14,1.42,0.52),
                Vector3(-0.60,1.48,-0.15),Vector3(0.14,1.42,0.52),
                Vector3(-0.55,1.28,0.55),
                Vector3(0.18,1.27,-0.18),Vector3(0.59,1.42,-0.08),
                Vector3(0.14,1.42,0.52)],charred)
            _card(root,"HumoDestruccionP06",
                Vector3(0.12,1.89,0.57),Vector2(1.20,1.44),"smoke",true)
            _card(root,"FuegoDestruccionP06",
                Vector3(0.05,1.62,0.58),Vector2(0.86,1.02),"fire",true)

static func apply(model: Node3D,color: Color) -> bool:
    if model==null or not model.get_meta("tarvoka_apc_armor_v2",false):
        return false
    if model.get_meta("tarvoka_apc_finish_v3",false):
        return false
    var v2: Node3D=model.find_child(V2.ROOT,true,false) as Node3D
    if v2==null:
        return false
    var detail:=Node3D.new()
    detail.name=ROOT
    v2.add_child(detail)
    var paint: Material=_material(V2._main_color(color))
    var steel: Material=V1._mat(Color("#3B4E54"),0.42,0.81)
    var lens: Material=V1._mat(Color("#4E7989"),0.06,0.24)
    var burned: Material=V1._mat(Color("#252B2C"),0.14,0.95)
    _roof(detail,paint,steel,lens)
    _side_seams(detail,steel)
    if not _turret(model,paint,steel,lens):
        detail.queue_free()
        return false
    _damage(detail,paint,burned,steel)
    model.set_meta("tarvoka_apc_finish_v3",true)
    model.set_meta("tarvoka_apc_v3_damage_stage",0)
    model.set_meta("tarvoka_apc_v3_damage_effect_count",7)
    return true

static func recolor(model: Node3D,color: Color) -> int:
    if model==null or not model.get_meta("tarvoka_apc_finish_v3",false):
        return 0
    var paint: Material=_material(V2._main_color(color))
    var updated:=0
    # Includes turret child even though it lives outside the static V3 root.
    for part in model.find_children("*","MeshInstance3D",true,false):
        if part.get_meta(PAINT,false):
            (part as MeshInstance3D).material_override=paint
            updated+=1
    return updated

static func stage_for_hp(hp: int,max_hp: int=10) -> int:
    if hp<=0:
        return 4
    var ratio: float=float(hp)/float(maxi(1,max_hp))
    if ratio<=0.25:
        return 3
    if ratio<=0.50:
        return 2
    if ratio<=0.80:
        return 1
    return 0

static func apply_stage(model: Node3D,stage: int) -> bool:
    if model==null or not model.get_meta("tarvoka_apc_finish_v3",false):
        return false
    var root: Node3D=model.find_child(STAGES,true,false) as Node3D
    if root==null:
        return false
    var current: int=clampi(stage,0,4)
    for i in range(1,5):
        var group: Node3D=root.find_child(
            "DanoP06Etapa_%d" % i,false,false) as Node3D
        if group==null:
            return false
        group.visible=current>=i
    model.set_meta("tarvoka_apc_v3_damage_stage",current)
    return true

static func animate_damage(model: Node3D,seconds: float) -> void:
    if model==null or not model.get_meta("tarvoka_apc_finish_v3",false):
        return
    var stage: int=int(model.get_meta("tarvoka_apc_v3_damage_stage",0))
    if stage<2:
        return
    # No particles or scene allocations during animation. Alpha cards are
    # reused per vehicle; smoke travels slowly and flames flicker. No
    # material mutation shared with another faction or model.
    for key in ["HumoMotorMedio","HumoMotorGrave","HumoDestruccionP06",
            "FogonMotorGrave","FuegoDestruccionP06"]:
        var fx: MeshInstance3D=model.find_child(key,true,false) as MeshInstance3D
        if fx==null:
            continue
        var home: Vector3=fx.get_meta(
            "apc_v3_effect_origin",fx.position) as Vector3
        var fire: bool=key.begins_with("Fogon") or key.begins_with("Fuego")
        var pulse: float=sin(seconds*(7.1 if fire else 1.8))
        fx.position=home+Vector3(0.0,
            0.014*pulse if fire else 0.12*sin(seconds*0.65),0.0)
        fx.scale=Vector3.ONE*(
            1.0+0.15*pulse if fire else 1.0+0.09*sin(seconds*1.15))
