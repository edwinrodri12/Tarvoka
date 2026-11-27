extends RefCounted
class_name TarvokaInfantrySculptFinishV2

# Sculpt pass on the EXISTING InfantryFamilyV1 rig: actual sealed, nontransparent
# Godot 4.3 3D surfaces. No tactical roles, stats, saves, or economy.
const FLAG := "tarvoka_infantry_sculpt_finish_v2"
const ROOT := "AcabadoInfanteriaV2"
const SLEEVE := Color("#53655b")
const FABRIC := Color("#637265")
const DARK_FABRIC := Color("#36483e")
const ARMOR := Color("#85938f")
const RIM := Color("#29383c")
const RUBBER := Color("#202a2c")
const METAL := Color("#a7b5b5")
const SKIN := Color("#bd9178")
const GLASS := Color("#204c63")

static func _coat(color: Color, metal: float = 0.0, rough: float = 0.66,
        clear: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(color.r,color.g,color.b,1.0)
    m.metallic = metal
    m.roughness = rough
    m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    if clear:
        m.clearcoat_enabled = true
        m.clearcoat = 0.92
        m.clearcoat_roughness = 0.1
    return m

static func _mesh(parent: Node3D, label: String, mesh: Mesh, coat: StandardMaterial3D,
        pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.material_override = coat
    node.position = pos
    node.rotation_degrees = rot
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, pos: Vector3, dims: Vector3,
        mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var b := BoxMesh.new()
    b.size = dims
    return _mesh(parent,label,b,mat,pos,rot)

static func _sphere(parent: Node3D, label: String, pos: Vector3, dims: Vector3,
        mat: StandardMaterial3D) -> MeshInstance3D:
    var s := SphereMesh.new()
    s.radius = 0.5
    s.height = 1.0
    s.radial_segments = 16
    s.rings = 8
    var n := _mesh(parent,label,s,mat,pos)
    n.scale = dims
    return n

static func _ring_pt(radius: Vector3, segment: int, total: int) -> Vector3:
    var angle: float = TAU*float(segment)/float(total)
    return Vector3(cos(angle)*radius.x,radius.y,sin(angle)*radius.z)

# Every segment is physically capped at each end: no floating cylinders,
# open-sided planes, cut-off legs, backpack shells or faceless proxy surfaces.
static func _organic_mesh(rings: Array[Vector3], sides: int=12,
        offsets: PackedFloat32Array=PackedFloat32Array(), shape: float=1.0,
        center_x: float=0.0) -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int = maxi(8,sides)
    var points: Array[PackedVector3Array] = []
    for row in range(rings.size()):
        var ring := PackedVector3Array()
        var shift: float = offsets[row] if offsets.size()==rings.size() else 0.0
        for i in range(count):
            var pt: Vector3 = _ring_pt(rings[row],i,count)
            if shape!=1.0:
                var angle: float = TAU*float(i)/float(count)
                pt.x = signf(cos(angle))*pow(absf(cos(angle)),shape)*rings[row].x
                pt.z = signf(sin(angle))*pow(absf(sin(angle)),shape)*rings[row].z
            if center_x!=0.0:
                pt.x += center_x
            pt.z += shift
            ring.append(pt)
        points.append(ring)
    for row in range(rings.size()-1):
        for i in range(count):
            var a: Vector3 = points[row][i]
            var b: Vector3 = points[row][(i+1)%count]
            var c: Vector3 = points[row+1][i]
            var d: Vector3 = points[row+1][(i+1)%count]
            # Godot front faces use clockwise winding viewed from outside.
            for v in [a,b,c,b,d,c]:
                tool.add_vertex(v)
    var low: Vector3 = Vector3(center_x,rings[0].y,offsets[0] if offsets.size()==rings.size() else 0.0)
    var top: Vector3 = Vector3(center_x,rings[-1].y,offsets[-1] if offsets.size()==rings.size() else 0.0)
    for i in range(count):
        var lower: Vector3 = points[0][i]
        var lower_next: Vector3 = points[0][(i+1)%count]
        for v in [low,lower_next,lower]:
            tool.add_vertex(v)
        var upper: Vector3 = points[-1][i]
        var upper_next: Vector3 = points[-1][(i+1)%count]
        for v in [top,upper,upper_next]:
            tool.add_vertex(v)
    tool.generate_normals()
    return tool.commit()

static func _organic(parent: Node3D, label: String, pos: Vector3,
        rings: Array[Vector3], material: StandardMaterial3D,
        sides: int = 12) -> MeshInstance3D:
    return _mesh(parent,label,_organic_mesh(rings,sides),material,pos)

# Refine only the five remaining official infantry identities. Keep G05
# and the legacy studies untouched; keep all rig pivots and node names.
const FAMILY_ANATOMY_V5 := "tarvoka_infantry_family_anatomy_v5"
const FAMILY_ANATOMY_ROLES := ["line","infantry_commando","infantry_sniper","infantry_logistic","infantry_medic"]

static func _resculpt(model: Node3D, label: String, profile: Array[Vector3],
        pos: Vector3, sides: int, offsets: PackedFloat32Array=PackedFloat32Array(),
        shape: float=1.0) -> bool:
    var part: MeshInstance3D = _find(model,label) as MeshInstance3D
    if part==null:
        return false
    part.mesh = _organic_mesh(profile,sides,offsets,shape)
    part.position = pos
    part.scale = Vector3.ONE
    part.set_meta(FAMILY_ANATOMY_V5,true)
    return true

static func _refine_core(model: Node3D, hero: bool) -> bool:
    var sides: int = 16 if hero else 10
    if not _resculpt(model,"PetoBase",[
            Vector3(0.20,-0.46,0.15),Vector3(0.27,-0.37,0.20),
            Vector3(0.32,-0.18,0.235),Vector3(0.365,0.075,0.27),
            Vector3(0.345,0.26,0.235),Vector3(0.19,0.41,0.15)],
            Vector3.ZERO,sides):
        return false
    if not _resculpt(model,"CinturaEquipo",[
            Vector3(0.19,-0.17,0.115),Vector3(0.27,-0.115,0.175),
            Vector3(0.30,0.015,0.195),Vector3(0.26,0.12,0.17),
            Vector3(0.18,0.16,0.11)],Vector3.ZERO,sides):
        return false
    for side in [-1,1]:
        var suffix: String = "_%d"%side
        if not _resculpt(model,"Hombrera"+suffix,[
                Vector3(0.113,-0.145,0.118),Vector3(0.156,-0.10,0.147),
                Vector3(0.164,-0.025,0.158),Vector3(0.138,0.065,0.137),
                Vector3(0.075,0.101,0.08)],Vector3(0,0,-0.04),sides):
            return false
        if not _resculpt(model,"V2_MangaCerrada"+suffix,[
                Vector3(0.102,-0.52,0.112),Vector3(0.123,-0.37,0.132),
                Vector3(0.142,-0.16,0.145),Vector3(0.142,-0.03,0.139),
                Vector3(0.117,0.06,0.119)],Vector3(0,0,0.005),sides):
            return false
        if not _resculpt(model,"V2_AntebrazoCerrado"+suffix,[
                Vector3(0.087,-0.755,0.096),Vector3(0.106,-0.66,0.119),
                Vector3(0.123,-0.55,0.131),Vector3(0.116,-0.46,0.122),
                Vector3(0.103,-0.42,0.111)],Vector3(0,0,-0.060),sides):
            return false
        if not _resculpt(model,"Rodillera"+suffix,[
                Vector3(0.077,-0.085,0.034),Vector3(0.109,-0.052,0.056),
                Vector3(0.111,0.042,0.058),Vector3(0.078,0.082,0.036)],
                Vector3(0,-0.48,-0.15),sides,PackedFloat32Array(),0.72):
            return false
        if not _resculpt(model,"V2_BotaMoldeada"+suffix,[
                Vector3(0.112,-0.925,0.196),Vector3(0.126,-0.875,0.204),
                Vector3(0.121,-0.815,0.181),Vector3(0.114,-0.74,0.15),
                Vector3(0.103,-0.655,0.126)],Vector3(0,0,-0.14),sides,
                PackedFloat32Array([0.0,0.0,0.025,0.065,0.10]),0.78):
            return false
        if not _resculpt(model,"V2_Suela"+suffix,[
                Vector3(0.108,-0.9675,0.206),Vector3(0.127,-0.954,0.225),
                Vector3(0.127,-0.91,0.225),Vector3(0.114,-0.8925,0.21)],
                Vector3(0,0,-0.128),sides,PackedFloat32Array(),0.62):
            return false
        _hide(model,"V2_PunteraProtegida"+suffix)
        var badge: MeshInstance3D = _find(model,"FaccionHombro"+suffix) as MeshInstance3D
        if badge!=null:
            badge.position.x=float(side)*0.151
            badge.scale=Vector3(1,0.68,0.76)
        var patch: MeshInstance3D = _find(model,"V2_FaccionParcheManga"+suffix) as MeshInstance3D
        if patch!=null:
            patch.position.x=float(side)*0.132
        for row in range(3):
            _hide(model,"V2_PliseManga_%d_%d"%[side,row])
    model.set_meta(FAMILY_ANATOMY_V5,true)
    if not _refine_head_and_armor(model,hero) or not _refine_face_and_profile(model,hero):
        return false
    if not _refine_v18_visor(model,hero):
        return false
    if not _refine_outer_armor(model,hero) or not _refine_family_legs(model,hero):
        return false
    if not _refine_v15_fit(model,hero) or not _refine_v16_exterior(model,hero):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))=="line" and not refine_v17_kit(model,"line",hero):
        return false
    return _attach_family_grips(model,hero)

const OPTICS_V18 := "tarvoka_infantry_optics_v18"
const OPTICS_TONES_V18 := {
    "line":Color("#315b70"),
    "infantry_commando":Color("#294f60"),
    "infantry_sniper":Color("#395c5e"),
    "infantry_logistic":Color("#53624f"),
    "infantry_medic":Color("#426a72")
}

# A sealed curved lens on the existing helmet rig. No new node, fake
# translucent overlay, or change to the head/weapon articulation.
static func _refine_v18_visor(model: Node3D,hero: bool)->bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if not OPTICS_TONES_V18.has(role):
        return false
    var visor: MeshInstance3D=_find(model,"V2_VisorOpacoPBR") as MeshInstance3D
    if visor==null:
        return false
    var width: float=1.0
    var height: float=1.0
    match role:
        "infantry_commando":
            width=1.03
            height=0.93
        "infantry_sniper":
            width=0.94
            height=0.96
        "infantry_logistic":
            width=1.03
        "infantry_medic":
            width=0.96
            height=1.03
    visor.mesh=_organic_mesh([
        Vector3(0.140*width,-0.071*height,0.031),
        Vector3(0.171*width,-0.055*height,0.052),
        Vector3(0.187*width,-0.026*height,0.066),
        Vector3(0.193*width,0.018*height,0.069),
        Vector3(0.178*width,0.048*height,0.054),
        Vector3(0.147*width,0.069*height,0.032)],
        24 if hero else 12,PackedFloat32Array([0.014,0.004,0.0,0.0,0.008,0.016]),0.73)
    visor.position=Vector3(0,0.235,-0.267)
    visor.scale=Vector3.ONE
    visor.material_override=_coat(OPTICS_TONES_V18[role],0.16,0.085,true)
    model.set_meta(OPTICS_V18,role)
    return true

const GEAR_V17 := "tarvoka_infantry_premium_kit_v17"
const GEAR_COUNT_V17 := "tarvoka_infantry_premium_kit_count_v17"
const GEAR_PARENT_V17 := {
    "line":"V2_MochilaOrganica",
    "infantry_commando":"V9_FS24_Radio",
    "infantry_sniper":"V4_CapaCamuflajePrecision",
    "infantry_logistic":"V4_BolsaSuministros",
    "infantry_medic":"V4_KitMedicoVerde"
}

# Find the actual rear surface of a closed kit, in its own mesh coordinates.
# This avoids projecting the fasteners onto an imaginary bounding box.
static func kit_rear_surface(mesh: Mesh,x: float,y: float)->float:
    var faces: PackedVector3Array=mesh.get_faces()
    var bounds: AABB=mesh.get_aabb()
    var origin:=Vector3(x,y,bounds.end.z+1.0)
    var closest: float=-INF
    for i in range(0,faces.size(),3):
        var hit: Variant=Geometry3D.ray_intersects_triangle(origin,Vector3(0,0,-1),
            faces[i],faces[i+1],faces[i+2])
        if hit is Vector3:
            closest=maxf(closest,(hit as Vector3).z)
    return closest

# Each role receives a tailored flap/cover and two closed fasteners.
# The pieces follow the existing real gear and inherit its local transform.
# The lightweight LOD8 receives only identity metadata.
static func refine_v17_kit(model: Node3D,role: String,hero: bool)->bool:
    if not GEAR_PARENT_V17.has(role):
        return false
    model.set_meta(GEAR_V17,role)
    model.set_meta(GEAR_COUNT_V17,0)
    if not hero:
        return true
    var kit: MeshInstance3D=_find(model,str(GEAR_PARENT_V17[role])) as MeshInstance3D
    if kit==null or kit.mesh==null or not kit.visible:
        return false
    var aabb: AABB=kit.mesh.get_aabb()
    var center: Vector3=aabb.get_center()
    var tone: Color=Color("#465950")
    var width_ratio: float=0.24
    var cover_height: float=0.09
    match role:
        "infantry_commando":
            tone=Color("#263b41")
            width_ratio=0.27
            cover_height=0.11
        "infantry_sniper":
            tone=Color("#4e5d44")
            width_ratio=0.22
            cover_height=0.12
        "infantry_logistic":
            tone=Color("#596748")
            width_ratio=0.26
        "infantry_medic":
            tone=Color("#35584b")
            width_ratio=0.20
    var flap_w: float=aabb.size.x*width_ratio
    var flap_h: float=aabb.size.y*cover_height
    var flap_d: float=aabb.size.z*0.075
    var y: float=aabb.position.y+aabb.size.y*0.77
    var rear: float=kit_rear_surface(kit.mesh,center.x,y)
    if not is_finite(rear):
        return false
    var cloth: StandardMaterial3D=_coat(tone,0.03,0.83)
    var fastener: StandardMaterial3D=_coat(tone.darkened(0.30),0.06,0.72)
    var flap: MeshInstance3D=_mesh(kit,"V17_FabricKitFlap",_organic_mesh([
        Vector3(flap_w*0.68,-flap_h,flap_d*0.55),
        Vector3(flap_w,-flap_h*0.57,flap_d),
        Vector3(flap_w,flap_h*0.52,flap_d),
        Vector3(flap_w*0.72,flap_h,flap_d*0.58)],
        14,PackedFloat32Array(),0.55),cloth,Vector3(center.x,y,rear-flap_d*0.65))
    flap.set_meta("tarvoka_v17_surface_contact",Vector3(center.x,y,rear))
    for side in [-1,1]:
        var x: float=center.x+float(side)*aabb.size.x*0.24
        # Keep the medical cross and the central faction insignia unobstructed.
        var latch_y: float=aabb.position.y+aabb.size.y*0.32
        var latch_z: float=kit_rear_surface(kit.mesh,x,latch_y)
        if not is_finite(latch_z):
            return false
        var lw: float=aabb.size.x*0.048
        var lh: float=aabb.size.y*0.068
        var ld: float=aabb.size.z*0.085
        var latch: MeshInstance3D=_mesh(kit,"V17_RubberKitLatch_%d"%side,_organic_mesh([
            Vector3(lw*0.70,-lh,ld*0.65),Vector3(lw,-lh*0.63,ld),
            Vector3(lw,lh*0.55,ld),Vector3(lw*0.72,lh,ld*0.65)],
            12,PackedFloat32Array(),0.50),fastener,
            Vector3(x,latch_y,latch_z-ld*0.65))
        latch.set_meta("tarvoka_v17_surface_contact",Vector3(x,latch_y,latch_z))
    model.set_meta(GEAR_COUNT_V17,3)
    return true

