extends RefCounted
class_name TarvokaTankArmorV10

# G09 production art overhaul. Edits the actual, collision-independent
# visual surfaces used in the game -- not a separate scene or image.
# V9 baseline remains selectable through the art_level builder argument.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09ArmaduraIntegralV10"

const HULL := Color("#556974")
const TURRET := Color("#465966")
const CERAMIC := Color("#586D78")
const CERAMIC_DARK := Color("#495E69")
const GUNMETAL := Color("#2D3C48")
const SEAM := Color("#202F37")
const WEAR := Color("#8E9695")
const VISION := Color("#174A60")

static var _steel_enamel_mask: ImageTexture
static var _ceramic_enamel_mask: ImageTexture

static func _enamel_mask(ceramic: bool) -> ImageTexture:
    # Two original, distinct PBR albedo masks. Neither copies real tank
    # markings, photographs nor texture-pack assets. Highly constrained
    # variation: matte sprayed armor with brushed metallic grain and sparse
    # battle scuffs, not obvious cartoon camouflage squares.
    if ceramic and _ceramic_enamel_mask != null:
        return _ceramic_enamel_mask
    if not ceramic and _steel_enamel_mask != null:
        return _steel_enamel_mask
    const N := 256
    var img := Image.create(N,N,false,Image.FORMAT_RGBA8)
    for y in range(N):
        for x in range(N):
            var large: float = Hero._smooth_hash(float(x),float(y),73.0)
            var micro: float = Hero._smooth_hash(float(x),float(y),13.0)
            var abrasion: float = Hero._hash(x,y)
            var streak: float = Hero._smooth_hash(
                float(x)*0.77,float(y)*1.85,31.0)
            var brightness: float
            if ceramic:
                brightness = 0.945+0.046*(large-0.5)+0.035*(micro-0.5)
            else:
                brightness = 0.913+0.076*(large-0.5)+0.052*(streak-0.5)
            # Chipped edge flecks and hairline micro scratches are masked by
            # surface variation, not a set of hard square camouflage blobs.
            if abrasion > 0.994 and micro < 0.43:
                brightness = minf(1.0,brightness+0.095)
            elif abrasion < 0.009 and streak < 0.42:
                brightness *= 0.84
            brightness = clampf(brightness,0.76,1.0)
            img.set_pixel(x,y,Color(brightness,brightness,brightness,1))
    var atlas := ImageTexture.create_from_image(img)
    if ceramic:
        _ceramic_enamel_mask = atlas
    else:
        _steel_enamel_mask = atlas
    return atlas

static func _solid_replace(parent: Node3D, original_name: String,
        outline: Array, levels: Array) -> bool:
    var original: MeshInstance3D = parent.find_child(
        original_name,true,false) as MeshInstance3D
    if original == null:
        return false
    # Actual closed-mesh replacement, retaining name, UV material reference
    # and all battle/inspector scripts that look up original G09 nodes.
    var temporary: MeshInstance3D = Hero._loft(parent,
        "TemporaryShellG09V10",outline,levels)
    original.mesh = temporary.mesh
    temporary.free()
    return true

