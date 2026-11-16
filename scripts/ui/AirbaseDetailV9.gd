extends RefCounted
class_name TarvokaAirbaseDetailV9

# Real 3D close-range quality pass: replace the original *solid* panoramic
# cab glass block with four thin transparent panes, fitted corner posts and a
# visible cockpit. No drawn concept art, lights, HP or combat changes.
# Keeps the original geometry available for V8/V9 before-after comparisons.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const STAGE_NAME := "CristaleriaPanoramicaYRematesV9"
const GLASS_TINT := Color(0.30,0.53,0.65,0.42)
const FRAME_COLOR := Color("#6d828d")
const DARK := Color("#24343d")
const DESK := Color("#405563")
const SCREEN := Color("#8ab4c9")
const ROOF_TRIM := Color("#435963")
static var _glass: StandardMaterial3D

static func _pane_material() -> StandardMaterial3D:
    if _glass!=null:
        return _glass
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=GLASS_TINT
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.roughness=0.20
    mat.metallic=0.02
    mat.metallic_specular=0.83
    mat.clearcoat_enabled=true
    mat.clearcoat_roughness=0.13
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    _glass=mat
    return _glass

static func _box(parent: Node3D, label: String,
        position: Vector3, size: Vector3, color: Color,
        metal: float=0.28) -> MeshInstance3D:
    return Airbase._box(parent,label,position,size,color,metal)

static func _pane(parent: Node3D,label: String,
        position: Vector3,size: Vector3) -> MeshInstance3D:
    var pane:=_box(parent,label,position,size,GLASS_TINT,0.02)
    pane.material_override=_pane_material()
    pane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    pane.set_meta("tarvoka_airbase_v9_glass",true)
    return pane

static func _control_cab(model: Node3D, stage: int, stats: Dictionary) -> void:
    if stage>=3:
        return # Destroyed cab must not acquire intact windows.
    var cab: Node3D=model.find_child("CabinaControlAerodromo",true,false) as Node3D
    if cab==null:
        return
    var original: MeshInstance3D=cab.get_node_or_null(
        "CristalPerimetral") as MeshInstance3D
    if original==null:
        return
    original.visible=false
    original.set_meta("tarvoka_v9_original_hidden",true)
    stats["hidden_solid_glass"]=1
    for side in [-1,1]:
        var old: MeshInstance3D=cab.get_node_or_null(
            "VentanaLateral_%s" % side) as MeshInstance3D
        if old!=null:
            old.visible=false
            stats["hidden_old_sides"]+=1

    var upgrade:=Node3D.new()
    upgrade.name="CabinaHuecaPanoramicaV9"
    cab.add_child(upgrade)
    _pane(upgrade,"CristalFrontalFinoV9",
        Vector3(0,0,-0.949),Vector3(1.86,0.76,0.028))
    _pane(upgrade,"CristalPosteriorFinoV9",
        Vector3(0,0,0.949),Vector3(1.86,0.76,0.028))
    for side in [-1,1]:
        _pane(upgrade,"CristalLateralFinoV9_%s" % side,
            Vector3(float(side)*1.015,0,0),Vector3(0.028,0.76,1.73))
    stats["thin_glass_panes"]=4
    # Narrow real mullions, sunk into glazing edges; not bulky box windows.
    for side in [-1,1]:
        for face in [-1,1]:
            _box(upgrade,"MontanteEsquinaV9_%s_%s" % [side,face],
                Vector3(float(side)*0.982,0,float(face)*0.93),
                Vector3(0.065,0.88,0.073),FRAME_COLOR,0.42)
        _box(upgrade,"MontanteFrontalV9_%s" % side,
            Vector3(float(side)*0.36,0,-0.975),
            Vector3(0.045,0.83,0.048),FRAME_COLOR,0.39)
        _box(upgrade,"MontanteTraseroV9_%s" % side,
            Vector3(float(side)*0.36,0,0.975),
            Vector3(0.045,0.83,0.048),FRAME_COLOR,0.39)
    for side in [-1,1]:
        _box(upgrade,"MarcoHorizontalLateralV9_%s" % side,
            Vector3(float(side)*1.028,-0.39,0),
            Vector3(0.050,0.052,1.84),FRAME_COLOR,0.40)
    # True visible negative space, with just enough detail to make the
    # transparent cab read as occupied at normal tactical camera distance.
    _box(upgrade,"SueloCabinaAereaV9",
        Vector3(0,-0.428,0),Vector3(1.93,0.08,1.81),DARK,0.15)
    _box(upgrade,"EscritorioControlV9",
        Vector3(0,-0.245,-0.40),Vector3(1.27,0.11,0.44),DESK,0.24)
    for i in range(3):
        _box(upgrade,"PantallaControlV9_%d" % i,
            Vector3(-0.39+float(i)*0.39,-0.115,-0.40),
            Vector3(0.28,0.17,0.055),SCREEN,0.09)
    _box(upgrade,"AsientoOperadorV9",
        Vector3(0,-0.235,0.34),Vector3(0.42,0.31,0.44),DARK,0.08)
    _box(upgrade,"RespaldoAsientoV9",
        Vector3(0,-0.09,0.53),Vector3(0.42,0.57,0.10),DESK,0.13)

    # A few narrow cracks at medium damage, not opaque polygonal shards.
    if stage==2:
        for i in range(3):
            var crack:=_box(upgrade,"FisuraCristalFinoV9_%d" % i,
                Vector3(-0.47+float(i)*0.19,0.12-float(i)*0.09,-0.975),
                Vector3(0.022,0.18,0.018),Color("#bad8e5"),0.04)
            crack.rotation_degrees.z=26.0 if i%2==0 else -19.0
        stats["medium_glass_cracks"]=3

