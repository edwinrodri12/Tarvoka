extends RefCounted
class_name TarvokaTankProductionV9

# G09 production geometry: functional roof service areas, real rounded
# wheel tires and suspended wheel fasteners, integrated turret front armor.
# Appended to the real Godot tank graph. No 2D drawing or concept art.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09ProductionV9"
const GREY := Color("#475864")
const EDGE := Color("#263540")
const STEEL := Color("#82919A")
const CERAMIC := Color("#758591")
const RUBBER := Color("#242A2D")
const GLASS := Color("#174D61")
const DUST := Color("#777163")

static func _armor(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, bevel: float, tint: Color,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    # Closed chamfered mesh (no alpha layer hiding unclosed geometry).
    var piece: MeshInstance3D = Hero._bevel(parent,label,pos,size,bevel,tint,rotation)
    piece.material_override = Hero._army_material(tint,true)
    return piece

static func _metal(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, tint: Color = EDGE) -> MeshInstance3D:
    var piece: MeshInstance3D = Hero._dark_box(parent,label,pos,size,tint)
    piece.material_override = Hero._army_material(tint,false)
    return piece

static func _seam(parent: Node3D, label: String, start: Vector3,
        stop: Vector3, radius: float = 0.014, tint: Color = EDGE) -> MeshInstance3D:
    return Hero._rod(parent,label,start,stop,radius,tint)

static func _wheel_trim(hull: Node3D) -> void:
    # Unlike the old primitive discs, every road wheel gets a physical
    # rubber tire, inset steel centre and six lug nuts. All repeated pieces
    # use two batched draw calls instead of 98 new scene meshes.
    var tire_mesh := TorusMesh.new()
    tire_mesh.inner_radius = 0.133
    tire_mesh.outer_radius = 0.167
    tire_mesh.rings = 10
    tire_mesh.ring_segments = 24
    var ring_instances := MultiMesh.new()
    ring_instances.transform_format = MultiMesh.TRANSFORM_3D
    ring_instances.mesh = tire_mesh
    ring_instances.instance_count = 14
    var nuts_mesh := SphereMesh.new()
    nuts_mesh.radius = 0.012
    nuts_mesh.height = 0.024
    nuts_mesh.radial_segments = 8
    nuts_mesh.rings = 4
    var lug_instances := MultiMesh.new()
    lug_instances.transform_format = MultiMesh.TRANSFORM_3D
    lug_instances.mesh = nuts_mesh
    lug_instances.instance_count = 84
    var count: int = 0
    var lug: int = 0
    var orient := Basis(Vector3.FORWARD,PI*0.5)
    for side in [-1,1]:
        var sign: float = float(side)
        for wheel in range(7):
            var z: float = -1.13 + float(wheel)*0.377
            var y: float = 0.29
            var ring := Transform3D(orient,Vector3(sign*1.365,y,z))
            ring_instances.set_instance_transform(count,ring)
            count += 1
            for bolt in range(6):
                var rad: float = TAU*float(bolt)/6.0
                var center := Vector3(sign*1.374,
                    y+0.058*cos(rad),z+0.058*sin(rad))
                lug_instances.set_instance_transform(lug,Transform3D(Basis.IDENTITY,center))
                lug += 1
    var tires := MultiMeshInstance3D.new()
    tires.name = "G09NeumaticosRuedasV9"
    tires.multimesh = ring_instances
    tires.material_override = Hero._army_material(RUBBER,false)
    hull.add_child(tires)
    var nuts := MultiMeshInstance3D.new()
    nuts.name = "G09TornillosRuedasV9"
    nuts.multimesh = lug_instances
    nuts.material_override = Hero._army_material(STEEL,false)
    hull.add_child(nuts)

static func _roof_details(turret: Node3D) -> void:
    # Distinct physical plates and embedded seams on the otherwise blank
    # V8 turret roof. Shallow hard-surface shapes, not tall floating blocks.
    for side in [-1,1]:
        var sign: float = float(side)
        _armor(turret,"G09PanelTechoDelanteroV9_%s" % side,
            Vector3(sign*0.515,0.683,-0.585),
            Vector3(0.282,0.037,0.437),0.026,GREY,
            Vector3(-4.0,sign*2.0,0.0))
        _seam(turret,"G09CordonTechoV9_%s" % side,
            Vector3(sign*0.669,0.691,-0.769),
            Vector3(sign*0.665,0.690,-0.367),0.012)
        # Side armor has a recessed horizontal service groove.
        _metal(turret,"G09JuntaMejillaV9_%s" % side,
            Vector3(sign*0.804,0.384,-0.565),
            Vector3(0.026,0.021,0.463))
        # Roof-top handhold is in front of the turret hatch, leaving the
        # circular hatches and armament silhouettes readable at battle zoom.
        _seam(turret,"G09AgarraderaDelanteraV9_%s" % side,
            Vector3(sign*0.475,0.725,-0.310),
            Vector3(sign*0.270,0.725,-0.310),0.014,STEEL)
        # Front wedge armor modules are actually chamfered along two axes.
        _armor(turret,"G09PlacaCeramicaMandibulaV9_%s" % side,
            Vector3(sign*0.516,0.389,-0.986),
            Vector3(0.334,0.167,0.240),0.075,CERAMIC,
            Vector3(-18.0,sign*13.0,-sign*6.0))
        _metal(turret,"G09JuntaCeramicaV9_%s" % side,
            Vector3(sign*0.520,0.353,-1.112),
            Vector3(0.235,0.016,0.021))
    # Breech panel is a narrow service hatch on the turret roof. Its four
    # edges are physically modeled, therefore legible without decals.
    _armor(turret,"G09PanelServicioTorreV9",
        Vector3(0.0,0.690,0.650),
        Vector3(0.305,0.028,0.235),0.033,GREY)
    _seam(turret,"G09BisagraTechoV9",
        Vector3(-0.128,0.715,0.773),Vector3(0.128,0.715,0.773),
        0.014,STEEL)
    for side in [-1,1]:
        var sign: float = float(side)
        # Integrated recessed side identification/thermal sensor.
        _armor(turret,"G09FundaSensorLateralV9_%s" % side,
            Vector3(sign*0.855,0.514,0.425),
            Vector3(0.090,0.104,0.232),0.028,GREY)
        _metal(turret,"G09LenteSensorLateralV9_%s" % side,
            Vector3(sign*0.905,0.524,0.430),
            Vector3(0.014,0.058,0.157),GLASS)

static func _hull_details(hull: Node3D) -> void:
    # Rear exhaust manifolds and service panel seams sit *inside* the roof
    # silhouette, giving recognizable engine systems from elevated camera.
    for side in [-1,1]:
        var sign: float = float(side)
        _armor(hull,"G09BisagraPortonMotorV9_%s" % side,
            Vector3(sign*0.602,1.146,1.338),
            Vector3(0.195,0.026,0.093),0.023,GREY)
        _seam(hull,"G09JuntaPortonMotorV9_%s" % side,
            Vector3(sign*0.652,1.166,0.815),
            Vector3(sign*0.650,1.166,1.373),0.010)
        # Two plated, short exhaust outlets at the extreme rear. Distinct
        # from bright fake rectangular outlines of earlier prototypes.
        _armor(hull,"G09EscudoEscapeV9_%s" % side,
            Vector3(sign*0.776,1.078,1.343),
            Vector3(0.150,0.075,0.263),0.024,GREY)
        _metal(hull,"G09SalidaEscapeV9_%s" % side,
            Vector3(sign*0.776,1.124,1.342),
            Vector3(0.077,0.011,0.171))
        # External tool and tow-cable retaining slots, flush to the skirt.
        for i in range(3):
            var z: float = -0.820+float(i)*0.747
            _metal(hull,"G09JuntaPanelFaldonV9_%s_%d" % [side,i],
                Vector3(sign*1.239,0.752,z),
                Vector3(0.013,0.235,0.024))
        _seam(hull,"G09CableRemolqueV9_%s" % side,
            Vector3(sign*0.854,1.043,-0.631),
            Vector3(sign*0.820,1.056,0.625),0.018,STEEL)
    _armor(hull,"G09PlacaCentralGlacisV9",
        Vector3(0,1.019,-1.218),
        Vector3(0.487,0.077,0.423),0.062,CERAMIC,
        Vector3(-20.0,0.0,0.0))

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_premium_finish_v8",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull := model.find_child("ChasisBlindado",true,false) as Node3D
    var turret := model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    _wheel_trim(hull)
    _roof_details(turret)
    _hull_details(hull)
    model.set_meta("tarvoka_mbt_production_v9",true)
    return true

static func restore_materials(model: Node3D) -> int:
    # Reinstall the authored military enamel for these visible components
    # after generic TankSurface3D applies its category PBR textures.
    if model == null or not model.get_meta("tarvoka_mbt_production_v9",false):
        return 0
    var painted: int = 0
    for name in ["G09PanelTechoDelanteroV9_-1","G09PanelTechoDelanteroV9_1",
            "G09PlacaCeramicaMandibulaV9_-1","G09PlacaCeramicaMandibulaV9_1",
            "G09PanelServicioTorreV9","G09BisagraPortonMotorV9_-1",
            "G09BisagraPortonMotorV9_1","G09EscudoEscapeV9_-1",
            "G09EscudoEscapeV9_1","G09PlacaCentralGlacisV9"]:
        var shape: MeshInstance3D = model.find_child(name,true,false) as MeshInstance3D
        if shape == null:
            continue
        var previous := shape.material_override as StandardMaterial3D
        var unique := previous.duplicate(true) as StandardMaterial3D
        unique.albedo_color = CERAMIC if "Ceramica" in name or "Glacis" in name else GREY
        unique.albedo_texture = Hero._army_texture()
        unique.normal_enabled = true
        unique.normal_texture = Hero._army_micro_normal()
        unique.normal_scale = 0.36
        unique.roughness_texture = Hero._army_micro_roughness()
        unique.roughness = 0.74
        unique.metallic = 0.21
        shape.material_override = unique
        painted += 1
    model.set_meta("tarvoka_mbt_production_v9_painted",painted)
    return painted
