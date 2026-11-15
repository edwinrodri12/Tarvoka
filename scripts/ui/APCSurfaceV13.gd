extends RefCounted
class_name TarvokaAPCSurfaceV13

# P06 V13: commercial-style material and finish art on the *real* sculpt.
# Reuses the approved eight faction enamels; no gameplay, health, sound,
# particles or movement changes. Original materials are kept for comparison.
const V2=preload("res://scripts/ui/APCArmorV2.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const V12=preload("res://scripts/ui/APCTurretV12.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const FLAG := "tarvoka_apc_surface_v13"
const ROOT := "P06V13_AcabadosYDesgaste3D"
const WELDS := "P06V13_SoldaduraOndulada"
const CHIPS := "P06V13_DesgasteDeBordes"
const SCUFFS := "P06V13_RozadurasLeves"
const MEDIUM := "P06V13_PinturaSaltada"
const CRITICAL := "P06V13_MetalChamuscado"
const TURRET_WELDS := "P06V13_JuntasTorreta"
const FASTENERS := "P06V13_PernosTorreta"
const PAINT_RECORDS := "tarvoka_apc_v13_paint_records"
const SHOW := "tarvoka_apc_v13_visible"
const STAGE := "tarvoka_apc_v13_damage_stage"
const TEXTURE_SIZE := 128
const BOLT_COUNT := 12
static var _coat_tex: ImageTexture
static var _rough_tex: ImageTexture

static func _make_texture(rough: bool) -> ImageTexture:
    var image:=Image.create(TEXTURE_SIZE,TEXTURE_SIZE,false,
        Image.FORMAT_RGBA8)
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            var u: float=float(x)
            var v: float=float(y)
            # Multiscale deterministic manufacturing grain, not random
            # temporal noise. Scratches/dust are handled by 3D geometry.
            var a: float=sin(u*1.81+v*0.38)*cos(v*0.97-u*0.24)
            var b: float=sin((u+v)*0.219)*cos((u-v)*0.347)
            var fine: float=sin(u*3.11-v*1.79)
            var value: float=0.93+0.033*a+0.025*b+0.010*fine
            if rough:
                value=0.74+0.115*a+0.052*b+0.022*fine
            value=clampf(value,0.58,0.995)
            image.set_pixel(x,y,Color(value,value,value,1.0))
    image.generate_mipmaps()
    return ImageTexture.create_from_image(image)

static func coating_texture() -> ImageTexture:
    if _coat_tex==null:
        _coat_tex=_make_texture(false)
    return _coat_tex

static func roughness_texture() -> ImageTexture:
    if _rough_tex==null:
        _rough_tex=_make_texture(true)
    return _rough_tex

static func _mat(color: Color,metal: float=0.34,
        rough: float=0.78) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _paint(color: Color,secondary: bool=false) -> StandardMaterial3D:
    var mat:=_mat(color,0.24 if not secondary else 0.30,
        0.77 if not secondary else 0.81)
    mat.albedo_texture=coating_texture()
    mat.roughness_texture=roughness_texture()
    mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
    mat.normal_enabled=true
    mat.normal_texture=V2._finish_normal()
    mat.normal_scale=0.23
    # Godot procedural SurfaceTool meshes need triplanar UV projection:
    # ordinary UV maps would evaluate all of V11's unwrapped polygons at
    # a single texture pixel. Local triplanar follows rotating turrets too.
    mat.uv1_triplanar=true
    mat.uv1_scale=Vector3(3.5,3.5,3.5)
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    return mat

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _patch(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,material: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var box:=BoxMesh.new()
    box.size=size
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=box
    node.material_override=material
    node.position=pos
    node.rotation_degrees=rotation
    parent.add_child(node)
    return node

static func _weld(parent: Node3D,name: String,
        edges: Array,metal: Material) -> MeshInstance3D:
    # Uninterrupted raised seam with gently uneven weld beads.
    # All segments from the entire chassis section share ONE real mesh.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for line in edges:
        var points: PackedVector3Array=line
        if points.size()<2:
            continue
        for seg in range(points.size()-1):
            var from: Vector3=points[seg]
            var to: Vector3=points[seg+1]
            var d: Vector3=to-from
            var axis: Vector3=d.normalized()
            if d.length()<0.001:
                continue
            var basis: Basis=Basis(Quaternion(Vector3.UP,axis))
            var pieces: int=maxi(3,int(ceil(d.length()/0.019)))
            for i in range(pieces):
                var a: float=float(i)/float(pieces)
                var b: float=float(i+1)/float(pieces)
                var start: Vector3=from.lerp(to,a)
                var end: Vector3=from.lerp(to,b)
                var radius_a: float=0.0065+0.0013*sin(
                    float(i)*2.9+float(seg))
                var radius_b: float=0.0065+0.0013*sin(
                    float(i+1)*2.9+float(seg))
                for j in range(6):
                    var theta: float=TAU*float(j)/6.0
                    var next: float=TAU*float(j+1)/6.0
                    var p0: Vector3=basis*Vector3(
                        radius_a*cos(theta),0,radius_a*sin(theta))
                    var p1: Vector3=basis*Vector3(
                        radius_a*cos(next),0,radius_a*sin(next))
                    var p2: Vector3=basis*Vector3(
                        radius_b*cos(next),0,radius_b*sin(next))
                    var p3: Vector3=basis*Vector3(
                        radius_b*cos(theta),0,radius_b*sin(theta))
                    for vtx in [start+p0,start+p1,end+p2,
                            start+p0,end+p2,end+p3]:
                        st.add_vertex(vtx)
    st.generate_normals()
    var weld:=MeshInstance3D.new()
    weld.name=name
    weld.mesh=st.commit()
    weld.material_override=metal
    parent.add_child(weld)
    return weld

static func _body_welds(root: Node3D,weld: Material,
        steel: Material) -> void:
    var section:=_group(root,WELDS)
    var segments: Array=[]
    for side in [-1,1]:
        var s: float=float(side)
        segments.append(PackedVector3Array([
            Vector3(s*0.10,1.174,-1.255),
            Vector3(s*0.395,1.151,-1.252),
            Vector3(s*0.68,1.130,-1.259)]))
        for z in [-0.597,0.061,0.723]:
            segments.append(PackedVector3Array([
                Vector3(s*0.863,1.285,z),
                Vector3(s*0.880,1.183,z),
                Vector3(s*0.892,1.087,z)]))
        segments.append(PackedVector3Array([
            Vector3(s*0.83,1.337,-1.11),
            Vector3(s*0.83,1.337,-0.40),
            Vector3(s*0.83,1.337,0.31),
            Vector3(s*0.83,1.337,1.14)]))
    _weld(section,"P06V13_CordonesSoldaduraReales",segments,weld)
    # A few honest small exposed metal edges on high-contact points,
    # rather than drawing dozens of random identical white scratches.
    var edge:=_group(root,CHIPS)
    for side in [-1,1]:
        var s: float=float(side)
        for axle in range(3):
            var z: float=float([-1.04,0.0,1.07][axle])
            for i in range(3):
                var angle: float=0.49+float(i)*1.02
                var radius: float=0.458
                var where:=Vector3(s*0.992,
                    0.43+radius*sin(angle),z+radius*cos(angle))
                _patch(edge,
                    "P06V13_MetalExpuestoGuardabarros_%d_%d_%d" %
                    [side,axle,i],
                    where,Vector3(0.006,0.013,0.029),
                    steel,Vector3(s*5.0,0,s*(15.0-float(i)*11.0)))

static func _turret_finish(turret: Node3D,
        weld: Material,steel: Material) -> void:
    var section:=_group(turret,TURRET_WELDS)
    var lines: Array=[]
    for side in [-1,1]:
        var s: float=float(side)
        lines.append(PackedVector3Array([
            Vector3(s*0.153,0.419,-0.196),
            Vector3(s*0.175,0.416,-0.04),
            Vector3(s*0.153,0.419,0.19)]))
        lines.append(PackedVector3Array([
            Vector3(s*0.272,0.290,-0.228),
            Vector3(s*0.293,0.229,-0.162),
            Vector3(s*0.291,0.191,-0.070)]))
    _weld(section,"P06V13_SoldaduraTorretaOndulada",lines,weld)
    var bolts:=MultiMeshInstance3D.new()
    bolts.name=FASTENERS
    var bolt_mesh:=CylinderMesh.new()
    bolt_mesh.top_radius=0.014
    bolt_mesh.bottom_radius=0.014
    bolt_mesh.height=0.014
    bolt_mesh.radial_segments=6
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=bolt_mesh
    mm.instance_count=BOLT_COUNT
    for i in range(BOLT_COUNT):
        var theta: float=TAU*float(i)/float(BOLT_COUNT)
        var pos:=Vector3(0.297*cos(theta),0.071,0.297*sin(theta))
        mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,pos))
    bolts.multimesh=mm
    bolts.material_override=steel
    turret.add_child(bolts)

