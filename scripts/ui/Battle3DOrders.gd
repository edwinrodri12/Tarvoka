extends RefCounted
class_name TarvokaBattle3DOrders

# Single, guarded bridge to TouchBoard's EXISTING confirmation and combat
# lifecycle. Never write directly to BattleSession or save dictionaries.
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Rules = preload("res://scripts/core/Rules.gd")

static func can_control(board: Control) -> bool:
    if board == null:
        return false
    var state: Variant = board.get("state")
    if not state is Dictionary or not Rules.valid_terrain(state.get("terrain",[])):
        return false
    # The overlay must NEVER use legacy double-tap's direct commit mode.
    if not bool(board.get("require_order_confirmation")):
        return false
    if bool(board.get("ai_enabled")) and int(state.get("faction",-1)) != 0:
        return false
    return int(state.get("faction",-1)) == 0 and int(state.get("winner",-1)) == -1

static func visible_friends(state: Dictionary, cell: Vector2i) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    if not Rules.inside(cell,state.get("terrain",[])):
        return options
    var visible: Dictionary = Visibility.visible_cells(state,0) if Visibility.enabled(state) else {}
    if Visibility.enabled(state) and not visible.has(cell):
        return options
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        if int(unit.get("faction",-1)) == 0 and unit.get("pos") == cell:
            options.append({"id":str(unit.get("id","")),"layer":Domains.layer(unit),
                "acted":bool(unit.get("acted",false))})
    options.sort_custom(func(a,b):
        if a["layer"] != b["layer"]:
            return a["layer"] == "surface"
        return str(a["id"]) < str(b["id"])
    )
    return options

static func next_friendly(state: Dictionary, cell: Vector2i, current: String) -> String:
    var options: Array[Dictionary] = visible_friends(state,cell)
    if options.is_empty():
        return ""
    for i in range(options.size()):
        if str(options[i]["id"]) == current:
            return str(options[(i+1)%options.size()]["id"])
    return str(options[0]["id"])

static func legal_intent(state: Dictionary, unit_id: String,
        cell: Vector2i) -> Dictionary:
    if unit_id.is_empty() or int(state.get("faction",-1)) != 0:
        return {}
    if not Rules.inside(cell,state.get("terrain",[])):
        return {}
    var selected: Dictionary = {}
    for unit in state.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == unit_id:
            selected = unit
            break
    if selected.is_empty() or int(selected.get("faction",-1)) != 0 or int(selected.get("hp",0)) <= 0:
        return {}
    var visible: Dictionary = Visibility.visible_cells(state,0) if Visibility.enabled(state) else {}
    if Visibility.enabled(state) and not visible.has(cell):
        return {}
    var hints: Dictionary = Hints.for_unit(state,unit_id)
    # Attack takes priority even when friendly surface/air units share the
    # same coordinate as the hostile target of the selected weapon.
    if hints["attacks"].has(cell):
        var enemy_id: String = str(hints["attacks"][cell].get("id",""))
        if not enemy_id.is_empty():
            return {"kind":"attack","unit_id":unit_id,"cell":cell,
                "target_id":enemy_id,"details":hints["attacks"][cell]}
    if hints["moves"].has(cell):
        return {"kind":"move","unit_id":unit_id,"cell":cell,
            "target_id":"","cost":int(hints["moves"][cell])}
    return {}

static func select(board: Control, unit_id: String) -> bool:
    if not can_control(board) or unit_id.is_empty():
        return false
    var state: Dictionary = board.get("state")
    var found := false
    for unit in state.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == unit_id and \
                int(unit.get("faction",-1)) == 0 and int(unit.get("hp",0)) > 0:
            found = true
            break
    if not found:
        return false
    # UI selection is not a serialized battle action.
    board.set("selected_id",unit_id)
    board.set("inspected_enemy_id","")
    board.set("message","Unidad %s seleccionada en mapa 3D." % unit_id)
    board.queue_redraw()
    return true

static func request_preview(board: Control, intent: Dictionary) -> Dictionary:
    if not can_control(board):
        return {}
    var state: Dictionary = board.get("state")
    var unit_id: String = str(intent.get("unit_id",""))
    var cell: Variant = intent.get("cell",null)
    if not cell is Vector2i or str(board.get("selected_id")) != unit_id:
        return {}
    var safe: Dictionary = legal_intent(state,unit_id,cell)
    if safe.is_empty() or safe.get("kind") != intent.get("kind") or \
            safe.get("target_id") != intent.get("target_id"):
        return {}
    var before: Dictionary = state.duplicate(true)
    # TouchBoard's double tap would otherwise EXECUTE a matching preview.
    # Explicit Confirm is the only authorizing action in the 3D overlay.
    var pending: Dictionary = board.get("pending_order")
    pending.clear()
    var target: Dictionary = {}
    if safe["kind"] == "attack":
        for enemy in state.get("units",[]):
            if enemy is Dictionary and str(enemy.get("id","")) == safe["target_id"] and \
                    int(enemy.get("faction",-1)) != 0 and enemy.get("pos") == cell:
                target = enemy
                break
        if target.is_empty():
            return {}
    board.call("_request_order",cell,target)
    var expected: Dictionary = {
        "kind":safe["kind"],"unit_id":unit_id,"cell":cell,
        "target_id":safe["target_id"]}
    var quoted: Dictionary = board.get("pending_order")
    if quoted != expected or board.get("state") != before:
        # Failed/stale preview is never kept as a queued order.
        if quoted == expected:
            quoted.clear()
        return {}
    board.queue_redraw()
    return {"valid":true,"order":expected,"state":before,
        "message":str(board.get("message"))}

static func cancel_preview(board: Control, quote: Dictionary) -> void:
    if board == null or quote.is_empty():
        return
    var pending: Dictionary = board.get("pending_order")
    if pending == quote.get("order",{}):
        pending.clear()
        board.queue_redraw()

static func confirm(board: Control, quote: Dictionary) -> bool:
    if not can_control(board) or not bool(quote.get("valid",false)):
        return false
    var pending: Dictionary = board.get("pending_order")
    var expected: Dictionary = quote.get("order",{})
    if expected.is_empty() or pending != expected:
        return false
    if str(board.get("selected_id")) != str(expected.get("unit_id","")) or \
            board.get("state") != quote.get("state",{}):
        cancel_preview(board,quote)
        return false
    # Board.confirm_pending_order() rechecks fresh TacticalHints and commits
    # through BattleSession, updates VFX and autosave exactly as the 2D HUD.
    return bool(board.call("confirm_pending_order"))
