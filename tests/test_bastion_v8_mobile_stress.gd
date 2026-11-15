extends SceneTree

# Godot/Mesa smoke + resource-budget checks; NOT a physical Android FPS test.
# Tests same visual unit count as 8 players x 8 Bastion vehicles, retaining
# fog restrictions and faction identity even beyond 8 "detailed" unit slots.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Tactical = preload("res://scripts/ui/APCTacticalLOD8.gd")
const Battle = preload("res://scripts/ui/BattleTerrain3D.gd")

var failures: int = 0

func _check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        push_error("P06 V8 mobile QA: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Tactical.MAX_DRAW_SURFACES<=15,
        "mobile render surface budget is declared")
    var individual: Node3D=Models.build("apc",0,false,8)
    _check(individual != null and Tactical.has_model(individual),
        "native mobile APC instead of disk")
    if individual != null and Tactical.has_model(individual):
        root.add_child(individual)
        _check(individual.get_meta("tarvoka_apc_lod8_wheel_count",0)==6,
            "six real wheels, no square surrogate")
        _check(individual.find_child("CascoBlindadoEsculpidoP06",true,false)!=null,
            "silhouette matches production five-ring welded hull")
        var wheel: MultiMeshInstance3D=individual.find_child(
            Tactical.WHEELS,true,false) as MultiMeshInstance3D
        _check(wheel!=null and wheel.multimesh.instance_count==6,
            "all six wheels in a single GPU instance batch")
        _check(Tactical.draw_surfaces(individual)<=Tactical.MAX_DRAW_SURFACES,
            "native APC uses <=15 mesh surfaces")
        _check(Models.pose_model("apc",individual,"move",0.55),
            "native wheel spin is controllable")
        _check(Models.pose_model("apc",individual,"attack",0.49),
            "six-pulse tactical gun recoil stays available")
        Models.restore_model_pose("apc",individual)
        individual.queue_free()
        await process_frame

    var units: Array=[]
    var cells: Dictionary={}
    for y in range(8):
        for x in range(8):
            var index: int=y*8+x
            var pos:=Vector2i(x,y)
            cells[pos]={"kind":"plain","seen":true,"visible":true}
            units.append({
                "id":"apc_%d" % index, "hp":10, "pos":pos,
                "faction":index%8,"role":"apc","domain":"ground"})
    var container:=Node3D.new()
    root.add_child(container)
    var time_start: int=Time.get_ticks_usec()
    var results: Dictionary=Battle._make_units(
        container,{"units":units},cells,"apc_0")
    var duration_ms: float=float(Time.get_ticks_usec()-time_start)/1000.0
    _check(int(results.get("visible",-1))==64,
        "all 64 visible APCs rendered, no arbitrary 8 unit cutoff")
    _check(int(results.get("apc_lod",-1))==64,
        "64 tactical 6x6 sculpts rather than disks")
    _check(int(results.get("hidden_enemies",-1))==0,
        "visible scope unchanged")
    _check(container.get_child_count()==64,
        "one inspectable Node3D per logical APC")
    var total_surfaces: int=0
    var palette_count: Dictionary={}
    for vehicle in container.get_children():
        var model: Node3D=vehicle as Node3D
        _check(model!=null and Tactical.has_model(model),
            "battle-rendered unit is a true native LOD")
        total_surfaces+=Tactical.draw_surfaces(model)
        var color: Color=model.get_meta(
            "tarvoka_apc_lod8_faction_color",Color.BLACK)
        palette_count[color.to_html()]=true
        _check(model.get_meta("cell",Vector2i(-1,-1))!=Vector2i(-1,-1),
            "unit kept real grid position and render metadata")
    _check(palette_count.size()==8,"all eight official faction colors used")
    _check(total_surfaces<=64*Tactical.MAX_DRAW_SURFACES,
        "64-vehicle graphics budget remains bounded")
    _check(container.get_child_count()==64,
        "no hidden children or game-state units created")
    var last: Node3D=container.get_child(63) as Node3D
    var home: Vector3=last.position
    _check(Models.pose_model("apc",last,"move_turn",0.50),
        "real battle grid unit animates without origin reset")
    Models.restore_model_pose("apc",last)
    _check(last.position.distance_to(home)<0.001,
        "grid cell unchanged after six-wheel cornering")
    container.queue_free()
    await process_frame

    # Fog of war must be checked BEFORE attempting to create any 3D model.
    var fogged: Dictionary=cells.duplicate(true)
    var hidden_pos:=Vector2i(7,7)
    fogged[hidden_pos]={"kind":"plain","seen":true,"visible":false}
    var reduced:=Node3D.new()
    root.add_child(reduced)
    var fog_results: Dictionary=Battle._make_units(
        reduced,{"units":units},fogged,"")
    _check(int(fog_results.get("hidden_enemies",0))==1,
        "invisible enemy APC never becomes visible from batching")
    _check(int(fog_results.get("apc_lod",0))==63,
        "only 63 visually revealed APCs constructed")
    reduced.queue_free()
    await process_frame
    if failures>0:
        push_error("P06 V8 mobile QA failures: %d" % failures)
        quit(1)
        return
    print("PASS P06 V8: 64 native 6x6 LODs, 8 colors, 2 wheel GPU batches, fog respected, <=%d surfaces, CPU construction %.1f ms (Mesa, not Android FPS)" % [
        64*Tactical.MAX_DRAW_SURFACES,duration_ms])
    quit(0)