const BOOTS_V32 := "tarvoka_infantry_boot_finish_v32"
const BOOT_COUNT_V32 := "tarvoka_infantry_boot_detail_count_v32"

# The original boot upper uses its existing ankle-space coordinates.
# Sample the actual forward surface for the fitted toe and instep armor.
static func boot_front_surface_v32(mesh: Mesh,x: float,y: float)->float:
    var faces: PackedVector3Array=mesh.get_faces()
    var bounds: AABB=mesh.get_aabb()
    var origin:=Vector3(x,y,bounds.position.z-1.0)
    var nearest: float=INF
    for i in range(0,faces.size(),3):
        var hit: Variant=Geometry3D.ray_intersects_triangle(origin,Vector3(0,0,1),
            faces[i],faces[i+1],faces[i+2])
        if hit is Vector3:
            nearest=minf(nearest,(hit as Vector3).z)
    return nearest

static func _refine_boots_v32(model: Node3D,paint: Color,hero: bool)->bool:
    if not hero:
        return true
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if role not in FAMILY_ANATOMY_ROLES:
        return false
    var shell: Color=Color("#35454a")
    var weight: float=0.20
    match role:
        "infantry_commando":
            shell=Color("#28373e")
            weight=0.25
        "infantry_sniper":
            shell=Color("#465347")
            weight=0.12
        "infantry_logistic":
            shell=Color("#484d42")
            weight=0.22
        "infantry_medic":
            shell=Color("#536460")
            weight=0.24
    var toe_mat: StandardMaterial3D=_coat(shell.lerp(paint,weight),0.08,0.65)
    var band_mat: StandardMaterial3D=_coat(shell.darkened(0.20),0.02,0.84)
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var boot: MeshInstance3D=_find(model,"V2_BotaMoldeada"+suffix) as MeshInstance3D
        var sole: MeshInstance3D=_find(model,"V2_Suela"+suffix) as MeshInstance3D
        if boot==null or sole==null or boot.get_parent()!=sole.get_parent():
            return false
        var original: AABB=boot.mesh.get_aabb()
        # Broad toe, defined heel/ankle and more gradual instep. The two
        # original longitudinal endpoints and separate outsole are retained.
        boot.mesh=_organic_mesh([
            Vector3(0.112,-0.925,0.196),Vector3(0.124,-0.907,0.203),
            Vector3(0.126,-0.875,0.204),Vector3(0.124,-0.845,0.195),
            Vector3(0.121,-0.815,0.181),Vector3(0.118,-0.775,0.162),
            Vector3(0.110,-0.725,0.145),Vector3(0.103,-0.655,0.126)],
            24,PackedFloat32Array([0,0,0,0.012,0.025,0.047,0.079,0.10]),0.57)
        boot.set_meta("tarvoka_v32_original_bounds",original)
        var toe_y: float=-0.868
        var toe_z: float=boot_front_surface_v32(boot.mesh,0.0,toe_y)
        var band_y: float=-0.789
        var band_z: float=boot_front_surface_v32(boot.mesh,0.0,band_y)
        if not is_finite(toe_z) or not is_finite(band_z):
            return false
        # The protective toe remains a separate closed volume embedded in
        # the boot, above the sole. Both new meshes are children of the
        # actual boot and follow its ankle, never the stationary torso.
        var toe: MeshInstance3D=_mesh(boot,"V32_ArmorToe"+suffix,_organic_mesh([
            Vector3(0.080,-0.045,0.024),Vector3(0.109,-0.028,0.039),
            Vector3(0.110,0.012,0.041),Vector3(0.082,0.037,0.024)],
            20,PackedFloat32Array([0.005,0,0,0.006]),0.58),
            toe_mat,Vector3(0,toe_y,toe_z+0.018))
        toe.set_meta("tarvoka_v32_contact",Vector3(0,toe_y,toe_z))
        var band: MeshInstance3D=_mesh(boot,"V32_RubberInstep"+suffix,_organic_mesh([
            Vector3(0.072,-0.022,0.017),Vector3(0.098,-0.012,0.025),
            Vector3(0.098,0.012,0.025),Vector3(0.073,0.022,0.016)],
            16,PackedFloat32Array(),0.62),band_mat,Vector3(0,band_y,band_z+0.010))
        band.set_meta("tarvoka_v32_contact",Vector3(0,band_y,band_z))
    model.set_meta(BOOTS_V32,role)
    model.set_meta(BOOT_COUNT_V32,4)
    return true

const ANATOMY_V27 := "tarvoka_infantry_anatomical_contours_v27"
const ANATOMY_COUNT_V27 := "tarvoka_infantry_anatomical_count_v27"
const HELMET_V28 := "tarvoka_infantry_helmet_profile_v28"
# Upper arm, forearm, thigh and calf: independent interior shape weights.
# The cap rings and all original joint positions are unchanged. Values
# describe visual cloth volume, not physical size, reach or gameplay.
const LIMB_GAIN_V27 := {
    "line":Vector4(1.0,1.0,1.0,1.0),
    "infantry_commando":Vector4(1.04,1.03,1.03,1.02),
    "infantry_sniper":Vector4(0.95,0.96,0.96,0.97),
    "infantry_logistic":Vector4(1.02,1.0,1.04,1.03),
    "infantry_medic":Vector4(0.97,0.97,0.98,0.98)
}
# Preserve the actual closed endpoints and the length used by the contact
# solver. More rings describe bicep, wrist taper, quadriceps and calf.
static func _limb_mesh_v27(profile: Array[Vector3],offsets: PackedFloat32Array,
        gain: float)->ArrayMesh:
    var refined: Array[Vector3]=[]
    for i in range(profile.size()):
        var p: Vector3=profile[i]
        var blend: float=sin(PI*float(i)/float(profile.size()-1))
        var g: float=lerpf(1.0,gain,blend)
        refined.append(Vector3(p.x*g,p.y,p.z*g))
    return _organic_mesh(refined,20,offsets,0.90)

static func _refine_limbs_v27(model: Node3D,hero: bool)->bool:
    if not hero:
        return true
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if not LIMB_GAIN_V27.has(role):
        return false
    var gain: Vector4=LIMB_GAIN_V27[role]
    var profiles: Dictionary={
        "V2_MangaCerrada":[
            Vector3(0.103,-0.52,0.112),Vector3(0.112,-0.46,0.121),
            Vector3(0.119,-0.38,0.132),Vector3(0.132,-0.28,0.139),
            Vector3(0.141,-0.17,0.143),Vector3(0.142,-0.07,0.139),
            Vector3(0.134,0.01,0.132),Vector3(0.119,0.06,0.12)],
        "V2_AntebrazoCerrado":[
            Vector3(0.091,-0.5,0.104),Vector3(0.099,-0.40,0.108),
            Vector3(0.105,-0.27,0.110),Vector3(0.099,-0.12,0.105),
            Vector3(0.088,0.07,0.094),Vector3(0.076,0.24,0.082),
            Vector3(0.066,0.40,0.071),Vector3(0.061,0.5,0.066)],
        "V2_MusloTaper":[
            Vector3(0.126,-0.52,0.136),Vector3(0.134,-0.46,0.148),
            Vector3(0.145,-0.38,0.158),Vector3(0.155,-0.29,0.173),
            Vector3(0.160,-0.19,0.179),Vector3(0.157,-0.10,0.177),
            Vector3(0.152,-0.03,0.173),Vector3(0.149,0.012,0.169)],
        "V2_PantorrillaTaper":[
            Vector3(0.105,-0.84,0.121),Vector3(0.110,-0.79,0.126),
            Vector3(0.119,-0.73,0.135),Vector3(0.130,-0.66,0.144),
            Vector3(0.140,-0.58,0.151),Vector3(0.138,-0.52,0.149),
            Vector3(0.128,-0.46,0.138),Vector3(0.119,-0.415,0.128)]
    }
    var offsets: Dictionary={
        "V2_MangaCerrada":PackedFloat32Array([0,0.002,0.006,0.010,0.008,0.004,0.001,0]),
        "V2_AntebrazoCerrado":PackedFloat32Array([0,0.002,0.005,0.006,0.004,0.002,0,0]),
        "V2_MusloTaper":PackedFloat32Array([0,0.002,-0.003,-0.009,-0.010,-0.005,0,0]),
        "V2_PantorrillaTaper":PackedFloat32Array([0,0.005,0.012,0.020,0.024,0.017,0.006,0])
    }
    var prefix_names: Array[String]=["V2_MangaCerrada","V2_AntebrazoCerrado","V2_MusloTaper","V2_PantorrillaTaper"]
    var count: int=0
    for side in [-1,1]:
        for i in range(prefix_names.size()):
            var prefix: String=prefix_names[i]
            var part: MeshInstance3D=_find(model,prefix+"_%d"%side) as MeshInstance3D
            if part==null or not part.mesh is ArrayMesh:
                return false
            var before: AABB=part.mesh.get_aabb()
            var profile: Array[Vector3]=[]
            profile.assign(profiles[prefix])
            part.mesh=_limb_mesh_v27(profile,offsets[prefix],gain[i])
            part.set_meta("tarvoka_v27_original_bounds",before)
            count+=1
    model.set_meta(ANATOMY_V27,role)
    model.set_meta(ANATOMY_COUNT_V27,count)
    return true

# Preserve every front vertex of the approved helmet, including its
# visor/brow seat. Only the rear shell receives a role-specific crown
# and occipital contour. This is a deterministic deformation of the
# existing closed triangles, not a second overlapping shell.
const HELMET_PROFILE_V28 := {
    "line":Vector2(0.035,0.025),
    "infantry_commando":Vector2(0.075,0.050),
    "infantry_sniper":Vector2(-0.065,-0.055),
    "infantry_logistic":Vector2(0.050,0.065),
    "infantry_medic":Vector2(-0.035,0.035)
}

static func _helmet_vertex_v28(vertex: Vector3,bounds: AABB,profile: Vector2)->Vector3:
    var center: Vector3=bounds.get_center()
    var height: float=clampf((vertex.y-bounds.position.y)/bounds.size.y,0.0,1.0)
    var rear: float=clampf((vertex.z-center.z)/maxf(0.0001,bounds.size.z*0.5),0.0,1.0)
    var blend: float=rear*sin(PI*height)
    return Vector3(vertex.x*(1.0+profile.x*blend),vertex.y,
        vertex.z+profile.y*bounds.size.z*blend)

static func _refine_helmet_v28(model: Node3D,hero: bool)->bool:
    if not hero:
        return true
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if not HELMET_PROFILE_V28.has(role):
        return false
    var helmet: MeshInstance3D=_find(model,"V2_CascoEsferoideCerrado") as MeshInstance3D
    if helmet==null or not helmet.mesh is ArrayMesh:
        return false
    var original: AABB=helmet.mesh.get_aabb()
    # Read the native surface directly: get_faces() goes through the
    # engine's triangle extraction/cache, which need not retain the
    # original vertex precision. The organic source is an unindexed soup.
    var arrays: Array=helmet.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var indices: Variant=arrays[Mesh.ARRAY_INDEX]
    if vertices.is_empty() or vertices.size()%3!=0 or original.size.y<=0.0:
        return false
    if indices!=null and not indices.is_empty():
        return false
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var profile: Vector2=HELMET_PROFILE_V28[role]
    var front_indices:=PackedInt32Array()
    var front_vertices:=PackedVector3Array()
    for i in range(vertices.size()):
        var vertex: Vector3=vertices[i]
        if vertex.z<=original.get_center().z:
            front_indices.append(i)
            front_vertices.append(vertex)
        tool.add_vertex(_helmet_vertex_v28(vertex,original,profile))
    tool.generate_normals()
    helmet.mesh=tool.commit()
    helmet.set_meta("tarvoka_v28_original_bounds",original)
    helmet.set_meta("tarvoka_v28_source_face_count",vertices.size())
    helmet.set_meta("tarvoka_v281_front_indices",front_indices)
    helmet.set_meta("tarvoka_v281_front_vertices",front_vertices)
    model.set_meta(HELMET_V28,role)
    return true

const FACTION_ARMOR_V26 := "tarvoka_infantry_faction_armor_v26"
const FACTION_COUNT_V26 := "tarvoka_infantry_faction_armor_count_v26"
# A stronger shared faction livery, tailored to each role. Helmet, chest,
# shoulders, waist and shins read as painted protective hardware, while
# fabrics, optics, medical symbols and existing exact-color badges stay intact.
const LIVERY_V26 := {
    "line":Vector3(0.55,0.52,0.72),
    "infantry_commando":Vector3(0.44,0.64,0.76),
    "infantry_sniper":Vector3(0.36,0.32,0.55),
    "infantry_logistic":Vector3(0.60,0.55,0.67),
    "infantry_medic":Vector3(0.67,0.58,0.74)
}

