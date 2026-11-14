extends Control
class_name TarvokaVisualStressBenchmark

# Android QA only. Reuses the real TouchBoard, terrain, tank sprite atlas and
# 3D-baked HQ PNGs. All added troops/effects are VISUAL LOAD; not a real match.
signal benchmark_completed(results: Array)

const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const VisualBudget = preload("res://scripts/ui/VisualBudget.gd")
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const HQ = preload("res://scripts/ui/HeadquartersSpriteV15.gd")
const Renderer = preload("res://scripts/ui/IsoRenderer.gd")
const SiteData = preload("res://scripts/ui/SiteOverlayData.gd")

const SEED := 774113
const CASES := [
    {"name":"HQ detallado", "dims":Vector2i(24,18), "tanks":24,
        "weather":"clear", "zoom":1.8, "focus":Vector2i(4,3), "effects":2, "saver":false},
    {"name":"Mapa completo", "dims":Vector2i(40,30), "tanks":60,
        "weather":"clear", "zoom":1.0, "focus":Vector2i(20,15), "effects":0, "saver":false},
    {"name":"Lluvia y combate", "dims":Vector2i(40,30), "tanks":100,
        "weather":"rain", "zoom":1.55, "focus":Vector2i(20,15), "effects":8, "saver":false},
    {"name":"Nieve extrema", "dims":Vector2i(40,30), "tanks":150,
        "weather":"snow", "zoom":1.7, "focus":Vector2i(20,15), "effects":16, "saver":false},
    {"name":"Nieve con ahorro", "dims":Vector2i(40,30), "tanks":150,
        "weather":"snow", "zoom":1.7, "focus":Vector2i(20,15), "effects":16, "saver":true},
    {"name":"8 equipos: avanzada", "dims":Vector2i(40,30), "tanks":160, "sites":64, "teams":8,
        "weather":"clear", "zoom":1.9, "focus":Vector2i(20,15), "effects":8, "saver":false},
    {"name":"8 equipos: grande", "dims":Vector2i(40,30), "tanks":320, "sites":128, "teams":8,
        "weather":"clear", "zoom":1.7, "focus":Vector2i(20,15), "effects":16, "saver":false},
    {"name":"8 equipos: masiva", "dims":Vector2i(40,30), "tanks":512, "sites":192, "teams":8,
        "weather":"rain", "zoom":1.7, "focus":Vector2i(20,15), "effects":24, "saver":false},
    {"name":"8 equipos: extremo", "dims":Vector2i(40,30), "tanks":768, "sites":256, "teams":8,
        "weather":"snow", "zoom":1.9, "focus":Vector2i(20,15), "effects":32, "saver":false},
    {"name":"8 equipos: ahorro", "dims":Vector2i(40,30), "tanks":768, "sites":256, "teams":8,
        "weather":"snow", "zoom":1.9, "focus":Vector2i(20,15), "effects":32, "saver":true},
    {"name":"8 equipos: culling cercano", "dims":Vector2i(40,30), "tanks":768, "sites":256, "teams":8,
        "weather":"rain", "zoom":4.0, "focus":Vector2i(4,4), "effects":32, "saver":false}
]

var board: Control
var status_label: Label
var output_label: RichTextLabel
var start_button: Button
var running := false
var completed := false
var results: Array[Dictionary] = []
var _case_index := -1
var _seconds := 0.0
var _effect_seconds := 0.0
var _warmup_seconds := 1.25
var _measure_seconds := 6.0
var _samples: Array[float] = []
var _peak_mem_mb := 0.0
var _last_stats: Dictionary = {}
var _actual_tanks := 0
var _actual_sites := 0
var _actual_teams := 2
var _result_text := ""
var _previous_memory := 0.0

