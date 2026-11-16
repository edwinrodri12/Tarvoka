extends RefCounted
class_name TarvokaApprovedBattleAssets3D

# Real Godot models from the artistic branches, integrated only as visuals.
# Never invent a playable building, change ownership, disclose fog, or
# replace the authoritative city/factory/production state.
const CommandArt = preload("res://scripts/ui/CommandCityArtV14.gd")
const HQ = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar = preload("res://scripts/ui/AirbaseHangarV2.gd")
const Exterior = preload("res://scripts/ui/AirbaseExteriorV6.gd")
const Materials = preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const Finish = preload("res://scripts/ui/AirbaseFinishV8.gd")
const AirDetails = preload("res://scripts/ui/AirbaseDetailV9.gd")
const Naval = preload("res://scripts/ui/NavalBase3DV1.gd")
const NavalV2 = preload("res://scripts/ui/NavalBaseDetailV2.gd")
const NavalV3 = preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const NavalV4 = preload("res://scripts/ui/NavalMarineFinishV4.gd")
const NavalV5 = preload("res://scripts/ui/NavalYardSignalsV5.gd")
const NavalV6 = preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const NavalV7 = preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const NavalV8 = preload("res://scripts/ui/NavalFendersV8.gd")
const NavalV9 = preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const NavalV10 = preload("res://scripts/ui/NavalMooringAlignmentV10.gd")
const NavalV11 = preload("res://scripts/ui/NavalContactFinishV11.gd")
const NavalV12 = preload("res://scripts/ui/NavalFinalContactV12.gd")
const NavalV13 = preload("res://scripts/ui/NavalInspectionV13.gd")

static func _airbase(faction: int, high_detail: bool) -> Node3D:
    var result: Node3D = Airbase.build(1,faction,0)
    if result == null:
        return null
    if high_detail and Hangar.apply(result,1,faction,0):
        if Exterior.apply(result,1,faction,0):
            if Materials.apply(result,1,faction,0):
                if Finish.apply(result,1,faction,0):
                    AirDetails.apply(result,1,faction,0)
    result.scale = Vector3.ONE * 0.105
    return result

static func _naval(faction: int, high_detail: bool) -> Node3D:
    var result: Node3D = Naval.build(1,faction,0)
    if result == null:
        return null
    if high_detail and NavalV2.apply(result,1,faction,0):
        if NavalV3.apply(result,1,faction,0):
            if NavalV4.apply(result,1,faction,0):
                if NavalV5.apply(result,1,faction,0):
                    if NavalV6.apply(result,1,faction,0):
                        if NavalV7.apply(result,1,faction,0):
                            if NavalV8.apply(result,1,faction,0):
                                if NavalV9.apply(result,1,faction,0):
                                    if NavalV10.apply(result,1,faction,0):
                                        if NavalV11.apply(result,1,faction,0):
                                            if NavalV12.apply(result,1,faction,0):
                                                NavalV13.apply(result,1,faction,0)
    result.scale = Vector3.ONE * 0.085
    return result

static func build(kind: String, state: Dictionary, cell: Vector2i,
        public_owner: int, dimensions: Vector2i) -> Node3D:
    # No ownership/intel leaks through the fog or on neutral installations.
    if public_owner not in [0,1]:
        return null
    var faction: int = CommandArt.faction_index(state,public_owner)
    if faction < 0 or faction > 7:
        return null
    var result: Node3D = null
    # Larger maps use original low-poly architecture, not full studio detail.
    var near_quality: bool = dimensions.x * dimensions.y <= 120
    if kind == "city" and CommandArt.is_visual_command_city(kind,cell,dimensions):
        result = HQ.build(1,faction,"operativo",
            HQ.QUALITY_TACTICAL,false)
        if result != null:
            result.scale = Vector3.ONE * 0.14
    elif kind == "airbase":
        result = _airbase(faction,near_quality)
    elif kind == "shipyard":
        result = _naval(faction,near_quality)
    if result != null:
        result.set_meta("tarvoka_approved_native_3d",true)
        result.set_meta("tarvoka_3d_source",kind)
        result.set_meta("tarvoka_visual_only",true)
    return result
