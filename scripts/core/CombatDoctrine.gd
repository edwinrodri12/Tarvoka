extends RefCounted
class_name TarvokaCombatDoctrine

# Design/catalogue v0.1. Weapon damage, ranges, domains and prices remain
# owned by UnitRoles / ModernArsenal. This table ONLY sets realistic relative
# reaction capacity and describes the role; not an unseen attack bonus.
# Tier is the CAMPAIGN INTRODUCTION act (1-4), NOT extra combat power.
# 32 unique playable roles: five original plus 27 modern.
const PROFILES := {
    "line":{"weapon":"fusil","style":"direct","reaction_pct":55,"armor":"ligera","tier":1,"strength":"Infanteria flexible, control de territorio","weakness":"Vulnerable a blindados y fuego de apoyo"},
    "scout":{"weapon":"carabina","style":"direct","reaction_pct":40,"armor":"ligera","tier":1,"strength":"Reconocimiento y vision amplia","weakness":"Bajo dano y pocos puntos de vida"},
    "bulwark":{"weapon":"ametralladora protegida","style":"direct","reaction_pct":55,"armor":"blindada","tier":1,"strength":"Defensa frontal y resistencia","weakness":"Lento; rompedor lo contrarresta"},
    "piercer":{"weapon":"arma antiblindaje","style":"direct","reaction_pct":35,"armor":"ligera","tier":1,"strength":"Contra blindados y baluartes","weakness":"Expuesto ante infanteria y bombardeo"},
    "artillery":{"weapon":"lanzador indirecto","style":"indirect","reaction_pct":0,"armor":"ligera","tier":1,"strength":"Fuego desde distancia de dos casillas","weakness":"Sin respuesta inmediata; punto ciego cercano"},
    "assault":{"weapon":"fusil de asalto","style":"direct","reaction_pct":55,"armor":"ligera","tier":1,"strength":"Presion y captura en zonas urbanas","weakness":"Muy vulnerable a tanques y artilleria"},
    "engineer":{"weapon":"arma de autodefensa","style":"direct","reaction_pct":25,"armor":"ligera","tier":1,"strength":"Captura y apoyo a infraestructura","weakness":"Combate deficiente y movimiento limitado"},
    "apc":{"weapon":"ametralladora montada","style":"direct","reaction_pct":35,"armor":"blindada","tier":2,"strength":"Movilidad y escolta ligera","weakness":"Ataque bajo frente a blindados; carga pendiente"},
    "ifv":{"weapon":"canon automatico","style":"direct","reaction_pct":55,"armor":"blindada","tier":2,"strength":"Apoyo mecanizado y cobertura de escuadras","weakness":"Pierde frente a tanque y armas pesadas"},
    "tank":{"weapon":"canon de carro","style":"direct","reaction_pct":60,"armor":"pesada","tier":2,"strength":"Duelo contra vehiculos terrestres blindados","weakness":"Sin ataque aereo; flancos, apoyo artillero"},
    "spg":{"weapon":"canon autopropulsado","style":"indirect","reaction_pct":0,"armor":"blindada","tier":2,"strength":"Bombardeo terrestre a distancia","weakness":"No responde; minimo de dos casillas"},
    "mlrs":{"weapon":"salva de cohetes","style":"saturation","reaction_pct":0,"armor":"ligera","tier":2,"strength":"Maximo alcance terrestre","weakness":"Punto ciego de tres casillas; recarga cara"},
    "mobile_aa":{"weapon":"canon antiaereo","style":"direct","reaction_pct":65,"armor":"blindada","tier":2,"strength":"Intercepcion de aviones y drones cercanos","weakness":"No puede atacar unidades terrestres"},
    "sam":{"weapon":"misiles antiaereos","style":"guided","reaction_pct":35,"armor":"ligera","tier":3,"strength":"Area antiaerea lejana","weakness":"Punto ciego cercano y ataque no terrestre"},
    "ew":{"weapon":"interferencia electronica","style":"support","reaction_pct":0,"armor":"ligera","tier":3,"strength":"Soporte electronico futuro","weakness":"Sin arma; interferencia aun no implementada"},
    "logistics":{"weapon":"reabastecimiento","style":"support","reaction_pct":0,"armor":"ligera","tier":1,"strength":"Suministro de combustible y municiones","weakness":"Sin armas; proteger y escoltar"},
    "uav_recon":{"weapon":"sensores opticos","style":"support","reaction_pct":0,"armor":"aerea","tier":2,"strength":"Vision y reconocimiento de area","weakness":"Sin armas, vulnerable a antiaereo"},
    "fpv":{"weapon":"carga explosiva dirigida","style":"consumable","reaction_pct":0,"armor":"aerea","tier":3,"strength":"Impacto terrestre economico de un uso","weakness":"Se destruye al disparar; no anti-aereo"},
    "loitering":{"weapon":"municion merodeadora","style":"consumable","reaction_pct":0,"armor":"aerea","tier":3,"strength":"Ataque remoto limitado a objetivo terrestre","weakness":"Consumible; no puede interceptar aviones"},
    "ucav":{"weapon":"misil aire-superficie","style":"guided","reaction_pct":25,"armor":"aerea","tier":3,"strength":"Golpes repetibles a tierra y mar","weakness":"Vulnerable a defensas aereas y recargas"},
    "attack_heli":{"weapon":"cohetes antitanque","style":"guided","reaction_pct":35,"armor":"aerea","tier":3,"strength":"Ataque terrestre movil","weakness":"Vulnerable al antiaereo; no combate aire-aire"},
    "transport_heli":{"weapon":"transporte aereo","style":"support","reaction_pct":0,"armor":"aerea","tier":3,"strength":"Insercion y evacuacion futuras","weakness":"Sin armas ni transporte implementado"},
    "fighter":{"weapon":"misiles aire-aire","style":"guided","reaction_pct":55,"armor":"aerea","tier":4,"strength":"Superioridad aerea y ataque limitado terrestre","weakness":"Alto coste y dependencia de combustible"},
    "bomber":{"weapon":"bombas guiadas","style":"guided","reaction_pct":15,"armor":"aerea","tier":4,"strength":"Gran golpe contra tierra y buques","weakness":"Sin armas aire-aire; caro y expuesto"},
    "patrol":{"weapon":"canon naval ligero","style":"direct","reaction_pct":55,"armor":"naval","tier":1,"strength":"Defensa costera y anti-drones","weakness":"Poco poder ante fragatas/destructores"},
    "missile_boat":{"weapon":"misil antibuque","style":"guided","reaction_pct":30,"armor":"naval","tier":2,"strength":"Golpe naval rapido a distancia","weakness":"Poca resistencia y sin defensa anti-aerea"},
    "corvette":{"weapon":"canon naval mixto","style":"direct","reaction_pct":55,"armor":"naval","tier":3,"strength":"Escolta y defensa anti-aerea","weakness":"Menor alcance y blindaje que fragata"},
    "frigate":{"weapon":"misiles de escolta","style":"guided","reaction_pct":50,"armor":"naval","tier":4,"strength":"Escorta buques y protege contra aire","weakness":"Alto coste; vulnerable a ataque submarino futuro"},
    "destroyer":{"weapon":"misiles de largo alcance","style":"guided","reaction_pct":45,"armor":"naval","tier":4,"strength":"Apoyo costero de largo alcance","weakness":"Punto ciego corto y coste muy alto"},
    "submarine":{"weapon":"torpedo","style":"guided","reaction_pct":35,"armor":"naval","tier":4,"strength":"Ataque naval especifico","weakness":"No ataca costa/aire; sigilo pendiente"},
    "landing_ship":{"weapon":"transporte anfibio","style":"support","reaction_pct":0,"armor":"naval","tier":2,"strength":"Movilidad y desembarco futuro","weakness":"Sin defensa; carga no implementada"},
    "usv":{"weapon":"carga antibuque expendible","style":"consumable","reaction_pct":0,"armor":"naval","tier":4,"strength":"Golpe naval consumible y economico","weakness":"Se consume al impactar; no tierra/aire"}
}

const STYLES := ["direct","guided","indirect","saturation","consumable","support"]
const ARMOR_CLASSES := ["ligera","blindada","pesada","aerea","naval"]

# Veterancy is a separate, opt-in FUTURE feature. Experience bonuses are
# intentionally 0 today to protect approved competitive/faction balance.
# UI and mission logic may show labels; no state XP field is currently added.
const VETERANCY := [
    {"level":0,"name":"Recluta","xp":0,"attack_bonus":0,"defense_bonus":0},
    {"level":1,"name":"Regular","xp":15,"attack_bonus":0,"defense_bonus":0},
    {"level":2,"name":"Veterano","xp":40,"attack_bonus":0,"defense_bonus":0},
    {"level":3,"name":"Elite","xp":80,"attack_bonus":0,"defense_bonus":0}
]

static func valid(role: String) -> bool:
    return PROFILES.has(role)

static func profile(role: String) -> Dictionary:
    return PROFILES.get(role, {}).duplicate(true)

static func reaction_percent(role: String) -> int:
    return int(PROFILES.get(role, {}).get("reaction_pct", 0))

static func tier(role: String) -> int:
    return int(PROFILES.get(role, {}).get("tier", 0))