static func _roof_perimeter(model: Node3D,stage: int,
        stats: Dictionary) -> void:
    if stage>=4:
        return
    var hangar: Node3D=model.find_child("HangarPrincipalV1",true,false) as Node3D
    if hangar==null:
        return
    var mesh:=SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segment_count:=0
    for i in range(14):
        # Exact same roof masks as in V1 — never bridge a destroyed hole.
        if (stage==3 and i in [2,3,4,5,6,7]) or (stage==2 and i in [6,7]):
            continue
        var x0: float=-3.65+float(i)*7.30/14.0
        var x1: float=-3.65+float(i+1)*7.30/14.0
        var y0: float=2.80+0.73*sin(PI*(x0+3.65)/7.30)+0.013
        var y1: float=2.80+0.73*sin(PI*(x1+3.65)/7.30)+0.013
        for z in [-3.243,3.283]:
            var half_depth:=0.044
            var a:=Vector3(x0,y0,z-half_depth)
            var b:=Vector3(x1,y1,z-half_depth)
            var c:=Vector3(x1,y1,z+half_depth)
            var d:=Vector3(x0,y0,z+half_depth)
            for p in [a,b,c,a,c,d]:
                mesh.add_vertex(p)
        segment_count+=1
    if segment_count==0:
        return
    mesh.generate_normals()
    var edge:=MeshInstance3D.new()
    edge.name="RematePerimetralCurvoV9"
    edge.mesh=mesh.commit()
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=ROOF_TRIM
    mat.metallic=0.33
    mat.roughness=0.56
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    edge.material_override=mat
    edge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    edge.set_meta("tarvoka_visual_only",true)
    hangar.add_child(edge)
    stats["roof_segments_preserved"]=segment_count
    stats["roof_batches"]=1

static func apply(model: Node3D,level: int,faction: int,
        stage: int) -> bool:
    if model==null or not Airbase.valid_spec(level,faction,stage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false) or model.get_meta(
            "tarvoka_airbase_v9",false):
        return false
    var group:=Node3D.new()
    group.name=STAGE_NAME
    group.set_meta("tarvoka_visual_only",true)
    model.add_child(group)
    var stats: Dictionary={
        "faction":faction,"level":level,"stage":stage,
        "thin_glass_panes":0,"hidden_solid_glass":0,
        "hidden_old_sides":0,"medium_glass_cracks":0,
        "roof_segments_preserved":0,"roof_batches":0
    }
    if stage<4:
        _control_cab(model,stage,stats)
        _roof_perimeter(model,stage,stats)
        if stage<3 and int(stats["thin_glass_panes"])!=4:
            model.remove_child(group)
            group.free()
            return false
    model.set_meta("tarvoka_airbase_v9",true)
    model.set_meta("tarvoka_airbase_v9_stats",stats)
    return true
