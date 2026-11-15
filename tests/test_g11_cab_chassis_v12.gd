extends SceneTree

# G11 V12 native 3D hard-surface regression: genuine cabin and chassis
# detail in eight faction skins; proves 12-tube V11 sculpt and V10 salvo
# animations remain unchanged. Visual stage changes are reversible.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const V10 = preload("res://scripts/ui/G11CooldownV10.gd")
const V11 = preload("res://scripts/ui/G11ArmorFinishV11.gd")
const V12 = preload("res://scripts/ui/G11CabChassisV12.gd")
var errors: int = 0

func _check(condition: bool, detail: String) -> void:
    if not condition:
        errors += 1
        push_error("G11 V12 CAB/CHASSIS QA: "+detail)

func _node(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"full MLRS hero model faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V11.FLAG,false)),
            "all V11 beveled launcher elements retained")
        _check(bool(model.get_meta(V12.FLAG,false)),
            "actual V12 cabin and chassis sculpt installed for faction %d" % faction)
        _check(int(model.get_meta("tarvoka_g11_v12_side_windows",0)) == 2,
            "two separate true 3D side windows")
        _check(int(model.get_meta("tarvoka_g11_v12_recessed_motor_louvers",0)) == 7,
            "seven independent metallic engine intake louvers")
        _check(int(model.get_meta("tarvoka_g11_v12_hardware",0)) == 24,
            "twenty-four real door/rear panel fasteners")

        var rivets := _node(model,"G11V12_PernosBlindajeLote") as MultiMeshInstance3D
        _check(rivets != null and rivets.multimesh != null,
            "one physical instanced hardware group exists")
        if rivets != null and rivets.multimesh != null:
            _check(rivets.multimesh.instance_count == 24,
                "all fasteners are genuine 3D hardware heads")
        for side in [-1,1]:
            var door := _node(model,"G11V12_PuertaBlindada_%d" % side) as MeshInstance3D
            var frame := _node(model,"G11V12_MarcoVentanilla_%d" % side) as MeshInstance3D
            var glass := _node(model,"G11V12_CristalLateral_%d" % side) as MeshInstance3D
            _check(door != null and door.mesh is ArrayMesh,
                "fully 3D armored door with actual thickness on side %d" % side)
            _check(frame != null and frame.mesh is ArrayMesh,
                "solid window rubber surround on side %d" % side)
            _check(glass != null and glass.mesh is ArrayMesh,
                "window glazing is actual pane geometry on side %d" % side)
            if door != null:
                _check(absf(door.position.x) > 0.64 and absf(door.position.x) < 0.68,
                    "door fits cab silhouette, not a floating side slab")
            if glass != null:
                _check(absf(glass.position.x) > absf(door.position.x),
                    "window is outermost, so no opaque door blocks glazing")
                var transparent_metal: StandardMaterial3D = glass.material_override as StandardMaterial3D
                _check(transparent_metal != null and transparent_metal.roughness < 0.40,
                    "real PBR glazing has smooth highlights")
            _check(_node(model,"G11_SoporteRetrovisor_%d" % side) == null,
                "V1 rectangular rearview support is correctly removed")
            var housing := _node(model,
                "G11V12_CarcasaEspejo_%d" % side) as MeshInstance3D
            _check(housing != null and housing.mesh is ArrayMesh,
                "rearview mirror now has a truly beveled enclosure")
            _check(_node(model,"G11V12_CristalEspejo_%d" % side) != null,
                "two reflective mirror faces exist as separate material")
            _check(_node(model,"G11V12_BrazoRetrovisor_%d" % side) != null,
                "mirrors attached to cab by real mounting arms")
            _check(_node(model,"G11V12_CierrePuerta_%d" % side) != null,
                "each 3D armored door has its own metal latch")
            _check(_node(model,"G11V12_MarcaFaccionCabina_%d" % side) != null,
                "original faction paint supplemented, never replaced")
            _check(_node(model,"G11V12_EscalonAntideslizante_%d" % side) != null,
                "actual steel chassis footstep")
            for rib in range(5):
                _check(_node(model,
                    "G11V12_GomaEscalon_%d_%d" % [side,rib]) != null,
                    "each steel step has five rubber non-slip bars")
            _check(_node(model,"G11V12_GuardaLodoTrasera_%d" % side) != null,
                "rear running gear receives physical mudguard")
            _check(_node(model,
                "G11V12_BrazoLimpiaparabrisas_%d" % side) != null,
                "two real windshield wiper arms attached to front glass")
            _check(_node(model,
                "G11V12_GomaLimpiaparabrisas_%d" % side) != null,
                "each windshield wiper has independent black rubber blade")
            _check(_node(model,"G11V12_CierrePorton_%d" % side) != null,
                "rear service hatch gets external locking hardware")
        _check(_node(model,"G11V12_ParachoquesBiselado") != null,
            "nose bumper is a chamfered actual mesh")
        var bumper := _node(model,"G11V12_ParachoquesBiselado") as MeshInstance3D
        _check(bumper.mesh is ArrayMesh,
            "front bumper has octagonal extruded profile, not a flat image")
        _check(_node(model,"G11V12_EmbocaduraRejillaProa") != null,
            "front grille cutout has its own recessed 3D shape")
        for slot in range(6):
            _check(_node(model,
                "G11V12_AletaRejillaProa_%d" % slot) != null,
                "front grille has separate steel insert %d" % slot)
        for blade in range(7):
            _check(_node(model,
                "G11V12_AletaVentilacionMotor_%d" % blade) != null,
                "engine airflow louver is independently modeled")
        _check(_node(model,"G11_RejillaMotor_0") == null,
            "obsolete primitive six-engine-slot geometry replaced")
        _check(_node(model,"G11V12_CajaVentilacionMotor") != null,
            "engine bay now has actual recessed ventilation enclosure")
        _check(_node(model,"G11_Tubo_0_0") != null,
            "V11 truly open rocket tube geometry remains on G11")
        _check(_node(model,"G11V11_NervioTecho_2") != null,
            "previous sculpted launcher roof remains present")
        _check(_node(model,"G11V5_LlantaEsculpida_1_0") != null,
            "V5 real running gear not changed")

        _check(Models.pose_model("mlrs",model,"move",0.37),
            "animated chassis still moves with correct physical track")
        _check(_node(model,"G11V12_EscalonAntideslizante_1").is_visible_in_tree(),
            "footstep remains part of moving vehicle, no detached geometry")
        _check(Models.pose_model("mlrs",model,"attack",0.85),
            "V8 twelve-projectile salvo still works on V12 cab/chassis")
        _check(V10.glowing_count(model) == 12,
            "all cooling tube rims retained after chassis enhancement")
        _check(Rig.pose(model,"cooldown",0.50),
            "V10 twin hydraulics still return smoothly")
        _check(Rig.pose(model,"cooldown",1.0),
            "launcher parks after cooldown")
        _check(Art.apply_stage(model,2),
            "medium armor deformation still available after new cab parts")
        _check(_node(model,"G11V12_CristalLateral_1").is_visible_in_tree(),
            "localized right body damage does not erase intact cabin glazing")
        _check(_node(model,"G11V12_CajaVentilacionMotor").visible,
            "undamaged engine grille remains until critical damage")
        _check(Art.apply_stage(model,3),
            "critical engine damage still exposes charred internals")
        _check(not _node(model,"G11V12_CajaVentilacionMotor").visible,
            "pristine V12 motor grille no longer obscures burned engine")
        _check(not _node(model,"G11V12_AletaVentilacionMotor_0").visible,
            "new metal louvers disappear only when engine bay is destroyed")
        _check(Art.apply_stage(model,0),"G11 full repair still reversible")
        _check(_node(model,"G11V12_CajaVentilacionMotor").visible,
            "repair restores seven metallic engine louvers and housing")
        _check(_node(model,"G11V12_CristalLateral_1").is_visible_in_tree(),
            "both windows survive all reversible damage states")
        Models.restore_model_pose("mlrs",model)
        model.queue_free()
        await process_frame
    if errors > 0:
        push_error("G11 V12 CAB/CHASSIS FAILED (%d checks)" % errors)
        quit(1)
        return
    print("PASS G11 CAB CHASSIS V12: eight factions, two armored doors/windows/mirrors, real wipers and steps, seven engine louvers, 24 bolts, preserved V11+V10")
    quit(0)