static func faction_armor_weight_v26(role: String,label: String)->float:
    var weights: Vector3=LIVERY_V26[role]
    if label=="V2_CascoEsferoideCerrado":
        return weights.x
    if label=="V2_CorazaPectoralHermetica":
        return weights.y
    if label.begins_with("Hombrera_"):
        return weights.z
    if label.begins_with("V16_ArmorShin"):
        return weights.y*0.78
    if label.begins_with("V16_ArmorWaist"):
        return weights.z*0.65
    return weights.y*0.68

static func _refine_faction_armor_v26(model: Node3D,paint: Color,hero: bool)->bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if not LIVERY_V26.has(role):
        return false
    # Never change the already benchmarked Android mesh/material path.
    if not hero:
        return true
    var labels: Array[String]=["V2_CascoEsferoideCerrado","V2_CorazaPectoralHermetica"]
    for side in [-1,1]:
        var suffix: String="_%d"%side
        labels.append_array(["Hombrera"+suffix,"V16_ArmorWaist"+suffix,
            "V16_ArmorShin"+suffix,"V2_CostillaArmadura"+suffix])
    for label in labels:
        var part: MeshInstance3D=_find(model,label) as MeshInstance3D
        if part==null or part.mesh==null or not part.material_override is StandardMaterial3D:
            return false
        var source: StandardMaterial3D=part.material_override as StandardMaterial3D
        var coat: StandardMaterial3D=source.duplicate() as StandardMaterial3D
        var original: Color=source.albedo_color
        var weight: float=faction_armor_weight_v26(role,label)
        coat.albedo_color=Color(original.r,original.g,original.b,1.0).lerp(paint,weight)
        part.material_override=coat
        part.set_meta("tarvoka_v26_base_paint",original)
        part.set_meta("tarvoka_v26_livery_weight",weight)
        if label.begins_with("V2_CostillaArmadura"):
            # Replace the old side plate with a rounded, closed armor rib
            # at its identical pivot and bounding envelope. Role-dependent
            # taper changes the relief, not collision or joint locations.
            var old_bounds: AABB=part.mesh.get_aabb()
            var r: Vector3=old_bounds.size*0.5
            var corner: float=0.58+0.23*float(LIVERY_V26[role].y)
            var rings: Array[Vector3]=[
                Vector3(r.x*corner,-r.y,r.z*corner),
                Vector3(r.x*0.91,-r.y*0.72,r.z*0.91),
                Vector3(r.x,-r.y*0.29,r.z),
                Vector3(r.x,r.y*0.29,r.z),
                Vector3(r.x*0.90,r.y*0.72,r.z*0.90),
                Vector3(r.x*corner,r.y,r.z*corner)]
            part.mesh=_organic_mesh(rings,16,PackedFloat32Array(),0.57)
            part.set_meta("tarvoka_v26_rib_bounds",old_bounds)
    model.set_meta(FACTION_ARMOR_V26,role)
    model.set_meta(FACTION_COUNT_V26,labels.size())
    return true

const PREMIUM_V16 := "tarvoka_infantry_premium_exterior_v16"
const PREMIUM_COUNT_V16 := "tarvoka_infantry_premium_mesh_count_v16"

# Seven small closed pieces on existing head/torso/knee pivots.
# Only studio LOD13 receives added geometry; the tactical tree stays intact.
static func _refine_v16_exterior(model: Node3D,hero: bool) -> bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if role not in FAMILY_ANATOMY_ROLES:
        return false
    model.set_meta(PREMIUM_V16,role)
    model.set_meta(PREMIUM_COUNT_V16,0)
    if not hero:
        return true
    var head: Node3D=_find(model,"CabezaRig")
    var upper: Node3D=_find(model,"TorsoRig")
    var helmet: MeshInstance3D=_find(model,"V2_CascoEsferoideCerrado") as MeshInstance3D
    if head==null or upper==null or helmet==null:
        return false
    # Different armoring weights, without changing shared proportions or
    # repainting the faction emblems. Medical and supply gear remains lighter.
    var profile: Vector3=Vector3(1.0,1.0,1.0)
    var shade: Color=Color("#53645f")
    match role:
        "infantry_commando":
            profile=Vector3(1.08,1.06,1.12)
            shade=Color("#35484c")
        "infantry_sniper":
            profile=Vector3(0.84,0.90,0.85)
            shade=Color("#54684d")
        "infantry_logistic":
            profile=Vector3(0.95,1.0,0.90)
            shade=Color("#626b50")
        "infantry_medic":
            profile=Vector3(0.88,0.90,0.83)
            shade=Color("#72817a")
    var armor: StandardMaterial3D=_coat(shade,0.09,0.62)
    var trim: StandardMaterial3D=_coat(shade.darkened(0.23),0.02,0.86)
    var bounds: AABB=helmet.mesh.get_aabb()
    var rear_z: float=helmet.position.z+bounds.end.z
    var rear_y: float=bounds.position.y+bounds.size.y*0.47
    # Shallow rear neck protector overlaps the shell instead of floating.
    _mesh(head,"V16_ArmorNape",_organic_mesh([
        Vector3(0.105,-0.076,0.025),Vector3(0.153,-0.049,0.043),
        Vector3(0.158,0.027,0.042),Vector3(0.115,0.065,0.022)],
        16,PackedFloat32Array([-0.025,0.0,0.0,-0.012]),0.66),
        armor,Vector3(0,rear_y,rear_z-0.035))
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var knee: Node3D=_find(model,"V11_RodillaRig"+suffix)
        if knee==null:
            return false
        # Recessed shell rail sits along the lower rear flank of the helmet.
        _mesh(head,"V16_RubberHelmetRail"+suffix,_organic_mesh([
            Vector3(0.020,-0.054,0.048),Vector3(0.030,-0.033,0.074),
            Vector3(0.032,0.033,0.074),Vector3(0.020,0.056,0.042)],
            12,PackedFloat32Array(),0.55),trim,
            Vector3(float(side)*(bounds.size.x*0.40),rear_y+0.012,0.13),
            Vector3(0,float(side)*-21,float(side)*-12))
        # Low-profile waist plates live on the torso rig, not on arms.
        _mesh(upper,"V16_ArmorWaist"+suffix,_organic_mesh([
            Vector3(0.062*profile.x,-0.087,0.022*profile.z),
            Vector3(0.100*profile.x,-0.061,0.038*profile.z),
            Vector3(0.105*profile.x,0.039,0.039*profile.z),
            Vector3(0.072*profile.x,0.080,0.023*profile.z)],
            14,PackedFloat32Array(),0.59),armor,
            Vector3(float(side)*0.135,-0.265,-0.237),Vector3(0,float(side)*-15,0))
        # Shins have a separate fitted front shell that follows knee motion.
        _mesh(knee,"V16_ArmorShin"+suffix,_organic_mesh([
            Vector3(0.062*profile.x,-0.259*profile.y,0.023*profile.z),
            Vector3(0.091*profile.x,-0.228*profile.y,0.035*profile.z),
            Vector3(0.101*profile.x,-0.130,0.037*profile.z),
            Vector3(0.087*profile.x,-0.090,0.023*profile.z)],
            14,PackedFloat32Array([0.010,0.0,0.0,0.012]),0.70),
            armor,Vector3(0,0,-0.139))
    model.set_meta(PREMIUM_COUNT_V16,7)
    return true

const FIT_V15 := "tarvoka_infantry_proportions_v15"
const ELBOW_LOCAL := Vector3(0,-0.47,-0.035)

# V14 visual review: reduce projecting knee pads, flatten hero insignia,
# and soften side pouches without increasing mesh counts.
static func _refine_v15_fit(model: Node3D,hero: bool) -> bool:
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var knee: MeshInstance3D=_find(model,"Rodillera"+suffix) as MeshInstance3D
        var badge: MeshInstance3D=_find(model,"FaccionHombro"+suffix) as MeshInstance3D
        if knee==null or badge==null:
            return false
        knee.mesh=_organic_mesh([
            Vector3(0.082,-0.107,0.022),Vector3(0.116,-0.073,0.032),
            Vector3(0.119,0.045,0.034),Vector3(0.085,0.099,0.022)],
            16 if hero else 10,PackedFloat32Array([0.012,0.0,0.0,0.012]),0.6)
        knee.position.z=-0.159
        if hero:
            badge.mesh=_organic_mesh([
                Vector3(0.014,-0.061,0.054),Vector3(0.022,-0.045,0.080),
                Vector3(0.022,0.045,0.080),Vector3(0.014,0.061,0.054)],
                12,PackedFloat32Array(),0.6)
            badge.scale=Vector3.ONE
            var pouch: MeshInstance3D=_find(model,"BolsaCostado"+suffix) as MeshInstance3D
            if pouch!=null:
                pouch.mesh=_organic_mesh([
                    Vector3(0.048,-0.137,0.080),Vector3(0.074,-0.110,0.116),
                    Vector3(0.074,0.084,0.116),Vector3(0.053,0.137,0.089)],
                    12,PackedFloat32Array(),0.55)
                pouch.scale=Vector3.ONE
    model.set_meta(FIT_V15,str(model.get_meta("tarvoka_infantry_role","")))
    return true

const FAMILY_IDENTITY_V6 := "tarvoka_infantry_role_identity_v6"
# Role-specific closed helmets; scale and material changes apply only
# to the five official non-engineer models. Paint is never recolored.
static func _refine_head_and_armor(model: Node3D, hero: bool) -> bool:
    var role: String = str(model.get_meta("tarvoka_infantry_role",""))
    var sides: int = 20 if hero else 12
    var width: float = 1.0
    var height: float = 1.0
    var depth: float = 1.0
    var shade: Color = Color("#85938f")
    var vest_scale := Vector3.ONE
    match role:
        "line":
            shade=Color("#84918c")
        "infantry_commando":
            width=0.98
            height=0.95
            depth=1.02
            shade=Color("#46545b")
            vest_scale=Vector3(1.04,1.0,1.14)
        "infantry_sniper":
            width=1.03
            height=0.96
            depth=1.04
            shade=Color("#65765f")
            vest_scale=Vector3(0.91,0.94,0.82)
        "infantry_logistic":
            width=1.045
            height=0.97
            shade=Color("#838b74")
            vest_scale=Vector3(1.0,1.0,0.9)
        "infantry_medic":
            width=0.96
            height=1.01
            shade=Color("#9da9a3")
            vest_scale=Vector3(0.95,0.98,0.9)
        _:
            return false
    var profile: Array[Vector3]=[]
    for ring in [Vector3(0.175,0.105,0.18),Vector3(0.239,0.165,0.236),
            Vector3(0.281,0.255,0.28),Vector3(0.290,0.39,0.292),
            Vector3(0.267,0.505,0.265),Vector3(0.185,0.585,0.185),
            Vector3(0.073,0.635,0.075)]:
        profile.append(Vector3(ring.x*width,ring.y*height,ring.z*depth))
    if not _resculpt(model,"V2_CascoEsferoideCerrado",profile,Vector3(0,0,0.016),sides):
        return false
    var helmet: MeshInstance3D=_find(model,"V2_CascoEsferoideCerrado") as MeshInstance3D
    helmet.material_override=_coat(shade,0.10,0.57)
    # Integrated curved opaque visor replaces the box without changing
    # the original material or node identity used by damage/LOD QA.
    var visor: MeshInstance3D=_find(model,"V2_VisorOpacoPBR") as MeshInstance3D
    if visor==null:
        return false
    visor.mesh=_organic_mesh([Vector3(0.143,-0.069,0.037),
        Vector3(0.181,-0.041,0.064),Vector3(0.190,0.021,0.067),
        Vector3(0.151,0.068,0.041)],sides,PackedFloat32Array(),0.64)
    visor.position=Vector3(0,0.235,-0.267)
    visor.scale=Vector3.ONE
    _hide(model,"V2_ReflejoCristalFisico")
    var chest: MeshInstance3D=_find(model,"V2_CorazaPectoralHermetica") as MeshInstance3D
    var collar: MeshInstance3D=_find(model,"CuelloProtegido") as MeshInstance3D
    if chest==null or collar==null:
        return false
    chest.scale=vest_scale
    chest.material_override=_coat(shade.lightened(0.05),0.11,0.59)
    collar.mesh=_organic_mesh([Vector3(0.145,-0.10,0.13),
        Vector3(0.175,-0.052,0.151),Vector3(0.167,0.067,0.151),
        Vector3(0.14,0.125,0.13)],sides)
    collar.position=Vector3(0,0.022,0.012)
    collar.scale=Vector3.ONE
    # keep badge on outer shell; use the existing exact faction paint
    var cap_badge: Node3D=_find(model,"V2_FaccionCasco")
    if cap_badge!=null:
        cap_badge.position.y=0.56*height
        cap_badge.position.z=-0.20*depth
        cap_badge.rotation_degrees.x=-24.0
    model.set_meta(FAMILY_IDENTITY_V6,role)
    return true

const SCULPT_V8 := "tarvoka_infantry_integrated_face_v8"