func set_test_timings(warmup: float, measure: float) -> void:
    _warmup_seconds = maxf(0.02,warmup)
    _measure_seconds = maxf(0.06,measure)

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var background := ColorRect.new()
    background.color = Color("#07121F")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var frame := HBoxContainer.new()
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame.add_theme_constant_override("separation",8)
    add_child(frame)
    var viewport_panel := PanelContainer.new()
    viewport_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewport_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(viewport_panel)
    board = BoardScript.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    viewport_panel.add_child(board)

    var right := VBoxContainer.new()
    right.custom_minimum_size.x = 325
    right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(right)
    var title := Label.new()
    title.text = "TARVOKA | PRUEBA DE ESTRÉS"
    title.add_theme_font_size_override("font_size",20)
    right.add_child(title)
    var instructions := Label.new()
    instructions.text = "Carga aislada: hasta 8 equipos, 768 tanques y 256 edificios. NO simula la red ni la IA de ocho jugadores. Los FPS corresponden a este dispositivo."
    instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    right.add_child(instructions)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    right.add_child(status_label)
    output_label = RichTextLabel.new()
    output_label.bbcode_enabled = false
    output_label.scroll_following = true
    output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(output_label)
    start_button = Button.new()
    start_button.text = "REPETIR PRUEBA"
    start_button.pressed.connect(start_benchmark)
    right.add_child(start_button)
    var copy_button := Button.new()
    copy_button.text = "COPIAR INFORME"
    copy_button.pressed.connect(_copy_report)
    right.add_child(copy_button)
    var close_button := Button.new()
    close_button.text = "VOLVER A PARTIDA"
    close_button.pressed.connect(queue_free)
    right.add_child(close_button)

    set_process(true)
    call_deferred("start_benchmark")

func _seed_tanks(requested: int, teams: int = 2) -> int:
    var terrain: Array = board.state.get("terrain",[])
    var candidate_cells: Array[Vector2i] = []
    for y in range(terrain.size()):
        for x in range(terrain[y].size()):
            if not str(terrain[y][x]) in ["water","mountain"]:
                candidate_cells.append(Vector2i(x,y))
    var units: Array = []
    var total: int = mini(requested,candidate_cells.size())
    # Sample the WHOLE battlefield, not the first rows: meaningful viewport
    # occupancy near the central camera and no duplicate surface positions.
    for i in range(total):
        var index: int = mini(candidate_cells.size()-1,
            int(floor((float(i)+0.5)*float(candidate_cells.size())/float(total))))
        var tank: Dictionary = Roles.make_unit(
            "QA_TANK_%03d" % i,i%2,candidate_cells[index],"tank")
        if not tank.is_empty():
            # Only visual team IDs 2..7. Not a legal 8-player combat session.
            tank["faction"] = i%teams
            units.append(tank)
    board.state["units"] = units
    return units.size()

func _seed_visual_sites(requested: int, teams: int) -> int:
    if teams <= 2:
        return board.state.get("economy",{}).get("sites",[]).size()
    var terrain: Array = board.state.get("terrain",[])
    var eligible: Array[Vector2i] = []
    for y in range(terrain.size()):
        for x in range(terrain[y].size()):
            if str(terrain[y][x]) not in ["water","mountain"]:
                eligible.append(Vector2i(x,y))
    var positions: Array[Vector2i] = []
    var middle := Vector2i(int(terrain[0].size()/2),int(terrain.size()/2))
    # Eight real baked HQ textures in one central visual test scene.
    for offset in [Vector2i(-6,-4),Vector2i(0,-6),Vector2i(6,-4),
            Vector2i(7,0),Vector2i(5,5),Vector2i(0,7),
            Vector2i(-6,5),Vector2i(-7,0)]:
        if eligible.is_empty():
            break
        var goal: Vector2i = middle+offset
        var best_index := 0
        var best_dist := 100000000
        for j in range(eligible.size()):
            var point: Vector2i = eligible[j]
            var d: int = abs(point.x-goal.x)+abs(point.y-goal.y)
            if d < best_dist:
                best_dist = d
                best_index = j
        positions.append(eligible[best_index])
        eligible.remove_at(best_index)
    var sites_total: int = mini(requested,positions.size()+eligible.size())
    while positions.size() < sites_total and not eligible.is_empty():
        var pick: int = int(floor(float(eligible.size())*0.55))
        positions.append(eligible[pick])
        eligible.remove_at(pick)
    var kinds := ["city","factory","armor_plant","artillery_depot",
        "drone_center","airbase","shipyard"]
    var markers: Array = []
    for i in range(positions.size()):
        markers.append({
            "pos":positions[i],
            "owner":i%teams,
            "kind":"city" if i < teams else kinds[i%kinds.size()],
            "visual_command_city":i < teams,
            "owner_known":true,
            "status":"city" if i < teams else "unknown",
            "income":0,
            "caption":"",
            "capture_pending":false
        })
    # Isolated display markers; never rewrite the authoritative economy.
    board.state["__qa_visual_eight_sides"] = true
    board.state["__qa_site_markers"] = markers
    return markers.size()

