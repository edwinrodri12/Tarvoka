extends SceneTree

# V2 native Godot tests for TWO visual attack modes in one G13.
# No invented combat damage, SAM rockets or new game unit IDs.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Dual=preload("res://scripts/ui/G13DualDomainVisualV2.gd")
const G11Audit=preload("res://scripts/ui/G11FinalAuditV33.gd")
var errors: int=0

func _check(ok: bool,label: String)->void:
    if not ok:
        errors+=1
        push_error("G13 V2 ground/air real 3D QA: "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    _check(Dual.GROUND_MAX_DEG<Dual.AIR_MIN_DEG,
        "ground elevation always visibly lower than air")
    _check(Dual.GROUND_BURSTS<Dual.AIR_BURSTS and
        Dual.RECOIL_M<=0.03,
        "ground and air have different cadence and bounded visual recoil")
    for faction in range(8):
        var g11:=Models.build("mlrs",faction,true,13)
        _check(g11!=null and G11Audit.verify_hero(g11),
            "G11 approved V33 locked art remains unchanged")
        if g11!=null:
            g11.free()
        for lod in [8,13]:
            var vehicle:=Models.build("aa_mobile",faction,true,lod)
            _check(vehicle!=null and G13.has_model(vehicle) and (
                bool(vehicle.get_meta(Dual.FLAG,false))),
                "original G13 V1 hull and eight faction colors remain compatible")
            if vehicle==null:
                continue
            var body_pose: Transform3D=vehicle.transform
            var original_meshes: int=Models.inspect_meshes(vehicle)
            var turret:=vehicle.find_child(
                G13.TURRET,true,false) as Node3D
            var gun:=vehicle.find_child(G13.GUNS,true,false) as Node3D
            var radar:=vehicle.find_child(G13.RADAR,true,false) as Node3D
            var flash:=vehicle.find_child(
                Dual.FLASH,true,false) as MultiMeshInstance3D
            _check(turret!=null and gun!=null and radar!=null and (
                flash!=null) and (
                flash.multimesh!=null) and (
                flash.multimesh.instance_count==2),
                "dual gun muzzle light is ONE pooled batch of two nozzles")
            if flash==null or gun==null or radar==null or turret==null:
                vehicle.free()
                continue
            var low_angle: float=0.0
            var high_angle: float=0.0
            for kind in [Dual.GROUND,Dual.AIR]:
                var t: float=0.70 if kind==Dual.GROUND else 0.63
                _check(Models.pose_model("aa_mobile",vehicle,kind,t),
                    "explicit "+kind+" supported as a visual-only mode")
                _check(str(vehicle.get_meta(Dual.MODE,""))==(
                    "ground" if kind==Dual.GROUND else "air"),
                    "mode name reflects selected firing domain")
                _check(flash.visible,
                    "short alternating muzzle flash visible during real salvo")
                _check(float(vehicle.get_meta(
                    "tarvoka_g13_v2_recoil_m",0))>0.0,
                    "individual barrel recoils briefly during burst")
                if kind==Dual.GROUND:
                    low_angle=gun.rotation_degrees.x
                    _check(low_angle>=Dual.GROUND_MIN_DEG and
                        low_angle<=Dual.GROUND_MAX_DEG,
                        "ground mode stays near horizon for light vehicles/infantry")
                    _check(absf(radar.rotation_degrees.y-6.0)<0.001,
                        "ground fire holds radar forward")
                else:
                    high_angle=gun.rotation_degrees.x
                    _check(high_angle>=Dual.AIR_MIN_DEG and
                        high_angle<=Dual.AIR_MAX_DEG,
                        "anti-air mode elevates against aircraft and drones")
                    _check(absf(radar.rotation_degrees.y)>1.0,
                        "air mode also tracks with independent radar")
                var transforms_seen: int=0
                for n in range(2):
                    if flash.multimesh.get_instance_transform(n
                            ).basis.determinant()>0.1:
                        transforms_seen+=1
                _check(transforms_seen==1,
                    "only one muzzle lights at a time in visual alternating fire")
                _check(vehicle.transform==body_pose and
                    Models.inspect_meshes(vehicle)==original_meshes,
                    "firing does not move hull or instantiate combat projectiles")
                Models.restore_model_pose("aa_mobile",vehicle)
                _check(not flash.visible and
                    not vehicle.has_meta(Dual.MODE),
                    "end of burst hides all effects and clears visual mode")
                for side in [-1,1]:
                    var barrel:=gun.find_child(
                        Dual.BARREL % side,false,false) as Node3D
                    _check(absf(barrel.position.z+0.66)<0.0001,
                        "existing cannons return to exact positions")
            _check(high_angle-low_angle>35.0,
                "same G13 has visually distinct ground and air trajectories")
            _check(not Models.pose_model(
                "aa_mobile",vehicle,"combat_aa",0.5),
                "no fake playable AA unit is activated by visual animations")
            vehicle.free()
    if errors>0:
        push_error("G13 V2 dual-domain art QA FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G13 V2: eight factions x two details, low-angle ground vs elevated air, radar tracking, reversible 2-nozzle flash/recoil, locked G11 and no combat changes")
    quit(0)
