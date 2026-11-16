extends SceneTree

# G13 V5 numeric clearance regression. Native MeshInstance3D shapes, not mockups.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var failures:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failures+=1
        push_error("G13 V5 geometry: "+why)

func part(root: Node,name: String)->MeshInstance3D:
    return root.find_child(name,true,false) as MeshInstance3D

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var paints: Dictionary={}
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,13)
        check(model!=null,"hero G13 exists faction %d" % faction)
        if model==null:
            continue
        var casing:=part(model,"G13_RemoteWeaponHousing")
        check(casing!=null,"original turret housing exists")
        if casing==null:
            model.free()
            continue
        var half_width: float=(casing.mesh as BoxMesh).size.x/2.0
        for side in [-1,1]:
            var cheek:=part(model,"G13_V2_TurretCheek_%d" % side)
            var insignia:=part(model,"G13_V2_TurretInsignia_%d" % side)
            check(cheek!=null and insignia!=null,
                "turret cheeks and insignias exist both sides")
            if cheek!=null and insignia!=null:
                var cheek_half: float=(cheek.mesh as BoxMesh).size.x/2.0
                var insignia_half: float=(insignia.mesh as BoxMesh).size.x/2.0
                check(absf(cheek.position.x)+cheek_half>half_width+0.05,
                    "cheek reaches beyond V1 housing instead of buried")
                check(absf(insignia.position.x)+insignia_half>
                    absf(cheek.position.x)+cheek_half+0.01,
                    "faction insignia appears on exterior cheek")
                var material:=insignia.material_override as StandardMaterial3D
                if material!=null:
                    paints[material.albedo_color.to_html()]=true
            for axle in [-1,1]:
                var fender:=part(model,"G13_V2_Fender_%d_%d" % [side,axle])
                var trim:=part(model,"G13_V2_FenderTrim_%d_%d" % [side,axle])
                check(fender!=null and trim!=null,"wheel cover & trim exist")
                if fender!=null and trim!=null:
                    var crown: float=G13.WHEEL_Y+G13.WHEEL_RADIUS
                    var fender_bottom: float=fender.position.y-(
                        fender.mesh as BoxMesh).size.y/2.0
                    var trim_bottom: float=trim.position.y-(
                        trim.mesh as BoxMesh).size.y/2.0
                    check(fender_bottom>crown+0.025,
                        "fender roof clears spinning tyre")
                    check(trim_bottom>=crown+0.005,
                        "outer trim clears spinning tyre")
        var wheel:=model.find_child(G13.WHEELS,true,false) as MultiMeshInstance3D
        check(wheel!=null and wheel.multimesh.instance_count==4,
            "four wheel GPU instances retained")
        model.free()
    check(paints.size()==8,"all eight faction colors remain distinct")
    var scene:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(scene!=null,"V5 inspection scene available")
    if scene!=null:
        var studio:=scene.instantiate() as Control
        root.add_child(studio)
        await process_frame
        var cam:=studio.get("camera") as Camera3D
        for view in ["front","rear","left","right","top","under","iso"]:
            studio.call("_inspect_view",view)
            check(cam!=null and cam.position.is_finite() and
                cam.global_transform.basis.is_finite(),
                "finite camera orientation in view "+view)
        studio.queue_free()
        await process_frame
    if failures>0:
        quit(1)
        return
    print("PASS G13 V5 geometry: exposed painted turret cheeks, eight factions, four wheels, clear fenders and seven 3D inspection angles")
    quit(0)
