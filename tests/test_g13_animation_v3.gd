extends SceneTree

# Art-only V3 regression: independent air/ground animations and reversible FX.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var failures:=0

func check(value: bool,desc: String)->void:
    if not value:
        failures+=1
        push_error("G13 V3: "+desc)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        for detail in [8,13]:
            var model:=Models.build("aa_mobile",faction,true,detail)
            check(model!=null,"model present")
            if model==null:
                continue
            var pitch:=model.find_child(G13.GUNS,true,false) as Node3D
            var turret:=model.find_child(G13.TURRET,true,false) as Node3D
            var radar:=model.find_child(G13.RADAR,true,false) as Node3D
            var count:=Models.inspect_meshes(model)
            check(Models.pose_model("aa_mobile",model,"aim_air",0.5),
                "air target pose available")
            check(absf(pitch.rotation_degrees.x-42.0)<0.01,
                "air pose has raised guns")
            check(Models.pose_model("aa_mobile",model,"aim_ground",0.5),
                "ground target pose available")
            check(absf(pitch.rotation_degrees.x-7.0)<0.01,
                "ground pose has low guns")
            check(Models.pose_model("aa_mobile",model,"attack_air",0.25,
                Vector2i(1,0)),"air burst available")
            check(absf(turret.rotation_degrees.y-90.0)<0.01,
                "bearing follows requested heading")
            check(radar.rotation_degrees.y!=turret.rotation_degrees.y,
                "radar is independent")
            var flash_a:=model.find_child(
                "G13_MuzzleFlash_-1",true,false) as Node3D
            var flash_b:=model.find_child(
                "G13_MuzzleFlash_1",true,false) as Node3D
            check(flash_a!=null and flash_b!=null,"both muzzle effects exist")
            if flash_a!=null and flash_b!=null:
                check(flash_a.visible!=flash_b.visible,
                    "alternating bursts rather than simultaneous flashes")
            check(Models.pose_model("aa_mobile",model,
                "attack_ground",0.42),"ground burst available")
            check(pitch.rotation_degrees.x<12.0,
                "ground burst not fired at aircraft elevation")
            Models.restore_model_pose("aa_mobile",model)
            check(absf(pitch.rotation_degrees.x-12.0)<0.01,
                "restore sets neutral elevation")
            if flash_a!=null and flash_b!=null:
                check(not flash_a.visible and not flash_b.visible,
                    "restore removes all visible flashes")
            check(count==Models.inspect_meshes(model),
                "pose creates no runtime mesh nodes")
            check(not Models.pose_model("aa_mobile",model,
                "combat_aa",0.5),"no unsupported game combat action")
            model.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V3: independent air and ground burst poses, eight factions, two LODs, no game combat state")
    quit(0)
