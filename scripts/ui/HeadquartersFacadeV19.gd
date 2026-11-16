extends RefCounted
class_name TarvokaHeadquartersFacadeV19

# V19: Actual beveled 3D aluminium window reveals and a restrained
# physical halo around the ORIGINAL official 8-faction shield mount.
# Hero close-up only. No new lights, collision, tactical rules or sprites.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME := "DetallesFachadaYMarcoEscudoHQV19"
const MAX_DRAW_BATCHES := 2
const INSTANCE_TOTAL := 20
static var _bar_mesh: ArrayMesh

static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b-a).cross(c-a).normalized()
    for point in [a,b,c]:
        st.set_normal(normal)
        st.set_uv(Vector2(point.x+0.5,point.y+0.5))
        st.add_vertex(point)

static func _chamfered_bar() -> ArrayMesh:
    if _bar_mesh != null:
        return _bar_mesh
    # An octagonal cross-section, not a flat square border. Same mesh is
    # reused for all twenty window and insignia trim pieces.
    var section: Array[Vector2] = [
        Vector2(-0.34,-0.5),Vector2(0.34,-0.5),
        Vector2(0.5,-0.34),Vector2(0.5,0.34),
        Vector2(0.34,0.5),Vector2(-0.34,0.5),
        Vector2(-0.5,0.34),Vector2(-0.5,-0.34)]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(section.size()):
        var next: int = (i+1)%section.size()
        var a := Vector3(-0.5,section[i].x,section[i].y)
        var b := Vector3(0.5,section[i].x,section[i].y)
        var c := Vector3(0.5,section[next].x,section[next].y)
        var d := Vector3(-0.5,section[next].x,section[next].y)
        _triangle(st,a,b,c)
        _triangle(st,a,c,d)
        _triangle(st,Vector3(-0.5,0,0),d,a)
        _triangle(st,Vector3(0.5,0,0),b,c)
    _bar_mesh = st.commit()
    return _bar_mesh

static func _material(color: Color, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.50
    mat.roughness = roughness
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _batch(name: String, pieces: Array, color: Color,
        roughness: float) -> MultiMeshInstance3D:
    var node := MultiMeshInstance3D.new()
    node.name = name
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = _chamfered_bar()
    mm.instance_count = pieces.size()
    for i in range(pieces.size()):
        var pos: Vector3 = pieces[i][0]
        var size: Vector3 = pieces[i][1]
        mm.set_instance_transform(i,Transform3D(Basis().scaled(size),pos))
    node.multimesh = mm
    node.material_override = _material(color,roughness)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.set_meta("tarvoka_hq_v19_beveled",true)
    return node

static func build() -> Node3D:
    var stage := Node3D.new()
    stage.name = STAGE_NAME
    stage.set_meta("tarvoka_visual_only",true)
    stage.set_meta("tarvoka_hq_v19_facade",true)
    var frames: Array = []
    # Right wing first so damaged state keeps only the sound right wing.
    # V12 windows: x = +/-4.03 +/-0.57, y=2.56, z=-3.117.
    for side in [1,-1]:
        for offset in [-0.57,0.57]:
            var x: float = float(side)*4.03 + float(offset)
            var z: float = -3.17
            frames.append([Vector3(x,2.735,z),Vector3(0.47,0.05,0.088)])
            frames.append([Vector3(x,2.385,z),Vector3(0.47,0.05,0.088)])
            frames.append([Vector3(x-0.224,2.56,z),Vector3(0.05,0.35,0.088)])
            frames.append([Vector3(x+0.224,2.56,z),Vector3(0.05,0.35,0.088)])
    stage.add_child(_batch("JunquillosVentanasAlaV19",frames,Color("#c0cdd0"),0.42))
    # The approved atlas is never copied or recoloured. This is an external
    # narrow metal frame set OUTSIDE its 0.96 x 1.17 shield mount.
    var crest: Array = [
        [Vector3(0,4.40,-3.60),Vector3(1.62,0.10,0.10)],
        [Vector3(0,2.74,-3.60),Vector3(1.62,0.10,0.10)],
        [Vector3(-0.81,3.57,-3.60),Vector3(0.10,1.66,0.10)],
        [Vector3(0.81,3.57,-3.60),Vector3(0.10,1.66,0.10)]
    ]
    stage.add_child(_batch("MarcoPerimetralSinCubrirEscudoV19",
        crest,Color("#c7a770"),0.48))
    stage.visible = false
    return stage

static func apply(stage: Node3D, faction: int, level: int,
        condition: String, weather: String, enabled: bool = true,
        distant: bool = false) -> bool:
    if stage == null or faction < 0 or faction >= 8 or level < 1 or level > 3:
        return false
    if not condition in ["operativo","capturado","danado","destruido"]:
        return false
    if not weather in ["clear","rain","snow"]:
        return false
    stage.visible = enabled and not distant and condition != "destruido"
    var windows: MultiMeshInstance3D = stage.get_node("JunquillosVentanasAlaV19")
    windows.multimesh.visible_instance_count = 8 if condition == "danado" else 16
    var crest: MultiMeshInstance3D = stage.get_node("MarcoPerimetralSinCubrirEscudoV19")
    for i in range(4):
        var t: Transform3D = crest.multimesh.get_instance_transform(i)
        t.origin.y = [4.40,2.74,3.57,3.57][i] + 0.91*float(level-1)
        crest.multimesh.set_instance_transform(i,t)
    var frame_mat: StandardMaterial3D = windows.material_override as StandardMaterial3D
    frame_mat.roughness = 0.28 if weather == "rain" else 0.70 if weather == "snow" else 0.42
    var crest_mat: StandardMaterial3D = crest.material_override as StandardMaterial3D
    # Subtle faction-tinted metal rim, not a replacement shield or atlas.
    var accent: Color = Style.faction_color(faction)
    crest_mat.albedo_color = Color("#c7a770").lerp(accent,0.19)
    crest_mat.roughness = 0.36 if weather == "rain" else 0.48
    stage.set_meta("tarvoka_hq_v19_level",level)
    stage.set_meta("tarvoka_hq_v19_faction",faction)
    stage.set_meta("tarvoka_hq_v19_weather",weather)
    return true

static func batches(stage: Node3D) -> int:
    if stage == null or not stage.visible:
        return 0
    var count: int = 0
    for child in stage.get_children():
        if child is MultiMeshInstance3D and child.visible:
            count += 1
    return count

static func instances(stage: Node3D) -> int:
    if stage == null:
        return 0
    var count: int = 0
    for child in stage.get_children():
        if child is MultiMeshInstance3D:
            count += (child as MultiMeshInstance3D).multimesh.instance_count
    return count
