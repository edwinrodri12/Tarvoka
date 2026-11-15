extends RefCounted
class_name TarvokaAPCWeaponAudioV8

# Original synthesized, royalty-free P06 automatic weapon audio.
# Exactly six mechanical reports at the V7 muzzle-flash timestamps.
# Generated once, shared by all 8 faction variants; NO file downloads,
# subscriptions, microphone access, per-frame synthesis or extra combat hits.
const Burst = preload("res://scripts/ui/APCMachineGunV7.gd")
const FLAG := "tarvoka_apc_weapon_audio_v8"
const PLAYER_NAME := "P06V8_SonidoMetralladora"
const STREAM_KEY := "tarvoka_apc_audio_player_v8"
const RATE := 22050
const SHOT_DECAY := 0.092
const CLIP_LENGTH := Burst.BURST_DURATION + 0.08
static var _clip: AudioStreamWAV

static func _wave() -> AudioStreamWAV:
    if _clip != null:
        return _clip
    var frames: int=int(ceil(float(RATE)*CLIP_LENGTH))
    var pcm:=PackedByteArray()
    pcm.resize(frames*2)
    for frame in range(frames):
        var clock: float=float(frame)/float(RATE)
        var sound: float=0.0
        for shot in range(Burst.SHOTS):
            var start: float=(Burst.FIRST_SHOT +
                float(shot)*Burst.SHOT_SPACING)*Burst.BURST_DURATION
            var age: float=clock-start
            if age<0.0 or age>SHOT_DECAY:
                continue
            var release: float=maxf(0.0,1.0-age/SHOT_DECAY)
            # Deterministic bright impulse + metallic bolt slap and brief
            # low body. Sine components are uncorrelated with the noise.
            var bits: int=(frame*1664525+shot*1013904223)&65535
            var noise: float=float(bits)/32767.5-1.0
            var body: float=sin(TAU*130.0*age+0.8*sin(
                TAU*250.0*age))
            var bolt: float=sin(TAU*790.0*age)
            sound+=release*release*(0.34*noise+0.25*body+
                0.12*bolt)*0.70
        var sample: int=clampi(int(sound*32767.0),-32767,32767)
        pcm[frame*2]=sample&255
        pcm[frame*2+1]=(sample>>8)&255
    var clip:=AudioStreamWAV.new()
    clip.mix_rate=RATE
    clip.format=AudioStreamWAV.FORMAT_16_BITS
    clip.stereo=false
    clip.data=pcm
    _clip=clip
    return _clip

static func prepare(model: Node3D) -> bool:
    if model==null or not Burst.has(model):
        return false
    if model.get_meta(FLAG,false):
        return true
    var gun: Node3D=model.find_child(
        "ArmaEstabilizadaP06",true,false) as Node3D
    if gun==null:
        return false
    var player:=AudioStreamPlayer.new()
    player.name=PLAYER_NAME
    player.stream=_wave()
    player.volume_db=-7.0
    player.max_polyphony=1
    player.autoplay=false
    gun.add_child(player)
    model.set_meta(STREAM_KEY,player)
    model.set_meta(FLAG,true)
    return true

static func player(model: Node3D) -> AudioStreamPlayer:
    if model==null or not model.get_meta(FLAG,false):
        return null
    return model.get_meta(STREAM_KEY,null) as AudioStreamPlayer

static func play(model: Node3D) -> bool:
    var audio: AudioStreamPlayer=player(model)
    if audio==null or not is_instance_valid(audio):
        return false
    audio.stop()
    audio.play()
    return true

static func stop(model: Node3D) -> void:
    var audio: AudioStreamPlayer=player(model)
    if audio!=null and is_instance_valid(audio):
        audio.stop()

static func bytes_in_clip() -> int:
    return _wave().data.size()

static func shot_time(index: int) -> float:
    return (Burst.FIRST_SHOT+float(clampi(index,0,Burst.SHOTS-1)) *
        Burst.SHOT_SPACING)*Burst.BURST_DURATION

static func peak_at(seconds: float, window_ms: int=15) -> float:
    # Exposed to QA for timing checks without a physical audio device.
    var clip: AudioStreamWAV=_wave()
    var data: PackedByteArray=clip.data
    var start: int=clampi(int(seconds*float(RATE)),0,data.size()/2-1)
    var stop: int=mini(data.size()/2,start+
        maxi(1,int(float(RATE)*float(window_ms)/1000.0)))
    var peak: float=0.0
    for i in range(start,stop):
        var bits: int=int(data[i*2]) | (int(data[i*2+1])<<8)
        var sample: int=bits-65536 if bits>=32768 else bits
        peak=maxf(peak,absf(float(sample))/32767.0)
    return peak
