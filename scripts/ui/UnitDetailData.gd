extends RefCounted
class_name TarvokaUnitDetailData

# Read-only, visibility-safe breakdown for the existing battle HUD card.
# Never use a raw enemy roster: UnitDossierData inspects via Visibility.
const Dossier = preload("res://scripts/ui/UnitDossierData.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

static func inspect(state: Dictionary, unit_id: String, viewer: int = 0) -> Dictionary:
    if unit_id.is_empty() or viewer not in [0,1]:
        return {}
    var data: Dictionary = Dossier.inspect(state,unit_id,"",
        Vector2i(-1,-1),Vector2i(-1,-1),viewer)
    if str(data.get("kind","")) != "friendly":
        return {}
    var selected: Dictionary = {}
    for item in state.get("units",[]):
        if item is Dictionary and str(item.get("id","")) == unit_id and (
                int(item.get("faction",-1)) == viewer) and int(item.get("hp",0)) > 0:
            selected=item
            break
    if selected.is_empty():
        return {}
    var role: String = str(selected.get("role",""))
    var profile: Dictionary = (
        Roles.PROFILES[role] if Roles.PROFILES.has(role) else Arsenal.profile(role))
    var targets: Array = selected.get("target_domains",[])
    if targets.is_empty() and int(selected.get("attack",0)) > 0 and not Arsenal.valid(role):
        targets=["ground"]
    var target_words: PackedStringArray = []
    for target in targets:
        match str(target):
            "ground": target_words.append("Tierra")
            "air": target_words.append("Aire")
            "naval": target_words.append("Mar")
    var domain: String = str(data.get("domain","ground"))
    var domain_name: String=(
        "Aérea" if domain=="air" else "Naval" if domain=="naval" else "Terrestre")
    var attack_min: int = int(selected.get("attack_min_range",1))
    var attack_max: int = int(selected.get("attack_range",1))
    var ammo_value: String = (
        "%d / %d" % [int(data["ammo"]),int(data.get("ammo_max",0))]
        if data.has("ammo") else "No utiliza")
    var fuel_value: String = (
        "%d / %d" % [int(data["fuel"]),int(data.get("fuel_max",0))]
        if data.has("fuel") else "No utiliza")
    var level_value: String = str(selected.get("level","")) if selected.has("level") else ""
    var features: PackedStringArray = []
    if Economy.can_capture(selected):
        features.append("Puede capturar instalaciones")
    if role=="logistics":
        features.append("Abastecimiento logístico")
    if role=="engineer":
        features.append("Construcción de campamentos: pendiente")
    if role in ["apc","ifv","transport_heli","landing_ship"]:
        features.append("Transporte de tropas: pendiente")
    if features.is_empty():
        features.append("Sin habilidades adicionales activas registradas")
    var movement: int = int(selected.get("move_points",0))
    var price: int = Economy.cost(role) if Roles.valid(role) else -1
    var result: Dictionary = data.duplicate(true)
    result["code"] = Arsenal.code(role) if Arsenal.valid(role) else role.to_upper()
    result["faction_color"] = Identity.color_for(state,viewer)
    result["faction_name"] = Identity.name_for(state,viewer)
    result["domain_label"] = domain_name
    result["target_label"] = ", ".join(target_words) if not target_words.is_empty() else "No ataca"
    result["range_label"] = (
        "%d–%d casillas" % [attack_min,attack_max]
        if int(selected.get("attack",0)) > 0 else "Sin armas")
    result["price_label"] = "%d créditos" % price if price >= 0 else "No disponible"
    result["ammo_label"] = ammo_value
    result["fuel_label"] = fuel_value
    result["level_label"] = level_value
    result["features"] = features
    result["status"] = str(data.get("status",""))
    result["stat_pairs"] = [
        {"name":"VIDA","value":"%d / %d" % [int(data.get("hp",0)),int(data.get("max_hp",1))]},
        {"name":"ATAQUE","value":str(selected.get("attack",0))},
        {"name":"DEFENSA","value":str(selected.get("defense",0))},
        {"name":"MOVIMIENTO","value":str(movement)},
        {"name":"VISIÓN","value":str(selected.get("vision",3))},
        {"name":"ALCANCE","value":str(result["range_label"])},
        {"name":"OBJETIVOS","value":str(result["target_label"])},
        {"name":"TIPO","value":domain_name},
        {"name":"MUNICIÓN","value":ammo_value},
        {"name":"COMBUSTIBLE","value":fuel_value},
        {"name":"COSTE","value":str(result["price_label"])},
        {"name":"CONTRAATAQUE","value":"Depende de rango, PV y munición"}
    ]
    return result