# Native V7 renders exposed the two spherical cheeks and a rectangular
# brow above the visor. Replace these with a continuous protective lower
# mask and a fitted, closed brow. Reuse mesh nodes/materials, preserve rig.
static func _refine_face_and_profile(model: Node3D,hero: bool) -> bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    var sides: int=20 if hero else 12
    var mask_width: float=0.183
    var brow_width: float=0.224
    var mask_color: Color=Color("#45544f")
    var mask_depth: float=0.105
    match role:
        "line":
            mask_color=Color("#47564f")
        "infantry_commando":
            mask_width=0.198
            brow_width=0.238
            mask_color=Color("#303e44")
            mask_depth=0.121
        "infantry_sniper":
            mask_width=0.182
            brow_width=0.205
            mask_color=Color("#465944")
        "infantry_logistic":
            mask_width=0.192
            brow_width=0.229
            mask_color=Color("#545d4a")
        "infantry_medic":
            mask_width=0.177
            brow_width=0.214
            mask_color=Color("#62716c")
        _:
            return false
    if not _resculpt(model,"V2_ProteccionBarbilla",[
            Vector3(mask_width*0.59,0.022,mask_depth*0.61),
            Vector3(mask_width*0.88,0.061,mask_depth*0.91),
            Vector3(mask_width,0.112,mask_depth),
            Vector3(mask_width*0.98,0.167,mask_depth*0.88),
            Vector3(mask_width*0.83,0.197,mask_depth*0.65)],
            Vector3(0,0,-0.168),sides,PackedFloat32Array([0.04,0.012,0.0,0.0,0.018]),0.76):
        return false
    var mask: MeshInstance3D=_find(model,"V2_ProteccionBarbilla") as MeshInstance3D
    mask.material_override=_coat(mask_color,0.02,0.84)
    for side in [-1,1]:
        _hide(model,"V2_Mejilla_%d"%side)
        var ear: MeshInstance3D=_find(model,"V2_OrejeraMoldeada_%d"%side) as MeshInstance3D
        if ear!=null:
            ear.scale=Vector3(0.083,0.185,0.195)
            ear.position=Vector3(float(side)*0.271,0.266,0.015)
        var pin: Node3D=_find(model,"V2_OrejerasFijacion_%d"%side)
        if pin!=null:
            pin.position=Vector3(float(side)*0.309,0.25,0.015)
            pin.scale=Vector3(1,0.74,0.71)
        _hide(model,"HebillaBota_%d"%side)
        var side_pouch: MeshInstance3D=_find(model,"BolsilloPierna_%d"%side) as MeshInstance3D
        if side_pouch!=null:
            side_pouch.mesh=_organic_mesh([Vector3(0.027,-0.10,0.077),
                Vector3(0.043,-0.067,0.092),Vector3(0.043,0.065,0.092),
                Vector3(0.027,0.10,0.077)],sides,PackedFloat32Array(),0.55)
            side_pouch.scale=Vector3.ONE
    # The brow follows the shell rather than projecting as a wide slab.
    if not _resculpt(model,"V2_BordeFrontalCasco",[
            Vector3(brow_width*0.87,-0.035,0.047),
            Vector3(brow_width,-0.012,0.058),
            Vector3(brow_width*0.96,0.020,0.057),
            Vector3(brow_width*0.76,0.044,0.037)],
            Vector3(0,0.354,-0.234),sides,PackedFloat32Array(),0.56):
        return false
    # Seat the chest and shoulder faction identifiers on actual surfaces.
    # Do not alter the exact faction paint. Keep them prominent at LOD8.
    var chest: MeshInstance3D=_find(model,"V2_CorazaPectoralHermetica") as MeshInstance3D
    var mark: Node3D=_find(model,"V2_FaccionPechoArticulada")
    if chest!=null and mark!=null:
        mark.position.z=chest.position.z+chest.mesh.get_aabb().position.z*chest.scale.z-0.010
    for side in [-1,1]:
        var shoulder: Node3D=_find(model,"FaccionHombro_%d"%side)
        if shoulder!=null:
            shoulder.position=Vector3(float(side)*0.147,-0.029,-0.04)
            shoulder.scale=Vector3(1,0.64,0.68)
    model.set_meta(SCULPT_V8,role)
    return true

const ARMOR_V10 := "tarvoka_infantry_armor_anatomy_v10"

# Keep the anatomical arm and hand endpoints. Shape a slimmer fitted
# forearm, a curved chest and role-specific shoulder mass instead of
# adding disconnected decoration or changing rig pivots.
static func _refine_outer_armor(model: Node3D,hero: bool) -> bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    var sides: int=20 if hero else 12
    var shoulder_width: float=1.0
    var shoulder_depth: float=1.0
    var chest_width: float=1.0
    var chest_depth: float=1.0
    match role:
        "line":
            pass
        "infantry_commando":
            shoulder_width=1.06
            shoulder_depth=1.08
            chest_width=1.04
            chest_depth=1.12
        "infantry_sniper":
            shoulder_width=0.87
            shoulder_depth=0.91
            chest_width=0.94
            chest_depth=0.88
        "infantry_logistic":
            shoulder_width=0.96
            chest_depth=0.91
        "infantry_medic":
            shoulder_width=0.92
            shoulder_depth=0.94
            chest_width=0.96
            chest_depth=0.91
        _:
            return false
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var shoulder_profile: Array[Vector3]=[]
        for ring in [Vector3(0.105,-0.145,0.108),Vector3(0.139,-0.095,0.139),
                Vector3(0.154,-0.02,0.147),Vector3(0.136,0.05,0.124),
                Vector3(0.091,0.091,0.087),Vector3(0.052,0.113,0.054)]:
            shoulder_profile.append(Vector3(ring.x*shoulder_width,ring.y,ring.z*shoulder_depth))
        if not _resculpt(model,"Hombrera"+suffix,shoulder_profile,Vector3(0,0,-0.035),sides):
            return false
        var shoulder: Node3D=_find(model,"FaccionHombro"+suffix)
        if shoulder!=null:
            shoulder.position.x=float(side)*(0.147*shoulder_width)
        if not _resculpt(model,"V2_MangaCerrada"+suffix,[
                Vector3(0.103,-0.52,0.112),Vector3(0.118,-0.43,0.127),
                Vector3(0.129,-0.30,0.135),Vector3(0.139,-0.15,0.143),
                Vector3(0.143,-0.025,0.14),Vector3(0.119,0.06,0.12)],
                Vector3(0,0,0.005),sides):
            return false
    var chest: MeshInstance3D=_find(model,"V2_CorazaPectoralHermetica") as MeshInstance3D
    if chest==null:
        return false
    # Superelliptic closed shell with a tapered waist. Use the original
    # chest center and keep all exact faction-colored pieces separate.
    chest.mesh=_organic_mesh([
        Vector3(0.235*chest_width,-0.265,0.045*chest_depth),
        Vector3(0.282*chest_width,-0.205,0.063*chest_depth),
        Vector3(0.319*chest_width,-0.055,0.079*chest_depth),
        Vector3(0.337*chest_width,0.10,0.083*chest_depth),
        Vector3(0.295*chest_width,0.207,0.060*chest_depth),
        Vector3(0.205*chest_width,0.266,0.038*chest_depth)],
        sides,PackedFloat32Array([0.012,0.002,-0.006,-0.006,0.0,0.018]),0.55)
    chest.scale=Vector3.ONE
    var mark: Node3D=_find(model,"V2_FaccionPechoArticulada")
    if mark!=null:
        mark.position.z=chest.position.z-0.069*chest_depth
    model.set_meta(ARMOR_V10,role)
    return true

const GAIT_V11 := "tarvoka_infantry_articulated_gait_v11"
const GROUND_V11 := "tarvoka_infantry_rest_sole_v11"

# Existing thigh, calf and boot meshes remain closed. Add two transform-only
# pivots per leg and reparent without changing the rest-space transforms.
static func _move_to_joint(part: Node3D,parent: Node3D,offset: Vector3) -> void:
    var old_position: Vector3=part.position
    part.get_parent().remove_child(part)
    parent.add_child(part)
    part.position=old_position-offset

static func _refine_family_legs(model: Node3D,hero: bool) -> bool:
    var sides: int=16 if hero else 10
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var leg: Node3D=_find(model,"PiernaRig"+suffix)
        if leg==null:
            return false
        for name in ["V2_PantorrillaTaper","Rodillera","V2_BotaMoldeada","V2_Suela"]:
            var part: Node3D=_find(model,name+suffix)
            if part==null or part.get_parent()!=leg:
                return false
        # Tapered cloth contours replace the horizontal floating box folds.
        if not _resculpt(model,"V2_MusloTaper"+suffix,[
                Vector3(0.126,-0.52,0.136),Vector3(0.140,-0.445,0.151),
                Vector3(0.153,-0.33,0.164),Vector3(0.148,-0.245,0.171),
                Vector3(0.159,-0.13,0.179),Vector3(0.149,0.012,0.169)],
                Vector3(0,0,0.02),sides):
            return false
        if not _resculpt(model,"V2_PantorrillaTaper"+suffix,[
                Vector3(0.105,-0.84,0.121),Vector3(0.119,-0.75,0.131),
                Vector3(0.133,-0.63,0.146),Vector3(0.140,-0.565,0.151),
                Vector3(0.130,-0.455,0.142),Vector3(0.119,-0.415,0.128)],
                Vector3(0,0,-0.03),sides):
            return false
        for row in range(3):
            _hide(model,"V2_PlisePantalon_%d_%d"%[side,row])
        var knee:=Node3D.new()
        knee.name="V11_RodillaRig"+suffix
        leg.add_child(knee)
        knee.position=Vector3(0,-0.47,0)
        var ankle:=Node3D.new()
        ankle.name="V11_TobilloRig"+suffix
        knee.add_child(ankle)
        ankle.position=Vector3(0,-0.31,0)
        for name in ["V2_PantorrillaTaper","Rodillera"]:
            _move_to_joint(_find(model,name+suffix),knee,Vector3(0,-0.47,0))
        for name in ["V2_BotaMoldeada","V2_Suela"]:
            _move_to_joint(_find(model,name+suffix),ankle,Vector3(0,-0.78,0))
    model.set_meta(GAIT_V11,true)
    if not _refine_v12_uniform(model,hero):
        return false
    model.set_meta(GROUND_V11,family_sole_floor(model))
    return true

const MOTION_V12 := "tarvoka_infantry_motion_uniform_v12"
const SOLE_VERTICES_V12 := "tarvoka_infantry_sole_vertices_v12"

# V11 images showed raised blue bars on the forehead. Use a shallow
# curved closed emblem instead; retain the exact faction material.
# Cloth pouches and chest pockets reuse their original node/material.
static func _refine_v12_uniform(model: Node3D,hero: bool) -> bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    var helmet: MeshInstance3D=_find(model,"V2_CascoEsferoideCerrado") as MeshInstance3D
    var badge: MeshInstance3D=_find(model,"V2_FaccionCasco") as MeshInstance3D
    if helmet==null or badge==null:
        return false
    var bounds: AABB=helmet.mesh.get_aabb()
    var width: float=bounds.size.x*0.255
    var y: float=bounds.position.y+bounds.size.y*0.73
    badge.mesh=_organic_mesh([
        Vector3(width*0.74,-0.027,0.022),Vector3(width,-0.013,0.033),
        Vector3(width,0.014,0.032),Vector3(width*0.73,0.027,0.021)],
        16 if hero else 10,PackedFloat32Array(),0.75)
    badge.position=Vector3(0,y,helmet.position.z+bounds.position.z+0.045)
    badge.rotation_degrees=Vector3(-23,0,0)
    badge.scale=Vector3.ONE
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var pocket: MeshInstance3D=_find(model,"V2_BolsilloPeitoral"+suffix) as MeshInstance3D
        if pocket!=null:
            pocket.mesh=_organic_mesh([
                Vector3(0.054,-0.076,0.016),Vector3(0.073,-0.053,0.027),
                Vector3(0.073,0.048,0.027),Vector3(0.054,0.075,0.016)],
                12,PackedFloat32Array(),0.55)
            pocket.scale=Vector3.ONE
            pocket.position.z=-0.349
        var strap: MeshInstance3D=_find(model,"V2_CinchaPortaequipo"+suffix) as MeshInstance3D
        if strap!=null:
            strap.mesh=_organic_mesh([
                Vector3(0.031,-0.29,0.017),Vector3(0.038,-0.20,0.023),
                Vector3(0.038,0.18,0.023),Vector3(0.029,0.29,0.017)],
                10,PackedFloat32Array([0.0,0.008,0.008,0.0]),0.6)
            strap.scale=Vector3.ONE
        var sole: MeshInstance3D=_find(model,"V2_Suela"+suffix) as MeshInstance3D
        if sole==null or not sole.mesh is ArrayMesh:
            return false
        # Cache unique mesh vertices once. The ground contact comes from
        # the actual curved outsole, not an imaginary box corner.
        var arrays: Array=sole.mesh.surface_get_arrays(0)
        var source: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var unique: Dictionary={}
        var points:=PackedVector3Array()
        for vertex in source:
            if not unique.has(vertex):
                unique[vertex]=true
                points.append(vertex)
        sole.set_meta(SOLE_VERTICES_V12,points)
    model.set_meta(MOTION_V12,role)
    return true

# Lowest actual sole vertex in the soldier's local frame. Works in a
# detached native QA model, without relying on global transforms.
static func family_sole_floor(model: Node3D) -> float:
    var soldier: Node3D=_find(model,"Infanteria_3D")
    var floor_y: float=INF
    for side in [-1,1]:
        var sole: MeshInstance3D=_find(model,"V2_Suela_%d"%side) as MeshInstance3D
        if sole==null or sole.mesh==null:
            continue
        var bounds: AABB=sole.mesh.get_aabb()
        var relative:=Transform3D.IDENTITY
        var node: Node3D=sole
        while node!=null and node!=soldier:
            relative=node.transform*relative
            node=node.get_parent() as Node3D
        var vertices: PackedVector3Array=sole.get_meta(SOLE_VERTICES_V12,PackedVector3Array())
        # Only the vertical component is needed; project the cached
        # vertices onto the exact Y row of the composed transform.
        var vertical:=Vector3(relative.basis.x.y,relative.basis.y.y,relative.basis.z.y)
        var offset: float=relative.origin.y
        if vertices.is_empty():
            for corner in range(8):
                floor_y=minf(floor_y,vertical.dot(bounds.get_endpoint(corner))+offset)
        else:
            for vertex in vertices:
                floor_y=minf(floor_y,vertical.dot(vertex)+offset)
    return floor_y

const MOTION_V21 := "tarvoka_infantry_role_motion_v21"
# Motion amplitude only; shared timings and contact solvers stay unchanged.
const GAIT_GAIN_V21 := {
    "line":1.0,"infantry_commando":0.96,"infantry_sniper":0.89,
    "infantry_logistic":0.88,"infantry_medic":0.92
}

