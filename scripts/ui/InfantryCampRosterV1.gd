extends RefCounted
class_name TarvokaInfantryCampRosterV1

# The six agreed infantry identities: one basic, one special and four
# specialist camp builders. This is art/UI metadata, not battlefield logic.
const CORE_ROLES := [
    "line", "infantry_commando",
    "infantry_sniper", "infantry_engineer",
    "infantry_logistic", "infantry_medic"
]
const CAMP_FOR_ROLE := {
    "infantry_sniper":"reconocimiento",
    "infantry_engineer":"defensivo",
    "infantry_logistic":"suministros",
    "infantry_medic":"medico"
}
const ROLE_LABEL := {
    "line":"Infantería básica · Guardia",
    "infantry_commando":"Comando de Operaciones Especiales · FS-24",
    "infantry_sniper":"Francotirador · Reconocimiento",
    "infantry_engineer":"Ingeniero · Defensivo",
    "infantry_logistic":"Logístico de infantería · Suministros",
    "infantry_medic":"Médico de combate · Médico"
}
const CAMP_NOTE := {
    "reconocimiento":"Amplía visión; no exige ocupar la casilla",
    "defensivo":"Fortificación; constructor exclusivo: Ingeniero",
    "suministros":"Reabastece a la unidad que ocupa el campamento",
    "medico":"Cura a la infantería que ocupa el campamento"
}

static func is_core(role: String) -> bool:
    return role in CORE_ROLES

static func camp_for(role: String) -> String:
    return str(CAMP_FOR_ROLE.get(role,""))

static func can_build(role: String, camp: String) -> bool:
    return not camp.is_empty() and camp_for(role)==camp

static func label(role: String) -> String:
    return str(ROLE_LABEL.get(role,role))
