extends RefCounted
class_name TarvokaInfantryEngineerOuterArmorV17

# Real 3D organic hard-surface art pass over V16's closed anatomical core.
# Replace existing mesh resources and positions, never add a new renderable.
# Unchanged: arm/leg pivots, animation contacts, faction paints, hit boxes,
# AI, damage, captures and tactical slot count.
const V13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const V14=preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const V16=preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const FLAG: String="tarvoka_engineer_outer_armor_v17"
const OLD: String="tarvoka_engineer_outer_armor_v17_original"
const NEW: String="tarvoka_engineer_outer_armor_v17_sculpt"
const FRONT: String="V8_PetoDelanteroContinuo"
const SHOULDER: String="V8_HombreraAnatomica"
const INSIGNIA: String="V8_EscudoTecnicoPecho"
const KNEE: String="Rodillera"
const POCKET: String="BolsilloPierna"
const SOLE: String="V2_Suela"
const TOE: String="V2_PunteraProtegida"
const CASE: String="V12_EstucheDorsalContorneado"
const FACE_PARTS: Array[String]=["V5_ViseraObraIngeniero",
    "V5_InsigniaCascoIngeniero","V9_VisorContinuoOpaco",
    "V7_MascaraResistenciaIngeniero","V7_FiltroCentralRespirador"]
const ELBOW: String="V10_CubiertaCodo"
const CLOTH_PARTS: Array[String]=["V2_MusloTaper","V2_PantorrillaTaper",
    "V2_MangaCerrada","V2_AntebrazoCerrado"]
const FOLD_VISIBLE: String="tarvoka_v17_old_fold_visibility"

static func cloth_labels() -> Array[String]:
    var result: Array[String]=[]
    for side in [-1,1]:
        for prefix in CLOTH_PARTS:
            result.append(prefix+"_%d"%side)
    return result

static func old_fold_labels() -> Array[String]:
    var result: Array[String]=[]
    for side in [-1,1]:
        for row in range(3):
            result.append("V2_PlisePantalon_%d_%d"%[side,row])
            result.append("V2_PliseManga_%d_%d"%[side,row])
    return result
const HAND_PALMS: Array[String]=["V9_GuanteContacto_-1",
    "V9_GuanteContacto_1","V9_GuanteTrabajoFijadoHerramienta"]
const HAND_CUFFS: Array[String]=["V10_MunecaContactoFusil_-1",
    "V10_MunecaContactoFusil_1","V10_MunecaContactoHerramienta"]

static func hand_digits(hero: bool) -> Array[String]:
    var labels: Array[String]=[]
    for i in range(3):
        if hero:
            for side in [-1,1]:
                labels.append("V9_DedosCerrados_%d_%d"%[side,i])
        labels.append("V10_DedoHerramienta_%d"%i)
    return labels

static func _find(model: Node3D, name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _find(model,FRONT)!=null and
        _find(model,SHOULDER+"_-1")!=null and
        _find(model,SHOULDER+"_1")!=null)

static func _change(model: Node3D, name: String,
        new_mesh: Mesh, new_scale: Vector3,
        new_pos: Vector3) -> bool:
    var part: MeshInstance3D=_find(model,name)
    if part==null or new_mesh==null:
        return false
    part.set_meta(OLD,{
        "mesh":part.mesh,
        "scale":part.scale,
        "position":part.position})
    part.set_meta(NEW,{
        "mesh":new_mesh,
        "scale":new_scale,
        "position":new_pos})
    part.mesh=new_mesh
    part.scale=new_scale
    part.position=new_pos
    return true

static func _place(model: Node3D, name: String,
        new_position: Vector3) -> bool:
    var part: MeshInstance3D=_find(model,name)
    if part==null:
        return false
    return _change(model,name,part.mesh,part.scale,new_position)

# Bend an actual closed press around the face, keeping clockwise triangles
# and transforming normals by the inverse transpose of the local shear.
# The outer edges sweep toward +Z (back) rather than hovering over the face.
static func _conformal_press(w: float,h: float,d: float,r: float,
        bulge: float,sweep: float,hero: bool) -> ArrayMesh:
    var source: ArrayMesh=V13._rounded_press(w,h,d,r,bulge,hero)
    var arrays: Array=source.surface_get_arrays(0)
    var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    var raw: Variant=arrays[Mesh.ARRAY_INDEX]
    var indices: PackedInt32Array=(raw if raw is PackedInt32Array
        else PackedInt32Array())
    var out:=SurfaceTool.new()
    out.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half: float=w*0.5
    var count: int=indices.size() if not indices.is_empty() else points.size()
    for i in range(count):
        var ix: int=indices[i] if not indices.is_empty() else i
        var p: Vector3=points[ix]
        var n: Vector3=normals[ix]
        var slope: float=2.0*sweep*p.x/(half*half)
        p.z+=sweep*pow(p.x/half,2.0)
        out.set_normal(Vector3(n.x-slope*n.z,n.y,n.z).normalized())
        out.add_vertex(p)
    return out.commit()

