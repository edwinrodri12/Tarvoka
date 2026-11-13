extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Lab = preload("res://scripts/ui/VisualLab.gd")
const Inspector = preload("res://scripts/ui/Unit3DInspector.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Renderer = preload("res://scripts/ui/UnitRender3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var model: Node3D = Models.build("tank",0)
    assert(model != null)
    assert(Damage.STAGES.size() == 5)
    assert(Damage.stage_for_hp(14,14) == 0)
    assert(Damage.stage_for_hp(12,14) == 1)
    assert(Damage.stage_for_hp(8,14) == 2)
    assert(Damage.stage_for_hp(3,14) == 3)
    assert(Damage.stage_for_hp(0,14) == 4)
    var renderer = Renderer.new()
    assert(renderer._damage_stage_from_unit({"hp":8}) == 2)
    renderer.free()
    assert(Damage.current_stage(model) == 0)
    assert(Models.paintable_count(model) == 14)
    assert(Damage.prepare(model) == false) # Idempotent, no duplicated layers.
    assert(Models.inspect_meshes(model) >= 160)
    var damage_root: Node3D = model.find_child(Damage.ROOT,true,false) as Node3D
    assert(damage_root != null and damage_root.get_child_count() == 4)
    for i in range(1,5):
        assert(not damage_root.find_child("DesgasteEtapa%d" % i,false,false).visible)

    var plate: MeshInstance3D = model.find_child("FaccionFaldon1_02",true,false) as MeshInstance3D
    var tread: MeshInstance3D = model.find_child("CintaSuperiorOruga1",true,false) as MeshInstance3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    var cannon: MeshInstance3D = model.find_child("Canon120mm",true,false) as MeshInstance3D
    assert(plate != null and tread != null and turret != null and gun != null and cannon != null)
    var coat: Color = plate.material_override.albedo_color
    for stage in range(5):
        assert(Damage.apply_stage(model,stage))
        assert(Damage.current_stage(model) == stage)
        for i in range(1,5):
            assert(damage_root.find_child("DesgasteEtapa%d" % i,false,false).visible == (stage >= i))
        assert(plate.visible == (stage < 2))
        assert(tread.visible == (stage < 3))
        assert(cannon.visible == (stage < 4))
        assert(is_equal_approx(turret.rotation_degrees.z,22.0 if stage == 4 else (6.0 if stage == 3 else 0.0)))
        if stage == 4:
            assert(is_equal_approx(gun.rotation_degrees.x,-18.0))
            assert(damage_root.find_child("DesgasteEtapa4",false,false).find_child("FuegoBase",true,false) != null)
            assert(damage_root.find_child("DesgasteEtapa4",false,false).find_child("ColumnaHumo",true,false) != null)
    assert(not Damage.apply_stage(model,-1))
    assert(not Damage.apply_stage(model,5))
    assert(Damage.apply_stage(model,0))
    assert(plate.visible and tread.visible and cannon.visible)
    assert(plate.material_override.albedo_color == coat)
    assert(Damage.current_stage(model) == 0)
    assert(Damage.apply_stage(model,3))
    assert(Rig.pose(model,"damaged",0.38,Vector2i(1,0)))
    assert(Damage.apply_stage(model,3))
    assert(damage_root.find_child("DesgasteEtapa3",false,false).visible)
    Rig.restore(model)
    assert(Damage.apply_stage(model,3))
    assert(is_equal_approx(turret.rotation_degrees.z,6.0))
    model.free()

    var inspector = Inspector.new()
    root.add_child(inspector)
    inspector.show_role("tank")
    assert(inspector.camera.size < Models.preview_frame_height("tank")) # Closer physical model framing.
    assert(inspector.tank_damage_picker.item_count == 5)
    assert(inspector.tank_hit_button != null and inspector.tank_destroy_button != null)
    assert(inspector.tank_damage_picker.visible)
    assert(Damage.current_stage(inspector.model_root) == 0)
    inspector.set_damage_stage(2)
    assert(Damage.current_stage(inspector.model_root) == 2)
    inspector.simulate_tank_hit()
    assert(Damage.current_stage(inspector.model_root) == 3)
    assert(inspector.tank_animation_mode == "damaged")
    inspector.stop_tank_animation()
    assert(Damage.current_stage(inspector.model_root) == 3)
    inspector.set_damage_stage(4)
    assert(Damage.current_stage(inspector.model_root) == 4)
    inspector.set_damage_stage(0)
    assert(Damage.current_stage(inspector.model_root) == 0)
    inspector.show_role("apc")
    assert(not inspector.tank_damage_picker.visible)
    inspector.simulate_tank_hit() # Unsupported role does nothing.
    inspector.show_role("tank")
    inspector.queue_free()

    var lab = Lab.new()
    root.add_child(lab)
    assert(lab.damage_stage_picker.item_count == 5)
    assert(lab.receive_hit_button != null and lab.damage_preview_button != null)
    var original: Dictionary = lab.lab_board.state.duplicate(true)
    lab.attacker_picker.select(lab.CATALOG.find("tank"))
    lab.defender_picker.select(lab.CATALOG.find("ifv"))
    lab.rebuild_stage()
    var before: Dictionary = lab.lab_board.state.duplicate(true)
    lab.damage_stage_picker.select(2)
    lab.preview_damage_stage()
    assert(Damage.current_stage(lab.preview_viewer.model_root) == 2)
    assert(lab.lab_board.state == before)
    lab.preview_received_hit()
    assert(Damage.current_stage(lab.preview_viewer.model_root) == 3)
    assert(lab.damage_stage_picker.selected == 3)
    assert(lab.lab_board.state == before) # Cannot modify HP/fuel/ammo.
    lab.preview_viewer.hide()

    # The art preview must follow actual HP from a legal mirror tank battle,
    # not an invented damage percentage or the old manual step selection.
    lab.attacker_picker.select(lab.CATALOG.find("tank"))
    lab.defender_picker.select(lab.CATALOG.find("tank"))
    lab.distance_picker.select(0)
    lab.rebuild_stage()
    assert(lab.damage_stage_picker.selected == 0)
    var mirror: Dictionary = Session.attack(lab.lab_board.state.duplicate(true),"LAB-A","LAB-B")
    assert(mirror.get("valid",false))
    lab.demo_attack()
    assert(lab.lab_board.state == mirror["state"])
    var defender_hp := 0
    for unit in lab.lab_board.state["units"]:
        if str(unit["id"]) == "LAB-B":
            defender_hp = int(unit["hp"])
    var tank_max: int = int(Arsenal.profile("tank")["hp"])
    assert(lab.damage_stage_picker.selected == Damage.stage_for_hp(defender_hp,tank_max))
    assert(lab.feedback_label.text.contains("Ver daños 3D"))
    var post_attack: Dictionary = lab.lab_board.state.duplicate(true)
    lab.preview_damage_stage()
    assert(Damage.current_stage(lab.preview_viewer.model_root) == lab.damage_stage_picker.selected)
    assert(lab.lab_board.state == post_attack)
    lab.preview_viewer.hide()
    lab.queue_free()
    print("PASS tank damage lab: 5 progressive 3D wreck states, hit playback, reversible plates and tank-only sandbox HP isolation")
    quit(0)
