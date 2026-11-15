extends SceneTree

# Original 22.05 kHz mono PCM is synthesized only once for all factions.
# Its amplitude peaks align with the V7 six individual muzzle flashes.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Burst = preload("res://scripts/ui/APCMachineGunV7.gd")
const Audio = preload("res://scripts/ui/APCWeaponAudioV8.gd")
var failures: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V8 sound: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var clip: AudioStreamWAV=Audio._wave()
    _check(clip!=null and clip.format==AudioStreamWAV.FORMAT_16_BITS,
        "native PCM sample is 16-bit")
    _check(clip.mix_rate==Audio.RATE and not clip.stereo,
        "portable mono 22.05 kHz clip")
    var bytes: int=Audio.bytes_in_clip()
    _check(bytes >= 2*Audio.RATE,
        "clip covers entire 1.12-second V7 burst")
    _check(bytes < 2*Audio.RATE*2,
        "sound remains compact for mobile RAM")
    _check(Audio.peak_at(0.02,5)<0.0001,
        "silence before initial trigger delay")
    for i in range(Burst.SHOTS):
        var moment: float=Audio.shot_time(i)
        _check(Burst.active_shot(moment/Burst.BURST_DURATION+0.012)==i,
            "visual muzzle pulse %d aligns with sound" % i)
        _check(Audio.peak_at(moment+0.002,16)>0.04,
            "shot %d actually has a sharp PCM peak" % i)
        _check(Audio.peak_at(moment-0.033,5)<0.002,
            "shot %d has an audible gap before ignition" % i)
    var first: AudioStreamWAV=null
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        root.add_child(model)
        _check(Audio.player(model)!=null,
            "built audio node for faction %d" % faction)
        _check(model.get_meta(Audio.FLAG,false),
            "audio is prepared before the user taps attack")
        var source: AudioStreamPlayer=Audio.player(model)
        if source!=null:
            if first==null:
                first=source.stream as AudioStreamWAV
            else:
                _check(source.stream==first,
                    "all factions share exactly one audio PCM allocation")
            _check(source.max_polyphony==1,
                "one playback voice per vehicle")
            # Godot Dummy audio-driver supports invoking these controls even
            # though it does not constitute a physical listening test.
            _check(Audio.play(model),
                "studio attack can trigger burst %d" % faction)
            Audio.stop(model)
        model.queue_free()
        await process_frame
    if failures>0:
        push_error("P06 V8 audio: %d failures" % failures)
        quit(1)
        return
    print("PASS P06 V8 AUDIO: six individually timed pulses, shared original 16-bit sound across 8 factions, no clip reallocation")
    quit(0)