# Existing gloves use their weapon/tool rig as parent. Preserve the
# contact centres and all V9 visibility switching, changing meshes only.
static func _sculpt_hands(model: Node3D, hero: bool) -> bool:
    var gun: Node3D=model.find_child("ArmamentoRig",true,false) as Node3D
    var tool: Node3D=model.find_child("V6_HerramientaArticuladaRig",true,false) as Node3D
    if gun==null or tool==null:
        return false
    # A tapered heel and broad knuckles replace the spherical mitt.
    var palm_mesh: ArrayMesh=V13._lathe([
        Vector3(0.047,-0.081,0.058),
        Vector3(0.073,-0.065,0.078),
        Vector3(0.084,-0.029,0.088),
        Vector3(0.082,0.018,0.087),
        Vector3(0.064,0.055,0.072),
        Vector3(0.048,0.083,0.053)
    ],hero)
    # Broad overlapping wrist cuff, no opening through the hand.
    var cuff_mesh: ArrayMesh=V13._lathe([
        Vector3(0.053,-0.075,0.059),
        Vector3(0.072,-0.050,0.076),
        Vector3(0.075,0.027,0.077),
        Vector3(0.065,0.069,0.068)
    ],hero)
    for i in range(HAND_PALMS.size()):
        var palm: MeshInstance3D=_find(model,HAND_PALMS[i])
        var cuff: MeshInstance3D=_find(model,HAND_CUFFS[i])
        var rig: Node3D=tool if i==2 else gun
        if palm==null or cuff==null or palm.get_parent()!=rig or cuff.get_parent()!=rig:
            return false
        if not _change(model,HAND_PALMS[i],palm_mesh,Vector3.ONE,palm.position):
            return false
        if not _change(model,HAND_CUFFS[i],cuff_mesh,Vector3.ONE,cuff.position):
            return false
    # Separate curved finger volumes, sharing one closed mesh per LOD.
    # Their bases overlap the palm; no new digits or rig nodes are added.
    var digit_mesh: ArrayMesh=V13._lathe([
        Vector3(0.013,-0.052,0.017),
        Vector3(0.020,-0.038,0.028),
        Vector3(0.023,-0.005,0.035),
        Vector3(0.022,0.030,0.032),
        Vector3(0.016,0.053,0.021)
    ],hero)
    for label in hand_digits(hero):
        var digit: MeshInstance3D=_find(model,label)
        var rig: Node3D=tool if label.begins_with("V10_") else gun
        if digit==null or digit.get_parent()!=rig:
            return false
        var original: Vector3=digit.position
        # Curl back into the palm, preserving the contact point of the grip.
        var fitted: Vector3=original+Vector3(0,0.008,0.006)
        if not _change(model,label,digit_mesh,Vector3.ONE,fitted):
            return false
    return true

# Continuous cloth relief: deform the existing closed anatomical mesh,
# not a stack of disconnected stripes. Fade to zero at both end caps so
# all original contacts with knees, elbows, boots and shoulders survive.
# The analytic inverse-transpose Jacobian keeps smooth lighting normals.
# Same triangle count and mesh-node budget, lower amplitude on LOD8.
static func _cloth_relief(source: Mesh, hero: bool,
        side: int, cycles: float) -> ArrayMesh:
    if source==null or source.get_surface_count()!=1:
        return null
    var arrays: Array=source.surface_get_arrays(0)
    var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    if points.is_empty() or points.size()!=normals.size():
        return null
    var raw: Variant=arrays[Mesh.ARRAY_INDEX]
    var indices: PackedInt32Array=(raw if raw is PackedInt32Array
        else PackedInt32Array())
    var bounds: AABB=source.get_aabb()
    var span: float=maxf(0.001,bounds.size.y)
    var rx: float=maxf(0.001,bounds.size.x*0.5)
    var rz: float=maxf(0.001,bounds.size.z*0.5)
    var amp: float=0.075 if hero else 0.032
    var frequency: float=TAU*cycles
    var ax: float=float(side)*0.85/rx
    var az: float=0.52/rz
    var out:=SurfaceTool.new()
    out.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int=indices.size() if not indices.is_empty() else points.size()
    for i in range(count):
        var ix: int=indices[i] if not indices.is_empty() else i
        var p: Vector3=points[ix]
        var n: Vector3=normals[ix]
        var t: float=clampf((p.y-bounds.position.y)/span,0.0,1.0)
        var envelope: float=pow(sin(PI*t),2.0)
        var phase: float=frequency*t+ax*p.x+az*p.z+float(side)*0.25
        var wave: float=sin(phase)
        var f: float=1.0+amp*envelope*wave
        var fx: float=amp*envelope*cos(phase)*ax
        var fz: float=amp*envelope*cos(phase)*az
        var fy: float=amp*(PI*sin(2.0*PI*t)*wave+
            envelope*cos(phase)*frequency)/span
        var jacobian:=Basis(
            Vector3(f+p.x*fx,0,p.z*fx),
            Vector3(p.x*fy,1,p.z*fy),
            Vector3(p.x*fz,0,f+p.z*fz))
        out.set_normal((jacobian.inverse().transposed()*n).normalized())
        out.add_vertex(Vector3(p.x*f,p.y,p.z*f))
    return out.commit()

