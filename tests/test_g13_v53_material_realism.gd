extends SceneTree

# Real native Godot 4.3 regression: V53 materials, G13 shape and 8 factions.
# Validates BOTH hero LOD13 and tactical LOD8, with no gameplay changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Realism=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
var problems:int=0

func _check(ok:bool,description:String)->void:
    if not ok:
        problems+=1
        push_error("G13 V53: "+description)

func _material(root:Node3D,part_name:String)->StandardMaterial3D:
    var part:=root.find_child(part_name,true,false) as GeometryInstance3D
    if part==null:
        return null
    return part.material_override as StandardMaterial3D

func _run()->void:
    for lod in [8,13]:
        for faction in [0,3,7]:
            var model:=Models.build("aa_mobile",faction,true,lod)
            _check(model!=null,"cannot build LOD%d faction %d" % [lod,faction])
            if model==null:
                continue
            _check(bool(model.get_meta(Realism.FLAG,false)),
                "V53 missing LOD%d faction %d" % [lod,faction])
            # V59 is newer than V55 and intentionally boosts official enamel
            # hues. Verify old V53 on its own original 3D material snapshot:
            # remove the V59 overlay FIRST, never weaken the old QA rules.
            if bool(model.get_meta(V60.FLAG,false)):
                _check(V60.show_finish(model,false),
                    "V60 hidden during historical V53 proof")
            if bool(model.get_meta(V59.FLAG,false)):
                _check(V59.show_finish(model,false),
                    "cannot restore historical V58 before native V53 QA")
            # V55 is the later hero PBR layer; reveal the historic V53
            # materials before checking exact original faction hue.
            if lod==13 and bool(model.get_meta(V55.FLAG,false)):
                _check(V55.show_finish(model,false),
                    "cannot expose historical V53 material for comparison")
            _check(bool(model.get_meta(
                "tarvoka_g13_v53_no_new_draw_nodes",false)),
                "extra draw nodes not permitted")
            var tire:=_material(model,"G13_Ruedas4x4MultiMesh")
            var wall:=_material(model,"G13_V7_Sidewalls")
            var tread:=_material(model,"G13_V7_TreadBlocks")
            var alloy:=_material(model,"G13_V46_MachinedArmoredHubCaps")
            var armored:=_material(model,"G13_LowerMonocoque")
            var stripe:=_material(model,"G13_TurretFaction_1")
            _check(tire!=null,"tire material missing on LOD%d" % lod)
            if lod==13:
                _check(wall!=null and tread!=null,
                    "hero wheel sidewalls/tread materials missing")
            _check(alloy!=null and armored!=null and stripe!=null,
                "missing metal or faction finishes")
            var rubber_parts: Array = [tire]
            if wall!=null:
                rubber_parts.append(wall)
            if tread!=null:
                rubber_parts.append(tread)
            for rubber in rubber_parts:
                if rubber==null:
                    continue
                _check(rubber.metallic<0.01 and rubber.roughness>0.85,
                    "wheel rubber must be non-metallic and diffuse")
                _check(rubber.normal_enabled and rubber.normal_texture!=null,
                    "wheel rubber must show a micro normal surface")
            if alloy!=null:
                _check(alloy.metallic>0.75 and alloy.roughness<0.35,
                    "machined hub must reflect like actual alloy")
            if armored!=null:
                _check(armored.metallic>0.45,
                    "main armored body needs metallic response")
            if stripe!=null:
                var color:Color=stripe.albedo_color
                _check(Realism.show_finish(model,false),
                    "comparison could not restore original materials")
                _check(Realism.show_finish(model,true),
                    "comparison could not reapply V53 materials")
                var refreshed:=_material(model,"G13_TurretFaction_1")
                _check(refreshed!=null and refreshed.albedo_color==color,
                    "G13 faction palette was changed")
            _check(model.find_child("G13_Autocannon_-1",true,false)!=null and
                model.find_child("G13_Autocannon_1",true,false)!=null,
                "twin cannons must remain, not replaced with missiles")
            if lod==13 and bool(model.get_meta(V55.FLAG,false)):
                _check(V55.show_finish(model,true),
                    "V55 final coating must be restored after V53 audit")
            if bool(model.get_meta(V59.FLAG,false)):
                _check(V59.show_finish(model,true),
                    "G13 V59 real tire/glass/faction finish must restore after V53 QA")
            if bool(model.get_meta(V60.FLAG,false)):
                _check(V60.show_finish(model,true),
                    "V60 3D tire restored after old V53 QA")
            model.free()
    if problems==0:
        print("PASS G13 V53 PBR METAL RUBBER: 6 real native variants")
    quit(1 if problems>0 else 0)

func _initialize()->void:
    call_deferred("_run")
