extends RefCounted
class_name TarvokaG11BattleContextV25

# Read-only showcase of the REAL BattleTerrain3D mesh renderer.
# Biomes and units are authored through the same Session / Scenarios /
# BattleTerrain3D production code paths. Never touches a saved battle.
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const IdentityV28 = preload("res://scripts/ui/G11CameraIdentityV28.gd")
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const DIMENSIONS := Vector2i(10,8)
const G11_HOME := Vector2i(5,5)
const G11_RIVAL := Vector2i(8,3)
const ROLES := ["mlrs","tank","apc","line","scout"]
const FLAG := "tarvoka_g11_v25_live_battle_context"
# V26: artistic palette comparison is independent of the authoritative
# two-team BattleSession and of shared cached tactical model materials.
const PALETTE_FLAG := "tarvoka_g11_v26_preview_faction"
const PAINT_PARTS := [
    "G11Mobile_InsigniaFrontal",
    "G11Mobile_PinturaCostado_-1",
    "G11Mobile_PinturaCostado_1",
    "G11Mobile_MarcaModulo"
]
const SEED: int=22435

static func make_state(faction: int,biome: String) -> Dictionary:
    if faction<0 or faction>=8 or not Biomes.valid(biome):
        return {}
    var terrain: Array=Scenarios.seeded_terrain(SEED,DIMENSIONS)
    if terrain.is_empty():
        return {}
    # Guaranteed dry hero staging area, while all other surrounding map
    # cells remain the REAL procedurally generated mixed terrain.
    for at in [
        G11_HOME,G11_RIVAL,Vector2i(3,5),Vector2i(6,4),
        Vector2i(4,4),Vector2i(2,3),Vector2i(8,6),
        Vector2i(9,4),Vector2i(7,7)]:
        terrain[at.y][at.x]="plain"
    terrain[5][5]="road"
    terrain[5][4]="road"
    terrain[5][6]="road"
    var units: Array=[
        {"id":"G11-H","role":"mlrs","faction":0,"hp":10,
            "pos":G11_HOME,"move_points":3,"attack":4,"acted":false},
        {"id":"G11-E","role":"mlrs","faction":1,"hp":10,
            "pos":G11_RIVAL,"move_points":3,"attack":4,"acted":false},
        {"id":"Tank-H","role":"tank","faction":0,"hp":10,
            "pos":Vector2i(3,5),"move_points":3,"attack":4,"acted":false},
        {"id":"APC-H","role":"apc","faction":0,"hp":10,
            "pos":Vector2i(6,4),"move_points":3,"attack":4,"acted":false},
        {"id":"Inf-H","role":"line","faction":0,"hp":10,
            "pos":Vector2i(4,4),"move_points":3,"attack":4,"acted":false},
        {"id":"Scout-H","role":"scout","faction":0,"hp":10,
            "pos":Vector2i(2,3),"move_points":3,"attack":4,"acted":false},
        {"id":"Tank-E","role":"tank","faction":1,"hp":10,
            "pos":Vector2i(8,6),"move_points":3,"attack":4,"acted":false},
        {"id":"Inf-E","role":"line","faction":1,"hp":10,
            "pos":Vector2i(9,4),"move_points":3,"attack":4,"acted":false},
        {"id":"APC-E","role":"apc","faction":1,"hp":10,
            "pos":Vector2i(7,7),"move_points":3,"attack":4,"acted":false}
    ]
    # The real game has two active sides. The requested eight-faction
    # art comparison is represented in the studio by translating the
    # approved paint palette of a designated unit after map building;
    # do not insert fictitious factions into the real BattleSession.
    var state: Dictionary=Session.start(
        units,terrain,0,false,true,false,false,false)
    state[Biomes.FIELD]=biome
    return state

# Repaint ONLY the original four faction enamel parts of the two G11s.
# A unique material prevents coloring another unit via G11MobileLOD's
# shared factory cache. These models remain team 0 and 1 in BattleSession.
static func _paint_gallery_g11(battle: Node3D,unit_id: String,
        selected_faction: int) -> bool:
    var g11 := battle.find_child("Unidad3D_"+unit_id,true,false) as Node3D
    if g11==null:
        return false
    var parts: Array[MeshInstance3D]=[]
    for part_name in PAINT_PARTS:
        var part := g11.find_child(str(part_name),true,false) as MeshInstance3D
        if part==null or not part.material_override is StandardMaterial3D:
            return false
        parts.append(part)
    # Preserve authentic metal, roughness and wear. Never mutate the
    # resource shared with other battle models or the approved V23 hero.
    var paint_source: StandardMaterial3D=IdentityV28.base_material(g11)
    if paint_source==null:
        paint_source=parts[0].material_override as StandardMaterial3D
    var enamel := paint_source.duplicate(true) as StandardMaterial3D
    enamel.albedo_color=Models.faction_paint_color(selected_faction)
    for part in parts:
        part.material_override=enamel
    # V28 must rebind to the newly chosen paint AFTER V26 recolors.
    # Otherwise the camera could restore the previous owner's material.
    if not IdentityV28.bind(g11,Tactical.active_level(g11)):
        return false
    g11.set_meta(PALETTE_FLAG,selected_faction)
    g11.set_meta("art_palette_only",true)
    return true

static func build_scene(faction: int,biome: String) -> Node3D:
    var state: Dictionary=make_state(faction,biome)
    if state.is_empty():
        return null
    # Fixed tactical LOD comparison intentionally has no inspected hero unit;
    # in live battles selecting a unit may upgrade only that model to studio detail.
    var battle := Terrain.build(state,"",0)
    if battle==null:
        return null
    # The battle remains the same authentic 0-vs-1 match; only the
    # showroom's four original enamel parts receive the selected colors.
    # The rival wraps to the next approved faction, avoiding identical
    # uniforms even when previewing Pacto Escarlata.
    var rival_faction: int=(faction+1)%8
    if not _paint_gallery_g11(battle,"G11-H",faction) or (
            not _paint_gallery_g11(battle,"G11-E",rival_faction)):
        battle.free()
        return null
    var root := Node3D.new()
    root.name="G11V25_VisorBatallaReal"
    battle.position=Vector3(
        -float(DIMENSIONS.x-1)*Terrain.CELL*0.5,
        0.0,
        -float(DIMENSIONS.y-1)*Terrain.CELL*0.5)
    root.add_child(battle)
    root.set_meta(FLAG,true)
    root.set_meta("visual_only",true)
    root.set_meta("battle_biome",biome)
    root.set_meta("gallery_faction",faction)
    root.set_meta("gallery_rival_faction",rival_faction)
    root.set_meta("palette_preview_only",true)
    root.set_meta("original_state",state.duplicate(true))
    root.set_meta("unit_count",state["units"].size())
    return root