static func _sculpt_uniform(model: Node3D, hero: bool) -> bool:
    for side in [-1,1]:
        for index in range(CLOTH_PARTS.size()):
            var label: String=CLOTH_PARTS[index]+"_%d"%side
            var cloth: MeshInstance3D=_find(model,label)
            if cloth==null:
                return false
            var cycles: float=[2.0,1.5,1.7,1.15][index]
            if not _change(model,label,_cloth_relief(cloth.mesh,hero,side,cycles),
                    cloth.scale,cloth.position):
                return false
    # The older rigid strips remain in the scene for exact comparisons.
    # Hide only the redundant fold geometry, not straps or faction marks.
    if hero:
        for label in old_fold_labels():
            var stripe: MeshInstance3D=_find(model,label)
            if stripe==null:
                return false
            stripe.set_meta(FOLD_VISIBLE,stripe.visible)
            stripe.visible=false
    return true

# Woven straps must bend along their length, not resemble rigid beams.
# Starting from a closed press keeps the rim and underside real.
static func _strap_press(w: float,h: float,d: float,bow: float,
        hero: bool) -> ArrayMesh:
    var base: ArrayMesh=V13._rounded_press(w,h,d,w*0.24,d*0.16,hero)
    var arrays: Array=base.surface_get_arrays(0)
    var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    var raw: Variant=arrays[Mesh.ARRAY_INDEX]
    var indices: PackedInt32Array=(raw if raw is PackedInt32Array
        else PackedInt32Array())
    var out:=SurfaceTool.new()
    out.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half: float=h*0.5
    var count: int=indices.size() if not indices.is_empty() else points.size()
    for i in range(count):
        var ix: int=indices[i] if not indices.is_empty() else i
        var p: Vector3=points[ix]
        var n: Vector3=normals[ix]
        var slope: float=2.0*bow*p.y/(half*half)
        p.z+=bow*pow(p.y/half,2.0)
        out.set_normal(Vector3(n.x,n.y-slope*n.z,n.z).normalized())
        out.add_vertex(p)
    return out.commit()

# All entries reuse real existing nodes and their materials. The dorsal
# load straps replace cylindrical rods with broad textile ribbons; their
# original rotation is preserved, so both endpoints stay near the carrier.
static func harness_labels(hero: bool) -> Array[String]:
    var labels: Array[String]=["V5_ArnesDiagonalIngeniero"]
    for side in [-1,1]:
        var suffix: String="_%d"%side
        for prefix in ["V2_CinchaPortaequipo","V5_SujecionBarreraIngeniero",
                "V12_CinchaCargaDorsal","V2_FaccionCincha"]:
            labels.append(prefix+suffix)
        if hero:
            for prefix in ["V9_BrocheArnesFijo","V12_CierrePouchMetalico",
                    "V8_CosturaHombrera"]:
                labels.append(prefix+suffix)
            for row in range(2):
                labels.append("V12_CosturaEstuche_%d_%d"%[side,row])
    return labels

static func _sculpt_harness(model: Node3D,hero: bool) -> bool:
    for label in harness_labels(hero):
        var part: MeshInstance3D=_find(model,label)
        if part==null or part.mesh==null:
            return false
        var dims: Vector3=part.mesh.get_aabb().size
        var pos: Vector3=part.position
        var replacement: ArrayMesh
        var scale: Vector3=Vector3.ONE
        if label=="V5_ArnesDiagonalIngeniero":
            # The enlarged V17 breastplate protrudes beyond V15's strap.
            # Lay the strap across its front, curling ends toward the body.
            replacement=_strap_press(0.108,0.640,0.036,0.080,hero)
            pos.z=-0.493
        elif label.begins_with("V12_CinchaCargaDorsal"):
            replacement=_strap_press(0.058,dims.y,0.022,-0.018,hero)
        elif label.begins_with("V2_CinchaPortaequipo"):
            replacement=_strap_press(0.073,0.610,0.037,-0.028,hero)
        elif label.begins_with("V5_SujecionBarreraIngeniero"):
            replacement=_strap_press(0.103,0.280,0.037,-0.018,hero)
        elif label.begins_with("V2_FaccionCincha"):
            replacement=_strap_press(0.056,0.116,0.018,-0.006,hero)
        elif label.begins_with("V9_BrocheArnesFijo"):
            # Solid cast clasp with curved face and full underside.
            replacement=V13._rounded_press(0.110,0.080,0.038,
                0.018,0.006,hero)
        elif label.begins_with("V12_CierrePouchMetalico"):
            replacement=V13._rounded_press(0.073,0.039,0.029,
                0.010,0.004,hero)
        elif label.begins_with("V8_CosturaHombrera"):
            replacement=_conformal_press(0.220,0.016,0.018,
                0.005,0.003,0.020,hero)
        else:
            # Existing case seam was a cylinder. Use a slim sewn welt
            # instead, preserving the original case-facing orientation.
            replacement=_strap_press(0.013,dims.y,0.011,-0.003,hero)
        if not _change(model,label,replacement,scale,pos):
            return false
    return true

