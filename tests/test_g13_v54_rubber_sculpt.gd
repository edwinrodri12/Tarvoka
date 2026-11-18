extends SceneTree

# Verify real 3D tyre carcass + tread sculpture at hero LOD13.
# Never substitute a screenshot, extra draw object, or change wheel poses.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V53=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
var failures:int=0

func check(ok:bool, reason:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V54 genuine rubber: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in [0,3,7]:
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"cannot build hero faction %d" % faction)
        if hero==null:
            continue
        # Restore exact old V54 geometry before auditing its 6 lugs/pad.
        # The live V59 intentionally has 20 lugs/pad instead.
        if bool(hero.get_meta(V60.FLAG,false)):
            check(V60.show_finish(hero,false),
                "reveal V59 before historical V54 proof")
        if bool(hero.get_meta(V59.FLAG,false)):
            check(V59.show_finish(hero,false),
                "historic V54 must first remove newer V59 meshes and shaders")
        check(bool(hero.get_meta(V53.FLAG,false)) and
            bool(hero.get_meta(V54.FLAG,false)),
            "V53 PBR and V54 sculpt both required")
        var wheels:=hero.find_child(V54.TIRE,true,false) as MultiMeshInstance3D
        var blocks:=hero.find_child(V54.LUGS,true,false) as MultiMeshInstance3D
        check(wheels!=null and blocks!=null,
            "existing GPU wheel and tread nodes remain in place")
        if wheels!=null and blocks!=null and wheels.multimesh!=null and (
                blocks.multimesh!=null):
            var sculpted:Mesh=wheels.multimesh.mesh
            var lugs:Mesh=blocks.multimesh.mesh
            check(sculpted is ArrayMesh and lugs is ArrayMesh,
                "real rounded ArrayMesh rather than flat cylinders")
            check(sculpted.get_faces().size()>=400*3,
                "continuous rubber shoulder sculpture has full geometry")
            check(lugs.get_faces().size()==V54.LUGS_PER_TREAD_BATCH*12*3,
                "six separate 3D rubber lugs per original tread pad")
            check(wheels.multimesh.instance_count==4 and
                blocks.multimesh.instance_count==32,
                "four wheel / 32 pad instances unchanged")
            var bound:AABB=sculpted.get_aabb()
            check(absf(bound.size.y-0.24)<0.002 and
                absf(bound.size.x-0.62)<0.012,
                "approved 0.24m width and 0.31m radius preserved")
            var mat:=wheels.material_override as StandardMaterial3D
            var padmat:=blocks.material_override as StandardMaterial3D
            check(mat!=null and padmat!=null and
                mat.metallic<0.01 and padmat.metallic<0.01,
                "real matte rubber material inherited from V53")
            check(V54.show_finish(hero,false) and
                wheels.multimesh.mesh is CylinderMesh and
                blocks.multimesh.mesh is BoxMesh,
                "same-scene comparison must restore original tires")
            check(V54.show_finish(hero,true) and
                wheels.multimesh.mesh==sculpted and
                blocks.multimesh.mesh==lugs,
                "same-scene comparison must restore V54 sculpture")
            var before:=wheels.multimesh.get_instance_transform(0)
            check(Models.pose_model("aa_mobile",hero,"move",0.42),
                "original moving pose still operates")
            check(not wheels.multimesh.get_instance_transform(0
                ).is_equal_approx(before),
                "native rounded tires actually roll")
            Models.restore_model_pose("aa_mobile",hero)
            check(wheels.multimesh.mesh==sculpted,
                "pose and restore cannot lose the sculpted rubber")
        if bool(hero.get_meta(V59.FLAG,false)):
            check(V59.show_finish(hero,true),
                "restore premium V59 after historical V54 inspection")
        if bool(hero.get_meta(V60.FLAG,false)):
            check(V60.show_finish(hero,true),
                "restore V60 after V54")
        hero.free()
        var light:=Models.build("aa_mobile",faction,true,8)
        check(light!=null,"LOD8 must still build")
        if light!=null:
            # A live V59 tactical wheel is intentionally no longer a flat
            # cylinder; temporarily expose V54-era Android reference.
            if bool(light.get_meta(V60.FLAG,false)):
                check(V60.show_finish(light,false),
                    "V60 Android hidden during V54 comparison")
            if bool(light.get_meta(V59.FLAG,false)):
                check(V59.show_finish(light,false),
                    "restore exact old tactical tire for V54 era inspection")
            check(not bool(light.get_meta(V54.FLAG,false)),
                "Android LOD8 mesh budget stays completely unchanged")
            var tire:=light.find_child(G13.WHEELS,true,false) as MultiMeshInstance3D
            check(tire!=null and tire.multimesh!=null and
                tire.multimesh.mesh is CylinderMesh,
                "LOD8 native original tyre cylinder must remain")
            if bool(light.get_meta(V59.FLAG,false)):
                check(V59.show_finish(light,true),
                    "reapply V59 superior tactical tire after V54 audit")
            if bool(light.get_meta(V60.FLAG,false)):
                check(V60.show_finish(light,true),
                    "restore V60 tactical surface")
            light.free()
    if failures==0:
        print("PASS G13 V54 RUBBER: 3 hero factions, 4 rounded wheels, 192 authentic tread lugs, reversible V53 comparison, rolling and LOD8 unchanged")
    quit(1 if failures>0 else 0)
