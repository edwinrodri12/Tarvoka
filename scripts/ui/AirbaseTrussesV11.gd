extends RefCounted
class_name TarvokaAirbaseTrussesV11

# Godot 4.3 native close-range art pass. Additional structural depth is
# geometrical: cross braces, underskin fixings and torn structural edges.
# Every structural member follows the exact fourteen V1 roof panels.
# Does not alter doors, factions, navigation, HP, combat, save data or FX.
const V1 = preload("res://scripts/ui/Airbase3DV1.gd")
const V10 = preload("res://scripts/ui/AirbaseStructureV10.gd")
const STAGE_NAME := "CerchasExpuestasYRoturasRealesV11"
const CROSS_BRACES := "ArriostramientoDiagonalBajoCubiertaV11"
const FASTENERS := "AnclajesNervadurasCubiertaV11"
const TORN_LIPS := "SeccionRotaCubiertaExpuestaV11"
const HANGING := "AceroDeformadoBordesRotosV11"
const ROOF_PANELS := 14
const PANEL_WIDTH := 7.30/14.0
const BRACE_COLOR := Color("#566c76")
const ANCHOR_COLOR := Color("#87969b")
const BURN_COLOR := Color("#584843")
const BREAK_COLOR := Color("#6e5a50")

static func _group(parent: Node3D,label: String) -> Node3D:
    var node := Node3D.new()
    node.name=label
    node.set_meta("tarvoka_visual_only",true)
    parent.add_child(node)
    return node

