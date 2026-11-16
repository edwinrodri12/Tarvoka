extends SceneTree

# Godot 4.3 regression: actual V6 mechanical train/engine seam and true
# reversibility; eight factions; unchanged battle LOD, rotors, gun and poses.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V5=preload("res://scripts/ui/AttackHelicopterLandingV5.gd")
const V6=preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
var failures: int=0

func _check(ok: bool, why: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V6: "+why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not V6.has_model(tactical),
        "existing mobile battle LOD does not pay for V6 meshes")
    if tactical!=null:
        tactical.free()
    var paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"hero renders for faction "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V1.has_model(model) and V4.has_model(model) and
            V5.has_model(model) and V6.has_model(model),
            "prior versions are intact and V6 mechanical layer is present")
        if not V6.has_model(model):
            model.queue_free()
            await process_frame
            continue
        var layer: Node3D=model.find_child(V6.ROOT,true,false) as Node3D
        _check(layer!=null and layer.is_visible_in_tree(),
            "mechanical finish is actually visible")
        var n: int=Models.inspect_meshes(model)
        _check(n>220,"physical V6 joints, pads, mount seams are actual meshes")
        for side in [-1,1]:
            var old_grip: Node3D=model.find_child(
                "A01V5_BandaGomaAntideslizante_"+str(side),
                true,false) as Node3D
            _check(old_grip!=null and not old_grip.visible,
                "old long box rubber strip hidden, not doubled")
            _check(model.find_child(V5.SKID+str(side),true,false)!=null,
                "continuous curved V5 rail itself retained")
            for index in range(4):
                var pad: MeshInstance3D=model.find_child(
                    V6.GRIP+"%d_%d" % [side,index],
                    true,false) as MeshInstance3D
                _check(pad!=null and pad.mesh is ArrayMesh,
                    "each curved-side grip pad is true polygonal solid")
            for index in range(2):
                var label: String="%d_%d" % [side,index]
                var old_upper: Node3D=model.find_child(
                    "A01V5_AnclajeSuperior_"+label,true,false) as Node3D
                var old_lower: Node3D=model.find_child(
                    "A01V5_CodoInferior_"+label,true,false) as Node3D
                _check(old_upper!=null and old_lower!=null
                    and not old_upper.visible and not old_lower.visible,
                    "oversized old joint spheres hidden")
                var damper: MeshInstance3D=model.find_child(
                    V6.DAMPER+label,true,false) as MeshInstance3D
                var piston: MeshInstance3D=model.find_child(
                    V6.PISTON+label,true,false) as MeshInstance3D
                _check(damper!=null and piston!=null
                    and damper.mesh is CylinderMesh
                    and piston.mesh is CylinderMesh,
                    "real telescopic damper and polished piston, not flat decals")
                if damper!=null and piston!=null:
                    _check((damper.mesh as CylinderMesh).height>0.17
                        and (piston.mesh as CylinderMesh).height>0.15,
                        "damper telescopes have visible mechanical lengths")
                for name in [V6.UPPER_PIN+label,V6.LOWER_PIN+label,
                        "A01V6_CollarSuperior_"+label,
                        "A01V6_CollarInferior_"+label]:
                    _check(model.find_child(name,true,false)!=null,
                        "pins/collars physically present: "+name)
                _check(model.find_child(V6.CLAMP+label,true,false)!=null,
                    "clamp grips existing round rail at each mount")
            var n_seams: int=0
            for index in range(V6.SEGMENTS):
                if model.find_child(V6.ENGINE_SEAM+
                        ("%d_%02d" % [side,index]),true,false)!=null:
                    n_seams+=1
            _check(n_seams==V6.SEGMENTS,
                "continuous 16-link engine shoulder ring without missing sections")
            var mark: MeshInstance3D=model.find_child(
                "A01V6_MarcaMantenimiento_"+str(side),
                true,false) as MeshInstance3D
            _check(mark!=null and mark.material_override is StandardMaterial3D,
                "subtle faction marking survives new grip plates")
            if side==1 and mark!=null and mark.material_override is StandardMaterial3D:
                paints[(mark.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        _check(V6.apply(model,Models.faction_paint_color(faction)),
            "V6 idempotently applies")
        _check(Models.inspect_meshes(model)==n,
            "no new geometry after repeated V6 apply")
        _check(V6.set_enabled(model,false),
            "true previous V5 preview can be re-enabled")
        _check(not layer.visible,
            "V6 geometry hidden on previous-version comparison")
        _check((model.find_child(
            "A01V5_AnclajeSuperior_1_0",true,false) as Node3D).visible,
            "earlier V5 upper joint returns when comparing")
        _check((model.find_child(
            "A01V5_BandaGomaAntideslizante_1",true,false) as Node3D).visible,
            "earlier V5 grip strip returns when comparing")
        _check(V6.set_enabled(model,true),
            "new small joinery can return without overlaps")
        _check(layer.visible,"V6 detail comes back")
        var start: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.42),
            "main/tail rotor remains animatable with V6")
        _check(Models.pose_model("attack_heli",model,"attack",0.33),
            "cannon firing pose remains animatable with V6")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==start and layer.visible,
            "return to rest leaves train geometry intact")
        model.queue_free()
        await process_frame
    _check(paints.size()==8,
        "eight paint palettes still have distinct small vehicle markings")
    if failures>0:
        push_error("A01 V6: %d failed geometry/regression checks" % failures)
        quit(1)
        return
    print("PASS A01 V6: 8 factions, 4 telescopic landing shocks, 8 machined hinge pins, 8 rail clamps, 8 short real-rubber pads, 32 engine weld-seam segments, safe V5 comparison and unchanged battle LOD")
    quit(0)