# Real PBR finish, independent of topology. Explicit lists exclude all
# faction insignia, impact effects, hidden legacy geometry and weapon FX.
# A shared, tileable neutral texture works even on procedural UV-less
# meshes via local triplanar projection. Tactical LOD uses no new maps.
const FINISH_OLD: String="tarvoka_v17_original_material"
const FINISH_NEW: String="tarvoka_v17_pbr_material"
const FINISH_KIND: String="tarvoka_v17_surface_kind"
static var _finish_textures: Dictionary={}
const WEAR_SOURCE: String="tarvoka_v17_wear_source_mesh"
const WEAR_KIND: String="tarvoka_v17_local_wear_kind"

# Only already-sculpted closed armor, boots and cases receive local wear.
# No faction emblems, optic, moving contacts or damage effects are touched.
static func wear_kind(label: String) -> String:
    if label==FRONT:
        return "armor"
    for prefix in [SHOULDER,ELBOW,KNEE]:
        if label.begins_with(prefix+"_"):
            return "armor"
    for prefix in [SOLE,TOE]:
        if label.begins_with(prefix+"_"):
            return "boot"
    if label.begins_with(CASE+"_"):
        return "case"
    return ""

# Vertex colors are bound to the mesh, not the world or camera. Use
# exposure-biased, continuous masks with a restrained contrast range.
# Preserve exact vertex order, normals, indices and primitive type.
static func _wear_mesh(source: ArrayMesh,kind: String) -> ArrayMesh:
    if source==null or source.get_surface_count()!=1:
        return null
    var arrays: Array=source.surface_get_arrays(0)
    var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    if points.is_empty() or points.size()!=normals.size():
        return null
    var aabb: AABB=source.get_aabb()
    var extent: Vector3=Vector3(maxf(aabb.size.x,0.001),
        maxf(aabb.size.y,0.001),maxf(aabb.size.z,0.001))
    var colors:=PackedColorArray()
    colors.resize(points.size())
    for i in range(points.size()):
        var p: Vector3=(points[i]-aabb.position)/extent
        var n: Vector3=normals[i]
        var edge: float=smoothstep(0.66,0.98,maxf(absf(p.x-0.5)*2.0,
            absf(p.y-0.5)*2.0))
        var speck: float=0.5+0.5*sin(p.x*31.0+p.y*27.0+p.z*19.0)
        var patch: float=0.5+0.5*sin(p.x*9.0-p.y*13.0+p.z*7.0)
        var tone: float=0.95-0.035*patch
        match kind:
            "armor":
                # Brighter rubbed bevels; irregular darker scuffs on exposed panels.
                tone=0.94+0.06*edge-0.075*(1.0-edge)*patch*speck
            "boot":
                # Dirt-like dark marks are strongest near the sole and toe.
                tone=0.97-0.13*(1.0-smoothstep(0.08,0.68,p.y))*patch
                tone-=0.035*maxf(0.0,-n.z)*speck
            "case":
                # Abrasion on projecting corners of the field equipment.
                tone=0.94+0.045*edge-0.070*patch*speck
        tone=clampf(tone,0.82,1.0)
        colors[i]=Color(tone,tone,tone,1.0)
    arrays[Mesh.ARRAY_COLOR]=colors
    var result:=ArrayMesh.new()
    result.add_surface_from_arrays(source.surface_get_primitive_type(0),arrays)
    return result

static func _local_wear(model: Node3D,hero: bool) -> bool:
    if not hero:
        return true
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        var kind: String=wear_kind(str(part.name))
        if kind.is_empty():
            continue
        if not part.has_meta(NEW) or not part.mesh is ArrayMesh:
            return false
        var source: ArrayMesh=part.mesh as ArrayMesh
        var worn: ArrayMesh=_wear_mesh(source,kind)
        if worn==null:
            return false
        part.set_meta(WEAR_SOURCE,source)
        part.set_meta(WEAR_KIND,kind)
        var state: Dictionary=part.get_meta(NEW)
        state["mesh"]=worn
        part.set_meta(NEW,state)
        part.mesh=worn
    return true