static func _usage(root: Node3D,steel: Material,
        rubbed: Material,char: Material) -> void:
    var scuffs:=_group(root,SCUFFS)
    scuffs.visible=false
    _patch(scuffs,"P06V13_RoceCantoGlacis",
        Vector3(-0.329,1.148,-1.477),
        Vector3(0.190,0.009,0.017),steel,Vector3(0,0,11))
    _patch(scuffs,"P06V13_MarcaGuardabarrosDerecho",
        Vector3(0.996,0.872,-1.060),
        Vector3(0.009,0.014,0.172),rubbed,Vector3(12,0,0))
    _patch(scuffs,"P06V13_MarcaLadoIzquierdo",
        Vector3(-0.884,1.212,0.410),
        Vector3(0.008,0.019,0.215),steel,Vector3(0,0,8))

    var med:=_group(root,MEDIUM)
    med.visible=false
    _patch(med,"P06V13_PinturaSaltadaPanelDerecho",
        Vector3(0.890,1.191,-0.50),
        Vector3(0.010,0.110,0.062),steel,Vector3(0,0,-12))
    _patch(med,"P06V13_LimiteOxidacionMarco",
        Vector3(-0.771,1.116,-1.243),
        Vector3(0.044,0.021,0.073),rubbed,Vector3(0,24,16))
    _patch(med,"P06V13_ChapaMarcadaGlacis",
        Vector3(0.422,0.999,-1.47),
        Vector3(0.095,0.021,0.026),steel,Vector3(0,0,-16))
    var critical:=_group(root,CRITICAL)
    critical.visible=false
    _patch(critical,"P06V13_ChamuscadoPanelRoto",
        Vector3(0.872,1.145,-0.389),
        Vector3(0.015,0.211,0.236),char,Vector3(0,0,11))
    _patch(critical,"P06V13_RasgadoPinturaProa",
        Vector3(-0.262,0.958,-1.487),
        Vector3(0.196,0.091,0.016),char,Vector3(0,-12,5))
    # The center of these burn marks is hidden behind actual V7
    # physically bent plates: no floating damage textures or large smoke box.