static func _pose_family_legs(model: Node3D,kind: String,t: float,stage: int) -> bool:
    if not bool(model.get_meta(GAIT_V11,false)):
        return true
    var soldier: Node3D=_find(model,"Infanteria_3D")
    if soldier==null:
        return false
    var pulse: float=sin(t*PI)
    var role: String=str(model.get_meta("tarvoka_infantry_role","line"))
    var gain: float=float(GAIT_GAIN_V21.get(role,1.0))
    model.set_meta(MOTION_V21,role)
    model.set_meta("tarvoka_infantry_validation_v24",role)
    for side in [-1,1]:
        var leg: Node3D=_find(model,"PiernaRig_%d"%side)
        var knee: Node3D=_find(model,"V11_RodillaRig_%d"%side)
        var ankle: Node3D=_find(model,"V11_TobilloRig_%d"%side)
        if leg==null or knee==null or ankle==null:
            return false
        leg.rotation_degrees.x=0.0
        knee.rotation_degrees.x=0.0
        ankle.rotation_degrees.x=0.0
        if stage>=4:
            continue
        if kind=="move":
            var wave: float=sin(t*TAU*2.0+float(side)*PI*0.5)*pulse
            leg.rotation_degrees.x=20.0*wave*gain
            knee.rotation_degrees.x=-33.0*maxf(0.0,wave)*gain
            ankle.rotation_degrees.x=-(leg.rotation_degrees.x+knee.rotation_degrees.x)*0.90
        elif kind=="run":
            var wave: float=sin(t*TAU*3.0+float(side)*PI*0.5)*pulse
            leg.rotation_degrees.x=32.0*wave*gain
            knee.rotation_degrees.x=-52.0*maxf(0.0,wave)*gain
            ankle.rotation_degrees.x=-(leg.rotation_degrees.x+knee.rotation_degrees.x)*0.85
        elif kind in ["aim","attack"]:
            var crouch: float=1.0 if role=="infantry_sniper" else 0.55
            leg.rotation_degrees.x=(17.0 if side<0 else -8.0)*pulse*crouch
            knee.rotation_degrees.x=(-27.0 if side<0 else -13.0)*pulse*crouch
            ankle.rotation_degrees.x=-(leg.rotation_degrees.x+knee.rotation_degrees.x)
        elif kind in ["capture","work","repair"]:
            leg.rotation_degrees.x=(24.0 if side<0 else -9.0)*pulse
            knee.rotation_degrees.x=(-34.0 if side<0 else -12.0)*pulse
            ankle.rotation_degrees.x=-(leg.rotation_degrees.x+knee.rotation_degrees.x)
    if stage<4 and kind in ["move","run","aim","attack","capture","work","repair","idle"]:
        var floor_y: float=family_sole_floor(model)
        var rest: float=float(model.get_meta(GROUND_V11,floor_y))
        if not is_finite(floor_y):
            return false
        soldier.position.y=rest-floor_y
    return true

const SURFACE_V7 := "tarvoka_infantry_material_finish_v7"
const DAMAGE_V7 := "tarvoka_infantry_visual_damage_v7"
const CLEAN_MAT := "tarvoka_infantry_v7_clean_material"
const STAGE_MATS := "tarvoka_infantry_v7_stage_materials"
static var _family_textures: Dictionary={}
const RELIEF_V14 := "tarvoka_infantry_relief_v14"
static var _family_normals: Dictionary={}

const TEXTILE_V29 := "tarvoka_infantry_textile_finish_v29"
const EQUIPMENT_V30 := "tarvoka_infantry_equipment_finish_v30"
const EQUIPMENT_COUNT_V30 := "tarvoka_infantry_equipment_count_v30"
# Roughness, relief strength, tile density for each hero textile finish.
# The existing 64x64 cached images and local triplanar mapping remain.
const TEXTILE_PROFILES_V29 := {
    "line":Vector3(0.87,0.39,3.2),
    "infantry_commando":Vector3(0.83,0.37,3.6),
    "infantry_sniper":Vector3(0.94,0.46,3.0),
    "infantry_logistic":Vector3(0.88,0.42,3.1),
    "infantry_medic":Vector3(0.85,0.34,3.8)
}

# Seven existing pieces get a tailored closed edge and reinforced center.
# Original node, material, local transform and bounding envelope survive.
# The specialist signature and its V17 fasteners are not moved.
static func _refine_equipment_v30(model: Node3D,hero: bool)->bool:
    if not hero:
        return true
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    if not TEXTILE_PROFILES_V29.has(role):
        return false
    var labels: Array[String]=["V2_CierreMochila"]
    for side in [-1,1]:
        var suffix: String="_%d"%side
        labels.append_array(["V2_BolsilloCurvo"+suffix,"V2_BolsilloPeitoral"+suffix,
            "V2_CinchaPortaequipo"+suffix])
    for label in labels:
        var part: MeshInstance3D=_find(model,label) as MeshInstance3D
        if part==null or part.mesh==null:
            return false
        var before: AABB=part.mesh.get_aabb()
        var r: Vector3=before.size*0.5
        var center: Vector3=before.get_center()
        # The original nine-sided rear pockets are not symmetric in X.
        # Preserve their actual local center, rather than rejecting the
        # entire soldier because the bounding box is slightly offset.
        if minf(r.x,minf(r.y,r.z))<=0.0 or not center.is_finite():
            return false
        var corner: float=0.68 if label.begins_with("V2_Cincha") else 0.76
        if label=="V2_CierreMochila":
            corner=0.58
        var rings: Array[Vector3]=[
            Vector3(r.x*corner,center.y-r.y,r.z*corner),
            Vector3(r.x*0.94,center.y-r.y*0.72,r.z*0.90),
            Vector3(r.x,center.y-r.y*0.42,r.z),
            Vector3(r.x,center.y+r.y*0.42,r.z),
            Vector3(r.x*0.94,center.y+r.y*0.72,r.z*0.90),
            Vector3(r.x*corner,center.y+r.y,r.z*corner)]
        var offsets:=PackedFloat32Array([center.z,center.z,center.z,center.z,center.z,center.z])
        part.mesh=_organic_mesh(rings,16,offsets,0.55,center.x)
        part.set_meta("tarvoka_v30_original_bounds",before)
    model.set_meta(EQUIPMENT_V30,role)
    model.set_meta(EQUIPMENT_COUNT_V30,labels.size())
    return true

const SURFACES_V19 := "tarvoka_infantry_role_surfaces_v19"
# Integer periodic frequencies keep tiled mipmapped textures seamless.
# Each role has its own weave, tread and coating profile, independent of faction.
const SURFACE_PROFILES_V19 := {
    "line":Vector3i(8,8,11),
    "infantry_commando":Vector3i(12,8,15),
    "infantry_sniper":Vector3i(6,10,9),
    "infantry_logistic":Vector3i(5,7,7),
    "infantry_medic":Vector3i(10,12,13)
}

static func _relief_height(kind: String,x: int,y: int,role: String) -> float:
    var profile: Vector3i=SURFACE_PROFILES_V19.get(role,Vector3i(8,8,11))
    var u: float=TAU*float(x)/64.0
    var v: float=TAU*float(y)/64.0
    var grain: float=sin(13.0*u+17.0*v)*cos(19.0*u-11.0*v)
    var warp: float=float(profile.x)
    var weft: float=float(profile.y)
    var finish: float=float(profile.z)
    match kind:
        "fabric":
            # Periodic warp/weft plus alternating diagonal twill, with a
            # small secondary fiber instead of an even checkerboard.
            return 0.24*cos(warp*u)*cos(weft*v)+0.10*cos(warp*u+weft*v)+0.045*cos(2.0*warp*u-weft*v)+0.055*grain
        "rubber":
            return 0.21*cos(warp*u+weft*v)+0.07*cos(warp*u-weft*v)+0.045*cos(2.0*weft*v)+0.04*grain
        _:
            return 0.045*sin(finish*u+3.0*v)*cos(5.0*u-finish*v)+0.023*grain

static func _family_normal(kind: String,role: String) -> ImageTexture:
    var key: String=role+":"+kind
    if _family_normals.has(key):
        return _family_normals[key] as ImageTexture
    var img: Image=Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var dx: float=(_relief_height(kind,x+1,y,role)-_relief_height(kind,x-1,y,role))*0.5
            var dy: float=(_relief_height(kind,x,y+1,role)-_relief_height(kind,x,y-1,role))*0.5
            var n: Vector3=Vector3(-dx,-dy,1.0).normalized()
            img.set_pixel(x,y,Color(n.x*0.5+0.5,n.y*0.5+0.5,n.z*0.5+0.5,1.0))
    img.generate_mipmaps()
    var tex: ImageTexture=ImageTexture.create_from_image(img)
    _family_normals[key]=tex
    return tex

# Grayscale role-specific microstructure preserves faction colors.
# Only hero LOD allocates these textures; all damage states share them.
static func _family_texture(kind: String,role: String) -> ImageTexture:
    var key: String=role+":"+kind
    if _family_textures.has(key):
        return _family_textures[key] as ImageTexture
    var img: Image=Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var h: float=_relief_height(kind,x,y,role)
            var tone: float=0.96+0.15*h
            if kind=="fabric":
                tone=0.91+0.21*h
            elif kind=="rubber":
                tone=0.94+0.12*h
            tone=clampf(tone,0.0,1.0)
            img.set_pixel(x,y,Color(tone,tone,tone,1.0))
    img.generate_mipmaps()
    var tex: ImageTexture=ImageTexture.create_from_image(img)
    _family_textures[key]=tex
    return tex

static func _finish_kind(label: String) -> String:
    if label=="V2_VisorOpacoPBR" or label=="V4_CristalPrecision" or label.begins_with("V4_CristalNV_"):
        return "optic"
    if label.begins_with("V32_Armor") or label.begins_with("V16_Armor") or label.begins_with("V2_CostillaArmadura"):
        return "armor"
    if label.begins_with("V17_Fabric"):
        return "fabric"
    if label in ["V9_MantleSeam_-1","V9_MantleSeam_1","V6_MedicalPouch"]:
        return "fabric"
    if label in ["V9_CargaAsa","V6_ServiceHandle","V2_CierreMochila"]:
        return "rubber"
    if label in ["V6_SupplyCase","V4_FundaInstrumentos"]:
        return "armor"
    if label.begins_with("V32_Rubber") or label.begins_with("V16_Rubber") or label.begins_with("V17_Rubber"):
        return "rubber"
    if label in ["V2_CascoEsferoideCerrado","V2_CorazaPectoralHermetica"] or label.begins_with("Hombrera_") or label.begins_with("Rodillera_"):
        return "armor"
    if label in ["PetoBase","CinturaEquipo","V2_MochilaOrganica","CuelloProtegido","V2_ProteccionBarbilla"] or label.begins_with("V2_MangaCerrada_") or label.begins_with("V2_AntebrazoCerrado_") or label.begins_with("V2_MusloTaper_") or label.begins_with("V2_PantorrillaTaper_"):
        return "fabric"
    if label.begins_with("V2_BotaMoldeada_") or label.begins_with("V2_Suela_") or label.begins_with("V2_PalmaGuante_") or label.begins_with("V2_DedoGuante_") or label.begins_with("V13_Pulgar_") or label.begins_with("V13_CodoProtegido_") or label.begins_with("V13_CanaBota_") or label=="V2_BordeFrontalCasco":
        return "rubber"
    # Finish cloth accessories, not faction paint, medical emblems, or optics.
    if label in ["V4_CapaCamuflajePrecision","V4_BolsaSuministros","V4_KitMedicoVerde",
            "V4_BotiquinCintura","V4_FundaInstrumentos","V9_MedicalHarness"] or label.begins_with("V2_Bolsillo") or label.begins_with("V2_CinchaPortaequipo_") or label.begins_with("V9_CargaCincha_"):
        return "fabric"
    if label.begins_with("V4_ModuloSuministro_") or label.begins_with("V4_HombreraEspecial_") or label=="V9_FS24_Radio":
        return "armor"
    return ""

static func _finish_family_materials(model: Node3D,hero: bool) -> bool:
    if not bool(model.get_meta(FAMILY_ANATOMY_V5,false)):
        return true
    var role: String=str(model.get_meta("tarvoka_infantry_role","line"))
    var cache: Dictionary={}
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        var kind: String=_finish_kind(str(part.name))
        if str(part.name).begins_with("V2_CostillaArmadura") and not part.has_meta("tarvoka_v26_rib_bounds"):
            continue
        if str(part.name)=="V2_CierreMochila" and not part.has_meta("tarvoka_v30_original_bounds"):
            continue
        if kind.is_empty() or part.has_meta(STAGE_MATS):
            continue
        var src: StandardMaterial3D=part.material_override as StandardMaterial3D
        if src==null:
            return false
        var key: String=str(src.get_instance_id())+":"+kind
        if not cache.has(key):
            var clean: StandardMaterial3D=src.duplicate() as StandardMaterial3D
            clean.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
            var opaque_color: Color=clean.albedo_color
            opaque_color.a=1.0
            clean.albedo_color=opaque_color
            clean.cull_mode=BaseMaterial3D.CULL_BACK
            clean.metallic=0.09 if kind=="armor" else 0.0
            clean.roughness=0.58 if kind=="armor" else (0.92 if kind=="fabric" else 0.84)
            clean.metallic_specular=0.38 if kind=="armor" else 0.24
            if kind=="optic":
                clean.metallic=0.16
                clean.roughness=0.085
                clean.metallic_specular=0.52
                clean.clearcoat_enabled=true
                clean.clearcoat=0.88
                clean.clearcoat_roughness=0.09
                clean.normal_enabled=false
            elif hero:
                clean.albedo_texture=_family_texture(kind,role)
                clean.uv1_triplanar=true
                clean.uv1_world_triplanar=false
                clean.uv1_scale=Vector3.ONE*4.0
                clean.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
                clean.normal_enabled=true
                clean.normal_texture=_family_normal(kind,role)
                clean.normal_scale=0.30 if kind=="fabric" else (0.24 if kind=="rubber" else 0.20)
                if kind=="fabric":
                    var textile: Vector3=TEXTILE_PROFILES_V29[role]
                    clean.roughness=textile.x
                    clean.normal_scale=textile.y
                    clean.uv1_scale=Vector3.ONE*textile.z
                    clean.metallic_specular=0.22
                elif kind=="rubber":
                    clean.normal_scale=0.32
                    clean.roughness=0.86
            var stages: Array[StandardMaterial3D]=[clean]
            for stage in range(1,5):
                var weathered: StandardMaterial3D=clean.duplicate() as StandardMaterial3D
                var c: Color=clean.albedo_color
                c=c.lerp(Color("#39352e"),float(stage)*0.11)
                c.a=1.0
                weathered.albedo_color=c
                weathered.roughness=minf(1.0,clean.roughness+float(stage)*0.065)
                if kind=="optic":
                    # A damaged opaque optical surface becomes dull, never
                    # invisible; the original clean material is reversible.
                    weathered.roughness=0.085+float(stage)*0.14
                    weathered.clearcoat=maxf(0.0,0.88-float(stage)*0.21)
                    weathered.clearcoat_roughness=0.09+float(stage)*0.14
                stages.append(weathered)
            cache[key]=stages
        var palette: Array=cache[key]
        part.material_override=palette[0]
        part.set_meta(CLEAN_MAT,palette[0])
        part.set_meta(STAGE_MATS,palette)
    # Reuse the existing four damage meshes and seat them on the new
    # armor front. No added effects or permanent changes to the model.
    var chest: MeshInstance3D=_find(model,"V2_CorazaPectoralHermetica") as MeshInstance3D
    if chest!=null:
        for stage in range(1,5):
            var mark: Node3D=_find(model,"Impacto_%d"%stage)
            if mark!=null:
                mark.position.z=chest.position.z+chest.mesh.get_aabb().position.z*chest.scale.z-0.010
                mark.position.y=0.14-float(stage)*0.09
    model.set_meta(SURFACE_V7,true)
    model.set_meta(DAMAGE_V7,0)
    model.set_meta(RELIEF_V14,str(model.get_meta("tarvoka_infantry_role","")))
    model.set_meta(SURFACES_V19,role)
    if hero:
        model.set_meta(TEXTILE_V29,role)
    return true

