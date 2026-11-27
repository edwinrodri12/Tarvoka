extends RefCounted
class_name TarvokaLayeredBridgePlaybackV48

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Crossings = preload("res://scripts/core/LayeredCrossingsV48.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# A visual quote, never an authoritative action. Playback restores the
# original pose; confirming real movement remains a separate engine action.
static func quote(state: Dictionary,unit_id: String,destination: Vector2i) -> Dictionary:
    var index: Dictionary = Crossings.state_index(state)
    if not index["valid"] or index["cells"].is_empty():
        return {}
    var side: int = int(state.get("faction",-1))
    var allowed: Variant = Visibility.visible_cells(state,side) if Visibility.enabled(state) else null
    for unit in state.get("units",[]):
        if str(unit.get("id",""))!=unit_id or not Turns.can_move(unit,side):
            continue
        var domain: String = Domains.domain(unit)
        var route: Array[Vector2i] = Crossings.route_for(state["terrain"],index["cells"],
            state["units"],unit["pos"],destination,domain,side,Logistics.movement_budget(unit),
            Logistics.road_fast(unit),Weather.from_state(state),Weather.traction(unit),allowed)
        if route.size()<2:
            return {}
        return {"id":unit_id,"domain":domain,"route":route,"seconds":float(route.size()-1)*0.48}
    return {}

static func sample(scene: Node3D,plan: Dictionary,progress: float,anchor_offset: float) -> Dictionary:
    if scene==null or not scene.has_meta("bridge_cells_v48") or not plan.has("route"):
        return {}
    var route: Array = plan["route"]
    if route.size()<2:
        return {}
    var t: float = clampf(progress,0.0,1.0)*float(route.size()-1)
    var segment: int = mini(floori(t),route.size()-2)
    var fraction: float = t-float(segment)
    var a: Vector3 = Terrain.world_at(route[segment])
    var b: Vector3 = Terrain.world_at(route[segment+1])
    var point: Vector3 = a.lerp(b,fraction)
    var domain: String = str(plan["domain"])
    var cells: Dictionary = scene.get_meta("public_cells")
    var bridges: Dictionary = scene.get_meta("bridge_cells_v48")
    var ramps: Array = scene.get_meta("bridge_ramp_profiles_v48")
    point.y = Terrain.bridge_surface_y(cells,bridges,ramps,point,domain)+anchor_offset
    var direction: Vector3 = b-a
    # Native vehicle/ship convention: local longitudinal Z; visual yaw
    # is applied only on the transient preview and restored afterward.
    return {"position":point,"yaw":atan2(direction.x,direction.z)}
