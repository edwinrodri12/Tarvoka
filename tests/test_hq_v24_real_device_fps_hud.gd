extends SceneTree

# QA of the SAME existing opt-in FPS button/PanelContainer used by the
# playable battle. Measurements appear when the user opens a battle on a
# physical Android device. CI itself is Linux, not an Android FPS reading.
const Battle=preload("res://scripts/ui/BattleTerrain3D.gd")
const Probe=preload("res://scripts/ui/City3DPerfProbeV7.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain:Array=Scenarios.terrain(0)
    var state:Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true,true)
    var original:Dictionary=state.duplicate(true)
    var battle:Node3D=Battle.build(state,"",0)
    assert(battle!=null)
    root.add_child(battle)
    var probe:Control=Probe.new()
    root.add_child(probe)
    probe.attach_battle(battle)
    var before:Dictionary=probe.snapshot()
    assert(int(before["headquarters"])==2,
        "Only two original real capital HQs are allowed")
    assert(int(before["headquarters_meshes"])==6,
        "Each native V24 HQ must have three consolidated MeshInstances")
    assert(int(before["headquarters_surfaces"])==26,
        "Two HQs must contain 13 approved material surfaces each")
    assert(int(before["headquarters_tier1"])==2)
    assert(int(before["headquarters_tier2"])==0)
    assert(int(before["headquarters_tier3"])==0)
    assert(int(before["headquarters_ruins"])==0)
    assert(int(before["headquarters_neutral"])>=0)
    assert(not probe.visible)
    assert(not probe.is_processing())
    probe.set_recording(true)
    assert(probe.visible and probe.is_processing())
    for i in range(8):
        await process_frame
    probe.refresh_once()
    var after:Dictionary=probe.snapshot()
    assert(int(after["headquarters"])==2)
    assert(int(after["headquarters_meshes"])==6)
    assert(int(after["headquarters_surfaces"])==26)
    assert(probe.readout.text.contains("Cuarteles HQ V24 2"))
    assert(probe.readout.text.contains("mallas 6"))
    assert(probe.readout.text.contains("superficies 26"))
    assert(probe.readout.text.contains("FPS"))
    assert(str(after["source"]).contains("on the device"))
    assert(state==original,
        "Monitoring actual HQ visual surfaces must never mutate gameplay")
    probe.set_recording(false)
    assert(not probe.visible and not probe.is_processing())
    probe.attach_battle(null)
    assert(int(probe.snapshot()["headquarters"])==0)
    probe.queue_free()
    battle.queue_free()
    await process_frame
    print("PASS HQ V24 REAL DEVICE HUD: original two command cities, six native meshes, 26 material surfaces, genuine FPS button, untouched economy and clean detach")
    quit(0)
