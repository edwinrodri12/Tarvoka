extends SceneTree

# V4 art-only refinement layered on existing V3 attacks and G13 V2 armor.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V4=preload("res://scripts/ui/G13GroundAirFinishV4.gd")
const G11=preload("res://scripts/ui/G11FinalAuditV33.gd")
var failed: int=0

func _check(ok: bool,description: String)->void:
    if not ok:
        failed+=1
        push_error("G13 V4 polished ground/air animation: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    _check(V4.GROUND_SHOTS<V4.AIR_SHOTS,
        "air bursts have faster cadence than ground fire")
    for faction in range(8):
        var approved:=Models.build("mlrs",faction,true,13)
        _check(approved!=null and G11.verify_hero(approved),
            "G11 finished V33 remains approved and unchanged")
        if approved!=null:
            approved.free()
        for level in [8,13]:
            var model:=Models.build("aa_mobile",faction,true,level)
            _check(model!=null and G13.has_model(model),
                "G13 V1 same 4x4 vehicle across eight factions and details")
            if model==null:
                continue
            _check(bool(model.get_meta(V4.FLAG,false)),
                "V4 finish installed on original V3 3D vehicle")
            var count: int=Models.inspect_meshes(model)
            var hull: Transform3D=model.transform
            var turret:=model.find_child(G13.TURRET,true,false) as Node3D
            var guns:=model.find_child(G13.GUNS,true,false) as Node3D
            var radar:=model.find_child(G13.RADAR,true,false) as Node3D
            _check(bool(model.get_meta("tarvoka_g13_detail_v2",false)) or
                level==8,
                "concurrent G13 V2 fender/armor details are still present")
            _check(Models.pose_model("aa_mobile",model,
                "attack_ground",0.42),
                "land attack continues using existing V3 mode")
            _check(guns.rotation_degrees.x<V4.GROUND_PITCH_MAX and
                absf(radar.rotation_degrees.y-6.0)<0.01,
                "ground firing stays near horizon with forward radar")
            _check(str(model.get_meta(V4.MODE,""))=="ground",
                "explicit ground mode is recorded only for art preview")
            var ground_recoil: float=float(model.get_meta(
                "tarvoka_g13_v4_recoil_m",0.0))
            _check(ground_recoil>0.0 and ground_recoil<=V4.BARREL_RECOIL_M,
                "existing ground barrel recoils a maximum of 2.5 cm")
            _check(Models.pose_model("aa_mobile",model,
                "attack_air",0.25,Vector2i(1,0)),
                "high elevation V3 air mode retained with bearing")
            _check(guns.rotation_degrees.x>=V4.AIR_PITCH_MIN and
                absf(turret.rotation_degrees.y-90.0)<0.01,
                "air attack elevates and rotates precisely to requested heading")
            _check(absf(radar.rotation_degrees.y-6.0)>5.0,
                "anti-air radar tracking visually differs from ground")
            _check(str(model.get_meta(V4.MODE,""))=="air",
                "air mode recorded distinctly")
            _check(float(model.get_meta(
                "tarvoka_g13_v4_recoil_m",0.0))>0.0,
                "existing air barrel recoils during alternating muzzle pulse")
            var flashes: int=0
            for side in [-1,1]:
                var flash:=model.find_child(
                    "G13_MuzzleFlash_%d" % side,true,false) as Node3D
                var cone:=model.find_child(
                    "G13_FlashCone_%d" % side,true,false) as MeshInstance3D
                var smoke:=model.find_child(
                    "G13_SmokeVolume_%d" % side,true,false) as MeshInstance3D
                _check(flash!=null and cone!=null and smoke!=null,
                    "reuses actual V3 muzzle/smoke nodes without adding copies")
                if flash!=null and flash.visible:
                    flashes+=1
                if cone!=null and smoke!=null:
                    var material:=cone.material_override as StandardMaterial3D
                    var mist:=smoke.material_override as StandardMaterial3D
                    _check(material!=null and material.emission_enabled,
                        "original muzzle flashes now emit soft light")
                    _check(mist!=null and
                        mist.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,
                        "original opaque smoke becomes translucent")
            _check(flashes==1,
                "V3 legacy alternating single-muzzle flashes preserved")
            _check(Models.inspect_meshes(model)==count and model.transform==hull,
                "V4 adds zero geometry and never moves authoritative vehicle")
            Models.restore_model_pose("aa_mobile",model)
            _check(not model.has_meta(V4.MODE) and
                not model.has_meta("tarvoka_g13_v4_recoil_m"),
                "all temporary mode metadata cleared when animation ends")
            for side in [-1,1]:
                var cannon:=guns.find_child(
                    "G13_Autocannon_%d" % side,false,false) as Node3D
                var tip:=guns.find_child(
                    "G13_RealMuzzle_%d" % side,false,false) as Node3D
                _check(cannon!=null and tip!=null and
                    absf(cannon.position.z+0.66)<0.0001 and
                    absf(tip.position.z+1.220)<0.0001,
                    "both barrels restore original approved world-space offsets")
            _check(not Models.pose_model("aa_mobile",model,
                "combat_aa",0.5),
                "no unimplemented game firing/attack orders introduced")
            model.free()
    if failed>0:
        push_error("G13 V4 ground/air native visual QA FAILED %d" % failed)
        quit(1)
        return
    print("PASS G13 V4: 8 factions x 2 variants, V3 air/ground trajectories, distinct cadence, 2.5cm reversible recoil, emissive flashes and translucent smoke, no combat changes")
    quit(0)