static func _needs_coating(name: String) -> int:
    # Return 0 for unaffected optical lenses/rubber/steel, 1 for painted
    # armor and 2 for darker factory-coated service covers.
    if name=="CascoBlindadoEsculpidoP06":
        return 1
    for prefix in [
            "P06V11_GlacisBisagrado_",
            "P06V11_ModuloBlindaje_",
            "P06V11_GuardabarrosCurvo_",
            "P06V11_CartelaUnion_",
            "P06V11_LabioBlindajeParrilla",
            "P06V11_ViseraFaro_",
            "P06V12_CarcasaOctogonalCerrada",
            "P06V12_RefuerzoLateral_",
            "P06V12_PlacaServicioSuperior",
            "P06V12_ModuloTelemetro",
            "P06V12_EscudoSuperiorTelemetro",
            "P06V12_CajaMecanismo",
            "P06V10_MarcoBlindado_",
            "P06V10_ChapaBlindajeExteriorRampa"]:
        if name.begins_with(prefix):
            return 1
    for prefix in [
            "P06V11_TapaPestillo_",
            "P06V11_RefuerzoRefrigeracion_",
            "P06V12_CanalCableado_",
            "P06V12_TapaSensorZoom"]:
        if name.begins_with(prefix):
            return 2
    return 0

static func _records(model: Node3D,
        primary: Material,secondary: Material) -> Array:
    var changed: Array=[]
    for part in model.find_children("*","MeshInstance3D",true,false):
        var piece: MeshInstance3D=part as MeshInstance3D
        var usage: int=_needs_coating(piece.name)
        if usage>0:
            var new_mat: Material=primary if usage==1 else secondary
            changed.append([piece,piece.material_override,new_mat])
            piece.material_override=new_mat
    return changed

static func _restore_materials(model: Node3D,enabled: bool) -> void:
    var records: Array=model.get_meta(PAINT_RECORDS,[])
    for entry in records:
        var piece: MeshInstance3D=entry[0] as MeshInstance3D
        if piece!=null and is_instance_valid(piece):
            piece.material_override=entry[2] if enabled else entry[1]

static func apply(model: Node3D,faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V12.FLAG,false)):
        return false
    if model.get_meta(FLAG,false):
        return true
    var v11: Node3D=model.find_child(V11.ROOT,true,false) as Node3D
    var turret: Node3D=model.find_child(V12.ROOT,true,false) as Node3D
    if v11==null or turret==null:
        return false
    var root:=_group(v11,ROOT)
    var primary: Material=_paint(Color("#54636a").lerp(faction_color,0.56))
    var secondary: Material=_paint(
        Color("#35464b").lerp(faction_color,0.33),true)
    var weld: Material=_mat(Color("#656e71"),0.58,0.65)
    var brushed: Material=_mat(Color("#91999b"),0.65,0.56)
    var dirt: Material=_mat(Color("#565249"),0.12,0.94)
    var char: Material=_mat(Color("#292d2d"),0.08,0.98)
    _body_welds(root,weld,brushed)
    _turret_finish(turret,weld,brushed)
    _usage(root,brushed,dirt,char)
    model.set_meta(PAINT_RECORDS,_records(model,primary,secondary))
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return true

static func set_stage(model: Node3D,value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int=clampi(value,0,4)
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    if root!=null:
        root.visible=enabled and stage<4
    var welds: Node3D=model.find_child(
        TURRET_WELDS,true,false) as Node3D
    if welds!=null:
        welds.visible=enabled and stage<4
    var fasteners: Node3D=model.find_child(
        FASTENERS,true,false) as Node3D
    if fasteners!=null:
        fasteners.visible=enabled and stage<4
    for entry in [[SCUFFS,1],[MEDIUM,2],[CRITICAL,3]]:
        var group: Node3D=model.find_child(
            str(entry[0]),true,false) as Node3D
        if group!=null:
            group.visible=enabled and stage>=int(entry[1]) and stage<4
    # Wear overlays must not bridge a physical break in V7's armor.
    var broken_side: Node3D=model.find_child(
        "P06V13_PinturaSaltadaPanelDerecho",true,false) as Node3D
    if broken_side!=null:
        broken_side.visible=enabled and stage==2
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    _restore_materials(model,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
