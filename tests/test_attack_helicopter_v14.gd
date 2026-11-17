extends SceneTree

# HAT-29 V14 native Godot regression: all eight factions, staged V13 damage,
# genuinely visible bullet/missile effects and a separately flying rocket.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const Coat = preload("res://scripts/ui/AttackHelicopterFactionV14.gd")
const FX = preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
var failures: int=0

func _check(condition: bool,reason: String) -> void:
    if not condition:
        failures+=1
        push_error("HAT29 V14: "+reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not Coat.has_model(tactical)
        and not FX.has_model(tactical)
        and (tactical==null or tactical.find_child(Coat.DETAIL_ROOT,true,false)==null),
        "Android battle LOD10 never receives hero paint, hardware or particles")
    if tactical!=null:
        tactical.free()
    var colors: Array[Color]=[]
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"A01 hero model built for army "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V13.has_model(model) and Coat.has_model(model)
            and FX.has_model(model),"all actual V13 and V14 layers coexist")
        _check(int(model.get_meta("a01_v14_faction_painted_count",0))>=9,
            "at least nine larger faction-colored parts, not tiny decals")
        var hull: MeshInstance3D=model.find_child(
            "A01_V2_Casco12CarasCerrado",true,false) as MeshInstance3D
        var main_color: Color=Color.TRANSPARENT
        if hull!=null and hull.material_override is StandardMaterial3D:
            main_color=(hull.material_override as StandardMaterial3D).albedo_color
            colors.append(main_color)
        _check(main_color.a>0.9,
            "large actual V2 hull carries enamel for army "+str(faction))
        var muted: Color=Color("#32444e").lerp(
            Models.faction_paint_color(faction),0.52)
        _check(main_color.is_equal_approx(muted),
            "HAT-29 hull has deliberately muted official faction paint")
        var door_seam: MeshInstance3D=model.find_child(
            "A01V14_1_DoorTop_1",true,false) as MeshInstance3D
        var hinge: MeshInstance3D=model.find_child(
            "A01V14_1_DoorHinge_-1_0",true,false) as MeshInstance3D
        var service: MeshInstance3D=model.find_child(
            "A01V14_1_EngineServicePlate_1",true,false) as MeshInstance3D
        var tail_clamp: MeshInstance3D=model.find_child(
            "A01V14_1_TailClamp_-1_1",true,false) as MeshInstance3D
        _check(door_seam!=null and door_seam.mesh is BoxMesh
            and hinge!=null and hinge.mesh is BoxMesh
            and service!=null and service.mesh is BoxMesh
            and tail_clamp!=null and tail_clamp.mesh is BoxMesh,
            "new real 3D panel seams, hinges, engine hatch and tail clamps")
        var belly: MeshInstance3D=model.find_child(
            "A01V14_2_PlacaVentralOctagonal",true,false) as MeshInstance3D
        var vent: MeshInstance3D=model.find_child(
            "A01V14_2_MotorLouver_1_1",true,false) as MeshInstance3D
        var service_panel: MeshInstance3D=model.find_child(
            "A01V14_2_TailServicePanel_-1",true,false) as MeshInstance3D
        var tail_bolt: MeshInstance3D=model.find_child(
            "A01V14_2_TailServiceBolt_1_1",true,false) as MeshInstance3D
        _check(belly!=null and belly.mesh is ArrayMesh
            and belly.mesh.get_surface_count()==1
            and vent!=null and vent.mesh is BoxMesh
            and service_panel!=null and service_panel.mesh is BoxMesh
            and tail_bolt!=null and tail_bolt.mesh is CylinderMesh,
            "V14.2 closed ventral hatch, visible motor vents and tail service bolts")
        _check(belly!=null and belly.position.y<0.66
            and service_panel!=null and service_panel.position.z>1.80,
            "V14.2 sculpture correctly mounted below hull and on aft boom")
        var gasket_count: int=0
        for i in range(8):
            var gasket: MeshInstance3D=model.find_child(
                "A01V14_2_Gasket_%d" % i,true,false) as MeshInstance3D
            if gasket!=null and gasket.mesh is CylinderMesh:
                _check(absf(gasket.position.y-0.574)<0.001,
                    "V14.2.1 gasket sits below the original hatch surface")
                gasket_count+=1
        _check(gasket_count==8,
            "V14.2.1 octagonal hatch has all eight physical perimeter segments")
        for side in [-1,1]:
            for index in range(3):
                var screw: MeshInstance3D=model.find_child(
                    "A01V14_2_VentralBolt_%d_%d" % [side,index],true,false) as MeshInstance3D
                _check(screw!=null and screw.mesh is CylinderMesh
                    and screw.rotation_degrees.is_equal_approx(Vector3.ZERO)
                    and screw.position.y<belly.position.y-0.04,
                    "V14.2.1 underside screw axis points outward, not sideways")
        # V14.3 material and geometry are distinct from the existing enamel:
        # brushed alloy on the engines, neoprene on doors/tail, no recoloring.
        for side in [-1,1]:
            var heat: MeshInstance3D=model.find_child(
                "A01V14_3_EscudoTermico_%d" % side,true,false) as MeshInstance3D
            var seal: MeshInstance3D=model.find_child(
                "A01V14_3_JuntaPuerta_%d" % side,true,false) as MeshInstance3D
            var latch: MeshInstance3D=model.find_child(
                "A01V14_3_CierreCola_%d_1" % side,true,false) as MeshInstance3D
            var tail_seal: MeshInstance3D=model.find_child(
                "A01V14_3_SelloRegistroCola_%d" % side,true,false) as MeshInstance3D
            _check(heat!=null and heat.mesh is BoxMesh
                and seal!=null and seal.mesh is BoxMesh
                and latch!=null and latch.mesh is BoxMesh
                and tail_seal!=null and tail_seal.mesh is BoxMesh,
                "V14.3 independent 3D metallic engine shields and weather seals")
            if heat!=null and seal!=null:
                var hm: StandardMaterial3D=heat.material_override as StandardMaterial3D
                var sm: StandardMaterial3D=seal.material_override as StandardMaterial3D
                _check(hm!=null and sm!=null and hm.metallic>0.60
                    and hm.roughness<0.50 and sm.metallic<0.10
                    and sm.roughness>0.85,
                    "V14.3 brushed alloy versus matte rubber physically distinct")
        _check(str(model.get_meta("a01_v14_coat_revision",""))=="muted_tactical_v14_3",
            "V14.3 retains all eight approved muted-faction finishes")
        _check(Coat.apply(model,Models.faction_paint_color(faction))
            and FX.apply(model),
            "V14 coating and effect builders are idempotent")

        var bullets: Node3D=model.find_child(FX.BULLETS,true,false) as Node3D
        var missile: Node3D=model.find_child(FX.MISSILE_HIT,true,false) as Node3D
        var rockets: Node3D=model.find_child(FX.MISSILES,true,false) as Node3D
        V13.pose(model,"hit_bullet",0.34)
        FX.pose(model,"hit_bullet",0.34)
        var sparks: int=0
        for child in bullets.get_children():
            if (child as Node3D).visible:
                sparks+=1
        _check(sparks>=1 and not missile.visible,
            "ricochets pulse without setting off missile explosion")
        V13.pose(model,"hit_explosive",0.34)
        FX.pose(model,"hit_explosive",0.34)
        var ring: Node3D=model.find_child(
            "A01V14_AnilloPresionMisil",true,false) as Node3D
        _check(missile.visible and ring!=null and ring.visible
            and ring.scale.x>1.0 and not bullets.visible,
            "missile hit shows physical pressure ring, flash and shrapnel")
        V13.pose(model,"hover",0.58)
        FX.pose(model,"fire_missiles",0.58)
        var flying: int=0
        for rocket in rockets.get_children():
            if (rocket as Node3D).visible:
                flying+=1
        _check(flying==2 and not missile.visible and not bullets.visible,
            "two staggered physical missiles detach from wing launchers")
        FX.pose(model,"idle",0.0)
        _check(not rockets.visible and not missile.visible
            and not bullets.visible,"all temporary V14 effects clear on idle")
        _check(V13.set_stage(model,3) and V13.stage(model)==3,
            "old V13 critical engine fire persists")
        V13.set_stage(model,4)
        _check(V13.pose(model,"destroy",1.0) and V13.stage(model)==4,
            "old rotor break and airborne crash remain intact")
        V13.restore(model)
        _check(V13.set_stage(model,0) and V13.stage(model)==0,
            "wreck is completely repairable after V14 effect playback")
        model.free()
    _check(colors.size()==8,"all eight aircraft have real colored hulls")
    if colors.size()==8:
        for i in range(8):
            for j in range(i+1,8):
                _check((absf(colors[i].r-colors[j].r)+absf(colors[i].g-colors[j].g)+absf(colors[i].b-colors[j].b))>0.08,
                    "distinct official faction hues "+str(i)+" / "+str(j))
    if failures>0:
        push_error("HAT29 V14: "+str(failures)+" failures")
        quit(1)
    else:
        print("PASS HAT29 V14: 8 muted factions and sculpted hardware; bullets, missile blast, dual flying rockets, unchanged mobile LOD and reversible V13 destruction")
        quit(0)
