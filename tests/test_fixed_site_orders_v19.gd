extends SceneTree

# New v19 behavior must be isolated from shipping core and old saves.
const Orders = preload("res://scripts/experiments/FixedSiteOrdersV19.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Camps = preload("res://scripts/experiments/SpecialistCampsV17.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    for size in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        _camp_turns_and_saves(size)
    _capture_card()
    print("PASS fixed site orders v19: 3 map sizes, 2 specialist camps, real credits/turns, HUD purchase cards, two-turn capture, strict v19 saves and old SaveCodec unchanged")
    quit(0)

static func _free(terrain: Array, sites: Array, excluded: Array) -> Vector2i:
    var dims: Vector2i = Rules.map_size(terrain)
    for y in range(1,dims.y-1):
        for x in range(1,dims.x-1):
            var cell := Vector2i(x,y)
            if cell in excluded or str(terrain[y][x]) not in ["plain","road","forest"]:
                continue
            var occupied := false
            for site in sites:
                if site["pos"] == cell or site.get("capture_pos",site["pos"]) == cell:
                    occupied = true
            if not occupied:
                return cell
    return Vector2i(-1,-1)

static func _find_unit(units: Array, uid: String) -> Dictionary:
    for unit in units:
        if str(unit.get("id","")) == uid:
            return unit
    return {}

static func _camp_turns_and_saves(size: Vector2i) -> void:
    var terrain: Array = Scenarios.terrain(0,size)
    var layout: Dictionary = Sites.layout(terrain)
    assert(layout.get("valid",false))
    var p0: Vector2i = _free(terrain,layout["sites"],[])
    var p1: Vector2i = _free(terrain,layout["sites"],[p0])
    var p2: Vector2i = _free(terrain,layout["sites"],[p0,p1])
    assert(p0.x >= 0 and p1.x >= 0 and p2.x >= 0)
    var army: Array = [
        Roles.make_unit("SC",0,p0,"scout"),
        Roles.make_unit("EN",0,p1,"engineer"),
        Roles.make_unit("FOE",1,p2,"line")
    ]
    var session: Dictionary = Orders.start(0,size,0,army)
    assert(session.get("valid",false))
    assert(session["camps"].is_empty())
    var initial: int = int(session["world"]["state"]["economy"]["credits"][0])
    var choices: Array = Orders.camp_choices(session,"SC")
    assert(choices.size() == 4)
    assert(bool(choices[1]["available"]))
    assert(not bool(choices[0]["available"]))
    assert(not bool(choices[2]["available"]))
    assert(not bool(choices[3]["available"]))
    assert(not Orders.build_camp(session,"SC","supply").get("valid",false))
    assert(not Orders.build_camp(session,"SC","medical").get("valid",false))
    assert(not Orders.build_camp(session,"SC","factory").get("valid",false))
    assert(not Orders.build_camp(session,"EN","recon").get("valid",false))
    var recon: Dictionary = Orders.build_camp(session,"SC","recon")
    assert(recon.get("valid",false))
    session = recon["session"]
    assert(int(recon["cost"]) == 100)
    assert(session["camps"].size() == 1)
    assert(bool(_find_unit(session["world"]["state"]["units"],"SC")["acted"]))
    assert(int(session["world"]["state"]["economy"]["credits"][0]) == initial-100)
    var camp_card: Dictionary = Orders.site_card(session,p0)
    assert(camp_card["type"] == "camp" and not camp_card["produces"] and camp_card["income"] == 0)
    assert(not Orders.build_camp(session,"SC","recon").get("valid",false))
    var defense: Dictionary = Orders.build_camp(session,"EN","defense")
    assert(defense.get("valid",false))
    session = defense["session"]
    assert(int(defense["cost"]) == 130)
    assert(int(session["world"]["state"]["economy"]["credits"][0]) == initial-230)
    assert(session["camps"].size() == 2)
    assert(not Orders.build_camp(session,"EN","defense").get("valid",false))
    assert(not Save.encode(session["world"]["state"]).is_empty())
    var raw: String = Orders.encode(session)
    assert(not raw.is_empty())
    var reconstructed: Dictionary = Orders.decode(raw)
    assert(reconstructed == session)
    var data: Dictionary = JSON.parse_string(raw)
    data["version"] = 18
    assert(Orders.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["camps"][0]["x"] = 999
    assert(Orders.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["camps"][0]["kind"] = "shipyard"
    assert(Orders.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["camps"].append(data["camps"][0].duplicate(true))
    assert(Orders.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["world"] = "broken old game"
    assert(Orders.decode(JSON.stringify(data)).is_empty())
    assert(Orders.decode(Save.encode(session["world"]["state"])).is_empty())
    # Turns and money remain authoritative and camps survive untouched.
    var forward: Dictionary = Orders.end_turn(session)
    assert(forward.get("valid",false))
    var enemy: Dictionary = Orders.end_turn(forward["session"])
    assert(enemy.get("valid",false))
    var later: Dictionary = enemy["session"]
    assert(later["camps"] == session["camps"])
    assert(int(later["world"]["state"]["faction"]) == 0)
    assert(not bool(_find_unit(later["world"]["state"]["units"],"SC")["acted"]))
    assert(Orders.decode(Orders.encode(later)) == later)
    # Every existing fixed producer remains fixed, and its catalog is read-only.
    var own: Dictionary = {}
    for site in later["world"]["layout"]["sites"]:
        if str(site["kind"]) != "city" and int(site["owner"]) == 0:
            own = site
            break
    assert(not own.is_empty())
    var view: Dictionary = Orders.site_card(later,own["pos"])
    assert(view["type"] == "fixed_site" and view["can_produce"])
    assert(view["choices"].size() > 0)
    assert(Orders.site_card(later,Vector2i(-1,-1)).is_empty())
    assert(later["world"]["layout"]["producers"] == layout["producers"])
    print("SITE_ORDERS size=%s recon=100 defense=130 credited=%d camp_cap=%d save_roundtrip=true" % [
        str(size),int(later["world"]["state"]["economy"]["credits"][0]),Camps.max_per_side(terrain)
    ])

static func _capture_card() -> void:
    var size := Vector2i(24,18)
    var terrain: Array = Scenarios.terrain(0,size)
    var layout: Dictionary = Sites.layout(terrain)
    var target: Dictionary = {}
    for site in layout["sites"]:
        if str(site["kind"]) != "city" and int(site["owner"]) == -1 and str(site["kind"]) != "shipyard":
            target = site
            break
    assert(not target.is_empty())
    var enemy: Vector2i = _free(terrain,layout["sites"],[target["pos"]])
    var army: Array = [
        Roles.make_unit("CAP",0,target["pos"],"scout"),
        Roles.make_unit("FOE",1,enemy,"line")
    ]
    var session: Dictionary = Orders.start(0,size,0,army)
    assert(session.get("valid",false))
    var first: Dictionary = Orders.site_card(session,target["pos"])
    assert(first["progress"] == 0 and not first["can_produce"])
    assert(not Orders.purchase(session,target["pos"],"apc").get("valid",false))
    var ending: Dictionary = Orders.end_turn(session)
    assert(ending.get("valid",false))
    session = ending["session"]
    var progress: Dictionary = Orders.site_card(session,target["pos"])
    assert(progress["progress"] == 1 and progress["hold_side"] == 0)
    var snap: String = Orders.encode(session)
    assert(Orders.decode(snap)["world"]["producer_holds"] == session["world"]["producer_holds"])
    var response: Dictionary = Orders.end_turn(session)
    assert(response.get("valid",false))
    var completing: Dictionary = Orders.end_turn(response["session"])
    assert(completing.get("valid",false))
    session = completing["session"]
    assert(Orders.site_card(session,target["pos"])["owner"] == 0)
    assert(Orders.site_card(session,target["pos"])["progress"] == 0)
    # Income and structures cannot be produced from an invented site.
    assert(not Orders.purchase(session,Vector2i(-1,-1),"apc").get("valid",false))
    assert(Economy.valid(session["world"]["state"]["economy"],session["world"]["state"]["terrain"]))