static func sync_family_damage(model: Node3D,stage: int) -> void:
    if not bool(model.get_meta(SURFACE_V7,false)):
        return
    var level: int=clampi(stage,0,4)
    if int(model.get_meta(DAMAGE_V7,-1))==level:
        return
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if part.has_meta(STAGE_MATS):
            var palette: Array=part.get_meta(STAGE_MATS)
            part.material_override=palette[level]
    model.set_meta(DAMAGE_V7,level)

const FAMILY_GRIPS_V5 := "tarvoka_infantry_grip_contacts_v5"

static func family_grip_point(side: int) -> Vector3:
    return Vector3(-0.04,-0.225,-0.052) if side>0 else Vector3(0.44,-0.155,-0.065)

# Reuse the existing gloves, fingers and forearms. No new draw calls.
# The forearm becomes a tapered link with its origin/length solved in
# the original arm frame; the palm is a child of the actual weapon rig.
static func _attach_family_grips(model: Node3D, hero: bool) -> bool:
    var gun: Node3D = _find(model,"ArmamentoRig")
    if gun==null:
        return false
    for side in [-1,1]:
        if _find(model,"BrazoRig_%d"%side)==null or _find(model,"V2_PalmaGuante_%d"%side)==null or _find(model,"V2_AntebrazoCerrado_%d"%side)==null:
            return false
    for side in [-1,1]:
        var arm: Node3D = _find(model,"BrazoRig_%d"%side)
        var palm: MeshInstance3D = _find(model,"V2_PalmaGuante_%d"%side) as MeshInstance3D
        var link: MeshInstance3D = _find(model,"V2_AntebrazoCerrado_%d"%side) as MeshInstance3D
        if palm.get_parent()!=arm or link.get_parent()!=arm:
            return false
        arm.remove_child(palm)
        gun.add_child(palm)
        palm.position=family_grip_point(side)
        palm.rotation_degrees=Vector3.ZERO
        palm.scale=Vector3(0.165,0.18,0.185)
        for finger in range(4):
            var digit: Node3D = _find(model,"V2_DedoGuante_%d_%d"%[side,finger])
            if digit==null:
                continue
            arm.remove_child(digit)
            gun.add_child(digit)
            digit.position=family_grip_point(side)+Vector3((float(finger)-1.5)*0.041,-0.071,-0.046)
            digit.rotation_degrees=Vector3(12,0,0)
            digit.scale=Vector3(0.85,0.76,0.85)
        link.mesh=_organic_mesh([
            Vector3(0.091,-0.5,0.104),Vector3(0.102,-0.35,0.110),
            Vector3(0.098,-0.12,0.105),Vector3(0.083,0.10,0.090),
            Vector3(0.073,0.29,0.079),Vector3(0.061,0.5,0.066)],16 if hero else 10)
    model.set_meta(FAMILY_GRIPS_V5,true)
    if not _refine_v13_contacts(model,hero):
        return false
    return _sync_family_grips(model)

const CONTACT_V13 := "tarvoka_infantry_gloves_boots_v13"

# Keep the established palm centers and solve all contacts as before.
# Closed curved fingers and a thumb travel with the original palm/holder.
# Elbow pads and ankle collars are hero-only, so LOD8 adds no mesh nodes.
static func _refine_v13_contacts(model: Node3D,hero: bool) -> bool:
    var role: String=str(model.get_meta("tarvoka_infantry_role",""))
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var palm: MeshInstance3D=_find(model,"V2_PalmaGuante"+suffix) as MeshInstance3D
        var arm: Node3D=_find(model,"BrazoRig"+suffix)
        var boot: MeshInstance3D=_find(model,"V2_BotaMoldeada"+suffix) as MeshInstance3D
        var ankle: Node3D=_find(model,"V11_TobilloRig"+suffix)
        var knee: Node3D=_find(model,"V11_RodillaRig"+suffix)
        if palm==null or arm==null or boot==null or ankle==null or knee==null:
            return false
        var rubber: StandardMaterial3D=palm.material_override as StandardMaterial3D
        if rubber==null:
            return false
        palm.mesh=_organic_mesh([
            Vector3(0.057,-0.088,0.058),Vector3(0.079,-0.050,0.083),
            Vector3(0.084,0.024,0.091),Vector3(0.071,0.069,0.074),
            Vector3(0.052,0.087,0.054)],14 if hero else 10,
            PackedFloat32Array([0.005,0.0,0.0,0.007,0.012]),0.72)
        palm.scale=Vector3.ONE
        for finger in range(4):
            var digit: MeshInstance3D=_find(model,"V2_DedoGuante_%d_%d"%[side,finger]) as MeshInstance3D
            if digit==null:
                if hero:
                    return false
                continue
            var len: float=0.94 if finger in [0,3] else 1.0
            digit.mesh=_organic_mesh([
                Vector3(0.012,-0.045*len,0.014),Vector3(0.019,-0.027*len,0.020),
                Vector3(0.021,0.014,0.022),Vector3(0.019,0.052,0.023),
                Vector3(0.015,0.067,0.018)],10,
                PackedFloat32Array([-0.020,-0.012,0.004,0.009,0.010]))
            digit.scale=Vector3.ONE
        if hero:
            _mesh(palm,"V13_Pulgar"+suffix,_organic_mesh([
                Vector3(0.023,-0.055,0.027),Vector3(0.030,-0.026,0.032),
                Vector3(0.027,0.025,0.030),Vector3(0.017,0.060,0.019)],12,
                PackedFloat32Array([-0.009,0.0,0.012,0.016])),
                rubber,Vector3(float(side)*0.061,-0.012,-0.045),Vector3(25,0,float(side)*24))
            _mesh(arm,"V13_CodoProtegido"+suffix,_organic_mesh([
                Vector3(0.079,-0.074,0.074),Vector3(0.103,-0.035,0.101),
                Vector3(0.110,0.027,0.106),Vector3(0.082,0.070,0.076)],14),
                rubber,Vector3(0,-0.47,-0.035))
            # Rounded cuff overlaps the boot upper and shin at the ankle
            # without changing the geometry or floor of the outsole.
            _mesh(ankle,"V13_CanaBota"+suffix,_organic_mesh([
                Vector3(0.106,-0.016,0.119),Vector3(0.119,0.016,0.132),
                Vector3(0.118,0.057,0.129),Vector3(0.103,0.088,0.116)],14),
                rubber,Vector3(0,0,-0.052))
        # The tactical knee insignia formerly followed the thigh while
        # the kneepad followed the knee. Preserve its rest transform.
        var knee_badge: Node3D=_find(model,"V3_IdentidadRodillaMapa"+suffix)
        if knee_badge!=null:
            _move_to_joint(knee_badge,knee,Vector3(0,-0.47,0))
    model.set_meta(CONTACT_V13,role)
    return true

static func _sync_family_grips(model: Node3D) -> bool:
    if not bool(model.get_meta(FAMILY_GRIPS_V5,false)):
        return false
    var gun: Node3D = _find(model,"ArmamentoRig")
    if gun==null:
        return false
    for side in [-1,1]:
        var arm: Node3D = _find(model,"BrazoRig_%d"%side)
        var link: MeshInstance3D = _find(model,"V2_AntebrazoCerrado_%d"%side) as MeshInstance3D
        if arm==null or link==null:
            return false
        # Both arm and weapon are children of TorsoRig. Local transforms
        # work even in native QA before the model enters a SceneTree.
        var palm: Node3D=_find(model,"V2_PalmaGuante_%d"%side)
        if palm==null:
            return false
        var holder: Node3D=palm.get_parent() as Node3D
        if holder==null or holder.get_parent()!=arm.get_parent():
            return false
        var contact: Vector3=holder.transform*palm.position
        # Two-link geometric solve in torso space. Keep the hand on the
        # actual existing grip and orient the upper arm toward a bent elbow.
        # The bend pole is down/outward rather than across the chest.
        if model.has_meta(FIT_V15):
            var reach: Vector3=contact-arm.position
            var distance: float=reach.length()
            if distance<0.001:
                return false
            var axis: Vector3=reach/distance
            var upper_len: float=ELBOW_LOCAL.length()
            var lower_len: float=maxf(0.455,distance-upper_len+0.025)
            var projection: float=clampf((upper_len*upper_len+distance*distance-lower_len*lower_len)/(2.0*distance),-upper_len*0.98,upper_len*0.98)
            var bend: Vector3=Vector3(float(side)*0.65,-1.0,0.18)
            bend-=axis*bend.dot(axis)
            if bend.length_squared()<0.0001:
                bend=Vector3.RIGHT-axis*axis.x
            var elbow_dir: Vector3=(axis*projection+bend.normalized()*sqrt(maxf(0.0,upper_len*upper_len-projection*projection))).normalized()
            var old_dir: Vector3=(arm.basis*ELBOW_LOCAL).normalized()
            arm.quaternion=Quaternion(old_dir,elbow_dir)*arm.quaternion
        var target: Vector3 = arm.transform.affine_inverse()*contact
        var elbow: Vector3 = ELBOW_LOCAL
        var delta: Vector3 = target-elbow
        var length: float = delta.length()
        if length<0.0001:
            return false
        link.position=elbow+delta*0.5
        link.quaternion=Quaternion(Vector3.UP,delta/length)
        link.scale=Vector3(1,length,1)
    return true