static func surface_kind(label: String) -> String:
    if label in ["V9_VisorContinuoOpaco","V8_LenteProtegida"]:
        return "optic"
    if label in [FRONT,"V9_CascoContinuoBiselado",
            "V12_EscudoCentralBiseladoCerrado"]:
        return "ceramic"
    if label in ["V7_FiltroCentralRespirador","V12_CierreCentralMetal",
            "V8_RielOpticoSuperior","V8_CarcasaFusilIngeniero",
            "V8_GuardamanosPerforado"]:
        return "metal"
    if label in HAND_PALMS or label in HAND_CUFFS or label in [
            "V7_MascaraResistenciaIngeniero","V8_EmpunaduraAntideslizante"]:
        return "rubber"
    if label in cloth_labels() or label in BODY_PARTS or label=="V2_MochilaOrganica":
        return "fabric"
    for prefix in [SHOULDER,ELBOW,KNEE,"V12_CorazaExteriorBarreraCerrada",
            "V12_RevestimientoAlaArticulada","V12_TapaEstucheBiselada"]:
        if label.begins_with(prefix+"_"):
            return "ceramic"
    for prefix in [CASE,POCKET,"V2_CinchaPortaequipo",
            "V12_CinchaCargaDorsal","V5_SujecionBarreraIngeniero",
            "V9_ArnesDorsalFijo",LINK_PREFIX]:
        if label.begins_with(prefix+"_"):
            return "fabric"
    for prefix in [SOLE,TOE,"V9_DedosCerrados","V10_DedoHerramienta"]:
        if label.begins_with(prefix+"_"):
            return "rubber"
    for prefix in ["V9_BrocheArnesFijo","V12_CierrePouchMetalico",
            "V12_RemacheExterior"]:
        if label.begins_with(prefix+"_"):
            return "metal"
    return ""

static func _surface_texture(kind: String) -> Texture2D:
    if _finish_textures.has(kind):
        return _finish_textures[kind] as Texture2D
    var img: Image=Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var u: float=TAU*float(x)/64.0
            var v: float=TAU*float(y)/64.0
            var grain: float=sin(13.0*u+17.0*v)*sin(19.0*u-11.0*v)
            var tone: float=0.96+0.022*grain
            match kind:
                "fabric":
                    tone=0.91+0.045*cos(8.0*u)*cos(8.0*v)+0.023*grain
                "metal":
                    # Short broken abrasion lines, repeated seamlessly
                    # on metal only. No faction paint or optic is altered.
                    var scratch: float=pow(maxf(0.0,cos(9.0*v+2.0*u)),18.0)
                    var broken: float=smoothstep(0.35,0.82,0.5+0.5*sin(3.0*u-2.0*v))
                    tone=0.95+0.028*sin(16.0*v+sin(2.0*u))+0.010*grain
                    tone-=0.065*scratch*broken
                "rubber":
                    tone=0.93+0.036*cos(8.0*u)*cos(8.0*v)+0.012*grain
                "ceramic":
                    tone=0.96+0.025*grain+0.012*sin(3.0*u-5.0*v)
            tone=clampf(tone,0.82,1.0)
            img.set_pixel(x,y,Color(tone,tone,tone,1.0))
    img.generate_mipmaps()
    var texture: ImageTexture=ImageTexture.create_from_image(img)
    _finish_textures[kind]=texture
    return texture

static func _pbr_surface(original: StandardMaterial3D, kind: String,
        hero: bool, worn: bool) -> StandardMaterial3D:
    var mat: StandardMaterial3D=original.duplicate() as StandardMaterial3D
    mat.vertex_color_use_as_albedo=worn
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    mat.cull_mode=BaseMaterial3D.CULL_BACK
    mat.clearcoat_enabled=false
    mat.metallic_specular=0.42
    match kind:
        "ceramic":
            mat.metallic=0.06
            mat.roughness=0.56
            mat.metallic_specular=0.35
        "metal":
            mat.metallic=0.78
            mat.roughness=0.34
        "fabric":
            mat.metallic=0.0
            mat.roughness=0.94
            mat.metallic_specular=0.20
        "rubber":
            mat.metallic=0.0
            mat.roughness=0.83
            mat.metallic_specular=0.28
        "optic":
            mat.metallic=0.10
            mat.roughness=0.16
            mat.clearcoat_enabled=true
            mat.clearcoat=0.72
            mat.clearcoat_roughness=0.17
    if hero and kind!="optic":
        mat.albedo_texture=_surface_texture(kind)
        mat.uv1_triplanar=true
        mat.uv1_world_triplanar=false
        mat.uv1_scale=Vector3.ONE*3.0
        mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    return mat

static func _surface_finish(model: Node3D,hero: bool) -> bool:
    var cache: Dictionary={}
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        var kind: String=surface_kind(str(part.name))
        if kind.is_empty():
            continue
        var original: StandardMaterial3D=part.material_override as StandardMaterial3D
        if original==null:
            return false
        var worn: bool=part.has_meta(WEAR_SOURCE)
        var key: String=str(original.get_instance_id())+":"+kind+":"+str(worn)
        if not cache.has(key):
            cache[key]=_pbr_surface(original,kind,hero,worn)
        part.set_meta(FINISH_OLD,original)
        part.set_meta(FINISH_NEW,cache[key])
        part.set_meta(FINISH_KIND,kind)
        part.material_override=cache[key] as StandardMaterial3D
    return true

