extends SceneTree

# Real native Godot 4.3 regression: V53 materials, G13 shape and 8 factions.
# Validates BOTH hero LOD13 and tactical LOD8, with no gameplay changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Realism=preload("res://scripts/ui/G13MaterialRealismV53.gd")
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
            _check(bool(model.get_meta(
                "tarvoka_g13_v53_no_new_draw_nodes",false)),
                "extra draw nodes not permitted")
            var tire:=_material(model,"G13_Ruedas4x4MultiMesh")
            var wall:=_material(model,"G13_V7_Sidewalls")
            var tread:=_material(model,"G13_V7_TreadBlocks")
            var alloy:=_material(model,"G13_V46_MachinedArmoredHubCaps")
            var armored:=_material(model,"G13_LowerMonocoque")
            var stripe:=_material(model,"G13_TurretFaction_1")
            _check(tire!=null and wall!=null and tread!=null,
                "missing non-metallic wheel materials")
            _check(alloy!=null and armored!=null and stripe!=null,
                "missing metal or faction finishes")
            if tire!=null and wall!=null and tread!=null:
                for rubber in [tire,wall,tread]:
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
            model.free()
    if problems==0:
        print("PASS G13 V53 PBR METAL RUBBER: 6 real native variants")
    quit(1 if problems>0 else 0)

func _initialize()->void:
    call_deferred("_run")