func start_benchmark() -> void:
    if running or board == null or board.size.x <= 0.0:
        return
    results.clear()
    completed = false
    running = true
    _case_index = -1
    _result_text = ""
    start_button.disabled = true
    _next_case()

func _next_case() -> void:
    _case_index += 1
    if _case_index >= CASES.size():
        _finish()
        return
    var config: Dictionary = CASES[_case_index]
    _seconds = 0.0
    _effect_seconds = 0.0
    _samples.clear()
    _peak_mem_mb = 0.0
    # Isolated test board: never touch the actual player's scene or autosave.
    board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,false,true,true,true,true,
        0,SEED,config["dims"],{},str(config["weather"]))
    board.set_isometric(true)
    board.set_battery_saver(bool(config["saver"]))
    board.iso_zoom = float(config["zoom"])
    _actual_teams = int(config.get("teams",2))
    _actual_tanks = _seed_tanks(int(config["tanks"]),_actual_teams)
    _actual_sites = _seed_visual_sites(int(config.get("sites",0)),_actual_teams)
    board.focus_iso_cell(config["focus"])
    board._site_overlay_key = -1
    board.selected_id = ""
    board.combat_effects.clear()
    board.motion_effects.clear()
    status_label.text = "%d/%d · %s\n%d equipos | %d tanques | %d edificios | %s" % [
        _case_index+1,CASES.size(),config["name"],_actual_teams,
        _actual_tanks,_actual_sites,config["weather"]]
    board.queue_redraw()
    _last_stats = {}

func _fake_combat(count: int) -> void:
    board.combat_effects.clear()
    board.motion_effects.clear()
    var units: Array = board.state.get("units",[])
    if units.size() < 2 or count <= 0:
        return
    for i in range(mini(count,units.size()-1)):
        var origin: Vector2i = units[(i*7)%units.size()]["pos"]
        var target: Vector2i = units[(i*7+1)%units.size()]["pos"]
        board.combat_effects.append({
            "origin":origin, "target":target, "attacker_role":"tank",
            "defender_role":"tank", "damage":3, "counter_damage":1,
            "destroyed":i%4==0, "elapsed":0.0
        })
        if i < 12:
            board.motion_effects.append({
                "id":units[(i*7)%units.size()]["id"],
                "from":origin+Vector2i(-1,0), "to":origin, "elapsed":0.0
            })

func _process(delta: float) -> void:
    if not running or board == null:
        return
    var dt: float = maxf(0.0,delta)
    _seconds += dt
    _effect_seconds += dt
    var config: Dictionary = CASES[_case_index]
    if _effect_seconds >= 0.50:
        _effect_seconds = 0.0
        _fake_combat(int(config["effects"]))
    # A deliberately pessimistic every-frame redraw. The normal game already
    # throttles ambience, so passing here leaves additional real-world margin.
    board.queue_redraw()
    if _seconds < _warmup_seconds:
        return
    if dt > 0.0 and dt < 1.0:
        _samples.append(dt*1000.0)
    _peak_mem_mb = maxf(_peak_mem_mb,
        float(Performance.get_monitor(Performance.MEMORY_STATIC))/1048576.0)
    _last_stats = Renderer.last_frame_stats.duplicate(true)
    if _seconds >= _warmup_seconds + _measure_seconds:
        _record_case()
        _next_case()

