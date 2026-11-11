extends SceneTree

const Hints = preload("res://scripts/core/TacticalHints.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var units: Array = [
        {"id":"A", "faction":0, "hp":10, "pos":Vector2i(2,2), "move_points":3,
         "attack":5, "defense":0, "cover":1, "acted":false},
        {"id":"X", "faction":1, "hp":8, "pos":Vector2i(8,2), "move_points":3,
         "attack":4, "defense":0, "cover":0, "acted":false}
    ]
    var woods: Dictionary = Session.start(units, Scenarios.terrain(1))
    var original: Dictionary = woods.duplicate(true)
    var forest: String = Hints.unit_summary(woods, "A")
    assert(forest.contains("Vida 10"))
    assert(forest.contains("Movimiento 3"))
    assert(forest.contains("Rol: Soldado | Terreno: Bosque (entrar cuesta 2) | Cobertura unidad: 1"))
    assert(woods == original)

    units[0]["pos"] = Vector2i(4,0)
    var heights: Dictionary = Session.start(units, Scenarios.terrain(1))
    assert(Hints.unit_summary(heights, "A").contains("Terreno: Montana (entrar cuesta 3)"))
    units[0]["pos"] = Vector2i(3,3)
    var roads: Dictionary = Session.start(units, Scenarios.terrain(1))
    assert(Hints.unit_summary(roads, "A").contains("Terreno: Camino (entrar cuesta 1)"))

    # Scout role uses sight capability, not a separate invented class bonus.
    var scouts: Array = [
        {"id":"S", "faction":0, "hp":6, "pos":Vector2i(1,3), "move_points":4,
         "attack":2, "defense":0, "cover":0, "vision":5, "acted":false},
        {"id":"Z", "faction":1, "hp":6, "pos":Vector2i(8,3), "move_points":4,
         "attack":2, "defense":0, "cover":0, "vision":5, "acted":false}
    ]
    var fog: Dictionary = Session.start(scouts, Scenarios.terrain(0), 0, true)
    var before: Dictionary = fog.duplicate(true)
    var own: String = Hints.unit_summary(fog, "S")
    assert(own.contains("Rol: Explorador"))
    assert(own.contains("Vision 5"))
    assert(own.contains("Terreno: Llanura (entrar cuesta 1)"))
    assert(Hints.unit_summary(fog, "Z") == "Unidad no disponible.")
    assert(fog == before)
    # Reversing current faction must also protect the other side's hidden unit.
    fog["faction"] = 1
    assert(Hints.unit_summary(fog, "S") == "Unidad no disponible.")
    assert(Hints.unit_summary(fog, "Z").contains("Rol: Explorador"))

    print("PASS terrain HUD: exact cost/cover, scout role, fog confidentiality and immutability")
    quit(0)
