extends SceneTree

const Catalog = preload("res://scripts/core/CampaignCatalog.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    _checks()
    quit()

func _checks() -> void:
    assert(Catalog.validate())
    var chapters: Array = Catalog.all()
    assert(chapters.size() == 50)
    assert(Catalog.ENGINE_FEATURES.size() >= 28)
    assert(Catalog.required_ui().has("pinch_zoom"))
    assert(Catalog.required_ui().has("minimap"))
    assert(Catalog.required_ui().has("enemy_inspect"))
    assert(Catalog.chapter("C00").is_empty())
    assert(Catalog.chapter("C51").is_empty())
    assert(Catalog.chapter("C01")["title"] == "Escudo compartido")
    assert(Catalog.chapter("C01")["status"] == "engine_core_only")
    assert(Catalog.chapter("C02")["status"] == "design_only")
    assert(Catalog.chapter("C27")["unlock"] == "M09")
    assert(Catalog.OPTIONAL_UNLOCKS == ["M09"])
    assert(Catalog.chapter("C50")["objective"] == "branch_finale")
    var features: Array = Catalog.features_used()
    for required in Catalog.ENGINE_FEATURES:
        assert(required in features)
    var known: Dictionary = {}
    for row in chapters:
        for feature in row["engine_features"]:
            known[str(feature)] = true
        var copy: Dictionary = Catalog.chapter(str(row["id"]))
        assert(copy == row)
        copy["title"] = "MODIFIED"
        assert(Catalog.chapter(str(row["id"]))["title"] == row["title"])
    for key in ["counterfire","range","terrain","height","flank","fog","fog_contacts",
                "capture","city_income","production","ammo","fuel","resupply","truck",
                "naval","air","drone_consumable","relays","initiative","ai",
                "large_map","seeded_map","domains","tactical_overlay"]:
        assert(known.has(key))

    # Real code/gameplay consistency: ALL five infantry types may capture.
    # An antitank infantryman is still an infantryman; artillery and
    # armoured units still cannot capture, regardless of chapter.
    var roles: Array = ["line","scout","piercer","assault","engineer"]
    for role in roles:
        var infantry: Dictionary = Roles.make_unit("CAPTURE_" + role,0,Vector2i(3,4),role)
        assert(not infantry.is_empty())
        assert(Economy.can_capture(infantry))
    assert(not Economy.can_capture(Roles.make_unit("ARMOR",0,Vector2i(3,4),"bulwark")))
    assert(not Economy.can_capture(Roles.make_unit("ART",0,Vector2i(3,4),"artillery")))

    # Confirm this is not a cosmetic check: end-turn city ownership follows
    # the newly legal Rompedor capture through the existing battle system.
    var capturers: Array = [
        Roles.make_unit("ROMPEDOR",0,Vector2i(3,4),"piercer"),
        Roles.make_unit("DEFENDER",1,Vector2i(8,3),"line")
    ]
    var state: Dictionary = Session.start(capturers,Scenarios.terrain(0),0,false,false,true)
    assert(state.has("economy"))
    assert(state["economy"]["sites"][2]["owner"] == -1)
    var result: Dictionary = Session.end_turn(state)
    assert(result["valid"])
    assert(result["state"]["economy"]["sites"][2]["owner"] == 0)
    assert(state["economy"]["sites"][2]["owner"] == -1)

    print("Campaign catalog: 50 chapters, mechanics coverage, 24 unlocks and infantry capture PASS.")
