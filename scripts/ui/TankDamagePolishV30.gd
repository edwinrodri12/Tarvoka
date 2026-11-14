extends RefCounted
class_name TarvokaTankDamagePolishV30

# Persistent five-stage damage art for the real G09 final model.
# Old opaque BoxMesh impact patches, huge rectangular torn tracks, wreck
# blocks and cone flames are invisible; replace with irregular alpha-masked
# painted scorch decals and actual sculpted angular 3D metal fragments.
# The damage/collision/state machine and authoring hierarchy are unchanged.
const ROOT := "G09V30DañoMilitarRealista"
static var _soot: ImageTexture
static var _metal: StandardMaterial3D
const SOOT_SIZE := 96

static func _texture() -> ImageTexture:
    if _soot!=null:
        return _soot
    var image := Image.create(SOOT_SIZE,SOOT_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(SOOT_SIZE):
        for x in range(SOOT_SIZE):
            var uv := Vector2(float(x)/95.0-0.5,float(y)/95.0-0.5)
            var angle: float = atan2(uv.y,uv.x)
            var ring: float = 0.37+0.064*sin(angle*7.0+1.1)+0.039*cos(angle*11.0)
            var radius: float = uv.length()/ring
            var noise: float = sin(float(x)*0.87+float(y)*0.17)*cos(float(y)*0.63-float(x)*0.23)
            var edge: float = clampf((1.0-radius)*6.0+0.07*noise,0.0,1.0)
            var core: float = clampf(1.0-radius*1.4,0.0,1.0)
            var colour := Color(
                0.11+0.23*core,0.12+0.18*core,0.13+0.13*core,
                (0.35+0.58*core)*edge)
            image.set_pixel(x,y,colour)
    image.generate_mipmaps()
    _soot=ImageTexture.create_from_image(image)
    return _soot

static func _scar(parent: Node3D,name: String,at: Vector3,
        scale_2d: Vector2,rotate: Vector3) -> void:
    var decal := MeshInstance3D.new()
    decal.name = name
    var quad := QuadMesh.new()
    quad.size = scale_2d
    decal.mesh = quad
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = _texture()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    decal.material_override=mat
    decal.position=at
    decal.rotation_degrees=rotate
    parent.add_child(decal)

static func _steel() -> StandardMaterial3D:
    if _metal==null:
        _metal=StandardMaterial3D.new()
        _metal.albedo_color=Color("#394C53")
        _metal.metallic=0.31
        _metal.roughness=0.86
    return _metal

static func _shard(parent: Node3D,name: String,
        at: Vector3,angles: Vector3,scale_3d: Vector3) -> void:
    # NOT a BoxMesh. Irregular peaked, CLOSED 3D sheared steel chunk with
    # independently sloped upper surfaces and non-square edge silhouette.
    var pts := [
        Vector3(-0.55,-0.11,-0.40),
        Vector3(0.43,-0.13,-0.48),
        Vector3(0.63,-0.02,0.32),
        Vector3(-0.16,-0.09,0.56),
        Vector3(-0.41,0.19,0.21),
        Vector3(0.16,0.14,-0.03)
    ]
    var order := [
        0,1,5,1,2,5,2,3,5,3,4,5,4,0,5,
        2,1,0,3,2,0,4,3,0
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for idx in order:
        var v: Vector3 = pts[idx]
        st.add_vertex(Vector3(v.x*scale_3d.x,v.y*scale_3d.y,
            v.z*scale_3d.z))
    st.generate_normals()
    var piece:=MeshInstance3D.new()
    piece.name=name
    piece.mesh=st.commit()
    piece.material_override=_steel()
    piece.position=at
    piece.rotation_degrees=angles
    parent.add_child(piece)

static func _retire_boxes(parent: Node) -> int:
    var retired:=0
    for child in parent.get_children():
        if child is MeshInstance3D:
            var mesh: Mesh = (child as MeshInstance3D).mesh
            if mesh is BoxMesh or mesh is CylinderMesh:
                child.visible=false
                retired+=1
        retired+=_retire_boxes(child)
    return retired

static func apply(model: Node3D) -> bool:
    if model==null or model.has_meta("tarvoka_damage_polished_v30"):
        return false
    if not model.get_meta("tarvoka_mbt_track_final_v29",false):
        return false
    var base: Node3D = model.find_child(
        "EtapasDestruccion3D",true,false) as Node3D
    var turret_marks: Node3D = model.find_child(
        "MarcasEnTorre",true,false) as Node3D
    if base==null or turret_marks==null:
        return false
    var retired:=0
    for stage in range(1,5):
        var node: Node3D = base.find_child(
            "DesgasteEtapa%d" % stage,false,false) as Node3D
        if node==null:
            return false
        retired+=_retire_boxes(node)
        if stage==1:
            _scar(node,"ImpactoBiselIrregular",Vector3(0.32,1.01,-1.20),
                Vector2(0.34,0.24),Vector3(-52,0,0))
            _scar(node,"RaspaduraCostado",Vector3(1.315,0.76,-0.47),
                Vector2(0.48,0.24),Vector3(0,90,-8))
        elif stage==2:
            _scar(node,"QuemaduraRejillaMotor",Vector3(0.36,1.163,0.98),
                Vector2(0.56,0.39),Vector3(-90,0,18))
            _scar(node,"ImpactoFaldon",Vector3(1.35,0.69,0.10),
                Vector2(0.51,0.39),Vector3(0,90,13))
            _shard(node,"BlindajeDesgarradoReal",
                Vector3(1.38,0.34,0.34),Vector3(21,13,31),
                Vector3(0.18,0.25,0.42))
        elif stage==3:
            _shard(node,"CadenaRotaFragmentoReal",
                Vector3(1.50,0.23,-0.86),Vector3(-19,10,24),
                Vector3(0.32,0.18,0.61))
            _shard(node,"AceroRasgaduraReal",
                Vector3(0.83,0.66,-1.21),Vector3(17,27,35),
                Vector3(0.49,0.23,0.45))
        else:
            _scar(node,"CarbonInteriorMotor",
                Vector3(0.01,1.153,1.01),Vector2(1.25,0.65),
                Vector3(-90,0,0))
            for i in range(4):
                _shard(node,"EscombroEsculpido%d" % i,
                    Vector3(-0.83+0.44*float(i),0.14,-1.65+0.29*float(i%2)),
                    Vector3(13.0*float(i),26.0*float(i),12.0*float(i)),
                    Vector3(0.25,0.19,0.34))
    retired+=_retire_boxes(turret_marks)
    _scar(turret_marks,"ImpactoTorreSuavizado",
        Vector3(-0.46,0.33,-0.75),Vector2(0.31,0.28),Vector3(-4,0,0))
    var marker:=Node3D.new()
    marker.name=ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_damage_polished_v30",true)
    model.set_meta("tarvoka_damage_polished_v30_retired",retired)
    return true

static func enforce(model: Node3D) -> void:
    # Damage stage code may turn old detached boxes on when recovering HP.
    # Only hide those stage overlays; never suppress the real chassis.
    if model==null or not model.get_meta("tarvoka_damage_polished_v30",false):
        return
    var base: Node3D = model.find_child(
        "EtapasDestruccion3D",true,false) as Node3D
    if base!=null:
        for stage in range(1,5):
            var node: Node3D = base.find_child(
                "DesgasteEtapa%d" % stage,false,false) as Node3D
            if node!=null:
                for part in node.get_children():
                    if part is MeshInstance3D:
                        var mesh: Mesh = (part as MeshInstance3D).mesh
                        if mesh is BoxMesh or mesh is CylinderMesh:
                            part.visible=false
    var turret: Node3D = model.find_child(
        "MarcasEnTorre",true,false) as Node3D
    if turret!=null:
        for part in turret.get_children():
            if part is MeshInstance3D and (
                    (part as MeshInstance3D).mesh is BoxMesh):
                part.visible=false
