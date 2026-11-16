extends SceneTree

# G13 V8 material regression, render-only, no BattleSession modifications.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/G13SurfaceFinishV8.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var failures:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failures+=1
        push_error("G13 V8 surface: "+why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var palettes: Dictionary={}
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero build faction %d" % faction)
        if hero==null:
            continue
        check(bool(hero.get_meta(Finish.FLAG,false)),
            "V8 PBR applied to hero")
        var paint:=hero.find_child("G13_V2_RoofFaction",true,false) as MeshInstance3D
        var glass:=hero.find_child("G13_FrontGlass_1",true,false) as MeshInstance3D
        var flash:=hero.find_child("G13_FlashCone_1",true,false) as MeshInstance3D
        check(paint!=null and glass!=null and flash!=null,
            "faction, optics and flash meshes exist")
        if paint!=null:
            var pm:=paint.material_override as StandardMaterial3D
            check(pm!=null and pm.metallic>0.2 and pm.roughness>0.4,
                "paint has authored durable armor coat")
            if pm!=null:
                palettes[pm.albedo_color.to_html()]=true
        if glass!=null:
            var gm:=glass.material_override as StandardMaterial3D
            check(gm!=null and gm.roughness<0.35,
                "optics distinguishable from rough armor")
        if flash!=null:
            var fm:=flash.material_override as StandardMaterial3D
            check(fm!=null and fm.emission_enabled,
                "muzzle flash has emissive material")
        var meshes:=Models.inspect_meshes(hero)
        check(not Finish.apply(hero,Color.WHITE),
            "finish refuses duplicate application")
        check(Models.inspect_meshes(hero)==meshes,
            "materials create no new meshes")
        check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
            "ground attack still animates")
        Models.restore_model_pose("aa_mobile",hero)
        check(Models.inspect_meshes(hero)==meshes,
            "animation and reset preserve mesh count")
        hero.free()
        var low:=Models.build("aa_mobile",faction,true,8)
        check(low!=null,"mobile LOD remains buildable")
        if low!=null:
            check(not bool(low.get_meta(Finish.FLAG,false)),
                "mobile LOD does not pay for hero materials")
            low.free()
    check(palettes.size()==8,"eight faction paint tones still distinct")
    var packed:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(packed!=null,"inspection scene loads")
    if packed!=null:
        var studio:=packed.instantiate() as Control
        root.add_child(studio)
        await process_frame
        var fill:=studio.find_child("G13_V8_InspectionFill",true,false) as DirectionalLight3D
        check(fill!=null and not fill.shadow_enabled,
            "inspection fill is lightweight and shadowless")
        studio.queue_free()
        await process_frame
    if failures>0:
        quit(1)
        return
    print("PASS G13 V8: eight faction coats, optics, muzzle emission, mobile LOD isolation")
    quit(0)