# Eight-point rounded ballistic plate, a closed bevelled ArrayMesh, instead
# of a flat square attached to the soldier's torso.
static func _plate(parent: Node3D, name: String, center: Vector3,
        w: float, h: float, depth: float, mat: StandardMaterial3D) -> MeshInstance3D:
    var shape := [
        Vector2(-0.25,0.50),Vector2(0.25,0.50),
        Vector2(0.47,0.34),Vector2(0.45,-0.33),
        Vector2(0.19,-0.50),Vector2(-0.19,-0.50),
        Vector2(-0.45,-0.33),Vector2(-0.47,0.34)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var layers: Array[Vector2] = [
        Vector2(1.0,depth*0.5),
        Vector2(1.0,-depth*0.5+minf(0.025,depth*0.38)),
        Vector2(0.89,-depth*0.5)
    ]
    for k in range(layers.size()-1):
        for i in range(shape.size()):
            var j: int=(i+1)%shape.size()
            var v0 := Vector3(shape[i].x*w*layers[k].x,
                shape[i].y*h*layers[k].x,layers[k].y)
            var v1 := Vector3(shape[j].x*w*layers[k].x,
                shape[j].y*h*layers[k].x,layers[k].y)
            var v2 := Vector3(shape[i].x*w*layers[k+1].x,
                shape[i].y*h*layers[k+1].x,layers[k+1].y)
            var v3 := Vector3(shape[j].x*w*layers[k+1].x,
                shape[j].y*h*layers[k+1].x,layers[k+1].y)
            for vertex in [v0,v2,v1,v1,v2,v3]:
                st.add_vertex(vertex)
    # Both caps cover the full silhouette and seal every side wall.
    for i in range(shape.size()):
        var j: int=(i+1)%shape.size()
        var a: Vector2=shape[i]
        var b: Vector2=shape[j]
        for v in [
            Vector3(0,0,depth*0.5),
            Vector3(a.x*w,a.y*h,depth*0.5),
            Vector3(b.x*w,b.y*h,depth*0.5),
            Vector3(0,0,-depth*0.5),
            Vector3(b.x*w*0.89,b.y*h*0.89,-depth*0.5),
            Vector3(a.x*w*0.89,a.y*h*0.89,-depth*0.5)
        ]:
            st.add_vertex(v)
    st.generate_normals()
    return _mesh(parent,name,st.commit(),mat,center)

static func _find(root: Node3D, part: String) -> Node3D:
    return root.find_child(part,true,false) as Node3D

static func _hide(root: Node3D, part: String) -> void:
    var target: Node3D=_find(root,part)
    if target != null:
        target.visible=false

static func _child(parent: Node3D, label: String) -> Node3D:
    var n := Node3D.new()
    n.name=label
    parent.add_child(n)
    return n

static func apply(model: Node3D, faction_paint: Color, hero: bool) -> bool:
    if model == null or not bool(model.get_meta("tarvoka_infantry_family_v1",false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return false
    var soldier: Node3D=_find(model,"Infanteria_3D")
    var upper: Node3D=_find(model,"TorsoRig")
    var head: Node3D=_find(model,"CabezaRig")
    if soldier==null or upper==null or head==null:
        return false
    var paint: Color=Color(faction_paint.r,faction_paint.g,faction_paint.b,1.0)
    var fabric: StandardMaterial3D=_coat(FABRIC,0.02,0.87)
    var dark: StandardMaterial3D=_coat(DARK_FABRIC,0.0,0.91)
    var seam: StandardMaterial3D=_coat(SLEEVE,0.05,0.79)
    var armor: StandardMaterial3D=_coat(ARMOR,0.24,0.42)
    var rubber: StandardMaterial3D=_coat(RUBBER,0.01,0.88)
    var metal: StandardMaterial3D=_coat(METAL,0.56,0.31)
    var glass: StandardMaterial3D=_coat(GLASS,0.19,0.085,true)
    var faction: StandardMaterial3D=_coat(paint,0.13,0.43)
    var skin: StandardMaterial3D=_coat(SKIN,0.0,0.92)
    var core: Node3D=_child(soldier,ROOT)
    # Bevelled closed armor replaces the two flat rectangular panels.
    _hide(model,"CorazaFrontal")
    _hide(model,"FaccionPecho")
    _hide(model,"MochilaRigida")
    _hide(model,"FaccionMochila")
    _hide(model,"FaccionCasco")
    _hide(model,"CascoSolido")
    _hide(model,"ViseraBlindada")
    _hide(model,"VisorSellado")
    _plate(upper,"V2_CorazaPectoralHermetica",Vector3(0,0.03,-0.28),
        0.68,0.55,0.13,armor)
    _plate(upper,"V2_FaccionPechoArticulada",Vector3(0,0.215,-0.366),
        0.40,0.09,0.034,faction)
    for side in [-1,1]:
        _plate(upper,"V2_CostillaArmadura_%d"%side,
            Vector3(float(side)*0.33,-0.11,-0.08),0.15,0.27,0.07,armor)
        _box(upper,"V2_CinchaPortaequipo_%d"%side,
            Vector3(float(side)*0.23,0.01,0.285),
            Vector3(0.075,0.61,0.05),dark,Vector3(0,0,float(side)*-9))
        _box(upper,"V2_FaccionCincha_%d"%side,
            Vector3(float(side)*0.27,0.24,0.321),
            Vector3(0.058,0.12,0.018),faction)
    # A real softened sealed rucksack: visible rear straps, pouches and
    # faction paint. The old giant cube had obscured the entire upper body.
    _organic(upper,"V2_MochilaOrganica",Vector3(0,0.00,0.32),[
        Vector3(0.17,-0.35,0.08),Vector3(0.26,-0.27,0.155),
        Vector3(0.29,0.06,0.18),Vector3(0.25,0.31,0.13),
        Vector3(0.13,0.35,0.075)
    ],fabric,14 if hero else 10)
    _plate(upper,"V2_FaccionMochilaDorsal",Vector3(0,0.145,0.509),
        0.38,0.135,0.035,faction)
    _box(upper,"V2_CierreMochila",Vector3(0,-0.135,0.513),
        Vector3(0.18,0.09,0.027),rubber)
    if hero:
        for side in [-1,1]:
            _organic(upper,"V2_BolsilloCurvo_%d"%side,
                Vector3(float(side)*0.22,-0.205,0.46),[
                Vector3(0.11,-0.115,0.065),Vector3(0.13,-0.04,0.088),
                Vector3(0.115,0.09,0.073),Vector3(0.095,0.14,0.05)
            ],dark,9)
        for row in range(3):
            _box(upper,"V2_PespunteHorizontal_%02d"%row,
                Vector3(0,0.11-float(row)*0.11,-0.366),
                Vector3(0.48,0.018,0.021),dark)
        for x in [-1,1]:
            _box(upper,"V2_BolsilloPeitoral_%d"%x,
                Vector3(float(x)*0.195,-0.07,-0.392),
                Vector3(0.14,0.16,0.055),dark)

    # Organic closed helmet with real brow, shell, cheek protection and opaque
    # optically glossy visor. No holes or transparent glass on the rear view.
    _organic(head,"V2_CascoEsferoideCerrado",Vector3(0,0,0.02),[
        Vector3(0.22,0.16,0.21),Vector3(0.29,0.26,0.28),
        Vector3(0.29,0.42,0.30),Vector3(0.23,0.56,0.24),
        Vector3(0.08,0.635,0.09)
    ],armor,16 if hero else 10)
    _box(head,"V2_BordeFrontalCasco",Vector3(0,0.37,-0.29),
        Vector3(0.50,0.09,0.13),rubber)
    _box(head,"V2_VisorOpacoPBR",Vector3(0,0.235,-0.247),
        Vector3(0.37,0.15,0.091),glass)
    _box(head,"V2_ReflejoCristalFisico",Vector3(-0.10,0.271,-0.295),
        Vector3(0.11,0.014,0.010),metal,Vector3(0,0,-17))
    _plate(head,"V2_FaccionCasco",Vector3(0,0.58,-0.065),
        0.36,0.085,0.052,faction)
    var scar: MeshInstance3D=_box(head,"V2_CicatrizCasco",
        Vector3(0.18,0.36,-0.286),Vector3(0.10,0.024,0.035),
        _coat(Color("#342e2c"),0.07,0.82),Vector3(0,0,-38))
    scar.visible=false
    _sphere(head,"V2_ProteccionBarbilla",Vector3(0,0.054,-0.205),
        Vector3(0.28,0.12,0.13),seam)
    for side in [-1,1]:
        _sphere(head,"V2_Mejilla_%d"%side,
            Vector3(float(side)*0.145,0.115,-0.178),
            Vector3(0.14,0.16,0.14),skin)
        _sphere(head,"V2_OrejeraMoldeada_%d"%side,
            Vector3(float(side)*0.284,0.275,0),
            Vector3(0.105,0.255,0.255),rubber)
        if hero:
            _box(head,"V2_OrejerasFijacion_%d"%side,
                Vector3(float(side)*0.334,0.25,0),
                Vector3(0.018,0.105,0.13),metal)
    # Human taper and cloth folds replace the original boxed legs and arms.
    for side in [-1,1]:
        var leg: Node3D=_find(model,"PiernaRig_%d"%side)
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        if leg==null or arm==null:
            return false
        for old_part in ["Muslo_%d"%side,"Espinillera_%d"%side,"Bota_%d"%side]:
            _hide(leg,old_part)
        for old_part in ["Manga_%d"%side,"Antebrazo_%d"%side,"Guante_%d"%side]:
            _hide(arm,old_part)
        _organic(leg,"V2_MusloTaper_%d"%side,Vector3(0,0,0.02),[
            Vector3(0.13,-0.50,0.135),Vector3(0.145,-0.42,0.165),
            Vector3(0.16,-0.18,0.18),Vector3(0.15,0.01,0.17)
        ],fabric,14 if hero else 9)
        _organic(leg,"V2_PantorrillaTaper_%d"%side,Vector3(0,0,-0.03),[
            Vector3(0.115,-0.87,0.125),Vector3(0.125,-0.75,0.135),
            Vector3(0.14,-0.57,0.155),Vector3(0.125,-0.46,0.145)
        ],seam,12 if hero else 9)
        _box(leg,"V2_Suela_%d"%side,Vector3(0,-0.93,-0.128),
            Vector3(0.25,0.075,0.45),rubber)
        _organic(leg,"V2_BotaMoldeada_%d"%side,Vector3(0,0,-0.14),[
            Vector3(0.115,-0.895,0.16),Vector3(0.12,-0.81,0.19),
            Vector3(0.11,-0.68,0.14)
        ],dark,12 if hero else 9)
        _sphere(leg,"V2_PunteraProtegida_%d"%side,
            Vector3(0,-0.85,-0.31),Vector3(0.24,0.13,0.19),rubber)
        _organic(arm,"V2_MangaCerrada_%d"%side,Vector3(0,0,0.005),[
            Vector3(0.105,-0.52,0.115),Vector3(0.14,-0.34,0.145),
            Vector3(0.16,-0.10,0.16),Vector3(0.17,0.055,0.15)
        ],fabric,12 if hero else 9)
        _organic(arm,"V2_AntebrazoCerrado_%d"%side,Vector3(0,0,-0.085),[
            Vector3(0.104,-0.72,0.115),Vector3(0.115,-0.59,0.115),
            Vector3(0.12,-0.46,0.125)
        ],seam,12 if hero else 9)
        _sphere(arm,"V2_PalmaGuante_%d"%side,
            Vector3(0,-0.772,-0.135),Vector3(0.215,0.20,0.19),rubber)
        _box(arm,"V2_FaccionParcheManga_%d"%side,
            Vector3(float(side)*0.151,-0.18,-0.025),
            Vector3(0.023,0.20,0.17),faction)
        if hero:
            for finger in range(4):
                _organic(arm,"V2_DedoGuante_%d_%d"%[side,finger],
                    Vector3(-0.080+float(finger)*0.054,-0.90,-0.20),[
                    Vector3(0.019,-0.06,0.023),
                    Vector3(0.023,0.01,0.027),
                    Vector3(0.017,0.07,0.02)
                ],rubber,8)
            for row in range(3):
                _box(leg,"V2_PlisePantalon_%d_%d"%[side,row],
                    Vector3(0,-0.24-float(row)*0.11,-0.15),
                    Vector3(0.23,0.014,0.025),dark,
                    Vector3(0,0,float(side)*(8+row*3)))
                _box(arm,"V2_PliseManga_%d_%d"%[side,row],
                    Vector3(0,-0.25-float(row)*0.095,-0.147),
                    Vector3(0.21,0.012,0.02),dark)

    # Tactical color pass V3: bold REAL 3D faction paint on the existing
    # Android LOD8 model. At distant camera zoom the V2 thin stripes vanish.
    # Keep hero-grade details unchanged and preserve the exact official
    # faction palette: no extra tactical roles, billboards, or fake overlays.
    if not hero:
        _plate(upper,"V3_IdentidadPechoMapa",Vector3(0,0.165,-0.412),
            0.53,0.17,0.045,faction)
        _plate(upper,"V3_IdentidadMochilaMapa",Vector3(0,0.15,0.53),
            0.43,0.18,0.045,faction)
        _box(head,"V3_IdentidadFrenteCascoMapa",
            Vector3(0,0.466,-0.296),Vector3(0.35,0.085,0.025),faction)
        for side in [-1,1]:
            var sleeve: Node3D=_find(model,"BrazoRig_%d"%side)
            var shin: Node3D=_find(model,"PiernaRig_%d"%side)
            if sleeve==null or shin==null:
                return false
            _box(sleeve,"V3_IdentidadMangaMapa_%d"%side,
                Vector3(float(side)*0.170,-0.17,-0.043),
                Vector3(0.052,0.28,0.22),faction)
            _box(shin,"V3_IdentidadRodillaMapa_%d"%side,
                Vector3(0,-0.485,-0.207),Vector3(0.235,0.115,0.035),faction)
        model.set_meta("tarvoka_infantry_v3_tactical_identity",true)

    # The V1 gun looked like a side-pointing floating rod. V2 adds hand grips,
    # controls and mechanical detail and aims down -Z at a natural angle.
    var weapon: Node3D=_find(model,"ArmamentoRig")
    if weapon==null:
        return false
    var role: String=str(model.get_meta("tarvoka_infantry_role","line"))
    if role!="infantry_antitank":
        _box(weapon,"V2_GuardamanosFusil",Vector3(0.36,0,0),
            Vector3(0.31,0.18,0.20),rubber)
        _box(weapon,"V2_RielSuperior",Vector3(0.18,0.119,-0.008),
            Vector3(0.41,0.032,0.15),metal)
        _box(weapon,"V2_Empunadura",Vector3(0.025,-0.18,0),
            Vector3(0.083,0.30,0.093),dark,Vector3(0,0,-12))
        _box(weapon,"V2_FaccionCargador",Vector3(0,-0.23,-0.079),
            Vector3(0.10,0.13,0.02),faction)
        if hero:
            for cut in range(4):
                _box(weapon,"V2_RanuraGuardamanos_%02d"%cut,
                    Vector3(0.25+float(cut)*0.085,0.09,-0.104),
                    Vector3(0.033,0.025,0.014),metal)
    else:
        _box(weapon,"V2_ProteccionOpticaAT",Vector3(-0.12,0.28,0),
            Vector3(0.33,0.095,0.17),rubber)
        _box(weapon,"V2_FaccionCarcasaAT",Vector3(-0.12,0.334,-0.005),
            Vector3(0.21,0.024,0.14),faction)
    # Native 3D attack feedback shares the same rifle rig, never a sprite.
    # Rifle lengths are already defined by InfantryFamilyV1; position the
    # flash on each actual muzzle, not in the character's torso.
    var short_rifle: bool=role in ["scout","infantry_urban","infantry_engineer"]
    var muzzle_x: float=0.91 if role=="infantry_antitank" else (
        0.81 if short_rifle else 1.04)
    var flame: StandardMaterial3D=_coat(Color("#ffc562"),0.0,0.25)
    flame.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    flame.emission_enabled=true
    flame.emission=Color("#ffad32")
    flame.emission_energy_multiplier=1.6
    var flash: MeshInstance3D=_sphere(weapon,"V2_DestelloDisparo3D",
        Vector3(muzzle_x,0.025,0),
        Vector3(0.18,0.11,0.11),flame)
    flash.visible=false
    if hero and role!="infantry_antitank":
        var brass: MeshInstance3D=_box(weapon,"V2_CasquilloFisico",
            Vector3(0.09,0.10,0.21),Vector3(0.10,0.035,0.039),
            _coat(Color("#b69a54"),0.77,0.29),Vector3(0,18,25))
        brass.visible=false

    # Variant-specific V2 outlines retain their original tactical identity
    # without turning them into extra buildable units.
    if role=="infantry_urban":
        _hide(model,"EscudoUrbanoPlegado")
        _hide(model,"FaccionEscudoUrbano")
        _plate(upper,"V2_EscudoUrbanoFacetado",Vector3(-0.36,-0.17,-0.42),
            0.47,0.70,0.10,armor)
        _plate(upper,"V2_FaccionEscudoUrbano",Vector3(-0.36,0.055,-0.483),
            0.29,0.135,0.035,faction)
    elif role=="infantry_defense":
        _hide(model,"ProteccionTorno")
        _hide(model,"FaccionBlindajeDefensivo")
        _plate(upper,"V2_CorazaDefensivaAdicional",Vector3(0,-0.09,-0.38),
            0.70,0.40,0.12,armor)
        _plate(upper,"V2_FaccionDefensiva",Vector3(0,-0.055,-0.463),
            0.47,0.09,0.029,faction)
        for side in [-1,1]:
            _plate(upper,"V2_HombreraDefensiva_%d"%side,
                Vector3(float(side)*0.47,0.275,-0.06),
                0.25,0.28,0.075,armor)
    elif role=="scout":
        _box(upper,"V2_SensorPasivoMochila",Vector3(0.16,0.26,0.48),
            Vector3(0.11,0.14,0.09),metal)
        _box(upper,"V2_FaccionSensor",Vector3(0.16,0.335,0.48),
            Vector3(0.085,0.018,0.072),faction)
    elif role=="infantry_antitank":
        _box(upper,"V2_CargaRepuestoLateral",Vector3(-0.33,-0.28,0.37),
            Vector3(0.20,0.47,0.19),rubber)
        _box(upper,"V2_FaccionCargaAT",Vector3(-0.33,-0.05,0.48),
            Vector3(0.15,0.09,0.018),faction)
    elif role=="infantry_engineer":
        _box(upper,"V2_SujecionHerramienta",Vector3(0.36,-0.22,0.375),
            Vector3(0.13,0.24,0.04),rubber)
        _plate(upper,"V2_FaccionHerramientas",Vector3(-0.34,-0.13,0.51),
            0.20,0.095,0.026,faction)
    if role in FAMILY_ANATOMY_ROLES:
        if not _refine_core(model,hero) or not _refine_limbs_v27(model,hero) or not _refine_helmet_v28(model,hero) or not _refine_faction_armor_v26(model,paint,hero) or not _refine_equipment_v30(model,hero) or not _refine_boots_v32(model,paint,hero) or not _finish_family_materials(model,hero):
            return false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_infantry_v2_hero",hero)
    model.set_meta("tarvoka_infantry_v2_opaque",true)
    return pose(model,"idle",0.0)

const SERVICE_RIG := "V6_EquipoServicioRig"
const SERVICE_FLAG := "tarvoka_infantry_service_pose_v6"

# The service prop lives beside ArmamentoRig under TorsoRig. Transfer
# the original right palm and fingers between these two real rigs.
static func _service_pose(model: Node3D, kind: String, t: float) -> bool:
    var service: Node3D=_find(model,SERVICE_RIG)
    if service==null:
        return true
    var gun: Node3D=_find(model,"ArmamentoRig")
    var palm: Node3D=_find(model,"V2_PalmaGuante_1")
    if gun==null or palm==null:
        return false
    var active: bool=kind in ["work","repair"] and t>0.04 and t<0.96 and int(model.get_meta("tarvoka_infantry_damage",0))<4
    var holder: Node3D=service if active else gun
    var contact: Vector3=Vector3(0.0,-0.065,0.018) if active else family_grip_point(1)
    service.visible=active
    service.position=Vector3(0.25,-0.27-0.085*sin(t*PI),-0.54)
    service.rotation_degrees=Vector3(-20.0+12.0*sin(t*TAU),0,-10)
    if palm.get_parent()!=holder:
        palm.get_parent().remove_child(palm)
        holder.add_child(palm)
    palm.position=contact
    for finger in range(4):
        var digit: Node3D=_find(model,"V2_DedoGuante_1_%d"%finger)
        if digit==null:
            continue
        if digit.get_parent()!=holder:
            digit.get_parent().remove_child(digit)
            holder.add_child(digit)
        digit.position=contact+Vector3((float(finger)-1.5)*0.041,-0.071,-0.046)
    model.set_meta(SERVICE_FLAG,active)
    return true

const FX_V10 := "V10_InfantryVisualFX"
const FX_V22 := "tarvoka_infantry_impact_fx_v22"
static var _family_fx_shape: SphereMesh
static var _family_fx_material: StandardMaterial3D

# One lazily created MultiMesh batch, not a particle node per soldier
# effect. Root-space effects stay upright when the visual body falls.
static func _family_fx_batch(model: Node3D) -> MultiMeshInstance3D:
    var batch: MultiMeshInstance3D=model.get_node_or_null(FX_V10) as MultiMeshInstance3D
    if batch!=null:
        return batch
    if _family_fx_shape==null:
        _family_fx_shape=SphereMesh.new()
        _family_fx_shape.radius=0.5
        _family_fx_shape.height=1.0
        _family_fx_shape.radial_segments=8
        _family_fx_shape.rings=4
        _family_fx_material=StandardMaterial3D.new()
        _family_fx_material.vertex_color_use_as_albedo=true
        _family_fx_material.roughness=1.0
        _family_fx_material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    batch=MultiMeshInstance3D.new()
    batch.name=FX_V10
    batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    batch.material_override=_family_fx_material
    var pool:=MultiMesh.new()
    pool.transform_format=MultiMesh.TRANSFORM_3D
    pool.use_colors=true
    pool.mesh=_family_fx_shape
    pool.instance_count=8 if bool(model.get_meta("tarvoka_infantry_v2_hero",false)) else 4
    pool.visible_instance_count=0
    batch.multimesh=pool
    batch.visible=false
    model.add_child(batch)
    return batch

static func _family_anchor(model: Node3D,rig: String,point: Vector3) -> Vector3:
    return _family_node_anchor(model,_find(model,rig),point)

static func _family_node_anchor(model: Node3D,node: Node3D,point: Vector3) -> Vector3:
    while node!=null and node!=model:
        point=node.transform*point
        node=node.get_parent() as Node3D
    return point

static func _family_fx(model: Node3D,kind: String,t: float,stage: int) -> void:
    if str(model.get_meta(ARMOR_V10,"")) not in FAMILY_ANATOMY_ROLES:
        return
    model.set_meta(FX_V22,str(model.get_meta("tarvoka_infantry_role","line")))
    var impact: bool=stage<4 and kind in ["hit_bullet","hit_explosive"] and t>0.08 and t<0.85
    var dust: bool=stage<4 and kind in ["move","run"] and t>0.08 and t<0.92
    # Equipment smoke is a stylized visual effect at D3/D4, no HP change.
    var smoke: bool=stage>=3
    var batch: MultiMeshInstance3D=model.get_node_or_null(FX_V10) as MultiMeshInstance3D
    if not (impact or dust or smoke):
        if batch!=null:
            batch.visible=false
            batch.multimesh.visible_instance_count=0
        return
    if batch==null:
        batch=_family_fx_batch(model)
    var pool: MultiMesh=batch.multimesh
    var used: int=0
    if smoke:
        var count: int=pool.instance_count >> 1
        var origin: Vector3=_family_anchor(model,"TorsoRig",Vector3(-0.32,0.22,0.40))
        for i in range(count):
            var p: float=fposmod(t+float(i)/float(count),1.0)
            var at: Vector3=origin+Vector3(-0.08-0.12*p+0.065*sin(i*2.4),
                0.20+0.70*p,0.06*cos(i*2.4))
            var size: float=0.11+0.18*p
            pool.set_instance_transform(used,Transform3D(Basis.from_scale(Vector3(size,size*1.22,size)),at))
            pool.set_instance_color(used,Color("#52595a").lerp(Color("#a0a19b"),p))
            used+=1
    if impact or dust:
        var explosive: bool=kind=="hit_explosive"
        var count: int=pool.instance_count-used
        if not explosive:
            count=mini(count,pool.instance_count >> 1)
        var p: float=clampf((t-0.08)/0.77,0.0,1.0)
        var origin: Vector3=Vector3.ZERO
        var sole_contacts: Array[Vector3]=[]
        if dust:
            # Resolve each sole once per frame, not once per dust instance.
            for side in [-1,1]:
                var sole: MeshInstance3D=_find(model,"V2_Suela_%d"%side) as MeshInstance3D
                var contact:=Vector3(float(side)*0.21,0.04,0.13)
                if sole!=null and sole.mesh!=null:
                    var bounds: AABB=sole.mesh.get_aabb()
                    contact=_family_node_anchor(model,sole,Vector3(
                        bounds.get_center().x,bounds.position.y,bounds.get_center().z))
                sole_contacts.append(contact)
        else:
            origin=_family_anchor(model,"TorsoRig",Vector3(0,0,-0.43))
        for i in range(count):
            var angle: float=float(i)*2.399963
            var radius: float=(0.36 if explosive else 0.18)*p
            var at: Vector3=origin+Vector3(cos(angle)*radius,sin(angle)*radius,-0.07-0.20*p)
            var size: float=(0.15 if explosive else 0.075)*(1.0-0.5*p)
            var shade: Color=Color("#efac63").lerp(Color("#777d7c"),p) if explosive else Color("#e8d5ae")
            var dims: Vector3=Vector3.ONE*size if explosive else Vector3(size*0.55,size*0.55,size*2.3)
            if explosive:
                dims=Vector3(size,size*(0.75+0.55*p),size)
                at.y+=0.19*p*p
            if dust:
                var side: float=-1.0 if i%2==0 else 1.0
                # Dust follows the actual animated outsole instead of a
                # fixed point at the model root.
                at=sole_contacts[i%2]+Vector3(side*0.10*p,0.04+0.10*p,0.15*p)
                size=0.14*(1.0-0.45*p)
                dims=Vector3(size*1.4,size*0.65,size*1.4)
                shade=Color("#b2a18c")
            pool.set_instance_transform(used,Transform3D(Basis.from_scale(dims),at))
            pool.set_instance_color(used,shade)
            used+=1
    pool.visible_instance_count=used
    batch.visible=used>0

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func pose(model: Node3D, requested_kind: String, t: float) -> bool:
    if not has_model(model):
        return false
    var role: String=str(model.get_meta("tarvoka_infantry_role","line"))
    var rifle: Node3D=_find(model,"ArmamentoRig")
    if rifle==null:
        return false
    var stage: int=int(model.get_meta("tarvoka_infantry_damage",0))
    var collapsed: bool=stage>=4 and role in FAMILY_ANATOMY_ROLES
    var kind: String="idle" if collapsed else requested_kind
    var effect_phase: float=clampf(t,0.0,1.0)
    var phase: float=0.0 if collapsed else effect_phase
    # A destroyed model must not aim, walk or service equipment on a
    # later preview request. Retain only its independent smoke clock.
    if collapsed:
        var wreck_torso: Node3D=_find(model,"TorsoRig")
        if wreck_torso!=null:
            wreck_torso.rotation_degrees=Vector3.ZERO
    var pulse: float=sin(phase*PI)
    var walk: float=sin(phase*TAU*2.0)
    # Rifle points forward, not horizontally across the preview screenshot.
    rifle.rotation_degrees=Vector3(-6,67,0) if role!="infantry_antitank" else Vector3(-9,64,-12)
    if model.has_meta(FIT_V15):
        # Seat the preview weapon nearer the chest so the support arm
        # no longer stretches to the opposite side of the body.
        rifle.rotation_degrees=Vector3(-6,96,0)
        rifle.position=Vector3(0.04,0.015,-0.25)
        if kind=="attack":
            rifle.position.z-=0.045*pulse
    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        if arm==null:
            return false
        # In V1 the hands hang far outside the weapon. Opposing shoulder
        # yaw now converges the two covered palms around the real grips.
        arm.rotation_degrees.x=49.0 if role!="infantry_antitank" else 56.0
        arm.rotation_degrees.z=34.0 if side<0 else -24.0
        arm.rotation_degrees.y=6.0 if side<0 else -4.0
        if kind=="move":
            arm.rotation_degrees.x+=3.5*sin(phase*TAU*2.0+float(side)*PI*0.5)
            arm.rotation_degrees.z+=3.0*walk*float(side)
        elif kind=="run":
            arm.rotation_degrees.x+=6.0*pulse*sin(phase*TAU*3.0+float(side)*PI*0.5)
            arm.rotation_degrees.z+=4.0*pulse*sin(phase*TAU*3.0)*float(side)
        elif kind in ["attack","aim"]:
            arm.rotation_degrees.x+=5.0
            arm.rotation_degrees.z+=(-3.0 if side<0 else 2.0)*pulse
        elif kind in ["work","repair","capture"]:
            arm.rotation_degrees.x=38.0+14.0*pulse
            arm.rotation_degrees.z=18.0 if side<0 else -14.0
    if kind=="run":
        var torso: Node3D=_find(model,"TorsoRig")
        if torso!=null:
            torso.rotation_degrees.x=-12.0*pulse
            torso.rotation_degrees.y=5.0*sin(phase*TAU*3.0)*pulse
        rifle.rotation_degrees.x+=8.0*pulse
    if kind=="attack":
        rifle.rotation_degrees.x-=6.5*pulse
        rifle.position.z-=0.045*pulse
    elif kind=="aim":
        rifle.rotation_degrees.x-=1.8*pulse
    if role=="infantry_antitank":
        rifle.rotation_degrees.y=64.0
    var head: Node3D=_find(model,"CabezaRig")
    if head!=null:
        head.rotation_degrees.x=2.0+2.5*walk if kind=="move" else (
            -3.5*pulse if kind in ["attack","aim"] else 0.0)
        head.rotation_degrees.y=-4.0*walk if kind=="move" else 0.0
        if role in FAMILY_ANATOMY_ROLES:
            # Distinct reconnaissance/cargo posture without moving grips.
            if kind=="move":
                head.rotation_degrees.y*=float(GAIT_GAIN_V21.get(role,1.0))
            elif kind=="run":
                head.rotation_degrees.x=-3.0*pulse*float(GAIT_GAIN_V21.get(role,1.0))
            elif kind in ["work","repair"] and role in ["infantry_logistic","infantry_medic"]:
                head.rotation_degrees.x=(8.0 if role=="infantry_medic" else 5.0)*pulse
    var flash: Node3D=_find(model,"V2_DestelloDisparo3D")
    if flash!=null:
        flash.visible=kind=="attack" and phase>0.13 and phase<0.53
    var case_mesh: Node3D=_find(model,"V2_CasquilloFisico")
    if case_mesh!=null:
        case_mesh.visible=kind=="attack" and phase>0.26 and phase<0.74
        case_mesh.position=Vector3(0.09,0.10+0.09*pulse,0.21+0.13*pulse)
    # Damage remains owned by V1 and survives pose changes. Never amend HP.
    if bool(model.get_meta(SURFACE_V7,false)):
        sync_family_damage(model,stage)
        var body: Node3D=_find(model,"Infanteria_3D")
        if stage>=4:
            if body!=null:
                body.rotation_degrees.z=-74.0
                body.position.y=-0.22
            if flash!=null:
                flash.visible=false
            if case_mesh!=null:
                case_mesh.visible=false
        elif body!=null and not kind in ["damage","damaged","hit_bullet","hit_explosive"]:
            body.rotation_degrees.z=0.0
    var scar: Node3D=_find(model,"V2_CicatrizCasco")
    if scar!=null:
        scar.visible=stage>=3
    if bool(model.get_meta(FAMILY_GRIPS_V5,false)):
        if not _pose_family_legs(model,kind,phase,stage):
            return false
        _family_fx(model,kind,effect_phase,stage)
        return _service_pose(model,kind,phase) and _sync_family_grips(model)
    return true

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    pose(model,"idle",0.0)
