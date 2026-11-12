extends RefCounted
class_name TarvokaModernArsenal

# New technology already used by contemporary militaries. Immutable base
# catalogue: combat stats and production sites only; complex systems (cargo,
# EW, repairs, ammunition, sonar) need explicit future action implementations.
# The five pre-existing classes remain authoritative in UnitRoles.gd.
# Fields: name, HP, movement, attack, defence, vision, minimum/maximum range,
# domain, target domains, suggested cost, producer, short role.
const ORDER := [
    "assault", "engineer", "apc", "ifv", "tank", "spg",
    "mlrs", "mobile_aa", "sam", "ew", "logistics",
    "uav_recon", "fpv", "loitering", "ucav", "attack_heli",
    "transport_heli", "fighter", "bomber",
    "patrol", "missile_boat", "corvette", "frigate",
    "destroyer", "submarine", "landing_ship", "usv"
]

const PROFILES := {
    "assault":         {"code":"G02", "label":"Asaltante", "symbol":"As", "hp":9, "move_points":3, "attack":5, "defense":0, "vision":3, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":["ground"], "cost":250, "site":"factory", "note":"Infantería urbana; captura."},
    "engineer":        {"code":"G05", "label":"Ingeniero", "symbol":"In", "hp":7, "move_points":2, "attack":2, "defense":0, "vision":3, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":["ground"], "cost":250, "site":"factory", "note":"Captura; reparar requiere sistema adicional."},
    "apc":             {"code":"G07", "label":"Transporte blindado", "symbol":"Tb", "hp":11,"move_points":5, "attack":2, "defense":1, "vision":3, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":["ground"], "cost":300, "site":"armor_plant", "note":"Movilidad blindada; carga pendiente."},
    "ifv":             {"code":"G08", "label":"Vehículo de infantería", "symbol":"Vi", "hp":11,"move_points":4, "attack":5, "defense":1, "vision":4, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":["ground"], "cost":500, "site":"armor_plant", "note":"Apoyo mecanizado; carga pendiente."},
    "tank":            {"code":"G09", "label":"Tanque principal", "symbol":"Tq", "hp":14,"move_points":4, "attack":8, "defense":2, "vision":3, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":["ground"], "cost":750, "site":"armor_plant", "note":"Blindado pesado; antiblindaje lo contrarresta."},
    "spg":             {"code":"G10", "label":"Artillería autopropulsada", "symbol":"Ar", "hp":8, "move_points":3, "attack":7, "defense":0, "vision":3, "attack_min_range":2, "attack_range":4, "domain":"ground", "target_domains":["ground"], "cost":650, "site":"artillery_depot", "note":"Alcance largo; sin disparo adyacente."},
    "mlrs":            {"code":"G12", "label":"Lanzacohetes múltiple", "symbol":"Lc", "hp":7, "move_points":2, "attack":9, "defense":0, "vision":3, "attack_min_range":3, "attack_range":5, "domain":"ground", "target_domains":["ground"], "cost":850, "site":"artillery_depot", "note":"Apoyo distante; recarga pendiente."},
    "mobile_aa":       {"code":"G13", "label":"Antiaéreo móvil", "symbol":"AA", "hp":9, "move_points":3, "attack":6, "defense":1, "vision":5, "attack_min_range":1, "attack_range":3, "domain":"ground", "target_domains":["air"], "cost":500, "site":"artillery_depot", "note":"Contramedida contra drones y helicópteros."},
    "sam":             {"code":"G14", "label":"Batería SAM", "symbol":"SM", "hp":8, "move_points":2, "attack":8, "defense":0, "vision":5, "attack_min_range":2, "attack_range":5, "domain":"ground", "target_domains":["air"], "cost":900, "site":"artillery_depot", "note":"Cobertura aérea de distancia; radar detallado pendiente."},
    "ew":              {"code":"G15", "label":"Guerra electrónica", "symbol":"GE", "hp":7, "move_points":3, "attack":0, "defense":0, "vision":4, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":[], "cost":550, "site":"artillery_depot", "note":"Perturbación no implementada; sin ataque convencional."},
    "logistics":       {"code":"G16", "label":"Vehículo logístico", "symbol":"Lg", "hp":8, "move_points":4, "attack":0, "defense":0, "vision":3, "attack_min_range":1, "attack_range":1, "domain":"ground", "target_domains":[], "cost":300, "site":"factory", "note":"Suministro/reparación pendientes; sin ataque."},
    "uav_recon":       {"code":"A01", "label":"Dron de reconocimiento", "symbol":"DR", "hp":4, "move_points":5, "attack":0, "defense":0, "vision":7, "attack_min_range":1, "attack_range":1, "domain":"air", "target_domains":[], "cost":250, "site":"drone_center", "note":"Visión de reconocimiento; no tiene armas."},
    "fpv":             {"code":"A02", "label":"Dron FPV", "symbol":"FP", "hp":2, "move_points":5, "attack":7, "defense":0, "vision":3, "attack_min_range":1, "attack_range":1, "domain":"air", "target_domains":["ground"], "cost":200, "site":"drone_center", "note":"Munición de un uso: pendiente mecánica consumible."},
    "loitering":       {"code":"A03", "label":"Munición merodeadora", "symbol":"MM", "hp":2, "move_points":4, "attack":8, "defense":0, "vision":4, "attack_min_range":1, "attack_range":2, "domain":"air", "target_domains":["ground"], "cost":350, "site":"drone_center", "note":"Munición de un uso: pendiente mecánica consumible."},
    "ucav":            {"code":"A04", "label":"Dron de combate", "symbol":"DC", "hp":8, "move_points":6, "attack":6, "defense":0, "vision":5, "attack_min_range":1, "attack_range":2, "domain":"air", "target_domains":["ground","naval"], "cost":800, "site":"airbase", "note":"Plataforma reutilizable; rearme pendiente."},
    "attack_heli":     {"code":"A05", "label":"Helicóptero de ataque", "symbol":"HA", "hp":10,"move_points":6, "attack":7, "defense":1, "vision":4, "attack_min_range":1, "attack_range":2, "domain":"air", "target_domains":["ground"], "cost":700, "site":"airbase", "note":"Aterrizaje/rearme pendientes."},
    "transport_heli":  {"code":"A06", "label":"Helicóptero de transporte", "symbol":"HT", "hp":9, "move_points":6, "attack":0, "defense":1, "vision":4, "attack_min_range":1, "attack_range":1, "domain":"air", "target_domains":[], "cost":500, "site":"airbase", "note":"Carga de soldados pendiente; sin armas."},
    "fighter":         {"code":"A07", "label":"Caza multifunción", "symbol":"CZ", "hp":9, "move_points":8, "attack":9, "defense":1, "vision":5, "attack_min_range":1, "attack_range":2, "domain":"air", "target_domains":["air","ground"], "cost":1000, "site":"airbase", "note":"Combate aéreo y terrestre; combustible pendiente."},
    "bomber":          {"code":"A08", "label":"Bombardero táctico", "symbol":"BT", "hp":11,"move_points":6, "attack":10,"defense":1, "vision":4, "attack_min_range":1, "attack_range":3, "domain":"air", "target_domains":["ground","naval"], "cost":1400, "site":"airbase", "note":"Daño a objetivos individuales; área pendiente."},
    "patrol":          {"code":"M01", "label":"Patrullero", "symbol":"Pt", "hp":10,"move_points":5, "attack":4, "defense":0, "vision":5, "attack_min_range":1, "attack_range":1, "domain":"naval", "target_domains":["naval","air"], "cost":500, "site":"shipyard", "note":"Protección costera y antidrones."},
    "missile_boat":    {"code":"M02", "label":"Lancha misilera", "symbol":"Lm", "hp":8, "move_points":6, "attack":7, "defense":0, "vision":4, "attack_min_range":1, "attack_range":3, "domain":"naval", "target_domains":["naval"], "cost":700, "site":"shipyard", "note":"Golpe rápido; munición pendiente."},
    "corvette":        {"code":"M03", "label":"Corbeta", "symbol":"Co", "hp":12,"move_points":4, "attack":6, "defense":1, "vision":5, "attack_min_range":1, "attack_range":2, "domain":"naval", "target_domains":["naval","air"], "cost":1000, "site":"shipyard", "note":"Escolta costera."},
    "frigate":         {"code":"M04", "label":"Fragata", "symbol":"Fr", "hp":16,"move_points":4, "attack":8, "defense":2, "vision":5, "attack_min_range":1, "attack_range":3, "domain":"naval", "target_domains":["naval","air"], "cost":1500, "site":"shipyard", "note":"Escolta naval; sonar aún no implementado."},
    "destroyer":       {"code":"M05", "label":"Destructor", "symbol":"De", "hp":19,"move_points":4, "attack":9, "defense":2, "vision":5, "attack_min_range":2, "attack_range":4, "domain":"naval", "target_domains":["naval","air","ground"], "cost":2000, "site":"shipyard", "note":"Buque de apoyo; ataque costero individual."},
    "submarine":       {"code":"M06", "label":"Submarino", "symbol":"Su", "hp":12,"move_points":4, "attack":8, "defense":1, "vision":3, "attack_min_range":1, "attack_range":2, "domain":"naval", "target_domains":["naval"], "cost":1700, "site":"shipyard", "note":"Sigilo/sonar pendientes; ahora buque de superficie lógica."},
    "landing_ship":    {"code":"M07", "label":"Buque de desembarco", "symbol":"Bd", "hp":14,"move_points":3, "attack":0, "defense":1, "vision":4, "attack_min_range":1, "attack_range":1, "domain":"naval", "target_domains":[], "cost":900, "site":"shipyard", "note":"Desembarco de tropas pendiente."},
    "usv":             {"code":"M08", "label":"Dron naval USV", "symbol":"US", "hp":3, "move_points":6, "attack":7, "defense":0, "vision":5, "attack_min_range":1, "attack_range":1, "domain":"naval", "target_domains":["naval"], "cost":300, "site":"shipyard", "note":"Ataque de un solo uso: pendiente mecánica consumible."}
}

static func valid(role: String) -> bool:
    return PROFILES.has(role)

static func profile(role: String) -> Dictionary:
    return PROFILES.get(role, {})

static func price(role: String) -> int:
    return int(PROFILES.get(role, {}).get("cost", -1))

static func site(role: String) -> String:
    return str(PROFILES.get(role, {}).get("site", ""))

static func code(role: String) -> String:
    return str(PROFILES.get(role, {}).get("code", ""))

static func is_modern(units: Array) -> bool:
    for unit in units:
        if unit is Dictionary and valid(str(unit.get("role", ""))):
            return true
    return false