static func _plate(parent: Node3D,name: String,point: Vector3,
        volume: Vector3,bevel: float,tint: Color,
        angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return Hero._bevel(parent,name,point,volume,bevel,tint,angle)

static func _line(parent: Node3D,name: String,start: Vector3,
        end: Vector3,width: float = 0.012,
        tint: Color = SEAM) -> MeshInstance3D:
    return Hero._rod(parent,name,start,end,width,tint)

static func _dark(parent: Node3D,name: String,point: Vector3,
        volume: Vector3,tint: Color = SEAM) -> MeshInstance3D:
    return Hero._dark_box(parent,name,point,volume,tint)

static func _hide(model: Node3D, names: Array) -> void:
    for name in names:
        var old: Node3D = model.find_child(str(name),true,false) as Node3D
        if old != null:
            old.visible = false

static func _reprofile_hull(hull: Node3D) -> bool:
    # Seven-ring closed hull with cast-welded, sloping lateral shoulders,
    # harder frontal prow and flat engine deck. The broad upper edges alter
    # the 120px battle silhouette even with effects/antialiasing disabled.
    var contour := [
        Vector2(-0.48,-1.635),Vector2(0.48,-1.635),
        Vector2(0.71,-1.52),Vector2(0.885,-1.28),
        Vector2(0.965,-0.79),Vector2(0.985,0.85),
        Vector2(0.925,1.24),Vector2(0.73,1.54),
        Vector2(-0.73,1.54),Vector2(-0.925,1.24),
        Vector2(-0.985,0.85),Vector2(-0.965,-0.79),
        Vector2(-0.885,-1.28),Vector2(-0.71,-1.52)
    ]
    var levels := [
        [0.340,0.89,0.015],
        [0.410,0.98,0.025],
        [0.585,1.0,0.055],
        [0.835,1.0,0.13],
        [1.006,0.973,0.19],
        [1.085,0.915,0.22],
        [1.105,0.862,0.23]
    ]
    return _solid_replace(hull,"CorazaSoldadaHermeticaV7",
        contour,levels)

static func _reprofile_turret(turret: Node3D) -> bool:
    # 8-layer low-profile turret with pronounced nose and shoulders. This
    # replaces the V7 loaf-shaped turret's ACTUAL mesh, not another layer of
    # flat boxes. Top is sufficiently low for the existing hatches/cameras.
    var contour := [
        Vector2(-0.19,-1.42),Vector2(0.19,-1.42),
        Vector2(0.46,-1.29),Vector2(0.705,-1.105),
        Vector2(0.91,-0.78),Vector2(1.012,-0.38),
        Vector2(1.01,0.59),Vector2(0.86,0.96),
        Vector2(0.67,1.16),Vector2(-0.67,1.16),
        Vector2(-0.86,0.96),Vector2(-1.01,0.59),
        Vector2(-1.012,-0.38),Vector2(-0.91,-0.78),
        Vector2(-0.705,-1.105),Vector2(-0.46,-1.29)
    ]
    var levels := [
        [0.055,0.84,0.017],
        [0.103,0.98,0.025],
        [0.182,1.015,0.034],
        [0.352,1.00,0.043],
        [0.501,0.951,0.049],
        [0.580,0.912,0.053],
        [0.637,0.855,0.057],
        [0.650,0.810,0.061]
    ]
    return _solid_replace(turret,"TorreBajaSoldadaV7",
        contour,levels)

static func _upgrade_hull(hull: Node3D) -> void:
    # Retire shallow V7/9 protruding prow boxes. The consolidated sculpted
    # V10 glacis has two visible facets and sealed upper service access.
    for side in [-1,1]:
        var sign: float = float(side)
        _plate(hull,"G09V10GlacisSuperior_%s" % side,
            Vector3(sign*0.415,0.985,-1.266),
            Vector3(0.672,0.092,0.626),0.085,CERAMIC,
            Vector3(-27,sign*5.0,0))
        _plate(hull,"G09V10GlacisInferior_%s" % side,
            Vector3(sign*0.365,0.761,-1.539),
            Vector3(0.622,0.108,0.231),0.072,CERAMIC_DARK,
            Vector3(-12.0,sign*3.0,0))
        _line(hull,"G09V10UnionGlacis_%s" % side,
            Vector3(sign*0.74,0.984,-1.04),
            Vector3(sign*0.685,0.808,-1.553),0.015,SEAM)
        # Outer skirt identification accent stays uncovered: modern armour
        # shapes frame the 14 original faction-paint meshes.
        _plate(hull,"G09V10HombroFaldon_%s" % side,
            Vector3(sign*1.063,0.951,0.016),
            Vector3(0.174,0.152,2.735),0.055,HULL,
            Vector3(0,0,-sign*5.0))
        _line(hull,"G09V10NervioFaldon_%s" % side,
            Vector3(sign*1.157,0.964,-1.26),
            Vector3(sign*1.155,0.964,1.31),0.017,GUNMETAL)
        # Recessed tool and transport channels, not loose boxes.
        for n in range(3):
            var z: float = -0.62+float(n)*0.66
            _dark(hull,"G09V10AnclajeLateral_%s_%d" % [side,n],
                Vector3(sign*1.145,0.886,z),
                Vector3(0.013,0.048,0.238),GUNMETAL)
    _plate(hull,"G09V10EscudoProaUnificado",
        Vector3(0.0,0.708,-1.614),
        Vector3(0.875,0.135,0.097),0.039,HULL)
    # Flush engine service roof provides shape information at top-down
    # tactical zoom with no planar sticker or billboard.
    _plate(hull,"G09V10CubiertaMotorBlindada",
        Vector3(0.0,1.124,1.102),
        Vector3(1.34,0.047,0.701),0.054,HULL)
    for side in [-1,1]:
        var sign: float = float(side)
        _line(hull,"G09V10SoldaduraMotor_%s" % side,
            Vector3(sign*0.587,1.151,0.785),
            Vector3(sign*0.585,1.151,1.411),0.010,SEAM)
    # Engine vent inlets, modeled at fixed depth (no alpha cutout).
    for n in range(6):
        var z: float = 0.837+float(n)*0.102
        _dark(hull,"G09V10RejillaRefrigeracion_%02d" % n,
            Vector3(0.0,1.155,z),
            Vector3(0.990,0.012,0.049),GUNMETAL)

static func _wedge_cheek(turret: Node3D, side: int) -> MeshInstance3D:
    # Not a rotated BoxMesh. A custom 6-sided, physically capped composite
    # cheek follows the front of the turret as a single, heavy armored mass.
    # Slightly different upper/lower footprints create sloped ceramic faces.
    var sign: float = float(side)
    var lower := [
        Vector3(sign*0.22,0.176,-1.255),
        Vector3(sign*0.52,0.176,-1.299),
        Vector3(sign*0.815,0.177,-1.042),
        Vector3(sign*0.928,0.198,-0.584),
        Vector3(sign*0.672,0.177,-0.463),
        Vector3(sign*0.319,0.176,-0.685)
    ]
    var upper := [
        Vector3(sign*0.21,0.442,-1.232),
        Vector3(sign*0.465,0.481,-1.265),
        Vector3(sign*0.735,0.544,-0.985),
        Vector3(sign*0.818,0.554,-0.598),
        Vector3(sign*0.633,0.490,-0.492),
        Vector3(sign*0.319,0.442,-0.686)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var mid_lower := Vector3.ZERO
    var mid_upper := Vector3.ZERO
    for i in range(lower.size()):
        mid_lower += lower[i]
        mid_upper += upper[i]
    mid_lower /= float(lower.size())
    mid_upper /= float(upper.size())
    for i in range(lower.size()):
        var next: int = (i+1)%lower.size()
        Hero._tri(st,lower[i],lower[next],upper[next])
        Hero._tri(st,lower[i],upper[next],upper[i])
        Hero._tri(st,mid_lower,lower[next],lower[i])
        Hero._tri(st,mid_upper,upper[i],upper[next])
    var part := MeshInstance3D.new()
    part.name = "G09V10MejillaCompuesta_%s" % side
    part.mesh = st.commit()
    part.material_override = Hero._army_material(CERAMIC,true)
    turret.add_child(part)
    return part

static func _upgrade_turret(turret: Node3D) -> void:
    # Two large coherent armored cheeks and side curtains, with deliberate
    # negative-space seams. Their placement follows the V10 hull's new
    # profile and changes appearance dramatically at battle scale.
    for side in [-1,1]:
        var sign: float = float(side)
        _wedge_cheek(turret,side)
        _plate(turret,"G09V10PlanchaMejillaExterior_%s" % side,
            Vector3(sign*0.904,0.326,-0.674),
            Vector3(0.145,0.276,0.599),0.044,CERAMIC_DARK,
            Vector3(-3.0,sign*9.0,sign*6.0))
        _line(turret,"G09V10BordeMejilla_%s" % side,
            Vector3(sign*0.785,0.557,-1.09),
            Vector3(sign*0.868,0.559,-0.484),0.022,GUNMETAL)
        # Broad sloping integrated side armor, not a row of cubes.
        _plate(turret,"G09V10BlindajeLateral_%s" % side,
            Vector3(sign*0.973,0.353,0.158),
            Vector3(0.095,0.315,0.716),0.045,HULL,
            Vector3(0,sign*4.0,-sign*4.0))
        for n in range(3):
            var z: float = -0.10+float(n)*0.273
            _line(turret,"G09V10CosturaBlindaje_%s_%d" % [side,n],
                Vector3(sign*1.025,0.208,z),
                Vector3(sign*1.026,0.478,z),0.010,SEAM)
        _plate(turret,"G09V10TapaEscudoPosterior_%s" % side,
            Vector3(sign*0.678,0.432,0.914),
            Vector3(0.245,0.225,0.373),0.067,HULL,
            Vector3(0,sign*11.0,-sign*3.0))
        _line(turret,"G09V10SoldaduraTecho_%s" % side,
            Vector3(sign*0.690,0.659,-0.550),
            Vector3(sign*0.687,0.659,0.480),0.012,GUNMETAL)
    # New trapezoidal front around the gun retains its exact animation pivot.
    _plate(turret,"G09V10ModuloAnteriorTorre",
        Vector3(0,0.402,-1.192),Vector3(0.352,0.301,0.263),
        0.081,TURRET,Vector3(-8,0,0))
    _plate(turret,"G09V10PanelServicioTecho",
        Vector3(0,0.684,0.740),Vector3(0.400,0.029,0.220),
        0.045,HULL)
    _line(turret,"G09V10BisagraPanelTecho",
        Vector3(-0.17,0.707,0.859),
        Vector3(0.17,0.707,0.859),0.011,WEAR)

static func _authored_roof_hard_surface(turret: Node3D) -> void:
    # Real shallow panels and steel fixings sit on the watertight V10 roof.
    # No tall disconnected boxes and no interference with animated sights.
    for side in [-1,1]:
        var sign: float = float(side)
        _plate(turret,"G09V10PanelAnteriorTecho_%s" % side,
            Vector3(sign*0.438,0.669,-0.542),
            Vector3(0.267,0.033,0.390),0.048,HULL,
            Vector3(-5,sign*2,0))
        _line(turret,"G09V10JuntaPanelAnterior_%s" % side,
            Vector3(sign*0.568,0.691,-0.706),
            Vector3(sign*0.569,0.691,-0.368),0.011,SEAM)
        _plate(turret,"G09V10PanelPosteriorTecho_%s" % side,
            Vector3(sign*0.458,0.675,0.824),
            Vector3(0.306,0.031,0.226),0.048,HULL)
        _line(turret,"G09V10SoldaduraPanelPosterior_%s" % side,
            Vector3(sign*0.317,0.698,0.941),
            Vector3(sign*0.599,0.698,0.941),0.012,SEAM)
        _dark(turret,"G09V10ZonaAntideslizante_%s" % side,
            Vector3(sign*0.365,0.681,-0.129),
            Vector3(0.169,0.014,0.215),GUNMETAL)
    _plate(turret,"G09V10RegistroCentralTorre",
        Vector3(0,0.677,-0.103),Vector3(0.210,0.023,0.281),
        0.033,TURRET)
    _line(turret,"G09V10CierreRegistroCentral",
        Vector3(-0.09,0.693,0.026),
        Vector3(0.09,0.693,0.026),0.009,WEAR)
    # Twenty-four visible roof fasteners, ONE mobile MultiMesh draw batch.
    var nuts := MultiMeshInstance3D.new()
    nuts.name = "G09V10TornillosTecho"
    var sphere := SphereMesh.new()
    sphere.radius = 0.010
    sphere.height = 0.018
    sphere.radial_segments = 8
    sphere.rings = 4
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = sphere
    mm.instance_count = 24
    var i: int = 0
    for side in [-1,1]:
        var sign: float = float(side)
        for z in [-0.73,-0.54,-0.35,0.62,0.79,0.96]:
            for edge in [0,1]:
                var x: float = sign*(0.335 if edge==0 else 0.594)
                var y: float = 0.692 if z<0.0 else 0.699
                mm.set_instance_transform(i,
                    Transform3D(Basis.IDENTITY,Vector3(x,y,float(z))))
                i += 1
    nuts.multimesh = mm
    nuts.material_override = Hero._army_material(WEAR,false)
    turret.add_child(nuts)

static func _mobile_microdetail_lod(model: Node3D) -> void:
    # Save actual mobile fill/draw time at long camera distances: tiny
    # fasteners and weld beads fade out only when they are sub-pixel small.
    # Full 3D remains inspectable when the phone/browser camera is close.
    var affected: int = 0
    for pattern in ["G09TornillosRuedasV9","RemachesBujesRodaje",
            "PernosFaldones","PernosCorazaTorre",
            "G09V10TornillosTecho",
            "G09V10CosturaBlindaje_*",
            "G09V10SoldaduraMotor_*","G09V10UnionGlacis_*",
            "G09V10AnclajeLateral_*","G09V10BisagraPanelTecho"]:
        for part in model.find_children(pattern,"GeometryInstance3D",true,false):
            var geo: GeometryInstance3D = part as GeometryInstance3D
            if geo == null:
                continue
            geo.visibility_range_end = 23.0
            geo.visibility_range_end_margin = 3.0
            affected += 1
    model.set_meta("tarvoka_mbt_sculpted_v10_micro_lod_count",affected)

static func apply(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    if not model.get_meta("tarvoka_mbt_production_v9",false):
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    if not _reprofile_hull(hull) or not _reprofile_turret(turret):
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    _hide(model,[
        "GlacisCeramicoV7_-1","GlacisCeramicoV7_1",
        "G09PlacaCentralGlacisV9",
        "G09PlacaCeramicaMandibulaV9_-1",
        "G09PlacaCeramicaMandibulaV9_1",
        "CubiertaCompuestaFrontalG09_-1",
        "CubiertaCompuestaFrontalG09_1",
        "ModuloBlindajeCeramicoV7_-1",
        "ModuloBlindajeCeramicoV7_1",
        "G09PanelTechoDelanteroV9_-1",
        "G09PanelTechoDelanteroV9_1",
        "G09CubiertaMotorSelladaV7",
        "CubiertaMotorRectificadaV7"])
    _upgrade_hull(hull)
    _upgrade_turret(turret)
    _authored_roof_hard_surface(turret)
    _mobile_microdetail_lod(model)
    model.set_meta("tarvoka_mbt_sculpted_v10",true)
    return true

static func finish_materials(model: Node3D) -> int:
    # Called after the generic material pass (which otherwise overwrites
    # authored colors). Preserve roughness, mipmapped armor microtexture and
    # separate ceramic/graphite enamel on real in-game surfaces.
    if model == null or not model.get_meta("tarvoka_mbt_sculpted_v10",false):
        return 0
    var count: int = 0
    for node in model.find_children("G09V10*","MeshInstance3D",true,false):
        var mesh: MeshInstance3D = node as MeshInstance3D
        if mesh == null:
            continue
        var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
        if material == null:
            continue
        var cloned: StandardMaterial3D = material.duplicate(true) as StandardMaterial3D
        cloned.roughness = 0.72
        cloned.metallic = 0.23
        cloned.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        var tint: Color = material.albedo_color
        if "Inferior" in str(node.name) or "Exterior" in str(node.name):
            tint = CERAMIC_DARK
        elif "Mejilla" in str(node.name) or "Glacis" in str(node.name):
            tint = CERAMIC
        elif "Soldadura" in str(node.name) or "Union" in str(node.name) or \
                "Costura" in str(node.name) or "Rejilla" in str(node.name):
            tint = GUNMETAL
        cloned.albedo_color = tint
        if tint != GUNMETAL and tint != SEAM and tint != WEAR:
            var ceramic_surface: bool = "Mejilla" in str(node.name) or                 "Glacis" in str(node.name) or "Compuesta" in str(node.name)
            cloned.albedo_texture = _enamel_mask(ceramic_surface)
            cloned.normal_enabled = true
            cloned.normal_texture = Hero._army_micro_normal()
            cloned.normal_scale = 0.38 if ceramic_surface else 0.29
            cloned.roughness_texture = Hero._army_micro_roughness()
            cloned.roughness = 0.81 if ceramic_surface else 0.73
            cloned.metallic = 0.12 if ceramic_surface else 0.26
        else:
            cloned.albedo_texture = null
            cloned.normal_enabled = false
            cloned.roughness_texture = null
            cloned.roughness = 0.58
            cloned.metallic = 0.54
        mesh.material_override = cloned
        count += 1
    var body: MeshInstance3D = model.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var head: MeshInstance3D = model.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    if body != null:
        var mat: StandardMaterial3D = body.material_override.duplicate(true) as StandardMaterial3D
        mat.albedo_color = HULL
        mat.albedo_texture = _enamel_mask(false)
        mat.roughness = 0.74
        mat.metallic = 0.24
        body.material_override = mat
    if head != null:
        var mat: StandardMaterial3D = head.material_override.duplicate(true) as StandardMaterial3D
        mat.albedo_color = TURRET
        mat.albedo_texture = _enamel_mask(false)
        mat.roughness = 0.74
        mat.metallic = 0.24
        head.material_override = mat
    # Real moving-gun metal now matches the military enamel. These meshes
    # remain attached to ElevacionCanon and retain elevation/recoil.
    for name in ["ManguitoTermico","ExtractorGases",
            "AbrazaderaManguitoCanon0","AbrazaderaManguitoCanon1"]:
        var gun_part: MeshInstance3D = model.find_child(
            name,true,false) as MeshInstance3D
        if gun_part == null or gun_part.material_override == null:
            continue
        var gun_finish: StandardMaterial3D = gun_part.material_override.duplicate(true) as StandardMaterial3D
        gun_finish.albedo_color = Color("#43545F")
        gun_finish.albedo_texture = Hero._army_texture()
        gun_finish.roughness = 0.62
        gun_finish.metallic = 0.36
        gun_part.material_override = gun_finish
    model.set_meta("tarvoka_mbt_sculpted_v10_pbr_count",count)
    return count