# The original V9 contact link is an animated cylinder. Replace only
# its mesh with a tapered fabric sleeve; V9 still computes its exact
# position, quaternion and length on every pose. The comparison must
# never restore a stale pose transform.
const LINK_PREFIX: String="V9_AntebrazoHaciaEmpunadura"
const LINK_OLD: String="tarvoka_v17_link_original"
const LINK_NEW: String="tarvoka_v17_link_anatomic"

static func _sculpt_contact_links(model: Node3D, hero: bool) -> bool:
    var sleeve: ArrayMesh=V13._lathe([
        Vector3(0.067,-0.5,0.071),
        Vector3(0.076,-0.37,0.075),
        Vector3(0.073,-0.20,0.071),
        Vector3(0.059,-0.04,0.063),
        Vector3(0.063,0.12,0.066),
        Vector3(0.053,0.29,0.055),
        Vector3(0.050,0.5,0.052)
    ],hero)
    for side in [-1,1]:
        var link: MeshInstance3D=_find(model,LINK_PREFIX+"_%d"%side)
        var arm: Node3D=model.find_child("BrazoRig_%d"%side,true,false) as Node3D
        if link==null or arm==null or link.get_parent()!=arm:
            return false
        link.set_meta(LINK_OLD,link.mesh)
        link.set_meta(LINK_NEW,sleeve)
        link.mesh=sleeve
    return true

static func show_finish(model: Node3D, enabled: bool) -> bool:
    if not has_model(model):
        return false
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if part.has_meta(LINK_OLD) and part.has_meta(LINK_NEW):
            part.mesh=part.get_meta(LINK_NEW if enabled else LINK_OLD)
        if part.has_meta(FOLD_VISIBLE):
            part.visible=false if enabled else bool(part.get_meta(FOLD_VISIBLE))
        if part.has_meta(FINISH_OLD) and part.has_meta(FINISH_NEW):
            part.material_override=part.get_meta(FINISH_NEW if enabled else FINISH_OLD)
        if not part.has_meta(OLD) or not part.has_meta(NEW):
            continue
        var data: Dictionary=part.get_meta(NEW if enabled else OLD)
        part.mesh=data["mesh"]
        part.scale=data["scale"]
        part.position=data["position"]
    model.set_meta("tarvoka_engineer_v17_visible",enabled)
    return true

# Rebalance the real body underneath the armor. Keep the original rig
# positions, leg lengths, movement pivots and silhouette height.
# A deeper ribcage makes contact with the front armor; the wider lower
# torso and tapered pelvis overlap rather than appearing as separate beads.
const BODY_PARTS: Array[String]=["PetoBase","CinturaEquipo"]
static func _sculpt_body(model: Node3D,hero: bool) -> bool:
    var torso: Node3D=model.find_child("TorsoRig",true,false) as Node3D
    var hips: Node3D=model.find_child("CaderaRig",true,false) as Node3D
    var core: MeshInstance3D=_find(model,BODY_PARTS[0])
    var pelvis: MeshInstance3D=_find(model,BODY_PARTS[1])
    if core==null or pelvis==null or torso==null or hips==null or (
            core.get_parent()!=torso or pelvis.get_parent()!=hips):
        return false
    var trunk: Array=[
        Vector3(0.207,-0.477,0.153),
        Vector3(0.282,-0.405,0.202),
        Vector3(0.332,-0.252,0.238),
        Vector3(0.377,-0.046,0.286),
        Vector3(0.394,0.155,0.304),
        Vector3(0.351,0.323,0.265),
        Vector3(0.194,0.435,0.160)]
    var waist: Array=[
        Vector3(0.181,-0.188,0.120),
        Vector3(0.277,-0.125,0.185),
        Vector3(0.311,0.008,0.211),
        Vector3(0.279,0.117,0.191),
        Vector3(0.186,0.176,0.136)]
    if not _change(model,BODY_PARTS[0],V13._lathe(trunk,hero,-0.034),
            core.scale,core.position):
        return false
    if not _change(model,BODY_PARTS[1],V13._lathe(waist,hero,-0.008),
            pelvis.scale,pelvis.position):
        return false
    return true

