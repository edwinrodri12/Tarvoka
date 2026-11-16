extends RefCounted
class_name TarvokaHeadquartersProductionV13

# Native 3D runtime asset: two DISJOINT quality paths. "tactical" never
# instantiates thousands of invisible V12 meshes. Real official emblem art.
# No modifications to rules, ownership, save games or the 2D battle board.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const MapLOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")

const STATES := ["operativo","capturado","danado","destruido"]
const QUALITY_TACTICAL := "tactical"
const QUALITY_HERO := "hero"
const SELECTION_LAYER := 1 << 19
const SURFACE_BUDGET := 10
const MESH_BUDGET := 2

static var _runtime_meshes: Dictionary = {}
static var _trim_mats: Dictionary = {}

static func valid(level: int,faction: int,condition: String,quality: String) -> bool:
    return HQ.valid_spec(level,faction,condition) and quality in [
        QUALITY_TACTICAL,QUALITY_HERO]

static func _mat(style: String,accent: Color) -> StandardMaterial3D:
    var key: String = "%s/%s" % [style,accent.to_html(false)]
    if _trim_mats.has(key):
        return _trim_mats[key]
    var m := StandardMaterial3D.new()
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.metallic = 0.18 if style != "concrete" else 0.06
    m.roughness = 0.68 if style != "concrete" else 0.89
    match style:
        "concrete": m.albedo_color = Color("#aebfbc")
        "roof": m.albedo_color = Color("#263a48")
        "paint": m.albedo_color = accent.darkened(0.13)
    _trim_mats[key] = m
    return m

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    for v in [a,b,c]:
        st.set_uv(Vector2(v.x*0.11+0.5,v.z*0.11+v.y*0.09))
        st.add_vertex(v)

static func _curved_lintel(st: SurfaceTool,x_center: float,
        half: float,height: float, rise: float,
        z_front: float,depth: float,thickness: float,
        segments: int = 10) -> void:
    # CLOSED, low-vertex piecewise curved extrusion: six visible faces.
    # Tactical silhouette follows the larger V12 roof, unlike old V5 boxes.
    for i in range(segments):
        var t0: float = float(i)/float(segments)
        var t1: float = float(i+1)/float(segments)
        var x0: float = x_center + (2.0*t0-1.0)*half
        var x1: float = x_center + (2.0*t1-1.0)*half
        var y0: float = height + rise*sqrt(maxf(0.0,1.0-pow(2.0*t0-1.0,2.0)))
        var y1: float = height + rise*sqrt(maxf(0.0,1.0-pow(2.0*t1-1.0,2.0)))
        var a := Vector3(x0,y0,z_front)
        var b := Vector3(x1,y1,z_front)
        var c := Vector3(x0,y0-thickness,z_front)
        var d := Vector3(x1,y1-thickness,z_front)
        var back := Vector3(0,0,depth)
        var e: Vector3 = a+back
        var f: Vector3 = b+back
        var g: Vector3 = c+back
        var h: Vector3 = d+back
        _tri(st,a,b,f)
        _tri(st,a,f,e)
        _tri(st,c,g,h)
        _tri(st,c,h,d)
        _tri(st,c,d,b)
        _tri(st,c,b,a)
        _tri(st,e,f,h)
        _tri(st,e,h,g)
        if i==0:
            _tri(st,a,e,g)
            _tri(st,a,g,c)
        if i==segments-1:
            _tri(st,b,d,h)
            _tri(st,b,h,f)

static func _runtime_mesh(level: int,faction: int,condition: String) -> ArrayMesh:
    var key: String = "%d/%d/%s" % [level,faction,condition]
    if _runtime_meshes.has(key):
        return _runtime_meshes[key] as ArrayMesh
    var base: ArrayMesh = MapLOD.shared_mesh(level,faction,condition)
    if base == null:
        return null
    var combined := ArrayMesh.new()
    # Clone, don't mutate the original V5 shared LOD: earlier studio scenes
    # and the separate 49-building benchmark continue to use its six surfaces.
    for i in range(base.get_surface_count()):
        combined.add_surface_from_arrays(
            base.surface_get_primitive_type(i),base.surface_get_arrays(i))
        combined.surface_set_material(i,base.surface_get_material(i))
    var roof := SurfaceTool.new()
    var concrete := SurfaceTool.new()
    var paint := SurfaceTool.new()
    for st in [roof,concrete,paint]:
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var y: float = 2.87+0.91*float(level-1)
    if condition == "destruido":
        _curved_lintel(roof,-1.91,0.97,0.38,0.15,-3.99,0.20,0.13,6)
        _curved_lintel(concrete,1.74,0.53,0.24,0.11,-3.36,0.19,0.10,6)
        _curved_lintel(paint,0.0,0.58,0.28,0.07,-4.2,0.10,0.08,6)
    else:
        for side in [-1,1]:
            var x: float = float(side)*4.03
            _curved_lintel(roof,x,1.25,3.01,0.55,-2.86,0.65,0.32)
            _curved_lintel(concrete,x,1.19,3.14,0.50,-2.98,0.28,0.18)
            _curved_lintel(paint,x,1.09,3.30,0.42,-3.025,0.14,0.10)
        # The crest sits ABOVE the approved emblem's plane, not in front.
        _curved_lintel(roof,0.0,1.91,y+2.34,0.50,-2.71,0.66,0.30)
        _curved_lintel(concrete,0.0,1.81,y+2.47,0.44,-2.78,0.22,0.15)
        _curved_lintel(paint,0.0,1.72,y+2.59,0.39,-2.81,0.095,0.09)
        if condition == "danado":
            # One wing's paint band has no continuous heroic decal; the
            # original V5 break and V13 dark cap still identify this state.
            _curved_lintel(roof,-4.18,0.26,2.95,0.17,-3.12,0.14,0.13,6)
    for data in [
            [roof,_mat("roof",Style.faction_color(faction))],
            [concrete,_mat("concrete",Style.faction_color(faction))],
            [paint,_mat("paint",Style.faction_color(faction))]]:
        var st: SurfaceTool = data[0] as SurfaceTool
        st.generate_normals()
        st.set_material(data[1] as Material)
        st.commit(combined)
    assert(combined.get_surface_count() == 9)
    _runtime_meshes[key] = combined
    return combined

