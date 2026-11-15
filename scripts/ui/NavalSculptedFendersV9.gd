extends RefCounted
class_name TarvokaNavalSculptedFendersV9

# Native Godot 4.3, visual-only sculpted marine fenders. Replaces prior
# visible fender primitives on new model instances, leaving V8 foam,
# drainage and older comparison modes untouched.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V8=preload("res://scripts/ui/NavalFendersV8.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const RUBBER_SHADER=preload("res://assets/shaders/naval_rubber_pbr_v9.gdshader")
const STAGE_NAME: String="DefensasMaritimasEsculpidasPBRV9"
const IRON=Color("#475b63")
const CAP=Color("#879ca0")
const RUST=Color("#986350")
const DARK=Color("#253841")
const RUBBER=Color("#25333b")
static var _mesh_cache: Dictionary={}
static var _rubber_mats: Dictionary={}

static func _box(root: Node3D,name: String,at: Vector3,
        size: Vector3,color: Color,metal: float=0.28,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(root,name,at,size,color,metal,rot)

static func _cylinder(root: Node3D,name: String,at: Vector3,
        radius: float,height: float,color: Color) -> MeshInstance3D:
    return Base._cylinder(root,name,at,radius,height,color,0.40,12)

static func _ribbed_mesh(torn: bool=false) -> ArrayMesh:
    var key: String="torn" if torn else "whole"
    if _mesh_cache.has(key):
        return _mesh_cache[key] as ArrayMesh
    # A true hand-built 3D rubber skin, not a circular primitive with a
    # painted rib. 16 longitudinal rings x 16 radial segments.
    var vertices:=PackedVector3Array()
    var normals:=PackedVector3Array()
    var uvs:=PackedVector2Array()
    var indices:=PackedInt32Array()
    var rings: int=16
    var sectors: int=16
    for i in range(rings):
        var t: float=float(i)/float(rings-1)
        var y: float=(t-0.5)*(0.29 if torn else 0.53)
        var collar: float=0.83+0.17*sin(PI*t)
        var rib: float=0.019*cos(t*PI*12.0)
        var radius: float=(0.143+rib)*collar
        if torn:
            radius*=0.83+0.10*sin(t*PI*5.0)
        for j in range(sectors+1):
            var a: float=TAU*float(j)/float(sectors)
            var direction:=Vector3(cos(a),0.0,sin(a))
            var location:=Vector3(cos(a)*radius,y,sin(a)*radius*1.18)
            vertices.append(location)
            normals.append(direction.normalized())
            uvs.append(Vector2(float(j)/float(sectors),t))
    for i in range(rings-1):
        for j in range(sectors):
            var a: int=i*(sectors+1)+j
            var b: int=a+sectors+1
            indices.append_array(PackedInt32Array([a,b,b+1,a,b+1,a+1]))
    var arrays: Array=[]
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=vertices
    arrays[Mesh.ARRAY_NORMAL]=normals
    arrays[Mesh.ARRAY_TEX_UV]=uvs
    arrays[Mesh.ARRAY_INDEX]=indices
    var mesh:=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    _mesh_cache[key]=mesh
    return mesh

static func _rubber_material(damage: int) -> ShaderMaterial:
    if _rubber_mats.has(damage):
        return _rubber_mats[damage] as ShaderMaterial
    var material:=ShaderMaterial.new()
    material.shader=RUBBER_SHADER
    material.set_shader_parameter("abrasion",minf(0.85,
        0.17+float(damage)*0.20))
    material.set_shader_parameter("roughness_base",0.86)
    material.set_shader_parameter("rubber_base",
        Color("#25343d") if damage<2 else Color("#394146"))
    material.set_shader_parameter("salt_scuff",Color("#778887"))
    material.set_shader_parameter("wet_rubber",Color("#172b32"))
    _rubber_mats[damage]=material
    return material

static func _sculpt_fender(near: Node3D,far: Node3D,
        label: String,pos: Vector3,damage: int,
        accent: Color,pier: bool) -> void:
    var torn: bool=damage==3
    var assembly:=Base._group(near,label+"_Assembly",pos)
    var body:=MeshInstance3D.new()
    body.name=label+"_SculptedShell"
    body.mesh=_ribbed_mesh(torn)
    body.material_override=_rubber_material(damage)
    body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    body.rotation_degrees=Vector3(0,0,16) if torn else (
        Vector3(0,0,8) if damage==2 else Vector3.ZERO)
    assembly.add_child(body)
    if torn:
        _box(assembly,label+"_CrackRevealed",
            Vector3(-0.115,0.03,0.03),
            Vector3(0.035,0.22,0.10),DARK,0.08,
            Vector3(18,19,31))
        _box(assembly,label+"_TornLip",
            Vector3(-0.112,0.10,0.068),
            Vector3(0.080,0.095,0.05),RUST,0.11,
            Vector3(14,20,9))
        _box(far,label+"_DamagedDistanceProfile",pos,
            Vector3(0.25,0.29,0.30),RUST,0.11,
            Vector3(0,0,15))
        return
    # Two real clamped metal ends; the original V8 metal rings are hidden
    # when this V9 assembly is present, so the structure isn't doubled.
    for sign in [-1,1]:
        if damage==2 and sign==1:
            continue
        var y: float=float(sign)*0.277
        _box(assembly,label+"_Collar_%s" % sign,
            Vector3(0,y,0),
            Vector3(0.33,0.064,0.38),
            IRON if damage<=1 else RUST,0.42)
        _box(assembly,label+"_Band_%s" % sign,
            Vector3(0,y+float(sign)*0.050,0),
            Vector3(0.28,0.024,0.33),CAP,0.38)
        for fastener in [-1,1]:
            _cylinder(assembly,
                label+"_ClampingBolt_%s_%s" % [sign,fastener],
                Vector3(float(fastener)*0.104,y+float(sign)*0.039,
                    0.168),0.025,0.045,CAP)
    # Small anti-slip waist pads and fender's exposed mounting arm.
    for sign in [-1,1]:
        if damage==2 and sign==1:
            continue
        _box(assembly,label+"_UpperGrip_%s" % sign,
            Vector3(0,float(sign)*0.144,0.157),
            Vector3(0.16,0.032,0.032),RUBBER,0.04)
    if damage<=1:
        _box(assembly,label+"_FactionMountingMark",
            Vector3(0,0.327,0),
            Vector3(0.19,0.024,0.17),accent,0.13)
    else:
        _box(assembly,label+"_BentMount",
            Vector3(0,0.28,0),
            Vector3(0.20,0.035,0.15),RUST,0.12,
            Vector3(0,0,-13))
    # A simpler fender silhouette appears when viewing the map from afar.
    _box(far,label+"_DistanceProfile",pos,
        Vector3(0.31,0.53,0.37),
        DARK if damage<=1 else RUST,0.10)

static func _hide_old(model: Node3D,name: String) -> void:
    var visual: Node3D=model.find_child(name,true,false) as Node3D
    if visual!=null:
        visual.visible=false

static func _remove_overlapping_originals(model: Node3D,
        damage: int) -> void:
    # The V8 geometry stays in memory for V8-only comparisons, but is
    # invisible when V9 is on. Never hide V8's foam, drains or markers.
    for i in range(7):
        var suffix: String="%02d" % i
        for prefix in [
            "DefensaDeGomaMuelles_","GomaVerticalMuelle_",
            "ChapaAceroDefensa_","FenderVerticalMuelleEste_",
            "FenderSiluetaMuelleEste_",
            "GomaMuelleEsteRota_"]:
            _hide_old(model,prefix+suffix)
        for suffix2 in [
            "_SoporteSuperior","_SoporteInferior","_AnilloCaucho"]:
            _hide_old(model,"FenderVerticalMuelleEste_"+suffix+suffix2)
    for side in [-1,1]:
        for i in range(6):
            _hide_old(model,"DefensaModularEspigon_%s_%d" % [side,i])
        for i in range(3):
            var prefix: String="DefensaNeumaticaEspigon_%s_%d" % [side,i]
            for tail in ["","_SoporteSuperior","_SoporteInferior",
                "_AnilloCaucho"]:
                _hide_old(model,prefix+tail)
            _hide_old(model,"DefensaTacticaEspigon_%s_%d" % [side,i])
            _hide_old(model,"DefensaEspigonRota_%s_%d" % [side,i])
    if damage==4:
        # Keep V8's authentic loose rubber debris; it is not intact.
        return

static func _assemble(stage: Node3D,damage: int,
        accent: Color) -> void:
    var near: Node3D=stage.get_node("DefensasEsculpidasCercaV9")
    var far: Node3D=stage.get_node("DefensasSiluetaLejosV9")
    if damage==4:
        # V8 has retained real rubble. The V9 is deliberately empty.
        return
    for i in range(7):
        if damage>=2 and i in [2,3]:
            continue
        _sculpt_fender(near,far,
            "MuelleEste_%02d" % i,
            Vector3(1.040,0.31,-4.10+float(i)*1.35),
            damage,accent,false)
    for side in [-1,1]:
        # Positive pier truly does not exist at damage 3.
        if damage>=3 and side==1:
            continue
        for i in range(3):
            if damage>=2 and i==1:
                continue
            _sculpt_fender(near,far,
                "Espigon_%s_%d" % [side,i],
                Vector3(-5.10+float(i)*1.83,0.31,
                    float(side)*4.19),damage,accent,true)

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var root: Node3D=model.get_node(STAGE_NAME)
    (root.get_node("DefensasEsculpidasCercaV9") as Node3D).visible=near_view
    (root.get_node("DefensasSiluetaLejosV9") as Node3D).visible=not near_view
    root.set_meta("naval_v9_close_mode",near_view)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V8.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    var root:=Base._group(model,STAGE_NAME)
    Base._group(root,"DefensasEsculpidasCercaV9")
    Base._group(root,"DefensasSiluetaLejosV9")
    _remove_overlapping_originals(model,damage)
    _assemble(root,damage,Style.faction_color(faction))
    root.set_meta("naval_v9_damage",damage)
    root.set_meta("naval_v9_level",level)
    root.set_meta("naval_v9_faction",faction)
    root.set_meta("naval_v9_pbr_rubber",true)
    set_detail(model,true)
    return true
