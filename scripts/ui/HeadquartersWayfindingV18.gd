extends RefCounted
class_name TarvokaHeadquartersWayfindingV18

# Showroom-only, batched architectural detail for the full V12 hero HQ.
# Deliberately NOT part of V13 tactical meshes, Android sprites, gameplay
# state, selection volumes, collision, fog or multiplayer simulation.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME := "SenalizacionArquitectonicaHQV18"
const MAX_DRAW_BATCHES := 3
const INSTANCE_TOTAL := 14

static func _emissive(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.12
    mat.roughness = 0.39
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 1.25
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _batch(name: String, blocks: Array, tint: Color) -> MultiMeshInstance3D:
    var node := MultiMeshInstance3D.new()
    node.name = name
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE
    var instances := MultiMesh.new()
    instances.transform_format = MultiMesh.TRANSFORM_3D
    instances.mesh = cube
    instances.instance_count = blocks.size()
    for i in range(blocks.size()):
        var center: Vector3 = blocks[i][0]
        var size: Vector3 = blocks[i][1]
        instances.set_instance_transform(i,Transform3D(Basis().scaled(size),center))
    node.multimesh = instances
    node.material_override = _emissive(tint)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.set_meta("tarvoka_hq_v18_batched",true)
    return node

static func build() -> Node3D:
    var stage := Node3D.new()
    stage.name = STAGE_NAME
    stage.set_meta("tarvoka_hq_v18_wayfinding",true)
    stage.set_meta("tarvoka_visual_only",true)
    stage.set_meta("tarvoka_hq_v18_max_draws",MAX_DRAW_BATCHES)
    # Façade glows occupy existing openings; they never cover the official
    # faction crest or change the silhouette of the central radar.
    # Coordinates are calibrated against REAL V12 glazing in
    # HeadquartersSilhouetteV12._wing_profiles and
    # Headquarters3D._windows, not approximate facade rectangles.
    # The final two upper tower panes are translated by level in apply().
    var windows := [
        [Vector3(-4.60,2.56,-3.149),Vector3(0.29,0.18,0.012)],
        [Vector3(-3.46,2.56,-3.149),Vector3(0.29,0.18,0.012)],
        [Vector3(3.46,2.56,-3.149),Vector3(0.29,0.18,0.012)],
        [Vector3(4.60,2.56,-3.149),Vector3(0.29,0.18,0.012)],
        [Vector3(-1.32,1.26,-2.452),Vector3(0.48,0.44,0.012)],
        [Vector3(1.32,1.26,-2.452),Vector3(0.48,0.44,0.012)],
        [Vector3(-1.26,4.945,-2.817),Vector3(0.19,0.26,0.012)],
        [Vector3(1.26,4.945,-2.817),Vector3(0.19,0.26,0.012)]
    ]
    stage.add_child(_batch("VentanasIluminadasUnLoteV18",windows,Color("#ffd9a0")))
    # Wide, unmistakable faction accents flank the front entrance; at night
    # the identity reads better than tiny strips lost on the 3D geometry.
    var accents := [
        [Vector3(-1.93,1.53,-4.02),Vector3(0.13,1.58,0.12)],
        [Vector3(1.93,1.53,-4.02),Vector3(0.13,1.58,0.12)],
        [Vector3(-4.01,3.25,-2.97),Vector3(1.66,0.10,0.12)],
        [Vector3(4.01,3.25,-2.97),Vector3(1.66,0.10,0.12)]
    ]
    stage.add_child(_batch("GuiasColorFaccionUnLoteV18",accents,Color("#69a3ee")))
    # Roof safety beacons use emission, NOT two additional OmniLight3D
    # objects or separate dynamic shadows.
    var beacons := [
        [Vector3(-5.32,3.90,-2.55),Vector3(0.20,0.18,0.20)],
        [Vector3(5.32,3.90,-2.55),Vector3(0.20,0.18,0.20)]
    ]
    stage.add_child(_batch("BalizasSeguridadUnLoteV18",beacons,Color("#ffac65")))
    stage.visible = false
    return stage

static func apply(stage: Node3D, faction: int, level: int,
        condition: String, lighting: int, weather: String,
        enabled: bool = true, distant: bool = false) -> bool:
    if stage == null or faction < 0 or faction > 7 or level < 1 or level > 3:
        return false
    if not condition in ["operativo","capturado","danado","destruido"]:
        return false
    if not weather in ["clear","rain","snow"] or lighting < 0 or lighting > 2:
        return false
    # No floating façade details over rubble, LOD proxies or V15 sprites.
    stage.visible = enabled and not distant and condition != "destruido" and lighting > 0
    # V18's upper glows must follow the V4 tower height at L1/L2/L3.
    # Do not regenerate the mesh or create new instances at each level.
    var windows: MultiMeshInstance3D = stage.get_node("VentanasIluminadasUnLoteV18")
    for side in [-1,1]:
        var index: int = 6 if side == -1 else 7
        var transform: Transform3D = windows.multimesh.get_instance_transform(index)
        transform.origin.y = 4.945 + 0.91 * float(level-1)
        windows.multimesh.set_instance_transform(index,transform)
    var accents: MultiMeshInstance3D = stage.get_node("GuiasColorFaccionUnLoteV18")
    var paint: StandardMaterial3D = accents.material_override as StandardMaterial3D
    var faction_color: Color = Style.faction_color(faction)
    paint.albedo_color = faction_color
    paint.emission = faction_color
    for child in stage.get_children():
        var part: MultiMeshInstance3D = child as MultiMeshInstance3D
        var material: StandardMaterial3D = part.material_override as StandardMaterial3D
        material.emission_energy_multiplier = (1.85 if lighting == 2 else 0.86) * (1.16 if weather == "rain" else 1.0)
    stage.set_meta("tarvoka_hq_v18_weather_visual",weather)
    stage.set_meta("tarvoka_hq_v18_lighting",lighting)
    stage.set_meta("tarvoka_hq_v18_faction",faction)
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
