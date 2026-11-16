extends RefCounted
class_name TarvokaG13GroundAirFinishV4

# Final pass ON TOP of the existing G13 V3 land/air poses.
# Reuses both original visible muzzle flash and smoke assemblies;
# adds ZERO nodes/meshes and never calls combat or changes unit stats.
const FLAG := "tarvoka_g13_v4_two_domain_fire_finish"
const MODE := "tarvoka_g13_v4_last_demo_domain"
const GROUND_SHOTS: int=10
const AIR_SHOTS: int=16
const BARREL_RECOIL_M: float=0.025
const GROUND_PITCH_MAX: float=12.0
const AIR_PITCH_MIN: float=35.0

static func _mesh(root: Node3D,label: String)->MeshInstance3D:
    return root.find_child(label,true,false) as MeshInstance3D

static func install(root: Node3D)->bool:
    if root==null or not bool(root.get_meta(
            "tarvoka_g13_mobile_aa_visual_v1",false)) or (
            bool(root.get_meta(FLAG,false))):
        return false
    var pitch:=root.find_child("G13_ElevacionCanones",true,false) as Node3D
    if pitch==null:
        return false
    for side in [-1,1]:
        if _mesh(pitch,"G13_FlashCone_%d" % side)==null or (
                _mesh(pitch,"G13_SmokeVolume_%d" % side)==null) or (
                pitch.find_child("G13_Autocannon_%d" % side,
                    false,false)==null) or (
                pitch.find_child("G13_RealMuzzle_%d" % side,
                    false,false)==null):
            return false
    for side in [-1,1]:
        # Keep the same existing draw nodes, improve materials in-place.
        var flash:=_mesh(pitch,"G13_FlashCone_%d" % side)
        var ember:=StandardMaterial3D.new()
        ember.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        ember.albedo_color=Color("#ffd48b")
        ember.emission_enabled=true
        ember.emission=Color("#ff9b43")
        ember.emission_energy_multiplier=0.86
        flash.material_override=ember
        var smoke:=_mesh(pitch,"G13_SmokeVolume_%d" % side)
        var haze:=StandardMaterial3D.new()
        haze.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        haze.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
        haze.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        haze.albedo_color=Color(0.68,0.71,0.72,0.24)
        smoke.material_override=haze
    root.set_meta(FLAG,true)
    return true

static func reset(root: Node3D)->void:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return
    var pitch:=root.find_child("G13_ElevacionCanones",true,false) as Node3D
    if pitch==null:
        return
    for side in [-1,1]:
        var x: float=float(side)*0.23
        var cannon:=pitch.find_child(
            "G13_Autocannon_%d" % side,false,false) as Node3D
        var muzzle:=pitch.find_child(
            "G13_RealMuzzle_%d" % side,false,false) as Node3D
        if cannon!=null:
            cannon.position=Vector3(x,-0.015,-0.66)
        if muzzle!=null:
            muzzle.position=Vector3(x,-0.015,-1.220)
    root.remove_meta(MODE)
    root.remove_meta("tarvoka_g13_v4_recoil_m")

static func pose(root: Node3D,kind: String,progress: float)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)) or (
            kind not in ["attack_ground","attack_air"]):
        return false
    var pitch:=root.find_child("G13_ElevacionCanones",true,false) as Node3D
    var radar:=root.find_child("G13_RadarAzimut",true,false) as Node3D
    if pitch==null or radar==null:
        return false
    var ground: bool=kind=="attack_ground"
    # Earlier V3 already sets the correct real gun elevation.
    # Preserve it and differentiate actual radar tracking + cadence.
    if ground:
        radar.rotation_degrees.y=6.0
    else:
        radar.rotation_degrees.y=26.0*sin(
            PI*clampf(progress,0.0,1.0))
    var recoil_max: float=0.0
    for side in [-1,1]:
        var active:=root.find_child(
            "G13_MuzzleFlash_%d" % side,true,false) as Node3D
        var smoke:=root.find_child(
            "G13_MuzzleSmoke_%d" % side,true,false) as Node3D
        var barrel:=pitch.find_child(
            "G13_Autocannon_%d" % side,false,false) as Node3D
        var muzzle:=pitch.find_child(
            "G13_RealMuzzle_%d" % side,false,false) as Node3D
        if active==null or smoke==null or barrel==null or muzzle==null:
            return false
        var t: float=clampf(progress,0.0,1.0)
        var shots: int=GROUND_SHOTS if ground else AIR_SHOTS
        var phase: float=fposmod(t*float(shots),1.0)
        # Recoil only while this exact muzzle is firing.
        var depth: float=(
            BARREL_RECOIL_M*(1.0-phase/0.42)
            if active.visible and phase<0.42 else 0.0)
        var x: float=float(side)*0.23
        barrel.position=Vector3(x,-0.015,-0.66+depth)
        muzzle.position=Vector3(x,-0.015,-1.220+depth)
        recoil_max=maxf(recoil_max,depth)
        if smoke.visible:
            # Longer, more diffuse air plumes; shorter, denser ground
            # puffs. Original smoke NODE and mesh are reused.
            smoke.scale=(
                Vector3(0.85+0.20*t,0.90+0.22*t,1.22+0.35*t)
                if ground else
                Vector3(0.70+0.22*t,0.76+0.25*t,1.65+0.55*t))
    root.set_meta(MODE,"ground" if ground else "air")
    root.set_meta("tarvoka_g13_v4_recoil_m",recoil_max)
    return true
