extends RefCounted
class_name TarvokaAPCMaterialFinishV21

# Bastion P06 V21: real Godot 4.3 PBR surfaces, not an image overlay.
# Procedural 48x48 deterministic texture grain is world/triplanar mapped
# so the V17-V20 six-faced meshes (which lack hand-authored UVs) receive
# the same finish as the original BoxMesh parts. Art only: no stats/physics.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V20 = preload("res://scripts/ui/APCMicrodetailV20.gd")
const FLAG := "tarvoka_apc_materials_v21"
const ROOT := "P06V21_AcabadosPBR"
const SHOW := "tarvoka_apc_v21_visible"
const STAGE := "tarvoka_apc_v21_stage"
const ORIGINAL := "tarvoka_apc_v21_original_mat"
const PALETTE := "tarvoka_apc_v21_palette"
const PAINT := "paint"
const WORN := "worn"
const STEEL := "steel"
const RUBBER := "rubber"
const SCORCH := "scorch"
const SOOT := "soot"
const WELD := "weld"
const TEXTURE_SIZE := 48

static func _grain(seed: int, minimum: float, amplitude: float) -> ImageTexture:
    # Fixed-size generated image, reused by all references within this
    # model. No network assets or implicit resource imports required.
    var img: Image=Image.create(
        TEXTURE_SIZE,TEXTURE_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            var h: int=(x*73+y*151+x*y*29+seed*97) % 251
            var fine: float=float(h)/250.0
            var stripe: float=float((x*3+y+seed)%13)/12.0
            var grain: float=clampf(minimum+
                amplitude*(0.76*fine+0.24*stripe),0.0,1.0)
            img.set_pixel(x,y,Color(grain,grain,grain,1.0))
    return ImageTexture.create_from_image(img)

static func _pbr(color: Color, metallic: float,
        roughness: float, tex: ImageTexture,
        scale: float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metallic
    mat.roughness=roughness
    mat.albedo_texture=tex
    mat.roughness_texture=tex
    mat.uv1_triplanar=true
    mat.uv1_scale=Vector3(scale,scale,scale)
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _palette(faction: Color) -> Dictionary:
    var enamel: Color=Color("#5a6d71").lerp(faction,0.74)
    var paint_texture: ImageTexture=_grain(3,0.90,0.10)
    var steel_texture: ImageTexture=_grain(7,0.79,0.19)
    var rubber_texture: ImageTexture=_grain(11,0.86,0.12)
    var burnt_texture: ImageTexture=_grain(17,0.62,0.34)
    return {
        PAINT:_pbr(enamel,0.36,0.76,paint_texture,4.0),
        WORN:_pbr(enamel.darkened(0.13),0.48,0.81,
            paint_texture,4.0),
        STEEL:_pbr(Color("#9ca9ae"),0.76,0.53,
            steel_texture,6.0),
        RUBBER:_pbr(Color("#32373b"),0.02,0.93,
            rubber_texture,5.0),
        SCORCH:_pbr(Color("#74665b"),0.38,0.86,
            burnt_texture,3.0),
        SOOT:_pbr(Color("#292725"),0.08,0.98,
            burnt_texture,3.0),
        WELD:_pbr(Color("#77858b"),0.68,0.62,
            steel_texture,7.0)
    }

static func _paint_mesh(model: Node3D, name: String,
        material: Material) -> void:
    var mesh: MeshInstance3D=model.find_child(
        name,true,false) as MeshInstance3D
    if mesh==null:
        return
    if not mesh.has_meta(ORIGINAL):
        mesh.set_meta(ORIGINAL,mesh.material_override)
    mesh.material_override=material

static func _reset(model: Node3D, name: String) -> void:
    var mesh: MeshInstance3D=model.find_child(
        name,true,false) as MeshInstance3D
    if mesh!=null and mesh.has_meta(ORIGINAL):
        mesh.material_override=mesh.get_meta(ORIGINAL) as Material

static func _targets(model: Node3D, pal: Dictionary,
        stage: int, enabled: bool) -> void:
    var paint: Material=pal[PAINT]
    var worn: Material=pal[WORN]
    var steel: Material=pal[STEEL]
    var rubber: Material=pal[RUBBER]
    var scorching: Material=pal[SCORCH]
    var soot: Material=pal[SOOT]
    var weld: Material=pal[WELD]

    # Factory paint: stable eight-faction identity and slightly more worn
    # right-hand side in light/medium damage; symmetric when pristine.
    for side in [-1,1]:
        for gap in range(2):
            var damaged_side: bool=(side==1 and stage>=1)
            var coat: Material=worn if damaged_side else paint
            for prefix in ["P06V18_PanelPuente_",
                    "P06V19_ChaflanSuperior_"]:
                var name: String="%s%d_%d" % [prefix,side,gap]
                if enabled:
                    _paint_mesh(model,name,coat)
                else:
                    _reset(model,name)
            for tip in [-1,1]:
                var trim: String="P06V20_RematePintado_%d_%d_%d" % [
                    side,gap,tip]
                if enabled:
                    _paint_mesh(model,trim,coat)
                else:
                    _reset(model,trim)
            for bead in ["P06V20_CordonSuperior_",
                    "P06V20_CordonTalón_"]:
                var label: String="%s%d_%d" % [bead,side,gap]
                if enabled:
                    _paint_mesh(model,label,weld)
                else:
                    _reset(model,label)
            for screw in range(3):
                var base_name: String="P06V20_PernoFaldon_%d_%d_%d" % [
                    side,gap,screw]
                for suffix in ["_Hex","_Arandela"]:
                    if enabled:
                        _paint_mesh(model,base_name+suffix,steel if suffix=="_Hex"
                            else weld)
                    else:
                        _reset(model,base_name+suffix)
        for axle in range(3):
            for segment in range(8):
                var arc: String="P06V19_LabioCurvo_%d_%d_%d" % [
                    side,axle,segment]
                if enabled:
                    _paint_mesh(model,arc,rubber)
                else:
                    _reset(model,arc)
            var bracket: String="P06V19_CartelaSuspension_%d_%d" % [
                side,axle]
            if enabled:
                _paint_mesh(model,bracket,steel)
            else:
                _reset(model,bracket)
            for index in range(3):
                var base_name: String="P06V20_PernoArco_%d_%d_%d" % [
                    side,axle,index]
                for suffix in ["_Hex","_Arandela"]:
                    if enabled:
                        _paint_mesh(model,base_name+suffix,steel)
                    else:
                        _reset(model,base_name+suffix)
        for part in ["P06V17_CuartonTrasero_%d",
                "P06V16_BordeTechoCostado_%d"]:
            var label: String=part % side
            if enabled:
                _paint_mesh(model,label,worn if side==1 and stage>=2 else paint)
            else:
                _reset(model,label)

    # Actual exposed 3D fracture faces, never opaque painted patches.
    var damaged: Array[String]=[
        "P06V20_SoldaduraAbierta",
        "P06V20_AristaMetalExpuesta",
        "P06V19_MuescaOxidadaPuente",
        "P06V20_RayaSuperficial",
        "P06V20_DesgarroTrasero",
        "P06V20_BordeArcoFrontalPartido",
        "P06V19_CantoneraCizallada",
        "P06V19_ArcoFrontalAplastado",
        "P06V18_PanelDerechoDesprendido",
        "P06V20_CordonSeparadoRuina",
        "P06V19_LaminaColapsada"
    ]
    for label in damaged:
        var finish_mat: Material=steel
        if stage>=3:
            finish_mat=scorching
        if stage>=4:
            finish_mat=soot
        if enabled:
            _paint_mesh(model,label,finish_mat)
        else:
            _reset(model,label)

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V20.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var root_node:=Node3D.new()
    root_node.name=ROOT
    model.add_child(root_node)
    root_node.set_meta(PALETTE,_palette(faction_color))
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return set_stage(model,0)

static func set_stage(model: Node3D, value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var root_node: Node3D=model.find_child(
        ROOT,true,false) as Node3D
    if root_node==null:
        return false
    var stage: int=clampi(value,0,4)
    var palette: Dictionary=root_node.get_meta(PALETTE)
    _targets(model,palette,stage,bool(model.get_meta(SHOW,true)))
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D, enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
