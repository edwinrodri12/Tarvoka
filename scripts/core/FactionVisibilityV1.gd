extends RefCounted
class_name TarvokaFactionVisibilityV1

# Experimental 2-8-faction fog helper, NOT wired into live BattleSession,
# SaveCodec, AI or multiplayer transport. No existing save schema changes.
# Each observation is fail-closed and never returns raw secret state keys.
const Rules=preload("res://scripts/core/Rules.gd")
const Legacy=preload("res://scripts/core/Visibility.gd")
const TurnOrder=preload("res://scripts/core/FactionTurnOrderV1.gd")

static func visible_cells(state: Dictionary,faction: int,roster: Array) -> Dictionary:
    var result: Dictionary={}
    if not TurnOrder.valid(roster) or faction not in roster or (
            not state.get("units") is Array):
        return result
    var terrain: Array=state.get("terrain",[])
    if not Rules.valid_terrain(terrain):
        return result
    var dims: Vector2i=Rules.map_size(terrain)
    if not bool(state.get("fog_enabled",false)):
        for y in range(dims.y):
            for x in range(dims.x):
                result[Vector2i(x,y)]=true
        return result
    for unit in state["units"]:
        if not unit is Dictionary or int(unit.get("hp",0))<=0 or (
                int(unit.get("faction",-1))!=faction):
            continue
        var center=unit.get("pos",null)
        if not center is Vector2i or not Rules.inside(center,terrain):
            continue
        var radius: int=clampi(int(unit.get("vision",Legacy.DEFAULT_VISION)),
            1,Legacy.MAX_VISION)
        for y in range(maxi(0,center.y-radius),mini(dims.y-1,
                center.y+radius)+1):
            for x in range(maxi(0,center.x-radius),mini(dims.x-1,
                    center.x+radius)+1):
                var cell:=Vector2i(x,y)
                if absi(cell.x-center.x)+absi(cell.y-center.y)<=radius and (
                        Legacy._clear_los(terrain,center,cell)):
                    result[cell]=true
    return result

static func explored_cells(state: Dictionary,faction: int,roster: Array) -> Dictionary:
    var result: Dictionary=visible_cells(state,faction,roster)
    if not TurnOrder.valid(roster) or faction not in roster or (
            not bool(state.get("fog_enabled",false))):
        return result
    var history=state.get("explored",{})
    if not history is Dictionary:
        return result
    var positions=history.get(str(faction),[])
    if not positions is Array:
        return result
    for cell in positions:
        if cell is Vector2i and Rules.inside(cell,state.get("terrain",[])):
            result[cell]=true
    return result

static func update_exploration(state: Dictionary,roster: Array) -> Dictionary:
    if not TurnOrder.valid(roster) or not Rules.valid_terrain(
            state.get("terrain",[])) or not state.get("units") is Array:
        return {}
    var copy: Dictionary=state.duplicate(true)
    if not bool(copy.get("fog_enabled",false)):
        return copy
    var dims: Vector2i=Rules.map_size(copy["terrain"])
    var history: Dictionary={}
    for faction in roster:
        var found: Dictionary=explored_cells(copy,int(faction),roster)
        var ordered: Array[Vector2i]=[]
        for y in range(dims.y):
            for x in range(dims.x):
                var cell:=Vector2i(x,y)
                if found.has(cell):
                    ordered.append(cell)
        history[str(faction)]=ordered
    copy["explored"]=history
    return copy

static func observed_state(state: Dictionary,faction: int,roster: Array) -> Dictionary:
    if not TurnOrder.valid(roster) or faction not in roster or (
            not Rules.valid_terrain(state.get("terrain",[]))) or (
            not state.get("units") is Array):
        return {}
    var fog: bool=bool(state.get("fog_enabled",false))
    var visible: Dictionary=visible_cells(state,faction,roster)
    var known: Dictionary=explored_cells(state,faction,roster)
    var terrain: Array=state["terrain"].duplicate(true)
    var dims: Vector2i=Rules.map_size(terrain)
    if fog:
        for y in range(dims.y):
            for x in range(dims.x):
                if not known.has(Vector2i(x,y)):
                    # Identical to legacy AI: unknown terrain is impassable.
                    terrain[y][x]="water"
    var observed: Dictionary={
        "faction":faction,
        "fog_enabled":fog,
        "terrain":terrain,
        "units":[],
        "winner":int(state.get("winner",-1))
    }
    # A deterministic map seed would let a client reconstruct every
    # unexplored tile. Only expose it when fog is OFF.
    if state.has("map_seed") and not fog:
        observed["map_seed"]=state["map_seed"]
    for unit in state["units"]:
        if not unit is Dictionary or int(unit.get("hp",0))<=0:
            continue
        if int(unit.get("faction",-1))==faction or (
                not fog) or visible.has(unit.get("pos",null)):
            observed["units"].append(unit.duplicate(true))
    var largest_faction: int=0
    for participant in roster:
        largest_faction=maxi(largest_faction,int(participant))
    # Build STRICT whitelists. Copying a future economy/control Dictionary
    # wholesale could accidentally expose secret orders or participant data.
    if state.get("economy") is Dictionary:
        var economy: Dictionary=state["economy"]
        var credits=economy.get("credits",null)
        if credits is Array and credits.size()>largest_faction and (
                credits.size()<=TurnOrder.MAX_FACTIONS):
            var private_credits: Array=credits.duplicate(true)
            for side in range(private_credits.size()):
                if side!=faction:
                    private_credits[side]=-1
            var safe_sites: Array=[]
            if economy.get("sites") is Array:
                for site in economy["sites"]:
                    if not site is Dictionary or not site.get("pos") is Vector2i:
                        continue
                    var pos: Vector2i=site["pos"]
                    var owner: int=int(site.get("owner",-1))
                    var concealed: bool=fog and not visible.has(pos) and owner!=faction
                    var public_site: Dictionary={
                        "pos":pos,
                        "kind":str(site.get("kind","")),
                        "owner":-2 if concealed else owner
                    }
                    if site.has("produced_turn"):
                        public_site["produced_turn"]=(
                            -1 if concealed else int(site["produced_turn"]))
                    safe_sites.append(public_site)
            observed["economy"]={
                "credits":private_credits,"sites":safe_sites
            }
    if state.get("control") is Dictionary:
        var control: Dictionary=state["control"]
        var scores=control.get("scores",null)
        if scores is Array and scores.size()>largest_faction and (
                scores.size()<=TurnOrder.MAX_FACTIONS):
            var private_scores: Array=scores.duplicate(true)
            for side in range(private_scores.size()):
                if side!=faction:
                    private_scores[side]=-1
            var safe_nodes: Array=[]
            if control.get("nodes") is Array:
                for relay in control["nodes"]:
                    if not relay is Dictionary or not relay.get("pos") is Vector2i:
                        continue
                    var location: Vector2i=relay["pos"]
                    var owner: int=int(relay.get("owner",-1))
                    var concealed: bool=fog and not visible.has(location) and (
                        owner!=faction)
                    safe_nodes.append({
                        "pos":location,
                        "owner":-2 if concealed else owner
                    })
            observed["control"]={
                "scores":private_scores,"nodes":safe_nodes,
                "target":int(control.get("target",0))
            }
    # No default pass-through of any other fields: contacts, full exploration,
    # hidden orders, secrets, auth tokens, etc. are NEVER returned.
    return observed
