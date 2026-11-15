extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
const Burst = preload("res://scripts/ui/APCMachineGunV7.gd")
const V3 = preload("res://scripts/ui/APCFinishV3.gd")
const V6 = preload("res://scripts/ui/APCFinishV6.gd")
const Wreck = preload("res://scripts/ui/APCDamageV7.gd")
var failures: int = 0

func _check(ok: bool,what: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V7 QA: "+what)

func _initialize() -> void:
    call_deferred("_run")

func _part(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _run() -> void:
    _check(Rig.SHOT_DURATION == Burst.BURST_DURATION,
        "shared attack duration must match gun animation")
    _check(Burst.active_shot(0.0)==-1,"no unintended idle gunfire")
    _check(Burst.active_shot(1.0)==-1,"no lingering final flash")
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"V7 APC builds in faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(Burst.has(model),"shot effects cached and ready")
        _check(model.get_meta(Wreck.FLAG,false),"physical damage rig ready")
        _check(_part(model,Burst.FLASH_ROOT)!=null,"physical muzzle tongues built")
        _check(_part(model,Burst.SMOKE_ROOT)!=null,"soft 3D muzzle puff built")
        var initial_meshes: int=Models.inspect_meshes(model)
        var gun: Node3D=_part(model,"ArmaEstabilizadaP06")
        var turret: Node3D=_part(model,"EstacionRemotaP06")
        var legacy: Node3D=_part(model,"FogonazoArmaP06")
        _check(gun!=null and turret!=null and legacy!=null,
            "gun/turret authored and retained")
        for i in range(Burst.SHOTS):
            var instant: float=Burst.FIRST_SHOT+float(i)*Burst.SHOT_SPACING+0.018
            _check(Burst.active_shot(instant)==i,
                "individual muzzle pulse %d" % i)
            _check(Rig.pose(model,"attack",instant,42.0),
                "animated shot %d" % i)
            _check(_part(model,Burst.FLASH_ROOT).visible,
                "flash appears at shot %d" % i)
            _check(legacy.visible,"legacy flash correctly pulsed with new weapon")
            var casing: Node3D=_part(model,Burst.SHELL_PREFIX+str(i))
            _check(casing!=null and casing.visible,
                "brass casing ejected at shot %d" % i)
            _check(gun.position.z > Burst.GUN_BASE_Z,
                "short spring recoil at shot %d" % i)
            if i<5:
                var silent: float=Burst.FIRST_SHOT+float(i)*Burst.SHOT_SPACING+0.077
                _check(Burst.active_shot(silent)==-1,
                    "dark interval between pulses %d" % i)
                _check(Rig.pose(model,"attack",silent),
                    "idle phase between shots %d" % i)
                _check(not _part(model,Burst.FLASH_ROOT).visible,
                    "no continuous cannon blast between rounds")
        _check(Rig.pose(model,"attack",0.96),"gun settles after the burst")
        _check(not _part(model,Burst.FLASH_ROOT).visible,
            "last flash ends")
        _check(Rig.pose(model,"idle",1.0),"idle pose")
        _check(not _part(model,Burst.FLASH_ROOT).visible,
            "stops flash after reset")
        _check(absf(gun.position.z-Burst.GUN_BASE_Z)<0.0001,
            "no residual recoil")
        for i in range(Burst.SHOTS):
            _check(not _part(model,Burst.SHELL_PREFIX+str(i)).visible,
                "casings pooled out of view after reset")
        _check(Models.inspect_meshes(model)==initial_meshes,
            "no new meshes allocated per shot")

        var rear_panel: Node3D=_part(model,"CorazaFaceteadaV2_1_1")
        var antenna: Node3D=_part(model,"AntenaBlindada_-1")
        var wheel: Node3D=_part(model,"RuedaMotorizadaP06_1_0")
        _check(rear_panel!=null and antenna!=null and wheel!=null,
            "actual breakable parts exist")
        for stage in range(5):
            _check(V3.apply_stage(model,stage),"legacy stage %d" % stage)
            _check(V6.set_stage(model,stage),"V6 stage %d" % stage)
            _check(Wreck.set_stage(model,stage),"V7 stage %d" % stage)
            _check(Wreck.stage(model)==stage,"V7 stage index")
            if stage>=1:
                _check(not antenna.visible,"antenna bent, not duplicated")
            if stage>=2:
                _check(not rear_panel.visible,"armor physically torn open")
                _check(_part(model,"P06V7_DanoFisico_2").visible,
                    "torn panel physically present")
            if stage>=3:
                _check(_part(model,"P06V7_DanoFisico_3").visible,
                    "wheel/fender fragments visible")
            if stage==4:
                _check(not wheel.visible,
                    "wrecked front-right wheel from V3 hidden")
                _check(absf(turret.rotation_degrees.z)>10.0,
                    "wrecked turret physically tilted")
                _check(_part(model,"AnilloMecanismoTorretaExpuesto")!=null,
                    "exposed turret rotation ring is real geometry")
        _check(V3.apply_stage(model,0),"repair physical wheel")
        _check(V6.set_stage(model,0),"repair V6 roof")
        _check(Wreck.set_stage(model,0),"repair bent armor/turret")
        _check(antenna.visible and rear_panel.visible and wheel.visible,
            "all original parts restored")
        _check(absf(turret.rotation_degrees.z)<0.001,
            "turret alignment restored")
        _check(Wreck.set_stage(model,3),"critical stage for comparison")
        _check(Wreck.set_enabled(model,false),"comparison hides damage V7")
        _check(rear_panel.visible and antenna.visible,
            "legacy V3 comparison shows original silhouette")
        _check(Wreck.set_enabled(model,true),"restore V7 staged debris")
        _check(not rear_panel.visible and not antenna.visible,
            "V7 damage details restored on comparison exit")
        model.queue_free()
        await process_frame
    if failures>0:
        push_error("P06 V7 machinegun & damage failures: %d" % failures)
        quit(1)
        return
    print("PASS P06 V7: 8 factions, 6 distinct machinegun shots/casings, no transient mesh allocations, staged physical damage and repair")
    quit(0)