static func _selector(parent: Node3D,condition: String) -> Area3D:
    # Dedicated selection-only layer, no movement or tactical collision.
    # Keeps this asset usable by a future 3D map without changing the rules.
    var area := Area3D.new()
    area.name = "ProxySeleccionHQV13"
    area.collision_layer = SELECTION_LAYER
    area.collision_mask = 0
    area.monitoring = false
    area.monitorable = true
    var shape := CollisionShape3D.new()
    shape.name = "VolumenSoloSeleccion"
    var box := BoxShape3D.new()
    box.size = Vector3(13.3,2.25,12.15) if condition == "destruido" else Vector3(13.3,7.6,12.15)
    shape.shape = box
    shape.position = Vector3(0,1.10,0) if condition == "destruido" else Vector3(0,3.8,0)
    area.add_child(shape)
    area.set_meta("tarvoka_selection_only",true)
    parent.add_child(area)
    return area

static func build(level: int,faction: int,condition: String = "operativo",
        quality: String = QUALITY_TACTICAL,selection: bool = false) -> Node3D:
    if not valid(level,faction,condition,quality):
        return null
    var node: Node3D
    if quality == QUALITY_HERO:
        node = HQ.build(level,faction,condition)
        if node == null:
            return null
    else:
        node = Node3D.new()
        node.name = "CuartelGeneralProduccionV13"
        var shell := MeshInstance3D.new()
        shell.name = "MallaTacticaConCurvasV13"
        shell.mesh = _runtime_mesh(level,faction,condition)
        assert(shell.mesh != null and shell.mesh.get_surface_count() == 9)
        node.add_child(shell)
        var crest := MeshInstance3D.new()
        crest.name = "EscudoOficialFaccion3D"
        crest.mesh = Emblems._geometry()
        crest.material_override = Emblems._material(faction)
        crest.set_meta("tarvoka_official_emblem_index",faction)
        var top: float = 2.87+0.91*float(level-1)
        crest.position = Vector3(1.40,0.27,-3.87) if condition == "destruido" else Vector3(0,top+0.67,-3.49)
        if condition == "destruido":
            crest.rotation_degrees = Vector3(-75,0,18)
            crest.scale = Vector3(0.71,0.71,0.71)
        else:
            crest.scale = Vector3(0.94,0.94,0.94)
        node.add_child(crest)
        node.set_meta("tarvoka_hq_production_v13",true)
        node.set_meta("tarvoka_hq_official_emblem",true)
    node.set_meta("tarvoka_building_kind","headquarters")
    node.set_meta("visual_level",level)
    node.set_meta("visual_faction",faction)
    node.set_meta("visual_condition",condition)
    node.set_meta("visual_only",true)
    node.set_meta("tarvoka_hq_render_quality",quality)
    node.set_meta("tarvoka_hq_selection_layer",SELECTION_LAYER)
    if selection:
        _selector(node,condition)
    return node

static func _meshes(node: Node) -> int:
    var result: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        result += _meshes(child)
    return result

static func render_budget(node: Node3D) -> Dictionary:
    if node == null:
        return {}
    var surfaces: int = 0
    for mesh in node.find_children("*","MeshInstance3D",true,false):
        var piece: MeshInstance3D = mesh as MeshInstance3D
        if piece.mesh != null:
            surfaces += piece.mesh.get_surface_count()
    return {"meshes":_meshes(node),"surfaces":surfaces,
        "within_tactical_budget":_meshes(node)<=MESH_BUDGET and surfaces<=SURFACE_BUDGET,
        "quality":str(node.get_meta("tarvoka_hq_render_quality","unknown"))}

static func cached_variant_count() -> int:
    return _runtime_meshes.size()