func _record_case() -> void:
    var samples: Array[float] = _samples.duplicate()
    samples.sort()
    var avg_ms := 0.0
    var slow := 0
    for ms in samples:
        avg_ms += ms
        if ms > 33.333:
            slow += 1
    avg_ms = avg_ms/maxf(1.0,float(samples.size()))
    var p95_ms: float = samples[clampi(int(ceil(float(samples.size())*0.95))-1,0,
        maxi(0,samples.size()-1))] if not samples.is_empty() else 0.0
    var cfg: Dictionary = CASES[_case_index]
    var dims: Vector2i = cfg["dims"]
    var hw: float = IsoTransform.half_width(board.size,float(cfg["zoom"]),dims)
    var bounds: Rect2i = VisualBudget.visible_grid_bounds(board.size,
        float(cfg["zoom"]),board.iso_pan,dims)
    var hq_on_screen := false
    if HQ.prefer(hw,bool(cfg["saver"])):
        var markers: Array = (board.state.get("__qa_site_markers",[])
            if bool(board.state.get("__qa_visual_eight_sides",false))
            else SiteData.snapshots(board.state))
        for site in markers:
            if bool(site.get("visual_command_city",false)) and bounds.has_point(site["pos"]):
                hq_on_screen = true
                break
    var result := {
        "case":str(cfg["name"]), "map":"%dx%d" % [dims.x,dims.y],
        "requested_tanks":int(cfg["tanks"]),"actual_tanks":_actual_tanks,
        "visual_factions":_actual_teams,
        "requested_sites":int(cfg.get("sites",0)),"actual_sites":_actual_sites,
        "sites_drawn":int(_last_stats.get("sites_drawn",0)),
        "units_sorted":int(_last_stats.get("units_sorted",0)),
        "weather":str(cfg["weather"]),"battery_saver":bool(cfg["saver"]),
        "effects":int(cfg["effects"]),"samples":samples.size(),
        "fps_avg":snappedf(1000.0/avg_ms,0.1) if avg_ms>0.0 else 0.0,
        "frame_p95_ms":snappedf(p95_ms,0.01),
        "frames_over_33ms_percent":snappedf(100.0*float(slow)/maxf(1.0,float(samples.size())),0.1),
        "max_static_memory_mb":snappedf(_peak_mem_mb,0.1),
        "tiles_drawn":int(_last_stats.get("tiles_drawn",0)),
        "units_drawn":int(_last_stats.get("units_drawn",0)),
        "hq_baked_visible":hq_on_screen
    }
    results.append(result)
    var row: String = "%s\n%d equipos, %d/%d tanques, %d/%d edificios visibles · %.1f FPS · p95 %.1f ms · %.1f%% cuadros >33 ms · %.1f MB\n" % [
        result["case"],result["visual_factions"],result["units_drawn"],
        result["actual_tanks"],result["sites_drawn"],result["actual_sites"],
        result["fps_avg"],result["frame_p95_ms"],
        result["frames_over_33ms_percent"],result["max_static_memory_mb"]]
    _result_text += row + "\n"
    output_label.text = _result_text
    print("TARVOKA_STRESS_CASE " + JSON.stringify(result))

func _finish() -> void:
    running = false
    completed = true
    start_button.disabled = false
    status_label.text = "Prueba finalizada · %d escenarios" % results.size()
    _result_text += "Resultados de cuadros completos; no son tiempos GPU aislados.\n"
    _result_text += "Cargas sintéticas: tanque técnico actual + HQ 3D precalculado.\n"
    _result_text += "Los 8 equipos son visuales: no hay red, turnos ni niebla por jugador.\n"
    _result_text += "El modo ahorro y la niebla de guerra pueden cambiar la carga.\n"
    output_label.text = _result_text
    var report: Dictionary = {
        "device_os":OS.get_name(),
        "display_server":DisplayServer.get_name(),
        "screen":str(get_viewport().get_visible_rect().size),
        "renderer":"Godot Compatibility",
        "type":"visual_stress_8_visual_teams_not_multiplayer_not_gpu_timer",
        "cases":results
    }
    var file := FileAccess.open("user://tarvoka_stress_report.json",FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report,"\t"))
        file.close()
    benchmark_completed.emit(results)
    print("TARVOKA_STRESS_DONE " + JSON.stringify(report))

func report_text() -> String:
    return _result_text

func _copy_report() -> void:
    if not _result_text.is_empty():
        DisplayServer.clipboard_set("TARVOKA | %s\n%s" % [OS.get_name(),_result_text])