static func _quad(tool: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        tool.add_vertex(vertex)

static func _bar(tool: SurfaceTool,start: Vector3,finish: Vector3,
        thickness: float) -> void:
    # A true solid, six-face rectangular steel bar with arbitrary 3D
    # orientation. No billboard plane or visual-only texture impostor.
    var direction: Vector3=finish-start
    if direction.length_squared()<0.00001:
        return
    direction=direction.normalized()
    var side: Vector3=direction.cross(Vector3.UP).normalized()
    if side.length_squared()<0.0001:
        side=Vector3.RIGHT
    var up: Vector3=side.cross(direction).normalized()
    var w: Vector3=side*thickness*0.5
    var h: Vector3=up*thickness*0.5
    var a: Vector3=start-w-h
    var b: Vector3=start+w-h
    var c: Vector3=start+w+h
    var d: Vector3=start-w+h
    var e: Vector3=finish-w-h
    var f: Vector3=finish+w-h
    var g: Vector3=finish+w+h
    var i: Vector3=finish-w+h
    _quad(tool,a,b,c,d)
    _quad(tool,e,i,g,f)
    _quad(tool,a,e,f,b)
    _quad(tool,d,c,g,i)
    _quad(tool,b,f,g,c)
    _quad(tool,a,d,i,e)

static func _mesh(parent: Node3D,label: String,
        tool: SurfaceTool,color: Color) -> void:
    tool.generate_normals()
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=tool.commit()
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=0.37
    material.roughness=0.76
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    item.material_override=material
    item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    item.set_meta("tarvoka_visual_only",true)
    parent.add_child(item)

static func _intact_panels(hangar: Node3D,damage: int,
        stats: Dictionary) -> void:
    var inside: Node3D=hangar.find_child(
        "InteriorOperativoHangarV2",true,false) as Node3D
    if inside==null or damage>=4:
        return
    var layer:=_group(inside,"InteriorEstructuraProfundaV11")
    var bracing:=SurfaceTool.new()
    bracing.begin(Mesh.PRIMITIVE_TRIANGLES)
    var fixings:=SurfaceTool.new()
    fixings.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(ROOF_PANELS):
        if not V10._has_roof(index,damage):
            continue
        var left: float=-3.65+float(index)*PANEL_WIDTH
        var right: float=left+PANEL_WIDTH
        var yleft: float=V10._roof_y(left)-0.34
        var yright: float=V10._roof_y(right)-0.34
        # Each panel has two crossed pairs of interlocking ties. All are
        # under the sheet, following its slope; nothing bridges missing roof.
        for pair in range(2):
            var za: float=-2.53+float(pair)*2.56
            var zb: float=za+2.45
            _bar(bracing,Vector3(left+0.04,yleft,za),
                Vector3(right-0.04,yright,zb),0.062)
            _bar(bracing,Vector3(right-0.04,yright,za),
                Vector3(left+0.04,yleft,zb),0.062)
            stats["diagonal_members"]+=2
        for z in [-2.53,2.60]:
            _bar(fixings,
                Vector3(left+0.052,V10._roof_y(left+0.052)-0.139,z),
                Vector3(left+0.052,V10._roof_y(left+0.052)-0.38,z),
                0.10)
            stats["roof_anchors"]+=1
        stats["roof_panels_supported"]+=1
    if stats["diagonal_members"]>0:
        _mesh(layer,CROSS_BRACES,bracing,BRACE_COLOR)
        _mesh(layer,FASTENERS,fixings,ANCHOR_COLOR)
        stats["intact_batches"]=2

static func _damage_breaks(hangar: Node3D,damage: int,
        stats: Dictionary) -> void:
    if damage<2 or damage>=4:
        return
    var breaks:=_group(hangar,"RoturasCubiertaEstructuralV11")
    var exposed:=SurfaceTool.new()
    exposed.begin(Mesh.PRIMITIVE_TRIANGLES)
    var hanging:=SurfaceTool.new()
    hanging.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Transition i marks the boundary between two original V1 roof strips.
    for i in range(1,ROOF_PANELS):
        var left_kept: bool=V10._has_roof(i-1,damage)
        var right_kept: bool=V10._has_roof(i,damage)
        if left_kept==right_kept:
            continue
        var x: float=-3.65+float(i)*PANEL_WIDTH
        var top: float=V10._roof_y(x)
        # Blackened steel is exactly at the real edge, not a new section
        # spread over the exposed open hole.
        _bar(exposed,Vector3(x,top-0.14,-3.20),
            Vector3(x,top-0.14,3.21),0.13)
        stats["torn_edges"]+=1
        var into_gap: float=1.0 if left_kept else -1.0
        var number: int=2 if damage==2 else 3
        for n in range(number):
            var z: float=-1.55+float(n)*2.89
            if damage==3:
                z=-2.15+float(n)*2.08
            _bar(hanging,
                Vector3(x,top-0.19,z),
                Vector3(x+into_gap*(0.22+float(n%2)*0.10),
                    top-0.39-float(n%2)*0.14,z+0.09),
                0.09)
            stats["hanging_stubs"]+=1
    if stats["torn_edges"]>0:
        _mesh(breaks,TORN_LIPS,exposed,BURN_COLOR)
        _mesh(breaks,HANGING,hanging,BREAK_COLOR)
        stats["damage_batches"]=2

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false) or not model.get_meta(
            "tarvoka_airbase_v10",false):
        return false
    if model.get_meta("tarvoka_airbase_v11",false):
        return false
    var hangar: Node3D=model.find_child(
        "HangarPrincipalV1",true,false) as Node3D
    if damage<4 and hangar==null:
        return false
    var marker:=_group(model,STAGE_NAME)
    var stats: Dictionary={
        "level":level,"faction":faction,"damage":damage,
        "roof_panels_supported":0,"diagonal_members":0,
        "roof_anchors":0,"intact_batches":0,
        "torn_edges":0,"hanging_stubs":0,"damage_batches":0
    }
    if hangar!=null and damage<4:
        _intact_panels(hangar,damage,stats)
        _damage_breaks(hangar,damage,stats)
    model.set_meta("tarvoka_airbase_v11",true)
    model.set_meta("tarvoka_airbase_v11_stats",stats)
    return true
