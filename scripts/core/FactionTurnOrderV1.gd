extends RefCounted
class_name TarvokaFactionTurnOrderV1

# Future multiplayer turn scheduling: PURE HELPERS, deliberately not wired
# into BattleSession, SaveCodec or networking yet. Existing two-faction
# sessions and saves remain authoritative until all eight-faction systems
# (fog, economy, relays, AI, victory, persistence) are generalized together.
const MIN_FACTIONS: int=2
const MAX_FACTIONS: int=8

static func valid(roster: Array) -> bool:
    if roster.size()<MIN_FACTIONS or roster.size()>MAX_FACTIONS:
        return false
    var seen: Dictionary={}
    for value in roster:
        if not value is int:
            return false
        var faction: int=int(value)
        if faction<0 or faction>=MAX_FACTIONS or seen.has(faction):
            return false
        seen[faction]=true
    return true

static func alive_factions(roster: Array,units: Array) -> Array[int]:
    var live: Array[int]=[]
    if not valid(roster):
        return live
    var present: Dictionary={}
    for unit in units:
        if not unit is Dictionary or int(unit.get("hp",0))<=0:
            continue
        var faction: int=int(unit.get("faction",-1))
        if faction in roster:
            present[faction]=true
    for faction in roster:
        if present.has(int(faction)):
            live.append(int(faction))
    return live

static func winner(roster: Array,units: Array) -> int:
    var alive: Array[int]=alive_factions(roster,units)
    return alive[0] if alive.size()==1 else -1

static func next_faction(roster: Array,current: int,units: Array) -> int:
    if not valid(roster) or not current in roster:
        return -1
    var alive: Array[int]=alive_factions(roster,units)
    if alive.size()<=1:
        # The match is finished or has no living armies.
        return -1
    var offset: int=roster.find(current)
    for step in range(1,roster.size()+1):
        var candidate: int=int(roster[(offset+step)%roster.size()])
        if candidate in alive and candidate!=current:
            return candidate
    return -1