static func apply(model: Node3D, hero: bool) -> bool:
    if model==null or has_model(model) or not V16.has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!="infantry_engineer":
        return false
    var torso: Node3D=model.find_child(
        "TorsoRig",true,false) as Node3D
    var pelvis: Node3D=model.find_child(
        "CaderaRig",true,false) as Node3D
    if torso==null or pelvis==null:
        return false

    if not _sculpt_body(model,hero):
        return false

    # Exterior replaces the previously almost-flat V8 chest plate.
    # A strongly tapered, double-sided-volume 360 shell follows shoulders
    # into abdomen, physically wrapping V16's narrower waist.
    var breast: MeshInstance3D=_find(model,FRONT)
    if breast==null or breast.get_parent()!=torso:
        return false
    var chest_rings: Array=[
        Vector3(0.093,-0.272,0.024),
        Vector3(0.174,-0.221,0.039),
        Vector3(0.252,-0.132,0.051),
        Vector3(0.327,0.024,0.074),
        Vector3(0.334,0.143,0.079),
        Vector3(0.244,0.236,0.060),
        Vector3(0.093,0.271,0.027)
    ]
    if not _change(model,FRONT,V13._lathe(chest_rings,hero),
            Vector3.ONE,
            Vector3(0.0,-0.023,-0.407)):
        return false

    # Faction medallion has to remain on the NEW front surface, not buried
    # inside the chest armor. Its original real material is preserved.
    var chest_mark: MeshInstance3D=_find(model,INSIGNIA)
    if chest_mark==null or chest_mark.get_parent()!=torso:
        return false
    if not _place(model,INSIGNIA,
            Vector3(0.0,0.128,-0.495)):
        return false

    # Sculpt the existing construction brow, faction band, optic and
    # respirator as nested curved solid parts, preserving the head pivot.
    # All materials stay opaque; no fake glass or layered duplicate nodes.
    var head: Node3D=model.find_child("CabezaRig",true,false) as Node3D
    if head==null:
        return false
    var face_specs: Array=[
        [0.570,0.126,0.128,0.039,0.014,0.065,Vector3(0,0.451,-0.316)],
        [0.345,0.069,0.024,0.018,0.004,0.024,Vector3(0,0.470,-0.394)],
        [0.410,0.136,0.065,0.037,0.014,0.051,Vector3(0,0.255,-0.293)],
        [0.345,0.196,0.100,0.050,0.019,0.045,Vector3(0,0.122,-0.286)],
        [0.154,0.098,0.044,0.026,0.008,0.009,Vector3(0,0.115,-0.352)]
    ]
    for i in range(FACE_PARTS.size()):
        var face: MeshInstance3D=_find(model,FACE_PARTS[i])
        if face==null or face.get_parent()!=head:
            return false
        var spec: Array=face_specs[i]
        if not _change(model,FACE_PARTS[i],_conformal_press(
                float(spec[0]),float(spec[1]),float(spec[2]),
                float(spec[3]),float(spec[4]),float(spec[5]),hero),
                Vector3.ONE,spec[6]):
            return false

    # Native side view showed the original V7 rear faction plate
    # floating out from the helmet's curved silhouette. Conform the
    # existing badge to the rear shell rather than stack another badge.
    var rear_badge: MeshInstance3D=_find(model,"V7_IdentidadCascoPosterior")
    if rear_badge==null or rear_badge.get_parent()!=head:
        return false
    if not _change(model,rear_badge.name,_conformal_press(
            0.270,0.065,0.020,0.018,0.004,-0.038,hero),
            Vector3.ONE,Vector3(0,0.390,0.341)):
        return false
    # The V2 crown marker also remains a separate slab; follow the
    # curved helmet cap, keeping the same faction material.
    var crown_badge: MeshInstance3D=_find(model,"V2_FaccionCasco")
    if crown_badge==null or crown_badge.get_parent()!=head:
        return false
    if not _change(model,crown_badge.name,_conformal_press(
            0.240,0.064,0.022,0.017,0.004,0.032,hero),
            Vector3.ONE,Vector3(0,0.548,-0.222)):
        return false

    # The V14 rounded shoulder was physically undersized and looked like
    # an isolated ball. New deltoids cover arm roots and descend toward
    # the biceps. Still a CLOSED continuous solid on each original arm rig.
    # Broad sloped deltoid armor, NOT the oversize sphere revealed by
    # the first 5-angle V17 native render. The shoulder has a flatter
    # upper crest, defined sidewall and a narrower bicep contact.
    var shoulder_rings: Array=[
        Vector3(0.072,-0.470,0.077),
        Vector3(0.160,-0.415,0.169),
        Vector3(0.271,-0.266,0.273),
        Vector3(0.379,-0.070,0.332),
        Vector3(0.382,0.109,0.337),
        Vector3(0.331,0.252,0.301),
        Vector3(0.204,0.370,0.207),
        Vector3(0.085,0.432,0.104)
    ]
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var arm: Node3D=model.find_child(
            "BrazoRig"+suffix,true,false) as Node3D
        if arm==null or arm.get_parent()!=torso:
            return false
        var shoulder: MeshInstance3D=_find(model,SHOULDER+suffix)
        if shoulder==null or shoulder.get_parent()!=arm:
            return false
        if not _change(model,SHOULDER+suffix,
                V13._lathe(shoulder_rings,hero),
                Vector3(0.68,0.55,0.65),
                Vector3(0.0,-0.083,-0.065)):
            return false
        # Place existing painted faction shoulder strip ON the outer
        # contour; otherwise a larger real shoulder would swallow it.
        var stripe: MeshInstance3D=_find(model,
            "V8_FaccionHombrera"+suffix)
        if stripe==null or stripe.get_parent()!=arm:
            return false
        if not _place(model,stripe.name,
                Vector3(float(side)*0.249,-0.074,-0.091)):
            return false

        # Existing elbow protector becomes a shaped hard-shell cap, fitted
        # to the flexible elbow seal without touching the dynamic grip link.
        var elbow: MeshInstance3D=_find(model,ELBOW+suffix)
        if elbow==null or elbow.get_parent()!=arm:
            return false
        if not _change(model,ELBOW+suffix,
                _conformal_press(0.184,0.158,0.068,0.045,
                    0.014,0.022,hero),Vector3.ONE,elbow.position):
            return false

        var leg: Node3D=model.find_child(
            "PiernaRig"+suffix,true,false) as Node3D
        if leg==null or leg.get_parent()!=pelvis:
            return false
        # The ORIGINAL V1 kneecap was still a hard rectangular block on top
        # of V16's organic leg. Replace the actual source node, not an
        # unrigged visual overlay. Both faces and sidewalls are closed.
        var pad: MeshInstance3D=_find(model,KNEE+suffix)
        if pad==null or pad.get_parent()!=leg:
            return false
        if not _change(model,KNEE+suffix,
                V13._rounded_press(0.282,0.196,0.083,0.072,
                    0.016,hero),
                Vector3.ONE,
                Vector3(0,-0.476,-0.165)):
            return false

        # Remove the impression of square pouches and blocky soles.
        # These are original scene nodes, still tracking leg movement.
        var pocket: MeshInstance3D=_find(model,POCKET+suffix)
        if pocket==null or pocket.get_parent()!=leg:
            return false
        if not _change(model,POCKET+suffix,
                V13._rounded_press(0.116,0.214,0.177,0.044,
                    0.018,hero),Vector3.ONE,
                Vector3(float(side)*0.145,-0.266,-0.011)):
            return false
        var sole: MeshInstance3D=_find(model,SOLE+suffix)
        if sole==null or sole.get_parent()!=leg:
            return false
        if not _change(model,SOLE+suffix,
                V13._lathe([
                    Vector3(0.099,-0.045,0.194),
                    Vector3(0.130,-0.028,0.226),
                    Vector3(0.132,0.014,0.229),
                    Vector3(0.116,0.043,0.210)
                ],hero),Vector3.ONE,
                Vector3(0,-0.930,-0.128)):
            return false

        # Replace the isolated sphere at the toe with a low, reinforced
        # closed boot cap that overlaps the boot and the actual outsole.
        var toe: MeshInstance3D=_find(model,TOE+suffix)
        if toe==null or toe.get_parent()!=leg:
            return false
        if not _change(model,TOE+suffix,V13._lathe([
                    Vector3(0.091,-0.066,0.074),
                    Vector3(0.119,-0.042,0.105),
                    Vector3(0.120,0.006,0.112),
                    Vector3(0.093,0.043,0.093),
                    Vector3(0.049,0.061,0.052)
                ],hero),Vector3.ONE,Vector3(0,-0.850,-0.300)):
            return false

        # Existing rear case gets a more structured rounded housing,
        # keeping its lids, latches, paint and the original torso rig.
        var case_part: MeshInstance3D=_find(model,CASE+suffix)
        if case_part==null or case_part.get_parent()!=torso:
            return false
        if not _change(model,CASE+suffix,V13._lathe([
                    Vector3(0.066,-0.174,0.078),
                    Vector3(0.101,-0.148,0.116),
                    Vector3(0.115,-0.097,0.128),
                    Vector3(0.119,0.090,0.127),
                    Vector3(0.108,0.144,0.115),
                    Vector3(0.070,0.174,0.080)
                ],hero),case_part.scale,case_part.position):
            return false

        # Keep existing tactical LOD8 identity on the outside of the
        # new pad, not inside it. No faction material is recreated.
        if not hero:
            var marker: MeshInstance3D=_find(model,
                "V3_IdentidadRodillaMapa"+suffix)
            if marker==null or marker.get_parent()!=leg:
                return false
            if not _place(model,marker.name,
                    Vector3(0,-0.485,-0.227)):
                return false

    if not _sculpt_hands(model,hero) or not _sculpt_uniform(model,hero):
        return false
    if not _sculpt_contact_links(model,hero):
        return false
    if not _sculpt_harness(model,hero):
        return false
    if not _local_wear(model,hero) or not _surface_finish(model,hero):
        return false

    # No new MeshInstance3D; all faction materials and collision bodies stay.
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v17_visible",true)
    model.set_meta("tarvoka_engineer_v17_hero",hero)
    return true
