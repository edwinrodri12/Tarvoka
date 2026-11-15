extends Node3D
class_name TarvokaAirbaseDoorRigV2

# Reversible, deterministic 4-leaf telescopic hangar gate animation.
# Moves the ACTUAL V1 panel/rib meshes, not a separate demo mesh.
# Only healthy gates (damage states 0/1) operate. No game HP/AI changes.
signal operation_completed(opened: bool)

const STAGE_NAME := "AnimacionPortonesHangarV2"
const MOTION_SECONDS := 1.85
const OPEN_X := [-3.43,-3.43,3.43,3.43]
const CLOSED_X := [-2.57,-0.85,0.87,2.59]
const PANEL_DEPTH_OFFSET := [-0.065,-0.19,-0.19,-0.065]

var damage_stage := 0
var _parts: Array[Dictionary] = []
var _fraction := 0.0
var _target := 0.0
var _installed := false
var _distant := false

static func build(stage: int) -> TarvokaAirbaseDoorRigV2:
    var node := TarvokaAirbaseDoorRigV2.new()
    node.name = STAGE_NAME
    node.damage_stage = stage
    node.set_meta("tarvoka_visual_only",true)
    return node

func _ready() -> void:
    _parts.clear()
    _installed = false
    if damage_stage > 1 or damage_stage < 0:
        set_process(false)
        return
    var building: Node3D = get_parent() as Node3D
    if building == null:
        set_process(false)
        return
    var hangar: Node3D = building.find_child("HangarPrincipalV1",true,false) as Node3D
    if hangar == null:
        set_process(false)
        return
    for i in range(4):
        var names: Array[String] = [
            "CompuertaPrincipal_%d" % i,
            "FranjaVerticalPorton_%d" % i]
        for rib in range(3):
            names.append("RefuerzoPorton_%d_%d" % [i,rib])
        for name in names:
            var part: MeshInstance3D = hangar.get_node_or_null(name) as MeshInstance3D
            if part == null:
                _parts.clear()
                set_process(false)
                return
            # Rail pockets are inside the footprint. Inner leaves stack
            # slightly forward in their own plane to prevent z-fighting.
            var target: Vector3 = Vector3(
                OPEN_X[i]-CLOSED_X[i],0,PANEL_DEPTH_OFFSET[i])
            _parts.append({"mesh":part,"start":part.position,
                "offset":target,"leaf":i})
    _installed = _parts.size()==20
    _pose()
    set_process(false)

func is_operational() -> bool:
    return _installed and damage_stage <= 1

func gate_mesh_count() -> int:
    return _parts.size()

func open_fraction() -> float:
    return _fraction

func is_moving() -> bool:
    return is_operational() and not is_equal_approx(_fraction,_target)

func play_open() -> bool:
    return _start(1.0)

func play_close() -> bool:
    return _start(0.0)

func _start(goal: float) -> bool:
    if not is_operational():
        return false
    _target = goal
    set_process(not _distant and is_moving())
    return true

func set_open_fraction(value: float) -> bool:
    if not is_operational():
        return false
    _fraction = clampf(value,0.0,1.0)
    _target = _fraction
    set_process(false)
    _pose()
    return true

func _pose() -> void:
    # Cubic smoothstep for near-zero door speed at both endpoints.
    var t: float = _fraction*_fraction*(3.0-2.0*_fraction)
    for entry in _parts:
        var node: MeshInstance3D = entry["mesh"] as MeshInstance3D
        if is_instance_valid(node):
            node.position = (entry["start"] as Vector3) + (entry["offset"] as Vector3)*t

func advance(delta: float) -> void:
    if not is_operational() or _distant or not is_moving():
        return
    _fraction = move_toward(_fraction,_target,
        maxf(0.0,delta)/MOTION_SECONDS)
    _pose()
    if not is_moving():
        set_process(false)
        operation_completed.emit(_target>0.5)

func _process(delta: float) -> void:
    advance(delta)

func set_distant(distant: bool) -> void:
    _distant = distant
    set_process(is_operational() and not distant and is_moving())
